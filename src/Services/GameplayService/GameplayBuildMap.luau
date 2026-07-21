--!strict
-- Behavior: clones Build + syncs Towers/PlayerSpawn/EntitySpawnZone(Main/Left/Right).

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Workspace = game:GetService("Workspace")

const GameplayTypes = require(ReplicatedStorage.Shareds.Services.GameplayService.GameplayTypes)
const Islands = require(ReplicatedStorage.Shareds.Constants.Datas.Islands)
const CollisionGroupsUtils = require(ReplicatedStorage.Shareds.Utils.CollisionGroupsUtils)

const GameplayBuildMap = {}

export type GameplayBuildMap = typeof(GameplayBuildMap)

local function FindChild(parent: Instance?, name: string): Instance?
	if not parent then
		return nil
	end

	return parent:FindFirstChild(name)
end

local function GetOrCreateFolder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)

	if folder and folder:IsA("Folder") then
		return folder
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = name
	newFolder.Parent = parent
	return newFolder
end

local function GetGameFolder(): Folder
	return GetOrCreateFolder(Workspace, "Game")
end

local function GetBuildsFolder(): Folder
	return GetOrCreateFolder(GetGameFolder(), "Builds")
end

local function GetTeamsRoot(): Folder
	local gameplay = GetOrCreateFolder(GetGameFolder(), "Gameplay")
	return GetOrCreateFolder(gameplay, "Teams")
end

local function GetTeamFolder(teamName: string): Folder
	local teamFolder = GetOrCreateFolder(GetTeamsRoot(), teamName)
	GetOrCreateFolder(teamFolder, "Towers")
	GetOrCreateFolder(teamFolder, "Units")
	GetOrCreateFolder(teamFolder, "Players")
	GetOrCreateFolder(teamFolder, "Interactions")
	return teamFolder
end

local function ClearFolder(folder: Folder): ()
	for _, child in folder:GetChildren() do
		child:Destroy()
	end
end

local function ConfigureEntityLimitations(buildClone: Instance): ()
	local limitations = FindChild(buildClone, "EntityLimitations")

	if limitations then
		CollisionGroupsUtils.AssignEntityBarriers(limitations)
	end
end

local function CloneBuildToWorkspace(mapModel: Instance): boolean
	local sourceBuild = FindChild(mapModel, "Build") or FindChild(mapModel, "build")

	if not sourceBuild then
		warn("GameplayBuildMap: Build not found in map", mapModel.Name)
		return false
	end

	local buildsFolder = GetBuildsFolder()
	ClearFolder(buildsFolder)

	local buildClone = sourceBuild:Clone()
	buildClone.Parent = buildsFolder

	ConfigureEntityLimitations(buildClone)

	return true
end

local function SyncTowers(sourceTowers: Instance?, destinationTowers: Instance?): ()
	if not sourceTowers or not destinationTowers then
		return
	end

	for _, child in destinationTowers:GetChildren() do
		child:Destroy()
	end

	for _, towerModel in sourceTowers:GetChildren() do
		if towerModel:IsA("Model") or towerModel:IsA("BasePart") then
			local towerClone = towerModel:Clone() :: Model
			towerClone.Parent = destinationTowers
		end
	end
end

local function ConfigureSpawnZonePart(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Transparency = 1
	part.CastShadow = false
	part:SetAttribute("Unlocked", false)
	-- Highlight: leave alone (as in Studio)
end

local function SyncInteractionPart(
	sourceInteractions: Instance,
	destinationInteractions: Instance,
	partName: string
): ()
	local sourcePart = FindChild(sourceInteractions, partName)

	if not sourcePart then
		warn(`GameplayBuildMap: {partName} not found in source interactions`)
		return
	end

	local oldPart = FindChild(destinationInteractions, partName)
	if oldPart then
		oldPart:Destroy()
	end

	local partClone = sourcePart:Clone()

	if partClone:IsA("BasePart") then
		partClone.Anchored = true
		partClone.CanCollide = false
		partClone.CanTouch = false
		partClone.CanQuery = true
	end

	partClone.Parent = destinationInteractions
end

local function SyncEntitySpawnZone(sourceInteractions: Instance, destinationInteractions: Instance): ()
	local sourceZone = FindChild(sourceInteractions, "EntitySpawnZone")
	if not sourceZone then
		warn("GameplayBuildMap: EntitySpawnZone not found in source interactions")
		return
	end

	local oldZone = FindChild(destinationInteractions, "EntitySpawnZone")
	if oldZone then
		oldZone:Destroy()
	end

	local zoneClone = sourceZone:Clone()
	zoneClone.Parent = destinationInteractions

	for _, child in zoneClone:GetChildren() do
		if child:IsA("BasePart") then
			ConfigureSpawnZonePart(child)
		end
	end
end

local function SyncInteractions(sourceInteractions: Instance?, destinationInteractions: Instance?): ()
	if not sourceInteractions or not destinationInteractions then
		warn("GameplayBuildMap: Interactions folder missing while syncing team")
		return
	end

	SyncInteractionPart(sourceInteractions, destinationInteractions, "PlayerSpawn")
	SyncEntitySpawnZone(sourceInteractions, destinationInteractions)
end

local function SyncTeam(sourceTeam: Instance): ()
	local destinationTeam = GetTeamFolder(sourceTeam.Name)
	local sourceInteractions = FindChild(sourceTeam, "Interactions")

	SyncTowers(FindChild(sourceTeam, "Towers"), FindChild(destinationTeam, "Towers"))
	SyncInteractions(sourceInteractions, FindChild(destinationTeam, "Interactions"))
end

function GameplayBuildMap.BuildMap(mapModel: Instance): GameplayTypes.Result
	assert(mapModel, "GameplayBuildMap.BuildMap: mapModel is nil")

	local buildCreated = CloneBuildToWorkspace(mapModel)

	if not buildCreated then
		return false
	end

	local sourceTeams = FindChild(mapModel, "Teams")

	if not sourceTeams then
		warn("GameplayBuildMap: Teams folder not found in map", mapModel.Name)
		return false
	end

	for _, sourceTeam in sourceTeams:GetChildren() do
		if sourceTeam:IsA("Model") or sourceTeam:IsA("Folder") then
			SyncTeam(sourceTeam)
		end
	end

	return true
end

function GameplayBuildMap.BindForMap(mapId: GameplayTypes.MapId): GameplayTypes.Result
	local ok, result = pcall(function()
		local mapModel = Islands.GetMapWithId(mapId)

		if not mapModel then
			warn(`GameplayBuildMap: island config not found: {mapId}`)
			return false
		end

		return GameplayBuildMap.BuildMap(mapModel)
	end)

	if not ok then
		warn("GameplayBuildMap error:", result)
		return false
	end

	return result
end

return GameplayBuildMap
