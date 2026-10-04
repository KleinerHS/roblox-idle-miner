--!strict
-- Rucksäcke (docs/10 §45). Weitere Stufen kommen mit dem Equipment Shop (Phase 3).
-- PersistenceClass siehe Pickaxes.luau (D-012: Backpacks bleiben bei Prestige).

local Pickaxes = require(script.Parent.Pickaxes)

export type BackpackDefinition = {
	Id: string,
	DisplayName: string,
	RequiredLevel: number,
	Price: number,
	-- Gesamtkapazität über alle Erzarten
	Capacity: number,
	PersistenceClass: Pickaxes.PersistenceClass,
}

local list: { BackpackDefinition } = {
	{
		Id = "backpack_starter",
		DisplayName = "Starter Backpack",
		RequiredLevel = 1,
		Price = 0,
		Capacity = 100, -- TODO_BALANCE (Beispielwert aus docs/10 §45)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
}

local byId: { [string]: BackpackDefinition } = {}
for _, def in list do
	assert(byId[def.Id] == nil, `Doppelte Backpack-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Backpacks = {
	List = table.freeze(list),
	ById = table.freeze(byId),
	StarterId = "backpack_starter",
}

function Backpacks.Get(id: string): BackpackDefinition?
	return byId[id]
end

return table.freeze(Backpacks)
