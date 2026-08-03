--!strict
const HttpService = game:GetService("HttpService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TweenService = game:GetService("TweenService")
const janitor = require(ReplicatedStorage.Packages.janitor)
const Pathfinder = require(ReplicatedStorage.Packages.Pathfinder)
const EntityActionManager = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.AttacksData.EntityActionManager)
const CardsCutscenes = require(script.Parent.CardsCutscenes)
const CardsServiceType = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceType)
const CardsServiceUtils = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceUtils)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const CollisionGroupsUtils = require(ReplicatedStorage.Shareds.Utils.CollisionGroupUtil)
const HumanoidManager = require(ReplicatedStorage.Shareds.Utils.HumanoidManager)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)

const MOVING_TARGET_TRACKING_RANGE = 400
const TROOP_AGGRO_LEAVE_MULTIPLIER = 1.25
const STATE_READY_ATT_NAME = "Ready"
const STATE_ATTACK_ENABLED_ATT_NAME = 'AttackEnabled'
const STATE_ATTACKING_ATT_NAME = 'Attacking'
const PATH_TARGET_MOVE_EPS = 2

type TargetKind = "Buildings" | "Ground" | "Air" | "All"

const CardsEntityManager = {}

const GlobalJanitor = janitor.new()
local EntityPathJanitors: { [string]: typeof(janitor.new()) } = {}

const PATH_ENTITY_NAME = '_Entitys'
const _EntityCache = workspace:WaitForChild('Game'):FindFirstChild(PATH_ENTITY_NAME)

const PATH_BILLBOARD_UNIT = 'UnitBillboard'
const _UnitBillboard = AssetsUtils.getMiscTemplate('Gameplay', PATH_BILLBOARD_UNIT) :: CardsServiceType.UnitBillboard

const Entitys: CardsServiceType.CardEntityMap = {}


local function ConsoleLog(message: string)
    return print('[CARD SYSTEM]: ', message)
end

const function getTowerAnchor(tower: Instance): Vector3?
	local grip = tower:FindFirstChild("GripEntity", true)
	if grip and grip:IsA("Attachment") then
		return grip.WorldPosition
	end
	if tower:IsA("Model") then
		return tower:GetPivot().Position
	end
	if tower:IsA("BasePart") then
		return tower.Position
	end
	return nil
end

const function getDistance(a: Vector3, b: Vector3): number
	return (a - b).Magnitude
end

const function getDistanceSq(a: Vector3, b: Vector3): number
	local delta = a - b
	return delta.X * delta.X + delta.Y * delta.Y + delta.Z * delta.Z
end

const function getXZDistance(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	
	return math.sqrt(dx * dx + dz * dz)
end

const function getXZDistanceSq(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return dx * dx + dz * dz
end

const function hasFoundTower(unitPos: Vector3, tower: Model, detectionRadius: number): boolean
	local anchor = getTowerAnchor(tower)
	if not anchor then
		return false
	end
	return getDistance(unitPos, anchor) <= detectionRadius
end

const function isWithinRange(origin: Vector3, targetPos: Vector3, range: number): boolean
	return getDistanceSq(origin, targetPos) <= range * range
end

const function matchesTargetKind(targetKind: TargetKind, enemyKind: string): boolean
	if targetKind == "All" then
		return true
	end
	if targetKind == "Buildings" then
		return enemyKind == "Tower"
	end
	if targetKind == "Ground" then
		return enemyKind == "Unit"
	end
	if targetKind == "Air" then
		return enemyKind == "Air"
	end
	return false
end

function CardsEntityManager._GetEntityWithUID(self: CardsEntityManager, UID:string): CardsServiceType.CardEntityEntry?
    return Entitys[UID]
end

function CardsEntityManager._UpdateUnitBillboard(self: CardsEntityManager, props: CardsServiceType.CardEntityEntry):()
    assert(props, 'Props not found')

    const entityName = `{props.Player.Name}_{props.UID}`
    const boardjanitor =  GlobalJanitor:get(entityName) or nil

    const EntityModel: CardsServiceType.UnitRig = _EntityCache[entityName]
    if not EntityModel or not EntityModel.HumanoidRootPart then 
        ConsoleLog('Have a problem with entity model')
        return 
    end 

    local EntityBoard = EntityModel.HumanoidRootPart:FindFirstChild(PATH_BILLBOARD_UNIT) :: CardsServiceType.UnitBillboard?
    if not EntityBoard then 
        EntityBoard = _UnitBillboard:Clone()
    end

    const HealthDisplay = EntityBoard.HealthDisplay

    HealthDisplay.HealthInfoContainer.TowerHealth.Text = tostring(EntityModel.Humanoid.Health)
    HealthDisplay.TowerLevelValue.Text = tostring(EntityModel:GetAttribute('Level'))

    GlobalJanitor:add(EntityModel.Humanoid:GetPropertyChangedSignal('Health'):Connect(function(...)
        HealthDisplay.HealthInfoContainer.TowerHealth.Text = tostring(EntityModel.Humanoid)

        TweenService:Create(HealthDisplay.HealthBar.Bar, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(math.clamp(EntityModel.Humanoid.Health/ EntityModel.Humanoid.MaxHealth, 0, 1), 1)})

    end), 'Disconnect', entityName)

    GlobalJanitor:add(EntityModel.Destroying:Connect(function()
            GlobalJanitor:remove(entityName)
    end), 'Disconnect', `{entityName}_Destroy`)

    if EntityBoard then 
        EntityBoard.Parent = EntityModel.HumanoidRootPart
    end
    
    return
end

-----------------------------------------------
---------- << < SERVER_CALLS > >> -------------
-----------------------------------------------

function CardsEntityManager.BuildEntityPath(
	self: CardsEntityManager,
	OwnerPlayer: Player,
	Model: CardsServiceType.UnitRig,
	CardId: string,
	UID: string,
	spawnPos: Vector3
)
	assert(RunService:IsServer(), "[CardsEntityManager] BuildEntityPath is server-only")

	const entityData = EntityHelper.GetEntityDataByCardId(CardId)
	const cardData = CardsServiceUtils._GetCardDataWithID(CardId, OwnerPlayer)
	const teamName = CardsServiceUtils.GetPlayerTeam(OwnerPlayer)

	if not entityData or not cardData or not teamName then
		warn("[CardsEntityManager] BuildEntityPath missing entity/card/team data")
		return
	end

	local currentBuildingTarget = EntityHelper.GetClosestEnemyTower(teamName, spawnPos)
	if not currentBuildingTarget then
		warn("[CardsEntityManager] BuildEntityPath missing targetable enemy towers")
		return
	end

	-- attack metatable
	local __attackMeta = EntityActionManager:GetUnitAttack(UID)

	const targetKind = entityData.TargetKind :: TargetKind
	const unitRange = EntityHelper.CalculateRange({
		BaseRange = entityData.BaseRange,
	})
	const canRetargetTroops = entityData.CanRetargetTroops and targetKind ~= "Buildings"

	local pathTarget: BasePart
	local syncedPathTargetPos: Vector3? = nil

	const function getTowerDetectionRadius(tower: Model): number
		return EntityHelper.GetTowerDetectionRadius(tower, unitRange)
	end

	const function getTowerApproachStopRadius(tower: Model): number
		return EntityHelper.GetTowerApproachStopRadius(tower, unitRange)
	end

	const function syncBuildingPathTarget(tower: Model): boolean
		local origin = Model.HumanoidRootPart.Position
		local nextPos = EntityHelper.GetTowerApproachPosition(
			tower,
			origin,
			getTowerApproachStopRadius(tower)
		)

		if syncedPathTargetPos and getXZDistanceSq(syncedPathTargetPos, nextPos) < PATH_TARGET_MOVE_EPS * PATH_TARGET_MOVE_EPS then
			return false
		end

		pathTarget.Position = nextPos
		syncedPathTargetPos = nextPos
		return true
	end

	CollisionGroupsUtils.AssignEntity(Model)
	Model.Humanoid.AutoRotate = true
	Model:PivotTo(CardsServiceUtils.GetEntityGoalCFrame(OwnerPlayer, spawnPos, Model))
	Model.Humanoid.WalkSpeed = entityData.Walk

	const hum = HumanoidManager.new(Model, {
		EntityKind = "Unit",
		EntityId = entityData.ModelID,
	})

	
	const Humanoid = Model.Humanoid
	const Animator = Humanoid:FindFirstChildOfClass('Animator')

	const function GetEntityAnimations(): {[string]: AnimationTrack}?
		local __cache = self:_GetEntityWithUID(UID)

		--[[
			TODO - Futuramente mudar para animações de entidades locais
			-- const IdleAnimation = AssetsUtils.getEntityAnimation('Unit', CardId, 'Idle')
			-- const RunAnimation = AssetsUtils.getEntityAnimation('Unit', CardId, 'Run')
		]]

		local IdleAnimation = AssetsUtils.GetDefaultEntityAnimation('Idle')
		local WalkAnimation = AssetsUtils.GetDefaultEntityAnimation('Walk')

		if not IdleAnimation or not WalkAnimation then 
			warn('Animations not found in __universal__')
			return nil
		end

		if not __cache then
			warn('Invalid Cache params')
			return nil
		end

		if not Animator then 
			warn('Animator not found in: ' .. CardId .. ' UID: ' .. UID)
			return nil
		end

		if __cache.Idle == nil then
			__cache.Idle = Animator:LoadAnimation(IdleAnimation)
		end
		if __cache.Walk == nil then
			__cache.Walk = Animator:LoadAnimation(WalkAnimation)
		end

		if typeof(__cache.Idle) ~= "Instance" or not __cache.Idle:IsA("AnimationTrack") then
			warn("Idle AnimationTrack failed to load.")
			return nil
		end
		if typeof(__cache.Walk) ~= "Instance" or not __cache.Walk:IsA("AnimationTrack") then
			warn("Walk AnimationTrack failed to load.")
			return nil
		end

		return {
			Idle = __cache.Idle,
			Walk = __cache.Walk
		}:: {[string]: AnimationTrack}
	end

	type LocomotionState = "Idle" | "Walk"
	local locomotionState: LocomotionState? = nil
	const MOVING_THRESHOLD = 0.35

	const function isUnitMoving(): boolean
		local vel = Model.HumanoidRootPart.AssemblyLinearVelocity
		local horizontalVel = Vector3.new(vel.X, 0, vel.Z)
		return horizontalVel.Magnitude > MOVING_THRESHOLD
	end

	const function getWantLocomotion(): LocomotionState
		if Model:GetAttribute(STATE_READY_ATT_NAME) ~= true then
			return "Idle"
		end

		if Model:GetAttribute(STATE_ATTACK_ENABLED_ATT_NAME) == true then
			return "Idle"
		end

		if isUnitMoving() then
			return "Walk"
		end

		return "Idle"
	end

	const function syncLocomotionAnim()
		local tracks = GetEntityAnimations()
		if not tracks then
			return
		end

		local want: LocomotionState = getWantLocomotion()
		if want == locomotionState then
			return
		end

		locomotionState = want

		if want == "Walk" then
			tracks.Idle:Stop(0.1)
			tracks.Walk:Play()
			return
		end

		tracks.Walk:Stop(0.1)
		tracks.Idle:Play()
	end

	const function setAttackReady(enabled: boolean)
		if Model:GetAttribute(STATE_ATTACK_ENABLED_ATT_NAME) == enabled then
			__attackMeta.CanAttack = enabled
			return
		end

		Model:SetAttribute(STATE_ATTACK_ENABLED_ATT_NAME, enabled)
		__attackMeta.CanAttack = enabled
		syncLocomotionAnim()
	end


	pathTarget = Instance.new("Part")
	pathTarget.Name = "PathTarget"
	pathTarget.Anchored = true
	pathTarget.CanCollide = false
	pathTarget.CanQuery = false
	pathTarget.CanTouch = false
	pathTarget.Transparency = 1
	pathTarget.Size = Vector3.new(0.5, 0.5, 0.5)
	pathTarget.Parent = _EntityCache
	syncBuildingPathTarget(currentBuildingTarget)

	const pathJanitor = janitor.new()
	EntityPathJanitors[UID] = pathJanitor

	local currentCombatTarget: Model? = nil
	local pathfinder = Pathfinder.new(Model, {
		Target = pathTarget,
		MovingTarget = true,
		MovingTargetTrackingRange = MOVING_TARGET_TRACKING_RANGE,
		MovingTargetRetargetingRange = unitRange,
		NoPathAction = function()
			return
		end,
		AgentParameters = EntityHelper.GetPathAgentParameters(Model),
	})

	

	const function isEnemyModel(other: Model): boolean
		if other.Name == Model.Name then
			return false
		end

		local owner = other:GetAttribute("Owner")
		if owner == OwnerPlayer.Name then
			return false
		end

		local humanoid = other:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return false
		end

		return true
	end

	const function findClosestEnemyTroop(origin: Vector3): Model?
		if not canRetargetTroops then
			return nil
		end

		local entityFolder = _EntityCache
		if not entityFolder then
			return nil
		end

		local best: Model? = nil
		local aggroRangeSq = unitRange * unitRange
		local bestDistSq = math.huge

		for _, child in entityFolder:GetChildren() do
			if not child:IsA("Model") or not isEnemyModel(child) then
				continue
			end

			local enemyKind = child:GetAttribute("Kind")
			if type(enemyKind) ~= "string" or not matchesTargetKind(targetKind :: TargetKind, enemyKind) then
				continue
			end

			local hrp = child:FindFirstChild("HumanoidRootPart")
			if not hrp or not hrp:IsA("BasePart") then
				continue
			end

			local distSq = getDistanceSq(origin, hrp.Position)
			if distSq <= aggroRangeSq and distSq < bestDistSq then
				best = child
				bestDistSq = distSq
			end
		end

		return best
	end

	const function resumeBuildingPath()
		currentCombatTarget = nil

		local origin = Model.HumanoidRootPart.Position
		local tower = EntityHelper.GetClosestEnemyTower(teamName, origin)
		if not tower then
			pathfinder:Stop()
			setAttackReady(false)
			return
		end

		currentBuildingTarget = tower
		syncBuildingPathTarget(tower)
		pathfinder:ChangeTarget(pathTarget)
		setAttackReady(hasFoundTower(origin, tower, getTowerDetectionRadius(tower)))
	end

	const function updateAttackingState(origin: Vector3)
		if currentCombatTarget then
			local targetHrp = currentCombatTarget:FindFirstChild("HumanoidRootPart")
			if targetHrp and targetHrp:IsA("BasePart") then
				setAttackReady(isWithinRange(origin, targetHrp.Position, unitRange))
				return
			end
		end

		if currentBuildingTarget then
			setAttackReady(hasFoundTower(origin, currentBuildingTarget, getTowerDetectionRadius(currentBuildingTarget)))
		end
	end

	const function refreshCombatTarget()
		if Model.Humanoid.Health <= 0 then
			pathfinder:Stop()
			hum:StopAll()
			return
		end

		local origin = Model.HumanoidRootPart.Position

		if currentBuildingTarget and not EntityHelper.IsTowerAlive(currentBuildingTarget) then
			resumeBuildingPath()
			return
		end

		if canRetargetTroops then
			if currentCombatTarget then
				local hum = currentCombatTarget:FindFirstChildOfClass("Humanoid")
				local targetHrp = currentCombatTarget:FindFirstChild("HumanoidRootPart")
				local lostTarget = not hum
					or hum.Health <= 0
					or not targetHrp
					or not targetHrp:IsA("BasePart")
					or not isWithinRange(origin, targetHrp.Position, unitRange * TROOP_AGGRO_LEAVE_MULTIPLIER)

				if lostTarget then
					resumeBuildingPath()
				end
			end

			if not currentCombatTarget then
				local troop = findClosestEnemyTroop(origin)
				if troop then
					currentCombatTarget = troop
					pathfinder:ChangeTarget(troop)
				elseif currentBuildingTarget then
					syncBuildingPathTarget(currentBuildingTarget)
				end
			end
		elseif currentBuildingTarget then
			syncBuildingPathTarget(currentBuildingTarget)
		end

		updateAttackingState(origin)
	end

	pathJanitor:add(pathfinder.OnIdle:Connect(function()
		syncLocomotionAnim()
		updateAttackingState(Model.HumanoidRootPart.Position)
	end), "Disconnect")

	pathJanitor:add(pathfinder.OnPathCompleted:Connect(function()
		syncLocomotionAnim()
		updateAttackingState(Model.HumanoidRootPart.Position)
	end), "Disconnect")

	pathJanitor:add(pathfinder.OnWaypointReached:Connect(function()
		syncLocomotionAnim()
	end), "Disconnect")

	pathJanitor:add(RunService.Heartbeat:Connect(function()
		refreshCombatTarget()
		syncLocomotionAnim()
	end), "Disconnect")

	pathJanitor:add(Model.Destroying:Connect(function()
		pathfinder:Destroy()
		pathTarget:Destroy()
		hum:Destroy()
		pathJanitor:destroy()
		EntityPathJanitors[UID] = nil
		__attackMeta:Destroy()
	end), "Disconnect")

	pathJanitor:add(Model:GetAttributeChangedSignal(STATE_READY_ATT_NAME):Connect(function()
		syncLocomotionAnim()
		if not Model:GetAttribute(STATE_READY_ATT_NAME) then
			return
		end
		pathfinder:Run()
	end), "Disconnect")

	pathJanitor:add(__attackMeta.Changed:Connect(function(ParamName: string, canAttackValue: any | boolean)
		if ParamName == 'CanAttack' and (type(canAttackValue) == 'boolean' and canAttackValue) then 
			__attackMeta:Attack()
		end
	end), 'Disconnect')

	syncLocomotionAnim()
end

function CardsEntityManager.StopEntityPath(_self: CardsEntityManager, UID: string)
	local pathJanitor = EntityPathJanitors[UID]
	if pathJanitor then
		pathJanitor:destroy()
		EntityPathJanitors[UID] = nil
	end
end


function CardsEntityManager.newEntity(self: CardsEntityManager, payload: CardsServiceType.NewEntityCardData): CardsServiceType.CardEntityEntry?
    assert(RunService:IsServer(), 'Cannot sended for client')
    --[[
          00:16:21.003   ▼  {
                    ["CardId"] = "PlaceholderSix",
                    ["Player"] = KartzBro,
                    ["Position"] =  ▼  {
                       ["X"] = 217.4166259765625,
                       ["Y"] = 59.7091064453125,
                       ["Z"] = 136.0999908447266
                    }
                 }  -  Servidor - CardsEntityManager:10
    ]]


    const entry = HttpService:GenerateGUID(false)
    const entityName = `{payload.Player.Name}_{entry}`
    local EntityTemplate = _EntityCache:FindFirstChild(entityName)
    
    const entityData = EntityHelper.GetEntityDataByCardId(payload.CardId)
    const cardDataPlayer  = CardsServiceUtils._GetCardDataWithID(payload.CardId, payload.Player)
    if not entityData or not cardDataPlayer then 
            warn('Entity data not found or cardDataPlayer not found')
        return
    end

    if not EntityTemplate then
           -- Server spawn matches client cutscene landing (goal CFrame on floor)
        const EntityModel = AssetsUtils.getEntityUnitModel(entityData.ModelID)
        if not EntityModel then
            warn('Entity model not found in assets!')
            return
        end

        EntityTemplate = EntityModel:Clone() :: CardsServiceType.UnitRig
        EntityTemplate.Name = entityName
        EntityTemplate.Parent = _EntityCache

        const spawnPos = Vector3.new(payload.Position.X, payload.Position.Y, payload.Position.Z)

        -- Configure entity health
        local Humanoid = EntityTemplate.Humanoid :: Humanoid
        local maxHealth = EntityHelper.CalculateHealth({
            BaseHealth = entityData.BaseHealth,
            Level = cardDataPlayer.Level,
            HealthPerLevel = EntityHelper.GetHealthPerLevel(entityData.BaseHealth),
        })
        Humanoid.MaxHealth = maxHealth
        Humanoid.Health = maxHealth

        EntityTemplate:SetAttribute('UID', entry)
        EntityTemplate:SetAttribute('CardId', payload.CardId)
        EntityTemplate:SetAttribute('Owner', payload.Player.Name)
        EntityTemplate:SetAttribute('MaxHealth', maxHealth)
        EntityTemplate:SetAttribute('Level', cardDataPlayer.Level)
        EntityTemplate:SetAttribute('Kind', cardDataPlayer.Kind)
        EntityTemplate:SetAttribute(STATE_READY_ATT_NAME, false)
		EntityTemplate:SetAttribute(STATE_ATTACKING_ATT_NAME, false)
		EntityTemplate:SetAttribute(STATE_ATTACK_ENABLED_ATT_NAME, false)

		Entitys[entry] = {
			UID = entry,
			CardId = payload.CardId,
			Ready = false,
			Deploytime = entityData.DeployTime,
			Attacking = false,
			Player = payload.Player,
			Position = payload.Position,
			Model = EntityTemplate,
		}

        CardsEntityManager:BuildEntityPath(payload.Player, EntityTemplate, payload.CardId, entry, spawnPos)

		return self:_GetEntityWithUID(entry)
    end

    warn('This Entity has in game')
    return
end


-----------------------------------------------
---------- << < CLIENT_CALLS > >> -------------
-----------------------------------------------

function CardsEntityManager.updateEntity(self: CardsEntityManager, props : CardsServiceType.CardEntityEntry)
    assert(RunService:IsClient(), 'Cannot sended for server.')

    const entityName = `{props.Player.Name}_{props.UID}`
    const EntityTemplate = _EntityCache:FindFirstChild(entityName)

    const NetClient = require(ReplicatedStorage.Shareds.Networker.NetClient)

    const spawnPos = Vector3.new(props.Position.X, props.Position.Y, props.Position.Z)
    const SpawnToCutscenePosition = CardsServiceUtils.GetEntityLookCFrame(props.Player, spawnPos)

    const Callbacks = CardsCutscenes:SpawnEntityInPosition(EntityTemplate, SpawnToCutscenePosition, props.Deploytime) :: CardsServiceType.SpawnEntityCallback
    Callbacks.Completed:Connect(function()
        self:_UpdateUnitBillboard(props)
        NetClient.Validations.CutsceneCompleted.Fire(props.UID, props.CardId)
    end)
end


function CardsEntityManager.BindAttackReplicated(self: CardsEntityManager)
	assert(RunService:IsClient(), 'Cannot sended for server.')
end


export type EntityProps = {
    Position: Vector3
}
export type CardsEntityManager = typeof(CardsEntityManager)
return CardsEntityManager
