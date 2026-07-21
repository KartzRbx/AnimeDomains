--!strict
-- Debi Remotes — one Reliable/Unreliable pair per channel (Game, Secondary, Validations)

const RunService = game:GetService("RunService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const ROOT_NAME = "_debi"
const RELIABLE_NAME = "Reliable"
const UNRELIABLE_NAME = "Unreliable"

export type DebiRemotes = {
	Reliable: RemoteEvent,
	Unreliable: UnreliableRemoteEvent,
}

const function getOrCreateRoot(): Folder
	if RunService:IsServer() then
		const existing = ReplicatedStorage:FindFirstChild(ROOT_NAME)
		if existing and existing:IsA("Folder") then
			return existing
		end

		const folder = Instance.new("Folder")
		folder.Name = ROOT_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end

	return ReplicatedStorage:WaitForChild(ROOT_NAME) :: Folder
end

const function getOrCreateChannel(channel: string): Folder
	const root = getOrCreateRoot()

	if RunService:IsServer() then
		const existing = root:FindFirstChild(channel)
		if existing and existing:IsA("Folder") then
			return existing
		end

		const folder = Instance.new("Folder")
		folder.Name = channel
		folder.Parent = root
		return folder
	end

	return root:WaitForChild(channel) :: Folder
end

const Remotes = {}

function Remotes.getServer(channel: string): DebiRemotes
	assert(RunService:IsServer(), "[Debi] getServer is server-only")
	assert(channel ~= "", "[Debi] empty channel")

	const folder = getOrCreateChannel(channel)

	local reliableInst = folder:FindFirstChild(RELIABLE_NAME)
	if reliableInst and not reliableInst:IsA("RemoteEvent") then
		reliableInst:Destroy()
		reliableInst = nil
	end
	if not reliableInst then
		const created = Instance.new("RemoteEvent")
		created.Name = RELIABLE_NAME
		created.Parent = folder
		reliableInst = created
	end

	local unreliableInst = folder:FindFirstChild(UNRELIABLE_NAME)
	if unreliableInst and not unreliableInst:IsA("UnreliableRemoteEvent") then
		unreliableInst:Destroy()
		unreliableInst = nil
	end
	if not unreliableInst then
		const created = Instance.new("UnreliableRemoteEvent")
		created.Name = UNRELIABLE_NAME
		created.Parent = folder
		unreliableInst = created
	end

	return {
		Reliable = reliableInst :: RemoteEvent,
		Unreliable = unreliableInst :: UnreliableRemoteEvent,
	}
end

function Remotes.getClient(channel: string): DebiRemotes
	assert(RunService:IsClient(), "[Debi] getClient is client-only")
	assert(channel ~= "", "[Debi] empty channel")

	const folder = getOrCreateChannel(channel)
	const reliable = folder:WaitForChild(RELIABLE_NAME)
	assert(reliable:IsA("RemoteEvent"), "[Debi] invalid Reliable")
	const unreliable = folder:WaitForChild(UNRELIABLE_NAME)
	assert(unreliable:IsA("UnreliableRemoteEvent"), "[Debi] invalid Unreliable")

	return {
		Reliable = reliable,
		Unreliable = unreliable,
	}
end

return Remotes
