--!strict

const GameplayTypes = require(script.Parent.Parent.GameplayService.GameplayTypes)

export type PlaceUnitRequest = {
	CardId: string,
	Position: GameplayTypes.Vec3Data,
}

export type TemplateCard = Frame & {
	Card: ImageButton & {
		Background: CanvasGroup & {
			Back: ImageLabel,
			Textura1: ImageLabel,
			Textura2: ImageLabel,
			UICorner: UICorner,
			UIGradient: UIGradient,
		},
		Background_2: ImageLabel & {
			UIGradient: UIGradient,
		},
		Descrition: Frame & {
			Info: Frame & {
				NameAvatar: TextLabel,
				Value: Frame & {
					Icon: ImageLabel,
					UIListLayout: UIListLayout,
					Value: TextLabel,
				},
			},
			Level: Frame & {
				ExpValue: TextLabel & {
					UIStroke: UIStroke,
				},
				LevelValue: TextLabel & {
					UIStroke: UIStroke,
				},
			},
			LevelBar: CanvasGroup & {
				Bar: Frame & {
					UICorner: UICorner,
					UIGradient: UIGradient,
				},
				StrokeCenter: UIStroke,
				StrokeCenterBack: UIStroke,
				StrokeInner: UIStroke,
				UICorner: UICorner,
			},
			Stroke: Frame & {
				UIGradient: UIGradient,
			},
			UICorner: UICorner,
			UIGradient: UIGradient,
			UIListLayout: UIListLayout,
		},
		Effect: CanvasGroup & {
			Back: ImageLabel,
			Textura1: ImageLabel,
			Textura2: ImageLabel,
			UICorner: UICorner,
			UIGradient: UIGradient,
		},
		EnergyInfo: ImageLabel & {
			EnergyValue: TextLabel & {
				UIStroke: UIStroke,
			},
			UIAspectRatioConstraint: UIAspectRatioConstraint,
		},
		Front: ImageLabel & {
			UICorner: UICorner,
		},
		Rank: TextLabel & {
			TextLabel: TextLabel,
			UIStroke: UIStroke,
		},
		Stroke: Frame & {
			StrokeInner: UIStroke & {
				UIGradient: UIGradient,
			},
			UICorner: UICorner,
			UIStroke: UIStroke & {
				UIGradient: UIGradient,
			},
		},
		UIAspectRatioConstraint: UIAspectRatioConstraint,
		UICorner: UICorner,
		UIScale: UIScale,
		UIShadow: UIShadow,
	},
	UIDragDetector: UIDragDetector,
}

-- Studio container; slots are created at runtime by the client
export type CardsContainer = Frame

export type GameplayHud = Frame & {
	Background: ImageLabel,
	CardsContainer: CardsContainer,
	UIAspectRatioConstraint: UIAspectRatioConstraint,
	UIGradient: UIGradient,
	UIStroke: UIStroke,
}

export type MainGui = ScreenGui & {
	Container: Frame & {
		Gameplay: GameplayHud,
	},
}

export type PreviewEffects = Model & {
	BillboardGui: BillboardGui & {
		Container: Frame & {
			EntityName: TextLabel & {
				MainText: TextLabel & {
					UIStroke: UIStroke,
				},
				UIStroke: UIStroke,
			},
			Level: TextLabel & {
				MainText: TextLabel & {
					UIStroke: UIStroke,
				},
				UIStroke: UIStroke,
			},
		},
	},
	Highlight: Highlight,
	Main: Attachment & {
		Slash1: ParticleEmitter,
	},
}

return {}
