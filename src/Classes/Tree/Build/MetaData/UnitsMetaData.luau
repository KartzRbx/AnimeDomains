--!strict
-- Behavior: jecs factory — creates Unit entity + card registry for UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
local UnitTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.UnitTag)
local TemplateTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
local ID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.ID)
local ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
local Level = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Level)
local HealthBase = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.HealthBase)
local Health = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Health)
local BaseDamage = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.BaseDamage)
local Damage = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Damage)
local ModelID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.ModelID)
local Position = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Position)
local Walk = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Walk)
local Velocity = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Velocity)
local RangeBase = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.RangeBase)
local Range = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Range)
local DelayAttack = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.DelayAttack)
local EnergyCost = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.EnergyCost)
local TargetKing = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.TargetKing)
local Target = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Target)
local LastAttack = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.LastAttack)
local CanRetargetTroops = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.CanRetargetTroops)
local Class = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Class)
local Icons = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.Icons)
local World = Mega.World
local Jecs = Mega.Jecs

export type UnitId = string
export type UnitRange = number
export type UnitDelayAttack = number
export type EnergyCostValue = number
export type TargetKindValue = TargetKing.TargetKindValue

export type UnitConfig = {
	Id: UnitId,
	Name: string,
	Level: number,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: UnitRange,
	DelayAttack: UnitDelayAttack,
	EnergyCost: EnergyCostValue,
	Class: string,
	ModelID: string,
	Position: Vector3,
	Walk: number,
	Velocity: Vector3,
	TargetKind: TargetKindValue,
	CanRetargetTroops: boolean,
	CardImage: string?,
	CardBack: string?,
	ExpCurrent: number?,
	ExpMax: number?,
}

export type UnitEntity = typeof(World.entity(World))

export type UnitCardParams = {
	Id: UnitId,
	Name: string,
	Level: number,
	Class: string,
	EnergyCost: EnergyCostValue,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: UnitRange,
	DelayAttack: UnitDelayAttack,
	CardImage: string,
	CardBack: string,
	ModelID: string,
	Walk: number,
	TargetKind: TargetKindValue,
	CanRetargetTroops: boolean,
	ExpCurrent: number,
	ExpMax: number,
}

local UnitsFolder = ReplicatedStorage.Shareds.Classes.Tree.Datas.Units
local datasLoaded = false
local CardRegistry: { [string]: UnitCardParams } = {}
local TemplateRegistry: { [string]: UnitEntity } = {}

export type SpawnFromIdOptions = {
	Position: Vector3?,
	Model: Model?,
}

local function resolveUnitIcons(unitId: string): (string, string)
	local units = Icons.Cards.Units :: { [string]: { Front: string, Back: string } }
	local unitIcons = units[unitId]
	if unitIcons then
		return unitIcons.Front, unitIcons.Back
	end
	return "", ""
end

local function toCardParams(config: UnitConfig): UnitCardParams
	local front, back = resolveUnitIcons(config.Id)
	local expMax = config.ExpMax or math.max(100, config.Level * 100)
	local expCurrent = config.ExpCurrent or math.floor(expMax * 0.5)

	return {
		Id = config.Id,
		Name = config.Name,
		Level = config.Level,
		Class = config.Class,
		EnergyCost = config.EnergyCost,
		BaseHealth = config.BaseHealth,
		BaseDamage = config.BaseDamage,
		BaseRange = config.BaseRange,
		DelayAttack = config.DelayAttack,
		CardImage = config.CardImage or front,
		CardBack = config.CardBack or back,
		ModelID = config.ModelID,
		Walk = config.Walk,
		TargetKind = config.TargetKind,
		CanRetargetTroops = config.CanRetargetTroops,
		ExpCurrent = expCurrent,
		ExpMax = expMax,
	}
end

local function new(config: UnitConfig): UnitEntity
	local entity = World:entity()
	World:set(entity, Jecs.Name, `Unit.{config.Id}`)
	World:add(entity, UnitTag)
	World:add(entity, TemplateTag)
	World:set(entity, ID, config.Id)
	World:set(entity, Level, config.Level)
	World:set(entity, HealthBase, config.BaseHealth)
	World:set(entity, Health, config.BaseHealth)
	World:set(entity, BaseDamage, config.BaseDamage)
	World:set(entity, Damage, config.BaseDamage)
	World:set(entity, ModelID, config.ModelID)
	World:set(entity, Position, config.Position)
	World:set(entity, Walk, config.Walk)
	World:set(entity, Class, config.Class)
	World:set(entity, Velocity, config.Velocity)
	World:set(entity, RangeBase, config.BaseRange)
	World:set(entity, Range, config.BaseRange)
	World:set(entity, DelayAttack, config.DelayAttack)
	World:set(entity, EnergyCost, config.EnergyCost)
	World:set(entity, TargetKing, config.TargetKind)
	World:set(entity, Target, 0)
	World:set(entity, LastAttack, 0)
	World:set(entity, CanRetargetTroops, config.CanRetargetTroops)

	CardRegistry[config.Id] = toCardParams(config)
	TemplateRegistry[config.Id] = entity
	return entity
end

local function EnsureLoaded()
	if datasLoaded then
		return
	end
	datasLoaded = true

	for _, child in UnitsFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			require(child)
		end
	end
end

local function GetCardParams(unitId: string): UnitCardParams?
	EnsureLoaded()
	return CardRegistry[unitId]
end

local function GetTemplate(unitId: string): UnitEntity?
	EnsureLoaded()
	return TemplateRegistry[unitId]
end

-- New entity with the same params as the ID (does not reuse the metadata)
local function SpawnFromId(unitId: string, options: SpawnFromIdOptions?): UnitEntity?
	EnsureLoaded()

	local template = TemplateRegistry[unitId]
	if not template then
		warn(`[UnitsMetaData] SpawnFromId: template missing "{unitId}"`)
		return nil
	end

	local entity = World:entity()
	World:set(entity, Jecs.Name, `Unit.{unitId}.Instance`)
	World:add(entity, UnitTag)

	World:set(entity, ID, World:get(template, ID))
	World:set(entity, Level, World:get(template, Level))
	World:set(entity, HealthBase, World:get(template, HealthBase))
	World:set(entity, Health, World:get(template, HealthBase))
	World:set(entity, BaseDamage, World:get(template, BaseDamage))
	World:set(entity, Damage, World:get(template, BaseDamage))
	World:set(entity, ModelID, World:get(template, ModelID))
	World:set(entity, Walk, World:get(template, Walk))
	World:set(entity, Class, World:get(template, Class))
	World:set(entity, Velocity, World:get(template, Velocity) or Vector3.zero)
	World:set(entity, RangeBase, World:get(template, RangeBase))
	World:set(entity, Range, World:get(template, RangeBase))
	World:set(entity, DelayAttack, World:get(template, DelayAttack))
	World:set(entity, EnergyCost, World:get(template, EnergyCost))
	World:set(entity, TargetKing, World:get(template, TargetKing))
	World:set(entity, CanRetargetTroops, World:get(template, CanRetargetTroops))
	World:set(entity, Target, 0)
	World:set(entity, LastAttack, 0)

	local position = if options and options.Position then options.Position else Vector3.zero
	World:set(entity, Position, position)

	if options and options.Model then
		World:set(entity, ModelComponent, options.Model)
	end

	return entity
end

return {
	new = new,
	EnsureLoaded = EnsureLoaded,
	GetCardParams = GetCardParams,
	GetTemplate = GetTemplate,
	SpawnFromId = SpawnFromId,
}
