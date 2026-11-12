--!strict
-- Sichtbarkeit der kaufbaren Deko eines Plots (D-091). Nicht gekaufte Deko liegt in
-- ServerStorage.DecorStash.Plot_N (für Clients unsichtbar) und kommt beim Kauf zurück in den Ordner
-- "Exterior" des Plots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Decor = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Decor)

local PlotDecor = {}

local function stashFor(plot: Model): Folder
	local root = ServerStorage:FindFirstChild("DecorStash")
	if not root then
		root = Instance.new("Folder")
		root.Name = "DecorStash"
		root.Parent = ServerStorage
	end
	local folder = (root :: Folder):FindFirstChild(plot.Name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = plot.Name
		folder.Parent = root
	end
	return folder :: Folder
end

-- Zeigt genau die gekauften Pakete (owned[Id] = true), alles andere wird versteckt
function PlotDecor.apply(plot: Model, owned: { [string]: boolean })
	local exterior = plot:FindFirstChild("Exterior")
	if not exterior then
		return
	end
	local stash = stashFor(plot)
	for _, child in exterior:GetChildren() do
		local def = Decor.ForItem(child.Name)
		if def and not owned[def.Id] then
			child.Parent = stash
		end
	end
	for _, child in stash:GetChildren() do
		local def = Decor.ForItem(child.Name)
		if def and owned[def.Id] then
			child.Parent = exterior
		end
	end
end

return table.freeze(PlotDecor)
