--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const EntityActionManager = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.AttacksData.EntityActionManager)

const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)

-- Behavior: Sabre unit attack handler factory



type ActionTime = EntityActionManager.MetaTable & {
	UID: string,
	TargetUID: string,
}



return function()
	return function(_action: EntityActionManager.MetaTable)
		local entityModel = EntityHelper.GetEntityCharacterForUID(_action.UID)
		local target = EntityHelper.GetEntityCharacterForUID(_action.TargetUID)

		if not entityModel or not target then
			return false, "Entity or target not found"
		end



		return true, ""
	end
end

