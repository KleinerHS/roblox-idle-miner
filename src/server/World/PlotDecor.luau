--!strict
-- Sichtbarkeit der kaufbaren Deko eines Plots (D-091, D-093). Nicht gekaufte Deko liegt in
-- ServerStorage.DecorStash.<Plot>.<Bereich> (für Clients unsichtbar) und kommt beim Kauf an ihren
-- Platz zurück: Außen-Deko in den Ordner "Exterior" des Plots, Garagen-Deko in die Ordner
-- "Decoration"/"Workshop" der Garage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Decor = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Decor)

local PlotDecor = {}

local function folderIn(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f :: Folder
end

local function stashFor(plot: Model, key: string): Folder
	local root = folderIn(ServerStorage, "DecorStash")
	return folderIn(folderIn(root, plot.Name), key)
end

local function applyContainer(container: Instance, stash: Folder, area: Decor.DecorArea, owned: { [string]: boolean })
	for _, child in container:GetChildren() do
		local def = Decor.ForItem(child.Name, area)
		if def and not owned[def.Id] then
			child.Parent = stash
		end
	end
	for _, child in stash:GetChildren() do
		local def = Decor.ForItem(child.Name, area)
		if def and owned[def.Id] then
			child.Parent = container
		end
	end
end

-- Zeigt genau die gekauften Pakete (owned[Id] = true), alles andere wird versteckt.
-- `garage` = aktuelles Garagen-Modell des Plots (nil, wenn keine Garage steht).
function PlotDecor.apply(plot: Model, owned: { [string]: boolean }, garage: Model?)
	local exterior = plot:FindFirstChild("Exterior")
	if exterior then
		applyContainer(exterior, stashFor(plot, "Exterior"), "Exterior", owned)
	end
	if garage then
		for _, name in Decor.GarageFolders do
			local container = garage:FindFirstChild(name, true)
			if container then
				applyContainer(container, stashFor(plot, "Garage" .. name), "Garage", owned)
			end
		end
	end
end

-- Neue Garage gebaut (oder abgerissen): versteckte Teile der alten Garage verwerfen
function PlotDecor.resetGarage(plot: Model)
	local root = ServerStorage:FindFirstChild("DecorStash")
	local plotStash = root and root:FindFirstChild(plot.Name)
	if not plotStash then
		return
	end
	for _, name in Decor.GarageFolders do
		local stash = plotStash:FindFirstChild("Garage" .. name)
		if stash then
			stash:ClearAllChildren()
		end
	end
end

return table.freeze(PlotDecor)
