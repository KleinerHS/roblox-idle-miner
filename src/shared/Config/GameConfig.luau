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

	-- Servervalidierung beim manuellen Mining (docs/03 §4)
	Mining = {
		-- Maximaler Abstand des Spielers zur Abbauzone in Studs
		ReachStuds = 7,
		-- Anteil des Pickaxe-Cooldowns, der mindestens zwischen zwei Hits liegen muss
		-- (Toleranz für Netzwerk-Schwankungen)
		CooldownTolerance = 0.85,
	},

	Offline = {
		-- Maximale Offline-Produktion in Sekunden (docs/14 §7, verbindlich).
		MaxSeconds = 3600,
	},
}

return table.freeze(GameConfig)
