--!strict
-- Behavior: marks recipe entity (metadata); spawn does not carry this tag

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local TemplateTag = Mega.World:entity()
return TemplateTag
