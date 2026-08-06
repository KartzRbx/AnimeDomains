--!strict
-- Behavior: Health <= 0 → Dead tag → DespawnEntity

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const EntityRegistry = require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.EntityRegistry)
const AttributeMirror = require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.AttributeMirror)

const Health = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Health)
const ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
const UID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.UID)
const Dead = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.Dead)
const TemplateTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
const World = Mega.World

local HealthSystem = {}

function HealthSystem.Update(_dt: number)
	for entity, health, model in World:query(Health, ModelComponent):without(TemplateTag, Dead) do
		if type(health) ~= "number" or health > 0 then
			continue
		end

		World:add(entity, Dead)
		AttributeMirror.SyncEntity(entity)

		local uid = World:get(entity, UID)
		if type(uid) ~= "string" or typeof(model) ~= "Instance" or not model:IsA("Model") then
			EntityRegistry.Delete(entity)
			continue
		end

		local CardsEntityManager = require(ReplicatedStorage.Shareds.Services.CardsService.Api.CardsEntityManager)
		CardsEntityManager:DespawnEntity(uid, model)
	end
end

return HealthSystem
