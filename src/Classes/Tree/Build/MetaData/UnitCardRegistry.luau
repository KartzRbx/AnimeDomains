--!strict
-- Behavior: Unit card params by CardId (sem Mega — evita ciclo com EntityHelper)

const ReplicatedStorage = game:GetService("ReplicatedStorage")

export type UnitCardParams = {
	Id: string,
	Name: string,
	Level: number,
	Class: string,
	EnergyCost: number,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: number,
	DelayAttack: number,
	DeployTime: number,
	CardImage: string,
	CardBack: string,
	ModelID: string,
	Walk: number,
	TargetKind: string,
	CanRetargetTroops: boolean,
	ExpCurrent: number,
	ExpMax: number,
}

local registry: { [string]: UnitCardParams } = {}
local datasLoaded = false
local UnitsFolder = ReplicatedStorage.Shareds.Classes.Tree.Datas.Units

local UnitCardRegistry = {}

function UnitCardRegistry.Set(cardId: string, params: UnitCardParams)
	registry[cardId] = params
end

function UnitCardRegistry.Get(cardId: string): UnitCardParams?
	return registry[cardId]
end

function UnitCardRegistry.MarkLoaded()
	datasLoaded = true
end

function UnitCardRegistry.IsLoaded(): boolean
	return datasLoaded
end

-- Carrega Modulescripts de Units (popula registry via UnitsMetaData.new)
function UnitCardRegistry.EnsureLoaded()
	if datasLoaded then
		return
	end
	datasLoaded = true

	for _, child in UnitsFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			(require :: any)(child)
		end
	end
end

return UnitCardRegistry
