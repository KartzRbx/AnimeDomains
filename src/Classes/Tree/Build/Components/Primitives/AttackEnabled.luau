--!strict
-- Behavior: runtime in-range attack gate

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local AttackEnabled = Mega.World:component() :: any

return AttackEnabled
