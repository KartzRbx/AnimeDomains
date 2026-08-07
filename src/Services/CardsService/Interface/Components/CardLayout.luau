--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TweenService = game:GetService("TweenService")

const Janitor = require(ReplicatedStorage.Packages.janitor)
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const UnitsMetaData = require(ReplicatedStorage.Shareds.Classes.Tree.Build.MetaData.UnitsMetaData)
const CardsServiceType = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceType)
const Icons = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.Icons)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const NumberFormater = require(ReplicatedStorage.Shareds.Utils.NumberFormater)
const UIModule = require(ReplicatedStorage.Shareds.Modules.UIModule)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const ShineLib = require(script.Parent.Parent.Lib.ShineLib)



const World = Mega.World

const Card = {}

export type CardConfig = UnitsMetaData.UnitCardParams

export type CardHandle = {
	CardJanitor: typeof(Janitor.new()),
	Template: CardsServiceType.TemplateCard,
	Data: CardConfig,
	EnabledCardLevelBar: boolean,
	Destroy: () -> (),
}

const CARD_BASE = AssetsUtils.getMiscTemplate("Card", "TemplateCard")
const COUNT_INFO = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
const BAR_INFO = TweenInfo.new(0.85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
const HOVER_SCALE = 1.1
const EMPTY = ""

const function clearText(label: TextLabel?)
	if label then
		label.Text = EMPTY
	end
end

const function getFoilLayer(root: Instance): CanvasGroup?
	local named = root:FindFirstChild("Background_2")
	if named and named:IsA("CanvasGroup") then
		return named
	end

	for _, child in root:GetChildren() do
		if child:IsA("CanvasGroup") and child.Name == "Background" then
			return child
		end
	end

	return nil
end

const function ResetCardTemplate(card: CardsServiceType.TemplateCard)
	local root = card.Card
	local description = root.Descrition
	local info = description.Info
	local level = description.Level

	root.Front.Image = EMPTY
	clearText(root.Rank)
	clearText(root.Rank.TextLabel)
	clearText(info.NameAvatar)
	clearText(info.Value.Value)
	clearText(level.LevelValue)
	clearText(level.ExpValue)

	local bar = description.LevelBar:FindFirstChild("Bar")
	if bar and bar:IsA("GuiObject") then
		bar.Size = UDim2.fromScale(0, 1)
	end
end

const function animateNumber(
	cardJanitor: typeof(Janitor.new()),
	fromValue: number,
	toValue: number,
	onStep: (value: number) -> ()
)
	local proxy = Instance.new("NumberValue")
	proxy.Value = fromValue
	cardJanitor:add(proxy, "Destroy")

	cardJanitor:add(proxy:GetPropertyChangedSignal("Value"):Connect(function()
		onStep(proxy.Value)
	end), "Disconnect")

	onStep(fromValue)
	local tween = TweenService:Create(proxy, COUNT_INFO, { Value = toValue })
	cardJanitor:add(tween, "Cancel")
	tween:Play()
end

const function BindData(
	card: CardsServiceType.TemplateCard,
	data: CardConfig,
	cardJanitor: typeof(Janitor.new()),
	enabledCardLevelBar: boolean
)
	local root = card.Card
	local description = root.Descrition
	local info = description.Info
	local energyValue = root.EnergyInfo.EnergyValue
	local levelFrame = description.Level
	local levelBar = description.LevelBar
	local bar = levelBar:FindFirstChild("Bar") :: Frame?
	local foil = getFoilLayer(root)

	root.Front.Image = data.CardImage
	root.Rank.Text = data.Class
	root.Rank.TextLabel.Text = data.Class
	info.NameAvatar.Text = data.Name
	energyValue.Text = NumberFormater.formatInteger(data.EnergyCost)

	if data.CardBack ~= EMPTY then
		root.Effect.Back.Image = data.CardBack
		if foil then
			local foilBack = foil:FindFirstChild("Back")
			if foilBack and foilBack:IsA("ImageLabel") then
				foilBack.Image = data.CardBack
			end
		end
	end

	levelFrame.Visible = enabledCardLevelBar
	levelBar.Visible = enabledCardLevelBar

	if not enabledCardLevelBar then
		if bar then
			bar.Size = UDim2.fromScale(0, 1)
		end
		clearText(levelFrame.LevelValue)
		clearText(levelFrame.ExpValue)
		return
	end

	local expMax = math.max(1, data.ExpMax)
	local progress = math.clamp(data.ExpCurrent / expMax, 0, 1)

	animateNumber(cardJanitor, 0, data.Level, function(value)
		levelFrame.LevelValue.Text = `Level {NumberFormater.formatInteger(value)}`
	end)

	animateNumber(cardJanitor, 0, data.ExpCurrent, function(value)
		local current = NumberFormater.formatInteger(value)
		local maxText = NumberFormater.formatInteger(expMax)
		levelFrame.ExpValue.Text = `{current} /{maxText}`
	end)

	if bar then
		bar.Size = UDim2.fromScale(0, 1)
		local barTween = TweenService:Create(bar, BAR_INFO, {
			Size = UDim2.fromScale(progress, 1),
		})
		cardJanitor:add(barTween, "Cancel")
		barTween:Play()
	end
end

const function mountEffects(
	cardTemplate: CardsServiceType.TemplateCard,
	cardJanitor: typeof(Janitor.new())
)
	local cardButton = cardTemplate.Card
	cardButton:SetAttribute("NoGuiFx", true)

	local scale = cardButton:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Name = "InterfaceScale"
	end

	local sweepHandle: ShineLib.ShineHandle? = nil

	cardJanitor:add(UIModule:HoverButton(cardButton, {
		Scale = HOVER_SCALE,
		Duration = 0.14,
	}), true)
	cardJanitor:add(UIModule:ClickButton(cardButton, {
		SpawnClickEffect = true,
	}), true)

	cardJanitor:add(function()
		if sweepHandle then
			sweepHandle:Destroy()
			sweepHandle = nil
		end
	end, true)

	cardJanitor:add(cardButton.MouseEnter:Connect(function()
		if sweepHandle then
			sweepHandle:Destroy()
		end
		sweepHandle = ShineLib.ApplyShine(cardButton, 1, false, 0)
	end), "Disconnect")

	cardJanitor:add(cardButton.MouseLeave:Connect(function()
		if sweepHandle then
			sweepHandle:Destroy()
			sweepHandle = nil
		end
	end), "Disconnect")
end

function Card.Make(cardData: CardConfig, enabledCardLevelBar: boolean?): CardHandle
	local cardTemplate = CARD_BASE:Clone() :: CardsServiceType.TemplateCard
	local cardJanitor = Janitor.new()
	local showLevelBar = if enabledCardLevelBar ~= nil then enabledCardLevelBar else false

	ResetCardTemplate(cardTemplate)
	BindData(cardTemplate, cardData, cardJanitor, showLevelBar)
	mountEffects(cardTemplate, cardJanitor)

	cardTemplate.Visible = true

	return {
		CardJanitor = cardJanitor,
		Template = cardTemplate,
		EnabledCardLevelBar = showLevelBar,
		Data = cardData,
		Destroy = function()
			cardJanitor:destroy()
			cardTemplate:Destroy()
		end,
	}
end

return Card
