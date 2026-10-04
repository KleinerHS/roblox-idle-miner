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
		Available = false, -- Werte offen (Q-016)
		DisplayName = "Steel Pickaxe",
		RequiredLevel = 4, -- TODO_BALANCE
		Price = 900, -- TODO_BALANCE
		MiningPower = 3, -- TODO_BALANCE
		MiningSpeed = 1.25, -- TODO_BALANCE
		PersistenceClass = "Permanent",
		HeadColor = Color3.fromRGB(186, 192, 202),
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
