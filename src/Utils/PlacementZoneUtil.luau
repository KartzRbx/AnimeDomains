--!strict
-- Behavior: drop on own Main; blocks EntityLimitations + tower clearance.
-- Unlocked enemy Left/Right are placeable after that tower falls.
-- Overlay highlight (Main→Left/Right→Base) is visual only — not a place block.

--[[
	Teams.<One|Two>.Interactions.EntitySpawnZone
	  Main / Left / Right / Base  (Highlight stays enabled; only Transparency changes)
]]

const Workspace = game:GetService("Workspace")

-- Literals: TeamName "One"|"Two"; LaneName "Left"|"Right"; ZoneId/OverlayId "Main"|"Left"|"Right"|"Base"
export type TeamName = string
export type LaneName = string
export type PlaceKind = string
export type ZoneId = string
export type OverlayId = string

export type TeamUnlocks = {
	Left: boolean,
	Right: boolean,
}

export type ZonePart = {
	Id: ZoneId,
	Part: BasePart,
	Unlocked: boolean,
}

const SURFACE_XZ_TOLERANCE = 2.5
const TOWER_CLEARANCE = 5
const ZONE_FOLDER_NAME = "EntitySpawnZone"
const TEAM_NAMES = { "One", "Two" }
const LANE_NAMES = { "Left", "Right" }
const OVERLAY_IDS = { "Main", "Left", "Right", "Base" }

local unlocks: { [string]: TeamUnlocks } = {
	One = { Left = false, Right = false },
	Two = { Left = false, Right = false },
}

local PlacementZoneUtils = {}

function PlacementZoneUtils.RequiresEntitySpawnZone(kind: PlaceKind): boolean
	return kind == "Unit" or kind == "Structure"
end

function PlacementZoneUtils.GetEnemyTeam(teamName: TeamName): TeamName
	if teamName == "One" then
		return "Two"
	end
	return "One"
end

const function getTeamsRoot(): Folder?
	local gameFolder = Workspace:FindFirstChild("Game")
	local gameplay = gameFolder and gameFolder:FindFirstChild("Gameplay")
	local teams = gameplay and gameplay:FindFirstChild("Teams")
	if teams and teams:IsA("Folder") then
		return teams
	end
	return nil
end

const function getSpawnZoneModel(teamName: TeamName): Model?
	local teamsRoot = getTeamsRoot()
	local teamFolder = teamsRoot and teamsRoot:FindFirstChild(teamName)
	local interactions = teamFolder and teamFolder:FindFirstChild("Interactions")
	local zoneModel = interactions and interactions:FindFirstChild(ZONE_FOLDER_NAME)
	if zoneModel and zoneModel:IsA("Model") then
		return zoneModel
	end
	return nil
end

function PlacementZoneUtils.GetZonePart(teamName: TeamName, zoneId: ZoneId): BasePart?
	local zoneModel = getSpawnZoneModel(teamName)
	if not zoneModel then
		return nil
	end

	local child = zoneModel:FindFirstChild(zoneId)
	if child and child:IsA("BasePart") then
		return child
	end
	return nil
end

function PlacementZoneUtils.IsLaneUnlocked(attackerTeam: TeamName, lane: LaneName): boolean
	local enemy = PlacementZoneUtils.GetEnemyTeam(attackerTeam)
	local part = PlacementZoneUtils.GetZonePart(enemy, lane)
	if part then
		local attr = part:GetAttribute("Unlocked")
		if typeof(attr) == "boolean" then
			return attr
		end
	end
	return unlocks[attackerTeam][lane]
end

function PlacementZoneUtils.GetUnlocks(attackerTeam: TeamName): TeamUnlocks
	return {
		Left = PlacementZoneUtils.IsLaneUnlocked(attackerTeam, "Left"),
		Right = PlacementZoneUtils.IsLaneUnlocked(attackerTeam, "Right"),
	}
end

function PlacementZoneUtils.GetEnemyBlockOverlayId(attackerTeam: TeamName): OverlayId
	local leftDown = PlacementZoneUtils.IsLaneUnlocked(attackerTeam, "Left")
	local rightDown = PlacementZoneUtils.IsLaneUnlocked(attackerTeam, "Right")

	if leftDown and rightDown then
		return "Base"
	elseif leftDown then
		return "Left"
	elseif rightDown then
		return "Right"
	end

	return "Main"
end

function PlacementZoneUtils.GetEnemySpawnZoneParts(enemyTeam: TeamName): { BasePart }
	local list: { BasePart } = {}
	for _, id in OVERLAY_IDS do
		local part = PlacementZoneUtils.GetZonePart(enemyTeam, id)
		if part then
			table.insert(list, part)
		end
	end
	return list
end

function PlacementZoneUtils.UnlockEnemyLane(attackerTeam: TeamName, lane: LaneName)
	unlocks[attackerTeam][lane] = true

	local enemy = PlacementZoneUtils.GetEnemyTeam(attackerTeam)
	local part = PlacementZoneUtils.GetZonePart(enemy, lane)
	if part then
		part:SetAttribute("Unlocked", true)
	end
end

function PlacementZoneUtils.ResetUnlocks()
	unlocks.One.Left = false
	unlocks.One.Right = false
	unlocks.Two.Left = false
	unlocks.Two.Right = false

	for _, teamName in TEAM_NAMES do
		for _, lane in LANE_NAMES do
			local part = PlacementZoneUtils.GetZonePart(teamName, lane)
			if part then
				part:SetAttribute("Unlocked", false)
			end
		end

		local teamsRoot = getTeamsRoot()
		local teamFolder = teamsRoot and teamsRoot:FindFirstChild(teamName)
		local towers = teamFolder and teamFolder:FindFirstChild("Towers")
		if towers then
			for _, tower in towers:GetChildren() do
				if tower:IsA("Model") then
					tower:SetAttribute("Destroyed", nil)
				end
			end
		end
	end
end

function PlacementZoneUtils.GetEntitySpawn(teamName: TeamName): BasePart?
	return PlacementZoneUtils.GetZonePart(teamName, "Main")
end

const function getEntityLimitations(): Instance?
	local gameFolder = Workspace:FindFirstChild("Game")
	local builds = gameFolder and gameFolder:FindFirstChild("Builds")
	if not builds then
		return nil
	end

	for _, child in builds:GetChildren() do
		local limitations = child:FindFirstChild("EntityLimitations")
		if limitations then
			return limitations
		end
	end

	return nil
end

function PlacementZoneUtils.GetEntityLimitations(): Instance?
	return getEntityLimitations()
end

function PlacementZoneUtils.IsOnBlockedEnemyFloor(attackerTeam: TeamName, worldPos: Vector3): boolean
	local enemy = PlacementZoneUtils.GetEnemyTeam(attackerTeam)
	local overlayId = PlacementZoneUtils.GetEnemyBlockOverlayId(attackerTeam)
	local part = PlacementZoneUtils.GetZonePart(enemy, overlayId)
	if not part then
		return false
	end
	return PlacementZoneUtils.IsPointInZone(worldPos, part)
end

function PlacementZoneUtils.IsInsideEntityBarrier(worldPos: Vector3): boolean
	local limitations = getEntityLimitations()
	if not limitations then
		return false
	end

	for _, descendant in limitations:GetDescendants() do
		if descendant:IsA("BasePart") and PlacementZoneUtils.IsPointInPart(worldPos, descendant) then
			return true
		end
	end

	if limitations:IsA("BasePart") and PlacementZoneUtils.IsPointInPart(worldPos, limitations) then
		return true
	end

	return false
end

const function getTowerAnchor(tower: Instance): Vector3?
	local grip = tower:FindFirstChild("GripEntity", true)
	if grip and grip:IsA("Attachment") then
		return grip.WorldPosition
	end
	if tower:IsA("Model") then
		return tower:GetPivot().Position
	end
	if tower:IsA("BasePart") then
		return tower.Position
	end
	return nil
end

const function getTowerClearRadius(tower: Instance): number
	if tower:IsA("Model") then
		local _cf, size = tower:GetBoundingBox()
		return math.max(size.X, size.Z) * 0.5 + TOWER_CLEARANCE
	end
	if tower:IsA("BasePart") then
		return math.max(tower.Size.X, tower.Size.Z) * 0.5 + TOWER_CLEARANCE
	end
	return TOWER_CLEARANCE + 4
end

function PlacementZoneUtils.IsTooCloseToTower(worldPos: Vector3): boolean
	local teamsRoot = getTeamsRoot()
	if not teamsRoot then
		return false
	end

	for _, teamName in TEAM_NAMES do
		local teamFolder = teamsRoot:FindFirstChild(teamName)
		local towers = teamFolder and teamFolder:FindFirstChild("Towers")
		if not towers then
			continue
		end

		for _, tower in towers:GetChildren() do
			if tower:GetAttribute("Destroyed") == true then
				continue
			end

			local grip = tower:FindFirstChild("GripEntity", true)
			if grip and grip:GetAttribute("Destroyed") == true then
				continue
			end

			local anchor = getTowerAnchor(tower)
			if not anchor then
				continue
			end

			local dx = worldPos.X - anchor.X
			local dz = worldPos.Z - anchor.Z
			local radius = getTowerClearRadius(tower)
			if (dx * dx + dz * dz) <= (radius * radius) then
				return true
			end
		end
	end

	return false
end

function PlacementZoneUtils.GetZonesForTeam(teamName: TeamName): { ZonePart }
	local list: { ZonePart } = {}

	local part = PlacementZoneUtils.GetZonePart(teamName, "Main")
	if part then
		table.insert(list, {
			Id = "Main",
			Part = part,
			Unlocked = true,
		})
	end

	return list
end

function PlacementZoneUtils.IsPointInPart(worldPos: Vector3, part: BasePart): boolean
	local localPoint = part.CFrame:PointToObjectSpace(worldPos)
	local half = part.Size * 0.5
	local yPad = math.max(half.Y, 8)
	return math.abs(localPoint.X) <= half.X + 0.05
		and math.abs(localPoint.Z) <= half.Z + 0.05
		and math.abs(localPoint.Y) <= yPad
end

function PlacementZoneUtils.IsPointInZone(worldPos: Vector3, part: BasePart): boolean
	if not PlacementZoneUtils.IsPointInPart(worldPos, part) then
		return false
	end

	if part:IsA("UnionOperation") or part:IsA("MeshPart") then
		local closest = part:GetClosestPointOnSurface(worldPos)
		local dx = worldPos.X - closest.X
		local dz = worldPos.Z - closest.Z
		return (dx * dx + dz * dz) <= (SURFACE_XZ_TOLERANCE * SURFACE_XZ_TOLERANCE)
	end

	return true
end

function PlacementZoneUtils.CanPlace(
	teamName: TeamName,
	worldPos: Vector3,
	kind: PlaceKind
): boolean
	if not PlacementZoneUtils.RequiresEntitySpawnZone(kind) then
		return true
	end

	if PlacementZoneUtils.IsInsideEntityBarrier(worldPos) then
		return false
	end
	if PlacementZoneUtils.IsTooCloseToTower(worldPos) then
		return false
	end

	-- Own Main is always placeable.
	for _, zone in PlacementZoneUtils.GetZonesForTeam(teamName) do
		if PlacementZoneUtils.IsPointInZone(worldPos, zone.Part) then
			return true
		end
	end

	-- Unlocked enemy lanes (LeftTower/RightTower down). Overlay highlight ≠ block.
	local enemy = PlacementZoneUtils.GetEnemyTeam(teamName)

	if PlacementZoneUtils.IsLaneUnlocked(teamName, "Left") then
		local left = PlacementZoneUtils.GetZonePart(enemy, "Left")
		if left and PlacementZoneUtils.IsPointInZone(worldPos, left) then
			return true
		end
	end

	if PlacementZoneUtils.IsLaneUnlocked(teamName, "Right") then
		local right = PlacementZoneUtils.GetZonePart(enemy, "Right")
		if right and PlacementZoneUtils.IsPointInZone(worldPos, right) then
			return true
		end
	end

	return false
end

return PlacementZoneUtils
