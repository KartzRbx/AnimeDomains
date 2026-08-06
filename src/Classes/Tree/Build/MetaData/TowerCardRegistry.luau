--!strict
-- Behavior: Tower recipe params by TowerId (sem Mega — evita ciclo)

const ReplicatedStorage = game:GetService("ReplicatedStorage")

export type TowerCardParams = {
	Id: string,
	Name: string,
	Level: number,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: number,
	DelayAttack: number,
	EnergyCost: number,
	Walk: number,
	TargetKind: string,
	HealthPerLevel: number,
	DamagePerLevel: number,
}

local registry: { [string]: TowerCardParams } = {}
local datasLoaded = false
local TowersFolder = ReplicatedStorage.Shareds.Classes.Tree.Datas.Towers

local TowerCardRegistry = {}

function TowerCardRegistry.Set(towerId: string, params: TowerCardParams)
	registry[towerId] = params
end

function TowerCardRegistry.Get(towerId: string): TowerCardParams?
	return registry[towerId]
end

function TowerCardRegistry.MarkLoaded()
	datasLoaded = true
end

function TowerCardRegistry.IsLoaded(): boolean
	return datasLoaded
end

function TowerCardRegistry.EnsureLoaded()
	if datasLoaded then
		return
	end

	local TowerMetaData = require(script.Parent.TowerMetaData)
	TowerMetaData.EnsureLoaded()
end

return TowerCardRegistry
