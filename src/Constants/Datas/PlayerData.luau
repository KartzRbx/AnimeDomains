


const PlayerDataTemplate: Schema = {
	Game = {
		Towers = {
			Left = { Id = "Dummy", Level = 1 },
			Main = { Id = "Dummy", Level = 1 },
			Right = { Id = "Dummy", Level = 1 },
		},
		Deck = {"Sabre"},
		Cards = {
			["acbd-efgh-12ij4k-sadasd"] = { Id = "Sabre", Level = 1, Count = 0 },
		},
		Trophies = 0,
	},
	Currency = {
		Coins = 0,
		Gems = 0,
	},
	Inventory = {
		Skins = { "Default" },
	},
	Settings = {
		Match = {
			ShowTowerRangeOnHover = true,
		},
	},
	Logs = {
		Matches = {},
	},
}


export type Schema = typeof(PlayerDataTemplate)
return table.freeze(PlayerDataTemplate)
