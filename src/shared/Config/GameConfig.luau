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

	-- Direkter Handel (docs/13 §5–12)
	Trade = {
		-- Abstand zum Starten einer Anfrage und beim Abschluss (Studs)
		RequestDistance = 20,
		CommitDistance = 80,
		-- Sekunden zwischen zwei Anfragen an denselben Spieler (Spam-Schutz)
		RequestCooldown = 10,
		-- Sekunden, die eine Anfrage gültig bleibt
		RequestTimeout = 20,
		-- Kurze Bestätigungsphase nach beidseitigem Sperren (Sekunden)
		ConfirmDelay = 3,
	},
}

return table.freeze(GameConfig)
