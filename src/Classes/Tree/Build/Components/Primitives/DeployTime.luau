--!strict
-- jecs component: deploy delay (seconds) before the unit can act — CR wiki standard troop value is 1 sec
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)

local DeployTime = Mega.World:component()
return DeployTime