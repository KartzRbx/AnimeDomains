--!strict

const HttpService = game:GetService("HttpService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const Workspace = game:GetService("Workspace")

const CardsEntityManager = require(ReplicatedStorage.Shareds.Services.CardsService.Api.CardsEntityManager)
const GameplayTypes = require(ReplicatedStorage.Shareds.Services.GameplayService.GameplayTypes)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const CollisionGroupUtil = require(ReplicatedStorage.Shareds.Utils.CollisionGroupUtil)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const HumanoidManager = require(ReplicatedStorage.Shareds.Utils.HumanoidManager)
const TowerMetaData = require(ReplicatedStorage.Shareds.Classes.Tree.Build.MetaData.TowerMetaData)
const EntityRegistry = require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.EntityRegistry)
const AttributeMirror = require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.AttributeMirror)

const GRIP_ENTITY_NAME = "GripEntity"
type GripEntityType = Attachment

const STATE_READY_ATT_NAME = "Ready"
const STATE_ATTACK_ENABLED_ATT_NAME = "AttackEnabled"
const STATE_ATTACKING_ATT_NAME = "Attacking"

const TowerServiceServer = {
	Initialized = false,
}

const function GetGeneratedModelName(towerKind: string): string
	return ("%s_%s"):format(towerKind, HttpService:GenerateGUID(false))
end

const function getTeamsRoot(): Folder?
	const gameFolder = Workspace:FindFirstChild("Game")
	const gameplay = gameFolder and gameFolder:FindFirstChild("Gameplay")
	const teams = gameplay and gameplay:FindFirstChild("Teams")
	if teams and teams:IsA("Folder") then
		return teams
	end
	return nil
end

const function spawnTeamTowers(
	teamsRoot: Folder,
	teamKey: EntityHelper.TeamName,
	teamData: GameplayTypes.TeamData
)
	const teamFolder = teamsRoot:FindFirstChild(teamKey)
	if not teamFolder or not teamFolder:IsA("Folder") then
		return
	end

	const towersFolder = teamFolder:FindFirstChild("Towers")
	const unitsCache = teamFolder:FindFirstChild("Units")
	if not towersFolder or not unitsCache or not unitsCache:IsA("Folder") then
		warn(`[TowerServiceServer] Towers/Units missing for team: {teamKey}`)
		return
	end

	const towersData = teamData.Data.Towers
	const teamName = teamKey

	for towerKind, towerPropertiesUnknown in towersData do
		const towerProperties = towerPropertiesUnknown :: GameplayTypes.TowerInfo
		const anchorModel = towersFolder:FindFirstChild(`{towerKind}Tower`)
		if not anchorModel or not anchorModel:IsA("Model") then
			warn(`[TowerServiceServer] Tower anchor missing: {towerKind}Tower`)
			continue
		end

		const gripPos = anchorModel:FindFirstChild(GRIP_ENTITY_NAME, true)
		if not gripPos or not gripPos:IsA("Attachment") then
			warn(`[TowerServiceServer] GripEntity missing on: {towerKind}Tower`)
			continue
		end

		const towerData = EntityHelper.GetTowerDataById(towerProperties.Id)
		if not towerData then
			warn(`[TowerServiceServer] Tower data missing for: {towerProperties.Id}`)
			continue
		end

		const entityModel = AssetsUtils.getEntityTowerModel(towerProperties.Id):Clone()
		const uid = HttpService:GenerateGUID(false)
		const humanoid = entityModel:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			entityModel:Destroy()
			warn(`[TowerServiceServer] Tower model missing Humanoid: {towerProperties.Id}`)
			continue
		end

		const maxHealth = EntityHelper.CalculateHealth({
			BaseHealth = towerData.BaseHealth,
			Level = towerProperties.Level,
			HealthPerLevel = towerData.HealthPerLevel,
		})
		humanoid.MaxHealth = maxHealth
		humanoid.Health = maxHealth
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		humanoid.BreakJointsOnDeath = false

		entityModel.Name = GetGeneratedModelName(towerKind :: string)
		entityModel.Parent = unitsCache

		CollisionGroupUtil.AssignEntity(entityModel)

		const gripWorld = (gripPos :: GripEntityType).WorldCFrame
		const spawnPos = gripWorld.Position
		const enemyPos = EntityHelper.GetEnemyTowerPosition(teamName, spawnPos)
		const lookCF = if enemyPos
			then CFrame.lookAt(spawnPos, Vector3.new(enemyPos.X, spawnPos.Y, enemyPos.Z))
			else gripWorld
		const floorOffset = EntityHelper.GetEntityFloorOffset(entityModel)

		entityModel:PivotTo(lookCF * CFrame.new(0, floorOffset, 0))

		entityModel:SetAttribute("UID", uid)
		entityModel:SetAttribute("CardId", towerProperties.Id)
		entityModel:SetAttribute("Owner", teamData.Owner)
		entityModel:SetAttribute("Team", teamKey)
		entityModel:SetAttribute("TowerSlot", towerKind)
		entityModel:SetAttribute("Kind", "Tower")
		entityModel:SetAttribute("MaxHealth", maxHealth)
		entityModel:SetAttribute("Level", towerProperties.Level)
		entityModel:SetAttribute(STATE_READY_ATT_NAME, true)
		entityModel:SetAttribute(STATE_ATTACKING_ATT_NAME, false)
		entityModel:SetAttribute(STATE_ATTACK_ENABLED_ATT_NAME, false)

		local ecsEntity = TowerMetaData.SpawnFromId(towerProperties.Id, {
			Position = spawnPos,
			Model = entityModel,
			Level = towerProperties.Level,
			Health = maxHealth,
			UID = uid,
			Owner = teamData.Owner,
			Team = teamKey,
			Ready = true,
			Kind = "Tower",
			TowerSlot = towerKind :: string,
			Anchor = anchorModel,
		})
		
		if ecsEntity then
			EntityRegistry.Register(ecsEntity, uid, entityModel)
			AttributeMirror.SyncEntity(ecsEntity)
		else
			warn(`[TowerServiceServer] Failed to spawn ECS tower for: {towerProperties.Id}`)
		end

		HumanoidManager.new(entityModel, {
			EntityKind = "Tower",
			EntityId = towerProperties.Id,
		})

		CardsEntityManager:BuildTowerAttack(entityModel, towerData, uid, teamName)
	end
end

function TowerServiceServer.SpawnMatchTowers(
	_self: TowerServiceServer,
	entityState: GameplayTypes.EntityState
): ()
	assert(RunService:IsServer(), "[TowerServiceServer] SpawnMatchTowers is server-only")

	const teamsRoot = getTeamsRoot()
	if not teamsRoot then
		warn("[TowerServiceServer] Teams folder missing")
		return
	end

	spawnTeamTowers(teamsRoot, "One", entityState.One)
	spawnTeamTowers(teamsRoot, "Two", entityState.Two)
end

function TowerServiceServer.Init(_self: TowerServiceServer): TowerServiceServer
	if TowerServiceServer.Initialized then
		return TowerServiceServer
	end

	TowerServiceServer.Initialized = true
	return TowerServiceServer
end

export type TowerServiceServer = typeof(TowerServiceServer)
return TowerServiceServer
