--!strict
-- Behavior: resolves Tower/Unit by ModuleScript name → { Config, create }

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Workspace = game:GetService("Workspace")

const PlacementZoneUtils = require(ReplicatedStorage.Shareds.Utils.PlacementZoneUtil)
const DatasFolder = ReplicatedStorage.Shareds.Classes.Tree.Datas
const TowerFolder = DatasFolder.Towers
const UnitsFolder = DatasFolder.Units

export type TeamName = PlacementZoneUtils.TeamName

export type EntityName = string
export type EntityType = "Tower" | "Unit"
export type EntityId = number

export type EntityConfig = {
	Id: string,
}

export type DamageCalculationProperties = {
	BaseDamage: number,
	Level: number,
	DamagePerLevel: number?,
	BonusDamage: number?,
	DamageMultiplier: number?,
}

export type HealthCalculationProperties = {
	BaseHealth: number,
	Level: number,
	HealthPerLevel: number,
	BonusHealth: number?,
	HealthMultiplier: number?,
}

export type RangeCalculationProperties = {
	BaseRange: number,
	BonusRange: number?,
	RangeMultiplier: number?,
}

export type EntityDef = {
	Config: EntityConfig,
	create: (position: Vector3) -> EntityId,
}

-- Card/unit recipe data (EnergyCost, ModelID, stats…) keyed by CardId
export type EntityData = {
	Id: string,
	Name: string,
	Level: number,
	Class: string,
	EnergyCost: number,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: number,
	DelayAttack: number,
	DeployTime: number,
	CardImage: string,
	CardBack: string,
	ModelID: string,
	Walk: number,
	TargetKind: string,
	CanRetargetTroops: boolean,
	ExpCurrent: number,
	ExpMax: number,
}

export type TowerEntityData = {
	Id: string,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: number,
	DelayAttack: number,
	TargetKind: "Buildings" | "Ground" | "Air" | "All",
	HealthPerLevel: number,
}

const TOWER_RECIPES: { [string]: TowerEntityData } = {
	Dummy = {
		Id = "Dummy",
		BaseHealth = 1200,
		BaseDamage = 140,
		BaseRange = 18,
		DelayAttack = 1,
		TargetKind = "All",
		HealthPerLevel = 140,
	},
}

local function findInFolder(folder: Folder, Name: EntityName): EntityDef?
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") and child.Name == Name then
			return require(child) :: EntityDef
		end
	end
	return nil
end

local EntityHelp = {}

-- Clash Royale style: ~10% of base stat per level step (HP and damage)
const STAT_PER_LEVEL_RATE = 0.10
const TOWER_CLEARANCE = 5
const TOWER_APPROACH_BUFFER = 2.5
const PATH_ENTITY_NAME = "_Entitys"
const SIDE_TOWER_NAMES = { "LeftTower", "RightTower" }
const MAIN_TOWER_NAME = "MainTower"

local function getTowerSlotFromAnchorName(anchorName: string): string?
	if anchorName == "LeftTower" then
		return "Left"
	end
	if anchorName == "MainTower" then
		return "Main"
	end
	if anchorName == "RightTower" then
		return "Right"
	end
	return nil
end

local function getTeamFolderFromTowerAnchor(anchor: Model): Folder?
	local towersFolder = anchor.Parent
	if not towersFolder or towersFolder.Name ~= "Towers" then
		return nil
	end

	local teamFolder = towersFolder.Parent
	if teamFolder and teamFolder:IsA("Folder") then
		return teamFolder
	end

	return nil
end

function EntityHelp.GetHealthPerLevel(BaseHealth: number): number
	return BaseHealth * STAT_PER_LEVEL_RATE
end

function EntityHelp.GetDamagePerLevel(BaseDamage: number): number
	return BaseDamage * STAT_PER_LEVEL_RATE
end

function EntityHelp.GetEntityFloorOffset(Entity: Model): number
	local boundsCF, size = Entity:GetBoundingBox()
	local pivotY = Entity:GetPivot().Position.Y
	const bottomY = boundsCF.Position.Y - size.Y * 0.5
	return math.max(0, pivotY - bottomY)
end


function EntityHelp.CalculateDamage(props: DamageCalculationProperties): number
	local bonusDamage = props.BonusDamage or 0
	local damageMultiplier = props.DamageMultiplier or 1
	local damagePerLevel = props.DamagePerLevel or EntityHelp.GetDamagePerLevel(props.BaseDamage)
	local levelDamage = damagePerLevel * math.max(props.Level - 1, 0)
	local damage = props.BaseDamage + levelDamage + bonusDamage

	return damage * damageMultiplier
end

function EntityHelp.CalculateHealth(props: HealthCalculationProperties): number
	local bonusHealth = props.BonusHealth or 0
	local healthMultiplier = props.HealthMultiplier or 1
	local healthPerLevel = props.HealthPerLevel
	local levelHealth = healthPerLevel * math.max(props.Level - 1, 0)
	local health = props.BaseHealth + levelHealth + bonusHealth

	return health * healthMultiplier
end

-- Clash Royale style: attack/detection range is fixed per card (no level scaling).
function EntityHelp.CalculateRange(props: RangeCalculationProperties): number
	local bonusRange = props.BonusRange or 0
	local rangeMultiplier = props.RangeMultiplier or 1
	return (props.BaseRange + bonusRange) * rangeMultiplier
end

local function getTeamsRoot(): Folder?
	local gameFolder = Workspace:FindFirstChild("Game")
	local gameplay = gameFolder and gameFolder:FindFirstChild("Gameplay")
	local teams = gameplay and gameplay:FindFirstChild("Teams")
	if teams and teams:IsA("Folder") then
		return teams
	end
	return nil
end

local function getEntitysFolder(): Folder?
	local gameFolder = Workspace:FindFirstChild("Game")
	local entityCache = gameFolder and gameFolder:FindFirstChild(PATH_ENTITY_NAME)
	if entityCache and entityCache:IsA("Folder") then
		return entityCache
	end
	return nil
end

local function getTowerAnchor(tower: Instance): Vector3?
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

local function getTowerClearRadius(tower: Instance): number
	if tower:IsA("Model") then
		local _cf, size = tower:GetBoundingBox()
		return math.max(size.X, size.Z) * 0.5 + TOWER_CLEARANCE
	end
	if tower:IsA("BasePart") then
		return math.max(tower.Size.X, tower.Size.Z) * 0.5 + TOWER_CLEARANCE
	end
	return TOWER_CLEARANCE + 4
end

local function getEnemyTowersFolder(teamName: TeamName): Folder?
	local enemy = PlacementZoneUtils.GetEnemyTeam(teamName)
	local teamsRoot = getTeamsRoot()
	local teamFolder = teamsRoot and teamsRoot:FindFirstChild(enemy)
	local towers = teamFolder and teamFolder:FindFirstChild("Towers")
	if towers and towers:IsA("Folder") then
		return towers
	end
	return nil
end

local function getXZDistanceSq(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return dx * dx + dz * dz
end

local function getGroundYAt(x: number, z: number, fallbackY: number, ignore: { Instance }?): number
	local origin = Vector3.new(x, fallbackY + 100, z)
	local params = RaycastParams.new()
	if ignore then
		params.FilterDescendantsInstances = ignore
		params.FilterType = Enum.RaycastFilterType.Exclude
	end

	local result = Workspace:Raycast(origin, Vector3.new(0, -300, 0), params)
	if result then
		return result.Position.Y
	end

	return fallbackY
end

function EntityHelp.GetTowerAnchor(tower: Instance): Vector3?
	return getTowerAnchor(tower)
end

function EntityHelp.GetEntityCharacterForUID(uid: string): Model?
	if type(uid) ~= "string" or uid == "" then
		return nil
	end

	local entityFolder = getEntitysFolder()
	if not entityFolder then
		return nil
	end

	for _, child in entityFolder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("UID") == uid then
			return child
		end
	end

	local gameFolder = Workspace:FindFirstChild("Game")
	local gameplay = gameFolder and gameFolder:FindFirstChild("Gameplay")
	local teams = gameplay and gameplay:FindFirstChild("Teams")
	if teams then
		for _, teamFolder in teams:GetChildren() do
			if not teamFolder:IsA("Folder") then
				continue
			end

			local units = teamFolder:FindFirstChild("Units")
			if units then
				for _, unit in units:GetChildren() do
					if unit:IsA("Model") and unit:GetAttribute("UID") == uid then
						return unit
					end
				end
			end

			local towers = teamFolder:FindFirstChild("Towers")
			if towers then
				for _, tower in towers:GetChildren() do
					if tower:IsA("Model") and tower:GetAttribute("UID") == uid then
						return tower
					end
				end
			end
		end
	end

	return nil
end

function EntityHelp.GetSpawnedTowerForAnchor(anchor: Model): Model?
	if anchor:GetAttribute("Kind") == "Tower" then
		local uid = anchor:GetAttribute("UID")
		if type(uid) == "string" and uid ~= "" then
			return anchor
		end
	end

	local slot = getTowerSlotFromAnchorName(anchor.Name)
	if not slot then
		return nil
	end

	local teamFolder = getTeamFolderFromTowerAnchor(anchor)
	if not teamFolder then
		return nil
	end

	local units = teamFolder:FindFirstChild("Units")
	if not units then
		return nil
	end

	for _, child in units:GetChildren() do
		if not child:IsA("Model") then
			continue
		end

		if child:GetAttribute("Kind") ~= "Tower" then
			continue
		end

		if child:GetAttribute("TowerSlot") == slot then
			return child
		end
	end

	return nil
end

function EntityHelp.GetCombatTargetForId(targetId: string): Model?
	if type(targetId) ~= "string" or targetId == "" then
		return nil
	end

	local entityModel = EntityHelp.GetEntityCharacterForUID(targetId)
	if entityModel then
		return entityModel
	end

	local gameFolder = Workspace:FindFirstChild("Game")
	local gameplay = gameFolder and gameFolder:FindFirstChild("Gameplay")
	local teams = gameplay and gameplay:FindFirstChild("Teams")
	if not teams then
		return nil
	end

	for _, teamFolder in teams:GetChildren() do
		if not teamFolder:IsA("Folder") then
			continue
		end

		local towers = teamFolder:FindFirstChild("Towers")
		local tower = towers and towers:FindFirstChild(targetId)
		if tower and tower:IsA("Model") then
			local spawned = EntityHelp.GetSpawnedTowerForAnchor(tower)
			if spawned and EntityHelp.IsTowerAlive(spawned) then
				return spawned
			end
			return nil
		end
	end

	return nil
end

function EntityHelp.IsTowerAlive(tower: Model): boolean
	if tower:GetAttribute("Destroyed") == true then
		return false
	end

	local spawned = EntityHelp.GetSpawnedTowerForAnchor(tower)
	local combatModel: Model
	if spawned then
		combatModel = spawned
	elseif getTowerSlotFromAnchorName(tower.Name) then
		-- Anchor with no spawned entity (defeated / not spawned) is not targetable
		return false
	else
		combatModel = tower
	end

	if combatModel:GetAttribute("Destroyed") == true or combatModel:GetAttribute("Despawning") == true then
		return false
	end

	local humanoid = combatModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health > 0
	end
	return combatModel.Parent ~= nil
end

function EntityHelp.GetTowerAnchorForSpawned(spawned: Model): Model?
	local team = spawned:GetAttribute("Team")
	local slot = spawned:GetAttribute("TowerSlot")
	if type(team) ~= "string" or type(slot) ~= "string" then
		return nil
	end

	local anchorName = if slot == "Left"
		then "LeftTower"
		elseif slot == "Main" then "MainTower"
		elseif slot == "Right" then "RightTower"
		else nil
	if not anchorName then
		return nil
	end

	local teamsRoot = getTeamsRoot()
	local teamFolder = teamsRoot and teamsRoot:FindFirstChild(team)
	local towers = teamFolder and teamFolder:FindFirstChild("Towers")
	local anchor = towers and towers:FindFirstChild(anchorName)
	if anchor and anchor:IsA("Model") then
		return anchor
	end

	return nil
end

function EntityHelp.IsMainTowerTargetable(leftAlive: boolean, rightAlive: boolean): boolean
	return not leftAlive or not rightAlive
end

function EntityHelp.GetTargetableEnemyTowers(teamName: TeamName): { Model }
	local towersFolder = getEnemyTowersFolder(teamName)
	if not towersFolder then
		return {}
	end

	local leftTower = towersFolder:FindFirstChild(SIDE_TOWER_NAMES[1])
	local rightTower = towersFolder:FindFirstChild(SIDE_TOWER_NAMES[2])
	local mainTower = towersFolder:FindFirstChild(MAIN_TOWER_NAME)

	local leftAlive = leftTower and leftTower:IsA("Model") and EntityHelp.IsTowerAlive(leftTower)
	local rightAlive = rightTower and rightTower:IsA("Model") and EntityHelp.IsTowerAlive(rightTower)

	local targetable: { Model } = {}

	if leftAlive then
		table.insert(targetable, leftTower :: Model)
	end
	if rightAlive then
		table.insert(targetable, rightTower :: Model)
	end
	if mainTower and mainTower:IsA("Model") and EntityHelp.IsTowerAlive(mainTower) then
		if EntityHelp.IsMainTowerTargetable(leftAlive == true, rightAlive == true) then
			table.insert(targetable, mainTower)
		end
	end

	return targetable
end

function EntityHelp.GetClosestEnemyTower(teamName: TeamName, fromPos: Vector3): Model?
	local targetable = EntityHelp.GetTargetableEnemyTowers(teamName)
	if #targetable == 0 then
		return nil
	end

	local closest: Model? = nil
	local closestDistSq = math.huge

	for _, tower in targetable do
		local anchor = getTowerAnchor(tower)
		if anchor then
			local distSq = getXZDistanceSq(fromPos, anchor)
			if distSq < closestDistSq then
				closest = tower
				closestDistSq = distSq
			end
		end
	end

	return closest
end

function EntityHelp.GetEnemyMainTower(teamName: TeamName): Model?
	local towersFolder = getEnemyTowersFolder(teamName)
	local mainTower = towersFolder and towersFolder:FindFirstChild(MAIN_TOWER_NAME)
	if mainTower and mainTower:IsA("Model") then
		return mainTower
	end
	return nil
end

function EntityHelp.GetEnemyMainTowerPosition(teamName: TeamName): Vector3?
	local mainTower = EntityHelp.GetEnemyMainTower(teamName)
	if not mainTower then
		return nil
	end
	return getTowerAnchor(mainTower)
end

function EntityHelp.GetTowerDetectionRadius(tower: Model, unitRange: number): number
	return math.max(unitRange, getTowerClearRadius(tower))
end

function EntityHelp.GetTowerApproachStopRadius(tower: Model, unitRange: number): number
	local detectionRadius = EntityHelp.GetTowerDetectionRadius(tower, unitRange)
	local clearRadius = getTowerClearRadius(tower)
	local desired = unitRange + TOWER_APPROACH_BUFFER
	return math.max(1, math.min(desired, clearRadius - 1, detectionRadius - 2))
end

function EntityHelp.GetTowerApproachPosition(tower: Model, fromPos: Vector3, stopRadius: number): Vector3
	local anchor = getTowerAnchor(tower)
	if not anchor then
		return fromPos
	end

	local flatOffset = Vector3.new(fromPos.X - anchor.X, 0, fromPos.Z - anchor.Z)
	local approachX: number
	local approachZ: number

	if flatOffset.Magnitude <= stopRadius then
		approachX = fromPos.X
		approachZ = fromPos.Z
	else
		local approach = anchor + flatOffset.Unit * stopRadius
		approachX = approach.X
		approachZ = approach.Z
	end

	local groundY = getGroundYAt(approachX, approachZ, fromPos.Y, { tower :: Instance })
	return Vector3.new(approachX, groundY, approachZ)
end

function EntityHelp.GetPathAgentParameters(model: Model): { [string]: any }
	local _cf, size = model:GetBoundingBox()
	local agentRadius = math.clamp(math.max(size.X, size.Z) * 0.5, 1.5, 4)

	return {
		AgentRadius = agentRadius,
		AgentHeight = math.max(size.Y, 4),
		AgentCanJump = true,
		AgentCanClimb = false,
		Costs = {
			EntityBarrier = 100,
		},
		PathSettings = {
			SupportPartialPath = true,
		},
	}
end

function EntityHelp.GetEnemyTowerPosition(teamName: TeamName, fromPos: Vector3?): Vector3?
	if fromPos then
		local closestTower = EntityHelp.GetClosestEnemyTower(teamName, fromPos)
		if closestTower then
			return getTowerAnchor(closestTower)
		end
	end

	return EntityHelp.GetEnemyMainTowerPosition(teamName)
end

function EntityHelp.GetTowerDataById(towerId: string): TowerEntityData?
	if type(towerId) ~= "string" or towerId == "" then
		return nil
	end

	return TOWER_RECIPES[towerId]
end

-- Unit card recipe by CardId (e.g. "Sabre") — not player save data
function EntityHelp.GetEntityDataByCardId(cardId: string): EntityData?
	if type(cardId) ~= "string" or cardId == "" then
		return nil
	end

	local UnitCardRegistry = require(ReplicatedStorage.Shareds.Classes.Tree.Build.MetaData.UnitCardRegistry)
	UnitCardRegistry.EnsureLoaded()
	return UnitCardRegistry.Get(cardId) :: EntityData?
end

-- Optional Kind: if Tower and Unit share the same name (e.g. Dummy), pass "Unit" or "Tower"
function EntityHelp.GetEntityForName(Name: EntityName, Kind: EntityType?): (EntityDef?, EntityType?)
	if Kind == "Tower" then
		local def = findInFolder(TowerFolder, Name)
		if def then
			return def, "Tower"
		end
		return nil, nil
	end

	if Kind == "Unit" then
		local def = findInFolder(UnitsFolder, Name)
		if def then
			return def, "Unit"
		end
		return nil, nil
	end

	local towerDef = findInFolder(TowerFolder, Name)
	if towerDef then
		return towerDef, "Tower"
	end

	local unitDef = findInFolder(UnitsFolder, Name)
	if unitDef then
		return unitDef, "Unit"
	end

	return nil, nil
end

return EntityHelp
