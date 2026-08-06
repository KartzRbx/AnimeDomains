--!strict
-- Behavior: Pathfinder adapter driven by ECS Target / BuildingTarget

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Workspace = game:GetService("Workspace")

const janitor = require(ReplicatedStorage.Packages.janitor)
const Pathfinder = require(ReplicatedStorage.Packages.Pathfinder)
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const HumanoidManager = require(ReplicatedStorage.Shareds.Utils.HumanoidManager)

const Anchor = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Anchor)
const AttackEnabled = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.AttackEnabled)
const BuildingTarget = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.BuildingTarget)
const ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
const Position = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Position)
const Range = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Range)
const Ready = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Ready)
const Target = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Target)
const Walk = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Walk)
const Dead = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.Dead)
const TemplateTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
const TowerTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TowerTag)
const UnitTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.UnitTag)
const World = Mega.World

const MOVING_TARGET_TRACKING_RANGE = 400
const PATH_TARGET_MOVE_EPS = 2
const PATH_ENTITY_NAME = "_Entitys"
const MOVING_THRESHOLD = 0.35

type UnitController = {
	pathfinder: any,
	pathTarget: BasePart,
	pathJanitor: typeof(janitor.new()),
	hum: any,
	syncedPathTargetPos: Vector3?,
	running: boolean,
	uid: string,
	cardId: string,
	locomotionState: string?,
}

local controllers: { [number]: UnitController } = {}

local MovementSystem = {}

const function getEntityCache(): Folder?
	local gameFolder = Workspace:FindFirstChild("Game")
	local cache = gameFolder and gameFolder:FindFirstChild(PATH_ENTITY_NAME)
	if cache and cache:IsA("Folder") then
		return cache
	end
	return nil
end

const function getXZDistanceSq(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return dx * dx + dz * dz
end

function MovementSystem.RegisterUnit(
	entity: number,
	model: Model,
	uid: string,
	cardId: string,
	walkSpeed: number
)
	if controllers[entity] then
		return
	end

	local cache = getEntityCache()
	if not cache then
		warn("[MovementSystem] _Entitys missing")
		return
	end

	local pathTarget = Instance.new("Part")
	pathTarget.Name = "PathTarget"
	pathTarget.Anchored = true
	pathTarget.CanCollide = false
	pathTarget.CanQuery = false
	pathTarget.CanTouch = false
	pathTarget.Transparency = 1
	pathTarget.Size = Vector3.new(0.5, 0.5, 0.5)
	pathTarget.Parent = cache

	local unitRange = World:get(entity, Range) or 5
	local pathJanitor = janitor.new()
	local hum = HumanoidManager.new(model, {
		EntityKind = "Unit",
		EntityId = cardId,
	})

	local pathfinder = Pathfinder.new(model, {
		Target = pathTarget,
		MovingTarget = true,
		MovingTargetTrackingRange = MOVING_TARGET_TRACKING_RANGE,
		MovingTargetRetargetingRange = unitRange,
		NoPathAction = function()
			return
		end,
		MoveFunction = function(destination: Vector3)
			if World:get(entity, Ready) ~= true then
				return
			end
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:MoveTo(destination)
			end
		end,
		AgentParameters = EntityHelper.GetPathAgentParameters(model),
	})

	pathJanitor:add(function()
		pathfinder:Destroy()
	end, true)
	pathJanitor:add(pathTarget, "Destroy")
	pathJanitor:add(function()
		hum:Destroy()
	end, true)

	pathJanitor:add(model.Destroying:Connect(function()
		MovementSystem.Unregister(entity)
	end), "Disconnect")

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
		humanoid.WalkSpeed = walkSpeed
	end

	controllers[entity] = {
		pathfinder = pathfinder,
		pathTarget = pathTarget,
		pathJanitor = pathJanitor,
		hum = hum,
		syncedPathTargetPos = nil,
		running = false,
		uid = uid,
		cardId = cardId,
		locomotionState = nil,
	}

	pathfinder:Run()
	controllers[entity].running = true
end

function MovementSystem.Unregister(entity: number)
	local controller = controllers[entity]
	if not controller then
		return
	end

	controller.pathJanitor:destroy()
	controllers[entity] = nil
end

const function syncBuildingPathTarget(controller: UnitController, towerModel: Model, origin: Vector3, unitRange: number): boolean
	local stopRadius = EntityHelper.GetTowerApproachStopRadius(towerModel, unitRange)
	local nextPos = EntityHelper.GetTowerApproachPosition(towerModel, origin, stopRadius)

	if controller.syncedPathTargetPos and getXZDistanceSq(controller.syncedPathTargetPos, nextPos) < PATH_TARGET_MOVE_EPS * PATH_TARGET_MOVE_EPS then
		return false
	end

	controller.pathTarget.Position = nextPos
	controller.syncedPathTargetPos = nextPos
	return true
end

const function ensureRunning(controller: UnitController)
	if controller.running then
		return
	end
	controller.running = true
	controller.pathfinder:Run()
end

const function pause(controller: UnitController)
	if not controller.running then
		return
	end
	controller.pathfinder:Stop()
	controller.running = false
end

const function syncLocomotion(entity: number, controller: UnitController, model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	local want = "Idle"
	if World:get(entity, Ready) == true and World:get(entity, AttackEnabled) ~= true then
		local hrp = model:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local vel = hrp.AssemblyLinearVelocity
			if Vector3.new(vel.X, 0, vel.Z).Magnitude > MOVING_THRESHOLD then
				want = "Walk"
			end
		end
	end

	if want == controller.locomotionState then
		return
	end
	controller.locomotionState = want

	local idle = AnimationUtil.GetOrLoadTrackForUID(model, controller.uid, "Idle")
	local walk = AnimationUtil.GetOrLoadTrackForUID(model, controller.uid, "Walk")
	if want == "Walk" then
		if idle then
			idle:Stop(0.1)
		end
		if walk then
			walk:Play()
		end
	else
		if walk then
			walk:Stop(0.1)
		end
		if idle then
			idle:Play()
		end
	end
end

function MovementSystem.Update(_dt: number)
	for entity, model in World:query(ModelComponent):with(UnitTag):without(TemplateTag, Dead) do
		local controller = controllers[entity]
		if not controller or typeof(model) ~= "Instance" or not model:IsA("Model") then
			continue
		end

		local healthModel = model:FindFirstChildOfClass("Humanoid")
		if healthModel and healthModel.Health <= 0 then
			pause(controller)
			controller.hum:StopAll()
			continue
		end

		local origin = World:get(entity, Position) or model:GetPivot().Position
		local unitRange = World:get(entity, Range) or 5
		local walk = World:get(entity, Walk) or 14
		local attackEnabled = World:get(entity, AttackEnabled) == true
		local ready = World:get(entity, Ready) == true

		if ready then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = walk
			end
		end

		if attackEnabled then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = false
			end
			pause(controller)
		else
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = true
			end
			if ready then
				ensureRunning(controller)
			else
				pause(controller)
			end
		end

		local target = World:get(entity, Target)
		if type(target) == "number" and target ~= 0 and World:has(target, UnitTag) then
			local troopModel = World:get(target, ModelComponent)
			if typeof(troopModel) == "Instance" and troopModel:IsA("Model") then
				controller.pathfinder:ChangeTarget(troopModel)
			end
		else
			local building = World:get(entity, BuildingTarget)
			if type(building) == "number" and building ~= 0 then
				local anchor = World:get(building, Anchor)
				local towerModel = if typeof(anchor) == "Instance" and anchor:IsA("Model")
					then anchor
					else World:get(building, ModelComponent)
				if typeof(towerModel) == "Instance" and towerModel:IsA("Model") then
					if syncBuildingPathTarget(controller, towerModel, origin, unitRange) then
						controller.pathfinder:ChangeTarget(controller.pathTarget)
					end
				end
			end
		end

		syncLocomotion(entity, controller, model)
	end
end

return MovementSystem
