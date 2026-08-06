--!strict
-- Behavior: single server Heartbeat runner for Tree ECS systems

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const PositionSystem = require(script.Parent.PositionSystem)
const TargetingSystem = require(script.Parent.TargetingSystem)
const MovementSystem = require(script.Parent.MovementSystem)
const AttackSystem = require(script.Parent.AttackSystem)
const HealthSystem = require(script.Parent.HealthSystem)

local started = false
local connection: RBXScriptConnection? = nil

local Schedule = {}

function Schedule.Start()
	assert(RunService:IsServer(), "[Tree.Schedule] server-only")
	if started then
		return
	end
	started = true

	connection = RunService.Heartbeat:Connect(function(dt)
		PositionSystem.Update(dt)
		TargetingSystem.Update(dt)
		MovementSystem.Update(dt)
		AttackSystem.Update(dt)
		HealthSystem.Update(dt)
	end)
end

function Schedule.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	started = false
end

return Schedule
