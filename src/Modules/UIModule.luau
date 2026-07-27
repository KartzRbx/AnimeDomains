--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Janitor = require(ReplicatedStorage.Packages.janitor)
local PlayerUtils = require(ReplicatedStorage.Shareds.Utils.PlayerUtils)

export type HudRegion = "Left" | "Right" | "Top" | "Bottom" | "HUD"

export type InterfaceEntry = {
	Frame: GuiObject,
	Region: HudRegion,
}

export type HoverButtonConfig = {
	Scale: number?,
	Duration: number?,
}

export type ClickButtonConfig = {
	Scale: number?,
	Duration: number?,
	SpawnClickEffect: boolean?,
}

export type MouseClickEffectConfig = {
	BubbleCount: number?,
	Color: Color3?,
	MinSpread: number?,
	MaxSpread: number?,
	MinSize: number?,
	MaxSize: number?,
	Duration: number?,
}

export type BindButtonConfig = {
	Hover: HoverButtonConfig?,
	Click: ClickButtonConfig?,
}

local DEFAULT_HOVER_SCALE = 1.06
local DEFAULT_HOVER_DURATION = 0.14
local DEFAULT_CLICK_SCALE = 0.94
local DEFAULT_CLICK_DURATION = 0.08
local EFFECT_DISPLAY_ORDER = 2850

local UIModule = {}

local Initialized = false
local MainGui: ScreenGui? = nil
local ModuleJanitor: any = nil
local Interfaces: { [string]: InterfaceEntry } = {}
local EffectsGui: ScreenGui? = nil
local EffectsContainer: Frame? = nil
local Rng = Random.new()

local function GetOrCreateScale(GuiObject: GuiObject): UIScale
	local Existing = GuiObject:FindFirstChild("InterfaceScale")
	if Existing and Existing:IsA("UIScale") then
		return Existing
	end

	local Scale = Instance.new("UIScale")
	Scale.Name = "InterfaceScale"
	Scale.Scale = 1
	Scale.Parent = GuiObject
	return Scale
end

local ActiveScaleTweens: { [UIScale]: Tween } = {}

local function TweenScale(Scale: UIScale, Target: number, Duration: number)
	local previous = ActiveScaleTweens[Scale]
	if previous then
		previous:Cancel()
		ActiveScaleTweens[Scale] = nil
	end

	local tween = TweenService:Create(
		Scale,
		TweenInfo.new(Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = Target }
	)
	ActiveScaleTweens[Scale] = tween
	tween.Completed:Connect(function()
		if ActiveScaleTweens[Scale] == tween then
			ActiveScaleTweens[Scale] = nil
		end
	end)
	tween:Play()
end

local function CancelScaleTween(Scale: UIScale)
	local previous = ActiveScaleTweens[Scale]
	if previous then
		previous:Cancel()
		ActiveScaleTweens[Scale] = nil
	end
end

local function IsDragLocked(Button: GuiButton): boolean
	return Button:GetAttribute("Dragging") == true
end

local function GetPointerPosition(Input: InputObject): Vector2
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		return UserInputService:GetMouseLocation()
	end

	local Inset = GuiService:GetGuiInset()
	return Vector2.new(Input.Position.X, Input.Position.Y + Inset.Y)
end

local function IsPointerInput(Input: InputObject): boolean
	return Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch
end

local function GetEffectsContainer(): Frame
	if EffectsContainer then
		return EffectsContainer
	end

	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "InterfaceEffectsGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.DisplayOrder = EFFECT_DISPLAY_ORDER
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui
	EffectsGui = ScreenGui

	local Container = Instance.new("Frame")
	Container.Name = "EffectsContainer"
	Container.BackgroundTransparency = 1
	Container.Size = UDim2.fromScale(1, 1)
	Container.ClipsDescendants = false
	Container.Parent = ScreenGui
	EffectsContainer = Container

	return Container
end

local function SpawnBubble(
	Container: Frame,
	Origin: UDim2,
	Color: Color3,
	MinSpread: number,
	MaxSpread: number,
	MinSize: number,
	MaxSize: number,
	Duration: number
)
	local StartSize = Rng:NextInteger(MinSize, MaxSize)
	local Bubble = Instance.new("Frame")
	Bubble.Name = "ClickBubble"
	Bubble.AnchorPoint = Vector2.new(0.5, 0.5)
	Bubble.Position = Origin
	Bubble.Size = UDim2.fromOffset(StartSize, StartSize)
	Bubble.BackgroundColor3 = Color
	Bubble.BackgroundTransparency = 0.15
	Bubble.BorderSizePixel = 0
	Bubble.Parent = Container

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(1, 0)
	Corner.Parent = Bubble

	local Angle = Rng:NextNumber(0, math.pi * 2)
	local Distance = Rng:NextNumber(MinSpread, MaxSpread)
	local Target = Origin + UDim2.fromOffset(math.cos(Angle) * Distance, math.sin(Angle) * Distance)
	local EndSize = math.max(2, math.floor(StartSize * 0.45))

	local Tween = TweenService:Create(
		Bubble,
		TweenInfo.new(Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = Target,
			Size = UDim2.fromOffset(EndSize, EndSize),
			BackgroundTransparency = 1,
		}
	)

	Tween:Play()
	Tween.Completed:Connect(function()
		Bubble:Destroy()
	end)
end

local function RegisterChildren(Root: Instance, Prefix: string)
	for _, Child in Root:GetChildren() do
		if Child:IsA("GuiObject") then
			UIModule:RegisterInterface(`{Prefix}.{Child.Name}`, Child, "HUD")
		end
	end
end

function UIModule:GetMainGui(): ScreenGui
	if MainGui and MainGui.Parent then
		return MainGui
	end

	MainGui = PlayerUtils.waitMain()
	return MainGui
end

function UIModule:Init()
	if Initialized then
		return
	end
	Initialized = true
	ModuleJanitor = Janitor.new()

	local ResolvedMain = self:GetMainGui()

	local Hud = ResolvedMain:FindFirstChild("HUD")
	if Hud then
		RegisterChildren(Hud, "HUD")
	end

	local Container = ResolvedMain:FindFirstChild("Container")
	if Container then
		RegisterChildren(Container, "Container")
	end

	for _, Descendant in ResolvedMain:GetDescendants() do
		if Descendant:IsA("GuiButton") and not Descendant:GetAttribute("NoGuiFx") then
			self:BindButton(Descendant)
		end
	end

	ModuleJanitor:add(ResolvedMain.DescendantAdded:Connect(function(Descendant: Instance)
		if Descendant:IsA("GuiButton") and not Descendant:GetAttribute("NoGuiFx") then
			self:BindButton(Descendant)
		end
	end))

	self:BindGlobalPointerClicks({
		BubbleCount = 4,
		MinSpread = 16,
		MaxSpread = 42,
		MinSize = 4,
		MaxSize = 8,
		Duration = 0.35,
	})
end

function UIModule:RegisterInterface(Name: string, Frame: GuiObject, Region: HudRegion?)
	Interfaces[Name] = {
		Frame = Frame,
		Region = Region or "HUD",
	}
end

function UIModule:GetInterface(Name: string): GuiObject?
	local Entry = Interfaces[Name]
	if not Entry then
		return nil
	end

	return Entry.Frame
end

function UIModule:IsOpen(Name: string): boolean
	local Entry = Interfaces[Name]
	return Entry ~= nil and Entry.Frame.Visible
end

function UIModule:ShowInterface(Name: string)
	local Entry = Interfaces[Name]
	if not Entry then
		warn(`[UIModule] Interface not registered: {Name}`)
		return
	end

	Entry.Frame.Visible = true
end

function UIModule:HideInterface(Name: string)
	local Entry = Interfaces[Name]
	if not Entry then
		return
	end

	Entry.Frame.Visible = false
end

function UIModule:ToggleInterface(Name: string)
	if self:IsOpen(Name) then
		self:HideInterface(Name)
	else
		self:ShowInterface(Name)
	end
end

function UIModule:HideAllInterfaces()
	for _, Entry in Interfaces do
		Entry.Frame.Visible = false
	end
end

function UIModule:MouseClickEffect(ScreenPosition: Vector2, Config: MouseClickEffectConfig?)
	local Container = GetEffectsContainer()
	local BubbleCount = if Config and Config.BubbleCount then Config.BubbleCount else 10
	local Color = if Config and Config.Color then Config.Color else Color3.fromRGB(255, 255, 255)
	local MinSpread = if Config and Config.MinSpread then Config.MinSpread else 28
	local MaxSpread = if Config and Config.MaxSpread then Config.MaxSpread else 76
	local MinSize = if Config and Config.MinSize then Config.MinSize else 6
	local MaxSize = if Config and Config.MaxSize then Config.MaxSize else 10
	local Duration = if Config and Config.Duration then Config.Duration else 0.42
	local Origin = UDim2.fromOffset(ScreenPosition.X, ScreenPosition.Y)

	for _ = 1, BubbleCount do
		SpawnBubble(Container, Origin, Color, MinSpread, MaxSpread, MinSize, MaxSize, Duration)
	end
end

function UIModule:CancelButtonScale(Button: GuiButton)
	local Scale = GetOrCreateScale(Button)
	CancelScaleTween(Scale)
end

function UIModule:HoverButton(Button: GuiButton, Config: HoverButtonConfig?): () -> ()
	local Scale = GetOrCreateScale(Button)
	local BaseScale = Scale.Scale
	local HoverScale = if Config and Config.Scale then Config.Scale else DEFAULT_HOVER_SCALE
	local Duration = if Config and Config.Duration then Config.Duration else DEFAULT_HOVER_DURATION

	local EnterConnection = Button.MouseEnter:Connect(function()
		if IsDragLocked(Button) then
			return
		end
		TweenScale(Scale, HoverScale, Duration)
	end)

	local LeaveConnection = Button.MouseLeave:Connect(function()
		if IsDragLocked(Button) then
			return
		end
		TweenScale(Scale, BaseScale, Duration)
	end)

	return function()
		EnterConnection:Disconnect()
		LeaveConnection:Disconnect()
		CancelScaleTween(Scale)
		Scale.Scale = BaseScale
	end
end

function UIModule:ClickButton(Button: GuiButton, Config: ClickButtonConfig?): () -> ()
	local Scale = GetOrCreateScale(Button)
	local BaseScale = Scale.Scale
	local ClickScale = if Config and Config.Scale then Config.Scale else DEFAULT_CLICK_SCALE
	local Duration = if Config and Config.Duration then Config.Duration else DEFAULT_CLICK_DURATION
	local SpawnEffect = if Config and Config.SpawnClickEffect ~= nil then Config.SpawnClickEffect else false

	local DownConnection = Button.MouseButton1Down:Connect(function()
		if IsDragLocked(Button) then
			return
		end
		TweenScale(Scale, ClickScale, Duration)
	end)

	local UpConnection = Button.MouseButton1Up:Connect(function()
		if IsDragLocked(Button) then
			return
		end
		TweenScale(Scale, BaseScale, Duration)
	end)

	local ClickConnection: RBXScriptConnection? = nil
	if SpawnEffect then
		ClickConnection = Button.MouseButton1Click:Connect(function()
			self:MouseClickEffect(UserInputService:GetMouseLocation())
		end)
	end

	return function()
		DownConnection:Disconnect()
		UpConnection:Disconnect()
		if ClickConnection then
			ClickConnection:Disconnect()
		end
		Scale.Scale = BaseScale
	end
end

function UIModule:BindButton(Button: GuiButton, OnClick: (() -> ())?, Config: BindButtonConfig?): () -> ()
	local Disconnects: { () -> () } = {}

	table.insert(Disconnects, self:HoverButton(Button, if Config then Config.Hover else nil))
	table.insert(Disconnects, self:ClickButton(Button, if Config then Config.Click else nil))

	local ClickConnection: RBXScriptConnection? = nil
	if OnClick then
		ClickConnection = Button.MouseButton1Click:Connect(OnClick)
	end

	return function()
		for _, Disconnect in Disconnects do
			Disconnect()
		end

		if ClickConnection then
			ClickConnection:Disconnect()
		end
	end
end

function UIModule:BindGlobalPointerClicks(Config: MouseClickEffectConfig?): () -> ()

	local Connection = UserInputService.InputBegan:Connect(function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed then
			return
		end
		if IsPointerInput(Input) then
			self:MouseClickEffect(GetPointerPosition(Input), Config)
		end
	end)

	return function()
		Connection:Disconnect()
	end
end

UIModule.mouseClickEffect = UIModule.MouseClickEffect
UIModule.hoverButton = UIModule.HoverButton
UIModule.clickButton = UIModule.ClickButton
UIModule.bindButton = UIModule.BindButton
UIModule.bindGlobalPointerClicks = UIModule.BindGlobalPointerClicks

export type UIModule = typeof(UIModule)

return UIModule
