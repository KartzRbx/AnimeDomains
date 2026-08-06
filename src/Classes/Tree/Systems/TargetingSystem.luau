--!strict
-- Behavior: pick combat Target + BuildingTarget for units/towers

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const AttributeMirror = require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.AttributeMirror)
const EntityRegistry = require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.EntityRegistry)

const Anchor = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Anchor)
const BuildingTarget = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.BuildingTarget)
const CanRetargetTroops = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.CanRetargetTroops)
const Health = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Health)
const Kind = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Kind)
const ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
const Position = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Position)
const Range = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Range)
const Ready = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Ready)
const Target = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Target)
const TargetKing = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.TargetKing)
const Team = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Team)
const Dead = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.Dead)
const TemplateTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
const TowerTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TowerTag)
const UnitTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.UnitTag)
const World = Mega.World

const TROOP_AGGRO_LEAVE_MULTIPLIER = 1.25

type TargetKind = "Buildings" | "Ground" | "Air" | "All"

local TargetingSystem = {}

const function getDistanceSq(a: Vector3, b: Vector3): number
	local d = a - b
	return d.X * d.X + d.Y * d.Y + d.Z * d.Z
end

const function matchesTargetKind(kind: TargetKind, enemyKind: string): boolean
	if kind == "All" then
		return true
	end
	if kind == "Buildings" then
		return enemyKind == "Tower"
	end
	if kind == "Ground" or kind == "Air" then
		return enemyKind ~= "Tower"
	end
	return true
end

const function isAliveEntity(entity: any): boolean
	if not World:contains(entity) or World:has(entity, Dead) then
		return false
	end
	local health = World:get(entity, Health)
	return type(health) == "number" and health > 0
end

const function enemyTeamOf(team: string): string
	return if team == "One" then "Two" else "One"
end

const function findClosestEnemyTroop(origin: Vector3, myTeam: string, targetKind: TargetKind, range: number): any?
	local best = nil
	local bestDistSq = range * range

	for entity, pos, team, kind in World:query(Position, Team, Kind):with(UnitTag):without(TemplateTag, Dead) do
		if team == myTeam or not isAliveEntity(entity) then
			continue
		end
		if type(kind) ~= "string" or not matchesTargetKind(targetKind, kind) then
			continue
		end

		local distSq = getDistanceSq(origin, pos)
		if distSq <= bestDistSq then
			best = entity
			bestDistSq = distSq
		end
	end

	return best
end

const function resolveBuildingEntity(anchor: Model): any?
	local spawned = EntityHelper.GetSpawnedTowerForAnchor(anchor)
	if not spawned then
		return nil
	end
	return EntityRegistry.GetByModel(spawned)
end

const function setTarget(entity: any, targetEntity: any?)
	if targetEntity then
		World:set(entity, Target, targetEntity)
	else
		World:set(entity, Target, 0)
	end
end

const function getTowerAnchorPos(towerEntity: any): (Model?, Vector3?)
	local anchor = World:get(towerEntity, Anchor)
	local model = World:get(towerEntity, ModelComponent)
	local towerModel: Model? = nil
	if typeof(anchor) == "Instance" and anchor:IsA("Model") then
		towerModel = anchor
	elseif typeof(model) == "Instance" and model:IsA("Model") then
		towerModel = model
	end
	if not towerModel then
		return nil, nil
	end

	local grip = towerModel:FindFirstChild("GripEntity", true)
	if grip and grip:IsA("Attachment") then
		return towerModel, grip.WorldPosition
	end
	return towerModel, towerModel:GetPivot().Position
end

function TargetingSystem.Update(_dt: number)
	-- Units
	for entity, pos, team, range in World:query(Position, Team, Range):with(UnitTag):without(TemplateTag, Dead) do
		if not isAliveEntity(entity) then
			continue
		end

		if World:get(entity, Ready) ~= true then
			continue
		end

		local targetKind = (World:get(entity, TargetKing) or "All") :: TargetKind
		local canRetarget = World:get(entity, CanRetargetTroops) == true and targetKind ~= "Buildings"
		local unitRange = if type(range) == "number" then range else 5

		local buildingEntity = World:get(entity, BuildingTarget)
		if type(buildingEntity) ~= "number" or buildingEntity == 0 or not isAliveEntity(buildingEntity) then
			local closestAnchor = EntityHelper.GetClosestEnemyTower(team :: any, pos)
			buildingEntity = if closestAnchor then resolveBuildingEntity(closestAnchor) else nil
			World:set(entity, BuildingTarget, buildingEntity or 0)
		end

		local currentTarget = World:get(entity, Target)
		local troopTarget = nil

		if canRetarget then
			if type(currentTarget) == "number" and currentTarget ~= 0 and World:has(currentTarget, UnitTag) then
				local targetPos = World:get(currentTarget, Position)
				local leaveRange = unitRange * TROOP_AGGRO_LEAVE_MULTIPLIER
				if not isAliveEntity(currentTarget) or typeof(targetPos) ~= "Vector3" then
					currentTarget = 0
				elseif getDistanceSq(pos, targetPos) > leaveRange * leaveRange then
					currentTarget = 0
				else
					troopTarget = currentTarget
				end
			end

			if not troopTarget then
				troopTarget = findClosestEnemyTroop(pos, team, targetKind, unitRange)
			end
		end

		if troopTarget then
			setTarget(entity, troopTarget)
		elseif type(buildingEntity) == "number" and buildingEntity ~= 0 then
			setTarget(entity, buildingEntity)
		else
			setTarget(entity, nil)
		end

		local target = World:get(entity, Target)
		local inRange = false
		if type(target) == "number" and target ~= 0 and isAliveEntity(target) then
			if World:has(target, TowerTag) then
				local towerModel, anchorPos = getTowerAnchorPos(target)
				if towerModel and anchorPos then
					local detection = EntityHelper.GetTowerDetectionRadius(towerModel, unitRange)
					inRange = (pos - anchorPos).Magnitude <= detection
				end
			else
				local targetPos = World:get(target, Position)
				if typeof(targetPos) == "Vector3" then
					inRange = getDistanceSq(pos, targetPos) <= unitRange * unitRange
				end
			end
		end

		AttributeMirror.SetAttackEnabled(entity, inRange)
	end

	-- Towers
	for entity, pos, team, range in World:query(Position, Team, Range):with(TowerTag):without(TemplateTag, Dead) do
		if not isAliveEntity(entity) then
			continue
		end

		local targetKind = (World:get(entity, TargetKing) or "All") :: TargetKind
		local towerRange = if type(range) == "number" then range else 18
		local myEnemy = enemyTeamOf(team)

		local currentTarget = World:get(entity, Target)
		if type(currentTarget) == "number" and currentTarget ~= 0 then
			local targetPos = World:get(currentTarget, Position)
			local targetTeam = World:get(currentTarget, Team)
			local lost = not isAliveEntity(currentTarget)
				or targetTeam ~= myEnemy
				or typeof(targetPos) ~= "Vector3"
				or getDistanceSq(pos, targetPos) > towerRange * towerRange
			if lost then
				currentTarget = 0
			end
		else
			currentTarget = 0
		end

		if currentTarget == 0 then
			local best = nil
			local bestDistSq = towerRange * towerRange
			for other, otherPos, otherTeam, otherKind in World:query(Position, Team, Kind):with(UnitTag):without(TemplateTag, Dead) do
				if otherTeam ~= myEnemy or not isAliveEntity(other) then
					continue
				end
				if type(otherKind) ~= "string" or not matchesTargetKind(targetKind, otherKind) then
					continue
				end
				local distSq = getDistanceSq(pos, otherPos)
				if distSq <= bestDistSq then
					best = other
					bestDistSq = distSq
				end
			end
			currentTarget = best or 0
		end

		setTarget(entity, if currentTarget ~= 0 then currentTarget else nil)
		AttributeMirror.SetAttackEnabled(entity, type(currentTarget) == "number" and currentTarget ~= 0)
	end
end

return TargetingSystem
