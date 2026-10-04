--!strict
-- Zentrale technische Spielkonstanten (keine Balancewerte, die stehen in BalanceConfig).

local GameConfig = {
	-- Anzahl Spielergrundstücke pro Server (docs/04 §2). Server-MaxPlayers muss in den
	-- Game Settings ebenfalls auf 6 stehen.
	MaxPlots = 6,

	-- Debug-Ausgaben im Output. Vor Release auf false setzen (docs/15 §20).
	Debug = true,

	Data = {
		-- Name des DataStores. Nie ändern, sonst sind alle Spielstände "weg".
		StoreName = "PlayerData",
		-- Schlüssel pro Spieler: KeyPrefix .. UserId
		KeyPrefix = "Player_",
	},

	Offline = {
		-- Maximale Offline-Produktion in Sekunden (docs/14 §7, verbindlich).
		MaxSeconds = 3600,
	},
}

return table.freeze(GameConfig)
