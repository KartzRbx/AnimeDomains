--!strict
-- Behavior: unit's current building-focus entity id (spawned tower)

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local BuildingTarget = Mega.World:component() :: any

return BuildingTarget
