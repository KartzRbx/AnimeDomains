--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- Boot Debi channels (creates _debi.*) before services
require(ReplicatedStorage.Shareds.Networker.NetServer)

const EnergyService = require(ServerScriptService.Source.Services.EnergyService)
const CardsServiceServer = require(ServerScriptService.Source.Services.CardsService)
const GameplayServiceServer = require(ServerScriptService.Source.Services.GameplayService)
const TowerServiceServer = require(ServerScriptService.Source.Services.TowerService)

EnergyService:Init()
CardsServiceServer:Init()
TowerServiceServer:Init()
GameplayServiceServer:Init()
