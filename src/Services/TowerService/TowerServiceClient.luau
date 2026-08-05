--!strict
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TweenService = game:GetService("TweenService")
const Workspace = game:GetService("Workspace")
const janitor = require(ReplicatedStorage.Packages.janitor)
const NetClient = require(ReplicatedStorage.Shareds.Networker.NetClient)
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const AnimationUtil = require(ReplicatedStorage.Shareds.Utils.AnimationUtil)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const CardsEntityManager = require(ReplicatedStorage.Shareds.Services.CardsService.Api.CardsEntityManager)

const PATH_BILLBOARD_TOWER = "TowerBillboard"
const TEAM_KEYS = { "One", "Two" }
const TOWER_RIG_TIMEOUT = 10
const BOARD_HEIGHT_PADDING = 2

const TowerServiceClient = {
	section = nil :: typeof(janitor.new())?,
	localplayer = nil :: Player?,
}

export type UpdateBillboardPropetiesType = {
	Level: number,
}

const function getTeamsRoot(): Folder?
	const gameFolder = Workspace:FindFirstChild("Game")
	const gameplay = gameFolder and gameFolder:FindFirstChild("Gameplay")
	const teams = gameplay and gameplay:FindFirstChild("Teams")
	if teams and teams:IsA("Folder") then
		return teams
	end
	return nil
end

const function getBoardAdornee(anchor: Model): BasePart?
	if anchor.PrimaryPart then
		return anchor.PrimaryPart
	end
	return anchor:FindFirstChildWhichIsA("BasePart", true)
end

-- Keeps the board above the whole build, whichever part it adorns
const function getBoardHeightOffset(anchor: Model, adornee: BasePart): number
	const boundsCF, size = anchor:GetBoundingBox()
	const topY = boundsCF.Position.Y + size.Y * 0.5
	return (topY - adornee.Position.Y) + BOARD_HEIGHT_PADDING
end

function TowerServiceClient.updateTowerBillboard(
	_self: TowerServiceClient,
	towerModel: Model,
	props: UpdateBillboardPropetiesType
)
	const humanoid = towerModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Health comes from the spawned entity, but the board belongs on the tower build
	const anchor = EntityHelper.GetTowerAnchorForSpawned(towerModel)
	const adornee = anchor and getBoardAdornee(anchor)
	if not anchor or not adornee then
		warn(`[TowerServiceClient] Tower anchor missing for: {towerModel.Name}`)
		return
	end

	const boardKey = `{towerModel.Name}_Billboard`
	const existingBoard = adornee:FindFirstChild(PATH_BILLBOARD_TOWER)
	const board: BillboardGui = if existingBoard and existingBoard:IsA("BillboardGui")
		then existingBoard
		else AssetsUtils.getTowerBillboard():Clone()

	board.Name = PATH_BILLBOARD_TOWER
	board.Adornee = adornee
	board.StudsOffsetWorldSpace = Vector3.new(0, getBoardHeightOffset(anchor, adornee), 0)
	board.Parent = adornee

	const healthDisplay = board:FindFirstChild("HealthDisplay", true)
	if not healthDisplay then
		return
	end

	const healthInfo = healthDisplay:FindFirstChild("HealthInfoContainer", true)
	const healthLabel = healthInfo and healthInfo:FindFirstChild("TowerHealth", true) :: TextLabel?
	const levelLabel = healthDisplay:FindFirstChild("TowerLevelValue", true) :: TextLabel?
	const healthBar = healthDisplay:FindFirstChild("HealthBar", true)
	const bar = healthBar and healthBar:FindFirstChild("Bar", true) :: Frame?

	const function syncHealth()
		if healthLabel then
			healthLabel.Text = tostring(math.floor(humanoid.Health + 0.5))
		end

		if bar then
			const ratio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 0
			TweenService:Create(bar, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
				Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
			}):Play()
		end
	end

	if levelLabel then
		levelLabel.Text = tostring(props.Level)
	end

	syncHealth()

	const uidAttr = towerModel:GetAttribute("UID")
	const uid = if type(uidAttr) == "string" then uidAttr else towerModel.Name

	const section = _self.section
	if section then
		section:add(humanoid:GetPropertyChangedSignal("Health"):Connect(syncHealth), "Disconnect", boardKey)
		section:add(humanoid.Died:Connect(function()
			CardsEntityManager:_PlayEntityDeathPresentationClient(towerModel, uid)

			if board.Parent then
				board.Enabled = false
			end
		end), "Disconnect", `{boardKey}_Died`)
		section:add(towerModel.Destroying:Connect(function()
			-- Board lives on the anchor, so it must go when the entity does
			board:Destroy()

			-- This Janitor build only exposes PascalCase Remove (:remove is nil)
			const boardSection = section :: any

			boardSection:Remove(boardKey)
			boardSection:Remove(`{boardKey}_Died`)
			boardSection:Remove(`{boardKey}_Destroy`)
		end), "Disconnect", `{boardKey}_Destroy`)
	end
end

-- Rig/attributes may replicate after the Model, so wait instead of skipping the board
function TowerServiceClient.bindTowerVisuals(self: TowerServiceClient, towerModel: Model)
	task.spawn(function()
		const hrp = towerModel:WaitForChild("HumanoidRootPart", TOWER_RIG_TIMEOUT)
		const humanoid = towerModel:WaitForChild("Humanoid", TOWER_RIG_TIMEOUT)
		if not hrp or not humanoid or not towerModel.Parent then
			warn(`[TowerServiceClient] Tower rig incomplete: {towerModel.Name}`)
			return
		end

		if towerModel:GetAttribute("Kind") ~= "Tower" then
			return
		end

		const levelAttr = towerModel:GetAttribute("Level")
		const level = if type(levelAttr) == "number" then levelAttr else 1

		self:updateTowerBillboard(towerModel, {
			Level = level,
		})

		AnimationUtil.PrepareModel(towerModel)
	end)
end

function TowerServiceClient.ResolveTowerEntitys(self: TowerServiceClient)
	const teamsRoot = getTeamsRoot()
	if not teamsRoot then
		return
	end

	for _, teamKey in TEAM_KEYS do
		const teamFolder = teamsRoot:FindFirstChild(teamKey)
		const unitsCache = teamFolder and teamFolder:FindFirstChild("Units")
		if not unitsCache then
			continue
		end

		for _, child in unitsCache:GetChildren() do
			if child:IsA("Model") then
				self:bindTowerVisuals(child)
			end
		end

		-- Towers replicated after this pass still get their board
		const section = self.section
		if section then
			section:add(unitsCache.ChildAdded:Connect(function(child: Instance)
				if child:IsA("Model") then
					self:bindTowerVisuals(child)
				end
			end), "Disconnect", `{teamKey}_TowerWatch`)
		end
	end
end

function TowerServiceClient.Init(self: TowerServiceClient): TowerServiceClient
	const section = janitor.new()
	self.section = section
	self.localplayer = Players.LocalPlayer

	section:add(function()
		section:cleanup()
	end)

	NetClient.Game.ResolveTowerEntitys.SetCallback(function()
		self:ResolveTowerEntitys()
	end)

	return self
end

export type TowerServiceClient = typeof(TowerServiceClient)
return TowerServiceClient
