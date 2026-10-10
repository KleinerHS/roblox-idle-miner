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
	-- MK4–MK6 (Phase 12b, Vorschlag Q-027): Preis ≈ 25.000 × Erzwert auf diesem Level (wie MK3),
	-- Puffer = 5 Minuten Produktion. Modellgröße wie MK3 (passt in jeden Mining-Slot).
	{
		Id = "drill_mk4",
		DisplayName = "Drill MK4",
		Tier = 4,
		RequiredLevel = 25, -- TODO_BALANCE (Q-027)
		Price = 1300000, -- TODO_BALANCE (Q-027)
		OrePerCycle = 60, -- TODO_BALANCE (Q-027) → 1.200 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 6000, -- TODO_BALANCE (Q-027)
		BodyColor = Color3.fromRGB(70, 140, 80),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk5",
		DisplayName = "Drill MK5",
		Tier = 5,
		RequiredLevel = 45, -- TODO_BALANCE (Q-027)
		Price = 98000000, -- TODO_BALANCE (Q-027)
		OrePerCycle = 150, -- TODO_BALANCE (Q-027) → 3.000 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 15000, -- TODO_BALANCE (Q-027)
		BodyColor = Color3.fromRGB(120, 40, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk6",
		DisplayName = "Drill MK6",
		Tier = 6,
		RequiredLevel = 70, -- TODO_BALANCE (Q-027)
		Price = 6500000000, -- TODO_BALANCE (Q-027)
		OrePerCycle = 375, -- TODO_BALANCE (Q-027) → 7.500 Erz/Min
		CycleSeconds = 3,
		OutputCapacity = 37500, -- TODO_BALANCE (Q-027)
		BodyColor = Color3.fromRGB(40, 40, 46),
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

function Drills.Get(id: string): DrillDefinition?
	return byId[id]
end

-- Erz pro Minute (für Anzeige und Produktion)
function Drills.OrePerMinute(def: DrillDefinition): number
	return def.OrePerCycle * 60 / def.CycleSeconds
end

return table.freeze(Drills)
