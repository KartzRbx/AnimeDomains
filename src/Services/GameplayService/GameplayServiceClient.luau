--!strict

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const CardsServiceInterface = require(ReplicatedStorage.Shareds.Services.CardsService.Interface.CardsServiceInterface)
const GameplayTypes = require(script.Parent.GameplayTypes)
const Debi = require(ReplicatedStorage.Shareds.Networker.NetClient).Game

const GameplayServiceClient = {
	Initialized = false,
	Player = nil :: Player?,
	PlayerGui = nil :: PlayerGui?,
	EntityState = nil :: GameplayTypes.EntityState?,
	Units = {} :: { [number]: GameplayTypes.UnitState },
	Energy = {
		Current = 0,
		Max = 0,
	} :: GameplayTypes.MatchEnergy,
}

export type GameplayServiceClient = typeof(GameplayServiceClient)

function GameplayServiceClient.ToVector3(position: GameplayTypes.Vec3Data): Vector3
	return Vector3.new(position.X, position.Y, position.Z)
end

function GameplayServiceClient.SetEntityState(self: GameplayServiceClient, state: GameplayTypes.EntityState): ()
	self.EntityState = state
	self:EnableGameplayInterface()

	CardsServiceInterface:OnEntityState(state)
end

function GameplayServiceClient.EnableGameplayInterface(self: GameplayServiceClient)
	local playerGui = self.PlayerGui
	if not playerGui then
		return
	end

	local main = playerGui:FindFirstChild("Main")
	local gameplayInterface = main and main:FindFirstChild("Gameplay", true)
	if gameplayInterface and gameplayInterface:IsA("GuiObject") then
		gameplayInterface.Visible = true
	end
end

function GameplayServiceClient.SetEnergy(self: GameplayServiceClient, energy: GameplayTypes.MatchEnergy): ()
	self.Energy = energy
	
end

function GameplayServiceClient.AddUnit(self: GameplayServiceClient, unit: GameplayTypes.UnitState): ()
	self.Units[unit.NetId] = unit
end

function GameplayServiceClient.UpdateUnit(self: GameplayServiceClient, unit: GameplayTypes.UnitUpdate): ()
	local oldUnit = self.Units[unit.NetId]

	if not oldUnit then
		return
	end

	oldUnit.Position = unit.Position
	oldUnit.Health = unit.Health
	oldUnit.Moving = unit.Moving
end

function GameplayServiceClient.RemoveUnit(self: GameplayServiceClient, netId: number): ()
	self.Units[netId] = nil
	
end

function GameplayServiceClient.Init(self: GameplayServiceClient): GameplayServiceClient
	if self.Initialized then
		return self
	end

	self.Initialized = true

	Debi.SetEntityState.SetCallback(function(state)
		self:SetEntityState(state :: any)
	end)
	Debi.SetEnergy.SetCallback(function(energy)
		self:SetEnergy(energy :: any)
	end)
	Debi.AddUnit.On(function(unit)
		self:AddUnit(unit :: any)
	end)
	Debi.UpdateUnit.On(function(unit)
		self:UpdateUnit(unit :: any)
	end)
	Debi.RemoveUnit.On(function(netId: number)
		self:RemoveUnit(netId)
	end)

	const player = Players.LocalPlayer
	self.Player = player
	self.PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	return self
end

return GameplayServiceClient
