--!strict

return {
	Name = "start-match",
	Aliases = { "startmatch", "sm" },
	Description = "Starts a match (mapName gamemode players). Current gamemode: 1v1.",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "mapName",
			Description = "Map id (e.g. FlorestMap)",
		},
		{
			Type = "string",
			Name = "gamemode",
			Description = "Game mode (1v1 only for now)",
		},
		{
			Type = "players",
			Name = "players",
			Description = "Match players (1 = vs Enemy, 2 = PvP)",
		},
	},
}
