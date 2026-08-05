--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const janitor = require(ReplicatedStorage.Packages.janitor)
const EntityActionManager = require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.AttacksData.EntityActionManager)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const AttackUtils = require(ReplicatedStorage.Shareds.Utils.AttackUtils)

assert(RunService:IsClient(), 'Cannot be required for server!')
const Config = require(script.Parent.Config)

const STATE_ATTACKING_ATT_NAME = "Attacking"

return function()
	return function(payload: EntityActionManager.AttackClientPayload)
		const attacker = payload.Attacker
		const section = janitor.new()

		attacker:SetAttribute(STATE_ATTACKING_ATT_NAME, true)

		const track = AnimationUtil.PlayEntityAnimationForUID(attacker, payload.UID, "Attack", 0.1)
		if not track then
			attacker:SetAttribute(STATE_ATTACKING_ATT_NAME, false)
			return
		end

		section:add(track.Stopped:Once(function()
			attacker:SetAttribute(STATE_ATTACKING_ATT_NAME, false)
			section:cleanup()
		end), "Disconnect")

		AttackUtils.BindTrackHitBox({
			Attacker = attacker,
			Track = track,
			HitTimes = Config.ATTACK_TIMES,
			WindowDuration = Config.HIT_WINDOW,
			Section = section,
			HitBoxConfig = {
				Shape = {
					Size = Config.HITBOX.Size,
					Offset = Config.HITBOX.Offset,
				},
				DebugVisible = false,
			},
			OnHit = function(result)
				for _, hitTarget in result.Targets do
					if hitTarget == payload.Target then
						print('Acertado')

						break
					end
				end
			end,
		})
	end
end
