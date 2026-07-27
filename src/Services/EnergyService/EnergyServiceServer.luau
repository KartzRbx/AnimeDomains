--!strict

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const Janitor = require(ReplicatedStorage.Packages.janitor)
const EnergyConstants = require(ReplicatedStorage.Shareds.Services.EnergyService.EnergyConstants)
const EnergyEnums = require(ReplicatedStorage.Shareds.Services.EnergyService.EnergyEnums)
const Debi = require(ReplicatedStorage.Shareds.Networker.NetServer).Game

type JanitorObject = typeof(Janitor.new())

export type MultiplierMode = "1x" | "2x" | "3x"
export type PlayersToRender = { [Player]: boolean }


const ENERGY_ATTRIBUTE_NAME = 'Energy'
const SYNC_INTERVAL = 1 / 12
const ENERGY_EPSILON = 0.01

const EnergyServiceServer = {
	initialized = false,
	janitor = Janitor.new() :: JanitorObject,
	playerToRender = {} :: PlayersToRender,
	lastSentEnergy = {} :: { [Player]: number },
	syncAccumulator = 0,
	multiplierMode = "1x" :: MultiplierMode,
}

export type EnergyServiceServer = typeof(EnergyServiceServer)

const function readEnergy(player: Player): number
	const energyAttribute = player:GetAttribute("Energy")
	if typeof(energyAttribute) == "number" then
		return energyAttribute
	end
	return EnergyConstants.STARTER_ENERGY
end

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
				const energy = readEnergy(player)
				const regenRate = EnergyConstants.REGEN_PER_SECOND * EnergyEnums.MultipliersMode[self.multiplierMode]
				const newEnergy = math.min(EnergyConstants.MAX_ENERGY, energy + regenRate * deltaTime)
				player:SetAttribute(ENERGY_ATTRIBUTE_NAME, newEnergy)
			end

			self.syncAccumulator += deltaTime
			if self.syncAccumulator < SYNC_INTERVAL then
				return
			end
			self.syncAccumulator = 0

			for player in self.playerToRender do
				const energy = readEnergy(player)
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
	if typeof(player:GetAttribute(ENERGY_ATTRIBUTE_NAME)) ~= "number" then
		player:SetAttribute(ENERGY_ATTRIBUTE_NAME, EnergyConstants.STARTER_ENERGY)
	end

	const energy = readEnergy(player)
	self.lastSentEnergy[player] = energy
	Debi.FetchPlayerEnergy.Fire(player, energy)
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

-- << PUBLIC FUNC >> -- 

function EnergyServiceServer.GetPlayerEnergy(self: EnergyServiceServer, target: Player): number?
	if not target or not Players:FindFirstChild(target.Name) then
			warn('Target player not found.')
		return
	end

	if not target:GetAttribute(ENERGY_ATTRIBUTE_NAME) then
			warn('Error to request player attribute.')
		return 
	end

	return target:GetAttribute(ENERGY_ATTRIBUTE_NAME) :: number
end

function EnergyServiceServer.SetPlayerEnergy(self: EnergyServiceServer, target: Player, targetEnergy: number): any
	print(target, targetEnergy)
	if not target or not Players:FindFirstChild(target.Name) or not self.playerToRender[target] then
			warn('Target player not found.')
		return
	end

	if not targetEnergy or type(targetEnergy) ~= 'number' then
			warn('Invalid targetEnergy value, cannot change of number')
		return
	end

	if not target:GetAttribute(ENERGY_ATTRIBUTE_NAME) then
			warn('Error to request player attribute.')
		return 
	end

	return target:SetAttribute(ENERGY_ATTRIBUTE_NAME, targetEnergy)
end

-- << END >>

return EnergyServiceServer
