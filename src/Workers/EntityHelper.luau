--!strict
-- Behavior: resolves Tower/Unit by ModuleScript name → { Config, create }

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const DatasFolder = ReplicatedStorage.Shareds.Classes.Tree.Datas
const TowerFolder = DatasFolder.Towers
const UnitsFolder = DatasFolder.Units

export type EntityName = string
export type EntityType = "Tower" | "Unit"
export type EntityId = number

export type EntityConfig = {
	Id: string,
}

export type DamageCalculationProperties = {
	BaseDamage: number,
	Level: number,
	DamagePerLevel: number,
	BonusDamage: number?,
	DamageMultiplier: number?,
}

export type HealthCalculationProperties = {
	BaseHealth: number,
	Level: number,
	HealthPerLevel: number,
	BonusHealth: number?,
	HealthMultiplier: number?,
}

export type RangeCalculationProperties = {
	BaseRange: number,
	Level: number,
	RangePerLevel: number,
	BonusRange: number?,
	RangeMultiplier: number?,
}

export type EntityDef = {
	Config: EntityConfig,
	create: (position: Vector3) -> EntityId,
}

local function findInFolder(folder: Folder, Name: EntityName): EntityDef?
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") and child.Name == Name then
			return require(child) :: EntityDef
		end
	end
	return nil
end

local EntityHelp = {}

function EntityHelp.CalculateDamage(props: DamageCalculationProperties): number
	local bonusDamage = props.BonusDamage or 0
	local damageMultiplier = props.DamageMultiplier or 1
	local levelDamage = props.DamagePerLevel * props.Level
	local damage = props.BaseDamage + levelDamage + bonusDamage

	return damage * damageMultiplier
end

function EntityHelp.CalculateHealth(props: HealthCalculationProperties): number
	local bonusHealth = props.BonusHealth or 0
	local healthMultiplier = props.HealthMultiplier or 1
	local levelHealth = props.HealthPerLevel * props.Level
	local health = props.BaseHealth + levelHealth + bonusHealth

	return health * healthMultiplier
end

function EntityHelp.CalculateRange(props: RangeCalculationProperties): number
	local bonusRange = props.BonusRange or 0
	local rangeMultiplier = props.RangeMultiplier or 1
	local levelRange = props.RangePerLevel * props.Level
	local range = props.BaseRange + levelRange + bonusRange

	return range * rangeMultiplier
end

-- Optional Kind: if Tower and Unit share the same name (e.g. Dummy), pass "Unit" or "Tower"
function EntityHelp.GetEntityForName(Name: EntityName, Kind: EntityType?): (EntityDef?, EntityType?)
	if Kind == "Tower" then
		local def = findInFolder(TowerFolder, Name)
		if def then
			return def, "Tower"
		end
		return nil, nil
	end

	if Kind == "Unit" then
		local def = findInFolder(UnitsFolder, Name)
		if def then
			return def, "Unit"
		end
		return nil, nil
	end

	local towerDef = findInFolder(TowerFolder, Name)
	if towerDef then
		return towerDef, "Tower"
	end

	local unitDef = findInFolder(UnitsFolder, Name)
	if unitDef then
		return unitDef, "Unit"
	end

	return nil, nil
end

return EntityHelp
