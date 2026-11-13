--!strict
-- Deko rund um die Halle und in der Garage (Felix 2026-11-12/13, D-091, D-093): nur durch Kauf, der
-- Reihe nach über einen Kaufknopf auf dem Vorplatz, sobald die Hallenwände stehen. Zäune, Vorplatz,
-- Wege, Schotter und die Technik der Garage (Verladeturm, Stellplätze, Leuchtring) gehören zum
-- Grundstück. Besitz wie ein Gebäude in PlayerData.Buildings[Id] (Prestige setzt ihn zurück).
--
-- Area "Exterior": Kinder des Ordners "Exterior" eines Plots.
-- Area "Garage":   Kinder der Ordner "Decoration" und "Workshop" im Garagen-Modell.
-- Items = Namensmuster (Lua-Pattern) der jeweiligen Kinder.

export type DecorArea = "Exterior" | "Garage"
export type DecorDefinition = {
	Id: string,
	DisplayName: string,
	Price: number,
	Area: DecorArea,
	Items: { string },
}

local REQUIRES = "build_walls"

local list: { DecorDefinition } = {
	{ Id = "decor_flowerbeds", DisplayName = "Flower Beds", Price = 150, Area = "Exterior", Items = { "^BedFront" } },
	{ Id = "decor_lamps", DisplayName = "Forecourt Lamps", Price = 250, Area = "Exterior", Items = { "^ForecourtLamp" } },
	{ Id = "decor_pines_front", DisplayName = "Front Pines", Price = 400, Area = "Exterior", Items = { "^Pine1%d%d$" } },
	-- Garagen-Deko (D-093), Preise in die Reihe einsortiert
	{
		Id = "decor_garage_pallets",
		DisplayName = "Garage Pallets",
		Price = 500,
		Area = "Garage",
		Items = { "^EmptyPallet", "^FloorPallet", "^DrumPallet$", "^SpillPallet$", "^LooseDrum", "^Extinguisher$" },
	},
	{ Id = "decor_pine_row", DisplayName = "Pine Row", Price = 600, Area = "Exterior", Items = { "^Pine2%d%d$" } },
	{ Id = "decor_yard_storage", DisplayName = "Yard Storage", Price = 900, Area = "Exterior", Items = { "^YardLeftCrate", "^YardRack" } },
	{ Id = "decor_garage_racks", DisplayName = "Garage Racks", Price = 1100, Area = "Garage", Items = { "^RackFront$", "^RackSide$" } },
	{ Id = "decor_side_storage", DisplayName = "Side Storage", Price = 1300, Area = "Exterior", Items = { "^SideRack", "^SideBarrel", "^SideTires" } },
	{
		Id = "decor_workshop",
		DisplayName = "Garage Workshop",
		Price = 1600,
		Area = "Garage",
		Items = { "^Workbench$", "^PartsShelf$", "^OilDrums$", "^LaneCones$", "^GarageOpen$", "^GarageWrapped$", "^GaragePalletTruck$" },
	},
	{ Id = "decor_rocks", DisplayName = "Rocks", Price = 1900, Area = "Exterior", Items = { "^SideRock" } },
	{ Id = "decor_guard_booth", DisplayName = "Guard Booth", Price = 2700, Area = "Exterior", Items = { "^GuardBooth$" } },
	{ Id = "decor_forklift", DisplayName = "Forklift", Price = 3800, Area = "Exterior", Items = { "^Forklift$" } },
	{ Id = "decor_container", DisplayName = "Container & AC Units", Price = 5400, Area = "Exterior", Items = { "^ShippingContainer$", "^ACUnit" } },
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
	-- Ordner im Garagen-Modell, deren Kinder Deko sind
	GarageFolders = table.freeze({ "Decoration", "Workshop" }),
}

-- Zu welchem Paket gehört ein Teil dieses Bereichs? (nil = gehört immer zum Grundstück)
function Decor.ForItem(name: string, area: DecorArea): DecorDefinition?
	for _, def in list do
		if def.Area == area then
			for _, pattern in def.Items do
				if string.find(name, pattern) then
					return def
				end
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
