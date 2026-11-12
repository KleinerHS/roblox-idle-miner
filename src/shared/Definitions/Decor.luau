--!strict
-- Deko rund um die Halle (Felix 2026-11-12, D-091): nur durch Kauf, der Reihe nach über einen
-- Kaufknopf auf dem Vorplatz, sobald die Hallenwände stehen. Zäune, Vorplatz, Wege und Schotter
-- gehören zum Grundstück und sind immer da. Besitz wie ein Gebäude in PlayerData.Buildings[Id]
-- (Prestige setzt ihn wie alle Gebäude zurück).
-- Items = Namensmuster (Lua-Pattern, ganzer Name) der Kinder des Ordners "Exterior" eines Plots.

export type DecorDefinition = {
	Id: string,
	DisplayName: string,
	Price: number,
	Items: { string },
}

local REQUIRES = "build_walls"

local list: { DecorDefinition } = {
	{ Id = "decor_flowerbeds", DisplayName = "Flower Beds", Price = 150, Items = { "^BedFront" } },
	{ Id = "decor_lamps", DisplayName = "Forecourt Lamps", Price = 250, Items = { "^ForecourtLamp" } },
	{ Id = "decor_pines_front", DisplayName = "Front Pines", Price = 400, Items = { "^Pine1%d%d$" } },
	{ Id = "decor_pine_row", DisplayName = "Pine Row", Price = 600, Items = { "^Pine2%d%d$" } },
	{ Id = "decor_yard_storage", DisplayName = "Yard Storage", Price = 900, Items = { "^YardLeftCrate", "^YardRack" } },
	{ Id = "decor_side_storage", DisplayName = "Side Storage", Price = 1300, Items = { "^SideRack", "^SideBarrel", "^SideTires" } },
	{ Id = "decor_rocks", DisplayName = "Rocks", Price = 1900, Items = { "^SideRock" } },
	{ Id = "decor_guard_booth", DisplayName = "Guard Booth", Price = 2700, Items = { "^GuardBooth$" } },
	{ Id = "decor_forklift", DisplayName = "Forklift", Price = 3800, Items = { "^Forklift$" } },
	{ Id = "decor_container", DisplayName = "Container & AC Units", Price = 5400, Items = { "^ShippingContainer$", "^ACUnit" } },
}

local byId: { [string]: DecorDefinition } = {}
for _, def in list do
	assert(byId[def.Id] == nil, `Doppelte Decor-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Decor = {
	List = table.freeze(list),
	ById = table.freeze(byId),
	-- Bauschritt, ab dem Deko kaufbar ist
	Requires = REQUIRES,
}

-- Zu welchem Paket gehört ein Exterior-Kind? (nil = gehört immer zum Grundstück)
function Decor.ForItem(name: string): DecorDefinition?
	for _, def in list do
		for _, pattern in def.Items do
			if string.find(name, pattern) then
				return def
			end
		end
	end
	return nil
end

-- Nächstes noch nicht gekauftes Paket (nil = alles gekauft)
function Decor.GetNext(buildings: { [string]: boolean }): DecorDefinition?
	for _, def in list do
		if not buildings[def.Id] then
			return def
		end
	end
	return nil
end

return table.freeze(Decor)
