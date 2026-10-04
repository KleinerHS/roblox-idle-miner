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
	} :: { [string]: { SellValue: number, XPValue: number } },

	-- Freischaltung der Minen über das Level (docs/12 §22). Mine 001 ist immer frei.
	-- Minen ohne Level-Eintrag sind noch nicht gebalanced und bleiben gesperrt.
	MineUnlocks = {
		mine_001 = { RequiredLevel = 1 },
		mine_002 = { RequiredLevel = 3 }, -- Felix (D-017)
	} :: { [string]: { RequiredLevel: number } },

	-- Firmenlager (docs/06 §14): Startkapazität 1.000 über alle Materialien (fest).
	Storage = {
		StartCapacity = 1000,
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

	-- Elevator-Materialtransport (docs/06 §9–11). Upgrades folgen mit der Elevator-App (4c).
	Elevator = {
		StartCapacity = 100, -- Felix (D-021) Erz pro Fahrt
		CycleSeconds = 10, -- Felix (D-021) eine Fahrt alle n Sekunden
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
