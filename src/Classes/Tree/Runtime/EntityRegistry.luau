--!strict
-- Behavior: O(1) UID/Model ↔ jecs entity index (server runtime)

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
const UID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.UID)
const World = Mega.World

export type EntityId = typeof(World.entity(World))

local byUid: { [string]: EntityId } = {}
local byModel: { [Model]: EntityId } = {}

local EntityRegistry = {}

function EntityRegistry.Register(entity: EntityId, uid: string, model: Model?)
	assert(RunService:IsServer(), "[EntityRegistry] Register is server-only")

	local previous = byUid[uid]
	if previous and previous ~= entity then
		warn(`[EntityRegistry] UID remapped: {uid}`)
	end

	byUid[uid] = entity
	World:set(entity, UID, uid)

	if model then
		byModel[model] = entity
		World:set(entity, ModelComponent, model)
	end
end

function EntityRegistry.GetByUid(uid: string): EntityId?
	if type(uid) ~= "string" or uid == "" then
		return nil
	end
	return byUid[uid]
end

function EntityRegistry.GetByModel(model: Model): EntityId?
	return byModel[model]
end

function EntityRegistry.GetModel(entity: EntityId): Model?
	local model = World:get(entity, ModelComponent)
	if typeof(model) == "Instance" and model:IsA("Model") then
		return model
	end
	return nil
end

function EntityRegistry.GetUid(entity: EntityId): string?
	local uid = World:get(entity, UID)
	if type(uid) == "string" then
		return uid
	end
	return nil
end

function EntityRegistry.Unregister(entity: EntityId)
	local uid = World:get(entity, UID)
	if type(uid) == "string" then
		if byUid[uid] == entity then
			byUid[uid] = nil
		end
	end

	local model = World:get(entity, ModelComponent)
	if typeof(model) == "Instance" and model:IsA("Model") then
		if byModel[model] == entity then
			byModel[model] = nil
		end
	end
end

function EntityRegistry.Delete(entity: EntityId)
	assert(RunService:IsServer(), "[EntityRegistry] Delete is server-only")
	EntityRegistry.Unregister(entity)
	World:delete(entity)
end

return EntityRegistry
