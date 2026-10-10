--!strict
-- Zentrale Balancewerte. Alles mit TODO_BALANCE ist ein Platzhalter und wird
-- in der Balance-Phase (docs/16 Phase 14) ersetzt. Keine Balancezahlen in anderen Scripts.

local BalanceConfig = {
	-- Startgeld eines neuen Spielers. Festgelegt durch D-003.
	StartCash = 800,

	-- XP-Kurve: XPRequired(level) = floor(BaseXP * level ^ Exponent)  (docs/11 §40)
	-- Muss Level 1000+ erlauben, deshalb kein Exponentialwachstum.
	Leveling = {
		BaseXP = 100, -- TODO_BALANCE
		Exponent = 1.5, -- TODO_BALANCE
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
		InputCapacity = 200, -- Felix (D-028) Erz im Einfülltrichter
		OutputCapacity = 100, -- Felix (D-028) Barren in der Ablage
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
	Storage = {
		StartCapacity = 1000,
		-- Kapazitätsstufen über die Storage-App im Laptop (docs/09 §29–30). Jede Stufe setzt
		-- die Gesamtkapazität auf Capacity. Werte von Felix bestätigt (D-022).
		Upgrades = {
			{ Capacity = 2500, Cost = 3000, RequiredLevel = 5 }, -- Felix (D-022)
			{ Capacity = 5000, Cost = 8000, RequiredLevel = 6 }, -- Felix (D-022)
			{ Capacity = 10000, Cost = 20000, RequiredLevel = 8 }, -- Felix (D-022)
			{ Capacity = 25000, Cost = 50000, RequiredLevel = 10 }, -- Felix (D-022)
			-- Phase 12b (Vorschlag Q-027): Kosten ≈ 15.000 × Erzwert auf diesem Level
			{ Capacity = 50000, Cost = 200000, RequiredLevel = 20 }, -- TODO_BALANCE (Q-027)
			{ Capacity = 100000, Cost = 13000000, RequiredLevel = 35 }, -- TODO_BALANCE (Q-027)
			{ Capacity = 250000, Cost = 360000000, RequiredLevel = 55 }, -- TODO_BALANCE (Q-027)
			{ Capacity = 500000, Cost = 18000000000, RequiredLevel = 80 }, -- TODO_BALANCE (Q-027)
		},
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
			-- Phase 12b (Vorschlag Q-027): Kosten ≈ 15.000 × Erzwert auf diesem Level
			{ Capacity = 1500, Cost = 120000, RequiredLevel = 18 }, -- TODO_BALANCE (Q-027)
			{ Capacity = 2500, Cost = 3200000, RequiredLevel = 30 }, -- TODO_BALANCE (Q-027)
			{ Capacity = 4000, Cost = 59000000, RequiredLevel = 45 }, -- TODO_BALANCE (Q-027)
			{ Capacity = 6000, Cost = 1700000000, RequiredLevel = 65 }, -- TODO_BALANCE (Q-027)
			{ Capacity = 10000, Cost = 44000000000, RequiredLevel = 85 }, -- TODO_BALANCE (Q-027)
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
		-- Erz-XP = XP-Bedarf (Level der ersten Mine) / XPDivisor, mindestens +1 je Tier
		XPDivisor = 2000, -- Startwert (D-035)
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
