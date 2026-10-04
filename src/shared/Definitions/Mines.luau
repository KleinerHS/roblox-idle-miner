--!strict
-- Minen 001–100, abgeleitet aus Ores (zwei Minen pro Erz, docs/03 §2).
-- IDs: mine_001 … mine_100. Freischaltung aus BalanceConfig.MineUnlocks.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)
local Ores = require(script.Parent.Ores)

export type MineDefinition = {
	Id: string,
	Number: number,
	OreId: string,
	-- nil = noch nicht gebalanced (TODO_BALANCE), Mine bleibt gesperrt
	RequiredLevel: number?,
	-- Geldpreis zusätzlich zum Level (ab Mine 03, D-017/D-019), 0 = kostenlos
	UnlockCost: number,
}

local function unlockCost(number: number): number
	local price = BalanceConfig.MinePrice
	if number < price.FirstPaidMine then
		return 0
	end
	return math.floor(price.BasePrice * price.Growth ^ (number - price.FirstPaidMine) + 0.5)
end

local list: { MineDefinition } = {}
local byId: { [string]: MineDefinition } = {}

for _, ore in Ores.List do
	for number = ore.MineStart, ore.MineEnd do
		local id = string.format("mine_%03d", number)
		local unlock = BalanceConfig.MineUnlocks[id]
		local mine: MineDefinition = table.freeze({
			Id = id,
			Number = number,
			OreId = ore.Id,
			RequiredLevel = if unlock then unlock.RequiredLevel else nil,
			UnlockCost = unlockCost(number),
		})
		list[number] = mine
		byId[id] = mine
	end
end

local Mines = {
	List = table.freeze(list),
	ById = table.freeze(byId),
	Count = #list,
	StartMineId = "mine_001",
}

function Mines.Get(id: string): MineDefinition?
	return byId[id]
end

function Mines.GetByNumber(number: number): MineDefinition?
	return list[number]
end

-- Minen werden über das Mining Level freigeschaltet (docs/12 §22). Ohne gebalanctes
-- RequiredLevel bleibt eine Mine gesperrt.
function Mines.IsAccessible(mine: MineDefinition, miningLevel: number): boolean
	return mine.RequiredLevel ~= nil and miningLevel >= mine.RequiredLevel
end

-- "MINE 01" … "MINE 100"
function Mines.Label(mine: MineDefinition): string
	return string.format("MINE %02d", mine.Number)
end

-- Felsfarbe: bis ca. Mine 30 grau, danach zunehmend dunkler (docs/19 §5).
local ROCK_LIGHT = Color3.fromRGB(74, 72, 70)
local ROCK_DARK = Color3.fromRGB(38, 36, 36)
function Mines.RockColor(mine: MineDefinition): Color3
	if mine.Number <= 30 then
		return ROCK_LIGHT
	end
	local t = math.clamp((mine.Number - 30) / 70, 0, 1)
	return ROCK_LIGHT:Lerp(ROCK_DARK, t)
end

return table.freeze(Mines)
