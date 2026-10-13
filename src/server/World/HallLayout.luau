--!strict
-- Von Hand angepasstes Hallen-Layout (Felix 2026-10-13: „alle Objekte einzeln gruppieren, damit
-- ich sie selber verschieben kann“).
--
-- In der Place-Datei liegt optional Workspace.HallLayout (Model) mit dem kompletten Ausbau von
-- Plot 1: je Bauschritt ein Model (Attribut BuildStepId, z. B. "build_smelter") und optional der
-- Folder "Exterior" (Außenbereich). Attribut "Origin" (CFrame) = Plot-1-CFrame beim Erzeugen.
-- Darin kann jedes Objekt (Regal, Maschine, Zaun …) in Studio frei verschoben werden.
--
-- Beim Serverstart wird HallLayout nach ServerStorage verschoben. BuildTemplates/PlotBuilder holen
-- sich von hier eine Kopie, versetzt auf den jeweiligen Plot. Fehlt ein Teil im Layout, wird es wie
-- bisher per Code gebaut (Rückfall). Funktionsteile werden über ihre Namen gefunden, deshalb
-- Namen nicht ändern.

local ServerStorage = game:GetService("ServerStorage")

local HallLayout = {}

HallLayout.Name = "HallLayout"

local layout: Model? = nil
local origin: CFrame? = nil

-- Einmal beim Serverstart (vor dem Bau der Plots)
function HallLayout.init()
	local found = workspace:FindFirstChild(HallLayout.Name)
	if not found then
		return
	end
	local o = found:GetAttribute("Origin")
	if not found:IsA("Model") or typeof(o) ~= "CFrame" then
		warn("[HallLayout] Workspace.HallLayout ohne Attribut Origin (CFrame) – wird ignoriert")
		return
	end
	found.Parent = ServerStorage
	layout = found
	origin = o
end

-- Versetzt alle Objekte unter `root` um `delta` (Models per Pivot, lose Parts direkt)
local function move(root: Instance, delta: CFrame)
	if root:IsA("Model") then
		root:PivotTo(delta * root:GetPivot())
	elseif root:IsA("BasePart") then
		root.CFrame = delta * root.CFrame
	else
		for _, child in root:GetChildren() do
			move(child, delta)
		end
	end
end

local function copyFor(source: Instance, plotCFrame: CFrame): Instance
	local copy = source:Clone()
	move(copy, plotCFrame * (origin :: CFrame):Inverse())
	return copy
end

-- Kopie des Gebäudes eines Bauschritts für den Plot, oder nil (dann per Code bauen)
function HallLayout.cloneStep(stepId: string, plotCFrame: CFrame): Model?
	if not layout then
		return nil
	end
	for _, child in layout:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("BuildStepId") == stepId then
			return copyFor(child, plotCFrame) :: Model
		end
	end
	return nil
end

-- Kopie des Außenbereichs für den Plot, oder nil (dann per Code bauen)
function HallLayout.cloneExterior(plotCFrame: CFrame): Instance?
	if not layout then
		return nil
	end
	local source = layout:FindFirstChild("Exterior")
	if not source then
		return nil
	end
	return copyFor(source, plotCFrame)
end

return table.freeze(HallLayout)
