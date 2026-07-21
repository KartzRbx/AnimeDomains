
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const dataservicev2 = require(ReplicatedStorage.Packages.dataservicev2)
const PlayerData = require(ReplicatedStorage.Shareds.Constants.Datas.PlayerData)



return table.freeze({
	Server = dataservicev2.Server,
	Client = dataservicev2.Client,
	Paths = dataservicev2.Paths :: PlayerData.Schema,
	Enums = dataservicev2.Enum
})