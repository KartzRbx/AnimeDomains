--!strict

const ServerScriptService = game:GetService("ServerScriptService")

const GameplayServiceServer = require(ServerScriptService.Source.Services.GameplayService)

return function(_context, players: { Player }?): string
	local ok, message = GameplayServiceServer:EndMatchCommand(players)
	if ok then
		return message
	end
	return `Error: {message}`
end
