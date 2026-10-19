--!strict
-- Zentrale Werte für Licht, Atmosphäre und Audio (Phase 13d, docs/01 §44, docs/08 §47,
-- docs/09 §58/§60). Alles reine Optik/Akustik auf dem Client.
--
-- Audio: nur für Roblox lizenzierte Bibliotheken (Pro Sound Effects, APM Music) bzw. frei
-- freigegebene Creator-Store-Sounds. Jede ID wurde in Studio geladen (2026-10-17).
-- Lautstärken sind Startwerte (TODO_BALANCE: nach Hörtest mit Felix feinjustieren).

export type SoundDef = {
	Ids: { number },
	Volume: number,
	PitchMin: number?,
	PitchMax: number?,
	-- räumlich: hörbar bis MaxDistance (Studs), volle Lautstärke bis MinDistance
	MinDistance: number?,
	MaxDistance: number?,
}

local AmbienceConfig = {}

-- Farbkorrektur oben und unter Tage (lokaler ColorCorrectionEffect "AmbienceGrade")
AmbienceConfig.Grade = {
	Surface = { Brightness = 0, Contrast = 0.04, Saturation = 0.06, TintColor = Color3.fromRGB(255, 252, 246) },
	Mine = { Brightness = -0.02, Contrast = 0.08, Saturation = -0.05, TintColor = Color3.fromRGB(255, 236, 212) },
}

-- Hall unter Tage (SoundService.AmbientReverb, nur lokal)
AmbienceConfig.MineReverb = Enum.ReverbType.StoneRoom

-- Hintergrundmusik: ruhige Akustik-Playlist (APM Music), unter Tage leiser.
-- Abgeschaltet (Felix 2026-10-19: „entferne bitte die Musik aus dem Spiel“), Playlist bleibt für später.
AmbienceConfig.Music = {
	Enabled = false,
	Ids = {
		1840007392, -- Maypole Summer
		1844683008, -- Open Fields
		1839359693, -- Acoustic Travel
	},
	Volume = 0.12,
	MineFactor = 0.5,
	FadeSeconds = 2,
}

-- Grundgeräusch je Ort (Schleife, nicht räumlich)
AmbienceConfig.Ambience = {
	Surface = { Ids = { 9112832288 }, Volume = 0.22 } :: SoundDef, -- Mountain Birds (Pro Sound Effects)
	Mine = { Ids = { 273398061 }, Volume = 0.3 } :: SoundDef, -- Cave Ambience
	FadeSeconds = 1.5,
}

-- Räumliche Maschinenklänge (Schleife am Objekt, nur solange es läuft)
AmbienceConfig.Machines = {
	Smelter = { Ids = { 9112839813 }, Volume = 0.35, MinDistance = 8, MaxDistance = 70 } :: SoundDef, -- Oil Refinery Burners
	Conveyor = { Ids = { 9112890497 }, Volume = 0.15, MinDistance = 4, MaxDistance = 36 } :: SoundDef, -- Distant Conveyor Belt
}

-- Einzelne Ereignisse
AmbienceConfig.Sounds = {
	MineHit = { Ids = { 9118634165, 9118634469 }, Volume = 0.4, PitchMin = 0.92, PitchMax = 1.12, MinDistance = 6, MaxDistance = 60 } :: SoundDef,
	Elevator = { Ids = { 9116983192 }, Volume = 0.45 } :: SoundDef, -- Motor Whir (Fahrt im Förderkorb)
	UiClick = { Ids = { 111764646352235 }, Volume = 0.3, PitchMin = 0.98, PitchMax = 1.04 } :: SoundDef,
	Error = { Ids = { 111764646352235 }, Volume = 0.35, PitchMin = 0.55, PitchMax = 0.55 } :: SoundDef,
	Success = { Ids = { 9113849583 }, Volume = 0.25 } :: SoundDef, -- Coin Throws
	Sell = { Ids = { 1319346243 }, Volume = 0.45 } :: SoundDef, -- Cash Register
	LevelUp = { Ids = { 99980076888596 }, Volume = 0.5 } :: SoundDef, -- positiver Jingle
	RareDrop = { Ids = { 128502047397803 }, Volume = 0.55 } :: SoundDef, -- Rare Ore (Stern)
	LuckyDrop = { Ids = { 135385970610304 }, Volume = 0.45 } :: SoundDef, -- Mengen-Multiplikator (Funkeln)
}

-- Mining-Staub beim Treffer (docs/19 §6: kleine Steinpartikel, ggf. Staub)
AmbienceConfig.MineDust = {
	Count = 14,
	Color = Color3.fromRGB(150, 135, 120),
	Size = 0.9,
	Lifetime = 0.9,
}

return table.freeze(AmbienceConfig)
