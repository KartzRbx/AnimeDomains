--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const EnergyConstants = require(script.Parent.EnergyConstants)
const PlayerUtils = require(ReplicatedStorage.Shareds.Utils.PlayerUtils)
const InterfaceTypes = require(ReplicatedStorage.Shareds.Utils.PlayerUtils.Types)
const Debi = require(ReplicatedStorage.Shareds.Networker.NetClient).Game

local EnergyServiceClient = {
	initialized = false,
	EnergyContainer = nil :: InterfaceTypes.EnergyContainer?,
	displayedEnergy = 0,
}

export type EnergyServiceClient = typeof(EnergyServiceClient)

function EnergyServiceClient.FetchPlayerEnergy(self: EnergyServiceClient, currentEnergy: number)
	self.displayedEnergy = currentEnergy

	const energyContainer = self.EnergyContainer
	if not energyContainer then
		return
	end

	const maxEnergy = EnergyConstants.MAX_ENERGY
	const ratio = math.clamp(currentEnergy / maxEnergy, 0, 1)
	energyContainer.Bar.Size = UDim2.fromScale(ratio, 1)

	const labelText = string.format("%.0f", math.round(currentEnergy + 0.5))
	energyContainer.CurrentEnergy.Text = labelText
	energyContainer.CurrentEnergy.Main.Text = labelText
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
		if self.displayedEnergy > 0 then
			self:FetchPlayerEnergy(self.displayedEnergy)
		end
	end)

	return self
end

return EnergyServiceClient
