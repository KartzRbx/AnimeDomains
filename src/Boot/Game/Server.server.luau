--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- Boot Debi channels (creates _debi.*) before services
require(ReplicatedStorage.Shareds.Networker.NetServer)

const EnergyService = require(ServerScriptService.Source.Services.EnergyService)
const CardsServiceServer = require(ServerScriptService.Source.Services.CardsService)
const GameplayServiceServer = require(ServerScriptService.Source.Services.GameplayService)
const TowerServiceServer = require(ServerScriptService.Source.Services.TowerService)
const TreeSchedule = require(ReplicatedStorage.Shareds.Classes.Tree.Systems.Schedule)
const UnitsMetaData = require(ReplicatedStorage.Shareds.Classes.Tree.Build.MetaData.UnitsMetaData)
const TowerMetaData = require(ReplicatedStorage.Shareds.Classes.Tree.Build.MetaData.TowerMetaData)

UnitsMetaData.EnsureLoaded()
TowerMetaData.EnsureLoaded()

EnergyService:Init()
CardsServiceServer:Init()
TowerServiceServer:Init()
GameplayServiceServer:Init()

TreeSchedule.Start()
