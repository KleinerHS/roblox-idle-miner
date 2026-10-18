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
}

local byId: { [string]: DrillDefinition } = {}
for _, def in list do
	assert(byId[def.Id] == nil, `Doppelte Drill-ID {def.Id}`)
	byId[def.Id] = table.freeze(def)
end

local Drills = {
	List = table.freeze(list),
	ById = table.freeze(byId),
}

-- Modellgröße: wächst bis MK3, ab MK4 gleich groß (Mining-Slots haben feste Größe)
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
