--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const CardsEntityManager = require(ReplicatedStorage.Shareds.Services.CardsService.Api.CardsEntityManager)
const CardsServiceInterface = require(ReplicatedStorage.Shareds.Services.CardsService.Interface.CardsServiceInterface)

const CardServiceClient = {

	initialized = false,
}

function CardServiceClient.Init(self: CardServiceClient)
	if self.initialized then
		return
	end

	self.initialized = true

	CardsEntityManager:InitAttackValidation()
	CardsEntityManager:BindAttackReplicated()
	CardsServiceInterface:Init()
end

type CardServiceClient = typeof(CardServiceClient)

return CardServiceClient
