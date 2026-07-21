--!strict
-- Behavior: facade — EntityHelp + World + jecs in a single require
-- Note: do NOT require primitives here (ID etc.) — avoids Mega ↔ ID cycle

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.jecs)

local EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
local World = jecs.World.new(true)

local Utils = {
	GetUnitMetadataWithID = function(UnitID: string)
		const ID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.ID)
		const TemplateTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
		for entity, id in World:query(ID):with(TemplateTag) do
			if id == UnitID then
				return entity
			end
		end
		return nil
	end,
}

return {
	Entitys = EntityHelper,
	World = World,
	Jecs = jecs,
	Utils = Utils,
}
