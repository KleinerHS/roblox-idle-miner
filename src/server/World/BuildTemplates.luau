--!strict
-- PLATZHALTER-Modelle für die Tycoon-Bauschritte (docs/19 §18). Jeder Eintrag baut das Modell
-- eines BuildSteps an seiner festen Position aus LayoutConfig.HallZones. Sobald finale Modelle
-- unter assets/ existieren, wird hier nur der Bau ersetzt; Namen, Tags und Anker bleiben gleich.
--
-- Vereinbarte Namen/Tags, auf die andere Systeme zugreifen:
--   Office:   Part "SpawnAnchor" (Spawn auf dem Bett), Model "Laptop" (Tag "Laptop")
--   Elevator: Model mit Tag "Elevator", Part "CarFloor"

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)

local BuildTemplates = {}

local METAL_SHEET = Color3.fromRGB(160, 168, 176)
local METAL_DARK = Color3.fromRGB(62, 66, 72)
local STEEL = Color3.fromRGB(96, 102, 110)
local WOOD = Color3.fromRGB(139, 98, 62)
local WOOD_DARK = Color3.fromRGB(98, 68, 44)
local FABRIC = Color3.fromRGB(70, 96, 140)
local WARNING_YELLOW = Color3.fromRGB(232, 184, 52)

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.Parent = parent
	return p
end

-- Ursprung eines Hallenbereichs: Mitte des Bereichs auf Oberkante Hallenboden.
local function zoneOrigin(plotCFrame: CFrame, zoneName: string): CFrame
	local zone = LayoutConfig.HallZones[zoneName]
	assert(zone, `Unbekannter Hallenbereich {zoneName}`)
	return plotCFrame * CFrame.new(zone.Center.X, LayoutConfig.HallFloorTop, zone.Center.Y)
end

-- Blechhütte / Büro (docs/04 §6–7): Schreibtisch, Laptop, Stuhl, Bett, Regal, Lampe.
local function buildOffice(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Office"
	local o = zoneOrigin(plotCFrame, "Office")

	local W, D, H = 26, 22, 11 -- Breite (X), Tiefe (Z), Höhe
	local t = 0.6
	local doorW, doorH, doorX = 6, 8, -1

	local floor = part(model, "HutFloor", Vector3.new(W, 0.3, D), o * CFrame.new(0, 0.15, 0), WOOD, Enum.Material.WoodPlanks)
	model.PrimaryPart = floor

	-- Wände aus Wellblech
	part(model, "Wall_Back", Vector3.new(W, H, t), o * CFrame.new(0, H / 2, D / 2 - t / 2), METAL_SHEET, Enum.Material.Metal)
	part(model, "Wall_Left", Vector3.new(t, H, D), o * CFrame.new(W / 2 - t / 2, H / 2, 0), METAL_SHEET, Enum.Material.Metal)
	part(model, "Wall_Right", Vector3.new(t, H, D), o * CFrame.new(-W / 2 + t / 2, H / 2, 0), METAL_SHEET, Enum.Material.Metal)

	-- Vorderwand mit Türöffnung
	local leftStart, leftEnd = doorX + doorW / 2, W / 2
	local rightStart, rightEnd = -W / 2, doorX - doorW / 2
	local frontZ = -D / 2 + t / 2
	part(model, "Wall_FrontLeft", Vector3.new(leftEnd - leftStart, H, t), o * CFrame.new((leftStart + leftEnd) / 2, H / 2, frontZ), METAL_SHEET, Enum.Material.Metal)
	part(model, "Wall_FrontRight", Vector3.new(rightEnd - rightStart, H, t), o * CFrame.new((rightStart + rightEnd) / 2, H / 2, frontZ), METAL_SHEET, Enum.Material.Metal)
	part(model, "Wall_FrontTop", Vector3.new(doorW, H - doorH, t), o * CFrame.new(doorX, doorH + (H - doorH) / 2, frontZ), METAL_SHEET, Enum.Material.Metal)
	part(model, "DoorFrame", Vector3.new(doorW + 0.6, 0.4, t + 0.2), o * CFrame.new(doorX, doorH + 0.2, frontZ), WOOD_DARK, Enum.Material.Wood)

	-- Fenster (Glas vor der Seitenwand)
	local window = part(model, "Window", Vector3.new(0.2, 3.5, 6), o * CFrame.new(-W / 2 - 0.05, 6.5, 0), Color3.fromRGB(170, 210, 230), Enum.Material.Glass)
	window.Transparency = 0.35

	-- Pultdach, leicht nach hinten geneigt
	part(model, "Roof", Vector3.new(W + 2, 0.5, D + 2), o * CFrame.new(0, H + 0.4, 0) * CFrame.Angles(math.rad(-4), 0, 0), METAL_DARK, Enum.Material.Metal)

	-- Einrichtung (lokal: hinten links = +X/+Z)
	local desk = part(model, "Desk", Vector3.new(7, 0.4, 3.2), o * CFrame.new(7, 3, 8.5), WOOD, Enum.Material.Wood)
	for i, offset in { Vector3.new(3.2, 0, 1.3), Vector3.new(-3.2, 0, 1.3), Vector3.new(3.2, 0, -1.3), Vector3.new(-3.2, 0, -1.3) } do
		part(model, `DeskLeg{i}`, Vector3.new(0.3, 2.8, 0.3), desk.CFrame * CFrame.new(offset.X, -1.6, offset.Z), WOOD_DARK, Enum.Material.Wood)
	end

	local laptop = Instance.new("Model")
	laptop.Name = "Laptop"
	laptop.Parent = model
	local base = part(laptop, "Base", Vector3.new(2.2, 0.15, 1.5), desk.CFrame * CFrame.new(0, 0.28, 0.2), METAL_DARK, Enum.Material.Metal)
	local screen = part(laptop, "Screen", Vector3.new(2.2, 1.4, 0.1), base.CFrame * CFrame.new(0, 0.7, 0.75) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(90, 170, 255), Enum.Material.Neon)
	screen.Transparency = 0.1
	laptop.PrimaryPart = base
	CollectionService:AddTag(laptop, "Laptop")

	local chair = part(model, "Chair", Vector3.new(2.2, 0.4, 2.2), o * CFrame.new(7, 2, 5), METAL_DARK, Enum.Material.Fabric)
	part(model, "ChairBack", Vector3.new(2.2, 2.4, 0.3), chair.CFrame * CFrame.new(0, 1.2, -1), METAL_DARK, Enum.Material.Fabric)
	part(model, "ChairLeg", Vector3.new(0.4, 1.6, 0.4), chair.CFrame * CFrame.new(0, -0.9, 0), STEEL, Enum.Material.Metal)

	-- Bett hinten rechts (Spawnpunkt)
	local bed = part(model, "Bed", Vector3.new(4.6, 1.4, 8.5), o * CFrame.new(-9.5, 1, 5.5), WOOD_DARK, Enum.Material.Wood)
	part(model, "Mattress", Vector3.new(4.2, 0.5, 8), bed.CFrame * CFrame.new(0, 0.9, 0), FABRIC, Enum.Material.Fabric)
	part(model, "Pillow", Vector3.new(3.2, 0.5, 1.4), bed.CFrame * CFrame.new(0, 1.35, 3.1), Color3.fromRGB(235, 235, 230), Enum.Material.Fabric)

	-- Regal an der linken Wand
	local shelf = part(model, "Shelf", Vector3.new(1.4, 6, 5), o * CFrame.new(W / 2 - 1.4, 3.3, -3), WOOD, Enum.Material.Wood)
	for i = 1, 3 do
		part(model, `ShelfBox{i}`, Vector3.new(1, 1, 1.4), shelf.CFrame * CFrame.new(-0.2, -2 + i * 1.6, -1.2 + (i % 2) * 1.6), WOOD_DARK, Enum.Material.Cardboard)
	end

	-- Deckenlampe
	local lamp = part(model, "Lamp", Vector3.new(1.4, 0.4, 1.4), o * CFrame.new(0, H - 0.4, 2), Color3.fromRGB(255, 236, 190), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 226, 180)
	light.Parent = lamp

	local spawnAnchor = part(model, "SpawnAnchor", Vector3.new(1, 1, 1), bed.CFrame * CFrame.new(0, 3, 0), WOOD, Enum.Material.SmoothPlastic)
	spawnAnchor.Transparency = 1
	spawnAnchor.CanCollide = false
	spawnAnchor.CanQuery = false

	return model
end

-- Elevator-Gitterkäfig (docs/04 §16). Funktion (Mine-Auswahl, Fahrt) folgt in Schritt 2b.
local function buildElevator(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Elevator"
	local o = zoneOrigin(plotCFrame, "Elevator")

	local S, H = 20, 20 -- Kantenlänge Käfig, Höhe
	local platform = part(model, "Platform", Vector3.new(S + 4, 1, S + 4), o * CFrame.new(0, 0.5, 0), METAL_DARK, Enum.Material.DiamondPlate)
	model.PrimaryPart = platform

	-- Warnstreifen am Plattformrand
	local edge = (S + 4) / 2 - 0.6
	part(model, "Warn_Front", Vector3.new(S + 4, 0.1, 1.2), o * CFrame.new(0, 1.05, -edge), WARNING_YELLOW, Enum.Material.SmoothPlastic)
	part(model, "Warn_Back", Vector3.new(S + 4, 0.1, 1.2), o * CFrame.new(0, 1.05, edge), WARNING_YELLOW, Enum.Material.SmoothPlastic)
	part(model, "Warn_Left", Vector3.new(1.2, 0.1, S + 4), o * CFrame.new(edge, 1.05, 0), WARNING_YELLOW, Enum.Material.SmoothPlastic)
	part(model, "Warn_Right", Vector3.new(1.2, 0.1, S + 4), o * CFrame.new(-edge, 1.05, 0), WARNING_YELLOW, Enum.Material.SmoothPlastic)

	part(model, "CarFloor", Vector3.new(S - 1, 0.4, S - 1), o * CFrame.new(0, 1.2, 0), STEEL, Enum.Material.DiamondPlate)

	-- Eckpfosten und Rahmen
	local half = S / 2
	for i, c in { Vector2.new(half, half), Vector2.new(-half, half), Vector2.new(half, -half), Vector2.new(-half, -half) } do
		part(model, `Post{i}`, Vector3.new(1.2, H, 1.2), o * CFrame.new(c.X, 1 + H / 2, c.Y), STEEL, Enum.Material.Metal)
	end
	part(model, "Beam_Front", Vector3.new(S + 1.2, 1, 1), o * CFrame.new(0, 1 + H, -half), STEEL, Enum.Material.Metal)
	part(model, "Beam_Back", Vector3.new(S + 1.2, 1, 1), o * CFrame.new(0, 1 + H, half), STEEL, Enum.Material.Metal)
	part(model, "Beam_Left", Vector3.new(1, 1, S + 1.2), o * CFrame.new(half, 1 + H, 0), STEEL, Enum.Material.Metal)
	part(model, "Beam_Right", Vector3.new(1, 1, S + 1.2), o * CFrame.new(-half, 1 + H, 0), STEEL, Enum.Material.Metal)

	-- Gitterwände hinten und seitlich, vorne offen (Gittertor folgt in 2b)
	local function grid(name: string, size: Vector3, cframe: CFrame)
		local g = part(model, name, size, cframe, METAL_DARK, Enum.Material.DiamondPlate)
		g.Transparency = 0.85
	end
	grid("Grid_Back", Vector3.new(S - 1.2, H - 2, 0.2), o * CFrame.new(0, 1 + H / 2, half))
	grid("Grid_Left", Vector3.new(0.2, H - 2, S - 1.2), o * CFrame.new(half, 1 + H / 2, 0))
	grid("Grid_Right", Vector3.new(0.2, H - 2, S - 1.2), o * CFrame.new(-half, 1 + H / 2, 0))
	for i = 1, 2 do
		local y = 1 + i * (H / 3)
		part(model, `Rail_Front{i}`, Vector3.new(S - 1.2, 0.3, 0.3), o * CFrame.new(0, y, -half), WARNING_YELLOW, Enum.Material.Metal)
	end

	-- Seilrad oben
	part(model, "HeadBeam", Vector3.new(1.2, 1.2, S + 1.2), o * CFrame.new(0, 2.6 + H, 0), STEEL, Enum.Material.Metal)
	local wheel = part(model, "Sheave", Vector3.new(0.8, 6, 6), o * CFrame.new(0, 5.6 + H, 0), METAL_DARK, Enum.Material.Metal)
	wheel.Shape = Enum.PartType.Cylinder
	part(model, "Cable", Vector3.new(0.2, H - 1, 0.2), o * CFrame.new(0, 1.5 + H / 2, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)

	-- Ankunftspunkt im Käfig (Blick nach vorne) und Bedienung per ProximityPrompt
	local arrival = part(model, "ArrivalPoint", Vector3.new(2, 1, 2), o * CFrame.new(0, 4.5, 2), STEEL, Enum.Material.SmoothPlastic)
	arrival.Transparency = 1
	arrival.CanCollide = false
	arrival.CanQuery = false

	local promptPart = part(model, "ElevatorPromptPart", Vector3.new(4, 4, 4), o * CFrame.new(0, 4, 0), STEEL, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ElevatorPrompt"
	prompt.ActionText = "Use Elevator"
	prompt.ObjectText = "Elevator"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ElevatorKind", "Surface")
	prompt.Parent = promptPart

	CollectionService:AddTag(model, "Elevator")
	return model
end

local BUILDERS: { [string]: (plotCFrame: CFrame) -> Model } = {
	build_office = buildOffice,
	build_elevator = buildElevator,
}

-- Baut das Modell eines BuildSteps. nil, wenn für den Schritt (noch) kein Modell existiert.
function BuildTemplates.build(stepId: string, plotCFrame: CFrame): Model?
	local builder = BUILDERS[stepId]
	if not builder then
		return nil
	end
	local model = builder(plotCFrame)
	model:SetAttribute("BuildStepId", stepId)
	return model
end

return table.freeze(BuildTemplates)
