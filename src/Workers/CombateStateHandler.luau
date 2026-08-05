--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const CardsServiceUtils = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceUtils)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)

export type PlayerCanEmitAttackResult = {
	UID: string,
	CardID: string,
	CanAttack: boolean,
	Reason: string,
}

export type ApplyDamageMeta = {
	AttackerUID: string,
	TargetUID: string,
	HitIndex: number,
	HitTime: number,
}

export type AttackHitClaimResult = {
	UID: string,
	TargetUID: string,
	HitIndex: number,
	Accepted: boolean,
	Reason: string,
}

export type AttackSessionConfig = {
	HitTimes: { number },
	HitWindow: number,
	HitDamageScale: number,
}

type AttackSession = {
	TargetUID: string,
	StartedAt: number,
	Config: AttackSessionConfig,
	ProcessedHits: { [number]: boolean },
	OwnerName: string,
}

const CombateStateHandler = {}

const STATE_ATTACKING_ATT_NAME = "Attacking"
const TIMING_TOLERANCE = 0.2
const SESSION_CLEANUP_BUFFER = 0.5

const attackSessions: { [string]: AttackSession } = {}

const function HasCardIDInPlayerCache(toPlayer: Player, CardId: string): boolean
	return CardsServiceUtils._GetCardDataWithID(CardId, toPlayer) ~= nil
end

const function getMaxHitTime(hitTimes: { number }): number
	local maxTime = 0
	for _, hitTime in hitTimes do
		if hitTime > maxTime then
			maxTime = hitTime
		end
	end
	return maxTime
end

const function resolveHitDamage(attacker: Model, session: AttackSession): number
	local cardId = attacker:GetAttribute("CardId")
	if type(cardId) ~= "string" then
		return 0
	end

	local entityData = EntityHelper.GetEntityDataByCardId(cardId)
	if not entityData then
		return 0
	end

	local level = attacker:GetAttribute("Level")
	if type(level) ~= "number" then
		level = entityData.Level
	end

	return EntityHelper.CalculateDamage({
		BaseDamage = entityData.BaseDamage,
		Level = level,
		DamageMultiplier = session.Config.HitDamageScale,
	})
end

const function clearAttackSession(uid: string)
	local session = attackSessions[uid]
	if not session then
		return
	end

	local entityModel = EntityHelper.GetEntityCharacterForUID(uid)
	if entityModel then
		entityModel:SetAttribute(STATE_ATTACKING_ATT_NAME, false)
	end

	attackSessions[uid] = nil
end

function CombateStateHandler.RegisterAttackSession(
	_self: CombateStateHandler,
	uid: string,
	targetUID: string,
	config: AttackSessionConfig
)
	const entityModel = EntityHelper.GetEntityCharacterForUID(uid)
	if not entityModel then
		return
	end

	const ownerName = entityModel:GetAttribute("Owner")
	if type(ownerName) ~= "string" then
		return
	end

	attackSessions[uid] = {
		TargetUID = targetUID,
		StartedAt = os.clock(),
		Config = config,
		ProcessedHits = {},
		OwnerName = ownerName,
	}

	local maxHitTime = getMaxHitTime(config.HitTimes)
	task.delay(maxHitTime + config.HitWindow + SESSION_CLEANUP_BUFFER, function()
		if attackSessions[uid] then
			clearAttackSession(uid)
		end
	end)
end

function CombateStateHandler.ProcessAttackHitClaim(
	_self: CombateStateHandler,
	player: Player,
	uid: string,
	targetUID: string,
	hitIndex: number,
	hitTime: number
): AttackHitClaimResult
	local result: AttackHitClaimResult = {
		UID = uid,
		TargetUID = targetUID,
		HitIndex = hitIndex,
		Accepted = false,
		Reason = "",
	}

	local session = attackSessions[uid]
	if not session then
		result.Reason = "Attack session missing"
		return result
	end

	if session.OwnerName ~= player.Name then
		result.Reason = "Not attack owner"
		return result
	end

	if session.TargetUID ~= targetUID then
		result.Reason = "Target mismatch"
		return result
	end

	if session.ProcessedHits[hitIndex] then
		result.Reason = "Hit already processed"
		return result
	end

	local expectedHitTime = session.Config.HitTimes[hitIndex]
	if expectedHitTime == nil then
		result.Reason = "Invalid hit index"
		return result
	end

	if math.abs(hitTime - expectedHitTime) > TIMING_TOLERANCE then
		result.Reason = "Hit frame mismatch"
		return result
	end

	local attacker = EntityHelper.GetEntityCharacterForUID(uid)
	local target = EntityHelper.GetCombatTargetForId(targetUID)
	if not attacker or not target then
		result.Reason = "Entity or target not found"
		return result
	end

	if attacker:GetAttribute("AttackEnabled") ~= true then
		result.Reason = "Attack not enabled"
		return result
	end

	local damage = resolveHitDamage(attacker, session)
	if damage <= 0 then
		result.Reason = "Invalid damage"
		return result
	end

	local applied = CombateStateHandler:ApplyDamageToTarget(target, damage, {
		AttackerUID = uid,
		TargetUID = targetUID,
		HitIndex = hitIndex,
		HitTime = hitTime,
	})

	if not applied then
		result.Reason = "Damage not applied"
		return result
	end

	session.ProcessedHits[hitIndex] = true
	result.Accepted = true
	return result
end

function CombateStateHandler.PlayerCanEmitAttackForCardID(
	_player: CombateStateHandler,
	player: Player,
	UID: string,
	CardID: string
): PlayerCanEmitAttackResult
	local result: PlayerCanEmitAttackResult = {
		UID = UID,
		CardID = CardID,
		CanAttack = false,
		Reason = "",
	}

	if type(UID) ~= "string" or UID == "" then
		result.Reason = "Invalid UID"
		return result
	end

	if type(CardID) ~= "string" or CardID == "" then
		result.Reason = "Invalid CardID"
		return result
	end

	if not HasCardIDInPlayerCache(player, CardID) then
		result.Reason = "Card not owned"
		return result
	end

	local entityModel = EntityHelper.GetEntityCharacterForUID(UID)
	if not entityModel then
		result.Reason = "Entity not found"
		return result
	end

	if entityModel:GetAttribute("Owner") ~= player.Name then
		result.Reason = "Not entity owner"
		return result
	end

	local entityCardId = entityModel:GetAttribute("CardId")
	if type(entityCardId) ~= "string" or entityCardId ~= CardID then
		result.Reason = "CardID mismatch"
		return result
	end

	if entityModel:GetAttribute("Ready") ~= true then
		result.Reason = "Entity not ready"
		return result
	end

	if entityModel:GetAttribute("AttackEnabled") ~= true then
		result.Reason = "Entity cannot attack"
		return result
	end

	result.CanAttack = true
	return result
end

function CombateStateHandler.ApplyDamageToTarget(
	_self: CombateStateHandler,
	target: Model,
	damage: number,
	_meta: ApplyDamageMeta?
): boolean
	if damage <= 0 then
		return false
	end

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	humanoid:TakeDamage(damage)
	return true
end

function CombateStateHandler.ManagerEntityForPlayer(_self: CombateStateHandler, _player: Player, _CardId: string)
	return
end

export type CombateStateHandler = typeof(CombateStateHandler)
return CombateStateHandler
