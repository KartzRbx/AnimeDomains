--!strict

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const EnergyService = require(script.Parent.EnergyService)
const CardsServiceServer = require(script.Parent.CardsService)
const GameplayTypes = require(ReplicatedStorage.Shareds.Services.GameplayService.GameplayTypes)
const GameplayBuildMap = require(ReplicatedStorage.Shareds.Services.GameplayService.GameplayBuildMap)
const PlacementZoneUtils = require(ReplicatedStorage.Shareds.Utils.PlacementZoneUtil)
const Islands = require(ReplicatedStorage.Shareds.Constants.Datas.Islands)
const Debi = require(ReplicatedStorage.Shareds.Networker.NetServer).Game
const Janitor = require(ReplicatedStorage.Packages.janitor)
const DataServiceV2 = require(ReplicatedStorage.Shareds.Workers.DataServiceV2)
const Server = DataServiceV2.Server
const Paths = DataServiceV2.Paths

const SUPPORTED_GAMEMODES: { [string]: boolean } = {
	["1v1"] = true,
}

type JanitorObject = typeof(Janitor.new())

const GameplayServiceServer = {
	Initialized = false,
	Janitor = nil :: JanitorObject?,
	Matches = {} :: GameplayTypes.MatchMap,
	NextMatchNumber = 0,
	CurrentMapId = nil :: GameplayTypes.MapId?,
}

const function AsString(value: any, fallback: string): string
	if type(value) == "string" and value ~= "" then
		return value
	end

	return fallback
end

const function AsNumber(value: any, fallback: number): number
	if type(value) == "number" then
		return value
	end

	return fallback
end

const function NormalizeTowerInfo(value: any): GameplayTypes.TowerInfo
	if type(value) == "table" then
		return {
			Id = AsString(value.Id, "Dummy"),
			Level = AsNumber(value.Level, 1),
		}
	end

	if type(value) == "string" then
		return {
			Id = value,
			Level = 1,
		}
	end

	return {
		Id = "Dummy",
		Level = 1,
	}
end

const function GetTowersFromPlayerData(playerData: any): GameplayTypes.TeamTowers
	local towers = playerData:Get(Paths.Game.Towers)

	if type(towers) ~= "table" then
		return {
			Left = { Id = "Dummy", Level = 1 },
			Main = { Id = "Dummy", Level = 1 },
			Right = { Id = "Dummy", Level = 1 },
		}
	end

	return {
		Left = NormalizeTowerInfo(towers.Left),
		Main = NormalizeTowerInfo(towers.Main),
		Right = NormalizeTowerInfo(towers.Right),
	}
end

const function GetDeckFromPlayerData(playerData: any): { string }
	local deck: { string } = {}
	local savedDeck = playerData:Get(Paths.Game.Deck)

	if type(savedDeck) == "table" then
		for _, cardId in savedDeck do
			if type(cardId) == "string" and cardId ~= "" then
				table.insert(deck, cardId)
			end
		end
	end

	if #deck == 0 then
		local cards = playerData:Get(Paths.Game.Cards)

		if type(cards) == "table" then
			for _, cardData in cards do
				if type(cardData) == "table" and type(cardData.Id) == "string" and cardData.Id ~= "" then
					table.insert(deck, cardData.Id)
				end
			end
		end
	end

	if #deck == 0 then
		table.insert(deck, "Sabre")
	end

	return deck
end

const function GetTeamFolder(teamName: string): Folder?
	local gameFolder = workspace:FindFirstChild("Game")
	local gameplay = gameFolder and gameFolder:FindFirstChild("Gameplay")
	local teams = gameplay and gameplay:FindFirstChild("Teams")
	local teamFolder = teams and teams:FindFirstChild(teamName)
	if teamFolder and teamFolder:IsA("Folder") then
		return teamFolder
	end
	return nil
end

const function GetTeamPlayersFolder(teamName: string): Folder?
	local teamFolder = GetTeamFolder(teamName)
	local playersFolder = teamFolder and teamFolder:FindFirstChild("Players")
	if playersFolder and playersFolder:IsA("Folder") then
		return playersFolder
	end
	return nil
end

const function GetTeamPlayerSpawn(teamName: string): BasePart?
	local teamFolder = GetTeamFolder(teamName)
	local interactions = teamFolder and teamFolder:FindFirstChild("Interactions")
	local playerSpawn = interactions and interactions:FindFirstChild("PlayerSpawn")

	if playerSpawn and playerSpawn:IsA("BasePart") then
		return playerSpawn
	end

	return nil
end

const function HasPlayerSpawn(teamName: string): boolean
	return GetTeamPlayerSpawn(teamName) ~= nil
end

const function MoveCharacterToTeamFolder(character: Model, teamName: string): ()
	local playersFolder = GetTeamPlayersFolder(teamName)
	if not playersFolder then
		warn(`[GameplayService] Players folder not found for team: {teamName}`)
		return
	end
	character.Parent = playersFolder
end

const function TeleportCharacterToSpawn(player: Player, teamName: string): ()
	local character = player.Character or player.CharacterAdded:Wait()
	local spawnPart = GetTeamPlayerSpawn(teamName)

	if not spawnPart then
		warn(`[GameplayService] PlayerSpawn not found for team: {teamName}`)
		return
	end

	MoveCharacterToTeamFolder(character, teamName)
	character:PivotTo(spawnPart.CFrame + Vector3.new(0, 3, 0))
end

function GameplayServiceServer.CreateMatchId(self: GameplayServiceServer): GameplayTypes.MatchId
	self.NextMatchNumber += 1
	return "Match_" .. tostring(self.NextMatchNumber)
end

function GameplayServiceServer.CreateDefaultProperties(player: Player): GameplayTypes.GameplayProperties
	return {
		Players = { player.Name },
		GameConfig = {
			GameType = "Single",
			GameMode = "1v1",
			MapId = "FlorestMap",
		},
	}
end


function GameplayServiceServer.GetDefaultTeamData(owner: string): GameplayTypes.TeamData
	local player = Players:FindFirstChild(owner)

	if player and player:IsA("Player") then
		local playerData = Server:WaitFor(player)

		return {
			Owner = owner,
			Data = {
				Towers = GetTowersFromPlayerData(playerData),
				Deck = GetDeckFromPlayerData(playerData),
			},
		}
	end

	-- IA
	return {
		Owner = owner,
		Data = {
			Towers = {
				Left = { Id = "Dummy", Level = 1 },
				Main = { Id = "Dummy", Level = 1 },
				Right = { Id = "Dummy", Level = 1 },
			},
			Deck = {
				"Sabre",
				"PlaceholderOne",
				"PlaceholderTwo",
				"PlaceholderThree",
				"PlaceholderFour",
				"PlaceholderFive",
				"PlaceholderSix",
				"PlaceholderSeven",
			},
		},
	}
end

function GameplayServiceServer.GetEntityStateForPlayer(
	self: GameplayServiceServer,
	player: Player
): GameplayTypes.EntityState
	local match = self:GetMatchByPlayer(player)
	local ownerOne = player.Name
	local ownerTwo = "Enemy"

	if match then
		ownerOne = match.Players[1] or player.Name
		ownerTwo = match.Players[2] or "Enemy"
	end

	return {
		One = GameplayServiceServer.GetDefaultTeamData(ownerOne),
		Two = GameplayServiceServer.GetDefaultTeamData(ownerTwo),
	}
end

function GameplayServiceServer.BuildMap(self: GameplayServiceServer, mapId: GameplayTypes.MapId): GameplayTypes.Result
	if self.CurrentMapId == mapId and HasPlayerSpawn("One") then
		return true
	end

	local result = GameplayBuildMap.BindForMap(mapId)

	if result then
		self.CurrentMapId = mapId
	end

	return result
end

function GameplayServiceServer.SendMatchState(self: GameplayServiceServer, player: Player): ()
	Debi.SetEntityState.Fire(player, self:GetEntityStateForPlayer(player))
end

function GameplayServiceServer.TeleportPlayer(self: GameplayServiceServer, player: Player, teamName: string): ()
	TeleportCharacterToSpawn(player, teamName)
end

function GameplayServiceServer.StartMatch(
	self: GameplayServiceServer,
	props: GameplayTypes.GameplayProperties
): GameplayTypes.Match
	self:BuildMap(props.GameConfig.MapId)

	const matchId = self:CreateMatchId()

	const match: GameplayTypes.Match = {
		MatchId = matchId,
		Players = props.Players,
		GameConfig = props.GameConfig,
		Status = "Running",
	}

	self.Matches[matchId] = match
	PlacementZoneUtils.ResetUnlocks()

	for index, playerName in props.Players do
		local player = Players:FindFirstChild(playerName)
		if player and player:IsA("Player") then
			local teamName = if index == 1 then "One" else "Two"
			local teamData = GameplayServiceServer.GetDefaultTeamData(player.Name)
			CardsServiceServer:BindPlayerHand(player, teamData.Data.Deck)
			EnergyService:FetchPlayerEnergy(player)

			task.spawn(function()
				if player.Character == nil then
					player.CharacterAdded:Wait()
				end
				self:TeleportPlayer(player, teamName)
				self:SendMatchState(player)
			end)
		end
	end

	print("[GameplayService] Match started:", matchId, props.GameConfig.MapId, props.GameConfig.GameMode)
	return match
end

-- Cmdr: start-match mapName gamemode players
function GameplayServiceServer.StartMatchCommand(
	self: GameplayServiceServer,
	mapName: string,
	gamemode: string,
	players: { Player }
): (boolean, string)
	assert(self.Initialized, "GameplayService not initialized")

	local mode = string.lower(gamemode)
	if not SUPPORTED_GAMEMODES[mode] then
		return false, `invalid gamemode "{gamemode}" (1v1 only)`
	end

	if Islands.GetMapWithId(mapName) == nil then
		return false, `invalid map "{mapName}"`
	end

	if mode == "1v1" then
		if #players < 1 or #players > 2 then
			return false, "1v1 needs 1 or 2 players"
		end
	end

	local playerNames: { string } = {}
	for _, player in players do
		self:EndPlayerMatch(player)
		table.insert(playerNames, player.Name)
	end

	local gameType: GameplayTypes.GameType = if #playerNames >= 2 then "Multi" else "Single"

	local match = self:StartMatch({
		Players = playerNames,
		GameConfig = {
			MapId = mapName,
			GameType = gameType,
			GameMode = "1v1",
		},
	})

	return true, `Match {match.MatchId} | map={mapName} | mode=1v1 | players={table.concat(playerNames, ", ")}`
end

-- Cmdr: end-game [players]
function GameplayServiceServer.EndMatchCommand(
	self: GameplayServiceServer,
	players: { Player }?
): (boolean, string)
	assert(self.Initialized, "GameplayService not initialized")

	if not players or #players == 0 then
		local count = 0
		for matchId: GameplayTypes.MatchId in self.Matches do
			self:EndMatch(matchId)
			count += 1
		end

		if count == 0 then
			return false, "no active matches"
		end

		return true, `ended {count} match(es)`
	end

	local ended: { string } = {}
	local seen: { [string]: boolean } = {}

	for _, player in players do
		local match = self:GetMatchByPlayer(player)
		if match and not seen[match.MatchId] then
			seen[match.MatchId] = true
			self:EndMatch(match.MatchId)
			table.insert(ended, match.MatchId)
		end
	end

	if #ended == 0 then
		return false, "no active match for selected player(s)"
	end

	return true, `ended match(es): {table.concat(ended, ", ")}`
end

-- Enemy tower fell → unlock attacker's lane (LeftTower → "Left")
function GameplayServiceServer.OnEnemyTowerDestroyed(
	self: GameplayServiceServer,
	attackerTeam: PlacementZoneUtils.TeamName,
	towerSide: PlacementZoneUtils.LaneName
)
	PlacementZoneUtils.UnlockEnemyLane(attackerTeam, towerSide)
	print(`[GameplayService] Zone unlocked | team={attackerTeam} lane={towerSide}`)
end

function GameplayServiceServer.GetMatchByPlayer(
	self: GameplayServiceServer,
	player: Player
): GameplayTypes.Match?
	for _, match in self.Matches do
		for _, playerName in match.Players do
			if playerName == player.Name then
				return match
			end
		end
	end

	return nil
end

function GameplayServiceServer.EndMatch(self: GameplayServiceServer, matchId: GameplayTypes.MatchId): GameplayTypes.Result
	const match = self.Matches[matchId]

	if not match then
		return false
	end

	match.Status = "Finished"

	for _, playerName in match.Players do
		local player = Players:FindFirstChild(playerName)
		if player and player:IsA("Player") then
			CardsServiceServer:ClearPlayerHand(player)
		end
	end

	self.Matches[matchId] = nil
	print("[GameplayService] Match finished:", matchId)

	return true
end

function GameplayServiceServer.EndPlayerMatch(self: GameplayServiceServer, player: Player): GameplayTypes.Result
	const match = self:GetMatchByPlayer(player)

	if not match then
		return false
	end

	return self:EndMatch(match.MatchId)
end

function GameplayServiceServer.Init(self: GameplayServiceServer): GameplayServiceServer
	if self.Initialized then
		return self
	end

	self.Initialized = true
	local janitor = Janitor.new()
	self.Janitor = janitor
	self.Matches = {}
	self.NextMatchNumber = 0
	self.CurrentMapId = nil

	-- Match only via Cmdr: start-match mapName gamemode players
	janitor:add(Players.PlayerRemoving:Connect(function(player: Player)
		self:EndPlayerMatch(player)
	end))

	janitor:add(function()
		for matchId: GameplayTypes.MatchId in self.Matches do
			self:EndMatch(matchId)
		end
	end, true)

	game:BindToClose(function()
		if self.Janitor then
			self.Janitor:destroy()
		end
	end)

	return self
end

export type GameplayServiceServer = typeof(GameplayServiceServer)

return GameplayServiceServer
