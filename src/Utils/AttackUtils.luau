--!strict
-- Behavior: attack hitboxes via overlap queries — swing windows, combat target query

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const Workspace = game:GetService("Workspace")

const janitor = require(ReplicatedStorage.Packages.janitor)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)

export type HitBoxShape = {
	Size: Vector3,
	Offset: CFrame?,
}

export type HitBoxOptions = {
	Name: string?,
	Shape: HitBoxShape?,
	Anchor: BasePart?,
	Parent: Instance?,
	DebugVisible: boolean?,
}

export type AttackHitBox = {
	Part: BasePart,
	UpdateCFrame: (self: AttackHitBox, worldCFrame: CFrame) -> (),
	GetCombatTargets: (self: AttackHitBox, attacker: Model) -> { Model },
	HasCombatTarget: (self: AttackHitBox, attacker: Model, target: Model) -> boolean,
	Destroy: (self: AttackHitBox) -> (),
}

export type HitResult = {
	Attacker: Model,
	Targets: { Model },
	HitTime: number,
	HitIndex: number,
}

export type BindTrackHitBoxOptions = {
	Attacker: Model,
	Track: AnimationTrack,
	HitTimes: { number },
	HitBox: AttackHitBox?,
	HitBoxConfig: HitBoxOptions?,
	WindowDuration: number?,
	GetHitBoxCFrame: ((attacker: Model) -> CFrame)?,
	OnHit: (result: HitResult) -> (),
	Section: typeof(janitor.new())?,
}

export type AttackUtils = {
	DEFAULT_HITBOX_SIZE: Vector3,
	DEFAULT_WINDOW_DURATION: number,
	FindAttachment: (attacker: Model, names: { string }?) -> Attachment?,
	GetDefaultHitBoxCFrame: (attacker: Model) -> CFrame,
	NewHitBox: (options: HitBoxOptions) -> AttackHitBox,
	BindTrackHitBox: (options: BindTrackHitBoxOptions) -> typeof(janitor.new()),
}

local AttackUtils = {} :: AttackUtils

AttackUtils.DEFAULT_HITBOX_SIZE = Vector3.new(4, 4, 4)
AttackUtils.DEFAULT_WINDOW_DURATION = 0.12

const HITBOX_PART_NAME = "AttackHitBox"
const HITBOX_FOLDER_NAME = "_AttackHitBoxes"
const ATTACHMENT_CANDIDATES = { "HitBox", "Weapon", "Slash", "Blade" }

const function getHitBoxFolder(): Folder
	local gameFolder = Workspace:FindFirstChild("Game")
	if not gameFolder or not gameFolder:IsA("Folder") then
		error("[AttackUtils] Workspace.Game folder missing")
	end

	local folder = gameFolder:FindFirstChild(HITBOX_FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		return folder
	end

	local created = Instance.new("Folder")
	created.Name = HITBOX_FOLDER_NAME
	created.Parent = gameFolder
	return created
end

const function getDefaultShape(): HitBoxShape
	return {
		Size = AttackUtils.DEFAULT_HITBOX_SIZE,
		Offset = CFrame.identity,
	}
end

const function isTowerModel(model: Model): boolean
	local parent = model.Parent
	return parent ~= nil and parent.Name == "Towers"
end

const function getCombatModelFromPart(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end

	if isTowerModel(model) then
		-- Anchors hold no Humanoid: a hit on the building counts as a hit on its spawned entity
		return EntityHelper.GetSpawnedTowerForAnchor(model)
	end

	if model:GetAttribute("UID") ~= nil then
		return model
	end

	return nil
end

const function isAliveCombatModel(model: Model): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health > 0
	end

	return EntityHelper.IsTowerAlive(model)
end

const function isEnemyOfAttacker(attacker: Model, candidate: Model): boolean
	if candidate == attacker then
		return false
	end

	local attackerOwner = attacker:GetAttribute("Owner")
	local candidateOwner = candidate:GetAttribute("Owner")

	if type(attackerOwner) == "string" and type(candidateOwner) == "string" then
		return attackerOwner ~= candidateOwner
	end

	if isTowerModel(candidate) then
		return true
	end

	return false
end

const function isValidCombatTarget(attacker: Model, candidate: Model): boolean
	if not isEnemyOfAttacker(attacker, candidate) then
		return false
	end

	return isAliveCombatModel(candidate)
end

const function dedupeModels(models: { Model }): { Model }
	local seen: { [Model]: boolean } = {}
	local unique: { Model } = {}

	for _, model in models do
		if not seen[model] then
			seen[model] = true
			table.insert(unique, model)
		end
	end

	return unique
end

function AttackUtils.FindAttachment(attacker: Model, names: { string }?): Attachment?
	local candidates = names or ATTACHMENT_CANDIDATES

	for _, name in candidates do
		local direct = attacker:FindFirstChild(name, true)
		if direct and direct:IsA("Attachment") then
			return direct
		end
	end

	local hrp = attacker:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		local rootAttachment = hrp:FindFirstChild("RootAttachment")
		if rootAttachment and rootAttachment:IsA("Attachment") then
			return rootAttachment
		end
	end

	return nil
end

function AttackUtils.GetDefaultHitBoxCFrame(attacker: Model): CFrame
	local attachment = AttackUtils.FindAttachment(attacker)
	if attachment then
		return attachment.WorldCFrame
	end

	local hrp = attacker:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp.CFrame * CFrame.new(0, 0, -2)
	end

	return attacker:GetPivot()
end

function AttackUtils.NewHitBox(options: HitBoxOptions): AttackHitBox
	local shape = options.Shape or getDefaultShape()
	local offset = shape.Offset or CFrame.identity
	local anchor = options.Anchor
	local parent = options.Parent or getHitBoxFolder()

	local hitPart = Instance.new("Part")
	hitPart.Name = options.Name or HITBOX_PART_NAME
	hitPart.Size = shape.Size
	hitPart.Anchored = true
	hitPart.CanCollide = false
	hitPart.CanTouch = true
	hitPart.CanQuery = true
	hitPart.Massless = true
	hitPart.Transparency = if options.DebugVisible then 0.6 else 1
	hitPart.Color = Color3.fromRGB(255, 85, 85)
	hitPart.Material = Enum.Material.Neon
	hitPart.CollisionGroup = "Default"
	hitPart.CFrame = if anchor then anchor.CFrame * offset else CFrame.new()
	hitPart.Parent = parent

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { hitPart }
	overlapParams.RespectCanCollide = false

	local cleanup = janitor.new()
	cleanup:add(hitPart, "Destroy")

	local hitBox = {} :: AttackHitBox
	hitBox.Part = hitPart

	function hitBox.UpdateCFrame(_self: AttackHitBox, worldCFrame: CFrame)
		hitPart.CFrame = worldCFrame * offset
	end

	function hitBox.GetCombatTargets(_self: AttackHitBox, attacker: Model): { Model }
		local targets: { Model } = {}
		local parts = Workspace:GetPartsInPart(hitPart, overlapParams)

		for _, part in parts do
			if not part:IsA("BasePart") then
				continue
			end

			local model = getCombatModelFromPart(part)
			if model and isValidCombatTarget(attacker, model) then
				table.insert(targets, model)
			end
		end

		return dedupeModels(targets)
	end

	function hitBox.HasCombatTarget(_self: AttackHitBox, attacker: Model, target: Model): boolean
		for _, candidate in hitBox:GetCombatTargets(attacker) do
			if candidate == target then
				return true
			end
		end

		return false
	end

	function hitBox.Destroy(_self: AttackHitBox)
		cleanup:cleanup()
	end

	return hitBox
end

function AttackUtils.BindTrackHitBox(options: BindTrackHitBoxOptions): typeof(janitor.new())
	local section = options.Section or janitor.new()
	local attacker = options.Attacker
	local track = options.Track
	local windowDuration = options.WindowDuration or AttackUtils.DEFAULT_WINDOW_DURATION
	local getHitBoxCFrame = options.GetHitBoxCFrame or AttackUtils.GetDefaultHitBoxCFrame

	local hitBox = options.HitBox
	if not hitBox then
		local anchorPart = attacker:FindFirstChild("HumanoidRootPart")
		assert(anchorPart and anchorPart:IsA("BasePart"), "[AttackUtils] Attacker missing HumanoidRootPart")

		hitBox = AttackUtils.NewHitBox({
			Anchor = anchorPart,
			Shape = options.HitBoxConfig and options.HitBoxConfig.Shape or getDefaultShape(),
			Name = options.HitBoxConfig and options.HitBoxConfig.Name or HITBOX_PART_NAME,
			DebugVisible = options.HitBoxConfig and options.HitBoxConfig.DebugVisible or false,
		})
		hitBox:UpdateCFrame(getHitBoxCFrame(attacker))
		section:add(hitBox, "Destroy")
	end

	local fired: { [number]: boolean } = {}
	local activeUntil = -math.huge

	section:add(track.Stopped:Once(function()
		table.clear(fired)
		activeUntil = -math.huge
	end), "Disconnect")

	section:add(RunService.PreAnimation:Connect(function()
		local timePosition = track.TimePosition
		local now = os.clock()

		if now <= activeUntil then
			hitBox:UpdateCFrame(getHitBoxCFrame(attacker))
		end

		for hitIndex, hitTime in options.HitTimes do
			if fired[hitTime] or timePosition < hitTime then
				continue
			end

			fired[hitTime] = true
			activeUntil = now + windowDuration
			hitBox:UpdateCFrame(getHitBoxCFrame(attacker))

			local targets = hitBox:GetCombatTargets(attacker)
			options.OnHit({
				Attacker = attacker,
				Targets = targets,
				HitTime = hitTime,
				HitIndex = hitIndex,
			})
		end
	end), "Disconnect")

	return section
end

return AttackUtils
