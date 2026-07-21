--!strict
-- Behavior: jecs factory — creates Tower entity with base + current stats + tag

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const BaseDamage = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.BaseDamage)
const Health = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Health)
const HealthBase = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.HealthBase)
const ID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.ID)
const LastAttack = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.LastAttack)
const Level = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Level)
const Position = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Position)
const RangeBase = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.RangeBase)
const Target = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Target)
const TargetKing = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.TargetKing)
const Walk = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Walk)
const TowerTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TowerTag)
const World = Mega.World
const Jecs = Mega.Jecs

export type TowerId = string
export type TowerLevel = number
export type TowerRange = number
export type TowerHealth = number
export type TowerDamage = number
export type TowerEnergyCost = number
export type TowerTargetKind = TargetKing.TargetKindValue

export type TowerConfig = {
	Id: TowerId,
	Level: TowerLevel,
	BaseHealth: TowerHealth,
	BaseDamage: TowerDamage,
	BaseRange: TowerRange,
	EnergyCost: TowerEnergyCost,
	Position: Vector3,
	Walk: number,
	TargetKind: TowerTargetKind?,
}

export type TowerEntity = typeof(World.entity(World))

const function new(config: TowerConfig): TowerEntity
	local entity = World:entity()
	World:set(entity, Jecs.Name, `Tower.{config.Id}`)
	World:add(entity, TowerTag)
	World:set(entity, ID, config.Id)
	World:set(entity, Level, config.Level)
	World:set(entity, HealthBase, config.BaseHealth)
	World:set(entity, Health, config.BaseHealth)
	World:set(entity, BaseDamage, config.BaseDamage)
	World:set(entity, Position, config.Position)
	World:set(entity, Walk, config.Walk)
	World:set(entity, RangeBase, config.BaseRange)
	World:set(entity, TargetKing, config.TargetKind or "All")
	World:set(entity, Target, 0)
	World:set(entity, LastAttack, 0)
	return entity
end

local Tower = {
	new = new,
}


export type Tower = typeof(Tower)

return Tower :: Tower
