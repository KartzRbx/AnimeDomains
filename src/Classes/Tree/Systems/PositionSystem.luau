--!strict
-- Behavior: Model HRP → Position component

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
const Position = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Position)
const TemplateTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
const Dead = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.Dead)
const World = Mega.World

local PositionSystem = {}

function PositionSystem.Update(_dt: number)
	for entity, model in World:query(ModelComponent):without(TemplateTag, Dead) do
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			continue
		end

		local hrp = model:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			World:set(entity, Position, hrp.Position)
		end
	end
end

return PositionSystem
