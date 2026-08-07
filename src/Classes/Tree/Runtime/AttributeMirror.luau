--!strict
-- Behavior: mirror ECS runtime fields onto Model attributes / Humanoid (replication view)

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const AttackEnabled = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.AttackEnabled)
const Attacking = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Attacking)
const Health = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Health)
const ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
const Ready = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Ready)
const World = Mega.World

const STATE_READY_ATT_NAME = "Ready"
const STATE_ATTACK_ENABLED_ATT_NAME = "AttackEnabled"
const STATE_ATTACKING_ATT_NAME = "Attacking"

local AttributeMirror = {}

function AttributeMirror.SyncEntity(entity: any)
	local model = World:get(entity, ModelComponent)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return
	end

	local ready = World:get(entity, Ready)
	if type(ready) == "boolean" and model:GetAttribute(STATE_READY_ATT_NAME) ~= ready then
		model:SetAttribute(STATE_READY_ATT_NAME, ready)
	end

	local attackEnabled = World:get(entity, AttackEnabled)
	if type(attackEnabled) == "boolean" and model:GetAttribute(STATE_ATTACK_ENABLED_ATT_NAME) ~= attackEnabled then
		model:SetAttribute(STATE_ATTACK_ENABLED_ATT_NAME, attackEnabled)
	end

	-- Attacking: model is source of truth (cleared on track.Stopped). Don't ECS→Model here.

	local health = World:get(entity, Health)
	if type(health) == "number" then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid and math.abs(humanoid.Health - health) > 0.01 then
			humanoid.Health = math.max(0, health)
		end
	end
end

function AttributeMirror.SetReady(entity: any, ready: boolean)
	World:set(entity, Ready, ready)
	AttributeMirror.SyncEntity(entity)
end

function AttributeMirror.SetAttackEnabled(entity: any, enabled: boolean)
	World:set(entity, AttackEnabled, enabled)
	AttributeMirror.SyncEntity(entity)
end

function AttributeMirror.SetAttacking(entity: any, attacking: boolean)
	World:set(entity, Attacking, attacking)
	local model = World:get(entity, ModelComponent)
	if typeof(model) == "Instance" and model:IsA("Model") then
		if model:GetAttribute(STATE_ATTACKING_ATT_NAME) ~= attacking then
			model:SetAttribute(STATE_ATTACKING_ATT_NAME, attacking)
		end
	end
end

function AttributeMirror.SetHealth(entity: any, health: number)
	World:set(entity, Health, health)
	AttributeMirror.SyncEntity(entity)
end

return AttributeMirror
