--!strict
-- Rucksäcke (docs/10 §45). Seit D-074 (Felix 2026-10-28) 22 Stufen aus Felix' Rucksack-Pack, 3D-Vorlagen
-- in ServerStorage.Vendor.Backpacks (Name = ID). Erst die 9 Stufen ohne Leuchten, dann die 13
-- leuchtenden. Werte seit dem Neubalancing vom 2026-11-11 (D-087) aus Felix' Balancing-Datei.
-- PersistenceClass siehe Pickaxes.luau (D-012).

local Pickaxes = require(script.Parent.Pickaxes)
local ContentCurve = require(script.Parent.ContentCurve)

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
	-- Modell hat leuchtende Teile (FX_Emissive)
	Glow: boolean?,
}

local list: { BackpackDefinition } = {
	{
		Id = "backpack_field_pouch",
		DisplayName = "Field Pouch",
		RequiredLevel = 1, -- Balancing 2026-11-11 (D-087)
		Price = 0, -- Balancing 2026-11-11 (D-087)
		Capacity = 2400, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_leather_satchel",
		DisplayName = "Leather Satchel",
		RequiredLevel = 2, -- Balancing 2026-11-11 (D-087)
		Price = 120, -- Balancing 2026-11-11 (D-087)
		Capacity = 3600, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_copper_prospector",
		DisplayName = "Copper Prospector",
		RequiredLevel = 3, -- Balancing 2026-11-11 (D-087)
		Price = 700, -- Balancing 2026-11-11 (D-087)
		Capacity = 5000, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_bronze_drill",
		DisplayName = "Bronze Drill Pack",
		RequiredLevel = 8, -- Balancing 2026-11-11 (D-087)
		Price = 1400, -- Balancing 2026-11-11 (D-087)
		Capacity = 6400, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_iron_hauler",
		DisplayName = "Iron Hauler",
		RequiredLevel = 13, -- Balancing 2026-11-11 (D-087)
		Price = 3300, -- Balancing 2026-11-11 (D-087)
		Capacity = 7900, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_steel_surveyor",
		DisplayName = "Steel Surveyor",
		RequiredLevel = 18, -- Balancing 2026-11-11 (D-087)
		Price = 6100, -- Balancing 2026-11-11 (D-087)
		Capacity = 9500, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_gold_vault",
		DisplayName = "Gold Vault",
		RequiredLevel = 22, -- Balancing 2026-11-11 (D-087)
		Price = 11000, -- Balancing 2026-11-11 (D-087)
		Capacity = 11100, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_blackstone_safe",
		DisplayName = "Blackstone Safe",
		RequiredLevel = 27, -- Balancing 2026-11-11 (D-087)
		Price = 18000, -- Balancing 2026-11-11 (D-087)
		Capacity = 12900, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_obsidian_case",
		DisplayName = "Obsidian Case",
		RequiredLevel = 32, -- Balancing 2026-11-11 (D-087)
		Price = 41000, -- Balancing 2026-11-11 (D-087)
		Capacity = 16500, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_verdant_reliquary",
		DisplayName = "Verdant Reliquary",
		RequiredLevel = 37, -- Balancing 2026-11-11 (D-087)
		Price = 78000, -- Balancing 2026-11-11 (D-087)
		Capacity = 19000, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_toxic_extractor",
		DisplayName = "Toxic Extractor",
		RequiredLevel = 42, -- Balancing 2026-11-11 (D-087)
		Price = 160000, -- Balancing 2026-11-11 (D-087)
		Capacity = 21900, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_ember_furnace",
		DisplayName = "Ember Furnace",
		RequiredLevel = 47, -- Balancing 2026-11-11 (D-087)
		Price = 230000, -- Balancing 2026-11-11 (D-087)
		Capacity = 25200, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_lava_crucible",
		DisplayName = "Lava Crucible",
		RequiredLevel = 51, -- Balancing 2026-11-11 (D-087)
		Price = 320000, -- Balancing 2026-11-11 (D-087)
		Capacity = 29000, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_frost_archive",
		DisplayName = "Frost Archive",
		RequiredLevel = 56, -- Balancing 2026-11-11 (D-087)
		Price = 1100000, -- Balancing 2026-11-11 (D-087)
		Capacity = 33400, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_tidal_prism",
		DisplayName = "Tidal Prism",
		RequiredLevel = 61, -- Balancing 2026-11-11 (D-087)
		Price = 2200000, -- Balancing 2026-11-11 (D-087)
		Capacity = 38500, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_storm_reactor",
		DisplayName = "Storm Reactor",
		RequiredLevel = 66, -- Balancing 2026-11-11 (D-087)
		Price = 6300000, -- Balancing 2026-11-11 (D-087)
		Capacity = 44300, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_thunder_coil",
		DisplayName = "Thunder Coil",
		RequiredLevel = 71, -- Balancing 2026-11-11 (D-087)
		Price = 10000000, -- Balancing 2026-11-11 (D-087)
		Capacity = 51000, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_amethyst_sanctum",
		DisplayName = "Amethyst Sanctum",
		RequiredLevel = 76, -- Balancing 2026-11-11 (D-087)
		Price = 33000000, -- Balancing 2026-11-11 (D-087)
		Capacity = 58700, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_lunar_oracle",
		DisplayName = "Lunar Oracle",
		RequiredLevel = 80, -- Balancing 2026-11-11 (D-087)
		Price = 42000000, -- Balancing 2026-11-11 (D-087)
		Capacity = 67600, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_solar_sovereign",
		DisplayName = "Solar Sovereign",
		RequiredLevel = 85, -- Balancing 2026-11-11 (D-087)
		Price = 84000000, -- Balancing 2026-11-11 (D-087)
		Capacity = 77800, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_royal_crystal",
		DisplayName = "Royal Crystal",
		RequiredLevel = 90, -- Balancing 2026-11-11 (D-087)
		Price = 160000000, -- Balancing 2026-11-11 (D-087)
		Capacity = 89500, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_void_emperor",
		DisplayName = "Void Emperor",
		RequiredLevel = 95, -- Balancing 2026-11-11 (D-087)
		Price = 390000000, -- Balancing 2026-11-11 (D-087)
		Capacity = 103000, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
}

local byId: { [string]: BackpackDefinition } = {}
for _, def in list do
	-- Spätspiel-Aufschlag ab Level LatePriceStartLevel (D-046)
	def.Price = ContentCurve.latePrice(def.Price, def.RequiredLevel)
	assert(byId[def.Id] == nil, `Doppelte Backpack-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Backpacks = {
	List = table.freeze(list),
	ById = table.freeze(byId),
	StarterId = "backpack_field_pouch",
	-- Alte IDs (vor D-074) → neue Stufe mit denselben Werten
	LegacyIds = table.freeze({
		backpack_starter = "backpack_field_pouch",
		backpack_reinforced = "backpack_copper_prospector",
		backpack_cargo = "backpack_iron_hauler",
		backpack_expedition = "backpack_blackstone_safe",
		backpack_heavy = "backpack_ember_furnace",
		backpack_titan = "backpack_thunder_coil",
		backpack_colossus = "backpack_void_emperor",
	}),
}

function Backpacks.Get(id: string): BackpackDefinition?
	return byId[id]
end

return table.freeze(Backpacks)
