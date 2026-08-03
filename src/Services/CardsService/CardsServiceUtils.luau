--!strict
-- Behavior: match hand cycle (4 active + NextCard + draw queue)

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const CardsCutscenes = require(script.Parent.Api.CardsCutscenes)
const DataServiceV2 = require(ReplicatedStorage.Shareds.Workers.DataServiceV2)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const PlacementZoneUtils = require(ReplicatedStorage.Shareds.Utils.PlacementZoneUtil)

const HAND_SIZE = 4
const TARGET_CYCLE_SIZE = 8

export type CardData = {
	Id: string,
	Level: number,
	Count: number?,
}

-- Lookup from player save (Paths.Game.Cards)
export type PlayerCardData = {
	UID: string,
	Id: string,
	Level: number,
	Count: number,
	Kind: CardKind,
}

export type MatchCardState = {
	Hand: { string },
	NextCard: string,
	Queue: { string },
}

const CardsServiceUtils = {
	HAND_SIZE = HAND_SIZE,
	TARGET_CYCLE_SIZE = TARGET_CYCLE_SIZE,
}

export type CardKind = "Unit" | "Tower"

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

function CardsServiceUtils._GetCardDataWithID(CardId: string, toPlayer: Player?): PlayerCardData?
	const Paths = DataServiceV2.Paths

	local cardsMap: { [string]: any }? = nil

	if RunService:IsClient() and Players.LocalPlayer then
		const DataService = DataServiceV2.Client
		const data = DataService:WaitForData()
		cardsMap = data:Get(Paths.Game.Cards)
	else
		assert(toPlayer, "[CardsServiceUtils] toPlayer required on server")
		const Data = DataServiceV2.Server:WaitFor(toPlayer)
		cardsMap = Data:Get(Paths.Game.Cards)
	end

	if not cardsMap then
		return nil
	end

	for UID, cardData in cardsMap do
		if cardData.Id == CardId then
			const result: PlayerCardData = {
				UID = UID,
				Id = cardData.Id,
				Level = cardData.Level,
				Count = cardData.Count or 0,
				Kind = "Unit",
			}
			return result
		end
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

function CardsServiceUtils.GetEntityLookCFrame(player: Player, spawnPos: Vector3): CFrame
	local teamName = CardsServiceUtils.GetPlayerTeam(player)
	local enemyTowerPosition = teamName and EntityHelper.GetEnemyTowerPosition(teamName, spawnPos)
	if enemyTowerPosition then
		return CFrame.lookAt(
			spawnPos,
			Vector3.new(enemyTowerPosition.X, spawnPos.Y, enemyTowerPosition.Z)
		)
	end
	return CFrame.new(spawnPos)
end

function CardsServiceUtils.GetEntityGoalCFrame(player: Player, spawnPos: Vector3, model: Model): CFrame
	const lookCFrame = CardsServiceUtils.GetEntityLookCFrame(player, spawnPos)
	const floorOffset = CardsCutscenes:GetEntityFloorOffset(model)
	return lookCFrame * CFrame.new(0, floorOffset, 0)
end

return CardsServiceUtils
