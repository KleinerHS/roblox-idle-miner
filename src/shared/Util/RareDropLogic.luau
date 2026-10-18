--!strict
-- Rare-Drop-Regeln (docs/03 §7, docs/11 §18–21, D-006/D-007). Reine Funktionen, damit Server und
-- Tests dieselbe Logik nutzen. Der Client würfelt nie selbst (docs/09 §18).

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)

local RareDropLogic = {}

export type RareResult = { Kind: "Amount", Multiplier: number } | { Kind: "Ore", TierOffset: number }

local cfg = BalanceConfig.RareDrops
local luck = BalanceConfig.Luck

-- Chance je Hit mit Mining-Luck-Level
function RareDropLogic.Chance(luckLevel: number): number
	return cfg.BaseChance * (1 + math.clamp(luckLevel, 0, luck.MaxLevel) * luck.ChanceBonusPerLevel)
end

local function weighted(rng: Random, weights: { number }): number
	local total = 0
	for _, w in weights do
		total += w
	end
	local r = rng:NextNumber() * total
	for i, w in weights do
		r -= w
		if r <= 0 then
			return i
		end
	end
	return #weights
end

-- Würfelt einen Hit. `maxTierOffset` = wie viele bessere Erzstufen es überhaupt noch gibt.
function RareDropLogic.Roll(rng: Random, luckLevel: number, maxTierOffset: number): RareResult?
	if rng:NextNumber() >= RareDropLogic.Chance(luckLevel) then
		return nil
	end
	local offsets = math.min(#cfg.TierWeights, maxTierOffset)
	if offsets > 0 and rng:NextNumber() < cfg.OreShare then
		local weights = table.move(cfg.TierWeights, 1, offsets, 1, {})
		return { Kind = "Ore", TierOffset = weighted(rng, weights) }
	end
	-- Index 1 = ×2 … Index 9 = ×10 (Gesamtmenge des Hits)
	return { Kind = "Amount", Multiplier = weighted(rng, cfg.MultiplierWeights) + 1 }
end

-- Preis und Mindest-Level des nächsten Luck-Levels (nil = Maximum erreicht)
function RareDropLogic.NextLuck(level: number): (number?, number?)
	if level >= luck.MaxLevel then
		return nil, nil
	end
	local n = level + 1
	return math.floor(luck.BasePrice * luck.PriceGrowth ^ (n - 1) + 0.5), luck.RequiredLevelStep * n
end

return table.freeze(RareDropLogic)
