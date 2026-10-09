--!strict
-- Förderbänder (docs/06 §22–27, docs/10 §34–38, docs/00 §18, D-024). Gekauft im Machine-Shop,
-- im Inventar, eingesetzt an festen Förderband-Plätzen in der Halle. Kein freies Bauen.
-- Feste Strecken (LayoutConfig.ConveyorPaths):
--   StorageToSmelter – schmelzbares Erz vom Lager in den Schmelzer-Trichter
--   SmelterToStorage – fertige Barren aus der Ablage zurück ins Lager
-- Throughput = Einheiten pro Minute. Werte: Q-024 / D-031 (Felix). MK2 und MK3 kommen erst,
-- wenn es Schmelzer-Upgrades gibt.

local Pickaxes = require(script.Parent.Pickaxes)

export type ConveyorDefinition = {
	Id: string,
	DisplayName: string,
	Tier: number,
	RequiredLevel: number,
	Price: number,
	Throughput: number,
	-- Farbe der Seitenwangen (sichtbare Stufe)
	FrameColor: Color3,
	PersistenceClass: Pickaxes.PersistenceClass,
}

local list: { ConveyorDefinition } = {
	{
		Id = "conveyor_mk1",
		DisplayName = "Conveyor MK1",
		Tier = 1,
		RequiredLevel = 12, -- Q-024 (Felix, D-031)
		Price = 15000, -- Q-024
		Throughput = 120, -- Q-024
		FrameColor = Color3.fromRGB(236, 182, 40),
		PersistenceClass = "Progression",
	},
}

local byId: { [string]: ConveyorDefinition } = {}
for _, def in list do
	assert(byId[def.Id] == nil, `Doppelte Conveyor-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Conveyors = {
	List = table.freeze(list),
	ById = table.freeze(byId),
	-- Feste Plätze (Reihenfolge = Anzeige)
	Slots = table.freeze({ "StorageToSmelter", "SmelterToStorage" }),
	SlotNames = table.freeze({
		StorageToSmelter = "Storage → Smelter",
		SmelterToStorage = "Smelter → Storage",
	}),
}

function Conveyors.Get(id: string): ConveyorDefinition?
	return byId[id]
end

function Conveyors.IsSlot(slot: string): boolean
	return Conveyors.SlotNames[slot] ~= nil
end

return table.freeze(Conveyors)
