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
	UnlockCost: number?,
}

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
			UnlockCost = if unlock then unlock.UnlockCost else nil,
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

return table.freeze(Mines)
