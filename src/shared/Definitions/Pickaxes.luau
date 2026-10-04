--!strict
-- Spitzhacken (docs/10 §44). Weitere Stufen kommen mit dem Equipment Shop (Phase 3).
-- PersistenceClass: wie das Item bei Prestige behandelt wird. Pickaxes, Backpacks und
-- Fahrzeuge bleiben erhalten (D-012), Drills/Maschinen sind "Progression".

export type PersistenceClass = "Progression" | "Permanent" | "RobuxEntitlement"

export type PickaxeDefinition = {
	Id: string,
	DisplayName: string,
	RequiredLevel: number,
	Price: number,
	-- Erzmenge pro gültigem Hit
	MiningPower: number,
	-- Hits pro Sekunde
	MiningSpeed: number,
	PersistenceClass: PersistenceClass,
}

local list: { PickaxeDefinition } = {
	{
		Id = "pickaxe_basic",
		DisplayName = "Starter Pickaxe",
		RequiredLevel = 1,
		Price = 0,
		MiningPower = 1, -- TODO_BALANCE (Richtung laut docs/20: 1–2 Erz pro Hit)
		MiningSpeed = 1, -- TODO_BALANCE
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
}

local byId: { [string]: PickaxeDefinition } = {}
for _, def in list do
	assert(byId[def.Id] == nil, `Doppelte Pickaxe-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Pickaxes = {
	List = table.freeze(list),
	ById = table.freeze(byId),
	StarterId = "pickaxe_basic",
}

function Pickaxes.Get(id: string): PickaxeDefinition?
	return byId[id]
end

return table.freeze(Pickaxes)
