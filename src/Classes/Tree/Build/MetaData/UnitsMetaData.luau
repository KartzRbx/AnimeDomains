--!strict
-- Behavior: jecs factory — unit templates + runtime SpawnFromId

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
local DeployTime = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.DeployTime)
local EnergyCost = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.EnergyCost)
local TargetKing = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.TargetKing)
local Target = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Target)
local LastAttack = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.LastAttack)
local CanRetargetTroops = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.CanRetargetTroops)
local Class = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Class)
local Icons = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.Icons)
local UnitCardRegistry = require(script.Parent.UnitCardRegistry)
local World = Mega.World
local Jecs = Mega.Jecs

export type UnitId = string
export type UnitRange = number
export type UnitDelayAttack = number
export type UnitDeployTime = number
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
	DeployTime: UnitDeployTime,
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
	DeployTime: UnitDeployTime,
	CardImage: string,
	CardBack: string,
	ModelID: string,
	Walk: number,
	TargetKind: TargetKindValue,
	CanRetargetTroops: boolean,
	ExpCurrent: number,
	ExpMax: number,
}

export type SpawnFromIdOptions = {
	Position: Vector3?,
	Model: Model?,
	Level: number?,
	Health: number?,
	UID: string?,
	Owner: string?,
	Team: string?,
	Ready: boolean?,
	Kind: string?,
}

local UnitsFolder = ReplicatedStorage.Shareds.Classes.Tree.Datas.Units
local datasLoaded = false
local CardRegistry: { [string]: UnitCardParams } = {}
local TemplateRegistry: { [string]: UnitEntity } = {}

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
		DeployTime = config.DeployTime,
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

local function registerTemplate(config: UnitConfig): UnitEntity
	local existing = TemplateRegistry[config.Id]
	if existing then
		return existing
	end

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
	World:set(entity, DeployTime, config.DeployTime)
	World:set(entity, EnergyCost, config.EnergyCost)
	World:set(entity, TargetKing, config.TargetKind)
	World:set(entity, Target, 0)
	World:set(entity, LastAttack, 0)
	World:set(entity, CanRetargetTroops, config.CanRetargetTroops)

	local cardParams = toCardParams(config)
	CardRegistry[config.Id] = cardParams
	UnitCardRegistry.Set(config.Id, cardParams)
	TemplateRegistry[config.Id] = entity
	return entity
end

local function EnsureLoaded()
	if datasLoaded then
		return
	end
	datasLoaded = true
	UnitCardRegistry.MarkLoaded()

	for _, child in UnitsFolder:GetChildren() do
		if not child:IsA("ModuleScript") then
			continue
		end

		local mod = (require :: any)(child)
		if type(mod) ~= "table" then
			continue
		end

		if type(mod.Id) == "string" then
			registerTemplate(mod :: UnitConfig)
		else
			for _, cfg in mod do
				if type(cfg) == "table" and type(cfg.Id) == "string" then
					registerTemplate(cfg :: UnitConfig)
				end
			end
		end
	end
end

local function GetCardParams(unitId: string): UnitCardParams?
	EnsureLoaded()
	return UnitCardRegistry.Get(unitId) or CardRegistry[unitId]
end

local function GetTemplate(unitId: string): UnitEntity?
	EnsureLoaded()
	return TemplateRegistry[unitId]
end

local function SpawnFromId(unitId: string, options: SpawnFromIdOptions?): UnitEntity?
	EnsureLoaded()

	local template = TemplateRegistry[unitId]
	if not template then
		warn(`[UnitsMetaData] SpawnFromId: template missing "{unitId}"`)
		return nil
	end

	local UID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.UID)
	local Owner = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Owner)
	local Ready = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Ready)
	local AttackEnabled = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.AttackEnabled)
	local Kind = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Kind)
	local Team = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Team)
	local Attacking = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Attacking)
	local BuildingTarget = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.BuildingTarget)

	local entity = World:entity()
	World:set(entity, Jecs.Name, `Unit.{unitId}.Instance`)
	World:add(entity, UnitTag)

	World:set(entity, ID, World:get(template, ID))
	World:set(entity, Level, if options and options.Level then options.Level else World:get(template, Level))
	World:set(entity, HealthBase, World:get(template, HealthBase))
	local health = if options and options.Health then options.Health else World:get(template, HealthBase)
	World:set(entity, Health, health)
	World:set(entity, BaseDamage, World:get(template, BaseDamage))
	World:set(entity, Damage, World:get(template, BaseDamage))
	World:set(entity, ModelID, World:get(template, ModelID))
	World:set(entity, Walk, World:get(template, Walk))
	World:set(entity, Class, World:get(template, Class))
	World:set(entity, Velocity, World:get(template, Velocity) or Vector3.zero)
	World:set(entity, RangeBase, World:get(template, RangeBase))
	World:set(entity, Range, World:get(template, RangeBase))
	World:set(entity, DelayAttack, World:get(template, DelayAttack))
	World:set(entity, DeployTime, World:get(template, DeployTime))
	World:set(entity, EnergyCost, World:get(template, EnergyCost))
	World:set(entity, TargetKing, World:get(template, TargetKing))
	World:set(entity, CanRetargetTroops, World:get(template, CanRetargetTroops))
	World:set(entity, Target, 0)
	World:set(entity, BuildingTarget, 0)
	World:set(entity, LastAttack, 0)
	World:set(entity, Ready, if options and options.Ready ~= nil then options.Ready else false)
	World:set(entity, AttackEnabled, false)
	World:set(entity, Attacking, false)
	World:set(entity, Kind, if options and options.Kind then options.Kind else "Unit")

	local position = if options and options.Position then options.Position else Vector3.zero
	World:set(entity, Position, position)

	if options and options.Model then
		World:set(entity, ModelComponent, options.Model)
	end
	if options and options.UID then
		World:set(entity, UID, options.UID)
	end
	if options and options.Owner then
		World:set(entity, Owner, options.Owner)
	end
	if options and options.Team then
		World:set(entity, Team, options.Team)
	end

	return entity
end

-- Compat: datas that still call .new register a template
local function new(config: UnitConfig): UnitEntity
	return registerTemplate(config)
end

return {
	new = new,
	registerTemplate = registerTemplate,
	EnsureLoaded = EnsureLoaded,
	GetCardParams = GetCardParams,
	GetTemplate = GetTemplate,
	SpawnFromId = SpawnFromId,
}
