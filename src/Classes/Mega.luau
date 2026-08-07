--!strict
-- Behavior: facade — World + jecs (EntityHelper fica em Workers, sem ciclo)

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const jecs = require(ReplicatedStorage.Packages.jecs)

const World = jecs.World.new(true)

const Utils = {
	GetUnitMetadataWithID = function(UnitID: string)
		const ID = (require :: any)(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.ID)
		const TemplateTag = (require :: any)(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
		for entity, id in World:query(ID):with(TemplateTag) do
			if id == UnitID then
				return entity
			end
		end
		return nil
	end,
}


return table.freeze({
	World = World,
	Jecs = jecs,
	Utils = Utils,
})

