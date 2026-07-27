

const PlayerDataTemplate: Schema = {
	Game = {
		Towers = {
			Left = { Id = "Dummy", Level = 1 },
			Main = { Id = "Dummy", Level = 1 },
			Right = { Id = "Dummy", Level = 1 },
		},
		Deck = {
			"Sabre",
			"PlaceholderOne",
			"PlaceholderTwo",
			"PlaceholderThree",
			"PlaceholderFour",
			"PlaceholderFive",
			"PlaceholderSix",
			"PlaceholderSeven",
		},
		Cards = {
			["card-sabre-0001"] = { Id = "Sabre", Level = 1, Count = 0 },
			["card-ph-0001"] = { Id = "PlaceholderOne", Level = 1, Count = 0 },
			["card-ph-0002"] = { Id = "PlaceholderTwo", Level = 1, Count = 0 },
			["card-ph-0003"] = { Id = "PlaceholderThree", Level = 1, Count = 0 },
			["card-ph-0004"] = { Id = "PlaceholderFour", Level = 1, Count = 0 },
			["card-ph-0005"] = { Id = "PlaceholderFive", Level = 1, Count = 0 },
			["card-ph-0006"] = { Id = "PlaceholderSix", Level = 1, Count = 0 },
			["card-ph-0007"] = { Id = "PlaceholderSeven", Level = 1, Count = 0 },
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
