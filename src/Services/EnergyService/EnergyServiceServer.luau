--!strict

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const Janitor = require(ReplicatedStorage.Packages.janitor)
const EnergyConstants = require(ReplicatedStorage.Shareds.Services.EnergyService.EnergyConstants)
const EnergyEnums = require(ReplicatedStorage.Shareds.Services.EnergyService.EnergyEnums)
const Debi = require(ReplicatedStorage.Shareds.Networker.Net).Game

type JanitorObject = typeof(Janitor.new())

export type MultiplierMode = "1x" | "2x" | "3x"
export type PlayersToRender = { [Player]: boolean }

const SYNC_INTERVAL = 1 / 12
const ENERGY_EPSILON = 0.01

local EnergyServiceServer = {
	initialized = false,
	janitor = Janitor.new() :: JanitorObject,
	playerToRender = {} :: PlayersToRender,
	lastSentEnergy = {} :: { [Player]: number },
	syncAccumulator = 0,
	multiplierMode = "1x" :: MultiplierMode,
}

export type EnergyServiceServer = typeof(EnergyServiceServer)

function EnergyServiceServer.SetMultiplierMode(self: EnergyServiceServer, mode: MultiplierMode): ()
	if not self.initialized then
		return
	end

	self.multiplierMode = mode
end

function EnergyServiceServer.RenderEnergyLoop(self: EnergyServiceServer): ()
	self.janitor:cleanup()
	self.syncAccumulator = 0

	self.janitor:add(
		RunService.Heartbeat:Connect(function(deltaTime: number)
			for player in self.playerToRender do
				local energyAttribute = player:GetAttribute("Energy")
				local energy = if typeof(energyAttribute) == "number"
					then energyAttribute
					else EnergyConstants.STARTER_ENERGY

				const regenRate = EnergyConstants.REGEN_PER_SECOND * EnergyEnums.MultipliersMode[self.multiplierMode]
				const newEnergy = math.min(EnergyConstants.MAX_ENERGY, energy + regenRate * deltaTime)
				player:SetAttribute("Energy", newEnergy)
			end

			self.syncAccumulator += deltaTime
			if self.syncAccumulator < SYNC_INTERVAL then
				return
			end
			self.syncAccumulator = 0

			for player in self.playerToRender do
				local energyAttribute = player:GetAttribute("Energy")
				const energy = if typeof(energyAttribute) == "number" then energyAttribute else 0
				const last = self.lastSentEnergy[player]
				if last ~= nil and math.abs(energy - last) < ENERGY_EPSILON then
					continue
				end
				if energy >= EnergyConstants.MAX_ENERGY and last ~= nil and last >= EnergyConstants.MAX_ENERGY then
					continue
				end

				self.lastSentEnergy[player] = energy
				Debi.FetchPlayerEnergy.Fire(player, energy)
			end
		end),
		"Disconnect"
	)
end

function EnergyServiceServer.FetchPlayerEnergy(self: EnergyServiceServer, player: Player): ()
	if self.playerToRender[player] then
		return
	end

	self.playerToRender[player] = true
end

function EnergyServiceServer.Init(self: EnergyServiceServer): EnergyServiceServer
	if self.initialized then
		return self
	end

	self.initialized = true
	self.playerToRender = {}
	self.lastSentEnergy = {}
	self.syncAccumulator = 0
	self.multiplierMode = "1x"

	self:RenderEnergyLoop()

	self.janitor:add(Players.PlayerRemoving:Connect(function(player: Player)
		self.playerToRender[player] = nil
		self.lastSentEnergy[player] = nil
	end), "Disconnect")

	game:BindToClose(function()
		self.janitor:destroy()
	end)

	return self
end

return EnergyServiceServer
