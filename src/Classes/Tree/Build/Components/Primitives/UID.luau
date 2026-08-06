--!strict
-- Behavior: runtime combat UID (string) on World entity

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local UID = Mega.World:component() :: any

return UID
