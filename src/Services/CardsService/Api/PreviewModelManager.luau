--!strict
-- Behavior: unit preview on the ground following the mouse + enemy overlay (Transparency)

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TweenService = game:GetService("TweenService")
const UserInputService = game:GetService("UserInputService")
const Workspace = game:GetService("Workspace")

const CardsServiceType = require(script.Parent.Parent.CardsServiceType)
const CardsServiceUtils = require(script.Parent.Parent.CardsServiceUtils)
const Janitor = require(ReplicatedStorage.Packages.janitor)
const CardLayout = require(ReplicatedStorage.Shareds.Services.CardsService.Interface.Components.CardLayout)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const PlacementZoneUtils = require(ReplicatedStorage.Shareds.Utils.PlacementZoneUtil)

const SHOW_TRANSPARENCY = 0
const HIDE_TRANSPARENCY = 1
const RAY_DISTANCE = 500
const OVERLAY_TWEEN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

const WALK_ANIMATION_NAME = 'Walk'
const WALK_ANIMATION_TRACK = AssetsUtils.getAnimation(WALK_ANIMATION_NAME) :: Animation


const PreviewModelManager = {}

export type TeamName = PlacementZoneUtils.TeamName

export type BindRaycastHandle = {
	Cancel: () -> (),
	CanPlace: () -> boolean,
	GetPosition: () -> Vector3?,
}

export type PreviewModelManager = typeof(PreviewModelManager)

type OverlaySession = {
	Parts: { BasePart },
	Tweens: { Tween },
}

const function getDebrisFolder(): Folder
	local gameFolder = Workspace:FindFirstChild("Game")
	if not gameFolder then
		gameFolder = Instance.new("Folder")
		gameFolder.Name = "Game"
		gameFolder.Parent = Workspace
	end

	local debris = gameFolder:FindFirstChild("_Debris")
	if debris and debris:IsA("Folder") then
		return debris
	end

	local folder = Instance.new("Folder")
	folder.Name = "_Debris"
	folder.Parent = gameFolder
	return folder
end

const function getRootPart(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		model.PrimaryPart = hrp
		return hrp
	end

	local torso = model:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		model.PrimaryPart = torso
		return torso
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

const function stripPreviewCollision(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		elseif descendant:IsA("Humanoid") then
			descendant.PlatformStand = true
			descendant.EvaluateStateMachine = false
			descendant:ChangeState(Enum.HumanoidStateType.Physics)
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		end
	end
end

const function makePreviewModel(handle: CardLayout.CardHandle): Model
	local data = handle.Data
	local model = AssetsUtils.getEntityUnitModel(data.ModelID):Clone()
	model.Name = `Preview_{data.Id}`

	stripPreviewCollision(model)

	local root = getRootPart(model)
	assert(root, `[PreviewModelManager] Unit missing BasePart: {data.Id}`)

	local effects = AssetsUtils.getMiscTemplate("Card", "PreviewEffects"):Clone() :: CardsServiceType.PreviewEffects
	effects.Name = "PreviewEffects"
	effects.Parent = model

	local CardData = CardsServiceUtils._GetCardDataWithID(data.Id)

	local highlight = effects:FindFirstChildOfClass("Highlight")
	if highlight then
		highlight.Adornee = model
		highlight.Enabled = true
	end

	local billboard = effects:FindFirstChildOfClass("BillboardGui")
	if billboard and billboard:IsA("BillboardGui") then
		billboard.Adornee = root
		billboard.Parent = root
		billboard.Enabled = true

		local container = billboard:FindFirstChild("Container")
		if container then
			local nameLabel = container:FindFirstChild("EntityName")
			if nameLabel and nameLabel:IsA("TextLabel") then
				nameLabel.Text = data.Name
				local mainText = nameLabel:FindFirstChild("MainText")
				if mainText and mainText:IsA("TextLabel") then
					mainText.Text = data.Name
				end
			end

			local levelLabel = container:FindFirstChild("Level")
			if levelLabel and levelLabel:IsA("TextLabel") then
				local levelText = `Lvl: {tostring(if CardData then CardData.Level else 0)}`
				levelLabel.Text = levelText
				local mainText = levelLabel:FindFirstChild("MainText")
				if mainText and mainText:IsA("TextLabel") then
					mainText.Text = levelText
				end
			end
		end
	end

	local mainAttachment = effects:FindFirstChild("Main")
	if mainAttachment and mainAttachment:IsA("Attachment") then
		mainAttachment.Parent = root
	end

	model.Parent = getDebrisFolder()

	stripPreviewCollision(model)

	return model
end

const function getTeamsRoot(): Folder?
	local gameFolder = Workspace:FindFirstChild("Game")
	local gameplay = gameFolder and gameFolder:FindFirstChild("Gameplay")
	local teams = gameplay and gameplay:FindFirstChild("Teams")
	if teams and teams:IsA("Folder") then
		return teams
	end
	return nil
end

const function getEnemyMainTowerPosition(teamName: TeamName): Vector3?
	local enemy = PlacementZoneUtils.GetEnemyTeam(teamName)
	local teamsRoot = getTeamsRoot()
	local teamFolder = teamsRoot and teamsRoot:FindFirstChild(enemy)
	local towers = teamFolder and teamFolder:FindFirstChild("Towers")
	local mainTower = towers and towers:FindFirstChild("MainTower")
	if not mainTower then
		return nil
	end

	local grip = mainTower:FindFirstChild("GripEntity", true)
	if grip and grip:IsA("Attachment") then
		return grip.WorldPosition
	end

	if mainTower:IsA("Model") then
		return mainTower:GetPivot().Position
	end
	if mainTower:IsA("BasePart") then
		return mainTower.Position
	end

	return nil
end

const function movePreview(model: Model, worldPos: Vector3, lookTarget: Vector3?): ()
	local offsetY: number = 3
	local position: Vector3 = worldPos + Vector3.new(0, offsetY, 0)

	local eixoY: number = 180
	if lookTarget then
		local delta: Vector3 = lookTarget - worldPos
		eixoY = math.deg(math.atan2(-delta.X, -delta.Z))
	end

	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(eixoY), 0))
end

const function cancelOverlayTweens(session: OverlaySession)
	for _, tween in session.Tweens do
		tween:Cancel()
	end
	table.clear(session.Tweens)
end

const function tweenPartTransparency(session: OverlaySession, part: BasePart, target: number)
	local tween = TweenService:Create(part, OVERLAY_TWEEN_INFO, { Transparency = target })
	table.insert(session.Tweens, tween)
	tween:Play()
end

const function showEnemyOverlay(teamName: TeamName): OverlaySession
	local enemy = PlacementZoneUtils.GetEnemyTeam(teamName)
	local parts = PlacementZoneUtils.GetEnemySpawnZoneParts(enemy)
	local activeId = PlacementZoneUtils.GetEnemyBlockOverlayId(teamName)
	local session: OverlaySession = {
		Parts = parts,
		Tweens = {},
	}

	for _, part in parts do
		if part.Name == activeId then
			part.Transparency = HIDE_TRANSPARENCY
			tweenPartTransparency(session, part, SHOW_TRANSPARENCY)
		else
			part.Transparency = HIDE_TRANSPARENCY
		end
	end

	return session
end

const function hideEnemyOverlay(session: OverlaySession)
	cancelOverlayTweens(session)

	for _, part in session.Parts do
		tweenPartTransparency(session, part, HIDE_TRANSPARENCY)
	end
end

function PreviewModelManager.onBindRaycast(
	teamName: TeamName,
	payload: CardLayout.CardHandle
): BindRaycastHandle
	local session = Janitor.new()
	local overlay = showEnemyOverlay(teamName)
	local previewModel = makePreviewModel(payload)
	local enemyTowerPos = getEnemyMainTowerPosition(teamName)
	local lastCanPlace = false
	local lastPosition: Vector3? = nil
	local Track: AnimationTrack? = nil

	session:add(function()
		hideEnemyOverlay(overlay)
	end, true)

	session:add(function()
		if previewModel.Parent then
			previewModel:Destroy()
		end
	end, true)

	local params: RaycastParams = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local excludeList: { Instance } = {
		Players.LocalPlayer.Character :: Instance,
		previewModel,
	}
	local limitations: Instance? = PlacementZoneUtils.GetEntityLimitations()
	if limitations then
		table.insert(excludeList, limitations)
	end
	local gameFolder: Instance? = Workspace:FindFirstChild("Game")
	local entitysFolder: Instance? = gameFolder and gameFolder:FindFirstChild("_Entitys")
	if entitysFolder then
		table.insert(excludeList, entitysFolder)
	end
	params.FilterDescendantsInstances = excludeList

	session:add(RunService.Heartbeat:Connect(function(_deltaTime: number): ()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		local mouse: Vector2 = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
		local result: RaycastResult<BasePart>? = Workspace:Raycast(ray.Origin, ray.Direction * RAY_DISTANCE, params)
		if not result then
			lastCanPlace = false
			lastPosition = nil
			return
		end

		lastPosition = result.Position
		movePreview(previewModel, result.Position, enemyTowerPos)

		if not Track then
			const animator = AnimationUtil.PrepareModel(previewModel)
			stripPreviewCollision(previewModel)
			if animator then
				Track = animator:LoadAnimation(WALK_ANIMATION_TRACK)
				if Track then
					Track:Play(0.1)
				end
			end
		end

		local canPlace: boolean = PlacementZoneUtils.CanPlace(teamName, result.Position, "Unit")
		lastCanPlace = canPlace
		previewModel:SetAttribute("CanPlace", canPlace)

		local highlight: Highlight? = previewModel:FindFirstChildWhichIsA("Highlight", true)
		if highlight then
			highlight.FillColor = if canPlace
				then Color3.fromRGB(255, 255, 255)
				else Color3.fromRGB(220, 70, 70)
		end
	end), "Disconnect")

	return {
		Cancel = function(): ()
			session:destroy()
			if Track then
				Track:Stop()
				Track:Destroy()
			end
		end,
		CanPlace = function(): boolean
			return lastCanPlace
		end,
		GetPosition = function(): Vector3?
			return lastPosition
		end,
	}
end

return PreviewModelManager
