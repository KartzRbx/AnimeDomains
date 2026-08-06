--!strict
-- Behavior: temporary placeholder units (same Sabre model) for hand/deck testing
-- DeployTime: Clash Royale wiki — standard ground troops use 1 sec (Archers, Knight, Barbarians, etc.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Icons = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.Icons)

type PlaceholderDef = {
	Id: string,
	Name: string,
	EnergyCost: number,
	DeployTime: number,
	Class: string,
	Level: number,
	BaseHealth: number,
	BaseDamage: number,
}

local SABRE_FRONT = Icons.Cards.Units.Sabre.Front
local SABRE_BACK = Icons.Cards.Units.Sabre.Back

local PLACEHOLDERS: { PlaceholderDef } = {
	{ Id = "PlaceholderOne", Name = "Placeholder 1", EnergyCost = 2, DeployTime = 1, Class = "A", Level = 8, BaseHealth = 400, BaseDamage = 60 },
	{ Id = "PlaceholderTwo", Name = "Placeholder 2", EnergyCost = 3, DeployTime = 1, Class = "B", Level = 9, BaseHealth = 450, BaseDamage = 70 },
	{ Id = "PlaceholderThree", Name = "Placeholder 3", EnergyCost = 4, DeployTime = 1, Class = "A", Level = 10, BaseHealth = 520, BaseDamage = 85 },
	{ Id = "PlaceholderFour", Name = "Placeholder 4", EnergyCost = 2, DeployTime = 1, Class = "C", Level = 7, BaseHealth = 380, BaseDamage = 55 },
	{ Id = "PlaceholderFive", Name = "Placeholder 5", EnergyCost = 5, DeployTime = 1, Class = "S", Level = 11, BaseHealth = 600, BaseDamage = 95 },
	{ Id = "PlaceholderSix", Name = "Placeholder 6", EnergyCost = 3, DeployTime = 1, Class = "B", Level = 8, BaseHealth = 430, BaseDamage = 65 },
	{ Id = "PlaceholderSeven", Name = "Placeholder 7", EnergyCost = 4, DeployTime = 1, Class = "A", Level = 10, BaseHealth = 510, BaseDamage = 80 },
}

local configs = {}
for _, def in PLACEHOLDERS do
	table.insert(configs, {
		Id = def.Id,
		Name = def.Name,
		Level = def.Level,
		BaseHealth = def.BaseHealth,
		BaseDamage = def.BaseDamage,
		BaseRange = 5,
		Class = def.Class,
		DelayAttack = 1,
		DeployTime = def.DeployTime,
		EnergyCost = def.EnergyCost,
		ModelID = "Sabre",
		Position = Vector3.zero,
		Walk = 14,
		Velocity = Vector3.zero,
		TargetKind = "Ground",
		CanRetargetTroops = true,
		CardImage = SABRE_FRONT,
		CardBack = SABRE_BACK,
		ExpCurrent = 100,
		ExpMax = 200,
	})
end

return configs
