--!strict
-- Behavior: runtime entity kind ("Unit" | "Tower" | …)

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local Kind = Mega.World:component() :: any

return Kind
