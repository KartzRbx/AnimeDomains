--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local AssetsUtil = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)

local ShineModule = {}

local DEFAULT_DURATION = 1.15
local DEFAULT_DELAY = 2.5
local START_OFFSET = Vector2.new(-1.15, -1.15)
local END_OFFSET = Vector2.new(1.15, 1.15)
local SHINE_ROTATION = 28
local RNG = Random.new()

export type Shine = Frame & {
	UICorner: UICorner,
	UIGradient: UIGradient,
}

export type ShineHandle = {
	Instance: Shine,
	Stop: (self: ShineHandle) -> (),
	Destroy: (self: ShineHandle) -> (),
}

local function configureShine(shine: Shine, element: GuiObject)
	shine.Name = "Shine"
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Position = UDim2.fromScale(0.5, 0.5)
	shine.Size = UDim2.fromScale(1, 1)
	shine.ZIndex = math.max(element.ZIndex + 1, shine.ZIndex)
	shine.Active = false
	shine.Selectable = false

	local parentCorner = element:FindFirstChildOfClass("UICorner")
	local shineCorner = shine:FindFirstChildOfClass("UICorner")
	if parentCorner and shineCorner then
		shineCorner.CornerRadius = parentCorner.CornerRadius
	end
end

local function playSweep(gradient: UIGradient, duration: number): Tween
	gradient.Rotation = SHINE_ROTATION
	gradient.Offset = START_OFFSET

	local tween = TweenService:Create(
		gradient,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ Offset = END_OFFSET }
	)
	tween:Play()
	return tween
end

function ShineModule.ApplyShine(
	element: GuiObject?,
	duration: number?,
	loop: boolean?,
	delayTime: number?
): ShineHandle?
	if not element then
		return nil
	end

	local template = AssetsUtil.getMiscTemplate("Card", "Shine") :: Shine
	local shine = template:Clone()
	local gradient = shine:FindFirstChildOfClass("UIGradient")
	if not gradient then
		shine:Destroy()
		return nil
	end

	configureShine(shine, element)
	shine.Parent = element

	local sweepDuration = duration or DEFAULT_DURATION
	local baseDelay = delayTime or DEFAULT_DELAY
	local running = true
	local activeTween: Tween? = nil

	local handle: ShineHandle

	local function stop()
		running = false
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
	end

	handle = {
		Instance = shine,
		Stop = function(_self: ShineHandle)
			stop()
		end,
		Destroy = function(_self: ShineHandle)
			stop()
			shine:Destroy()
		end,
	}

	shine.Destroying:Once(function()
		running = false
		activeTween = nil
	end)

	element.Destroying:Once(function()
		handle:Destroy()
	end)

	if loop then
		task.spawn(function()
			while running and shine.Parent do
				activeTween = playSweep(gradient, sweepDuration)
				activeTween.Completed:Wait()
				activeTween = nil

				if not running then
					break
				end

				-- Random delay between sweeps to feel more organic
				task.wait(RNG:NextNumber(baseDelay, baseDelay * 2.5))
			end
		end)
	else
		activeTween = playSweep(gradient, sweepDuration)
	end

	return handle
end

return ShineModule
