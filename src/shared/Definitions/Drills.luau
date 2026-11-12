--!strict
-- Drills (docs/05 §24–31, docs/10 §27–33, §46). Automatische Mining-Maschinen, die einen
-- Mining-Slot statt eines Workers belegen. Gekauft im Machine-Shop, landen im Inventar und
-- werden in einer Mine an einem freien Mining-Slot platziert (Phase 5b).
-- Keine Rare Drops (docs/05 §40). Kein Gehalt (docs/11 §28).
--
-- Produktion: OrePerCycle Erz alle CycleSeconds → Erz/Min = OrePerCycle * 60 / CycleSeconds.
-- OutputCapacity = lokaler Zwischenspeicher am Slot (docs/05 §31), ist er voll, stoppt der Drill.
-- PersistenceClass "Progression": wird bei Prestige zurückgesetzt (D-012).

local Pickaxes = require(script.Parent.Pickaxes)
local ContentCurve = require(script.Parent.ContentCurve)
local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)

export type DrillDefinition = {
	Id: string,
	DisplayName: string,
	-- 1, 2, 3 … für Größe/Optik des Modells (docs/10 §28: Entwicklung sichtbar)
	Tier: number,
	RequiredLevel: number,
	Price: number,
	OrePerCycle: number,
	CycleSeconds: number,
	OutputCapacity: number,
	-- Akzentfarbe des Maschinenkörpers
	BodyColor: Color3,
	PersistenceClass: Pickaxes.PersistenceClass,
}

-- Alle Zahlen seit dem Neubalancing vom 2026-11-11 (D-087) aus Felix' Balancing-Datei; Puffer = 5 Minuten Produktion
local list: { DrillDefinition } = {
	{
		Id = "drill_mk1",
		DisplayName = "Drill MK1",
		Tier = 1,
		RequiredLevel = 10, -- Balancing 2026-11-11 (D-087)
		Price = 900, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 4, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 240, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(230, 160, 40),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk2",
		DisplayName = "Drill MK2",
		Tier = 2,
		RequiredLevel = 12, -- Balancing 2026-11-11 (D-087)
		Price = 1400, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 5, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 300, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(200, 70, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk3",
		DisplayName = "Drill MK3",
		Tier = 3,
		RequiredLevel = 16, -- Balancing 2026-11-11 (D-087)
		Price = 2000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 6, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 360, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(60, 120, 190),
		PersistenceClass = "Progression",
	},
	-- Weitere Stufen (Phase 12b D-036, Phase 14c D-044): Preis ≈ 25.000 × Erzwert auf diesem Level
	-- (wie MK3), Puffer = 5 Minuten Produktion. Modellgröße wie MK3 (passt in jeden Mining-Slot).
	-- Anzeige-Nummer = Reihenfolge; die IDs bleiben stabil (drill_mk4 heißt seit D-044 „MK5“ usw.).
	{
		Id = "drill_mk7",
		DisplayName = "Drill MK4",
		Tier = 4,
		RequiredLevel = 18, -- Balancing 2026-11-11 (D-087)
		Price = 2900, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 7, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 420, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(150, 110, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk4",
		DisplayName = "Drill MK5",
		Tier = 5,
		RequiredLevel = 20, -- Balancing 2026-11-11 (D-087)
		Price = 5600, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 8, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 480, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(70, 140, 80),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk8",
		DisplayName = "Drill MK6",
		Tier = 6,
		RequiredLevel = 23, -- Balancing 2026-11-11 (D-087)
		Price = 18000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 9, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 540, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(90, 60, 140),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk5",
		DisplayName = "Drill MK7",
		Tier = 7,
		RequiredLevel = 25, -- Balancing 2026-11-11 (D-087)
		Price = 23000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 10, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 600, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(120, 40, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk9",
		DisplayName = "Drill MK8",
		Tier = 8,
		RequiredLevel = 28, -- Balancing 2026-11-11 (D-087)
		Price = 73000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 11, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 660, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(170, 140, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk6",
		DisplayName = "Drill MK9",
		Tier = 9,
		RequiredLevel = 30, -- Balancing 2026-11-11 (D-087)
		Price = 80000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 12, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 720, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(40, 40, 46),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk10",
		DisplayName = "Drill MK10",
		Tier = 10,
		RequiredLevel = 33, -- Balancing 2026-11-11 (D-087)
		Price = 120000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 13, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 780, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(200, 200, 210),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk11",
		DisplayName = "Drill MK11",
		Tier = 11,
		RequiredLevel = 35, -- Balancing 2026-11-11 (D-087)
		Price = 140000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 14, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 840, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(210, 170, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk12",
		DisplayName = "Drill MK12",
		Tier = 12,
		RequiredLevel = 38, -- Balancing 2026-11-11 (D-087)
		Price = 160000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 15, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 900, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(100, 220, 230),
		PersistenceClass = "Progression",
	},
	-- MK13–MK30 (D-075, Felix 2026-10-28): neue Stufen aus dem Paket Industrial_Drills, hinten
	-- angehängt.
	{
		Id = "drill_mk13",
		DisplayName = "Drill MK13",
		Tier = 13,
		RequiredLevel = 40, -- Balancing 2026-11-11 (D-087)
		Price = 240000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 17, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 1020, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(120, 130, 140),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk14",
		DisplayName = "Drill MK14",
		Tier = 14,
		RequiredLevel = 43, -- Balancing 2026-11-11 (D-087)
		Price = 430000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 19, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 1140, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(150, 90, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk15",
		DisplayName = "Drill MK15",
		Tier = 15,
		RequiredLevel = 45, -- Balancing 2026-11-11 (D-087)
		Price = 620000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 21, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 1260, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(80, 120, 100),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk16",
		DisplayName = "Drill MK16",
		Tier = 16,
		RequiredLevel = 48, -- Balancing 2026-11-11 (D-087)
		Price = 910000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 24, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 1440, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(110, 80, 130),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk17",
		DisplayName = "Drill MK17",
		Tier = 17,
		RequiredLevel = 50, -- Balancing 2026-11-11 (D-087)
		Price = 1000000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 27, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 1620, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(60, 110, 150),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk18",
		DisplayName = "Drill MK18",
		Tier = 18,
		RequiredLevel = 53, -- Balancing 2026-11-11 (D-087)
		Price = 1400000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 30, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 1800, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(170, 120, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk19",
		DisplayName = "Drill MK19",
		Tier = 19,
		RequiredLevel = 55, -- Balancing 2026-11-11 (D-087)
		Price = 2200000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 34, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 2040, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(90, 90, 100),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk20",
		DisplayName = "Drill MK20",
		Tier = 20,
		RequiredLevel = 58, -- Balancing 2026-11-11 (D-087)
		Price = 4600000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 38, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 2280, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(140, 60, 70),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk21",
		DisplayName = "Drill MK21",
		Tier = 21,
		RequiredLevel = 60, -- Balancing 2026-11-11 (D-087)
		Price = 5200000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 43, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 2580, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(70, 140, 140),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk22",
		DisplayName = "Drill MK22",
		Tier = 22,
		RequiredLevel = 63, -- Balancing 2026-11-11 (D-087)
		Price = 12000000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 48, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 2880, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(160, 150, 80),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk23",
		DisplayName = "Drill MK23",
		Tier = 23,
		RequiredLevel = 65, -- Balancing 2026-11-11 (D-087)
		Price = 14000000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 54, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 3240, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(100, 70, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk24",
		DisplayName = "Drill MK24",
		Tier = 24,
		RequiredLevel = 68, -- Balancing 2026-11-11 (D-087)
		Price = 37000000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 61, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 3660, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(60, 80, 120),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk25",
		DisplayName = "Drill MK25",
		Tier = 25,
		RequiredLevel = 71, -- Balancing 2026-11-11 (D-087)
		Price = 53000000, -- Balancing 2026-11-11 (D-087), aufsteigend sortiert (D-089)
		OrePerCycle = 69, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 4140, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(130, 130, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk26",
		DisplayName = "Drill MK26",
		Tier = 26,
		RequiredLevel = 75, -- Balancing 2026-11-11 (D-087)
		Price = 76000000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 78, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 4680, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(150, 100, 140),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk27",
		DisplayName = "Drill MK27",
		Tier = 27,
		RequiredLevel = 79, -- Balancing 2026-11-11 (D-087)
		Price = 230000000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 88, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 5280, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(80, 60, 90),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk28",
		DisplayName = "Drill MK28",
		Tier = 28,
		RequiredLevel = 83, -- Balancing 2026-11-11 (D-087)
		Price = 270000000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 99, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 5940, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(190, 140, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk29",
		DisplayName = "Drill MK29",
		Tier = 29,
		RequiredLevel = 87, -- Balancing 2026-11-11 (D-087)
		Price = 410000000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 111, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 6660, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(50, 60, 70),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk30",
		DisplayName = "Drill MK30",
		Tier = 30,
		RequiredLevel = 90, -- Balancing 2026-11-11 (D-087)
		Price = 500000000, -- Balancing 2026-11-11 (D-087)
		OrePerCycle = 125, -- Balancing 2026-11-11 (D-087)
		CycleSeconds = 5, -- Balancing 2026-11-11 (D-087)
		OutputCapacity = 7500, -- Balancing 2026-11-11 (D-087)
		BodyColor = Color3.fromRGB(210, 180, 90),
		PersistenceClass = "Progression",
	},
}

local byId: { [string]: DrillDefinition } = {}
for _, def in list do
	-- Spätspiel-Aufschlag ab Level LatePriceStartLevel (D-046)
	def.Price = ContentCurve.latePrice(def.Price, def.RequiredLevel)
	assert(byId[def.Id] == nil, `Doppelte Drill-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Drills = {
	List = table.freeze(list),
	ById = table.freeze(byId),
}

-- Modellgröße des alten Platzhalter-Modells (nur ohne 3D-Vorlage): wächst bis MK3, ab MK4 gleich
-- groß. Seit D-075 bringt jede Stufe ihr 3D-Modell L01–L30 in eigener Größe mit (DrillModels).
function Drills.Scale(def: DrillDefinition): number
	return 1 + (math.min(def.Tier, 3) - 1) * 0.25
end

-- Drill-Level (D-043): eigene Upgrade-Stufe 1…MaxLevel je Drill, gespeichert im DrillRecord
Drills.MaxLevel = BalanceConfig.Drills.MaxLevel

function Drills.LevelOf(record: { Level: number? }): number
	return math.clamp(math.floor(record.Level or 1), 1, Drills.MaxLevel)
end

-- Produktionsfaktor eines Levels
function Drills.Multiplier(level: number?): number
	return 1 + (math.max(level or 1, 1) - 1) * BalanceConfig.Drills.ProductionBonusPerLevel
end

-- Puffer am Slot wächst mit dem Level (bleibt ~5 Minuten Produktion)
function Drills.OutputCapacity(def: DrillDefinition, level: number?): number
	return math.floor(def.OutputCapacity * Drills.Multiplier(level))
end

-- Kosten von `level` auf `level + 1` (nil bei MaxLevel)
function Drills.LevelUpCost(def: DrillDefinition, level: number): number?
	if level >= Drills.MaxLevel then
		return nil
	end
	local cfg = BalanceConfig.Drills
	return math.floor(def.Price * cfg.UpgradeCostShare * cfg.UpgradeCostGrowth ^ (level - 1) + 0.5)
end

function Drills.Get(id: string): DrillDefinition?
	return byId[id]
end

-- Erz pro Minute (für Anzeige und Produktion), optional mit Drill-Level
function Drills.OrePerMinute(def: DrillDefinition, level: number?): number
	return math.floor(def.OrePerCycle * 60 / def.CycleSeconds * Drills.Multiplier(level) + 0.5)
end

return table.freeze(Drills)
