--!strict
const RunService = game:GetService("RunService")
-- Typed server entry — require this from ServerScripts / server services

assert(RunService:IsServer(), 'Cannot to be required for client!')

return table.freeze({
	Game = require(script.Parent.Game.Server),
	Secondary = require(script.Parent.Secondary.Server),
	Validations = require(script.Parent.Validations.Server),
})
