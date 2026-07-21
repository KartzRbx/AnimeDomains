--!strict
-- Behavior: resolves Anims (_Universal vs Tower/Unit Id) and controls play via Signal

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Signal = require(ReplicatedStorage.Packages.signal)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)

export type EntityKind = "Tower" | "Unit"
export type AnimName = string
export type EntityId = string

export type AnimationPlayer = {
	Play: (self: AnimationPlayer, name: AnimName) -> (),
	SetSpeed: (self: AnimationPlayer, speed: number) -> (),
	Pause: (self: AnimationPlayer) -> (),
	Destroy: (self: AnimationPlayer) -> (),
	Played: typeof(Signal.new()),
	Paused: typeof(Signal.new()),
	_animator: Animator,
	_tracks: { [AnimName]: AnimationTrack },
	_currentName: AnimName?,
	_currentTrack: AnimationTrack?,
	_speed: number,
	_kind: EntityKind,
	_entityId: EntityId,
}

export type AnimationResolveUtils = {
	PrepareModel: (model: Model) -> Animator,
	ResolveAnimation: (kind: EntityKind, entityId: EntityId, animName: AnimName) -> Animation,
	Bind: (model: Model, kind: EntityKind, entityId: EntityId) -> AnimationPlayer,
}

local AnimationResolveUtils = {} :: AnimationResolveUtils

const function getOrCreateAnimator(humanoid: Humanoid): Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end
	local created = Instance.new("Animator")
	created.Parent = humanoid
	return created
end

-- Unanchor parts so Motor6D/anim can work; HRP may be re-anchored later (tower)
function AnimationResolveUtils.PrepareModel(model: Model): Animator
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	assert(humanoid, `AnimationResolveUtils: Humanoid missing on {model:GetFullName()}`)

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local keepAnchored = descendant:GetAttribute("KeepAnchored") == true
			if not keepAnchored then
				descendant.Anchored = false
			end
			-- HRP must collide with the ground (pathfinder); limbs must not
			descendant.CanCollide = descendant.Name == "HumanoidRootPart"
		end
	end

	humanoid.PlatformStand = false
	return getOrCreateAnimator(humanoid)
end

function AnimationResolveUtils.ResolveAnimation(kind: EntityKind, entityId: EntityId, animName: AnimName): Animation
	return AssetsUtils.getEntityAnimation(kind, entityId, animName)
end

const function loadTrack(animator: Animator, animation: Animation): AnimationTrack
	return animator:LoadAnimation(animation)
end

const function createPlayer(animator: Animator, kind: EntityKind, entityId: EntityId): AnimationPlayer
	local player = {
		Played = Signal.new(),
		Paused = Signal.new(),
		_animator = animator,
		_tracks = {},
		_currentName = nil,
		_currentTrack = nil,
		_speed = 1,
		_kind = kind,
		_entityId = entityId,
	} :: AnimationPlayer

	function player.Play(self: AnimationPlayer, name: AnimName)
		if self._currentName == name and self._currentTrack and self._currentTrack.IsPlaying then
			return
		end

		local track = self._tracks[name]
		if not track then
			local animation = AnimationResolveUtils.ResolveAnimation(self._kind, self._entityId, name)
			track = loadTrack(self._animator, animation)
			track.Looped = (name == "Idle" or name == "Walk")
			self._tracks[name] = track
		end

		if self._currentTrack and self._currentTrack ~= track then
			self._currentTrack:Stop(0.1)
		end

		track:Play(0.1)
		track:AdjustSpeed(self._speed)
		self._currentTrack = track
		self._currentName = name
		self.Played:Fire(name)
	end

	function player.SetSpeed(self: AnimationPlayer, speed: number)
		self._speed = speed
		if self._currentTrack then
			self._currentTrack:AdjustSpeed(speed)
		end
	end

	function player.Pause(self: AnimationPlayer)
		if not self._currentTrack or not self._currentName then
			return
		end
		self._currentTrack:AdjustSpeed(0)
		self.Paused:Fire(self._currentName)
	end

	function player.Destroy(self: AnimationPlayer)
		for _, track in self._tracks do
			track:Stop(0)
			track:Destroy()
		end
		table.clear(self._tracks)
		self._currentTrack = nil
		self._currentName = nil
		self.Played:Destroy()
		self.Paused:Destroy()
	end

	return player
end

function AnimationResolveUtils.Bind(model: Model, kind: EntityKind, entityId: EntityId): AnimationPlayer
	local animator = AnimationResolveUtils.PrepareModel(model)
	return createPlayer(animator, kind, entityId)
end

return AnimationResolveUtils
