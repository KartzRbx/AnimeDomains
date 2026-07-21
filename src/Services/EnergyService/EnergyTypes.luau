export type EnergyContainer = Frame & {
	Bar: Frame & {
		UIGradient: UIGradient,
	},
	CurrentEnergy: TextLabel & {
		Main: TextLabel & {
			UIGradient: UIGradient,
		},
		UIStroke: UIStroke,
	},
	UIStroke: UIStroke & {
		UIGradient: UIGradient,
	},
}