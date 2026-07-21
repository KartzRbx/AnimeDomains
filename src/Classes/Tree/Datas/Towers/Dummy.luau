--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TowerMetaData = require(ReplicatedStorage.Shareds.Classes.Tree.Build.MetaData.TowerMetaData)

export type TowerTargetKind = "Buildings" | "Ground" | "Air" | "All"

export type TowerUpgradeData = {
	DamagePerLevel: number,
	HealthPerLevel: number,
	RangePerLevel: number,
}

export type TowerData = {
	Id: string,
	Name: string,
	Level: number,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: number,
	EnergyCost: number,
	Position: Vector3,
	Walk: number,
	TargetKind: TowerTargetKind,
	Upgrade: TowerUpgradeData,
}

const Tower: TowerData = {
	Id = "Dummy",
	Name = "Dummy Tower",
	Level = 1,
	BaseHealth = 1200,
	BaseDamage = 140,
	BaseRange = 18,
	EnergyCost = 0,
	Position = Vector3.zero,
	Walk = 0,
	TargetKind = "All",
	Upgrade = table.freeze({
		DamagePerLevel = 140,
		HealthPerLevel = 140,
		RangePerLevel = 1,
	}),
}

return TowerMetaData.new(Tower)
