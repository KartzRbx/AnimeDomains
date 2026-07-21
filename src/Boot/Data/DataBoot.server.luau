const ReplicatedStorage = game:GetService("ReplicatedStorage")
const PlayerData = require(ReplicatedStorage.Shareds.Constants.Datas.PlayerData)
const DataServiceV2 = require(ReplicatedStorage.Shareds.Workers.DataServiceV2).Server


DataServiceV2:Init({
    UseMock = true,
    Template = PlayerData,
    StoreName = 'BETA',
    KeyPrefix = 'Player_',
    StrictPaths = true,
    AutoCreateMissingTables = false
})