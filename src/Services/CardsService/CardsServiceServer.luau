--!strict
-- Behavior: validates client PlaceUnit via typed Debi

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Debi = require(ReplicatedStorage.Shareds.Networker.Net).Game
const CardsServiceType = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceType)

local CardServiceServer = {
	Initialized = false,
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
		and isValidVec3(payload.Position)
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

	-- Create World entity (TODO)
end

function CardServiceServer.Init(self: CardServiceServer): CardServiceServer
	if self.Initialized then
		return self
	end

	self.Initialized = true

	Debi.PutCardInPlace.SetCallback(function(player: Player, payload)
		self:PutCardInPlace(player, payload :: CardsServiceType.PlaceUnitRequest)
	end)

	return self
end

return CardServiceServer
