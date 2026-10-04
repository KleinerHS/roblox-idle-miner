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

-- Alle Zahlen: Vorschlag Q-020, TODO_BALANCE bis zur Bestätigung
local list: { DrillDefinition } = {
	{
		Id = "drill_mk1",
		DisplayName = "Drill MK1",
		Tier = 1,
		RequiredLevel = 6, -- TODO_BALANCE (Q-020)
		Price = 8000, -- TODO_BALANCE (Q-020)
		OrePerCycle = 5, -- TODO_BALANCE (Q-020) → 60 Erz/Min
		CycleSeconds = 5, -- TODO_BALANCE (Q-020)
		OutputCapacity = 300, -- TODO_BALANCE (Q-020)
		BodyColor = Color3.fromRGB(230, 160, 40),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk2",
		DisplayName = "Drill MK2",
		Tier = 2,
		RequiredLevel = 9, -- TODO_BALANCE (Q-020)
		Price = 25000, -- TODO_BALANCE (Q-020)
		OrePerCycle = 10, -- TODO_BALANCE (Q-020) → 120 Erz/Min
		CycleSeconds = 5, -- TODO_BALANCE (Q-020)
		OutputCapacity = 600, -- TODO_BALANCE (Q-020)
		BodyColor = Color3.fromRGB(200, 70, 50),
		PersistenceClass = "Progression",
	},
	{
		Id = "drill_mk3",
		DisplayName = "Drill MK3",
		Tier = 3,
		RequiredLevel = 12, -- TODO_BALANCE (Q-020)
		Price = 75000, -- TODO_BALANCE (Q-020)
		OrePerCycle = 20, -- TODO_BALANCE (Q-020) → 240 Erz/Min
		CycleSeconds = 5, -- TODO_BALANCE (Q-020)
		OutputCapacity = 1200, -- TODO_BALANCE (Q-020)
		BodyColor = Color3.fromRGB(60, 120, 190),
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

function Drills.Get(id: string): DrillDefinition?
	return byId[id]
end

-- Erz pro Minute (für Anzeige und Produktion)
function Drills.OrePerMinute(def: DrillDefinition): number
	return def.OrePerCycle * 60 / def.CycleSeconds
end

return table.freeze(Drills)
