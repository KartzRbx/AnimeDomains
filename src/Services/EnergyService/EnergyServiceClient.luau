--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const EnergyConstants = require(script.Parent.EnergyConstants)
const PlayerUtils = require(ReplicatedStorage.Shareds.Utils.PlayerUtils)
const InterfaceTypes = require(ReplicatedStorage.Shareds.Utils.PlayerUtils.Types)
const Debi = require(ReplicatedStorage.Shareds.Networker.Net).Game

local EnergyServiceClient = {
	initialized = false,
	EnergyContainer = nil :: InterfaceTypes.EnergyContainer?,
}

export type EnergyServiceClient = typeof(EnergyServiceClient)

function EnergyServiceClient.FetchPlayerEnergy(self: EnergyServiceClient, currentEnergy: number)
	local energyContainer = self.EnergyContainer
	if not energyContainer then
		return
	end

	local bar = energyContainer.Bar
	bar.Size = bar.Size:Lerp(UDim2.fromScale(currentEnergy / EnergyConstants.MAX_ENERGY, 1), 1 / 30)
end

function EnergyServiceClient.Init(self: EnergyServiceClient): EnergyServiceClient
	if self.initialized then
		return self
	end

	self.initialized = true

	Debi.FetchPlayerEnergy.SetCallback(function(energy: number)
		self:FetchPlayerEnergy(energy)
	end)

	task.spawn(function()
		self.EnergyContainer = PlayerUtils.wait("Main/Container/Gameplay/EnergyContainer") :: InterfaceTypes.EnergyContainer
	end)

	return self
end

return EnergyServiceClient
