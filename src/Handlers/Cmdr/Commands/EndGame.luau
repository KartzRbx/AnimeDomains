--!strict

return {
	Name = "end-game",
	Aliases = { "endgame", "eg", "endmatch" },
	Description = "Ends the active match for player(s), or all matches if none specified.",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "Players to end match for (empty = all matches)",
			Optional = true,
		},
	},
}
