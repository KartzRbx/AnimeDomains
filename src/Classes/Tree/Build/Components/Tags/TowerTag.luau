--!strict
-- Behavior: jecs tag that marks entity as Tower (query with no data)

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local TowerTag = Mega.World:entity() 

return TowerTag
