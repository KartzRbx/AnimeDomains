--!strict
-- Behavior: tower recipe config (registered by TowerMetaData.EnsureLoaded)

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
	DelayAttack: number,
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
	BaseDamage = 35,
	BaseRange = 18,
	DelayAttack = 1,
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

return Tower
