--!strict
-- Kisten-Lager (Phase 13b-2, Felix 2026-10-10): Das Firmenlager und die beiden Ofen-Lager bestehen
-- aus Palettenboxen. Jede Kiste fasst CrateSize Einheiten EINER Materialsorte. Eine Sorte belegt
-- also ceil(Menge / CrateSize) Kisten; Platz für eine Sorte hängt davon ab, wie viele Kisten die
-- anderen Sorten schon belegen. Gemeinsame Regeln für Server (Logik) und Client (Anzeige).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BalanceConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.BalanceConfig)
local Types = require(ReplicatedStorage:WaitForChild("Shared").Types)

local CrateLogic = {}

CrateLogic.Size = BalanceConfig.Storage.CrateSize

-- Kisten, die eine Menge einer Sorte belegt
function CrateLogic.cratesFor(amount: number): number
	if amount <= 0 then
		return 0
	end
	return math.ceil(amount / CrateLogic.Size)
end

-- Belegte Kisten über alle Sorten
function CrateLogic.used(items: Types.ItemCounts): number
	local total = 0
	for _, amount in items do
		total += CrateLogic.cratesFor(amount)
	end
	return total
end

-- Wie viel von `id` passt noch hinein (bei `crates` Kisten insgesamt)?
function CrateLogic.freeFor(items: Types.ItemCounts, crates: number, id: string): number
	local own = items[id] or 0
	local others = CrateLogic.used(items) - CrateLogic.cratesFor(own)
	return math.max(0, (crates - others) * CrateLogic.Size - own)
end

-- Passen alle Zugänge gleichzeitig hinein (z. B. Handel, Rucksack abladen)?
function CrateLogic.fits(items: Types.ItemCounts, crates: number, additions: { [string]: number }): boolean
	local merged: { [string]: number } = table.clone(items)
	for id, n in additions do
		merged[id] = (merged[id] or 0) + n
	end
	return CrateLogic.used(merged) <= crates
end

-- Ist kein Platz mehr für irgendetwas Neues? (alle Kisten belegt und voll)
function CrateLogic.isFull(items: Types.ItemCounts, crates: number): boolean
	if CrateLogic.used(items) < crates then
		return false
	end
	for _, amount in items do
		if amount % CrateLogic.Size ~= 0 then
			return false
		end
	end
	return true
end

-- Preis der n-ten Kiste des Firmenlagers (Felix: 1. $100, 2. $500, 3. $1.000, danach ×1,5)
function CrateLogic.price(n: number): number
	local cfg = BalanceConfig.Storage
	if n <= #cfg.CratePrices then
		return cfg.CratePrices[n]
	end
	local last = cfg.CratePrices[#cfg.CratePrices]
	return math.floor(last * cfg.CrateGrowth ^ (n - #cfg.CratePrices) + 0.5)
end

return table.freeze(CrateLogic)
