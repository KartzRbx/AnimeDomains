--!strict
-- Behavior: named humanoid anim slots — Hum.Idle:Play(), Hum.Walk:Play()

const AnimationUtil = require(script.Parent.AnimationUtil)
const AssetsUtils = require(script.Parent.AssetsUtils)

export type AnimName = string
export type EntityKind = AnimationUtil.EntityKind
export type EntityId = AnimationUtil.EntityId
export type AnimationSource = Animation | AnimName

export type AnimSlot = {
	Play: (self: AnimSlot, fadeTime: number?) -> AnimationTrack,
	Stop: (self: AnimSlot, fadeTime: number?) -> (),
	Pause: (self: AnimSlot) -> (),
	SetSpeed: (self: AnimSlot, speed: number) -> (),
	IsPlaying: (self: AnimSlot) -> boolean,
}

export type HumanoidManagerConfig = {
	Idle: AnimationSource?,
	Walk: AnimationSource?,
	EntityKind: EntityKind?,
	EntityId: EntityId?,
}

export type HumanoidManager = {
	Idle: AnimSlot,
	Walk: AnimSlot,
	Humanoid: Humanoid,
	Animator: Animator,
	Destroy: (self: HumanoidManager) -> (),
	StopAll: (self: HumanoidManager, fadeTime: number?) -> (),
}

type HumanoidManagerInternal = HumanoidManager & {
	_currentTrack: AnimationTrack?,
	_currentSlot: AnimSlot?,
	_speed: number,
	_tracks: { [AnimationTrack]: boolean },
}

const DEFAULT_IDLE = "Idle"
const DEFAULT_WALK = "Walk"

local HumanoidManager = {}
HumanoidManager.__index = HumanoidManager

const function resolveAnimation(
	source: AnimationSource,
	kind: EntityKind?,
	entityId: EntityId?,
	fallbackName: AnimName
): Animation
	if typeof(source) == "Instance" and source:IsA("Animation") then
		return source
	end

	local animName = if type(source) == "string" then source else fallbackName

	if kind and entityId then
		return AnimationUtil.ResolveAnimation(kind, entityId, animName)
	end

	local anim = AssetsUtils.getAnimation(animName)
	assert(anim:IsA("Animation"), `[HumanoidManager] Animation missing: {animName}`)
	return anim
end

const function createAnimSlot(
	manager: HumanoidManagerInternal,
	animation: Animation,
	looped: boolean,
	priority: Enum.AnimationPriority
): AnimSlot
	local track: AnimationTrack? = nil

	local slot = {} :: AnimSlot

	function slot.Play(_self: AnimSlot, fadeTime: number?): AnimationTrack
		local fade = fadeTime or 0.1

		if not track then
			local loaded = manager.Animator:LoadAnimation(animation)
			loaded.Looped = looped
			loaded.Priority = priority
			track = loaded
			manager._tracks[loaded] = true
		end

		local activeTrack = track :: AnimationTrack

		if manager._currentTrack and manager._currentTrack ~= activeTrack then
			manager._currentTrack:Stop(fade)
		end

		activeTrack:Play(fade)
		activeTrack:AdjustSpeed(manager._speed)
		manager._currentTrack = activeTrack
		manager._currentSlot = slot
		return activeTrack
	end

	function slot.Stop(_self: AnimSlot, fadeTime: number?)
		if not track then
			return
		end

		track:Stop(fadeTime or 0.1)

		if manager._currentSlot == slot then
			manager._currentTrack = nil
			manager._currentSlot = nil
		end
	end

	function slot.Pause(_self: AnimSlot)
		if track and track.IsPlaying then
			track:AdjustSpeed(0)
		end
	end

	function slot.SetSpeed(_self: AnimSlot, speed: number)
		manager._speed = speed
		if track then
			track:AdjustSpeed(speed)
		end
	end

	function slot.IsPlaying(_self: AnimSlot): boolean
		return track ~= nil and track.IsPlaying
	end

	return slot
end

function HumanoidManager.new(model: Model, config: HumanoidManagerConfig?): HumanoidManager
	local options: HumanoidManagerConfig = config or {}

	local kind = options.EntityKind
	local entityId = options.EntityId

	local animator = AnimationUtil.PrepareModel(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	assert(humanoid, `[HumanoidManager] Humanoid missing on {model:GetFullName()}`)

	local idleAnimation = resolveAnimation(options.Idle or DEFAULT_IDLE, kind :: EntityKind?, entityId, DEFAULT_IDLE)
	local walkAnimation = resolveAnimation(options.Walk or DEFAULT_WALK, kind :: EntityKind?, entityId, DEFAULT_WALK)

	local rawManager = setmetatable({
		Humanoid = humanoid,
		Animator = animator,
		_currentTrack = nil,
		_currentSlot = nil,
		_speed = 1,
		_tracks = {},
	}, HumanoidManager)
	local manager = (rawManager :: any) :: HumanoidManagerInternal

	manager.Idle = createAnimSlot(manager, idleAnimation, true, Enum.AnimationPriority.Idle)
	manager.Walk = createAnimSlot(manager, walkAnimation, true, Enum.AnimationPriority.Movement)

	return manager
end

function HumanoidManager.StopAll(self: HumanoidManager, fadeTime: number?)
	self.Idle:Stop(fadeTime)
	self.Walk:Stop(fadeTime)
end

function HumanoidManager.Destroy(self: HumanoidManager)
	local internal = self :: HumanoidManagerInternal

	internal:StopAll(0)

	for track in internal._tracks do
		track:Stop(0)
		track:Destroy()
	end

	table.clear(internal._tracks)
	internal._currentTrack = nil
	internal._currentSlot = nil
end

return HumanoidManager
