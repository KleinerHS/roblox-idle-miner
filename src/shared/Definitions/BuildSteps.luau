--!strict
-- Tycoon-Baukette (docs/04 §39). Reihenfolge ist verbindlich:
-- Büro → Elevator/frühe Infrastruktur → Lager → Garage → Schmelzer (docs/00 §9).
-- Immer nur der nächste Schritt hat einen aktiven Kaufbutton.
-- Weitere Schritte (Wände/Dach nach D-002, Lager, Garage …) werden mit ihren Phasen ergänzt.

export type BuildStepDefinition = {
	Id: string,
	DisplayName: string,
	Price: number,
	RequiredLevel: number,
	-- Vorheriger Schritt, nil = erster Schritt
	Requires: string?,
	-- Button erscheint erst nach der Firmeneinrichtung (docs/04 §6)
	RequiresCompanySetup: boolean?,
}

local list: { BuildStepDefinition } = {
	{
		Id = "build_office",
		DisplayName = "Office",
		Price = 0, -- fest (docs/04 §6)
		RequiredLevel = 1,
		Requires = nil,
	},
	{
		Id = "build_elevator",
		DisplayName = "Elevator",
		Price = 200, -- fest (D-003)
		RequiredLevel = 1,
		Requires = "build_office",
		RequiresCompanySetup = true,
	},
	-- Außenwände und Dach als frühe eigene Schritte (D-002), danach das Lager (docs/00 §9).
	-- Preise/Level von Felix festgelegt (D-020).
	{
		Id = "build_walls",
		DisplayName = "Walls",
		Price = 1500, -- Felix (D-020)
		RequiredLevel = 3, -- Felix (D-020)
		Requires = "build_elevator",
		RequiresCompanySetup = true,
	},
	{
		Id = "build_roof",
		DisplayName = "Roof",
		Price = 2500, -- Felix (D-020)
		RequiredLevel = 4, -- Felix (D-020)
		Requires = "build_walls",
		RequiresCompanySetup = true,
	},
	{
		Id = "build_storage",
		DisplayName = "Storage",
		Price = 5000, -- Felix (D-020)
		RequiredLevel = 5, -- Felix (D-020)
		Requires = "build_roof",
		RequiresCompanySetup = true,
	},
	-- Garage nach dem Lager, vor dem Schmelzer (docs/07 §3, docs/00 §9). Vorschlag Q-021.
	{
		Id = "build_garage",
		DisplayName = "Garage",
		Price = 10000, -- TODO_BALANCE (Q-021)
		RequiredLevel = 7, -- TODO_BALANCE (Q-021)
		Requires = "build_storage",
		RequiresCompanySetup = true,
	},
}

local byId: { [string]: BuildStepDefinition } = {}
for index, def in list do
	assert(byId[def.Id] == nil, `Doppelte BuildStep-ID {def.Id}`)
	if index == 1 then
		assert(def.Requires == nil, "Erster BuildStep darf keine Voraussetzung haben")
	else
		assert(def.Requires == list[index - 1].Id, `BuildStep {def.Id} muss auf den vorherigen Schritt folgen`)
	end
	byId[def.Id] = table.freeze(def)
end

local BuildSteps = {
	List = table.freeze(list),
	ById = table.freeze(byId),
}

function BuildSteps.Get(id: string): BuildStepDefinition?
	return byId[id]
end

-- Liefert den nächsten noch nicht gekauften Schritt (oder nil, wenn alles gebaut ist).
function BuildSteps.GetNext(purchased: { [string]: boolean }): BuildStepDefinition?
	for _, def in list do
		if not purchased[def.Id] then
			return def
		end
	end
	return nil
end

return table.freeze(BuildSteps)
