--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- Boot Debi channels (creates _debi.*) before services
require(ReplicatedStorage.Shareds.Networker.Net)

const EnergyService = require(ServerScriptService.Source.Services.EnergyService)
const CardsServiceServer = require(ServerScriptService.Source.Services.CardsService)
const GameplayServiceServer = require(ServerScriptService.Source.Services.GameplayService)

EnergyService:Init()
CardsServiceServer:Init()
GameplayServiceServer:Init()
