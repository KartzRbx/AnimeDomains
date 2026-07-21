--!strict
-- Behavior: clones VFX (Attachment/emitters), EmitAll/For/Excluded, Completed signal

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Debris = game:GetService("Debris")
const Signal = require(ReplicatedStorage.Packages.signal)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)

export type EffectName = string
export type EmitterName = string

export type EffectPlayback = {
	Completed: typeof(Signal.new()),
	Instance: Instance,
	Destroy: (self: EffectPlayback) -> (),
	_destroyed: boolean,
}

export type VisualEffectsUtils = {
	EmitAll: (source: Instance | Animation, parent: Instance) -> EffectPlayback,
	EmitFor: (source: Instance | Animation, parent: Instance, emitterNames: { EmitterName }) -> EffectPlayback,
	EmitExcluded: (source: Instance | Animation, parent: Instance, excludedNames: { EmitterName }) -> EffectPlayback,
}

local VisualEffectsUtils = {} :: VisualEffectsUtils

const function resolveEffectTemplate(source: Instance | Animation): Instance
	if source:IsA("Animation") then
		local linked = source:GetAttribute("Parent") or source:GetAttribute("Parrent")
		assert(typeof(linked) == "string" and linked ~= "", "Animation needs Parent attribute (effect name)")
		return AssetsUtils.getGameplayEntityEffect(linked :: string)
	end
	return source
end

const function collectEmitters(root: Instance): { ParticleEmitter }
	local emitters: { ParticleEmitter } = {}
	if root:IsA("ParticleEmitter") then
		table.insert(emitters, root)
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, descendant)
		end
	end
	return emitters
end

const function filterEmitters(
	emitters: { ParticleEmitter },
	mode: "all" | "for" | "excluded",
	names: { EmitterName }?
): { ParticleEmitter }
	if mode == "all" or not names then
		return emitters
	end

	local nameSet: { [string]: boolean } = {}
	for _, name in names do
		nameSet[name] = true
	end

	local filtered: { ParticleEmitter } = {}
	for _, emitter in emitters do
		local included = nameSet[emitter.Name] == true
		if mode == "for" and included then
			table.insert(filtered, emitter)
		elseif mode == "excluded" and not included then
			table.insert(filtered, emitter)
		end
	end
	return filtered
end

const function burstCount(emitter: ParticleEmitter): number
	local attr = emitter:GetAttribute("EmitCount")
	if typeof(attr) == "number" and attr > 0 then
		return math.floor(attr)
	end
	if emitter.Rate > 0 then
		return math.max(1, math.ceil(emitter.Rate))
	end
	return 16
end

const function maxLifetime(emitters: { ParticleEmitter }): number
	local longest = 0.5
	for _, emitter in emitters do
		local life = emitter.Lifetime.Max
		if life > longest then
			longest = life
		end
	end
	return longest
end

const function findAttachParent(parent: Instance): Instance
	if parent:IsA("BasePart") or parent:IsA("Attachment") then
		return parent
	end
	if parent:IsA("Model") then
		local hrp = parent:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			return hrp
		end
		local primary = parent.PrimaryPart
		if primary then
			return primary
		end
	end
	if parent:IsA("Humanoid") then
		local character = parent.Parent
		if character and character:IsA("Model") then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				return hrp
			end
		end
	end
	return parent
end

const function cloneUnderParent(template: Instance, parent: Instance): Instance
	local attachParent = findAttachParent(parent)
	local clone = template:Clone()
	clone.Parent = attachParent
	return clone
end

const function createPlayback(clone: Instance, emitters: { ParticleEmitter }): EffectPlayback
	local playback = {
		Completed = Signal.new(),
		Instance = clone,
		_destroyed = false,
	} :: EffectPlayback

	function playback.Destroy(self: EffectPlayback)
		if self._destroyed then
			return
		end
		self._destroyed = true
		if self.Instance.Parent then
			self.Instance:Destroy()
		end
		self.Completed:Destroy()
	end

	for _, emitter in emitters do
		emitter:Emit(burstCount(emitter))
	end

	local lifetime = maxLifetime(emitters) + 0.15
	task.delay(lifetime, function()
		if playback._destroyed then
			return
		end
		playback.Completed:Fire()
		playback:Destroy()
	end)

	-- Safety if Completed is never listened to
	Debris:AddItem(clone, lifetime + 2)

	return playback
end

const function emitInternal(
	source: Instance | Animation,
	parent: Instance,
	mode: "all" | "for" | "excluded",
	names: { EmitterName }?
): EffectPlayback
	local template = resolveEffectTemplate(source)
	local clone = cloneUnderParent(template, parent)
	local emitters = filterEmitters(collectEmitters(clone), mode, names)
	assert(#emitters > 0, "VisualEffectsUtils: no ParticleEmitter to emit")
	return createPlayback(clone, emitters)
end

function VisualEffectsUtils.EmitAll(source: Instance | Animation, parent: Instance): EffectPlayback
	return emitInternal(source, parent, "all", nil)
end

function VisualEffectsUtils.EmitFor(
	source: Instance | Animation,
	parent: Instance,
	emitterNames: { EmitterName }
): EffectPlayback
	return emitInternal(source, parent, "for", emitterNames)
end

function VisualEffectsUtils.EmitExcluded(
	source: Instance | Animation,
	parent: Instance,
	excludedNames: { EmitterName }
): EffectPlayback
	return emitInternal(source, parent, "excluded", excludedNames)
end

return VisualEffectsUtils
