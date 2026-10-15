--!strict
-- Von Hand angepasstes Hallen-Layout (Felix 2026-10-13: „alle Objekte einzeln gruppieren, damit
-- ich sie selber verschieben kann“).
--
-- In der Place-Datei liegt optional Workspace.HallLayout (Model) mit dem kompletten Ausbau von
-- Plot 1: je Bauschritt ein Model (Attribut BuildStepId, z. B. "build_smelter") und optional der
-- Folder "Exterior" (Außenbereich). Der unsichtbare Part "LayoutOrigin" markiert die Plotmitte;
-- er wandert mit, wenn das ganze Layout gedreht/verschoben wird (z. B. zum Bearbeiten gerade zum
-- Raster). Alte Layouts ohne Marker nutzen das Attribut "Origin" (CFrame).
-- Darin kann jedes Objekt (Regal, Maschine, Zaun …) in Studio frei verschoben werden.
--
-- Beim Serverstart wird HallLayout nach ServerStorage verschoben. BuildTemplates/PlotBuilder holen
-- sich von hier eine Kopie, versetzt auf den jeweiligen Plot. Fehlt ein Teil im Layout, wird es wie
-- bisher per Code gebaut (Rückfall). Funktionsteile werden über ihre Namen gefunden, deshalb
-- Namen nicht ändern.
--
-- Damit in Studio ein Klick genau ein Objekt auswählt (Felix 2026-10-15: „jedes Hochregal einzeln
-- verschiebbar“), sind HallLayout selbst und die Gebäude im Layout Folder (Studio wählt beim Klick
-- das oberste Model; Folder zählen nicht). Im Spiel werden die Gebäude wieder zu Models.
-- Ausnahme: der Elevator bleibt ein Ganzes (Model), weil Korb und Schacht zusammengehören.

local ServerStorage = game:GetService("ServerStorage")

local HallLayout = {}

HallLayout.Name = "HallLayout"
HallLayout.OriginName = "LayoutOrigin"

-- Marker für die Plotmitte (unsichtbar, nicht anklickbar im Spiel)
function HallLayout.makeOrigin(parent: Instance, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = HallLayout.OriginName
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(4, 0.2, 4)
	p.CFrame = cf
	p.Parent = parent
	return p
end

local layout: Instance? = nil
local origin: CFrame? = nil

-- Einmal beim Serverstart (vor dem Bau der Plots)
function HallLayout.init()
	local found = workspace:FindFirstChild(HallLayout.Name)
	if not found then
		return
	end
	local marker = found:FindFirstChild(HallLayout.OriginName)
	local o: any = if marker and marker:IsA("BasePart") then marker.CFrame else found:GetAttribute("Origin")
	if not (found:IsA("Model") or found:IsA("Folder")) or typeof(o) ~= "CFrame" then
		warn("[HallLayout] Workspace.HallLayout ohne LayoutOrigin/Origin – wird ignoriert")
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

-- Gebäude für das Layout: Folder statt Model (gleiche Attribute, gleiche Kinder)
function HallLayout.toLayoutForm(building: Model): Instance
	if building:GetAttribute("BuildStepId") == "build_elevator" then
		return building
	end
	local folder = Instance.new("Folder")
	folder.Name = building.Name
	for key, value in building:GetAttributes() do
		folder:SetAttribute(key, value)
	end
	for _, child in building:GetChildren() do
		child.Parent = folder
	end
	building:Destroy()
	return folder
end

-- Layout-Form zurück zum Gebäude-Model (für das Spiel)
local function toModel(inst: Instance): Model
	if inst:IsA("Model") then
		return inst
	end
	local m = Instance.new("Model")
	m.Name = inst.Name
	for key, value in inst:GetAttributes() do
		m:SetAttribute(key, value)
	end
	for _, child in inst:GetChildren() do
		child.Parent = m
	end
	inst:Destroy()
	return m
end

-- Kopie des Gebäudes eines Bauschritts für den Plot, oder nil (dann per Code bauen)
function HallLayout.cloneStep(stepId: string, plotCFrame: CFrame): Model?
	if not layout then
		return nil
	end
	for _, child in layout:GetChildren() do
		if (child:IsA("Model") or child:IsA("Folder")) and child:GetAttribute("BuildStepId") == stepId then
			return toModel(copyFor(child, plotCFrame))
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
