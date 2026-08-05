
export type Teams = Folder & {
	One: Folder & {
		Interactions: Folder & {
			EntitySpawnZone: Model & {
				Base: BasePart & {
					Highlight: Highlight,
				},
				Left: BasePart & {
					Highlight: Highlight,
				},
				Main: BasePart & {
					Highlight: Highlight,
				},
				Right: BasePart & {
					Highlight: Highlight,
				},
			},
			PlayerSpawn: BasePart,
		},
		Players: Folder & {
			KartzBro: Model & {
				["Accessory (DoubleOutline)"]: Accessory & {
					Handle: BasePart & {
						AccessoryRigidConstraint: RigidConstraint,
						BodyFrontAttachment: Attachment,
						DoubleOutlineWrapLayer: WrapLayer,
						OriginalSize: Vector3Value,
					},
				},
				["Accessory (cartoony pixel meme sunglasses)"]: Accessory & {
					Handle: BasePart & {
						AccessoryRigidConstraint: RigidConstraint,
						AvatarPartScaleType: StringValue,
						FaceCenterAttachment: Attachment & {
							OriginalPosition: Vector3Value,
						},
						OriginalSize: Vector3Value,
					},
				},
				AudioEmitter: AudioEmitter & {
					Wire: Wire,
				},
				["Body Colors"]: BodyColors,
				Head: BasePart & {
					AvatarPartScaleType: StringValue,
					FaceCenterAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					FaceControls: FaceControls,
					FaceFrontAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					HairAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					HatAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					HeadWrapTarget: WrapTarget,
					HumanoidRootPartNoCollision: NoCollisionConstraint,
					LeftUpperArmNoCollision: NoCollisionConstraint,
					Neck: AnimationConstraint,
					NeckBallSocket: BallSocketConstraint,
					NeckRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					OriginalSize: Vector3Value,
					RightUpperArmNoCollision: NoCollisionConstraint,
				},
				Humanoid: Humanoid & {
					Animator: Animator,
					BodyDepthScale: NumberValue,
					BodyHeightScale: NumberValue,
					BodyProportionScale: NumberValue,
					BodyTypeScale: NumberValue,
					BodyWidthScale: NumberValue,
					HeadScale: NumberValue,
					HumanoidDescription: HumanoidDescription & {
						AccessoryDescription: AccessoryDescription,
						AccessoryDescription_2: AccessoryDescription,
						AccessoryDescription_3: AccessoryDescription,
						BodyPartDescription: BodyPartDescription,
						BodyPartDescription_2: BodyPartDescription,
						BodyPartDescription_3: BodyPartDescription,
						BodyPartDescription_4: BodyPartDescription,
						BodyPartDescription_5: BodyPartDescription,
						BodyPartDescription_6: BodyPartDescription,
					},
					Status: Status,
				},
				HumanoidRootPart: BasePart & {
					Climbing: Sound,
					Died: Sound,
					FreeFalling: Sound,
					GettingUp: Sound,
					Jumping: Sound,
					Landing: Sound,
					OriginalSize: Vector3Value,
					RootAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RootRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					Running: Sound,
					Splash: Sound,
					Swimming: Sound,
				},
				LeftFoot: BasePart & {
					LeftAnkle: AnimationConstraint,
					LeftAnkleBallSocket: BallSocketConstraint,
					LeftAnkleRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftFoot: WrapTarget,
					LeftFootAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					OriginalSize: Vector3Value,
				},
				LeftHand: BasePart & {
					LeftGripAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftHand: WrapTarget,
					LeftWrist: AnimationConstraint,
					LeftWristBallSocket: BallSocketConstraint,
					LeftWristRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					OriginalSize: Vector3Value,
				},
				LeftLowerArm: BasePart & {
					LeftElbow: AnimationConstraint,
					LeftElbowBallSocket: BallSocketConstraint,
					LeftElbowRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftLowerArm: WrapTarget,
					LeftWristRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					OriginalSize: Vector3Value,
				},
				LeftLowerLeg: BasePart & {
					LeftAnkleRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftKnee: AnimationConstraint,
					LeftKneeBallSocket: BallSocketConstraint,
					LeftKneeRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftLowerLeg: WrapTarget,
					OriginalSize: Vector3Value,
				},
				LeftUpperArm: BasePart & {
					LeftElbowRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftHandNoCollision: NoCollisionConstraint,
					LeftShoulder: AnimationConstraint,
					LeftShoulderAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftShoulderBallSocket: BallSocketConstraint,
					LeftShoulderRigAttachment: Attachment & {
						JointRotation: Attachment & {
							OriginalPosition: Vector3Value,
						},
						OriginalPosition: Vector3Value,
					},
					LeftUpperArm: WrapTarget,
					OriginalSize: Vector3Value,
				},
				LeftUpperLeg: BasePart & {
					LeftFootNoCollision: NoCollisionConstraint,
					LeftHip: AnimationConstraint,
					LeftHipBallSocket: BallSocketConstraint,
					LeftHipRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftKneeRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftUpperLeg: WrapTarget,
					OriginalSize: Vector3Value,
					RightUpperLegNoCollision: NoCollisionConstraint,
				},
				LowerTorso: BasePart & {
					LeftHipRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftLowerLegNoCollision: NoCollisionConstraint,
					LeftUpperArmNoCollision: NoCollisionConstraint,
					LowerTorso: WrapTarget,
					OriginalSize: Vector3Value,
					RightHipRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightLowerLegNoCollision: NoCollisionConstraint,
					RightUpperArmNoCollision: NoCollisionConstraint,
					Root: AnimationConstraint,
					RootRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					WaistBackAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					WaistCenterAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					WaistFrontAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					WaistRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
				},
				["Meshes/FedoraAccessory"]: Accessory & {
					Handle: BasePart & {
						AccessoryRigidConstraint: RigidConstraint,
						AvatarPartScaleType: StringValue,
						HatAttachment: Attachment & {
							OriginalPosition: Vector3Value,
						},
						OriginalSize: Vector3Value,
					},
				},
				Pants: Pants,
				RightFoot: BasePart & {
					OriginalSize: Vector3Value,
					RightAnkle: AnimationConstraint,
					RightAnkleBallSocket: BallSocketConstraint,
					RightAnkleRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightFoot: WrapTarget,
					RightFootAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
				},
				RightHand: BasePart & {
					OriginalSize: Vector3Value,
					RightGripAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightHand: WrapTarget,
					RightWrist: AnimationConstraint,
					RightWristBallSocket: BallSocketConstraint,
					RightWristRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
				},
				RightLowerArm: BasePart & {
					OriginalSize: Vector3Value,
					RightElbow: AnimationConstraint,
					RightElbowBallSocket: BallSocketConstraint,
					RightElbowRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightLowerArm: WrapTarget,
					RightWristRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
				},
				RightLowerLeg: BasePart & {
					OriginalSize: Vector3Value,
					RightAnkleRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightKnee: AnimationConstraint,
					RightKneeBallSocket: BallSocketConstraint,
					RightKneeRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightLowerLeg: WrapTarget,
				},
				RightUpperArm: BasePart & {
					OriginalSize: Vector3Value,
					RightElbowRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightHandNoCollision: NoCollisionConstraint,
					RightShoulder: AnimationConstraint,
					RightShoulderAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightShoulderBallSocket: BallSocketConstraint,
					RightShoulderRigAttachment: Attachment & {
						JointRotation: Attachment & {
							OriginalPosition: Vector3Value,
						},
						OriginalPosition: Vector3Value,
					},
					RightUpperArm: WrapTarget,
				},
				RightUpperLeg: BasePart & {
					OriginalSize: Vector3Value,
					RightFootNoCollision: NoCollisionConstraint,
					RightHip: AnimationConstraint,
					RightHipBallSocket: BallSocketConstraint,
					RightHipRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightKneeRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightUpperLeg: WrapTarget,
				},
				Shirt: Shirt,
				UpperTorso: BasePart & {
					BodyBackAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					BodyFrontAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					HumanoidRootPartNoCollision: NoCollisionConstraint,
					LeftCollarAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					LeftLowerArmNoCollision: NoCollisionConstraint,
					LeftLowerLegNoCollision: NoCollisionConstraint,
					LeftShoulderRigAttachment: Attachment & {
						JointRotation: Attachment & {
							OriginalPosition: Vector3Value,
						},
						OriginalPosition: Vector3Value,
					},
					LeftUpperLegNoCollision: NoCollisionConstraint,
					NeckAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					NeckRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					OriginalSize: Vector3Value,
					RightCollarAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
					RightLowerArmNoCollision: NoCollisionConstraint,
					RightLowerLegNoCollision: NoCollisionConstraint,
					RightShoulderRigAttachment: Attachment & {
						JointRotation: Attachment & {
							OriginalPosition: Vector3Value,
						},
						OriginalPosition: Vector3Value,
					},
					RightUpperLegNoCollision: NoCollisionConstraint,
					UpperTorso: WrapTarget,
					Waist: AnimationConstraint,
					WaistBallSocket: BallSocketConstraint,
					WaistRigAttachment: Attachment & {
						OriginalPosition: Vector3Value,
					},
				},
			},
		},
		Towers: Folder & {
			LeftTower: Model & {
				["Cube.026"]: BasePart,
				GripEntity: Attachment,
			},
			MainTower: Model & {
				["BézierCurve"]: BasePart,
				["Cube.011"]: BasePart,
				["Cube.012"]: BasePart,
				["Cylinder.002"]: BasePart,
				["Cylinder.005"]: BasePart,
				GripEntity: Attachment,
			},
			RightTower: Model & {
				["Cube.028"]: BasePart,
				GripEntity: Attachment,
			},
		},
		Units: Folder,
	},
	Two: Folder & {
		Interactions: Folder & {
			EntitySpawnZone: Model & {
				Base: BasePart & {
					Highlight: Highlight,
				},
				Left: BasePart & {
					Highlight: Highlight,
				},
				Main: BasePart & {
					Highlight: Highlight,
				},
				Right: BasePart & {
					Highlight: Highlight,
				},
			},
			PlayerSpawn: BasePart,
		},
		Players: Folder,
		Towers: Folder & {
			LeftTower: Model & {
				["Cube.006"]: BasePart,
				GripEntity: Attachment,
			},
			MainTower: Model & {
				["BézierCurve"]: BasePart,
				["Cube.011"]: BasePart,
				["Cube.012"]: BasePart,
				["Cylinder.002"]: BasePart,
				["Cylinder.005"]: BasePart,
				GripEntity: Attachment,
			},
			RightTower: Model & {
				["Cube.024"]: BasePart,
				GripEntity: Attachment,
			},
		},
		Units: Folder,
	},
}

return {}