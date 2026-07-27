--!strict
const RunService = game:GetService("RunService")
-- Typed client entry — require this from LocalScripts / client services

assert(RunService:IsClient(), 'Cannot to be required for server!')

return table.freeze({
	Game = require(script.Parent.Game.Client),
	Secondary = require(script.Parent.Secondary.Client),
	Validations = require(script.Parent.Validations.Client),
})
