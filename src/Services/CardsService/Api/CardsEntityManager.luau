--!strict
const HttpService = game:GetService("HttpService")
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TweenService = game:GetService("TweenService")
const janitor = require(ReplicatedStorage.Packages.janitor)
const Pathfinder = require(ReplicatedStorage.Packages.Pathfinder)
const EntityActionManager = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.AttacksData.EntityActionManager)
const CardsCutscenes = require(script.Parent.CardsCutscenes)
const CardsServiceType = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceType)
const CardsServiceUtils = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceUtils)
const PlacementZoneUtils = require(ReplicatedStorage.Shareds.Utils.PlacementZoneUtil)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const CollisionGroupsUtils = require(ReplicatedStorage.Shareds.Utils.CollisionGroupUtil)
const HumanoidManager = require(ReplicatedStorage.Shareds.Utils.HumanoidManager)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const CombateStateHandler = require(ReplicatedStorage.Shareds.Workers.CombateStateHandler)

const MOVING_TARGET_TRACKING_RANGE = 400
const TROOP_AGGRO_LEAVE_MULTIPLIER = 1.25
const STATE_READY_ATT_NAME = "Ready"
const STATE_ATTACK_ENABLED_ATT_NAME = 'AttackEnabled'
const STATE_ATTACKING_ATT_NAME = 'Attacking'
const PATH_TARGET_MOVE_EPS = 2

type TargetKind = "Buildings" | "Ground" | "Air" | "All"

const CardsEntityManager = {}

const GlobalJanitor = janitor.new()
const EntityPathJanitors: { [string]: typeof(janitor.new()) } = {}

const PATH_ENTITY_NAME = '_Entitys'
const _EntityCache = workspace:WaitForChild('Game'):FindFirstChild(PATH_ENTITY_NAME)

const PATH_BILLBOARD_UNIT = 'UnitBillboard'
const _UnitBillboard = AssetsUtils.getMiscTemplate('Gameplay', PATH_BILLBOARD_UNIT) :: CardsServiceType.UnitBillboard

const DEFAULT_TOWER_ATTACK_DELAY = 1
const DEATH_DESPAWN_DELAY = 0.75
const DEATH_ANIM_NAME = "Death"

const Entitys: CardsServiceType.CardEntityMap = {}
const TowerAttackJanitors: { [string]: typeof(janitor.new()) } = {}
const DespawnedEntities: { [string]: boolean } = {}

local clientAttackValidationInitialized = false
local clientAttackReplicaInitialized = false
const attackValidationPending: { [string]: BindableEvent } = {}


const function ConsoleLog(message: string)
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

    GlobalJanitor:add(EntityModel.Humanoid:GetPropertyChangedSignal('Health'):Connect(function()
        HealthDisplay.HealthInfoContainer.TowerHealth.Text = tostring(math.floor(EntityModel.Humanoid.Health + 0.5))

        TweenService:Create(HealthDisplay.HealthBar.Bar, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(math.clamp(EntityModel.Humanoid.Health/ EntityModel.Humanoid.MaxHealth, 0, 1), 1)}):Play()

    end), 'Disconnect', entityName)

    GlobalJanitor:add(EntityModel.Humanoid.Died:Connect(function()
        self:_PlayEntityDeathPresentationClient(EntityModel, props.UID)
        self:_RemoveUnitBillboard(props)
    end), 'Disconnect', `{entityName}_Died`)

    GlobalJanitor:add(EntityModel.Destroying:Connect(function()
            self:_RemoveUnitBillboard(props)
    end), 'Disconnect', `{entityName}_Destroy`)

    if EntityBoard then 
        EntityBoard.Parent = EntityModel.HumanoidRootPart
    end
    
    return
end

function CardsEntityManager._RemoveUnitBillboard(_self: CardsEntityManager, props: CardsServiceType.CardEntityEntry)
    const entityName = `{props.Player.Name}_{props.UID}`
    -- This Janitor build only exposes PascalCase Remove (:remove is nil)
    const boardJanitor = GlobalJanitor :: any

    boardJanitor:Remove(entityName)
    boardJanitor:Remove(`{entityName}_Died`)
    boardJanitor:Remove(`{entityName}_Destroy`)

    const EntityModel = _EntityCache and _EntityCache:FindFirstChild(entityName)
    if not EntityModel or not EntityModel:IsA("Model") then
        return
    end

    const hrp = EntityModel:FindFirstChild("HumanoidRootPart")
    const board = hrp and hrp:FindFirstChild(PATH_BILLBOARD_UNIT)
    if board then
        board:Destroy()
    end
end

function CardsEntityManager._PlayEntityDeathPresentationServer(_self: CardsEntityManager, model: Model, uid: string): number
	-- << Death anim / VFX (server) — customize aqui >>

	return DEATH_DESPAWN_DELAY
end

function CardsEntityManager._PlayEntityDeathPresentationClient(_self: CardsEntityManager, model: Model, uid: string)
	assert(RunService:IsClient(), 'Cannot sended for server.')

	-- << Death anim / VFX (client) — customize aqui >>

	AnimationUtil.PlayEntityAnimationForUID(model, uid, DEATH_ANIM_NAME, 0.1)
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
	const attackDelay = entityData.DelayAttack
	const canRetargetTroops = entityData.CanRetargetTroops and targetKind ~= "Buildings"
	const ATTACK_PREP_LEAD = 0.35

	local lastAttackAt = -math.huge

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
		const IdleAnimation = AssetsUtils.getEntityAnimation('Unit', CardId, 'Idle')
		
		]]
		local WalkAnimation = AssetsUtils.getEntityAnimation('Unit', CardId, 'Walk')
		local IdleAnimation = AnimationUtil.ResolveDefaultAnimation('Idle')

		if not WalkAnimation  then
			WalkAnimation = AnimationUtil.ResolveDefaultAnimation('Walk')
		end

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

	const function syncAttackTargetUid()
		if currentCombatTarget then
			local targetUid = currentCombatTarget:GetAttribute("UID")
			__attackMeta.TargetUID = if type(targetUid) == "string" then targetUid else ""
			return
		end

		if currentBuildingTarget then
			local spawnedTower = EntityHelper.GetSpawnedTowerForAnchor(currentBuildingTarget)
			local targetUid = if spawnedTower then spawnedTower:GetAttribute("UID") else currentBuildingTarget.Name
			__attackMeta.TargetUID = if type(targetUid) == "string" then targetUid else currentBuildingTarget.Name
			return
		end

		__attackMeta.TargetUID = ""
	end

	syncAttackTargetUid()

	local pathfinder = Pathfinder.new(Model, {
		Target = pathTarget,
		MovingTarget = true,
		MovingTargetTrackingRange = MOVING_TARGET_TRACKING_RANGE,
		MovingTargetRetargetingRange = unitRange,
		NoPathAction = function()
			return
		end,
		MoveFunction = function(destination: Vector3)
			if Model:GetAttribute(STATE_READY_ATT_NAME) ~= true then
				return
			end

			Model.Humanoid:MoveTo(destination)
		end,
		AgentParameters = EntityHelper.GetPathAgentParameters(Model),
	})

	-- StopEntityPath destroys the janitor before Model.Destroying fires, so teardown lives here
	pathJanitor:add(function()
		pathfinder:Destroy()
	end, true)
	pathJanitor:add(pathTarget, "Destroy")
	pathJanitor:add(function()
		hum:Destroy()
	end, true)
	pathJanitor:add(function()
		__attackMeta:Destroy()
	end, true)

	const function getCombatTargetPosition(): Vector3?
		if currentCombatTarget then
			local targetHrp = currentCombatTarget:FindFirstChild("HumanoidRootPart")
			if targetHrp and targetHrp:IsA("BasePart") then
				return targetHrp.Position
			end
		end

		if currentBuildingTarget then
			return getTowerAnchor(currentBuildingTarget)
		end

		return nil
	end

	const function faceCombatTarget(targetPos: Vector3)
		local hrp = Model.HumanoidRootPart
		local flatTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
		local dir = flatTarget - hrp.Position
		if dir.Magnitude < 0.05 then
			return
		end

		hrp.CFrame = CFrame.lookAt(hrp.Position, flatTarget)
	end

	const function prepareCombatForAttack()
		if currentBuildingTarget then
			syncBuildingPathTarget(currentBuildingTarget)
		end

		local targetPos = getCombatTargetPosition()
		if targetPos then
			faceCombatTarget(targetPos)
		end

		AnimationUtil.GetOrLoadTrackForUID(Model, UID, "Attack")
	end

	const function tryPrepareNextAttack()
		if not __attackMeta.CanAttack or __attackMeta.TargetUID == "" then
			return
		end

		const now = os.clock()
		local remainingCooldown = attackDelay - (now - lastAttackAt)
		local isAttacking = Model:GetAttribute(STATE_ATTACKING_ATT_NAME) == true

		if isAttacking or remainingCooldown <= ATTACK_PREP_LEAD then
			prepareCombatForAttack()
		end
	end

	local pathfinderRunning = false

	const function ensurePathfinderRunning()
		if pathfinderRunning then
			return
		end

		pathfinderRunning = true
		pathfinder:Run()
	end

	const function pausePathfinder()
		if not pathfinderRunning then
			return
		end

		pathfinder:Stop()
		pathfinderRunning = false
	end

	const function unlockEntityMovement()
		if Model:GetAttribute(STATE_READY_ATT_NAME) ~= true then
			return
		end

		Model.Humanoid.WalkSpeed = entityData.Walk
	end

	const function setAttackReady(enabled: boolean)
		if Model:GetAttribute(STATE_ATTACK_ENABLED_ATT_NAME) == enabled then
			__attackMeta.CanAttack = enabled
			return
		end

		Model:SetAttribute(STATE_ATTACK_ENABLED_ATT_NAME, enabled)
		__attackMeta.CanAttack = enabled

		if enabled then
			Model.Humanoid.AutoRotate = false
			pausePathfinder()
			prepareCombatForAttack()
		else
			Model.Humanoid.AutoRotate = true
			ensurePathfinderRunning()
		end

		syncLocomotionAnim()
	end

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
			pausePathfinder()
			setAttackReady(false)
			return
		end

		currentBuildingTarget = tower
		syncBuildingPathTarget(tower)
		syncAttackTargetUid()
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
			pausePathfinder()
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
					syncAttackTargetUid()
					pathfinder:ChangeTarget(troop)
				elseif currentBuildingTarget then
					syncBuildingPathTarget(currentBuildingTarget)
				end
			end
		elseif currentBuildingTarget then
			syncBuildingPathTarget(currentBuildingTarget)
		end

		syncAttackTargetUid()
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

	const function tryContinuousAttack()
		if not __attackMeta.CanAttack then
			return
		end

		if __attackMeta.TargetUID == "" then
			return
		end

		if Model:GetAttribute(STATE_ATTACKING_ATT_NAME) == true then
			return
		end

		const now = os.clock()
		if now - lastAttackAt < attackDelay then
			return
		end

		__attackMeta:Attack()
		lastAttackAt = now
	end

	pathJanitor:add(RunService.Heartbeat:Connect(function()
		refreshCombatTarget()
		tryPrepareNextAttack()
		tryContinuousAttack()
		syncLocomotionAnim()
	end), "Disconnect")

	pathJanitor:add(Model.Destroying:Connect(function()
		AnimationUtil.ClearTrackCacheForUID(UID)
		pathJanitor:destroy()
		EntityPathJanitors[UID] = nil
	end), "Disconnect")

	pathJanitor:add(Model:GetAttributeChangedSignal(STATE_READY_ATT_NAME):Connect(function()
		unlockEntityMovement()
		syncLocomotionAnim()
	end), "Disconnect")

	pathJanitor:add(Model.Humanoid.Died:Connect(function()
		self:DespawnEntity(UID, Model)
	end), "Disconnect")

	ensurePathfinderRunning()
	refreshCombatTarget()
	unlockEntityMovement()
	syncLocomotionAnim()
end

function CardsEntityManager.BuildTowerAttack(
	_self: CardsEntityManager,
	model: Model,
	towerData: EntityHelper.TowerEntityData,
	uid: string,
	teamName: EntityHelper.TeamName
)
	assert(RunService:IsServer(), "[CardsEntityManager] BuildTowerAttack is server-only")

	const existingJanitor = TowerAttackJanitors[uid]
	if existingJanitor then
		existingJanitor:destroy()
		TowerAttackJanitors[uid] = nil
	end

	const hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		warn(`[CardsEntityManager] Tower missing HumanoidRootPart: {uid}`)
		return
	end

	const attackDelay = towerData.DelayAttack > 0 and towerData.DelayAttack or DEFAULT_TOWER_ATTACK_DELAY
	const towerRange = EntityHelper.CalculateRange({
		BaseRange = towerData.BaseRange,
	})
	const resolvedTargetKind: TargetKind = towerData.TargetKind
	const enemyTeam = PlacementZoneUtils.GetEnemyTeam(teamName)
	local lastAttackAt = -math.huge
	local currentTarget: Model? = nil

	const attackJanitor = janitor.new()
	TowerAttackJanitors[uid] = attackJanitor

	const function getEntityTeam(entityModel: Model): string?
		const team = entityModel:GetAttribute("Team")
		if type(team) == "string" then
			return team
		end

		const owner = entityModel:GetAttribute("Owner")
		if type(owner) ~= "string" then
			return nil
		end

		if owner == "Enemy" then
			return "Two"
		end

		const player = Players:FindFirstChild(owner)
		if player and player:IsA("Player") then
			return CardsServiceUtils.GetPlayerTeam(player)
		end

		return nil
	end

	const function isEnemyUnit(other: Model): boolean
		if other.Name == model.Name then
			return false
		end

		if other:GetAttribute("Kind") == "Tower" then
			return false
		end

		if getEntityTeam(other) ~= enemyTeam then
			return false
		end

		const otherHumanoid = other:FindFirstChildOfClass("Humanoid")
		if not otherHumanoid or otherHumanoid.Health <= 0 then
			return false
		end

		const enemyKind = other:GetAttribute("Kind")
		if type(enemyKind) ~= "string" or not matchesTargetKind(resolvedTargetKind, enemyKind) then
			return false
		end

		return true
	end

	const function findClosestEnemy(origin: Vector3): Model?
		if not _EntityCache then
			return nil
		end

		local best: Model? = nil
		const rangeSq = towerRange * towerRange
		local bestDistSq = math.huge

		for _, child in _EntityCache:GetChildren() do
			if not child:IsA("Model") or not isEnemyUnit(child) then
				continue
			end

			const targetHrp = child:FindFirstChild("HumanoidRootPart")
			if not targetHrp or not targetHrp:IsA("BasePart") then
				continue
			end

			const distSq = getDistanceSq(origin, targetHrp.Position)
			if distSq <= rangeSq and distSq < bestDistSq then
				best = child
				bestDistSq = distSq
			end
		end

		return best
	end

	const function faceTarget(target: Model)
		const targetHrp = target:FindFirstChild("HumanoidRootPart")
		if not targetHrp or not targetHrp:IsA("BasePart") then
			return
		end

		const flatTarget = Vector3.new(targetHrp.Position.X, hrp.Position.Y, targetHrp.Position.Z)
		hrp.CFrame = CFrame.lookAt(hrp.Position, flatTarget)
	end

	const function setAttackReady(enabled: boolean)
		if model:GetAttribute(STATE_ATTACK_ENABLED_ATT_NAME) == enabled then
			return
		end

		model:SetAttribute(STATE_ATTACK_ENABLED_ATT_NAME, enabled)
	end

	const function replicateTowerAttack(targetUID: string)
		model:SetAttribute(STATE_ATTACKING_ATT_NAME, true)

		const Debi = require(ReplicatedStorage.Shareds.Networker.NetServer).Secondary
		Debi.BindAttack_Replica.FireAll({
			UID = uid,
			TargetUID = targetUID,
		})

		task.delay(attackDelay, function()
			if model.Parent then
				model:SetAttribute(STATE_ATTACKING_ATT_NAME, false)
			end
		end)
	end

	const function tryTowerAttack()
		if not currentTarget then
			return
		end

		const targetHrp = currentTarget:FindFirstChild("HumanoidRootPart")
		if not targetHrp or not targetHrp:IsA("BasePart") then
			currentTarget = nil
			setAttackReady(false)
			return
		end

		const origin = hrp.Position
		if not isWithinRange(origin, targetHrp.Position, towerRange) then
			setAttackReady(false)
			return
		end

		setAttackReady(true)
		faceTarget(currentTarget)

		const now = os.clock()
		if now - lastAttackAt < attackDelay then
			return
		end

		if model:GetAttribute(STATE_ATTACKING_ATT_NAME) == true then
			return
		end

		const targetUid = currentTarget:GetAttribute("UID")
		if type(targetUid) ~= "string" or targetUid == "" then
			return
		end

		const levelAttr = model:GetAttribute("Level")
		const level: number = if type(levelAttr) == "number" then levelAttr else 1

		const damage = EntityHelper.CalculateDamage({
			BaseDamage = towerData.BaseDamage,
			Level = level,
		})

		lastAttackAt = now
		replicateTowerAttack(targetUid)

		CombateStateHandler:ApplyDamageToTarget(currentTarget, damage, {
			AttackerUID = uid,
			TargetUID = targetUid,
			HitIndex = 1,
			HitTime = 0,
		})
	end

	const function refreshTarget()
		const origin = hrp.Position

		if currentTarget then
			const targetHum = currentTarget:FindFirstChildOfClass("Humanoid")
			const targetHrp = currentTarget:FindFirstChild("HumanoidRootPart")
			const lostTarget = not targetHum
				or targetHum.Health <= 0
				or not targetHrp
				or not targetHrp:IsA("BasePart")
				or not isWithinRange(origin, targetHrp.Position, towerRange)

			if lostTarget then
				currentTarget = nil
				setAttackReady(false)
			end
		end

		if not currentTarget then
			currentTarget = findClosestEnemy(origin)
		end

		tryTowerAttack()
	end

	attackJanitor:add(RunService.Heartbeat:Connect(refreshTarget), "Disconnect")

	const towerHumanoid = model:FindFirstChildOfClass("Humanoid")
	if towerHumanoid then
		attackJanitor:add(towerHumanoid.Died:Connect(function()
			_self:DespawnEntity(uid, model)
		end), "Disconnect")
	end

	attackJanitor:add(model.Destroying:Connect(function()
		attackJanitor:destroy()
		TowerAttackJanitors[uid] = nil
	end), "Disconnect")

	refreshTarget()
end


function CardsEntityManager.StopEntityPath(_self: CardsEntityManager, UID: string)
	local pathJanitor = EntityPathJanitors[UID]
	if pathJanitor then
		pathJanitor:destroy()
		EntityPathJanitors[UID] = nil
	end
end

function CardsEntityManager._OnTowerDefeated(_self: CardsEntityManager, model: Model)
	const team = model:GetAttribute("Team")
	const towerSlot = model:GetAttribute("TowerSlot")
	if type(team) ~= "string" or type(towerSlot) ~= "string" then
		return
	end

	model:SetAttribute("Destroyed", true)

	const anchor = EntityHelper.GetTowerAnchorForSpawned(model)
	if anchor then
		anchor:SetAttribute("Destroyed", true)
	end

	-- Left/Right tower down → attacker gains that lane on the zone
	if towerSlot ~= "Left" and towerSlot ~= "Right" then
		return
	end

	const attackerTeam = PlacementZoneUtils.GetEnemyTeam(team)
	PlacementZoneUtils.UnlockEnemyLane(attackerTeam, towerSlot)
end

function CardsEntityManager.DespawnEntity(_self: CardsEntityManager, uid: string, model: Model)
	assert(RunService:IsServer(), "[CardsEntityManager] DespawnEntity is server-only")

	if DespawnedEntities[uid] then
		return
	end
	DespawnedEntities[uid] = true

	CardsEntityManager:StopEntityPath(uid)

	local towerJanitor = TowerAttackJanitors[uid]
	if towerJanitor then
		towerJanitor:destroy()
		TowerAttackJanitors[uid] = nil
	end

	Entitys[uid] = nil
	model:SetAttribute("Despawning", true)

	if model:GetAttribute("Kind") == "Tower" then
		_self:_OnTowerDefeated(model)
	end

	const despawnDelay = _self:_PlayEntityDeathPresentationServer(model, uid)

	task.delay(despawnDelay, function()
		if not model.Parent then
			DespawnedEntities[uid] = nil
			return
		end

		AnimationUtil.ClearTrackCacheForUID(uid)
		model:Destroy()
		DespawnedEntities[uid] = nil
	end)
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
        Humanoid.BreakJointsOnDeath = false

        EntityTemplate:SetAttribute('UID', entry)
        EntityTemplate:SetAttribute('CardId', payload.CardId)
        EntityTemplate:SetAttribute('Owner', payload.Player.Name)
        EntityTemplate:SetAttribute('MaxHealth', maxHealth)
        EntityTemplate:SetAttribute('Level', cardDataPlayer.Level)
        EntityTemplate:SetAttribute('Kind', cardDataPlayer.Kind)
		const playerTeam = CardsServiceUtils.GetPlayerTeam(payload.Player)
		if playerTeam then
			EntityTemplate:SetAttribute("Team", playerTeam)
		end
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
	if clientAttackReplicaInitialized then
		return
	end
	clientAttackReplicaInitialized = true

	const DebiSecondary = require(ReplicatedStorage.Shareds.Networker.NetClient).Secondary

	-- Replication from server
	DebiSecondary.BindAttack_Replica.On(function(replica)
		local attacker = EntityHelper.GetEntityCharacterForUID(replica.UID)
		if not attacker then
			return
		end

		local target = EntityHelper.GetCombatTargetForId(replica.TargetUID)
		if not target then
			return
		end

		self:_PlayAttackVisual({
			Attacker = attacker,
			Target = target,
			UID = replica.UID,
			TargetUID = replica.TargetUID,
		})
	end)
end

function CardsEntityManager.InitAttackValidation(self: CardsEntityManager)
	assert(RunService:IsClient(), 'Cannot sended for server.')
	if clientAttackValidationInitialized then
		return
	end
	clientAttackValidationInitialized = true

	const DebiValidations = require(ReplicatedStorage.Shareds.Networker.NetClient).Validations

	DebiValidations.PlayerCanEmitAttackForCardIDResult.SetCallback(function(result: PlayerCanEmitAttackResult)
		local key = self:_MakeAttackValidationKey(result.UID, result.CardID)
		local signal = attackValidationPending[key]
		if signal then
			signal:Fire(result)
		end
	end)
end

function CardsEntityManager.PlayerCanEmitAttackForCardID(
	self: CardsEntityManager,
	UID: string,
	CardID: string
): PlayerCanEmitAttackResult
	assert(RunService:IsClient(), 'Cannot sended for server.')

	const DebiValidations = require(ReplicatedStorage.Shareds.Networker.NetClient).Validations
	local key = self:_MakeAttackValidationKey(UID, CardID)
	local signal = Instance.new("BindableEvent")
	attackValidationPending[key] = signal

	DebiValidations.PlayerCanEmitAttackForCardID.Fire(UID, CardID)

	local result = signal.Event:Wait() :: PlayerCanEmitAttackResult
	attackValidationPending[key] = nil
	return result
end

function CardsEntityManager._MakeAttackValidationKey(_self: CardsEntityManager, uid: string, cardId: string): string
	return `{uid}\0{cardId}`
end

function CardsEntityManager._PlayAttackVisual(_self: CardsEntityManager, payload: AttackVisualPayload)
	if EntityActionManager:RunUnitAttackClient({
		Attacker = payload.Attacker,
		Target = payload.Target,
		UID = payload.UID,
		TargetUID = payload.TargetUID,
	}) then
		return
	end

	payload.Attacker:SetAttribute(STATE_ATTACKING_ATT_NAME, true)
	AnimationUtil.PlayEntityAnimationForUID(payload.Attacker, payload.UID, "Attack", 0.1)
end

export type AttackVisualPayload = {
	Attacker: Model,
	Target: Model,
	UID: string,
	TargetUID: string,
}

export type PlayerCanEmitAttackResult = CombateStateHandler.PlayerCanEmitAttackResult
export type EntityProps = { Position: Vector3 }
export type CardsEntityManager = typeof(CardsEntityManager)
return CardsEntityManager
