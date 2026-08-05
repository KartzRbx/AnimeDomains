--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const Players = game:GetService("Players")
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const CombateStateHandler = require(ReplicatedStorage.Shareds.Workers.CombateStateHandler)


const EntityActionManager = {}

export type UnitAttackHandler = (action: MetaTable) -> (boolean, string)
export type UnitAttackFactory = () -> UnitAttackHandler

export type AttackClientPayload = {
	Attacker: Model,
	Target: Model,
	UID: string,
	TargetUID: string,
}

export type UnitAttackClientHandler = (payload: AttackClientPayload) -> ()
export type UnitAttackClientFactory = () -> UnitAttackClientHandler

export type UnitAttackSessionConfig = {
	HitTimes: { number },
	HitWindow: number,
	HitDamageScale: number,
}


const function findAttackFolder(folderName: string): Folder?
	const Units: Folder = script.Parent.Units
	local storageFolder = Units:FindFirstChild(folderName)
	if not storageFolder or not storageFolder:IsA("Folder") then
		return nil
	end

	local attackFolder = storageFolder:FindFirstChild("Attack") or storageFolder:FindFirstChild("ATTACK")
	if attackFolder and attackFolder:IsA("Folder") then
		return attackFolder
	end

	return nil
end

const function Get_Entity_Unit_AttackModule(uid: string): ModuleScript?
	local entityModel = EntityHelper.GetEntityCharacterForUID(uid)
	if not entityModel then
		return nil
	end

	local cardId = entityModel:GetAttribute("CardId")
	if type(cardId) ~= "string" or cardId == "" then
		return nil
	end

	local attackFolder = findAttackFolder(cardId)
	if attackFolder then
		local serverModule = attackFolder:FindFirstChild("Server")
		if serverModule and serverModule:IsA("ModuleScript") then
			return serverModule
		end
	end

	local entityData = EntityHelper.GetEntityDataByCardId(cardId)
	if entityData then
		attackFolder = findAttackFolder(entityData.ModelID)
		if attackFolder then
			local serverModule = attackFolder:FindFirstChild("Server")
			if serverModule and serverModule:IsA("ModuleScript") then
				return serverModule
			end
		end
	end

	return nil
end

const function Get_Entity_Unit_AttackClientModule(uid: string): ModuleScript?
	local entityModel = EntityHelper.GetEntityCharacterForUID(uid)
	if not entityModel then
		return nil
	end

	local cardId = entityModel:GetAttribute("CardId")
	if type(cardId) ~= "string" or cardId == "" then
		return nil
	end

	local attackFolder = findAttackFolder(cardId)
	if attackFolder then
		local clientModule = attackFolder:FindFirstChild("Client")
		if clientModule and clientModule:IsA("ModuleScript") then
			return clientModule
		end
	end

	local entityData = EntityHelper.GetEntityDataByCardId(cardId)
	if entityData then
		attackFolder = findAttackFolder(entityData.ModelID)
		if attackFolder then
			local clientModule = attackFolder:FindFirstChild("Client")
			if clientModule and clientModule:IsA("ModuleScript") then
				return clientModule
			end
		end
	end

	return nil
end

function EntityActionManager.RunUnitAttackClient(_self: EntityActionManager, payload: AttackClientPayload): boolean
	if RunService:IsServer() then
		return false
	end

	local clientModule = Get_Entity_Unit_AttackClientModule(payload.UID)
	if not clientModule then
		return false
	end

	local factory = require(clientModule) :: UnitAttackClientFactory
	if type(factory) ~= "function" then
		warn(`Attack client module must return a factory: {payload.UID}`)
		return false
	end

	local handler = factory()
	if type(handler) ~= "function" then
		warn(`Attack client factory must return a handler: {payload.UID}`)
		return false
	end

	handler(payload)
	return true
end

export type MetaTable = {
	AttackName: string,
	UID: string,
	TargetUID: string,
	CanAttack: boolean,
	Changed: RBXScriptSignal,
	Attack: (self: MetaTable) -> (boolean, string),
	Destroy: (self: MetaTable) -> (),
}

local function cleanupAction(action: MetaTable)
	action.CanAttack = false
	action.AttackName = ""
	action.UID = ""
	action.TargetUID = ""

	local rawData = (action :: any)._rawData
	if rawData and rawData._changedEvent then
		rawData._changedEvent:Destroy()
	end
	setmetatable(action :: any, nil)
end

const STATE_ATTACKING_ATT_NAME = "Attacking"

const function replicateAttack(action: MetaTable)
	if not RunService:IsServer() then
		return
	end

	local entityModel = EntityHelper.GetEntityCharacterForUID(action.UID)
	if entityModel then
		entityModel:SetAttribute(STATE_ATTACKING_ATT_NAME, true)
	end

	local Debi = require(ReplicatedStorage.Shareds.Networker.NetServer).Secondary
	Debi.BindAttack_Replica.FireAll({
		UID = action.UID,
		TargetUID = action.TargetUID,
	})
end

local function Attack(action: MetaTable): (boolean, string)
	if not action.CanAttack then
		return false, "Cannot attack"
	end

	if action.UID == "" then
		return false, "Missing entity UID"
	end

	local entityModel = EntityHelper.GetEntityCharacterForUID(action.UID)
	if entityModel then
		local ownerName = entityModel:GetAttribute("Owner")
		local cardId = entityModel:GetAttribute("CardId")
		if type(ownerName) == "string" and type(cardId) == "string" then
			local ownerPlayer = Players:FindFirstChild(ownerName)
			if ownerPlayer and ownerPlayer:IsA("Player") then
				local validation = CombateStateHandler:PlayerCanEmitAttackForCardID(ownerPlayer, action.UID, cardId)
				if not validation.CanAttack then
					return false, validation.Reason ~= "" and validation.Reason or "Cannot attack"
				end
			end
		end
	end

	local entityAttackModule = Get_Entity_Unit_AttackModule(action.UID)
	if not entityAttackModule then
		warn(`Attack module not found for UID: {action.UID}`)
		return false, "Attack module missing"
	end

	local factory = require(entityAttackModule) :: UnitAttackFactory
	if type(factory) ~= "function" then
		warn(`Attack module must return a factory: {action.UID}`)
		return false, "Invalid attack module"
	end

	local handler = factory()
	if type(handler) ~= "function" then
		warn(`Attack factory must return a handler: {action.UID}`)
		return false, "Invalid attack handler"
	end

	local ok, err = handler(action)
	if ok then
		replicateAttack(action)
	end

	return ok, err
end

function EntityActionManager.GetUnitAttack(self: EntityActionManager, UID: string): MetaTable
	local rawData = {
		AttackName = "Attack",
		CanAttack = false,
		UID = UID,
		TargetUID = "",
		_changedEvent = Instance.new("BindableEvent"),
	}

	local proxy = {}

	local ActionMeta = {
		__index = function(_, key): any
			if key == "Changed" then
				return rawData._changedEvent.Event
			elseif key == "Attack" then
				local attackMethod: (MetaTable) -> (boolean, string) = function(_self: MetaTable): (boolean, string)
					return Attack(proxy :: any)
				end
				return attackMethod
			elseif key == "Destroy" then
				local destroyMethod: (MetaTable) -> () = function(_self: MetaTable)
					cleanupAction(proxy :: any)
				end
				return destroyMethod
			elseif key == "_rawData" then
				return rawData
			end
			return rawData[key]
		end,

		__newindex = function(_, key, newValue)
			local oldValue = rawData[key]

			if oldValue ~= newValue then
				rawData[key] = newValue
				rawData._changedEvent:Fire(key, newValue, oldValue)
			end
		end,
	}

	setmetatable(proxy, ActionMeta)

	return (proxy :: any) :: MetaTable
end

export type EntityActionManager = typeof(EntityActionManager)
return EntityActionManager
