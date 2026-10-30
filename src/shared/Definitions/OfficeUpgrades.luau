--!strict
-- Büro-Ausbaustufen (Felix 2026-10-30, D-082). Stufe 1 ist die Starter-Blechhütte des BuildSteps
-- build_office. Jede weitere Stufe wird an einem eigenen Kaufknopf neben dem Büro gekauft und
-- ersetzt das Büro-Modell auf dem Plot. Besitz wird wie ein Gebäude in PlayerData.Buildings[Id]
-- gespeichert (Prestige setzt ihn wie alle Gebäude zurück).

export type OfficeUpgradeDefinition = {
	Id: string,
	DisplayName: string,
	-- Büro-Stufe nach dem Kauf (Hütte = 1)
	Level: number,
	Price: number,
	RequiredLevel: number,
	-- Name der Vorlage unter ServerStorage.Vendor
	Template: string,
}

local list: { OfficeUpgradeDefinition } = {
	{
		Id = "office_premium",
		DisplayName = "Premium Office",
		Level = 2,
		Price = 35000, -- Felix (D-082)
		RequiredLevel = 15, -- Felix (D-082)
		Template = "PremiumOffice",
	},
}

local byId: { [string]: OfficeUpgradeDefinition } = {}
for index, def in list do
	assert(byId[def.Id] == nil, `Doppelte OfficeUpgrade-ID {def.Id}`)
	assert(def.Level == index + 1, `OfficeUpgrade {def.Id} muss Stufe {index + 1} sein`)
	byId[def.Id] = table.freeze(def)
end

local OfficeUpgrades = {
	List = table.freeze(list),
	ById = table.freeze(byId),
}

-- Höchste gekaufte Stufe (nil = Starter-Hütte)
function OfficeUpgrades.GetCurrent(buildings: { [string]: boolean }): OfficeUpgradeDefinition?
	local current = nil
	for _, def in list do
		if buildings[def.Id] then
			current = def
		end
	end
	return current
end

-- Nächste noch nicht gekaufte Stufe (nil = alles gekauft)
function OfficeUpgrades.GetNext(buildings: { [string]: boolean }): OfficeUpgradeDefinition?
	for _, def in list do
		if not buildings[def.Id] then
			return def
		end
	end
	return nil
end

return table.freeze(OfficeUpgrades)
