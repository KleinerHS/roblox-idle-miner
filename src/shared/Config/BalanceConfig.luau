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

	-- Freischaltung der Minen. Mine 001 ist immer frei. Weitere Minen ohne Eintrag
	-- sind noch nicht gebalanced und gesperrt.
	MineUnlocks = {
		mine_001 = { RequiredLevel = 1, UnlockCost = 0 },
	} :: { [string]: { RequiredLevel: number, UnlockCost: number } },
}

return table.freeze(BalanceConfig)
