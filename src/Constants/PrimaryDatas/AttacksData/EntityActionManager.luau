--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)

const EntityActionManager = {}

export type UnitAttackHandler = (action: MetaTable) -> (boolean, string)
export type UnitAttackFactory = () -> UnitAttackHandler

const function Get_Entity_Unit_AttackModule(uid: string): ModuleScript?
	local entityModel = EntityHelper.GetEntityCharacterForUID(uid)
	if not entityModel then
		return nil
	end

	local cardId = entityModel:GetAttribute("CardId")
	if type(cardId) ~= "string" or cardId == "" then
		return nil
	end

	const Units: Folder = script.Parent.Units

	const function findAttackInFolder(folderName: string): ModuleScript?
		local storageFolder = Units:FindFirstChild(folderName)
		if not storageFolder or not storageFolder:IsA("Folder") then
			return nil
		end

		local attackModule = storageFolder:FindFirstChild("Attack")
		if attackModule and attackModule:IsA("ModuleScript") then
			return attackModule
		end

		return nil
	end

	local byCardId = findAttackInFolder(cardId)
	if byCardId then
		return byCardId
	end

	local entityData = EntityHelper.GetEntityDataByCardId(cardId)
	if entityData then
		return findAttackInFolder(entityData.ModelID)
	end

	return nil
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

local function Attack(action: MetaTable): (boolean, string)
	if not action.CanAttack then
		return false, "Cannot attack"
	end

	if action.UID == "" then
		return false, "Missing entity UID"
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

	return handler(action)
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
