--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const signal = require(ReplicatedStorage.Packages.signal)
const GameplayTypes = require(script.Parent.Parent.GameplayService.GameplayTypes)

export type PlaceUnitRequest = {
	CardId: string,
	SlotIndex: number,
	Position: GameplayTypes.Vec3Data,
}

export type UnitBillboard = BillboardGui & {
	CrownDisplay: Frame & {
		CrownIcon: ImageLabel & {
			UIAspectRatioConstraint: UIAspectRatioConstraint,
		},
		TowerLevelValue: TextLabel & {
			UIGradient: UIGradient,
			UIShadow: UIShadow,
			UIStroke: UIStroke,
		},
	},
	HealthDisplay: Frame & {
		CrownIcon: ImageLabel & {
			UIAspectRatioConstraint: UIAspectRatioConstraint,
		},
		HealthBar: Frame & {
			Bar: Frame & {
				UIGradient: UIGradient,
			},
			UIStroke: UIStroke,
		},
		HealthInfoContainer: Frame & {
			HealthIcon: ImageLabel & {
				UIAspectRatioConstraint: UIAspectRatioConstraint,
			},
			TowerHealth: TextLabel & {
				UIGradient: UIGradient,
				UIStroke: UIStroke,
			},
			UIListLayout: UIListLayout,
		},
		TowerLevelValue: TextLabel & {
			UIGradient: UIGradient,
			UIShadow: UIShadow,
			UIStroke: UIStroke,
		},
	},
	UIListLayout: UIListLayout,
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

export type NewEntityCardData = {
	CardId: string,
	Position: GameplayTypes.Vec3Data,
	Player: Player,
}

export type SpawnEntityCallback = {
	Completed: typeof(signal.new()),
}

export type Clock = Model & {
	Look: BasePart & {
		Attachment: Attachment & {
			Wave: ParticleEmitter,
		},
		Cowdown: BillboardGui & {
			Container: Frame & {
				TextLabel: TextLabel & {
					UIShadow: UIShadow & {
						UICorner: UICorner,
					},
				},
			},
		},
	},
	Mesh: BasePart,
	Mesh_2: BasePart & {
		WeldConstraint: WeldConstraint,
	},
	Mesh_3: BasePart,
	Mesh_4: BasePart,
	Mesh_5: BasePart & {
		WeldConstraint: WeldConstraint,
		WeldConstraint_2: WeldConstraint,
		WeldConstraint_3: WeldConstraint,
	},
}

-- Basic unit/character rig (Humanoid + HRP)
export type UnitRig = Model & {
	Humanoid: Humanoid & {
		Animator: Animator,
	},
	HumanoidRootPart: BasePart & {
		RootAttachment: Attachment?,
	},
}

-- Mirrors Debi SpawnEntityInMapFromServerType (network payload + local entry)
export type CardEntityEntry = {
	UID: string,
	CardId: string,
	Ready: boolean,
	Attacking: boolean,
	Idle: AnimationTrack?,
	Walk: AnimationTrack?,
	Deploytime: number,
	Player: Player,
	Position: GameplayTypes.Vec3Data,
	Model: Model?,
}

export type CardEntityMap = { [string]: CardEntityEntry }

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
