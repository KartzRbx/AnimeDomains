--!strict
-- Behavior: 4 active hand slots + NextCard; drag place; refill from SyncCardHand

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TweenService = game:GetService("TweenService")
const UserInputService = game:GetService("UserInputService")
const GuiService = game:GetService("GuiService")

const CardsEntityManager = require(script.Parent.Parent.Api.CardsEntityManager)
const PreviewModelManager = require(script.Parent.Parent.Api.PreviewModelManager)
const UnitsMetaData = require(ReplicatedStorage.Shareds.Classes.Tree.Build.MetaData.UnitsMetaData)
const GameplayTypes = require(ReplicatedStorage.Shareds.Services.GameplayService.GameplayTypes)
const CardLayout = require(script.Parent.Components.CardLayout)
const PlacementZoneUtils = require(ReplicatedStorage.Shareds.Utils.PlacementZoneUtil)
const PlayerUtils = require(ReplicatedStorage.Shareds.Utils.PlayerUtils)
const UIModule = require(ReplicatedStorage.Shareds.Modules.UIModule)
const Debi = require(ReplicatedStorage.Shareds.Networker.NetClient).Game
const CardsServiceType = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceType)
const CardsServiceUtils = require(ReplicatedStorage.Shareds.Services.CardsService.CardsServiceUtils)
const Janitor = require(ReplicatedStorage.Packages.janitor)

const MAX_SLOTS = CardsServiceUtils.HAND_SIZE


local SLOT_POSITIONS: { UDim2 } = {
	UDim2.fromScale(0.125, 0.365),
	UDim2.fromScale(0.375, 0.365),
	UDim2.fromScale(0.625, 0.365),
	UDim2.fromScale(0.874, 0.365),
}

local NEXT_CARD_POSITION = UDim2.fromScale(-0.12, 0.62)
local NEXT_CARD_SCALE = 0.72

type CardHandState = {
	Hand: { string },
	NextCard: string,
}

-- Limit: Y priority (lifting the card). In CardsContainer scale.
local Y_LIFT_LIMIT = 0.5
local X_WEIGHT = 0.35
local BASE_CARD_SCALE = 1
local MIN_DRAG_SCALE = 0.04 -- nearly vanishes at top of lift

local ENTRANCE_Y_OFFSET = 0.35
local ENTRANCE_STAGGER = 0.14
local ENTRANCE_INFO = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local RETURN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local previewBind: PreviewModelManager.BindRaycastHandle? = nil

local CardServiceClient = {
	Initialized = false,
	MainGui = nil :: ScreenGui?,
	CardsContainer = nil :: Frame?,
	DeckJanitor = nil :: any,
	ActiveCards = {} :: { [number]: CardLayout.CardHandle },
	NextCardHandle = nil :: CardLayout.CardHandle?,
	LastHandKey = "",
	EntranceToken = 0,
	LocalTeam = "One" :: PlacementZoneUtils.TeamName,
}

export type CardServiceClient = typeof(CardServiceClient)

local function buildHandKey(hand: { string }, nextCard: string): string
	return `{table.concat(hand, "|")}>>{nextCard}`
end

local function udim2ToVector2(position: UDim2, parentSize: Vector2): Vector2
	return Vector2.new(
		position.X.Scale * parentSize.X + position.X.Offset,
		position.Y.Scale * parentSize.Y + position.Y.Offset
	)
end

local function getLiftScore(slotPos: UDim2, cardPos: UDim2, parentSize: Vector2): (number, number, number)
	local slot = udim2ToVector2(slotPos, parentSize)
	local card = udim2ToVector2(cardPos, parentSize)

	local dx = math.abs(card.X - slot.X) / math.max(parentSize.X, 1)
	local dyUp = math.max(0, (slot.Y - card.Y) / math.max(parentSize.Y, 1))
	local score = dyUp + dx * X_WEIGHT
	return score, dyUp, dx
end

local function pointerToParentScale(parent: GuiObject, screenPos: Vector2?): Vector2
	local mouse = screenPos or (UserInputService:GetMouseLocation() - GuiService:GetGuiInset())
	local absPos = parent.AbsolutePosition
	local absSize = parent.AbsoluteSize
	if absSize.X <= 0 or absSize.Y <= 0 then
		return Vector2.new(0.5, 0.5)
	end

	return Vector2.new((mouse.X - absPos.X) / absSize.X, (mouse.Y - absPos.Y) / absSize.Y)
end

function CardServiceClient.ResolveHud(self: CardServiceClient): Frame
	if self.CardsContainer and self.CardsContainer.Parent then
		return self.CardsContainer
	end

	local main = PlayerUtils.waitMain()
	local cardsContainer = PlayerUtils.wait("Main/Container/Gameplay/CardsContainer")
	assert(cardsContainer:IsA("Frame"), "[CardsServiceClient] CardsContainer must be a Frame")

	for _, child in cardsContainer:GetChildren() do
		if child:IsA("GuiObject") and string.sub(child.Name, 1, 12) == "TemplateCard" then
			child:Destroy()
		end
	end

	local list = cardsContainer:FindFirstChildOfClass("UIListLayout")
	if list then
		list:Destroy()
	end

	self.MainGui = main
	self.CardsContainer = cardsContainer
	return cardsContainer
end

function CardServiceClient.ClearDeck(self: CardServiceClient)
	self.EntranceToken += 1

	if self.DeckJanitor then
		self.DeckJanitor:destroy()
	end
	self.DeckJanitor = Janitor.new()

	for slotIndex, handle in self.ActiveCards do
		handle.Destroy()
		self.ActiveCards[slotIndex] = nil
	end
	table.clear(self.ActiveCards)

	if self.NextCardHandle then
		self.NextCardHandle.Destroy()
		self.NextCardHandle = nil
	end
end

local function playEntrance(template: GuiObject, targetPos: UDim2, janitor: any)
	local card = template:FindFirstChild("Card")
	local scale = if card then card:FindFirstChildOfClass("UIScale") else nil

	template.AnchorPoint = Vector2.new(0.5, 0.5)
	template.Position = UDim2.fromScale(targetPos.X.Scale, targetPos.Y.Scale + ENTRANCE_Y_OFFSET)
	template.Visible = true

	if scale and scale:IsA("UIScale") then
		scale.Scale = 0.55
		local scaleTween = TweenService:Create(scale, ENTRANCE_INFO, { Scale = 1 })
		janitor:add(scaleTween, "Cancel")
		scaleTween:Play()
	end

	local posTween = TweenService:Create(template, ENTRANCE_INFO, { Position = targetPos })
	janitor:add(posTween, "Cancel")
	posTween:Play()
end

local function getCardScale(cardButton: GuiObject): UIScale?
	local named = cardButton:FindFirstChild("InterfaceScale")
	if named and named:IsA("UIScale") then
		return named
	end
	return cardButton:FindFirstChildOfClass("UIScale")
end

local function returnToSlot(template: GuiObject, cardButton: GuiObject, slotPos: UDim2, janitor: any)
	template.Visible = true
	local scale = getCardScale(cardButton)
	if scale then
		local scaleTween = TweenService:Create(scale, RETURN_INFO, { Scale = BASE_CARD_SCALE })
		janitor:add(scaleTween, "Cancel")
		scaleTween:Play()
	end

	local tween = TweenService:Create(template, RETURN_INFO, { Position = slotPos })
	janitor:add(tween, "Cancel")
	tween:Play()
end

function CardServiceClient.ManagerInsertCardHandle(
	self: CardServiceClient,
	handle: CardLayout.CardHandle,
	slotPosition: UDim2,
	slotIndex: number
)
	local cardJanitor = handle.CardJanitor
	local template = handle.Template
	local cardButton = template.Card
	local parent = template.Parent :: GuiObject
	local uiScale = getCardScale(cardButton)

	local dragging = false
	local pastLimit = false
	local committed = false
	local dragConn: RBXScriptConnection? = nil
	local grabOffset = Vector2.zero

	local function stopDragListen()
		if dragConn then
			dragConn:Disconnect()
			dragConn = nil
		end
	end

	local function applyLiftVisual(dyUp: number)
		local alpha = math.clamp(dyUp / Y_LIFT_LIMIT, 0, 1)
		local scaleValue = BASE_CARD_SCALE + (MIN_DRAG_SCALE - BASE_CARD_SCALE) * alpha

		if uiScale then
			uiScale.Scale = scaleValue
		end

		template.Visible = alpha < 1
	end

	local function onDragMove(screenPos: Vector2?)
		if not dragging or committed or not parent then
			return
		end

		local pointer = pointerToParentScale(parent, screenPos)
		template.Position = UDim2.fromScale(pointer.X + grabOffset.X, pointer.Y + grabOffset.Y)

		local parentSize = parent.AbsoluteSize
		local score, dyUp, dx = getLiftScore(slotPosition, template.Position, parentSize)

		applyLiftVisual(dyUp)

		if dyUp >= Y_LIFT_LIMIT then
			if not pastLimit then
				pastLimit = true
				--print(`[CardsServiceClient] Card vanished at limit | slot={slotIndex} card={handle.Data.Id} dyUp={string.format("%.3f", dyUp)} dx={string.format("%.3f", dx)} score={string.format("%.3f", score)}`)

				previewBind = PreviewModelManager.onBindRaycast(self.LocalTeam, handle)
			end
		elseif pastLimit then
			pastLimit = false
			--[[
				print(
								`[CardsServiceClient] Card returned to its zone | slot={slotIndex} card={handle.Data.Id}`
							)
			]]
			if previewBind then
				previewBind.Cancel()
				previewBind = nil
			end
		end
	end

	local function beginDrag(input: InputObject?)
		if committed or dragging then
			return
		end

		dragging = true
		pastLimit = false
		template.ZIndex = 50
		template.Visible = true
		cardButton:SetAttribute("Dragging", true)
		UIModule:CancelButtonScale(cardButton)
		if uiScale then
			uiScale.Scale = BASE_CARD_SCALE
		end

		local screenPos = if input
			then Vector2.new(input.Position.X, input.Position.Y) - GuiService:GetGuiInset()
			else nil
		local pointer = pointerToParentScale(parent, screenPos)
		local cardPos = Vector2.new(template.Position.X.Scale, template.Position.Y.Scale)
		grabOffset = cardPos - pointer

		stopDragListen()
		dragConn = UserInputService.InputChanged:Connect(function(changed: InputObject)
			if
				changed.UserInputType == Enum.UserInputType.MouseMovement
				or changed.UserInputType == Enum.UserInputType.Touch
			then
				onDragMove(Vector2.new(changed.Position.X, changed.Position.Y) - GuiService:GetGuiInset())
			end
		end)
	end

	cardJanitor:add(function()
		stopDragListen()
	end, true)

	local function endDrag()
		if not dragging then
			return
		end

		dragging = false
		stopDragListen()
		cardButton:SetAttribute("Dragging", false)

		local parentSize = if parent then parent.AbsoluteSize else Vector2.one
		local _, dyUp = getLiftScore(slotPosition, template.Position, parentSize)

		local canPlace = false
		local placePos: Vector3? = nil
		if dyUp >= Y_LIFT_LIMIT and previewBind then
			canPlace = previewBind.CanPlace()
			placePos = previewBind.GetPosition()
		end

		if previewBind then
			previewBind.Cancel()
			previewBind = nil
		end

		if dyUp >= Y_LIFT_LIMIT and canPlace and placePos then
			committed = true
			template.Visible = false
			if uiScale then
				uiScale.Scale = MIN_DRAG_SCALE
			end

			local payload: CardsServiceType.PlaceUnitRequest = {
				CardId = handle.Data.Id,
				SlotIndex = slotIndex,
				Position = {
					X = placePos.X,
					Y = placePos.Y,
					Z = placePos.Z,
				},
			}
			Debi.PutCardInPlace.Fire(payload)
			--print(`[CardsServiceClient] Card confirmed at limit | slot={slotIndex} card={handle.Data.Id}`)
			return
		end

		template.ZIndex = 1
		if uiScale then
			uiScale.Scale = BASE_CARD_SCALE
		end
		returnToSlot(template, cardButton, slotPosition, cardJanitor)
	end

	cardJanitor:add(cardButton.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			beginDrag(input)
		end
	end), "Disconnect")

	cardJanitor:add(UserInputService.InputEnded:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			endDrag()
		end
	end), "Disconnect")
end

local function spawnSlotCard(
	self: CardServiceClient,
	cardId: string,
	slotIndex: number,
	animate: boolean
): CardLayout.CardHandle?
	local cardData = UnitsMetaData.GetCardParams(cardId)
	if not cardData then
		warn(`[CardsServiceClient] Card data missing: {cardId}`)
		return nil
	end

	local cardsContainer = self:ResolveHud()
	local targetPos = SLOT_POSITIONS[slotIndex]
	local handle = CardLayout.Make(cardData, false)
	local template = handle.Template
	template.Name = `Card_Slot{slotIndex}_{cardId}`
	template.ZIndex = 1
	template.Parent = cardsContainer

	self.ActiveCards[slotIndex] = handle

	if animate then
		playEntrance(template, targetPos, self.DeckJanitor)
	else
		template.AnchorPoint = Vector2.new(0.5, 0.5)
		template.Position = targetPos
		template.Visible = true
	end

	self:ManagerInsertCardHandle(handle, targetPos, slotIndex)

	return handle
end

function CardServiceClient.RenderNextCard(self: CardServiceClient, cardId: string, animate: boolean)
	if self.NextCardHandle then
		self.NextCardHandle.Destroy()
		self.NextCardHandle = nil
	end

	local cardData = UnitsMetaData.GetCardParams(cardId)
	if not cardData then
		warn(`[CardsServiceClient] NextCard data missing: {cardId}`)
		return
	end

	local cardsContainer = self:ResolveHud()
	local handle = CardLayout.Make(cardData, false)
	local template = handle.Template
	template.Name = `NextCard_{cardId}`
	template.ZIndex = 0
	template.Parent = cardsContainer

	local cardButton = template.Card
	cardButton.Active = false
	cardButton.Interactable = false

	local uiScale = getCardScale(cardButton)
	if uiScale then
		uiScale.Scale = NEXT_CARD_SCALE
	end

	if animate then
		playEntrance(template, NEXT_CARD_POSITION, self.DeckJanitor)
		if uiScale then
			local scaleTween = TweenService:Create(uiScale, ENTRANCE_INFO, { Scale = NEXT_CARD_SCALE })
			self.DeckJanitor:add(scaleTween, "Cancel")
			scaleTween:Play()
		end
	else
		template.AnchorPoint = Vector2.new(0.5, 0.5)
		template.Position = NEXT_CARD_POSITION
		template.Visible = true
	end

	self.NextCardHandle = handle
end

function CardServiceClient.ReplaceSlot(
	self: CardServiceClient,
	slotIndex: number,
	cardId: string
)
	local old = self.ActiveCards[slotIndex]
	if old then
		old.Destroy()
		self.ActiveCards[slotIndex] = nil
	end

	spawnSlotCard(self, cardId, slotIndex, true)
end

function CardServiceClient.RenderHandState(self: CardServiceClient, state: CardHandState)
	local key = buildHandKey(state.Hand, state.NextCard)
	local hadCards = next(self.ActiveCards) ~= nil

	local hasPendingCommit = false
	for _, handle in self.ActiveCards do
		if handle.Template.Visible == false then
			hasPendingCommit = true
			break
		end
	end

	if key == self.LastHandKey and hadCards and self.NextCardHandle and not hasPendingCommit then
		return
	end

	UnitsMetaData.EnsureLoaded()
	self:ResolveHud()

	if hadCards and self.LastHandKey ~= "" then
		for slotIndex = 1, MAX_SLOTS do
			local cardId = state.Hand[slotIndex]
			local existing = self.ActiveCards[slotIndex]
			if not cardId then
				continue
			end

			if not existing or existing.Data.Id ~= cardId or existing.Template.Visible == false then
				self:ReplaceSlot(slotIndex, cardId)
			end
		end

		if not self.NextCardHandle or self.NextCardHandle.Data.Id ~= state.NextCard then
			self:RenderNextCard(state.NextCard, true)
		end

		self.LastHandKey = key
		return
	end

	-- First full deal
	self.LastHandKey = key
	self:ClearDeck()

	local token = self.EntranceToken
	local slotCount = math.min(#state.Hand, MAX_SLOTS)

	task.spawn(function()
		for slotIndex = 1, slotCount do
			if token ~= self.EntranceToken then
				return
			end

			local cardId = state.Hand[slotIndex]
			spawnSlotCard(self, cardId, slotIndex, true)
			task.wait(ENTRANCE_STAGGER)
		end

		if token ~= self.EntranceToken then
			return
		end

		self:RenderNextCard(state.NextCard, true)
	end)
end

function CardServiceClient.OnSyncCardHand(self: CardServiceClient, state: CardHandState)
	self:RenderHandState(state)
end

function CardServiceClient.OnEntityState(self: CardServiceClient, state: GameplayTypes.EntityState)
	local localName = Players.LocalPlayer.Name
	local teamName: PlacementZoneUtils.TeamName? = nil

	if state.One.Owner == localName then
		teamName = "One"
	elseif state.Two.Owner == localName then
		teamName = "Two"
	end

	if not teamName then
		return
	end

	self.LocalTeam = teamName
end

function CardServiceClient.Init(self: CardServiceClient): CardServiceClient
	if self.Initialized then
		return self
	end

	self.Initialized = true
	self.ActiveCards = {}
	self.NextCardHandle = nil
	self.DeckJanitor = Janitor.new()
	self.EntranceToken = 0
	self.LastHandKey = ""

	UnitsMetaData.EnsureLoaded()

	Debi.SyncCardHand.SetCallback(function(state)
		self:OnSyncCardHand(state)
	end)

	Debi.SpawnEntityInMapFromServer.SetCallback(function(payload)
		CardsEntityManager:updateEntity(payload)
	end)

	task.spawn(function()
		self:ResolveHud()
	end)

	return self
end

return CardServiceClient
