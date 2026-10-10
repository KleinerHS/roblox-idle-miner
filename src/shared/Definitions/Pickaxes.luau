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
	-- false = im Shop sichtbar, aber noch nicht kaufbar ("Coming soon", Werte offen)
	Available: boolean?,
	-- Farbe des Hackenkopfs (nur Optik, höhere Stufen wirken hochwertiger, docs/10 §12)
	HeadColor: Color3,
}

-- Stufen 2–3 sind Platzhalter aus Q-015 (Default bis zur Antwort). Alle Zahlen TODO_BALANCE.
local list: { PickaxeDefinition } = {
	{
		Id = "pickaxe_basic",
		DisplayName = "Starter Pickaxe",
		RequiredLevel = 1,
		Price = 0,
		MiningPower = 1, -- TODO_BALANCE (Richtung laut docs/20: 1–2 Erz pro Hit)
		MiningSpeed = 1, -- TODO_BALANCE
		PersistenceClass = "Permanent", -- bleibt bei Prestige (D-012)
		HeadColor = Color3.fromRGB(70, 72, 76),
	},
	{
		Id = "pickaxe_iron",
		DisplayName = "Iron Pickaxe",
		RequiredLevel = 2, -- TODO_BALANCE
		Price = 1000, -- Felix (D-017)
		MiningPower = 2, -- TODO_BALANCE
		MiningSpeed = 1.1, -- TODO_BALANCE
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(128, 130, 136),
	},
	{
		Id = "pickaxe_steel",
		DisplayName = "Steel Pickaxe",
		RequiredLevel = 4, -- Felix (D-019)
		Price = 3000, -- Felix (D-019)
		MiningPower = 3, -- Felix (D-019)
		MiningSpeed = 1.25, -- Felix (D-019)
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(186, 192, 202),
	},
	-- Stufen 4–9 (Phase 12b, Startwert D-036): Preis ≈ 8.000 × Erzwert der besten Mine auf
	-- diesem Level, Power/Speed steigen gleichmäßig
	{
		Id = "pickaxe_reinforced",
		DisplayName = "Reinforced Pickaxe",
		RequiredLevel = 10, -- Startwert (D-036)
		Price = 24000, -- Startwert (D-036)
		MiningPower = 5, -- Startwert (D-036)
		MiningSpeed = 1.35, -- Startwert (D-036)
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(96, 104, 120),
	},
	{
		Id = "pickaxe_industrial",
		DisplayName = "Industrial Pickaxe",
		RequiredLevel = 20, -- Startwert (D-036)
		Price = 100000, -- Startwert (D-036)
		MiningPower = 8, -- Startwert (D-036)
		MiningSpeed = 1.5, -- Startwert (D-036)
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(222, 150, 40),
	},
	{
		Id = "pickaxe_titanium",
		DisplayName = "Titanium Pickaxe",
		RequiredLevel = 35, -- Startwert (D-036)
		Price = 7000000, -- Startwert (D-036)
		MiningPower = 12, -- Startwert (D-036)
		MiningSpeed = 1.65, -- Startwert (D-036)
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(150, 165, 185),
	},
	{
		Id = "pickaxe_carbide",
		DisplayName = "Tungsten Carbide Pickaxe",
		RequiredLevel = 50, -- Startwert (D-036)
		Price = 78000000, -- Startwert (D-036)
		MiningPower = 18, -- Startwert (D-036)
		MiningSpeed = 1.8, -- Startwert (D-036)
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(70, 74, 82),
	},
	{
		Id = "pickaxe_diamond",
		DisplayName = "Diamond-Tipped Pickaxe",
		RequiredLevel = 70, -- Startwert (D-036)
		Price = 2100000000, -- Startwert (D-036)
		MiningPower = 27, -- Startwert (D-036)
		MiningSpeed = 2.0, -- Startwert (D-036)
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(170, 225, 245),
	},
	{
		Id = "pickaxe_star_metal",
		DisplayName = "Star Metal Pickaxe",
		RequiredLevel = 90, -- Startwert (D-036)
		Price = 57000000000, -- Startwert (D-036)
		MiningPower = 40, -- Startwert (D-036)
		MiningSpeed = 2.2, -- Startwert (D-036)
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(240, 225, 160),
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
