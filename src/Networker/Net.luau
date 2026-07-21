--!strict
-- Boots Game / Secondary / Validations (Client or Server based on context)

const RunService = game:GetService("RunService")

const networker = script.Parent :: Folder
const sideName = if RunService:IsServer() then "Server" else "Client"

const function load(channel: string): any
	const folder = networker:WaitForChild(channel) :: Folder
	const mod = folder:WaitForChild(sideName)
	assert(mod:IsA("ModuleScript"), `[Net] invalid {channel}.{sideName}`)
	return require(mod)
end

return table.freeze({
	Game = load("Game"),
	Secondary = load("Secondary"),
	Validations = load("Validations"),
})
