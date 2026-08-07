--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Icons = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.Icons)

export type UnitTargetKind = "Buildings" | "Ground" | "Air" | "All"

export type UnitUpgradeData = {
	DamagePerLevel: number,
	HealthPerLevel: number,
	RangePerLevel: number,
}

export type UnitData = {
	Id: string,
	Name: string,
	Level: number,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: number,
	DelayAttack: number,
	DeployTime: number,
	EnergyCost: number,
	Class: string,
	ModelID: string,
	Position: Vector3,
	Walk: number,
	Velocity: Vector3,
	TargetKind: UnitTargetKind,
	CanRetargetTroops: boolean,
	CardImage: string,
	CardBack: string,
	ExpCurrent: number,
	ExpMax: number,
	Upgrade: UnitUpgradeData,
}

local Unit: UnitData = {
	Id = "Sabre",
	Name = "Sabre",
	Level = 12,
	BaseHealth = 500,
	BaseDamage = 80,
	BaseRange = 5,
	Class = "S",
	DelayAttack = 2.23,
	DeployTime = 1, -- Knight-like melee troop — CR wiki Deploy Time: 1 sec
	EnergyCost = 3,
	ModelID = "Sabre",
	Position = Vector3.zero,
	Walk = 14,
	Velocity = Vector3.zero,
	TargetKind = "Ground",
	CanRetargetTroops = true,
	CardImage = Icons.Cards.Units.Sabre.Front,
	CardBack = Icons.Cards.Units.Sabre.Back,
	ExpCurrent = 100,
	ExpMax = 200,
	Upgrade = table.freeze({
		DamagePerLevel = 80,
		HealthPerLevel = 140,
		RangePerLevel = 0,
	}),
}

return Unit
