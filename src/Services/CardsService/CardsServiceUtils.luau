--!strict
-- Behavior: match hand cycle (4 active + NextCard + draw queue)

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const Workspace = game:GetService("Workspace")
const DataServiceV2 = require(ReplicatedStorage.Shareds.Workers.DataServiceV2)
const PlacementZoneUtils = require(ReplicatedStorage.Shareds.Utils.PlacementZoneUtil)

const HAND_SIZE = 4
const TARGET_CYCLE_SIZE = 8


export type CardData = { Id: string, Level: number }

export type MatchCardState = {
	Hand: { string },
	NextCard: string,
	Queue: { string },
}

const CardsServiceUtils = {
	HAND_SIZE = HAND_SIZE,
	TARGET_CYCLE_SIZE = TARGET_CYCLE_SIZE,
}

local function copyList(source: { string }): { string }
	local copy = table.create(#source)
	for index, value in source do
		copy[index] = value
	end
	return copy
end

local function shuffleInPlace(list: { string })
	for index = #list, 2, -1 do
		local swapIndex = math.random(index)
		list[index], list[swapIndex] = list[swapIndex], list[index]
	end
end

function CardsServiceUtils.NormalizeDeck(deck: { string }): { string }
	local normalized: { string } = {}
	for _, cardId in deck do
		if type(cardId) == "string" and cardId ~= "" then
			table.insert(normalized, cardId)
		end
	end

	if #normalized == 0 then
		table.insert(normalized, "Sabre")
	end

	-- Pad by cycling so hand (4) + NextCard (1) always exist.
	local source = copyList(normalized)
	local index = 1
	while #normalized < HAND_SIZE + 1 do
		table.insert(normalized, source[((index - 1) % #source) + 1])
		index += 1
	end

	while #normalized < TARGET_CYCLE_SIZE do
		table.insert(normalized, source[((index - 1) % #source) + 1])
		index += 1
	end

	return normalized
end

function CardsServiceUtils.CreateMatchCardState(deck: { string }): MatchCardState
	local cycle = CardsServiceUtils.NormalizeDeck(deck)
	shuffleInPlace(cycle)

	-- Prefer 4 different cards in the active hand when the deck allows it.
	local hand = table.create(HAND_SIZE)
	local used: { [string]: boolean } = {}
	local remaining = copyList(cycle)
	local handCount = 0

	local index = 1
	while handCount < HAND_SIZE and index <= #remaining do
		local cardId = remaining[index]
		if not used[cardId] then
			handCount += 1
			hand[handCount] = cardId
			used[cardId] = true
			table.remove(remaining, index)
		else
			index += 1
		end
	end

	while handCount < HAND_SIZE and #remaining > 0 do
		handCount += 1
		hand[handCount] = table.remove(remaining, 1) :: string
	end

	local nextCard = table.remove(remaining, 1) :: string
	assert(nextCard ~= nil, "[CardsServiceUtils] NextCard missing after hand deal")

	return {
		Hand = hand,
		NextCard = nextCard,
		Queue = remaining,
	}
end

-- Play slot → NextCard fills it → queue draws new NextCard → played card goes to queue end.
function CardsServiceUtils.PlayCardFromHand(state: MatchCardState, slotIndex: number, cardId: string): (boolean, string?)
	if slotIndex < 1 or slotIndex > HAND_SIZE then
		return false, "Invalid Slot"
	end

	if state.Hand[slotIndex] ~= cardId then
		return false, "Card not in slot"
	end

	local played = state.Hand[slotIndex]
	state.Hand[slotIndex] = state.NextCard
	table.insert(state.Queue, played)
	state.NextCard = table.remove(state.Queue, 1) :: string

	return true, nil
end

function CardsServiceUtils.ToSyncPayload(state: MatchCardState): { Hand: { string }, NextCard: string }
	return {
		Hand = copyList(state.Hand),
		NextCard = state.NextCard,
	}
end

function CardsServiceUtils._GetCardDataWithID(CardId: string, toPlayer: Player?): (string?, CardData?)
	const Paths = DataServiceV2.Paths

	local resultUID: string? = nil
	local resultCardData: CardData? = nil

	if RunService:IsClient() and Players.LocalPlayer then
		const DataService = DataServiceV2.Client
		const data = DataService:WaitForData()
		const Cards = data:Get(Paths.Game.Cards)

		for UID, cardData in Cards do
			if cardData.Id == CardId then
				resultUID = UID
				resultCardData = cardData
				break
			end
		end
	else
		assert(toPlayer, "[CardsServiceUtils] toPlayer required on server")
		const Data = DataServiceV2.Server:WaitFor(toPlayer)
		const Cards = Data:Get(Paths.Game.Cards)

		for UID, cardData in Cards do
			if cardData.Id == CardId then
				resultUID = UID
				resultCardData = cardData
				break
			end
		end
	end

	return resultUID, resultCardData
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

function CardsServiceUtils.GetPlayerTeam(player: Player): PlacementZoneUtils.TeamName?
	local character = player.Character
	if not character then
		return nil
	end

	local playersFolder = character.Parent
	local teamFolder = playersFolder and playersFolder.Parent
	if teamFolder and (teamFolder.Name == "One" or teamFolder.Name == "Two") then
		return teamFolder.Name
	end

	return nil
end

function CardsServiceUtils.GetEnemyMainTowerPosition(teamName: PlacementZoneUtils.TeamName): Vector3?
	local enemy = PlacementZoneUtils.GetEnemyTeam(teamName)
	local teamsRoot = getTeamsRoot()
	local teamFolder = teamsRoot and teamsRoot:FindFirstChild(enemy)
	local towers = teamFolder and teamFolder:FindFirstChild("Towers")
	local mainTower = towers and towers:FindFirstChild("MainTower")
	if not mainTower then
		return nil
	end

	local grip = mainTower:FindFirstChild("GripEntity", true)
	if grip and grip:IsA("Attachment") then
		return grip.WorldPosition
	end

	if mainTower:IsA("Model") then
		return mainTower:GetPivot().Position
	end
	if mainTower:IsA("BasePart") then
		return mainTower.Position
	end

	return nil
end

function CardsServiceUtils.GetEnemyTowerPosition(player: Player): Vector3?
	local teamName = CardsServiceUtils.GetPlayerTeam(player)
	if not teamName then
		return nil
	end
	return CardsServiceUtils.GetEnemyMainTowerPosition(teamName)
end

return CardsServiceUtils
