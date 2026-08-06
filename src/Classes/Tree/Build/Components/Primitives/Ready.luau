--!strict
-- Behavior: runtime Ready flag (post-cutscene)

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local Ready = Mega.World:component() :: any

return Ready
