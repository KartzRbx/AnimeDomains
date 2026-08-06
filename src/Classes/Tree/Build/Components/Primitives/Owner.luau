--!strict
-- Behavior: runtime owner name (Player.Name or "Enemy")

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local Owner = Mega.World:component() :: any

return Owner
