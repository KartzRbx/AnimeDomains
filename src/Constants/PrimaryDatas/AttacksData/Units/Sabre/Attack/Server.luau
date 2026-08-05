--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const janitor = require(ReplicatedStorage.Packages.janitor)
const EntityActionManager = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.AttacksData.EntityActionManager)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const AttackUtils = require(ReplicatedStorage.Shareds.Utils.AttackUtils)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const CombateStateHandler = require(ReplicatedStorage.Shareds.Workers.CombateStateHandler)


assert(RunService:IsServer(), 'Cannot be required for client!')

const Config = require(script.Parent.Config)

const STATE_ATTACKING_ATT_NAME = "Attacking"

-- << TODO Converter para função de utilidade em EntitysHelper.luau >> -- 
const function resolveHitDamage(attacker: Model): number
	local cardId = attacker:GetAttribute("CardId")
	if type(cardId) ~= "string" then
		return 0
	end

	local entityData = EntityHelper.GetEntityDataByCardId(cardId)
	if not entityData then
		return 0
	end

	local level
	local levelAttr = attacker:GetAttribute("Level")
	if type(levelAttr) == "number" then
		level = levelAttr
	else
		level = entityData.Level
	end
	

	return EntityHelper.CalculateDamage({
		BaseDamage = entityData.BaseDamage,
		Level = level,
		DamageMultiplier = Config.HIT_DAMAGE_SCALE,
	})
end

return function()
	return function(action: EntityActionManager.MetaTable): (boolean, string)
		const entityModel = EntityHelper.GetEntityCharacterForUID(action.UID)
		const lockedTarget = EntityHelper.GetCombatTargetForId(action.TargetUID)
		const section = janitor.new()

		if not entityModel or not lockedTarget then
			return false, "Entity or target not found"
		end

		const track = AnimationUtil.GetOrLoadTrackForUID(entityModel, action.UID, "Attack")
		if not track then
			return false, "Attack animation not found"
		end

		track:Play(0.1)

		section:add(track.Stopped:Once(function()
			entityModel:SetAttribute(STATE_ATTACKING_ATT_NAME, false)
			section:cleanup()
		end), "Disconnect")

		AttackUtils.BindTrackHitBox({
			Attacker = entityModel,
			Track = track,
			HitTimes = Config.ATTACK_TIMES,
			WindowDuration = Config.HIT_WINDOW,
			Section = section,
			HitBoxConfig = {
				Shape = {
					Size = Config.HITBOX.Size,
					Offset = Config.HITBOX.Offset,
				},
			},
			OnHit = function(result)
				local hasLocked = false
				for _, hitTarget in result.Targets do
					if hitTarget == lockedTarget then
						hasLocked = true
						break
					end
				end

				if not hasLocked then
					return
				end

				local damage = resolveHitDamage(entityModel)
				if damage <= 0 then
					warn('Damage not found')
					return
				end

				print(damage)
				CombateStateHandler:ApplyDamageToTarget(lockedTarget, damage, {
					AttackerUID = action.UID,
					TargetUID = action.TargetUID,
					HitIndex = result.HitIndex,
					HitTime = result.HitTime,
				})
			end,
		})

		return true, ""
	end
end
