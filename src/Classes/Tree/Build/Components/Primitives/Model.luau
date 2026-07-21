--!strict
-- Behavior: spawn Model Instance in Workspace (not a ModelID string)

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local Model = Mega.World:component()
return Model
