--!strict
-- Behavior: validates PlaceUnit, cycles hand (4 slots + NextCard), syncs to client

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Debi = require(ReplicatedStorage.Shareds.Networker.NetServer).Game
const CardsEntityManager = require(ReplicatedStorage.Shareds.Services.CardsService.CardsEntityManager)
const EnergyService = require(script.Parent.EnergyService)
const CardsServiceType = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceType)
const CardsServiceUtils = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceUtils)
const EnergyConstants = require(ReplicatedStorage.Shareds.Services.EnergyService.EnergyConstants)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)

local CardServiceServer = {
	Initialized = false,
	PlayerHands = {} :: { [Player]: CardsServiceUtils.MatchCardState },
}

export type CardServiceServer = typeof(CardServiceServer)

@native
local function isValidVec3(position: any): boolean
	return type(position) == "table"
		and type(position.X) == "number"
		and type(position.Y) == "number"
		and type(position.Z) == "number"
end

@native
local function isValidPlaceRequest(payload: any): boolean
	return type(payload) == "table"
		and type(payload.CardId) == "string"
		and payload.CardId ~= ""
		and type(payload.SlotIndex) == "number"
		and payload.SlotIndex >= 1
		and payload.SlotIndex <= CardsServiceUtils.HAND_SIZE
		and isValidVec3(payload.Position)
end

local function syncHand(self: CardServiceServer, player: Player)
	local state = self.PlayerHands[player]
	if not state then
		return
	end

	Debi.SyncCardHand.Fire(player, CardsServiceUtils.ToSyncPayload(state))
end

local function trySpendEnergy(player: Player, cardId: string): (boolean, string?)
	local entityData = EntityHelper.GetEntityDataByCardId(cardId)
	if not entityData then
		return false, "Invalid Card"
	end

	local energy = EnergyService:GetPlayerEnergy(player)
	if energy == nil or energy < entityData.EnergyCost then
		return false, "Insufficient Energy"
	end

	local result = math.clamp(
		energy - entityData.EnergyCost,
		EnergyConstants.MIN_ENERGY,
		EnergyConstants.MAX_ENERGY
	)
	EnergyService:SetPlayerEnergy(player, result)
	return true, nil
end

function CardServiceServer.BindPlayerHand(self: CardServiceServer, player: Player, deck: { string })
	local state = CardsServiceUtils.CreateMatchCardState(deck)
	self.PlayerHands[player] = state
	syncHand(self, player)
end

function CardServiceServer.ClearPlayerHand(self: CardServiceServer, player: Player)
	self.PlayerHands[player] = nil
end

function CardServiceServer.GetPlayerHand(self: CardServiceServer, player: Player): CardsServiceUtils.MatchCardState?
	return self.PlayerHands[player]
end

function CardServiceServer.PutCardInPlace(
	self: CardServiceServer,
	player: Player,
	payload: CardsServiceType.PlaceUnitRequest
): ()
	if not isValidPlaceRequest(payload) then
		warn(`[CardsServiceServer] Invalid PlaceUnit from {player.Name}`)
		return
	end

	local state = self.PlayerHands[player]
	if not state then
		warn(`[CardsServiceServer] No hand for {player.Name}`)
		return
	end

	if state.Hand[payload.SlotIndex] ~= payload.CardId then
		warn(`[CardsServiceServer] Slot mismatch from {player.Name}`)
		syncHand(self, player)
		return
	end

	local energyOk, energyReason = trySpendEnergy(player, payload.CardId)
	if not energyOk then
		warn(energyReason)
		syncHand(self, player)
		return
	end

	local playOk, playReason = CardsServiceUtils.PlayCardFromHand(state, payload.SlotIndex, payload.CardId)
	if not playOk then
		warn(playReason)
		syncHand(self, player)
		return
	end

		--[[
			  00:10:09.848   ▼  {
                    ["CardId"] = "PlaceholderFour",
                    ["Position"] =  ▼  {
                       ["X"] = 211.2488250732422,
                       ["Y"] = 54.8416633605957,
                       ["Z"] = 133.9837341308594
                    },
                    ["SlotIndex"] = 1
                 }  -  Servidor - CardsEntityManager:10
		]]
	-- TODO: insert entity on map at payload.Position
	const GenerateEnemyData = {
		CardId = payload.CardId,
		Position = payload.Position,
		Player = player
	} :: CardsServiceType.NewEntityCardData

	const newEntityData = CardsEntityManager:newEntity(GenerateEnemyData)
	if newEntityData then
		Debi.SpawnEntityInMapFromServer.FireAll(newEntityData)
	end

	syncHand(self, player)
end

function CardServiceServer.Init(self: CardServiceServer): CardServiceServer
	if self.Initialized then
		return self
	end

	self.Initialized = true
	self.PlayerHands = {}

	Debi.PutCardInPlace.SetCallback(function(player: Player, payload)
		self:PutCardInPlace(player, payload)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:ClearPlayerHand(player)
	end)

	return self
end

return CardServiceServer
