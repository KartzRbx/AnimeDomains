--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const CombateStateHandler = require(ReplicatedStorage.Shareds.Workers.CombateStateHandler)
const NetServer = require(ReplicatedStorage.Shareds.Networker.NetServer)

NetServer.Validations.PlayerCanEmitAttackForCardID.SetCallback(function(player: Player, UID: string, CardID: string)
	local result = CombateStateHandler:PlayerCanEmitAttackForCardID(player, UID, CardID)
	NetServer.Validations.PlayerCanEmitAttackForCardIDResult.Fire(player, result)
end)

NetServer.Validations.AttackHitClaim.SetCallback(function(
	player: Player,
	UID: string,
	TargetUID: string,
	HitIndex: number,
	HitTime: number
)
	local result = CombateStateHandler:ProcessAttackHitClaim(player, UID, TargetUID, HitIndex, HitTime)
	NetServer.Validations.AttackHitClaimResult.Fire(player, result)
end)
