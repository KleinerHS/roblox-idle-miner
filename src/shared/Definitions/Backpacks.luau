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
	-- false = im Shop sichtbar, aber noch nicht kaufbar ("Coming soon", Werte offen)
	Available: boolean?,
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
	-- Stufen 2–3: Platzhalter aus Q-015 (Default bis zur Antwort), alle Zahlen TODO_BALANCE
	{
		Id = "backpack_reinforced",
		DisplayName = "Reinforced Backpack",
		RequiredLevel = 2, -- TODO_BALANCE
		Price = 1000, -- Felix (D-017)
		Capacity = 1000, -- Felix (D-017)
		PersistenceClass = "Permanent",
	},
	{
		Id = "backpack_cargo",
		DisplayName = "Cargo Pack",
		RequiredLevel = 4, -- Felix (D-019)
		Price = 3500, -- Felix (D-019)
		Capacity = 2500, -- Felix (D-019)
		PersistenceClass = "Permanent",
	},
	-- Stufen 4–7 (Phase 12b, Startwert D-036): Preis ≈ 6.000 × Erzwert auf diesem Level.
	-- Bewusst nicht größer als 15.000, damit der Rucksack kein Fahrzeug ersetzt.
	{
		Id = "backpack_expedition",
		DisplayName = "Expedition Pack",
		RequiredLevel = 12, -- Startwert (D-036)
		Price = 18000, -- Startwert (D-036)
		Capacity = 5000, -- Startwert (D-036)
		PersistenceClass = "Permanent",
	},
	{
		Id = "backpack_heavy",
		DisplayName = "Heavy Duty Pack",
		RequiredLevel = 30, -- Startwert (D-036)
		Price = 1300000, -- Startwert (D-036)
		Capacity = 7500, -- Startwert (D-036)
		PersistenceClass = "Permanent",
	},
	{
		Id = "backpack_titan",
		DisplayName = "Titan Pack",
		RequiredLevel = 55, -- Startwert (D-036)
		Price = 140000000, -- Startwert (D-036)
		Capacity = 10000, -- Startwert (D-036)
		PersistenceClass = "Permanent",
	},
	{
		Id = "backpack_colossus",
		DisplayName = "Colossus Pack",
		RequiredLevel = 80, -- Startwert (D-036)
		Price = 7200000000, -- Startwert (D-036)
		Capacity = 15000, -- Startwert (D-036)
		PersistenceClass = "Permanent",
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
