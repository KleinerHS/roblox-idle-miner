--!strict
-- Rare-Drop-Regeln (docs/03 §7, docs/11 §18–21, D-006/D-007, seit D-088 mit Sonderfunden).
-- Reine Funktionen, damit Server und Tests dieselbe Logik nutzen. Der Client würfelt nie selbst
-- (docs/09 §18).
--
-- Ein exklusiver Wurf je gültigem Hit (D-088): von der seltensten Möglichkeit an
--   Sonderfund ancient → radiant → pristine → nächstes Erz (1–4 Stufen) → Mengen-Bonus → nichts.
-- Jede Chance wird mit dem Luck-Faktor (1 + Stufe × ChanceBonusPerLevel) multipliziert.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)

local RareDropLogic = {}

export type RareResult =
	{ Kind: "Amount", Multiplier: number }
	| { Kind: "Ore", TierOffset: number }
	| { Kind: "Special", Rarity: string }

local cfg = BalanceConfig.RareDrops
local special = BalanceConfig.SpecialFinds
local luck = BalanceConfig.Luck

-- Faktor auf alle Chancen (Stufe 0 = 1)
function RareDropLogic.LuckFactor(luckLevel: number): number
	return 1 + math.clamp(luckLevel, 0, luck.MaxLevel) * luck.ChanceBonusPerLevel
end

-- Chance je Hit auf irgendein Rare Event (Anzeige im Laptop)
function RareDropLogic.Chance(luckLevel: number): number
	local base = cfg.AmountChance + cfg.NextOreChance
	for _, rarity in special.Rarities do
		base += rarity.Chance
	end
	return base * RareDropLogic.LuckFactor(luckLevel)
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
-- `hasSpecial` = ob es für das Erz der Mine Sonderfunde gibt.
function RareDropLogic.Roll(rng: Random, luckLevel: number, maxTierOffset: number, hasSpecial: boolean?): RareResult?
	local factor = RareDropLogic.LuckFactor(luckLevel)
	local r = rng:NextNumber()
	if hasSpecial ~= false then
		for _, rarity in special.Rarities do
			local chance = rarity.Chance * factor
			if r < chance then
				return { Kind = "Special", Rarity = rarity.Id }
			end
			r -= chance
		end
	end
	local offsets = math.min(#cfg.TierWeights, maxTierOffset)
	if offsets > 0 then
		local chance = cfg.NextOreChance * factor
		if r < chance then
			local weights = table.move(cfg.TierWeights, 1, offsets, 1, {})
			return { Kind = "Ore", TierOffset = weighted(rng, weights) }
		end
		r -= chance
	end
	if r < cfg.AmountChance * factor then
		-- Index 1 = ×2 … Index 9 = ×10 (Gesamtmenge des Hits)
		return { Kind = "Amount", Multiplier = weighted(rng, cfg.MultiplierWeights) + 1 }
	end
	return nil
end

-- Preis und Mindest-Level des nächsten Luck-Levels (nil = Maximum erreicht), D-087: Einzelwerte
function RareDropLogic.NextLuck(level: number): (number?, number?)
	if level >= luck.MaxLevel then
		return nil, nil
	end
	local n = level + 1
	return luck.Prices[n], luck.RequiredLevels[n]
end

return table.freeze(RareDropLogic)
