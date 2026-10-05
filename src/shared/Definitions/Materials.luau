--!strict
-- Gemeinsames Materialverzeichnis (docs/06 §3–4): Rohstoffe (Erze) und verarbeitete
-- Materialien (Barren) unter einer Schnittstelle, damit Lager, Fahrzeug, Verkauf und UI
-- beide gleich behandeln. Werte kommen aus den jeweiligen Definitionen.

local Ores = require(script.Parent.Ores)
local Recipes = require(script.Parent.Recipes)

export type MaterialKind = "Ore" | "Bar"
export type MaterialInfo = {
	Id: string,
	Kind: MaterialKind,
	DisplayName: string,
	Color: Color3,
	Tier: number,
	SellValue: number?,
	XPValue: number?,
}

local cache: { [string]: MaterialInfo } = {}

for _, ore in Ores.List do
	cache[ore.Id] = table.freeze({
		Id = ore.Id,
		Kind = "Ore" :: MaterialKind,
		DisplayName = ore.DisplayName,
		Color = ore.Color,
		Tier = ore.Tier,
		SellValue = ore.SellValue,
		XPValue = ore.XPValue,
	})
end
for _, bar in Recipes.Bars do
	cache[bar.Id] = table.freeze({
		Id = bar.Id,
		Kind = "Bar" :: MaterialKind,
		DisplayName = bar.DisplayName,
		Color = bar.Color,
		Tier = bar.Tier,
		SellValue = bar.SellValue,
		XPValue = bar.XPValue,
	})
end

local Materials = {}

function Materials.Get(id: string): MaterialInfo?
	return cache[id]
end

-- Sortierfunktion nach Tier (Erz, dann sein Barren)
function Materials.SortIds(ids: { string })
	table.sort(ids, function(a, b)
		local ma, mb = cache[a], cache[b]
		return (if ma then ma.Tier else 999) < (if mb then mb.Tier else 999)
	end)
end

return table.freeze(Materials)
