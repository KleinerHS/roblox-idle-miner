--!strict
-- Gemeinsame Schmelzer-Regeln für Server (Verarbeitung) und Client (Anzeige), damit Status
-- und gewähltes Rezept überall gleich sind (docs/06 §29–33, D-011).
--   * Rezeptwahl: bevorzugtes Erz (Priority), wenn genug davon im Trichter liegt; sonst das
--     Rezept mit dem wertvollsten Barren. Nie zufällig (docs/06 §31).
--   * Status: Running / WaitingForInput / OutputFull / Idle (leer).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Recipes = require(Shared.Definitions.Recipes)
local Types = require(Shared.Types)

export type SmelterStatus = "Running" | "WaitingForInput" | "OutputFull" | "Idle"

local SmelterLogic = {}

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

SmelterLogic.Sum = sum

-- Nächstes Rezept oder nil, wenn kein Erz für einen Barren reicht
function SmelterLogic.PickRecipe(state: Types.SmelterState): Recipes.RecipeDefinition?
	if state.Priority ~= "" then
		local preferred = Recipes.ForOre(state.Priority)
		if preferred and Recipes.IsActive(preferred) and (state.Input[preferred.OreId] or 0) >= preferred.OrePerBar then
			return preferred
		end
	end
	local best: Recipes.RecipeDefinition? = nil
	local bestValue = -1
	for oreId, amount in state.Input do
		local recipe = Recipes.ForOre(oreId)
		if recipe and Recipes.IsActive(recipe) and amount >= recipe.OrePerBar then
			local bar = Recipes.GetBar(recipe.BarId)
			local value = if bar and bar.SellValue then bar.SellValue else 0
			-- Gleichstand: feste Reihenfolge über die ID
			if value > bestValue or (value == bestValue and best and recipe.Id < best.Id) then
				best, bestValue = recipe, value
			end
		end
	end
	return best
end

function SmelterLogic.Status(state: Types.SmelterState): SmelterStatus
	if sum(state.Output) >= BalanceConfig.Smelter.OutputCapacity then
		return "OutputFull"
	end
	if SmelterLogic.PickRecipe(state) then
		return "Running"
	end
	return if sum(state.Input) > 0 then "WaitingForInput" else "Idle"
end

-- Kann dieses Erz überhaupt geschmolzen werden (aktives Rezept)?
function SmelterLogic.IsSmeltable(oreId: string): boolean
	local recipe = Recipes.ForOre(oreId)
	return recipe ~= nil and Recipes.IsActive(recipe)
end

return table.freeze(SmelterLogic)
