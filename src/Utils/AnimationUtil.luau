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
	ResolveAnimationForUID: (uid: string, animName: AnimName) -> Animation?,
	ResolveDefaultAnimation: (animName: AnimName) -> Animation,
	LoadTrackForUID: (model: Model, uid: string, animName: AnimName) -> AnimationTrack?,
	GetOrLoadTrackForUID: (model: Model, uid: string, animName: AnimName) -> AnimationTrack?,
	ClearTrackCacheForUID: (uid: string) -> (),
	PlayEntityAnimationForUID: (model: Model, uid: string, animName: AnimName, fadeTime: number?) -> AnimationTrack?,
	Bind: (model: Model, kind: EntityKind, entityId: EntityId) -> AnimationPlayer,
}

local AnimationResolveUtils = {} :: AnimationResolveUtils

local uidTrackCache: { [string]: { [AnimName]: AnimationTrack } } = {}

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
	local animation = AssetsUtils.getEntityAnimation(kind, entityId, animName)
	assert(animation, `Animation missing: {kind}/{entityId}/{animName}`)
	return animation
end

function AnimationResolveUtils.ResolveAnimationForUID(uid: string, animName: AnimName): Animation?
	return AssetsUtils.GetEntityAnimationForUID(uid, animName)
end

function AnimationResolveUtils.ResolveDefaultAnimation(animName: AnimName): Animation
	return AssetsUtils.GetDefaultEntityAnimation(animName)
end

const function getModelAnimator(model: Model): Animator?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	return humanoid:FindFirstChildOfClass("Animator")
end

function AnimationResolveUtils.LoadTrackForUID(model: Model, uid: string, animName: AnimName): AnimationTrack?
	local animation = AnimationResolveUtils.ResolveAnimationForUID(uid, animName)
	if not animation then
		return nil
	end

	local animator = getModelAnimator(model)
	if not animator then
		return nil
	end

	local track = animator:LoadAnimation(animation)
	track.Looped = animName == "Idle" or animName == "Walk"
	return track
end

function AnimationResolveUtils.GetOrLoadTrackForUID(model: Model, uid: string, animName: AnimName): AnimationTrack?
	local cachedByAnim = uidTrackCache[uid]
	if cachedByAnim then
		local cachedTrack = cachedByAnim[animName]
		if cachedTrack then
			return cachedTrack
		end
	end

	local track = AnimationResolveUtils.LoadTrackForUID(model, uid, animName)
	if not track then
		return nil
	end

	if not cachedByAnim then
		cachedByAnim = {}
		uidTrackCache[uid] = cachedByAnim
	end

	cachedByAnim[animName] = track
	return track
end

function AnimationResolveUtils.ClearTrackCacheForUID(uid: string)
	uidTrackCache[uid] = nil
end

function AnimationResolveUtils.PlayEntityAnimationForUID(
	model: Model,
	uid: string,
	animName: AnimName,
	fadeTime: number?
): AnimationTrack?
	local track = AnimationResolveUtils.GetOrLoadTrackForUID(model, uid, animName)
	if not track then
		return nil
	end

	track:Play(fadeTime or 0.1)
	return track
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
