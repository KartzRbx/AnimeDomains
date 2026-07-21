--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

export type TargetKindValue = "Buildings" | "Ground" | "Air" | "All"

local TargetKing = Mega.World:component()
return TargetKing
