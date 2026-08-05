--!strict

export type TowerSlot = "Left" | "Main" | "Right"

export type TowerSlotModelName = "LeftTower" | "MainTower" | "RightTower"

const SLOT_TO_MODEL_NAME: { [TowerSlot]: TowerSlotModelName } = {
	Left = "LeftTower",
	Main = "MainTower",
	Right = "RightTower",
}

const MODEL_NAME_TO_SLOT: { [TowerSlotModelName]: TowerSlot } = {
	LeftTower = "Left",
	MainTower = "Main",
	RightTower = "Right",
}

const TowerServiceUtils = {}

function TowerServiceUtils.GetSlotModelName(slot: string): TowerSlotModelName?
	if slot == "Left" then
		return "LeftTower"
	end
	if slot == "Main" then
		return "MainTower"
	end
	if slot == "Right" then
		return "RightTower"
	end
	return nil
end

function TowerServiceUtils.GetSlotFromModelName(modelName: string): TowerSlot?
	return MODEL_NAME_TO_SLOT[modelName :: TowerSlotModelName]
end

function TowerServiceUtils.GetAllSlots(): { TowerSlot }
	return { "Left", "Main", "Right" }
end

export type TowerServiceUtils = typeof(TowerServiceUtils)
return TowerServiceUtils
