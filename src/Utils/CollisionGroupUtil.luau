--!strict
-- Behavior: Players ↔ Entities do not collide; EntityBarriers block Units, not Players

const Players = game:GetService("Players")
const PhysicsService = game:GetService("PhysicsService")
const RunService = game:GetService("RunService")

export type CollisionGroupName = "Players" | "Entities" | "EntityBarriers"

const GROUP_PLAYERS: CollisionGroupName = "Players"
const GROUP_ENTITIES: CollisionGroupName = "Entities"
const GROUP_ENTITY_BARRIERS: CollisionGroupName = "EntityBarriers"

local registered = false
local playerHooked = false

const function ensureGroup(name: CollisionGroupName)
	if not RunService:IsServer() then
		return
	end
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

const function applyGroup(instance: Instance, group: CollisionGroupName)
	if instance:IsA("BasePart") then
		instance.CollisionGroup = group
	end
end

const function applyGroupRecursive(root: Instance, group: CollisionGroupName)
	applyGroup(root, group)
	for _, descendant in root:GetDescendants() do
		applyGroup(descendant, group)
	end
end

local CollisionGroupsUtils = {}

function CollisionGroupsUtils.Init()
	if registered then
		return
	end
	registered = true

	if RunService:IsServer() then
		ensureGroup(GROUP_PLAYERS)
		ensureGroup(GROUP_ENTITIES)
		ensureGroup(GROUP_ENTITY_BARRIERS)

		-- Players pass through troops and entity barriers
		PhysicsService:CollisionGroupSetCollidable(GROUP_PLAYERS, GROUP_ENTITIES, false)
		PhysicsService:CollisionGroupSetCollidable(GROUP_PLAYERS, GROUP_ENTITY_BARRIERS, false)
		-- Units hit barriers (pathfinder / physics)
		PhysicsService:CollisionGroupSetCollidable(GROUP_ENTITIES, GROUP_ENTITY_BARRIERS, true)

		if not playerHooked then
			playerHooked = true

			local function hookCharacter(character: Model)
				applyGroupRecursive(character, GROUP_PLAYERS)
				character.DescendantAdded:Connect(function(descendant)
					applyGroup(descendant, GROUP_PLAYERS)
				end)
			end

			local function hookPlayer(player: Player)
				if player.Character then
					hookCharacter(player.Character)
				end
				player.CharacterAdded:Connect(hookCharacter)
			end

			for _, player in Players:GetPlayers() do
				hookPlayer(player)
			end
			Players.PlayerAdded:Connect(hookPlayer)
		end
	end
end

function CollisionGroupsUtils.AssignEntity(model: Model)
	if RunService:IsServer() and not registered then
		CollisionGroupsUtils.Init()
	end
	applyGroupRecursive(model, GROUP_ENTITIES)
	model.DescendantAdded:Connect(function(descendant)
		applyGroup(descendant, GROUP_ENTITIES)
	end)
end

-- Build.EntityLimitations: CanCollide + PathfindingModifier (NavMesh avoids)
function CollisionGroupsUtils.AssignEntityBarriers(root: Instance)
	if RunService:IsServer() and not registered then
		CollisionGroupsUtils.Init()
	end

	local function configurePart(part: BasePart)
		part.CanCollide = true
		part.Anchored = true
		part.CollisionGroup = GROUP_ENTITY_BARRIERS

		local mod = part:FindFirstChildOfClass("PathfindingModifier")
		if not mod then
			mod = Instance.new("PathfindingModifier")
			mod.Parent = part
		end
		mod.Label = "EntityBarrier"
		mod.PassThrough = false
	end

	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			configurePart(descendant)
		end
	end
	if root:IsA("BasePart") then
		configurePart(root)
	end
end

CollisionGroupsUtils.Players = GROUP_PLAYERS
CollisionGroupsUtils.Entities = GROUP_ENTITIES
CollisionGroupsUtils.EntityBarriers = GROUP_ENTITY_BARRIERS

return CollisionGroupsUtils
