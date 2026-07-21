--!strict

export type MapId = string
export type Result = boolean
export type GameType = "Single" | "Multi"
export type GameMode = "1v1"
export type MatchId = string
export type GameStatus = "Waiting" | "Running" | "Finished"

export type GameConfig = {
	MapId: MapId,
	GameType: GameType,
	GameMode: GameMode,
}

export type GameplayProperties = {
	Players: { string },
	GameConfig: GameConfig,
}

export type GameplayPropeties = GameplayProperties

export type TowerInfo = {
	Id: string,
	Level: number,
}

export type TeamTowers = {
	Left: TowerInfo,
	Main: TowerInfo,
	Right: TowerInfo,
}

export type TeamData = {
	Owner: string,
	Data: {
		Towers: TeamTowers,
		Deck: { string },
	},
}

export type EntityState = {
	One: TeamData,
	Two: TeamData,
}

export type Vec3Data = {
	X: number,
	Y: number,
	Z: number,
}

export type UnitState = {
	NetId: number,
	CardId: string,
	Team: string,
	Position: Vec3Data,
	Health: number,
	MaxHealth: number,
	Moving: boolean?,
}

export type UnitUpdate = {
	NetId: number,
	Position: Vec3Data,
	Health: number,
	Moving: boolean,
}

export type UnitDespawn = {
	NetId: number,
}

export type MatchEnergy = {
	Current: number,
	Max: number,
}

export type Match = {
	MatchId: MatchId,
	Players: { string },
	GameConfig: GameConfig,
	Status: GameStatus,
}

export type MatchMap = {
	[MatchId]: Match,
}

return {}
