--!strict
-- Behavior: jecs factory — tower templates + runtime SpawnFromId

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const BaseDamage = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.BaseDamage)
const Damage = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Damage)
const DelayAttack = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.DelayAttack)
const EnergyCost = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.EnergyCost)
const Health = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Health)
const HealthBase = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.HealthBase)
const ID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.ID)
const LastAttack = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.LastAttack)
const Level = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Level)
const ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
const Position = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Position)
const Range = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Range)
const RangeBase = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.RangeBase)
const Target = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Target)
const TargetKing = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.TargetKing)
const Walk = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Walk)
const TowerTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TowerTag)
const TemplateTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
const TowerCardRegistry = require(script.Parent.TowerCardRegistry)
const World = Mega.World
const Jecs = Mega.Jecs

export type TowerId = string
export type TowerTargetKind = TargetKing.TargetKindValue

export type TowerUpgradeData = {
	DamagePerLevel: number,
	HealthPerLevel: number,
	RangePerLevel: number,
}

export type TowerConfig = {
	Id: TowerId,
	Name: string?,
	Level: number,
	BaseHealth: number,
	BaseDamage: number,
	BaseRange: number,
	DelayAttack: number?,
	EnergyCost: number,
	Position: Vector3,
	Walk: number,
	TargetKind: TowerTargetKind?,
	Upgrade: TowerUpgradeData?,
}

export type TowerEntity = typeof(World.entity(World))

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
	TowerSlot: string?,
	Anchor: Model?,
}

local TowersFolder = ReplicatedStorage.Shareds.Classes.Tree.Datas.Towers
local datasLoaded = false
local TemplateRegistry: { [string]: TowerEntity } = {}

const function toCardParams(config: TowerConfig): TowerCardRegistry.TowerCardParams
	local upgrade = config.Upgrade
	return {
		Id = config.Id,
		Name = config.Name or config.Id,
		Level = config.Level,
		BaseHealth = config.BaseHealth,
		BaseDamage = config.BaseDamage,
		BaseRange = config.BaseRange,
		DelayAttack = config.DelayAttack or 1,
		EnergyCost = config.EnergyCost,
		Walk = config.Walk,
		TargetKind = config.TargetKind or "All",
		HealthPerLevel = if upgrade then upgrade.HealthPerLevel else config.BaseHealth * 0.10,
		DamagePerLevel = if upgrade then upgrade.DamagePerLevel else config.BaseDamage * 0.10,
	}
end

const function registerTemplate(config: TowerConfig): TowerEntity
	local existing = TemplateRegistry[config.Id]
	if existing then
		return existing
	end

	local entity = World:entity()
	World:set(entity, Jecs.Name, `Tower.{config.Id}`)
	World:add(entity, TowerTag)
	World:add(entity, TemplateTag)
	World:set(entity, ID, config.Id)
	World:set(entity, Level, config.Level)
	World:set(entity, HealthBase, config.BaseHealth)
	World:set(entity, Health, config.BaseHealth)
	World:set(entity, BaseDamage, config.BaseDamage)
	World:set(entity, Damage, config.BaseDamage)
	World:set(entity, Position, config.Position)
	World:set(entity, Walk, config.Walk)
	World:set(entity, RangeBase, config.BaseRange)
	World:set(entity, Range, config.BaseRange)
	World:set(entity, DelayAttack, config.DelayAttack or 1)
	World:set(entity, EnergyCost, config.EnergyCost)
	World:set(entity, TargetKing, config.TargetKind or "All")
	World:set(entity, Target, 0)
	World:set(entity, LastAttack, 0)

	local cardParams = toCardParams(config)
	TowerCardRegistry.Set(config.Id, cardParams)
	TemplateRegistry[config.Id] = entity
	return entity
end

const function EnsureLoaded()
	if datasLoaded then
		return
	end
	datasLoaded = true
	TowerCardRegistry.MarkLoaded()

	for _, child in TowersFolder:GetChildren() do
		if not child:IsA("ModuleScript") then
			continue
		end

		local mod = (require :: any)(child)
		if type(mod) ~= "table" then
			continue
		end

		if type(mod.Id) == "string" then
			registerTemplate(mod :: TowerConfig)
		else
			for _, cfg in mod do
				if type(cfg) == "table" and type(cfg.Id) == "string" then
					registerTemplate(cfg :: TowerConfig)
				end
			end
		end
	end
end

const function GetCardParams(towerId: string): TowerCardRegistry.TowerCardParams?
	EnsureLoaded()
	return TowerCardRegistry.Get(towerId)
end

const function GetTemplate(towerId: string): TowerEntity?
	EnsureLoaded()
	return TemplateRegistry[towerId]
end

const function SpawnFromId(towerId: string, options: SpawnFromIdOptions?): TowerEntity?
	EnsureLoaded()

	local template = TemplateRegistry[towerId]
	if not template then
		warn(`[TowerMetaData] SpawnFromId: template missing "{towerId}"`)
		return nil
	end

	local UID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.UID)
	local Owner = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Owner)
	local Ready = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Ready)
	local AttackEnabled = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.AttackEnabled)
	local Kind = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Kind)
	local Team = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Team)
	local TowerSlot = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.TowerSlot)
	local Anchor = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Anchor)
	local Attacking = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Attacking)

	local entity = World:entity()
	World:set(entity, Jecs.Name, `Tower.{towerId}.Instance`)
	World:add(entity, TowerTag)

	World:set(entity, ID, World:get(template, ID))
	World:set(entity, Level, if options and options.Level then options.Level else World:get(template, Level))
	World:set(entity, HealthBase, World:get(template, HealthBase))
	local health = if options and options.Health then options.Health else World:get(template, HealthBase)
	World:set(entity, Health, health)
	World:set(entity, BaseDamage, World:get(template, BaseDamage))
	World:set(entity, Damage, World:get(template, BaseDamage))
	World:set(entity, Walk, World:get(template, Walk))
	World:set(entity, RangeBase, World:get(template, RangeBase))
	World:set(entity, Range, World:get(template, RangeBase))
	World:set(entity, DelayAttack, World:get(template, DelayAttack) or 1)
	World:set(entity, EnergyCost, World:get(template, EnergyCost) or 0)
	World:set(entity, TargetKing, World:get(template, TargetKing) or "All")
	World:set(entity, Target, 0)
	World:set(entity, LastAttack, 0)
	World:set(entity, Ready, if options and options.Ready ~= nil then options.Ready else true)
	World:set(entity, AttackEnabled, false)
	World:set(entity, Attacking, false)
	World:set(entity, Kind, if options and options.Kind then options.Kind else "Tower")

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
	if options and options.TowerSlot then
		World:set(entity, TowerSlot, options.TowerSlot)
	end
	if options and options.Anchor then
		World:set(entity, Anchor, options.Anchor)
	end

	return entity
end

-- Compat: datas that still call .new register a template
const function new(config: TowerConfig): TowerEntity
	return registerTemplate(config)
end

local Tower = {
	new = new,
	registerTemplate = registerTemplate,
	EnsureLoaded = EnsureLoaded,
	GetCardParams = GetCardParams,
	GetTemplate = GetTemplate,
	SpawnFromId = SpawnFromId,
}

export type Tower = typeof(Tower)
return Tower :: Tower
