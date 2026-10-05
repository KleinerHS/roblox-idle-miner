--!strict
-- Schmelz-Rezepte (docs/06 §28–31, D-011): Nur Metalle bekommen Rezepte; Coal, Edelsteine und
-- Kristalle werden nur roh verkauft. Ein Rezept macht aus OrePerBar Erz einen Barren in
-- Seconds Sekunden. Legierungen (mehrere Erze → ein Produkt) kommen in einer späteren Version.
-- IDs der Barren sind stabil ("bar_<metall>") und werden gespeichert.
--
-- Ein Rezept ist nur aktiv, wenn Erz UND Barren gebalanct sind (SellValue in BalanceConfig);
-- sonst würde der Schmelzer unverkäufliches Material erzeugen.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)
local Ores = require(script.Parent.Ores)

export type BarDefinition = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	-- Sortierung: direkt nach dem Erz
	Tier: number,
	-- nil = noch nicht gebalanced (TODO_BALANCE)
	SellValue: number?,
	XPValue: number?,
}

export type RecipeDefinition = {
	Id: string,
	OreId: string,
	BarId: string,
	OrePerBar: number,
	Seconds: number,
}

-- Metalle mit Schmelz-Rezept (D-011)
local METALS = {
	"ore_copper", "ore_tin", "ore_iron", "ore_lead", "ore_zinc", "ore_silver", "ore_nickel",
	"ore_cobalt", "ore_chromium", "ore_manganese", "ore_aluminum", "ore_titanium", "ore_tungsten",
	"ore_platinum", "ore_palladium", "ore_osmium", "ore_iridium", "ore_rhodium", "ore_mythril",
	"ore_star_metal", "ore_celestial_metal", "ore_astralium",
}

local bars: { BarDefinition } = {}
local barsById: { [string]: BarDefinition } = {}
local recipes: { RecipeDefinition } = {}
local recipeByOre: { [string]: RecipeDefinition } = {}

for _, oreId in METALS do
	local ore = Ores.Get(oreId)
	assert(ore, `Rezept für unbekanntes Erz {oreId}`)
	local metal = (oreId:gsub("^ore_", ""))
	local barId = "bar_" .. metal
	local value = BalanceConfig.BarValues[barId]
	local bar: BarDefinition = table.freeze({
		Id = barId,
		DisplayName = ore.DisplayName .. " Bar",
		-- Barren etwas heller/glänzender als das Erz
		Color = ore.Color:Lerp(Color3.new(1, 1, 1), 0.15),
		Tier = ore.Tier + 0.5,
		SellValue = if value then value.SellValue else nil,
		XPValue = if value then value.XPValue else nil,
	})
	table.insert(bars, bar)
	barsById[barId] = bar
	local recipe: RecipeDefinition = table.freeze({
		Id = "recipe_" .. metal,
		OreId = oreId,
		BarId = barId,
		OrePerBar = BalanceConfig.Smelter.OrePerBar,
		Seconds = BalanceConfig.Smelter.SecondsPerBar,
	})
	table.insert(recipes, recipe)
	recipeByOre[oreId] = recipe
end

local Recipes = {
	Bars = table.freeze(bars),
	Recipes = table.freeze(recipes),
}

function Recipes.GetBar(id: string): BarDefinition?
	return barsById[id]
end

function Recipes.ForOre(oreId: string): RecipeDefinition?
	return recipeByOre[oreId]
end

-- Rezept nutzbar? Erz und Barren müssen einen Verkaufswert haben.
function Recipes.IsActive(recipe: RecipeDefinition): boolean
	local ore = Ores.Get(recipe.OreId)
	local bar = barsById[recipe.BarId]
	return ore ~= nil and ore.SellValue ~= nil and bar ~= nil and bar.SellValue ~= nil
end

return table.freeze(Recipes)
