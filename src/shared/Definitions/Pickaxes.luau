--!strict
-- Spitzhacken (docs/10 §44). Weitere Stufen kommen mit dem Equipment Shop (Phase 3).
-- PersistenceClass: wie das Item bei Prestige behandelt wird. Pickaxes, Backpacks und
-- Fahrzeuge bleiben erhalten (D-012), Drills/Maschinen sind "Progression".

local ContentCurve = require(script.Parent.ContentCurve)

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
	-- false = im Shop sichtbar, aber noch nicht kaufbar ("Coming soon", Werte offen)
	Available: boolean?,
	-- Farbe des Hackenkopfs (nur Optik, höhere Stufen wirken hochwertiger, docs/10 §12)
	HeadColor: Color3,
	-- Vorlage in ServerStorage.Vendor.Pickaxes (3D-Modell aus dem Pickaxe-Pack); fehlt sie, wird
	-- die Hacke aus Parts gebaut
	Model: string?,
}

-- 25 Stufen aus Felix' Pickaxe-Pack (D-071, 2026-10-27). Ankerwerte von früher (D-017, D-019,
-- D-036) bleiben auf den entsprechenden Stufen, die Stufen dazwischen sind verteilt (TODO_BALANCE).
-- Alte IDs werden beim Laden umgeschrieben (DataSchema v12, LegacyIds unten).
local list: { PickaxeDefinition } = {
	{
		Id = "pickaxe_standard",
		DisplayName = "Standard Pickaxe",
		RequiredLevel = 1, -- Startwert, vorher pickaxe_basic
		Price = 0,
		MiningPower = 1,
		MiningSpeed = 1.0,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(140, 144, 147),
		Model = "pickaxe_standard",
	},
	{
		Id = "pickaxe_copper",
		DisplayName = "Copper Pickaxe",
		RequiredLevel = 1, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 300,
		MiningPower = 1,
		MiningSpeed = 1.05,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(201, 112, 54),
		Model = "pickaxe_copper",
	},
	{
		Id = "pickaxe_iron",
		DisplayName = "Iron Pickaxe",
		RequiredLevel = 2, -- Felix (D-017)
		Price = 1000,
		MiningPower = 2,
		MiningSpeed = 1.1,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(165, 175, 182),
		Model = "pickaxe_iron",
	},
	{
		Id = "pickaxe_gold",
		DisplayName = "Gold Pickaxe",
		RequiredLevel = 4, -- Felix (D-019), vorher pickaxe_steel
		Price = 3000,
		MiningPower = 3,
		MiningSpeed = 1.25,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(226, 183, 91),
		Model = "pickaxe_gold",
	},
	{
		Id = "pickaxe_obsidian",
		DisplayName = "Obsidian Pickaxe",
		RequiredLevel = 7, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 8500,
		MiningPower = 4,
		MiningSpeed = 1.3,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(51, 49, 62),
		Model = "pickaxe_obsidian",
	},
	{
		Id = "pickaxe_raw_diamond",
		DisplayName = "Raw Diamond Pickaxe",
		RequiredLevel = 10, -- D-036, vorher pickaxe_reinforced
		Price = 24000,
		MiningPower = 5,
		MiningSpeed = 1.35,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(101, 170, 204),
		Model = "pickaxe_raw_diamond",
	},
	{
		Id = "pickaxe_nature",
		DisplayName = "Nature Pickaxe",
		RequiredLevel = 13, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 38000,
		MiningPower = 6,
		MiningSpeed = 1.4,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(70, 126, 60),
		Model = "pickaxe_nature",
	},
	{
		Id = "pickaxe_fire",
		DisplayName = "Fire Pickaxe",
		RequiredLevel = 17, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 62000,
		MiningPower = 7,
		MiningSpeed = 1.45,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(43, 36, 36),
		Model = "pickaxe_fire",
	},
	{
		Id = "pickaxe_ice",
		DisplayName = "Ice Pickaxe",
		RequiredLevel = 20, -- D-036, vorher pickaxe_industrial
		Price = 100000,
		MiningPower = 8,
		MiningSpeed = 1.5,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(131, 201, 255),
		Model = "pickaxe_ice",
	},
	{
		Id = "pickaxe_electric",
		DisplayName = "Electric Pickaxe",
		RequiredLevel = 25, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 430000,
		MiningPower = 9,
		MiningSpeed = 1.55,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(41, 125, 229),
		Model = "pickaxe_electric",
	},
	{
		Id = "pickaxe_light",
		DisplayName = "Light Pickaxe",
		RequiredLevel = 30, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 1700000,
		MiningPower = 10,
		MiningSpeed = 1.6,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(226, 189, 93),
		Model = "pickaxe_light",
	},
	{
		Id = "pickaxe_poison",
		DisplayName = "Poison Pickaxe",
		RequiredLevel = 35, -- D-036, vorher pickaxe_titanium
		Price = 7000000,
		MiningPower = 12,
		MiningSpeed = 1.65,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(72, 94, 65),
		Model = "pickaxe_poison",
	},
	{
		Id = "pickaxe_shadow",
		DisplayName = "Shadow Pickaxe",
		RequiredLevel = 40, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 15000000,
		MiningPower = 14,
		MiningSpeed = 1.7,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(64, 51, 96),
		Model = "pickaxe_shadow",
	},
	{
		Id = "pickaxe_blood",
		DisplayName = "Blood Pickaxe",
		RequiredLevel = 45, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 35000000,
		MiningPower = 16,
		MiningSpeed = 1.75,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(73, 38, 42),
		Model = "pickaxe_blood",
	},
	{
		Id = "pickaxe_ghost",
		DisplayName = "Ghost Pickaxe",
		RequiredLevel = 50, -- D-036, vorher pickaxe_carbide
		Price = 78000000,
		MiningPower = 18,
		MiningSpeed = 1.8,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(44, 114, 124),
		Model = "pickaxe_ghost",
	},
	{
		Id = "pickaxe_inferno",
		DisplayName = "Inferno Pickaxe",
		RequiredLevel = 55, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 180000000,
		MiningPower = 20,
		MiningSpeed = 1.85,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(53, 48, 52),
		Model = "pickaxe_inferno",
	},
	{
		Id = "pickaxe_rune",
		DisplayName = "Rune Pickaxe",
		RequiredLevel = 60, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 420000000,
		MiningPower = 22,
		MiningSpeed = 1.9,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(77, 50, 144),
		Model = "pickaxe_rune",
	},
	{
		Id = "pickaxe_cosmic",
		DisplayName = "Cosmic Pickaxe",
		RequiredLevel = 65, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 950000000,
		MiningPower = 25,
		MiningSpeed = 1.95,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(98, 83, 121),
		Model = "pickaxe_cosmic",
	},
	{
		Id = "pickaxe_sapphire",
		DisplayName = "Sapphire Pickaxe",
		RequiredLevel = 70, -- D-036, vorher pickaxe_diamond
		Price = 2100000000,
		MiningPower = 27,
		MiningSpeed = 2.0,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(51, 92, 144),
		Model = "pickaxe_sapphire",
	},
	{
		Id = "pickaxe_amethyst",
		DisplayName = "Amethyst Pickaxe",
		RequiredLevel = 75, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 4900000000,
		MiningPower = 30,
		MiningSpeed = 2.05,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(114, 62, 152),
		Model = "pickaxe_amethyst",
	},
	{
		Id = "pickaxe_ice_titan",
		DisplayName = "Ice Titan Pickaxe",
		RequiredLevel = 80, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 11000000000,
		MiningPower = 33,
		MiningSpeed = 2.1,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(53, 130, 179),
		Model = "pickaxe_ice_titan",
	},
	{
		Id = "pickaxe_royal",
		DisplayName = "Royal Pickaxe",
		RequiredLevel = 85, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 25000000000,
		MiningPower = 36,
		MiningSpeed = 2.15,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(217, 182, 102),
		Model = "pickaxe_royal",
	},
	{
		Id = "pickaxe_crystal_king",
		DisplayName = "Crystal King Pickaxe",
		RequiredLevel = 90, -- D-036, vorher pickaxe_star_metal
		Price = 57000000000,
		MiningPower = 40,
		MiningSpeed = 2.2,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(189, 91, 159),
		Model = "pickaxe_crystal_king",
	},
	{
		Id = "pickaxe_shadow_king",
		DisplayName = "Shadow King Pickaxe",
		RequiredLevel = 95, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 130000000000,
		MiningPower = 45,
		MiningSpeed = 2.3,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(126, 66, 152),
		Model = "pickaxe_shadow_king",
	},
	{
		Id = "pickaxe_primal_king",
		DisplayName = "Primal King Pickaxe",
		RequiredLevel = 100, -- TODO_BALANCE (verteilt zwischen den Ankerwerten, D-071)
		Price = 300000000000,
		MiningPower = 50,
		MiningSpeed = 2.4,
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(187, 74, 135),
		Model = "pickaxe_primal_king",
	},
}

local byId: { [string]: PickaxeDefinition } = {}
for _, def in list do
	-- Spätspiel-Aufschlag ab Level LatePriceStartLevel (D-046)
	def.Price = ContentCurve.latePrice(def.Price, def.RequiredLevel)
	assert(byId[def.Id] == nil, `Doppelte Pickaxe-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Pickaxes = {
	List = table.freeze(list),
	ById = table.freeze(byId),
	StarterId = "pickaxe_standard",
	-- Alte IDs (vor D-071) → neue Stufe mit denselben Werten
	LegacyIds = table.freeze({
		pickaxe_basic = "pickaxe_standard",
		pickaxe_steel = "pickaxe_gold",
		pickaxe_reinforced = "pickaxe_raw_diamond",
		pickaxe_industrial = "pickaxe_ice",
		pickaxe_titanium = "pickaxe_poison",
		pickaxe_carbide = "pickaxe_ghost",
		pickaxe_diamond = "pickaxe_sapphire",
		pickaxe_star_metal = "pickaxe_crystal_king",
	}),
}

function Pickaxes.Get(id: string): PickaxeDefinition?
	return byId[id]
end

return table.freeze(Pickaxes)
