
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const dataservicev2 = require(ReplicatedStorage.Packages.dataservicev2)

-- Paths NÃO é Schema — é PathTree. Cast pra Schema + PathOf do package quebra o LSP
-- ("PathOf setproperty type expected, got string"). any até o package alinhar o typefunction.
return table.freeze({
	Server = dataservicev2.Server,
	Client = dataservicev2.Client,
	Paths = dataservicev2.Paths :: any,
	Enums = dataservicev2.Enum,
})
