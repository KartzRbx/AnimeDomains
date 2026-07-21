--!strict

const ServerScriptService = game:GetService("ServerScriptService")

const GameplayServiceServer = require(ServerScriptService.Source.Services.GameplayService)

return function(_context, mapName: string, gamemode: string, players: { Player }): string
	local ok, message = GameplayServiceServer:StartMatchCommand(mapName, gamemode, players)
	if ok then
		return message
	end
	return `Error: {message}`
end
