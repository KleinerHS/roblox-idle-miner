--!strict
-- Rucksäcke (docs/10 §45). Seit D-074 (Felix 2026-10-28) 22 Stufen aus Felix' Rucksack-Pack, 3D-Vorlagen
-- in ServerStorage.Vendor.Backpacks (Name = ID). Erst die 9 Stufen ohne Leuchten, dann die 13
-- leuchtenden. Die früheren Werte (D-017, D-019, D-036) bleiben als Anker auf den Stufen 1, 3, 5, 8,
-- 12, 17 und 22, die Stufen dazwischen sind verteilt (TODO_BALANCE). Höchstens 15.000, damit der
-- Rucksack kein Fahrzeug ersetzt. PersistenceClass siehe Pickaxes.luau (D-012).

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
		RequiredLevel = 1, -- Startwert, vorher backpack_starter
		Price = 0,
		Capacity = 100,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_leather_satchel",
		DisplayName = "Leather Satchel",
		RequiredLevel = 1, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 300,
		Capacity = 500,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_copper_prospector",
		DisplayName = "Copper Prospector",
		RequiredLevel = 2, -- Felix (D-017), vorher backpack_reinforced
		Price = 1000,
		Capacity = 1000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_bronze_drill",
		DisplayName = "Bronze Drill Pack",
		RequiredLevel = 3, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 1900,
		Capacity = 1750,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_iron_hauler",
		DisplayName = "Iron Hauler",
		RequiredLevel = 4, -- Felix (D-019), vorher backpack_cargo
		Price = 3500,
		Capacity = 2500,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_steel_surveyor",
		DisplayName = "Steel Surveyor",
		RequiredLevel = 7, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 6000,
		Capacity = 3300,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_gold_vault",
		DisplayName = "Gold Vault",
		RequiredLevel = 9, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 10500,
		Capacity = 4200,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_blackstone_safe",
		DisplayName = "Blackstone Safe",
		RequiredLevel = 12, -- D-036, vorher backpack_expedition
		Price = 18000,
		Capacity = 5000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_obsidian_case",
		DisplayName = "Obsidian Case",
		RequiredLevel = 16, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 52000,
		Capacity = 5600,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
	},
	{
		Id = "backpack_verdant_reliquary",
		DisplayName = "Verdant Reliquary",
		RequiredLevel = 21, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 150000,
		Capacity = 6200,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_toxic_extractor",
		DisplayName = "Toxic Extractor",
		RequiredLevel = 25, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 450000,
		Capacity = 6900,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_ember_furnace",
		DisplayName = "Ember Furnace",
		RequiredLevel = 30, -- D-036, vorher backpack_heavy
		Price = 1300000,
		Capacity = 7500,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_lava_crucible",
		DisplayName = "Lava Crucible",
		RequiredLevel = 35, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 3300000,
		Capacity = 8000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_frost_archive",
		DisplayName = "Frost Archive",
		RequiredLevel = 40, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 8500000,
		Capacity = 8500,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_tidal_prism",
		DisplayName = "Tidal Prism",
		RequiredLevel = 45, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 21600000,
		Capacity = 9000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_storm_reactor",
		DisplayName = "Storm Reactor",
		RequiredLevel = 50, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 55000000,
		Capacity = 9500,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_thunder_coil",
		DisplayName = "Thunder Coil",
		RequiredLevel = 55, -- D-036, vorher backpack_titan
		Price = 140000000,
		Capacity = 10000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_amethyst_sanctum",
		DisplayName = "Amethyst Sanctum",
		RequiredLevel = 60, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 310000000,
		Capacity = 11000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_lunar_oracle",
		DisplayName = "Lunar Oracle",
		RequiredLevel = 65, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 680000000,
		Capacity = 12000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_solar_sovereign",
		DisplayName = "Solar Sovereign",
		RequiredLevel = 70, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 1500000000,
		Capacity = 13000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_royal_crystal",
		DisplayName = "Royal Crystal",
		RequiredLevel = 75, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-074)
		Price = 3300000000,
		Capacity = 14000,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		Glow = true, -- leuchtende Teile (Neon + Licht)
	},
	{
		Id = "backpack_void_emperor",
		DisplayName = "Void Emperor",
		RequiredLevel = 80, -- D-036, vorher backpack_colossus; Obergrenze 15.000
		Price = 7200000000,
		Capacity = 15000,
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
