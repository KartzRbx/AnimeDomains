--!strict

export type SabreAttackConfig = {
	ATTACK_TIMES: { number },
	HIT_WINDOW: number,
	HIT_DAMAGE_SCALE: number,
	HITBOX: {
		Size: Vector3,
		Offset: CFrame,
	},
}

local Config: SabreAttackConfig = {
	ATTACK_TIMES = {
		[1] = 0.75,
		[2] = 1.48,
	},
	HIT_WINDOW = 0.12,
	HIT_DAMAGE_SCALE = 1.1,
	HITBOX = {
		Size = Vector3.new(5, 4, 5),
		Offset = CFrame.new(0, 0, -2),
	},
}

return table.freeze(Config)
