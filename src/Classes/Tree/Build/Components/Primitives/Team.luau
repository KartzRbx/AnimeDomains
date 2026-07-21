--!strict
-- Behavior: Team component — "One" | "Two" in the World

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

export type TeamName = "One" | "Two"

local Team = Mega.World:component() 

return Team
