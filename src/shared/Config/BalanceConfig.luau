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
		ore_copper = { SellValue = 2, XPValue = 2 }, -- TODO_BALANCE (Q-022)
		ore_tin = { SellValue = 3, XPValue = 3 }, -- TODO_BALANCE (Q-022)
		ore_iron = { SellValue = 5, XPValue = 4 }, -- TODO_BALANCE (Q-022)
	} :: { [string]: { SellValue: number, XPValue: number } },

	-- Barren aus dem Schmelzer (docs/06 §36: Wert(Output) > Wert(Input)). Barren ohne Eintrag
	-- sind noch nicht gebalanced; ihr Rezept bleibt inaktiv. Vorschlag Q-022.
	BarValues = {
		bar_copper = { SellValue = 6, XPValue = 5 }, -- TODO_BALANCE (Q-022) aus 2 Copper (= $4)
		bar_tin = { SellValue = 9, XPValue = 7 }, -- TODO_BALANCE (Q-022) aus 2 Tin (= $6)
		bar_iron = { SellValue = 14, XPValue = 10 }, -- TODO_BALANCE (Q-022) aus 2 Iron (= $10)
	} :: { [string]: { SellValue: number, XPValue: number } },

	-- Schmelzer (docs/06 §28–35). Vorschlag Q-022.
	Smelter = {
		OrePerBar = 2, -- TODO_BALANCE (Q-022)
		SecondsPerBar = 3, -- TODO_BALANCE (Q-022)
		InputCapacity = 200, -- TODO_BALANCE (Q-022) Erz im Einfülltrichter
		OutputCapacity = 100, -- TODO_BALANCE (Q-022) Barren in der Ablage
	},

	-- Freischaltung der Minen über das Level (docs/12 §22). Mine 001 ist immer frei.
	-- Minen ohne Level-Eintrag sind noch nicht gebalanced und bleiben gesperrt.
	MineUnlocks = {
		mine_001 = { RequiredLevel = 1 },
		mine_002 = { RequiredLevel = 3 }, -- Felix (D-017)
		-- Ab Mine 03 zusätzlich Kauf (MinePrice). Level: Vorschlag Q-022
		mine_003 = { RequiredLevel = 6 }, -- TODO_BALANCE (Q-022) Copper
		mine_004 = { RequiredLevel = 8 }, -- TODO_BALANCE (Q-022) Copper
		mine_005 = { RequiredLevel = 10 }, -- TODO_BALANCE (Q-022) Tin
		mine_006 = { RequiredLevel = 12 }, -- TODO_BALANCE (Q-022) Tin
		mine_007 = { RequiredLevel = 14 }, -- TODO_BALANCE (Q-022) Iron
		mine_008 = { RequiredLevel = 16 }, -- TODO_BALANCE (Q-022) Iron
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
		},
	},

	-- Geldpreis der Minen ab Mine 03 zusätzlich zum Level (D-017, D-019):
	-- Preis(n) = BasePrice * Growth ^ (n - FirstPaidMine), auf ganze Dollar gerundet.
	-- Mine 03 = $3.000, jede weitere Mine +50 %.
	MinePrice = {
		FirstPaidMine = 3,
		BasePrice = 3000,
		Growth = 1.5,
	},
}

return table.freeze(BalanceConfig)
