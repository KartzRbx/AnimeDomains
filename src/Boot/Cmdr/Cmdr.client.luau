--!strict
-- Behavior: wires up the Cmdr client (opens with ;)

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))
CmdrClient:SetActivationKeys({ Enum.KeyCode.F2 })
