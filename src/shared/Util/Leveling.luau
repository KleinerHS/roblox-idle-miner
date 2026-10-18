--!strict
-- Mining-Level-Berechnung (docs/11 §39–40). Gespeichert werden Level und XP im aktuellen
-- Level, damit eine spätere Änderung der Kurve kein bereits erreichtes Level wegnimmt.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)

local Leveling = {}

-- XP, die nötig ist, um von `level` auf `level + 1` zu kommen. Abschnittsweise Potenzkurve
-- (D-042): in jedem Abschnitt wächst der Bedarf mit (L / Abschnittsanfang)^Exponent.
function Leveling.xpRequired(level: number): number
	local curve = BalanceConfig.Leveling
	local value, from = curve.BaseXP, 1
	for _, segment in curve.Segments do
		local upTo = math.min(level, segment.UpTo)
		value *= (upTo / from) ^ segment.Exponent
		from = upTo
		if level <= segment.UpTo then
			break
		end
	end
	return math.max(1, math.floor(value))
end

-- Addiert XP und verarbeitet Level-Ups. Kein hartes Maximallevel (Level 1000+ möglich).
-- Gibt neues Level, neue XP im Level und die Anzahl gewonnener Level zurück.
function Leveling.addXP(level: number, xp: number, amount: number): (number, number, number)
	assert(amount >= 0, "XP-Menge darf nicht negativ sein")
	local newLevel = level
	local newXP = xp + amount
	local required = Leveling.xpRequired(newLevel)
	while newXP >= required do
		newXP -= required
		newLevel += 1
		required = Leveling.xpRequired(newLevel)
	end
	return newLevel, newXP, newLevel - level
end

return table.freeze(Leveling)
