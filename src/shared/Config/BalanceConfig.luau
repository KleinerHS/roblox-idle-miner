--!strict
-- Zentrale Balancewerte. Alles mit TODO_BALANCE ist ein Platzhalter und wird
-- in der Balance-Phase (docs/16 Phase 14) ersetzt. Keine Balancezahlen in anderen Scripts.

local BalanceConfig = {
	-- Startgeld eines neuen Spielers. Festgelegt durch D-003.
	StartCash = 800,

	-- XP-Kurve (docs/11 §40, D-042): abschnittsweise Potenzkurve, stetig zusammengesetzt.
	-- XPRequired(L) = BaseXP × Π (Abschnittsende / Abschnittsanfang)^Exponent, ab Level 1.
	-- Kein Exponentialwachstum, damit Level 1000+ möglich bleibt. Exponenten per Simulation
	-- (tools/BalanceSim.luau) auf Felix' Zielzeiten eingestellt: L10 1 h, L25 5 h, L50 20 h, L100 50 h.
	Leveling = {
		BaseXP = 100,
		Segments = {
			{ UpTo = 10, Exponent = 1.5 }, -- unverändert (Frühphase passte)
			{ UpTo = 25, Exponent = 4.6 }, -- per Simulation (D-042): L25 ≈ 5 h
			{ UpTo = 50, Exponent = 5.3 }, -- per Simulation (D-042): L50 ≈ 18 h
			{ UpTo = 100, Exponent = 0 }, -- per Simulation (D-042): gleicher Bedarf je Level, L100 ≈ 53 h
			{ UpTo = math.huge, Exponent = 2 }, -- nach Prestige-Level weiter steigend (Level 1000+ möglich), TODO_BALANCE
		},
	},

	-- Verkaufswert und Mining-XP je Erz, getrennt konfiguriert (docs/03 §11).
	-- Erze ohne Eintrag sind noch nicht gebalanced und nicht verkaufbar.
	OreValues = {
		ore_coal = { SellValue = 1, XPValue = 1 }, -- TODO_BALANCE (Beispielwerte aus docs/03 §16)
		ore_copper = { SellValue = 2, XPValue = 2 }, -- Felix (D-028)
		ore_tin = { SellValue = 3, XPValue = 3 }, -- Felix (D-028)
		ore_iron = { SellValue = 5, XPValue = 4 }, -- Felix (D-028)
	} :: { [string]: { SellValue: number, XPValue: number } },

	-- Barren aus dem Schmelzer (docs/06 §36: Wert(Output) > Wert(Input)). Barren ohne Eintrag
	-- sind noch nicht gebalanced; ihr Rezept bleibt inaktiv. bestätigt (D-028).
	BarValues = {
		bar_copper = { SellValue = 6, XPValue = 5 }, -- Felix (D-028) aus 2 Copper (= $4)
		bar_tin = { SellValue = 9, XPValue = 7 }, -- Felix (D-028) aus 2 Tin (= $6)
		bar_iron = { SellValue = 14, XPValue = 10 }, -- Felix (D-028) aus 2 Iron (= $10)
	} :: { [string]: { SellValue: number, XPValue: number } },

	-- Verladeturm (D-025): Einheiten pro Sekunde vom Lager ins Fahrzeug. bestätigt (D-029).
	Loading = {
		UnitsPerSecond = 100, -- Felix (D-029)
	},

	-- Schmelzer (docs/06 §28–35). bestätigt (D-028).
	Smelter = {
		OrePerBar = 2, -- Felix (D-028)
		SecondsPerBar = 3, -- Felix (D-028)
		-- Eingangs- und Ausgangslager des Ofens: je 4 Hochregale × 4 Paletten (Felix D-037),
		-- Kisten wie im Firmenlager (eine Sorte je Kiste, CrateSize Einheiten)
		InputCrates = 16, -- Felix (D-037)
		OutputCrates = 16, -- Felix (D-037)
	},

	-- Freischaltung der Minen über das Level (docs/12 §22). Mine 001 ist immer frei.
	-- Minen ohne Level-Eintrag sind noch nicht gebalanced und bleiben gesperrt.
	MineUnlocks = {
		mine_001 = { RequiredLevel = 1 },
		mine_002 = { RequiredLevel = 3 }, -- Felix (D-017)
		-- Ab Mine 03 zusätzlich Kauf (MinePrice). Level: bestätigt (D-028)
		mine_003 = { RequiredLevel = 6 }, -- Felix (D-028) Copper
		mine_004 = { RequiredLevel = 8 }, -- Felix (D-028) Copper
		mine_005 = { RequiredLevel = 10 }, -- Felix (D-028) Tin
		mine_006 = { RequiredLevel = 12 }, -- Felix (D-028) Tin
		mine_007 = { RequiredLevel = 14 }, -- Felix (D-028) Iron
		mine_008 = { RequiredLevel = 16 }, -- Felix (D-028) Iron
	} :: { [string]: { RequiredLevel: number } },

	-- Firmenlager (docs/06 §14): Startkapazität 1.000 über alle Materialien (fest).
	-- Firmenlager aus Palettenboxen (Phase 13b-2, Felix D-037): jede Kiste fasst CrateSize einer
	-- Materialsorte; Kisten werden am Laptop gekauft (ersetzt die Kapazitäts-Upgrades D-022/D-036).
	Storage = {
		CrateSize = 1000, -- Felix (D-037)
		-- Plätze in den Hochregalen der Halle (32 Regale × 4 Paletten übereinander)
		MaxCrates = 192, -- Felix (2026-10-13: 48 Regale × 4, bis zur Markierung)
		-- Kisten eines neuen Profils (die erste Kiste wird gekauft)
		StartCrates = 0, -- Felix (D-037: Startkiste kostet $100)
		-- Preis der 1., 2., 3. Kiste, danach jeweils × CrateGrowth
		CratePrices = { 100, 500, 1000 }, -- Felix (D-037)
		CrateGrowth = 1.5, -- Felix (D-037), TODO_BALANCE: späte Kisten sehr teuer (Kiste 50 ≈ $1,9 Bio.)
		-- keine Kapazitätsstufen mehr (Lager wächst über Kisten)
		Upgrades = {} :: { { Capacity: number, Cost: number, RequiredLevel: number } },
	},

	-- Worker (docs/05 §5–9). Werte von Felix bestätigt (D-021).
	Workers = {
		Mining = {
			HireCost = 2000, -- Felix (D-021)
			WagePerMinute = 5, -- Felix (D-021)
			OrePerMinute = 30, -- Felix (D-021)
		},
		Transport = {
			HireCost = 1500, -- Felix (D-021)
			WagePerMinute = 4, -- Felix (D-021)
			-- Erz pro Gang und Dauer eines Hin-und-Rückwegs (ergibt ca. 150 Erz/Min)
			CarryAmount = 50, -- Felix (D-021)
			TripSeconds = 20, -- Felix (D-021)
		},
		-- Puffer je belegtem Mining-Slot (Erz wartet auf Abholung, docs/06 §20)
		SlotBuffer = 200, -- Felix (D-021)
		-- Abstand der Lohnabrechnung (docs/05 §6: jede Minute)
		PayrollSeconds = 60,
		-- Rückerstattung beim Entlassen (Anteil der Einstellungskosten)
		FireRefund = 0, -- Felix (D-021)
	},

	-- Rare Drops beim manuellen Mining (docs/03 §7–8, docs/11 §18–21, D-006). Nur Spieler, nie
	-- Worker/Drills/Offline. Ein Rare Event ist ENTWEDER Mengen-Multiplikator ODER ein Rare Ore.
	RareDrops = {
		BaseChance = 0.01, -- TODO_BALANCE: Chance je erfolgreichem Hit (1 %)
		OreShare = 0.15, -- TODO_BALANCE: Anteil Rare Ore unter den Rare Events (Rest = Multiplikator)
		-- Gewichte für den Multiplikator ×2 … ×10 auf die Menge dieses Hits (höher = seltener;
		-- docs/11 §18: „1x bis 10x“, ×1 wäre kein Bonus)
		MultiplierWeights = { 30, 22, 15, 10, 8, 6, 4, 3, 2 }, -- TODO_BALANCE (×2 … ×10)
		-- Gewichte für 1 … 4 Erzstufen weiter (je weiter, desto seltener, docs/11 §19)
		TierWeights = { 8, 4, 2, 1 }, -- TODO_BALANCE
		RareOreAmount = 1, -- docs/03 §7: genau ein seltenes Erz
	},

	-- Mining Luck (docs/10 §17, D-007): eigene Upgrades mit Geld im Equipment-Shop, erhöht nur
	-- die Rare-Drop-Chance. Chance × (1 + Level × ChanceBonusPerLevel).
	Luck = {
		MaxLevel = 10, -- TODO_BALANCE
		ChanceBonusPerLevel = 0.15, -- TODO_BALANCE (Lv 10 = 2,5-fache Chance)
		BasePrice = 5000, -- TODO_BALANCE: Preis Level 1
		PriceGrowth = 3, -- TODO_BALANCE: jedes Level × 3
		-- Mindest-Mining-Level je Luck-Level: Level n braucht RequiredLevelStep × n
		RequiredLevelStep = 5, -- TODO_BALANCE
	},

	-- Drill-Level am Laptop (Felix 2026-10-18, D-043): jeder Drill hat eigene Upgrade-Level
	-- 1…MaxLevel, unabhängig von der MK-Stufe (neue MK-Stufe nur per Kauf).
	--   Produktion × (1 + (Level − 1) × ProductionBonusPerLevel), Puffer wächst mit
	--   Kosten Level n → n+1 = Drill-Preis × UpgradeCostShare × UpgradeCostGrowth^(n − 1)
	Drills = {
		MaxLevel = 10, -- Felix (D-043: „lvl 1-10“)
		ProductionBonusPerLevel = 0.10, -- TODO_BALANCE (Startwert, Lv 10 = +90 %)
		UpgradeCostShare = 0.05, -- Felix 2026-10-18 („5%“: Kosten-Start, nicht Produktion)
		UpgradeCostGrowth = 1.35, -- TODO_BALANCE
	},

	-- Elevator-Materialtransport (docs/06 §9–11).
	Elevator = {
		StartCapacity = 100, -- Felix (D-021) Erz pro Fahrt
		CycleSeconds = 10, -- Felix (D-021) eine Fahrt alle n Sekunden
		-- Kapazitätsstufen über die Elevator-App im Laptop (docs/09 §31). Bestätigt (D-022).
		Upgrades = {
			{ Capacity = 200, Cost = 2000, RequiredLevel = 3 }, -- Felix (D-022)
			{ Capacity = 350, Cost = 5000, RequiredLevel = 5 }, -- Felix (D-022)
			{ Capacity = 500, Cost = 10000, RequiredLevel = 7 }, -- Felix (D-022)
			{ Capacity = 750, Cost = 20000, RequiredLevel = 9 }, -- Felix (D-022)
			{ Capacity = 1000, Cost = 40000, RequiredLevel = 11 }, -- Felix (D-022)
			-- Phase 12b (Startwert D-036): Kosten ≈ 15.000 × Erzwert auf diesem Level
			{ Capacity = 1500, Cost = 120000, RequiredLevel = 18 }, -- Startwert (D-036)
			{ Capacity = 2500, Cost = 3200000, RequiredLevel = 30 }, -- Startwert (D-036)
			{ Capacity = 4000, Cost = 59000000, RequiredLevel = 45 }, -- Startwert (D-036)
			{ Capacity = 6000, Cost = 1700000000, RequiredLevel = 65 }, -- Startwert (D-036)
			{ Capacity = 10000, Cost = 44000000000, RequiredLevel = 85 }, -- Startwert (D-036)
		},
	},

	-- Geldpreis der Minen ab Mine 03 zusätzlich zum Level (D-017, D-019):
	-- Preis(n) = BasePrice * Growth ^ (n - FirstPaidMine), auf ganze Dollar gerundet.
	-- Mine 03 = $3.000, jede weitere Mine +50 %.
	-- Prestige (docs/12 §50–64, docs/11 §42–47). Ab Level 100 (fest). Bonus additiv je Prestige,
	-- dadurch sinkt das relative Wachstum (kein x2/x4/x8, docs/11 §45). Bestätigt (D-034).
	Prestige = {
		RequiredLevel = 100,
		-- Verkaufserlös (Geld, nicht XP) +n je Prestige: Faktor = 1 + n * Count
		MoneyBonusPerPrestige = 0.10, -- Felix (D-034)
		-- Mining Speed (Hits pro Sekunde) +n je Prestige, gedeckelt
		SpeedBonusPerPrestige = 0.05, -- Felix (D-034)
		SpeedBonusMax = 0.50, -- Felix (D-034)
	},

	-- Kurven für alle Inhalte ohne festen Einzelwert (Phase 12, ContentCurve.luau).
	-- Von Felix als Startwert bestätigt (D-035); Feinschliff in der Balance-Phase (docs/16 Phase 14).
	ContentCurve = {
		-- Erzwert je Tier ab Tier 5 (Lead): Vorgänger × Wachstum
		OreValueGrowthEarly = 1.6, -- Startwert (D-035) bis Tier EarlyUntilTier
		EarlyUntilTier = 15, -- Startwert (D-035)
		OreValueGrowthLate = 1.35, -- Startwert (D-035) danach
		-- Erz-XP = Bezugs-XP (Level der ersten Mine) / XPDivisor, mindestens +1 je Tier.
		-- Bezugskurve fest = alte Level-Kurve (D-042), damit die Erz-XP unverändert bleiben.
		XPDivisor = 2000, -- Startwert (D-035)
		XPReferenceBase = 100, -- D-042 (= Level-Kurve bis 2026-10-18)
		XPReferenceExponent = 1.5, -- D-042
		-- Barren: Wert und XP der eingesetzten Erze × Faktor (Copper–Iron: ~1.4 / ~1.25)
		BarValueFactor = 1.4, -- Startwert (D-035)
		BarXPFactor = 1.25, -- Startwert (D-035)
		-- Minen-Level linear zwischen Anker (Mine 08 = Level 16, D-028) und Mine 100
		LevelAnchorMine = 8,
		LevelAnchorLevel = 16,
		LastMine = 100,
		LastMineLevel = 100, -- Startwert (D-035) docs/02 §30: Mine 100 und Level 100 als Endziel
		-- Minenpreis ab Mine 09 = Erzwert × Vielfaches (zweite Mine einer Erzart × Faktor)
		MinePriceOreMultiple = 4500, -- Startwert (D-035)
		SecondMinePriceFactor = 1.25, -- Startwert (D-035)
	},

	-- Minenpreis Mine 03–08 (D-019: $3.000, je +50 %). Ab Mine 09 über ContentCurve.
	MinePrice = {
		FirstPaidMine = 3,
		BasePrice = 3000,
		Growth = 1.5,
		-- letzte Mine mit D-019-Formel
		LastFormulaMine = 8,
	},
}

return table.freeze(BalanceConfig)
