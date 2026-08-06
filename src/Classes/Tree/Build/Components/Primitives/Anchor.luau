--!strict
-- Behavior: map tower anchor Model (path/UI), not the combat body

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local Anchor = Mega.World:component() :: any

return Anchor
