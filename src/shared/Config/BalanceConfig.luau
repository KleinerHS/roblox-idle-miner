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
