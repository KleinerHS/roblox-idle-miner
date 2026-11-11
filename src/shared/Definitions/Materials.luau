--!strict
-- Gemeinsames Materialverzeichnis (docs/06 §3–4): Rohstoffe (Erze) und verarbeitete
-- Materialien (Barren) unter einer Schnittstelle, damit Lager, Fahrzeug, Verkauf und UI
-- beide gleich behandeln. Werte kommen aus den jeweiligen Definitionen.
-- Seit D-088 zusätzlich Sonderfunde (Kind "Special", z. B. ore_coal_pristine): fester Wert und XP
-- aus BalanceConfig.SpecialFinds, nur von Hand abbaubar, vorerst nicht handelbar.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)
local Ores = require(script.Parent.Ores)
local Recipes = require(script.Parent.Recipes)

export type MaterialKind = "Ore" | "Bar" | "Special"
export type MaterialInfo = {
	Id: string,
	Kind: MaterialKind,
	DisplayName: string,
	Color: Color3,
	Tier: number,
	SellValue: number?,
	XPValue: number?,
	-- nur Sonderfunde: Quell-Erz und Seltenheit (pristine/radiant/ancient)
	SourceId: string?,
	Rarity: string?,
	-- false = nicht handelbar (Sonderfunde, D-088)
	Tradable: boolean,
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
		Tradable = true,
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
		Tradable = true,
	})
end
-- Sonderfunde je Erz (D-088): Farbe zum Weiß hin aufgehellt, Sortierung direkt nach dem Erz
local RARITY_TIER_OFFSET = { pristine = 0.6, radiant = 0.7, ancient = 0.8 }
local specialIds: { [string]: { [string]: string } } = {}
for _, ore in Ores.List do
	for _, rarity in BalanceConfig.SpecialFinds.Rarities do
		local id = `{ore.Id}_{rarity.Id}`
		local value = BalanceConfig.SpecialFinds.Values[id]
		if value then
			cache[id] = table.freeze({
				Id = id,
				Kind = "Special" :: MaterialKind,
				DisplayName = `{rarity.DisplayName} {ore.DisplayName}`,
				Color = ore.Color,
				Tier = ore.Tier + (RARITY_TIER_OFFSET[rarity.Id] or 0.6),
				SellValue = value.Value,
				XPValue = value.XP,
				SourceId = ore.Id,
				Rarity = rarity.Id,
				Tradable = false,
			})
			specialIds[ore.Id] = specialIds[ore.Id] or {}
			specialIds[ore.Id][rarity.Id] = id
		end
	end
end

local Materials = {}

-- ID des Sonderfunds für ein Erz und eine Seltenheit (nil = gibt es nicht)
function Materials.SpecialId(oreId: string, rarity: string): string?
	local byRarity = specialIds[oreId]
	return byRarity and byRarity[rarity]
end

-- Darf das Material gehandelt werden? (unbekannte IDs: nein)
function Materials.IsTradable(id: string): boolean
	local info = cache[id]
	return info ~= nil and info.Tradable
end

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
