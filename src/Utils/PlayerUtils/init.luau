--!strict
-- Behavior: resolves PlayerGui instances by path (e.g. "Main/Container/Gameplay")

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Types = require(script.Types)

export type Interfaces = Types.Interfaces
export type ByPath = Types.ByPath
export type InterfacePath = Types.InterfacePath
-- Generated types (Main, etc.): use Types.Main or ByPath["Main/Container/..."]

local PlayerUtils = {}

local function resolvePlayer(player: Player?): Player
	local resolved = player or Players.LocalPlayer
	assert(resolved, "[PlayerUtils] LocalPlayer unavailable")
	return resolved
end

local function splitPath(path: string): { string }
	local parts = {}
	for _, segment in string.split(path, "/") do
		if segment ~= "" then
			table.insert(parts, segment)
		end
	end
	assert(#parts > 0, "[PlayerUtils] Empty path")
	return parts
end

function PlayerUtils.getPlayerGui(player: Player?): PlayerGui
	return resolvePlayer(player):WaitForChild("PlayerGui") :: PlayerGui
end

-- Ensures StarterGui.Main is in PlayerGui (waits character when ResetOnSpawn delays clone).
function PlayerUtils.waitMain(player: Player?): ScreenGui
	local resolved = resolvePlayer(player)
	local playerGui = PlayerUtils.getPlayerGui(resolved)

	local existing = playerGui:FindFirstChild("Main")
	if existing and existing:IsA("ScreenGui") then
		return existing
	end

	if not resolved.Character then
		resolved.CharacterAdded:Wait()
	end

	existing = playerGui:FindFirstChild("Main")
	if existing and existing:IsA("ScreenGui") then
		return existing
	end

	local starterMain = StarterGui:FindFirstChild("Main")
	if starterMain and starterMain:IsA("ScreenGui") then
		local clone = starterMain:Clone()
		clone.Parent = playerGui
		return clone
	end

	return playerGui:WaitForChild("Main") :: ScreenGui
end

-- Yield until each segment exists. E.g. "Main/Container/Gameplay/CardsContainer"
function PlayerUtils.wait(path: InterfacePath, player: Player?, timeout: number?): Instance
	local parts = splitPath(path)
	local current: Instance = PlayerUtils.getPlayerGui(player)

	for index, name in parts do
		if index == 1 and name == "Main" then
			current = PlayerUtils.waitMain(player)
			continue
		end

		local child = if timeout ~= nil then current:WaitForChild(name, timeout) else current:WaitForChild(name)
		assert(child, `[PlayerUtils] Timed out at '{name}' in path: {path}`)
		current = child
	end

	return current
end

-- No yield; nil if any segment is missing
function PlayerUtils.find(path: InterfacePath, player: Player?): Instance?
	local playerGui = resolvePlayer(player):FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end

	local current: Instance = playerGui
	for _, name in splitPath(path) do
		local child = current:FindFirstChild(name)
		if not child then
			return nil
		end
		current = child
	end

	return current
end

function PlayerUtils.getInterface(path: InterfacePath, player: Player?, timeout: number?): GuiObject
	local instance = PlayerUtils.wait(path, player, timeout)
	assert(instance:IsA("GuiObject"), `[PlayerUtils] Not a GuiObject: {path} ({instance.ClassName})`)
	return instance
end

function PlayerUtils.findInterface(path: InterfacePath, player: Player?): GuiObject?
	local instance = PlayerUtils.find(path, player)
	if not instance or not instance:IsA("GuiObject") then
		return nil
	end
	return instance
end

PlayerUtils.Types = Types

return PlayerUtils
