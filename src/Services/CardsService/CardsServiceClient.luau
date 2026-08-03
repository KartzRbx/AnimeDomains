const ReplicatedStorage = game:GetService("ReplicatedStorage")
const CardsServiceInterface = require(ReplicatedStorage.Shareds.Services.CardsService.Interface.CardsServiceInterface)
const CardServiceClient = {
	initialized = false
}


function CardServiceClient.Init(self: CardServiceClient)
	if self.initialized then return end 
	self.initialized = true

	

	CardsServiceInterface:Init()
end



type CardServiceClient = typeof(CardServiceClient)
return CardServiceClient
