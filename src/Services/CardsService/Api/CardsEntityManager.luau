--!strict
const HttpService = game:GetService("HttpService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TweenService = game:GetService("TweenService")
const janitor = require(ReplicatedStorage.Packages.janitor)
const EntityActionManager = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.AttacksData.EntityActionManager)
const CardsCutscenes = require(script.Parent.CardsCutscenes)
const CardsServiceType = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceType)
const CardsServiceUtils = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceUtils)
const PlacementZoneUtils = require(ReplicatedStorage.Shareds.Utils.PlacementZoneUtil)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const CollisionGroupsUtils = require(ReplicatedStorage.Shareds.Utils.CollisionGroupUtil)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const CombateStateHandler = require(ReplicatedStorage.Shareds.Workers.CombateStateHandler)

const STATE_READY_ATT_NAME = "Ready"
const STATE_ATTACK_ENABLED_ATT_NAME = 'AttackEnabled'
const STATE_ATTACKING_ATT_NAME = 'Attacking'

const CardsEntityManager = {}

const GlobalJanitor = janitor.new()
const EntityPathJanitors: { [string]: typeof(janitor.new()) } = {}

const PATH_ENTITY_NAME = '_Entitys'
const _EntityCache = workspace:WaitForChild('Game'):FindFirstChild(PATH_ENTITY_NAME)

const PATH_BILLBOARD_UNIT = 'UnitBillboard'
const _UnitBillboard = AssetsUtils.getMiscTemplate('Gameplay', PATH_BILLBOARD_UNIT) :: CardsServiceType.UnitBillboard

const DEATH_DESPAWN_DELAY = 0.75
const DEATH_ANIM_NAME = "Death"

const Entitys: CardsServiceType.CardEntityMap = {}
const TowerAttackJanitors: { [string]: typeof(janitor.new()) } = {}
const DespawnedEntities: { [string]: boolean } = {}

local clientAttackValidationInitialized = false
local clientAttackReplicaInitialized = false
const attackValidationPending: { [string]: BindableEvent } = {}

const function getEntityRegistry()
	return require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.EntityRegistry)
end

const function getAttributeMirror()
	return require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.AttributeMirror)
end

const function getUnitsMetaData()
	return require(ReplicatedStorage.Shareds.Classes.Tree.Build.MetaData.UnitsMetaData)
end

const function getMovementSystem()
	return require(ReplicatedStorage.Shareds.Classes.Tree.Systems.MovementSystem)
end

const function getAttackSystem()
	return require(ReplicatedStorage.Shareds.Classes.Tree.Systems.AttackSystem)
end

const function getDeadTag()
	return require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.Dead)
end

const function getMega()
	return require(ReplicatedStorage.Shareds.Classes.Mega)
end


const function ConsoleLog(message: string)
    return print('[CARD SYSTEM]: ', message)
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
	const teamName = CardsServiceUtils.GetPlayerTeam(OwnerPlayer)
	if not entityData or not teamName then
		warn("[CardsEntityManager] BuildEntityPath missing entity/card/team data")
		return
	end

	CollisionGroupsUtils.AssignEntity(Model)
	Model:PivotTo(CardsServiceUtils.GetEntityGoalCFrame(OwnerPlayer, spawnPos, Model))

	local entity = getEntityRegistry().GetByUid(UID)
	if not entity then
		warn("[CardsEntityManager] BuildEntityPath missing ECS entity for", UID)
		return
	end

	getMovementSystem().RegisterUnit(entity, Model, UID, entityData.ModelID, entityData.Walk)
	getAttackSystem().BindUnitAttack(entity, UID)

	const pathJanitor = janitor.new()
	EntityPathJanitors[UID] = pathJanitor
	pathJanitor:add(function()
		getMovementSystem().Unregister(entity)
		getAttackSystem().Unbind(entity)
	end, true)

	pathJanitor:add(Model.Destroying:Connect(function()
		AnimationUtil.ClearTrackCacheForUID(UID)
		pathJanitor:destroy()
		EntityPathJanitors[UID] = nil
	end), "Disconnect")

	pathJanitor:add(Model.Humanoid.Died:Connect(function()
		self:DespawnEntity(UID, Model)
	end), "Disconnect")
end

function CardsEntityManager.BuildTowerAttack(
	_self: CardsEntityManager,
	model: Model,
	_towerData: EntityHelper.TowerEntityData,
	uid: string,
	_teamName: EntityHelper.TeamName
)
	assert(RunService:IsServer(), "[CardsEntityManager] BuildTowerAttack is server-only")

	const existingJanitor = TowerAttackJanitors[uid]
	if existingJanitor then
		existingJanitor:destroy()
		TowerAttackJanitors[uid] = nil
	end

	local entity = getEntityRegistry().GetByUid(uid)
	if not entity then
		warn("[CardsEntityManager] BuildTowerAttack missing ECS entity for", uid)
		return
	end

	const attackJanitor = janitor.new()
	TowerAttackJanitors[uid] = attackJanitor

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

	local ecsEntity = getEntityRegistry().GetByUid(uid)
	if ecsEntity then
		getMega().World:add(ecsEntity, getDeadTag())
	end

	if model:GetAttribute("Kind") == "Tower" then
		_self:_OnTowerDefeated(model)
	end

	const despawnDelay = _self:_PlayEntityDeathPresentationServer(model, uid)

	task.delay(despawnDelay, function()
		if ecsEntity and getMega().World:contains(ecsEntity) then
			getEntityRegistry().Delete(ecsEntity)
		end

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

		local ecsEntity = getUnitsMetaData().SpawnFromId(payload.CardId, {
			Position = spawnPos,
			Model = EntityTemplate,
			Level = cardDataPlayer.Level,
			Health = maxHealth,
			UID = entry,
			Owner = payload.Player.Name,
			Team = playerTeam,
			Ready = false,
			Kind = (if type(cardDataPlayer.Kind) == "string" then cardDataPlayer.Kind else "Unit") :: string,
		})
		if ecsEntity then
			getEntityRegistry().Register(ecsEntity, entry, EntityTemplate)
			getAttributeMirror().SyncEntity(ecsEntity)
		else
			warn("[CardsEntityManager] Failed to spawn ECS entity for", payload.CardId)
		end

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
