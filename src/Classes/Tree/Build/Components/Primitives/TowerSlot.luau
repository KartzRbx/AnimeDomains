--!strict
-- Behavior: runtime tower slot ("Left" | "Main" | "Right")

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local TowerSlot = Mega.World:component() :: any

return TowerSlot
