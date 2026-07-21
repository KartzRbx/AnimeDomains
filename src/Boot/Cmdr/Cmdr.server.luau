--!strict
-- Behavior: boots Cmdr on the server and registers commands under Handlers/Cmdr

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")
const RunService = game:GetService("RunService")

const Cmdr = require(ReplicatedStorage.Packages.cmdr)

Cmdr:RegisterDefaultCommands()

const commandsFolder = ServerScriptService.Source.Handlers:FindFirstChild("Cmdr")
if commandsFolder then
	local commands = commandsFolder:FindFirstChild("Commands")
	if commands then
		Cmdr:RegisterCommandsIn(commands)
	end
end

-- Studio / dev: unlock all groups
Cmdr.Registry:RegisterHook("BeforeRun", function(_context)
	if RunService:IsStudio() then
		return nil
	end
	return nil
end)
