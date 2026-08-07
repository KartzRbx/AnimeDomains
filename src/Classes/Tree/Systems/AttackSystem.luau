--!strict
-- Behavior: cooldown + fire unit/tower attacks from ECS Target

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const AttributeMirror = require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.AttributeMirror)
const EntityRegistry = require(ReplicatedStorage.Shareds.Classes.Tree.Runtime.EntityRegistry)

const AttackEnabled = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.AttackEnabled)
const Attacking = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Attacking)
const BaseDamage = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.BaseDamage)
const DelayAttack = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.DelayAttack)
const LastAttack = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.LastAttack)
const Level = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Level)
const ModelComponent = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Model)
const Position = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Position)
const Ready = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Ready)
const Target = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.Target)
const UID = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Primitives.UID)
const Dead = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.Dead)
const TemplateTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TemplateTag)
const TowerTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.TowerTag)
const UnitTag = require(ReplicatedStorage.Shareds.Classes.Tree.Build.Components.Tags.UnitTag)
const World = Mega.World

const ATTACK_PREP_LEAD = 0.35
const DEFAULT_TOWER_ATTACK_DELAY = 1

local unitAttackMeta: { [number]: any } = {}

local AttackSystem = {}

const function getEntityActionManager()
	return require(ReplicatedStorage.Shareds.Constants.PrimaryDatas.AttacksData.EntityActionManager)
end

const function getCombateStateHandler()
	return require(ReplicatedStorage.Shareds.Workers.CombateStateHandler)
end

function AttackSystem.BindUnitAttack(entity: number, uid: string)
	if unitAttackMeta[entity] then
		return
	end
	unitAttackMeta[entity] = getEntityActionManager():GetUnitAttack(uid)
end

function AttackSystem.Unbind(entity: number)
	local meta = unitAttackMeta[entity]
	if meta then
		meta:Destroy()
		unitAttackMeta[entity] = nil
	end
end

const function faceTarget(model: Model, targetPos: Vector3)
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	local flatTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
	local dir = flatTarget - hrp.Position
	if dir.Magnitude < 0.05 then
		return
	end

	hrp.CFrame = CFrame.lookAt(hrp.Position, flatTarget)
end

const function getTargetPos(targetEntity: number): Vector3?
	local pos = World:get(targetEntity, Position)
	if typeof(pos) == "Vector3" then
		return pos
	end
	local model = World:get(targetEntity, ModelComponent)
	if typeof(model) == "Instance" and model:IsA("Model") then
		return model:GetPivot().Position
	end
	return nil
end

function AttackSystem.Update(_dt: number)
	local now = os.clock()

	-- Units
	for entity, model in World:query(ModelComponent):with(UnitTag):without(TemplateTag, Dead) do
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			continue
		end
		if World:get(entity, Ready) ~= true then
			continue
		end

		local meta = unitAttackMeta[entity]
		local uid = World:get(entity, UID)
		if not meta or type(uid) ~= "string" then
			continue
		end

		local targetEntity = World:get(entity, Target)
		local targetUid = ""
		if type(targetEntity) == "number" and targetEntity ~= 0 then
			local resolved = EntityRegistry.GetUid(targetEntity)
			targetUid = if type(resolved) == "string" then resolved else ""
		end

		meta.TargetUID = targetUid
		meta.CanAttack = World:get(entity, AttackEnabled) == true and targetUid ~= ""

		-- Keep ECS Attacking in sync with Model attribute (attack modules clear it)
		local attrAttacking = model:GetAttribute("Attacking") == true
		AttributeMirror.SetAttacking(entity, attrAttacking)

		-- DelayAttack = duração da anim de ataque (intervalo entre inícios de swing)
		local delay = World:get(entity, DelayAttack) or 1
		if type(delay) ~= "number" or delay <= 0 then
			delay = 1
		end
		local lastAttack = World:get(entity, LastAttack) or 0
		local isAttacking = attrAttacking
		local elapsed = now - lastAttack
		local cooldownReady = elapsed >= delay

		if meta.CanAttack and (isAttacking or elapsed >= delay - ATTACK_PREP_LEAD) then
			local targetPos = if type(targetEntity) == "number" then getTargetPos(targetEntity) else nil
			if targetPos then
				faceTarget(model, targetPos)
			end
			AnimationUtil.GetOrLoadTrackForUID(model, uid, "Attack")
		end

		if not meta.CanAttack or isAttacking or not cooldownReady then
			continue
		end

		local ok = meta:Attack()
		if ok then
			World:set(entity, LastAttack, now)
			AttributeMirror.SetAttacking(entity, true)

			-- Backup: se Stopped falhar, libera no fim do DelayAttack (= anim)
			const swingStartedAt = now
			task.delay(delay, function()
				if not World:contains(entity) then
					return
				end
				if World:get(entity, LastAttack) ~= swingStartedAt then
					return
				end
				AttributeMirror.SetAttacking(entity, false)
			end)
		end
	end

	-- Towers (direct damage)
	for entity, model in World:query(ModelComponent):with(TowerTag):without(TemplateTag, Dead) do
		if typeof(model) ~= "Instance" or not model:IsA("Model") then
			continue
		end

		local attackEnabled = World:get(entity, AttackEnabled) == true
		local targetEntity = World:get(entity, Target)
		if not attackEnabled or type(targetEntity) ~= "number" or targetEntity == 0 then
			continue
		end

		local targetPos = getTargetPos(targetEntity)
		if targetPos then
			faceTarget(model, targetPos)
		end

		local delay = World:get(entity, DelayAttack) or DEFAULT_TOWER_ATTACK_DELAY
		if delay <= 0 then
			delay = DEFAULT_TOWER_ATTACK_DELAY
		end
		local lastAttack = World:get(entity, LastAttack) or 0
		if now - lastAttack < delay then
			continue
		end
		if World:get(entity, Attacking) == true then
			continue
		end

		local uid = World:get(entity, UID)
		local targetUid = EntityRegistry.GetUid(targetEntity)
		local targetModel = World:get(targetEntity, ModelComponent)
		if type(uid) ~= "string" or type(targetUid) ~= "string" then
			continue
		end
		if typeof(targetModel) ~= "Instance" or not targetModel:IsA("Model") then
			continue
		end

		local levelAny = World:get(entity, Level)
		local level = if type(levelAny) == "number" then levelAny else 1
		local baseAny = World:get(entity, BaseDamage)
		local baseDamage = if type(baseAny) == "number" then baseAny else 0
		local damage = EntityHelper.CalculateDamage({
			BaseDamage = baseDamage,
			Level = level,
		})

		World:set(entity, LastAttack, now)
		AttributeMirror.SetAttacking(entity, true)

		local Debi = require(ReplicatedStorage.Shareds.Networker.NetServer).Secondary
		Debi.BindAttack_Replica.FireAll({
			UID = uid,
			TargetUID = targetUid,
		})

		task.delay(delay, function()
			if World:contains(entity) then
				AttributeMirror.SetAttacking(entity, false)
			end
		end)

		getCombateStateHandler():ApplyDamageToTarget(targetModel, damage, {
			AttackerUID = uid,
			TargetUID = targetUid,
			HitIndex = 1,
			HitTime = 0,
		})
	end
end

return AttackSystem
