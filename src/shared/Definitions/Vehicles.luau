--!strict
-- Firmenfahrzeuge (docs/07 §5–8, §14, §47). Kapazität ist der wichtigste Progressionswert;
-- große Fahrzeuge sind nicht schneller, sondern schwerer und träger (docs/07 §14).
-- Je Typ besitzt der Spieler höchstens ein Fahrzeug (Fuhrpark). Ladung je Fahrzeug (D-009).
-- PersistenceClass "Permanent": Fahrzeuge bleiben bei Prestige (D-012).
--
-- Fahrwerte (studs/s bzw. Faktoren) werden von VehicleModelBuilder/VehicleController genutzt.

local Pickaxes = require(script.Parent.Pickaxes)
local ContentCurve = require(script.Parent.ContentCurve)

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
	-- im Autohaus ausgestellt (Felix 2026-10-18: nur die kleinen Fahrzeuge)
	Showroom: boolean?,
	-- false = sichtbar, aber noch nicht kaufbar (Lastzüge warten auf die Anhänger-Technik)
	Available: boolean?,
}

-- Karosserien seit 2026-10-18 aus Felix' Modellen (ServerStorage.Vendor.VehicleBodies, D-048).
-- Namen ohne echte Marken (D-026).

local list: { VehicleDefinition } = {
	{
		Id = "vehicle_pickup",
		DisplayName = "Pickup",
		Tier = 1,
		Style = "Pickup",
		RequiredLevel = 7,
		Price = 6000,
		Capacity = 1000, -- fest (docs/07 §7)
		Showroom = true,
		MaxSpeed = 55,
		Acceleration = 1,
		PaintColor = Color3.fromRGB(232, 232, 228),
		PersistenceClass = "Permanent",
	},
	{
		Id = "vehicle_van",
		DisplayName = "Cargo Van",
		Tier = 2,
		Style = "Van",
		RequiredLevel = 10,
		Price = 20000,
		Capacity = 2500,
		Showroom = true,
		MaxSpeed = 52,
		Acceleration = 0.85,
		PaintColor = Color3.fromRGB(70, 82, 96),
		PersistenceClass = "Permanent",
	},
	{
		Id = "vehicle_boxtruck",
		DisplayName = "High-Roof Van",
		Tier = 3,
		Style = "BoxTruck",
		RequiredLevel = 14,
		Price = 60000,
		Capacity = 6000,
		Showroom = true,
		MaxSpeed = 46,
		Acceleration = 0.65,
		PaintColor = Color3.fromRGB(196, 60, 46),
		PersistenceClass = "Permanent",
	},
	-- Phase 12c (docs/07 §6: mittlerer LKW, großer Mining-Truck). Vorschlag Q-028:
	-- Preis ≈ 20.000 × Erzwert auf diesem Level, Modelle vorläufig (Feinschliff am Ende)
	{
		Id = "vehicle_truck",
		DisplayName = "Box Truck",
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
		DisplayName = "Tipper Road Train",
		Tier = 5,
		Available = false, -- Anhänger-Technik folgt (PLANS/ROAD_TRAINS.md)
		Style = "Hauler",
		RequiredLevel = 45, -- TODO_BALANCE (Q-028)
		Price = 78000000, -- TODO_BALANCE (Q-028)
		Capacity = 25000, -- TODO_BALANCE (Q-028)
		MaxSpeed = 40, -- TODO_BALANCE (Q-028)
		Acceleration = 0.45, -- TODO_BALANCE (Q-028)
		PaintColor = Color3.fromRGB(236, 182, 40),
		PersistenceClass = "Permanent",
	},
	{
		Id = "vehicle_roadtrain",
		DisplayName = "Grain Road Train",
		Tier = 6,
		Style = "Hauler",
		RequiredLevel = 65, -- TODO_BALANCE
		Price = 2000000000, -- TODO_BALANCE (vor Spätspiel-Aufschlag)
		Capacity = 50000, -- TODO_BALANCE
		MaxSpeed = 33, -- TODO_BALANCE: ~60 % der kleinen Fahrzeuge (Felix 2026-10-19); A-Chassis-Tune SpeedLimit 60 km/h
		Acceleration = 0.4, -- TODO_BALANCE
		PaintColor = Color3.fromRGB(230, 230, 230),
		PersistenceClass = "Permanent",
		Available = false, -- im Autohaus erst nach Fahrtest freigeben (PLANS/ROAD_TRAINS.md); per DevTool GiveVehicle testbar
	},
}

local byId: { [string]: VehicleDefinition } = {}
for _, def in list do
	-- Spätspiel-Aufschlag ab Level LatePriceStartLevel (D-046)
	def.Price = ContentCurve.latePrice(def.Price, def.RequiredLevel)
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
