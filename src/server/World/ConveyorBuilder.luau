--!strict
-- Förderband-Modelle entlang einer festen Strecke (docs/06 §23–27, docs/04 §24).
-- Jedes Segment: dunkler Gurt (Client lässt Querstollen und Materialhaufen laufen), Seitenwangen in
-- der Stufenfarbe, Umlenkrolle am Ende, Stützen bis zum Boden. Ohne Definition entsteht eine
-- halbtransparente Vorschau der Strecke ("PLACE CONVEYOR HERE", docs/04 §24).
--
-- Vereinbarte Namen/Attribute (für ConveyorAnimController):
--   Part "Belt1".."BeltN" in Laufrichtung (LookVector = Laufrichtung, Size.Z = Länge)
--   Attribute am Modell: "Running" (bool), "HeapColor" (Color3), "Segments" (number)
--   Tag "Conveyor"

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conveyors = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Conveyors)

local ConveyorBuilder = {}

local BELT = Color3.fromRGB(34, 34, 36)
local STEEL = Color3.fromRGB(70, 74, 80)
local ROLLER = Color3.fromRGB(150, 154, 160)
local GHOST = Color3.fromRGB(236, 182, 40)
local WIDTH = 2.4

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanTouch = false
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- points: Weltpositionen der Gurtoberkante in Laufrichtung; floorY: Höhe des Hallenbodens
function ConveyorBuilder.build(points: { Vector3 }, floorY: number, def: Conveyors.ConveyorDefinition?): Model
	local model = Instance.new("Model")
	model.Name = if def then def.Id else "ConveyorPreview"
	local ghost = def == nil
	local frameColor = if def then def.FrameColor else GHOST
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local length = (b - a).Magnitude
		local mid = (a + b) / 2
		-- Gurt liegt mit der Oberkante auf der Strecke
		local cf = CFrame.lookAt(mid, b) * CFrame.new(0, -0.15, 0)
		local belt = part(model, `Belt{i}`, Vector3.new(WIDTH, 0.3, length + (if i < #points - 1 then 0.3 else 0)), cf, if ghost then GHOST else BELT, if ghost then Enum.Material.SmoothPlastic else Enum.Material.Rubber)
		if ghost then
			belt.Transparency = 0.7
			belt.CanCollide = false
			belt.CanQuery = false
			belt.CastShadow = false
		else
			-- Seitenwangen
			for _, side in { -1, 1 } do
				part(model, `Rail{i}_{side}`, Vector3.new(0.25, 0.7, length + 0.3), cf * CFrame.new(side * (WIDTH / 2 + 0.12), 0.2, 0), frameColor, Enum.Material.SmoothPlastic)
			end
			-- Umlenkrolle am Segmentende
			local roller = part(model, `Roller{i}`, Vector3.new(WIDTH + 0.2, 0.5, 0.5), CFrame.lookAt(b, b + (b - a)) * CFrame.new(0, -0.25, 0) * CFrame.Angles(0, math.rad(90), 0), ROLLER)
			roller.Shape = Enum.PartType.Cylinder
			-- Stützen alle ~5 Studs
			local legs = math.max(1, math.floor(length / 5))
			for j = 0, legs do
				local p = a:Lerp(b, j / legs)
				local height = p.Y - 0.5 - floorY
				if height > 0.4 then
					for _, side in { -1, 1 } do
						local legCF = CFrame.lookAt(p, b) * CFrame.new(side * (WIDTH / 2 - 0.2), 0, 0)
						local legPos = Vector3.new(legCF.Position.X, floorY + height / 2, legCF.Position.Z)
						part(model, `Leg{i}_{j}_{side}`, Vector3.new(0.35, height, 0.35), CFrame.new(legPos), STEEL)
					end
				end
			end
		end
		belt:SetAttribute("Segment", i)
	end
	if ghost then
		-- Markierung am Startplatz
		local start = points[1]
		local pad = part(model, "PlaceMarker", Vector3.new(5, 0.08, 5), CFrame.new(start.X, floorY + 0.04, start.Z), GHOST, Enum.Material.Neon)
		pad.Transparency = 0.5
		pad.CanCollide = false
		pad.CanQuery = false
		local labelPart = part(model, "PlaceLabel", Vector3.new(7, 0.05, 2.2), CFrame.new(start.X, floorY + 0.1, start.Z) * CFrame.new(0, 0, 3.8), GHOST, Enum.Material.SmoothPlastic)
		labelPart.Transparency = 1
		labelPart.CanCollide = false
		labelPart.CanQuery = false
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Top
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.LightInfluence = 0.4
		gui.Parent = labelPart
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = GHOST
		label.Text = "PLACE CONVEYOR HERE"
		label.Parent = gui
	end
	model:SetAttribute("Segments", #points - 1)
	model:SetAttribute("Running", false)
	if not ghost then
		CollectionService:AddTag(model, "Conveyor")
	end
	return model
end

function ConveyorBuilder.setRunning(model: Model, running: boolean, heapColor: Color3?)
	if model:GetAttribute("Running") ~= running then
		model:SetAttribute("Running", running)
	end
	if heapColor and model:GetAttribute("HeapColor") ~= heapColor then
		model:SetAttribute("HeapColor", heapColor)
	end
end

return table.freeze(ConveyorBuilder)
