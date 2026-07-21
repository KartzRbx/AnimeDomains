--!strict
--[[
	InterfaceTypesSync — Studio plugin

	Sends the StarterGui tree to tools/genInterfaceTypes.js
	(http://127.0.0.1:3847/sync), which writes src/Utils/PlayerUtils/Types.luau.

	Install:
	  npm run install:interface-plugin
	  (or copy this file to %LOCALAPPDATA%\Roblox\Plugins\)

	Then: npm run dev  →  edit StarterGui  →  Types.luau regenerates automatically.
]]

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

if not RunService:IsEdit() then
	return
end

local ENDPOINT = "http://127.0.0.1:3847/sync"
local HEALTH = "http://127.0.0.1:3847/health"
local DEBOUNCE_SECONDS = 0.45

local SKIP_CLASSES = {
	LocalScript = true,
	Script = true,
	ModuleScript = true,
	PackageLink = true,
}

local toolbar = plugin:CreateToolbar("AnimeDomains")
local syncButton = toolbar:CreateButton(
	"Sync UI Types",
	"Send StarterGui → PlayerUtils/Types.luau (npm run dev)",
	"rbxasset://textures/StudioSharedUI/Refresh.png"
)
syncButton.ClickableWhenViewportHidden = true

local autoButton = toolbar:CreateButton(
	"Auto Sync UI Types",
	"Toggle automatic sync when StarterGui changes",
	"rbxasset://textures/AnimationEditor/Play.png"
)
autoButton.ClickableWhenViewportHidden = true

local autoEnabled = true
local debounceThread: thread? = nil
local lastPayload: string? = nil

local function dump(inst: Instance): { [string]: any }
	local children = {}
	local seen: { [string]: boolean } = {}

	for _, child in inst:GetChildren() do
		if SKIP_CLASSES[child.ClassName] then
			continue
		end
		if seen[child.Name] then
			continue
		end
		seen[child.Name] = true
		table.insert(children, dump(child))
	end

	table.sort(children, function(a, b)
		return a.name < b.name
	end)

	return {
		name = inst.Name,
		className = inst.ClassName,
		children = children,
	}
end

local function collectRoots(): { any }
	local roots = {}
	for _, child in StarterGui:GetChildren() do
		if child:IsA("ScreenGui") or child:IsA("Folder") or child:IsA("GuiObject") then
			table.insert(roots, dump(child))
		end
	end
	table.sort(roots, function(a, b)
		return a.name < b.name
	end)
	return roots
end

local function isServerUp(): boolean
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = HEALTH,
			Method = "GET",
		})
	end)
	return ok and response.Success == true
end

local function syncNow(force: boolean?)
	local roots = collectRoots()
	local payload = HttpService:JSONEncode({ roots = roots })
	if not force and payload == lastPayload then
		return
	end

	if not isServerUp() then
		warn("[InterfaceTypesSync] npm run watch:interfaces / npm run dev is not running (port 3847).")
		return
	end

	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = ENDPOINT,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = payload,
		})
	end)

	if not ok then
		warn("[InterfaceTypesSync] Failed to send:", response)
		return
	end

	if not response.Success then
		warn("[InterfaceTypesSync] HTTP", response.StatusCode, response.Body)
		return
	end

	lastPayload = payload
	print("[InterfaceTypesSync] Types.luau updated.")
end

local function scheduleSync()
	if not autoEnabled then
		return
	end
	if debounceThread then
		task.cancel(debounceThread)
	end
	debounceThread = task.delay(DEBOUNCE_SECONDS, function()
		debounceThread = nil
		syncNow(false)
	end)
end

syncButton.Click:Connect(function()
	syncNow(true)
end)

autoButton.Click:Connect(function()
	autoEnabled = not autoEnabled
	autoButton:SetActive(autoEnabled)
	print(`[InterfaceTypesSync] Auto sync: {autoEnabled}`)
	if autoEnabled then
		scheduleSync()
	end
end)

autoButton:SetActive(true)

StarterGui.DescendantAdded:Connect(function(desc)
	desc:GetPropertyChangedSignal("Name"):Connect(scheduleSync)
	scheduleSync()
end)

StarterGui.DescendantRemoving:Connect(scheduleSync)

for _, desc in StarterGui:GetDescendants() do
	desc:GetPropertyChangedSignal("Name"):Connect(scheduleSync)
end

print("[InterfaceTypesSync] Ready. Run npm run dev, then edit StarterGui.")
