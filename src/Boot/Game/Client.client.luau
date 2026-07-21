--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Boot Debi channels early (wires OnClientEvent before Unreliable fires)
require(ReplicatedStorage.Shareds.Networker.Net)

const EnergyServiceClient = require(ReplicatedStorage.Shareds.Services.EnergyService.EnergyServiceClient)
const CardsServiceClient = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceClient)
const GameplayServiceClient = require(ReplicatedStorage.Shareds.Services.GameplayService.GameplayServiceClient)

EnergyServiceClient:Init()
CardsServiceClient:Init()
GameplayServiceClient:Init()
