--!strict
-- Wachstumskurven für Inhalte ohne festen Einzelwert (Phase 12, docs/03 §12–13, Q-026).
-- Bestätigte Einzelwerte in BalanceConfig (OreValues, BarValues, MineUnlocks) haben immer
-- Vorrang; die Kurve füllt nur die Lücken bis Mine 100 / Erz-Tier 50. Alle Parameter stehen in
-- BalanceConfig.ContentCurve (TODO_BALANCE), damit Phase 14 nur dort dreht.
--
--   Erzwert:   ab Tier 5 Vorgänger × Wachstum (früh stärker, später schwächer – keine
--              absurden Zahlen trotz „ungefähr Verdopplung“), auf 2 Stellen gerundet
--   Erz-XP:    folgt einer festen Bezugskurve (D-042): Bezugs-XP des Levels der ersten Mine / Teiler,
--              steigt mindestens um 1 je Tier
--   Barren:    aus OrePerBar Erz, Wert × BarValueFactor, XP × BarXPFactor
--   Minen:     Level linear von Mine 08 (Level 16) bis Mine 100 (Level 100),
--              Preis ab Mine 09 = Vielfaches des Erzwerts, zweite Mine einer Erzart teurer

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)

local cfg = BalanceConfig.ContentCurve

local ContentCurve = {}

-- Auf zwei signifikante Stellen runden (z. B. 1234 → 1200), kleine Werte ganzzahlig
function ContentCurve.nice(value: number): number
	if value < 100 then
		return math.max(1, math.floor(value + 0.5))
	end
	local magnitude = 10 ^ (math.floor(math.log10(value)) - 1)
	return math.floor(value / magnitude + 0.5) * magnitude
end

-- Mindest-Level einer Mine (nur für Minen ohne Eintrag in BalanceConfig.MineUnlocks)
function ContentCurve.mineLevel(number: number): number
	local a, b = cfg.LevelAnchorMine, cfg.LastMine
	local la, lb = cfg.LevelAnchorLevel, cfg.LastMineLevel
	return la + math.floor((number - a) * (lb - la) / (b - a) + 0.5)
end

-- Unrundete Erzwerte je Tier (Tier 1 = Coal), ausgehend vom letzten festen Wert
local rawValue: { [number]: number } = {}
local function oreRaw(tier: number, fixed: (number) -> number?): number
	if rawValue[tier] then
		return rawValue[tier]
	end
	local value = fixed(tier)
	if value == nil then
		local growth = if tier <= cfg.EarlyUntilTier then cfg.OreValueGrowthEarly else cfg.OreValueGrowthLate
		value = oreRaw(tier - 1, fixed) * growth
	end
	rawValue[tier] = value :: number
	return value :: number
end

-- Verkaufswert und XP für ein Erz-Tier. `fixed(tier)` liefert bestätigte Werte (oder nil).
function ContentCurve.oreValues(tier: number, fixedSell: (number) -> number?, fixedXP: (number) -> number?): (number, number)
	local sell = fixedSell(tier) or ContentCurve.nice(oreRaw(tier, fixedSell))
	local xp = fixedXP(tier)
	if xp == nil then
		local previous = if tier > 1 then select(2, ContentCurve.oreValues(tier - 1, fixedSell, fixedXP)) else 0
		local firstMine = (tier - 1) * 2 + 1
		-- Bezugskurve fest (D-042): unabhängig von BalanceConfig.Leveling, sonst hebt eine steilere
		-- Level-Kurve sich über mehr Erz-XP wieder auf
		local refXP = math.max(1, math.floor(cfg.XPReferenceBase * ContentCurve.mineLevel(firstMine) ^ cfg.XPReferenceExponent))
		local fromLevel = math.floor(refXP / cfg.XPDivisor + 0.5)
		xp = math.max(previous + 1, fromLevel)
	end
	return sell, xp :: number
end

-- Barrenwert aus dem Erzwert
function ContentCurve.barValues(oreSell: number, oreXP: number): (number, number)
	local orePerBar = BalanceConfig.Smelter.OrePerBar
	return ContentCurve.nice(oreSell * orePerBar * cfg.BarValueFactor), math.floor(oreXP * orePerBar * cfg.BarXPFactor + 0.5)
end

-- Spätspiel-Aufschlag (D-046): 1 bis LatePriceStartLevel, danach × LatePriceGrowth je Level
function ContentCurve.latePriceFactor(requiredLevel: number): number
	return cfg.LatePriceGrowth ^ math.max(0, requiredLevel - cfg.LatePriceStartLevel)
end

-- Preis mit Spätspiel-Aufschlag (unverändert bis zum Startlevel)
function ContentCurve.latePrice(price: number, requiredLevel: number): number
	local factor = ContentCurve.latePriceFactor(requiredLevel)
	return if factor == 1 then price else ContentCurve.nice(price * factor)
end

-- Minenpreis ab Mine 09 (Mine 03–08: D-019), mit Spätspiel-Aufschlag (D-046)
function ContentCurve.minePrice(number: number, oreSell: number): number
	local second = number % 2 == 0
	local base = oreSell * cfg.MinePriceOreMultiple * (if second then cfg.SecondMinePriceFactor else 1)
	return ContentCurve.nice(base * ContentCurve.latePriceFactor(ContentCurve.mineLevel(number)))
end

return table.freeze(ContentCurve)
