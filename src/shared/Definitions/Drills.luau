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

-- Alle Zahlen: Q-020, von Felix bestätigt (2026-10-10, MK3 auf 500 Erz/Min angehoben)
local list: { DrillDefinition } = {
	{
		Id = "drill_mk1",
		DisplayName = "Drill MK1",
		Tier = 1,
		RequiredLevel = 6,
		Price = 8000,
		OrePerCycle = 5, -- → 60 Erz/Min
		CycleSeconds = 5,
		OutputCapacity = 300,
		BodyColor = Color3.fromRGB(230, 160, 40),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk2",
		DisplayName = "Drill MK2",
		Tier = 2,
		RequiredLevel = 9,
		Price = 25000,
		OrePerCycle = 10, -- → 120 Erz/Min
		CycleSeconds = 5,
		OutputCapacity = 600,
		BodyColor = Color3.fromRGB(200, 70, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk3",
		DisplayName = "Drill MK3",
		Tier = 3,
		RequiredLevel = 12,
		Price = 75000,
		OrePerCycle = 25, -- Q-020: 500 Erz/Min (Felix)
		CycleSeconds = 3,
		OutputCapacity = 2500, -- reicht wie MK1/MK2 für 5 Minuten Produktion
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
		RequiredLevel = 18, -- Startwert (D-044)
		Price = 200000, -- Startwert (D-044): ≈ 25.000 × Erzwert auf diesem Level
		OrePerCycle = 40, -- Startwert (D-044) → 800 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 4000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(150, 110, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk4",
		DisplayName = "Drill MK5",
		Tier = 5,
		RequiredLevel = 25, -- Startwert (D-036)
		Price = 1300000, -- Startwert (D-036)
		OrePerCycle = 60, -- Startwert (D-036) → 1.200 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 6000, -- Startwert (D-036)
		BodyColor = Color3.fromRGB(70, 140, 80),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk8",
		DisplayName = "Drill MK6",
		Tier = 6,
		RequiredLevel = 35, -- Startwert (D-044)
		Price = 22000000, -- Startwert (D-044): ≈ 25.000 × Erzwert auf diesem Level
		OrePerCycle = 95, -- Startwert (D-044) → 1,900 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 9500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(90, 60, 140),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk5",
		DisplayName = "Drill MK7",
		Tier = 7,
		RequiredLevel = 45, -- Startwert (D-036)
		Price = 98000000, -- Startwert (D-036)
		OrePerCycle = 150, -- Startwert (D-036) → 3.000 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 15000, -- Startwert (D-036)
		BodyColor = Color3.fromRGB(120, 40, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk9",
		DisplayName = "Drill MK8",
		Tier = 8,
		RequiredLevel = 58, -- Startwert (D-044)
		Price = 800000000, -- Startwert (D-044): ≈ 25.000 × Erzwert auf diesem Level
		OrePerCycle = 240, -- Startwert (D-044) → 4,800 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 24000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(170, 140, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk6",
		DisplayName = "Drill MK9",
		Tier = 9,
		RequiredLevel = 70, -- Startwert (D-036)
		Price = 6500000000, -- Startwert (D-036)
		OrePerCycle = 375, -- Startwert (D-036) → 7.500 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 37500, -- Startwert (D-036)
		BodyColor = Color3.fromRGB(40, 40, 46),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk10",
		DisplayName = "Drill MK10",
		Tier = 10,
		RequiredLevel = 80, -- Startwert (D-044)
		Price = 30000000000, -- Startwert (D-044): ≈ 25.000 × Erzwert auf diesem Level
		OrePerCycle = 600, -- Startwert (D-044) → 12,000 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 60000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(200, 200, 210),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk11",
		DisplayName = "Drill MK11",
		Tier = 11,
		RequiredLevel = 90, -- Startwert (D-044)
		Price = 180000000000, -- Startwert (D-044): ≈ 25.000 × Erzwert auf diesem Level
		OrePerCycle = 900, -- Startwert (D-044) → 18,000 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 90000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(210, 170, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk12",
		DisplayName = "Drill MK12",
		Tier = 12,
		RequiredLevel = 100, -- Startwert (D-044)
		Price = 800000000000, -- Startwert (D-044): ≈ 25.000 × Erzwert auf diesem Level
		OrePerCycle = 1350, -- Startwert (D-044) → 27,000 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 135000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(100, 220, 230),
		PersistenceClass = "Progression",
	},
	-- MK13–MK30 (D-075, Felix 2026-10-28): neue Stufen aus dem Paket Industrial_Drills, hinten
	-- angehängt. Werte nur fortgeschrieben, die Balance macht Felix später (TODO_BALANCE).
	{
		Id = "drill_mk13",
		DisplayName = "Drill MK13",
		Tier = 13,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 1600000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 1755, -- TODO_BALANCE: × 1,3 je Stufe → 35,100 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 175500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(120, 130, 140),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk14",
		DisplayName = "Drill MK14",
		Tier = 14,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 3200000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 2280, -- TODO_BALANCE: × 1,3 je Stufe → 45,600 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 228000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(150, 90, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk15",
		DisplayName = "Drill MK15",
		Tier = 15,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 6400000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 2965, -- TODO_BALANCE: × 1,3 je Stufe → 59,300 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 296500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(80, 120, 100),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk16",
		DisplayName = "Drill MK16",
		Tier = 16,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 12800000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 3855, -- TODO_BALANCE: × 1,3 je Stufe → 77,100 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 385500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(110, 80, 130),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk17",
		DisplayName = "Drill MK17",
		Tier = 17,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 25600000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 5010, -- TODO_BALANCE: × 1,3 je Stufe → 100,200 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 501000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(60, 110, 150),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk18",
		DisplayName = "Drill MK18",
		Tier = 18,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 51200000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 6515, -- TODO_BALANCE: × 1,3 je Stufe → 130,300 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 651500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(170, 120, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk19",
		DisplayName = "Drill MK19",
		Tier = 19,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 102400000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 8470, -- TODO_BALANCE: × 1,3 je Stufe → 169,400 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 847000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(90, 90, 100),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk20",
		DisplayName = "Drill MK20",
		Tier = 20,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 204800000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 11010, -- TODO_BALANCE: × 1,3 je Stufe → 220,200 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 1101000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(140, 60, 70),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk21",
		DisplayName = "Drill MK21",
		Tier = 21,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 409600000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 14315, -- TODO_BALANCE: × 1,3 je Stufe → 286,300 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 1431500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(70, 140, 140),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk22",
		DisplayName = "Drill MK22",
		Tier = 22,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 819200000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 18610, -- TODO_BALANCE: × 1,3 je Stufe → 372,200 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 1861000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(160, 150, 80),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk23",
		DisplayName = "Drill MK23",
		Tier = 23,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 1638400000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 24195, -- TODO_BALANCE: × 1,3 je Stufe → 483,900 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 2419500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(100, 70, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk24",
		DisplayName = "Drill MK24",
		Tier = 24,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 3276800000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 31455, -- TODO_BALANCE: × 1,3 je Stufe → 629,100 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 3145500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(60, 80, 120),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk25",
		DisplayName = "Drill MK25",
		Tier = 25,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 6553600000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 40890, -- TODO_BALANCE: × 1,3 je Stufe → 817,800 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 4089000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(130, 130, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk26",
		DisplayName = "Drill MK26",
		Tier = 26,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 13107200000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 53155, -- TODO_BALANCE: × 1,3 je Stufe → 1,063,100 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 5315500, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(150, 100, 140),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk27",
		DisplayName = "Drill MK27",
		Tier = 27,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 26214400000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 69100, -- TODO_BALANCE: × 1,3 je Stufe → 1,382,000 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 6910000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(80, 60, 90),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk28",
		DisplayName = "Drill MK28",
		Tier = 28,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 52428800000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 89830, -- TODO_BALANCE: × 1,3 je Stufe → 1,796,600 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 8983000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(190, 140, 60),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk29",
		DisplayName = "Drill MK29",
		Tier = 29,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 104857600000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 116780, -- TODO_BALANCE: × 1,3 je Stufe → 2,335,600 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 11678000, -- 5 Minuten Produktion
		BodyColor = Color3.fromRGB(50, 60, 70),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk30",
		DisplayName = "Drill MK30",
		Tier = 30,
		RequiredLevel = 100, -- TODO_BALANCE (D-075: hinten angehängt, Balance folgt)
		Price = 209715200000000000, -- TODO_BALANCE: × 2 je Stufe
		OrePerCycle = 151815, -- TODO_BALANCE: × 1,3 je Stufe → 3,036,300 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 15181500, -- 5 Minuten Produktion
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
