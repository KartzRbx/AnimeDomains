--!strict
-- Behavior: map catalog + lookup by IslandId

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)

export type _BuildNewIslandData = {
	IslandId: string,
	Name: string,
	Requisits: {
		IslandLevel: number,
	},
	IslandModel: _IslandModel,
}

export type EntitySpawnZonePart = BasePart & {
	Highlight: Highlight,
}

export type EntitySpawnZone = Model & {
	Left: EntitySpawnZonePart,
	Main: EntitySpawnZonePart,
	Right: EntitySpawnZonePart,
	Base: EntitySpawnZonePart?,
}

export type Teams = Model & {
	One: Model & {
		Interactions: Folder & {
			EntitySpawnZone: EntitySpawnZone,
			PlayerSpawn: BasePart,
		},
		Towers: Folder & {
			LeftTower: Model & {
				GripEntity: Attachment,
			},
			MainTower: Model & {
				GripEntity: Attachment,
			},
			RightTower: Model & {
				GripEntity: Attachment,
			},
		},
	},
	Two: Model & {
		Interactions: Folder & {
			EntitySpawnZone: EntitySpawnZone,
			PlayerSpawn: BasePart,
		},
		Towers: Folder & {
			LeftTower: Model & {
				GripEntity: Attachment,
			},
			MainTower: Model & {
				GripEntity: Attachment,
			},
			RightTower: Model & {
				GripEntity: Attachment,
			},
		},
	},
}

export type _IslandModel = Model & {
	Build: Model & {
		Construtions: Model?,
		EntityLimitations: Model?,
	},
	Teams: Teams,
}

local function BuildNewIslandData(Propeties: _BuildNewIslandData): _BuildNewIslandData
	return {
		Name = Propeties.Name,
		IslandModel = Propeties.IslandModel,
		Requisits = Propeties.Requisits,
		IslandId = Propeties.IslandId,
	}
end

-- Data only — never mix functions into this array
const IslandList: { _BuildNewIslandData } = {
	BuildNewIslandData({
		IslandId = "FlorestMap",
		Name = "FlorestMap",
		IslandModel = AssetsUtils.getMaps("FlorestMap"),
		Requisits = {
			IslandLevel = 0,
		},
	}),
}

local function GetMapWithId(IslandId: string): _IslandModel?
	for _, IslandData in IslandList do
		if IslandData.IslandId == IslandId then
			return IslandData.IslandModel
		end
	end
	return nil
end

return {
	GetMapWithId = GetMapWithId,
	List = IslandList,
}
