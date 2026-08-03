--!strict
-- Behavior: spawn fall cutscene for card entities

const Debris = game:GetService("Debris")
const HttpService = game:GetService("HttpService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TweenService = game:GetService("TweenService")
const Workspace = game:GetService("Workspace")

const Janitor = require(ReplicatedStorage.Packages.janitor)
const signal = require(ReplicatedStorage.Packages.signal)
const CardsServiceType = require(script.Parent.Parent.CardsServiceType)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const MathUtils = require(ReplicatedStorage.Shareds.Utils.MathUtils)
const VFXUtil = require(ReplicatedStorage.Shareds.Utils.VFXUtil)

const CardServiceCutscenes = {}

const _janitor = Janitor.new()

const SPAWN_TWEEN_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
const GOAL_POSITION_JANITOR_TAG = "GoalPositionJanitor"

const FALLING_ANIMATION_NAME = "Falling"
const FALING_ANIMATION = AssetsUtils.getAnimation(FALLING_ANIMATION_NAME) :: Animation

const IDLE_ANIMATION_NAME = "Idle"
const IDLE_ANIMATION = AssetsUtils.getAnimation(IDLE_ANIMATION_NAME) :: Animation

const DebrisFolder = Workspace:FindFirstChild('Game'):FindFirstChild('_Debris')

const function GetClockModel()
	const Model = AssetsUtils.getGameplayModel('General', 'Clock'):Clone() :: CardsServiceType.Clock
	Model.Parent = DebrisFolder

	for _, p in Model:GetChildren() do
		if not p:IsA('BasePart') then continue end
		p.CanCollide = false
		p.CanTouch = false
	end

	Model.Name = ("Clock_%s"):format(HttpService:GenerateGUID(false))
	return Model
end

const function PivotClockTowardCamera(Clock: CardsServiceType.Clock, pivotPosition: Vector3)
	const Camera = Workspace.CurrentCamera
	if not Camera then
		return
	end

	const lookOffset = Clock:GetPivot():ToObjectSpace(Clock.Look.CFrame)
	const basePivot = CFrame.new(pivotPosition)
	const lookPos = (basePivot * lookOffset).Position
	const targetLook = CFrame.lookAt(lookPos, Camera.CFrame.Position)

	Clock:PivotTo(targetLook * lookOffset:Inverse())
end

const CLOCK_ORBIT_RADIUS = 3
const CLOCK_ORBIT_HEIGHT = 0

const function GetClockOrbitPosition(HumanoidRootPart: BasePart): Vector3
	const Camera = Workspace.CurrentCamera
	local flatToCamera = Vector3.new(HumanoidRootPart.CFrame.LookVector.X, 0, HumanoidRootPart.CFrame.LookVector.Z)

	if Camera then
		local toCamera = Camera.CFrame.Position - HumanoidRootPart.Position
		flatToCamera = Vector3.new(toCamera.X, 0, toCamera.Z)
	end

	if flatToCamera.Magnitude < 1e-4 then
		flatToCamera = Vector3.new(0, 0, -1)
	else
		flatToCamera = flatToCamera.Unit
	end

	return HumanoidRootPart.Position + flatToCamera * CLOCK_ORBIT_RADIUS + Vector3.new(0, CLOCK_ORBIT_HEIGHT, 0)
end

-- Distance from model pivot to its bottom (feet → floor).
function CardServiceCutscenes.GetEntityFloorOffset(self:CardServiceCutscenes, Entity: Model): number
	local boundsCF, size = Entity:GetBoundingBox()
	local pivotY = Entity:GetPivot().Position.Y
	const bottomY = boundsCF.Position.Y - size.Y * 0.5
	return math.max(0, pivotY - bottomY)
end

function CardServiceCutscenes.ClockTimeEffect(Entity: Model, deployTime: number): CardsServiceType.SpawnEntityCallback
	const __call: CardsServiceType.SpawnEntityCallback = {
		Completed = signal.new(),
	}

	const HumanoidRootPart = Entity:FindFirstChild('HumanoidRootPart') :: BasePart
	const StarterClockPosition = HumanoidRootPart.CFrame * CFrame.new(math.random(-2, 2), math.random(7, 8), math.random(-2, 2))
	const Clock = GetClockModel()
	
	const GoalScale = 0.004
	const InitialScale = GoalScale/1000

	Clock:ScaleTo(InitialScale)

	const Number = Instance.new('NumberValue')
	Number.Value = InitialScale

	const conn = Number:GetPropertyChangedSignal('Value'):Connect(function()
		Clock:ScaleTo(Number.Value)
	end)
	_janitor:add(conn, 'Disconnect')

	const showTween = TweenService:Create(Number, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), { Value = GoalScale})
	local hoverConn: RBXScriptConnection?

	const function HoverEffect()
		local hoverElapsed = 0

		hoverConn = RunService.RenderStepped:Connect(function(delta: number)
			hoverElapsed += delta
			const anchor = GetClockOrbitPosition(HumanoidRootPart)
			const hoverPos = MathUtils.spaceshipHover(hoverElapsed, anchor, anchor).Position
			PivotClockTowardCamera(Clock, hoverPos)
		end)

		_janitor:add(hoverConn, 'Disconnect')
	end

	const function AddCowdownEffect()
		--< Values >--
		const GOAL_SIZE = UDim2.fromScale(0.6, 0.6)
		const INIT_SIZE = UDim2.fromScale(0, 0)
		const RISE_HEIGHT = 5
		const EXIT_DURATION = 0.45
		--

		const Textlabel = Clock.Look.Cowdown.Container.TextLabel
		Textlabel.Text = string.format("%.2f", deployTime) .. 's'
		Textlabel.Size = INIT_SIZE

		const enabledText = TweenService:Create(Textlabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0.1), {Size = GOAL_SIZE})
		enabledText:Play()

		local remaining = deployTime
		local countdownConn: RBXScriptConnection
		local finished = false

		const function FinishDeploy()
			if finished then
				return
			end
			finished = true

			countdownConn:Disconnect()

			if hoverConn then
				hoverConn:Disconnect()
			end

			Textlabel.Text = '0s'

			const closeFrame = TweenService:Create(Textlabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.1), { Size = INIT_SIZE })
			closeFrame:Play()

			const startPivot = Clock:GetPivot()
			const riseProxy = Instance.new('CFrameValue')
			riseProxy.Value = startPivot

			local riseConn = riseProxy.Changed:Connect(function(value: CFrame)
				Clock:PivotTo(value)
			end)

			const scaleProxy = Instance.new('NumberValue')
			scaleProxy.Value = GoalScale

			local scaleConn = scaleProxy:GetPropertyChangedSignal('Value'):Connect(function()
				Clock:ScaleTo(scaleProxy.Value)
			end)

			const riseTween = TweenService:Create(
				riseProxy,
				TweenInfo.new(EXIT_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,  0, false, 0.15),
				{ Value = startPivot * CFrame.new(0, RISE_HEIGHT, 0) }
			)
			const scaleTween = TweenService:Create(
				scaleProxy,
				TweenInfo.new(EXIT_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In,  0, false, 0.15),
				{ Value = InitialScale}
			)

			riseTween:Play()
			scaleTween:Play()

			scaleTween.Completed:Connect(function()
				riseConn:Disconnect()
				scaleConn:Disconnect()
				riseProxy:Destroy()
				scaleProxy:Destroy()
				Debris:AddItem(Clock, 0)
				__call.Completed:Fire()
			end)
		end

		const enabledConnection = enabledText.Completed:Connect(function()
			countdownConn = RunService.PreRender:Connect(function(deltaTime: number)
				remaining -= deltaTime

				if remaining > 0 then
					Textlabel.Text = string.format("%.2f", remaining) .. 's'
					return
				end

				FinishDeploy()
			end)

			_janitor:add(countdownConn, 'Disconnect')
		end)

		_janitor:add(enabledConnection, 'Disconnect')
	end


	const function BezierEffect()
		local bezierConn : RBXScriptConnection

		local elapsed = 0
		local duration = 0.6

		const function ManageElapsed(time: number)
			if time >= 1 then
				bezierConn:Disconnect()
				HoverEffect()
				AddCowdownEffect()
			end
		end

		bezierConn = RunService.RenderStepped:Connect(function(delta: number)
			elapsed += delta

			local t = math.clamp(elapsed / duration, 0, 1)
			local finish = GetClockOrbitPosition(HumanoidRootPart)
			local pos = MathUtils.cubicBezier(t, StarterClockPosition.Position, finish)
			PivotClockTowardCamera(Clock, pos)

			ManageElapsed(t)
		end)
		
		_janitor:add(bezierConn, 'Disconnect')
	end

	showTween.Completed:Connect(function(a0: Enum.PlaybackState)
		conn:Disconnect()
		Debris:AddItem(Number, 0.1)
		Clock:ScaleTo(GoalScale)

		BezierEffect()
	end)

	PivotClockTowardCamera(Clock, StarterClockPosition.Position)
	showTween:Play()
	
	return __call
end

function CardServiceCutscenes.EmitSpawnEffect(
	self: CardServiceCutscenes,
	Entity: Model
)
	local effect = VFXUtil.EmitAll(AssetsUtils.getGameplayEntityEffect('ImpactSpawn'), Entity)
	local hrp = Entity:FindFirstChild('HumanoidRootPart') :: BasePart
	if effect.Instance:IsA('Attachment') then
		effect.Instance.CFrame = CFrame.new(0, -self:GetEntityFloorOffset(Entity), 0)
	end
end

function CardServiceCutscenes.SpawnEntityInPosition(
	self: CardServiceCutscenes,
	Entity: Model,
	Pos: CFrame,
	deployTime: number
): CardsServiceType.SpawnEntityCallback
	const __call: CardsServiceType.SpawnEntityCallback = {
		Completed = signal.new(),
	}

	const Animator = AnimationUtil.PrepareModel(Entity)
	const FalingTrack = Animator:LoadAnimation(FALING_ANIMATION)
	const IdleTrack = Animator:LoadAnimation(IDLE_ANIMATION)

	FalingTrack.Looped = true
	FalingTrack.Priority = Enum.AnimationPriority.Action

	IdleTrack.Looped = true
	IdleTrack.Priority = Enum.AnimationPriority.Idle

	assert(Entity:IsA("Model"), "SpawnEntityInPosition expects a Model")

	const Offset = CardServiceCutscenes:GetEntityFloorOffset(Entity)
	const goalCFrame = Pos * CFrame.new(0, Offset, 0)
	const startCFrame = goalCFrame * CFrame.new(0, Offset, 0)

	Entity:PivotTo(startCFrame)

	const proxy = Instance.new("CFrameValue")
	proxy.Value = startCFrame

	local connection = proxy.Changed:Connect(function(value: CFrame)
		Entity:PivotTo(value)
	end)

	const tween = TweenService:Create(proxy, SPAWN_TWEEN_INFO, { Value = goalCFrame })
	_janitor:add(tween.Completed:Connect(function()
		connection:Disconnect()

		proxy:Destroy()

		Entity:PivotTo(goalCFrame)

		_janitor:removeNoClean(GOAL_POSITION_JANITOR_TAG)

		FalingTrack:Stop(0.1); FalingTrack:Destroy()
		self:EmitSpawnEffect(Entity)

		IdleTrack:Play(0.2)


		local events = self.ClockTimeEffect(Entity, deployTime)

		events.Completed:Connect(function(...)
			IdleTrack:Stop(0.1)
			IdleTrack:Destroy()
			__call.Completed:Fire()
		end)
	end), "Disconnect", GOAL_POSITION_JANITOR_TAG)


	const function StarterCutscene()
		FalingTrack:Play()
		while not FalingTrack.IsPlaying do
			task.wait()
		end

		tween:Play()
	end


	StarterCutscene()
	--[__call.Completed:Fire()]
	return __call
end

export type CardServiceCutscenes = typeof(CardServiceCutscenes)
return CardServiceCutscenes
