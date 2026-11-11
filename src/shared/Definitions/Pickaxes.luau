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

-- 25 Stufen aus Felix' Pickaxe-Pack (D-071, 2026-10-27). Werte seit dem Neubalancing vom
-- 2026-11-11 (D-087) aus Felix' Balancing-Datei.
-- Alte IDs werden beim Laden umgeschrieben (DataSchema v12, LegacyIds unten).
local list: { PickaxeDefinition } = {
	{
		Id = "pickaxe_standard",
		DisplayName = "Standard Pickaxe",
		RequiredLevel = 1, -- Balancing 2026-11-11 (D-087)
		Price = 0, -- Balancing 2026-11-11 (D-087)
		MiningPower = 1, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(140, 144, 147),
		Model = "pickaxe_standard",
	},
	{
		Id = "pickaxe_copper",
		DisplayName = "Copper Pickaxe",
		RequiredLevel = 2, -- Balancing 2026-11-11 (D-087)
		Price = 90, -- Balancing 2026-11-11 (D-087)
		MiningPower = 2, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.033, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(201, 112, 54),
		Model = "pickaxe_copper",
	},
	{
		Id = "pickaxe_iron",
		DisplayName = "Iron Pickaxe",
		RequiredLevel = 3, -- Balancing 2026-11-11 (D-087)
		Price = 750, -- Balancing 2026-11-11 (D-087)
		MiningPower = 3, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.067, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(165, 175, 182),
		Model = "pickaxe_iron",
	},
	{
		Id = "pickaxe_gold",
		DisplayName = "Gold Pickaxe",
		RequiredLevel = 7, -- Balancing 2026-11-11 (D-087)
		Price = 1600, -- Balancing 2026-11-11 (D-087)
		MiningPower = 4, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.1, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(226, 183, 91),
		Model = "pickaxe_gold",
	},
	{
		Id = "pickaxe_obsidian",
		DisplayName = "Obsidian Pickaxe",
		RequiredLevel = 11, -- Balancing 2026-11-11 (D-087)
		Price = 3300, -- Balancing 2026-11-11 (D-087)
		MiningPower = 5, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.133, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(51, 49, 62),
		Model = "pickaxe_obsidian",
	},
	{
		Id = "pickaxe_raw_diamond",
		DisplayName = "Raw Diamond Pickaxe",
		RequiredLevel = 16, -- Balancing 2026-11-11 (D-087)
		Price = 6300, -- Balancing 2026-11-11 (D-087)
		MiningPower = 6, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.167, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(101, 170, 204),
		Model = "pickaxe_raw_diamond",
	},
	{
		Id = "pickaxe_nature",
		DisplayName = "Nature Pickaxe",
		RequiredLevel = 20, -- Balancing 2026-11-11 (D-087)
		Price = 12000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 7, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.2, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(70, 126, 60),
		Model = "pickaxe_nature",
	},
	{
		Id = "pickaxe_fire",
		DisplayName = "Fire Pickaxe",
		RequiredLevel = 24, -- Balancing 2026-11-11 (D-087)
		Price = 19000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 8, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.233, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(43, 36, 36),
		Model = "pickaxe_fire",
	},
	{
		Id = "pickaxe_ice",
		DisplayName = "Ice Pickaxe",
		RequiredLevel = 28, -- Balancing 2026-11-11 (D-087)
		Price = 29000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 9, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.267, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(131, 201, 255),
		Model = "pickaxe_ice",
	},
	{
		Id = "pickaxe_electric",
		DisplayName = "Electric Pickaxe",
		RequiredLevel = 32, -- Balancing 2026-11-11 (D-087)
		Price = 50000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 10, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.3, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(41, 125, 229),
		Model = "pickaxe_electric",
	},
	{
		Id = "pickaxe_light",
		DisplayName = "Light Pickaxe",
		RequiredLevel = 36, -- Balancing 2026-11-11 (D-087)
		Price = 90000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 11, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.333, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(226, 189, 93),
		Model = "pickaxe_light",
	},
	{
		Id = "pickaxe_poison",
		DisplayName = "Poison Pickaxe",
		RequiredLevel = 41, -- Balancing 2026-11-11 (D-087)
		Price = 160000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 12, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.367, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(72, 94, 65),
		Model = "pickaxe_poison",
	},
	{
		Id = "pickaxe_shadow",
		DisplayName = "Shadow Pickaxe",
		RequiredLevel = 45, -- Balancing 2026-11-11 (D-087)
		Price = 200000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 13, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.4, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(64, 51, 96),
		Model = "pickaxe_shadow",
	},
	{
		Id = "pickaxe_blood",
		DisplayName = "Blood Pickaxe",
		RequiredLevel = 49, -- Balancing 2026-11-11 (D-087)
		Price = 350000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 14, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.433, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(73, 38, 42),
		Model = "pickaxe_blood",
	},
	{
		Id = "pickaxe_ghost",
		DisplayName = "Ghost Pickaxe",
		RequiredLevel = 53, -- Balancing 2026-11-11 (D-087)
		Price = 710000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 15, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.467, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(44, 114, 124),
		Model = "pickaxe_ghost",
	},
	{
		Id = "pickaxe_inferno",
		DisplayName = "Inferno Pickaxe",
		RequiredLevel = 57, -- Balancing 2026-11-11 (D-087)
		Price = 1400000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 16, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.5, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(53, 48, 52),
		Model = "pickaxe_inferno",
	},
	{
		Id = "pickaxe_rune",
		DisplayName = "Rune Pickaxe",
		RequiredLevel = 62, -- Balancing 2026-11-11 (D-087)
		Price = 4300000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 17, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.533, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(77, 50, 144),
		Model = "pickaxe_rune",
	},
	{
		Id = "pickaxe_cosmic",
		DisplayName = "Cosmic Pickaxe",
		RequiredLevel = 66, -- Balancing 2026-11-11 (D-087)
		Price = 7600000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 18, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.567, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(98, 83, 121),
		Model = "pickaxe_cosmic",
	},
	{
		Id = "pickaxe_sapphire",
		DisplayName = "Sapphire Pickaxe",
		RequiredLevel = 70, -- Balancing 2026-11-11 (D-087)
		Price = 12000000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 19, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.6, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(51, 92, 144),
		Model = "pickaxe_sapphire",
	},
	{
		Id = "pickaxe_amethyst",
		DisplayName = "Amethyst Pickaxe",
		RequiredLevel = 74, -- Balancing 2026-11-11 (D-087)
		Price = 20000000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 20, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.633, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(114, 62, 152),
		Model = "pickaxe_amethyst",
	},
	{
		Id = "pickaxe_ice_titan",
		DisplayName = "Ice Titan Pickaxe",
		RequiredLevel = 78, -- Balancing 2026-11-11 (D-087)
		Price = 58000000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 21, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.667, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(53, 130, 179),
		Model = "pickaxe_ice_titan",
	},
	{
		Id = "pickaxe_royal",
		DisplayName = "Royal Pickaxe",
		RequiredLevel = 82, -- Balancing 2026-11-11 (D-087)
		Price = 75000000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 22, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.7, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(217, 182, 102),
		Model = "pickaxe_royal",
	},
	{
		Id = "pickaxe_crystal_king",
		DisplayName = "Crystal King Pickaxe",
		RequiredLevel = 87, -- Balancing 2026-11-11 (D-087)
		Price = 150000000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 23, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.733, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(189, 91, 159),
		Model = "pickaxe_crystal_king",
	},
	{
		Id = "pickaxe_shadow_king",
		DisplayName = "Shadow King Pickaxe",
		RequiredLevel = 91, -- Balancing 2026-11-11 (D-087)
		Price = 240000000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 24, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.767, -- Balancing 2026-11-11 (D-087)
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(126, 66, 152),
		Model = "pickaxe_shadow_king",
	},
	{
		Id = "pickaxe_primal_king",
		DisplayName = "Primal King Pickaxe",
		RequiredLevel = 95, -- Balancing 2026-11-11 (D-087)
		Price = 470000000, -- Balancing 2026-11-11 (D-087)
		MiningPower = 25, -- Balancing 2026-11-11 (D-087)
		MiningSpeed = 1.8, -- Balancing 2026-11-11 (D-087)
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
