--!strict
-- Firmenfahrzeuge (docs/07 §5–8, §14, §47). Kapazität ist der wichtigste Progressionswert;
-- große Fahrzeuge sind nicht schneller, sondern schwerer und träger (docs/07 §14).
-- Je Typ besitzt der Spieler höchstens ein Fahrzeug (Fuhrpark). Ladung je Fahrzeug (D-009).
-- PersistenceClass "Permanent": Fahrzeuge bleiben bei Prestige (D-012).
--
-- Fahrwerte (studs/s bzw. Faktoren) werden von VehicleModelBuilder/VehicleController genutzt.

local Pickaxes = require(script.Parent.Pickaxes)

export type VehicleStyle = "Pickup" | "Van" | "BoxTruck" | "Truck" | "Hauler"

export type VehicleDefinition = {
	Id: string,
	DisplayName: string,
	-- 1, 2, 3 … für Reihenfolge und Größe
	Tier: number,
	Style: VehicleStyle,
	RequiredLevel: number,
	Price: number,
	-- Gesamtkapazität über alle Materialien (docs/07 §7–8)
	Capacity: number,
	-- Höchstgeschwindigkeit in Studs pro Sekunde (Anzeige "Speed")
	MaxSpeed: number,
	-- Beschleunigung als Faktor (1 = normal); große Fahrzeuge träger
	Acceleration: number,
	-- Lackfarbe der Karosserie (Firmenfarbe nur als Akzent, docs/07 §36)
	PaintColor: Color3,
	PersistenceClass: Pickaxes.PersistenceClass,
}

local list: { VehicleDefinition } = {
	{
		Id = "vehicle_pickup",
		DisplayName = "Utility Pickup",
		Tier = 1,
		Style = "Pickup",
		RequiredLevel = 7,
		Price = 6000,
		Capacity = 1000, -- fest (docs/07 §7)
		MaxSpeed = 55,
		Acceleration = 1,
		PaintColor = Color3.fromRGB(232, 232, 228),
		PersistenceClass = "Permanent",
	},
	{
		Id = "vehicle_van",
		DisplayName = "Utility Van",
		Tier = 2,
		Style = "Van",
		RequiredLevel = 10,
		Price = 20000,
		Capacity = 2500,
		MaxSpeed = 52,
		Acceleration = 0.85,
		PaintColor = Color3.fromRGB(70, 82, 96),
		PersistenceClass = "Permanent",
	},
	{
		Id = "vehicle_boxtruck",
		DisplayName = "Box Truck",
		Tier = 3,
		Style = "BoxTruck",
		RequiredLevel = 14,
		Price = 60000,
		Capacity = 6000,
		MaxSpeed = 46,
		Acceleration = 0.65,
		PaintColor = Color3.fromRGB(196, 60, 46),
		PersistenceClass = "Permanent",
	},
	-- Phase 12c (docs/07 §6: mittlerer LKW, großer Mining-Truck). Vorschlag Q-028:
	-- Preis ≈ 20.000 × Erzwert auf diesem Level, Modelle vorläufig (Feinschliff am Ende)
	{
		Id = "vehicle_truck",
		DisplayName = "Tipper Truck",
		Tier = 4,
		Style = "Truck",
		RequiredLevel = 25, -- TODO_BALANCE (Q-028)
		Price = 1000000, -- TODO_BALANCE (Q-028)
		Capacity = 12000, -- TODO_BALANCE (Q-028)
		MaxSpeed = 44, -- TODO_BALANCE (Q-028)
		Acceleration = 0.55, -- TODO_BALANCE (Q-028)
		PaintColor = Color3.fromRGB(46, 96, 160),
		PersistenceClass = "Permanent",
	},
	{
		Id = "vehicle_hauler",
		DisplayName = "Mining Hauler",
		Tier = 5,
		Style = "Hauler",
		RequiredLevel = 45, -- TODO_BALANCE (Q-028)
		Price = 78000000, -- TODO_BALANCE (Q-028)
		Capacity = 25000, -- TODO_BALANCE (Q-028)
		MaxSpeed = 40, -- TODO_BALANCE (Q-028)
		Acceleration = 0.45, -- TODO_BALANCE (Q-028)
		PaintColor = Color3.fromRGB(236, 182, 40),
		PersistenceClass = "Permanent",
	},
}

local byId: { [string]: VehicleDefinition } = {}
for _, def in list do
	assert(byId[def.Id] == nil, `Doppelte Vehicle-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Vehicles = {
	List = table.freeze(list),
	ById = table.freeze(byId),
	-- Stellplätze in der Garage (D-016)
	BayCount = 2,
}

function Vehicles.Get(id: string): VehicleDefinition?
	return byId[id]
end

return table.freeze(Vehicles)
