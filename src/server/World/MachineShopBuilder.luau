--!strict
-- Machine-Shop in der Mitte (CENTRAL_AREA_REFERENCE.png: orange, hinten; docs/08 §13–14,
-- docs/10 §24–26). Industrieller als der Equipment-Shop: Betonboden, Stahlstützen,
-- Trapezblech-Wände, großes offenes Rolltor, Maschinenplattform mit ausgestellten Drills,
-- Werkzeugwand, Werkbank und Tresen mit Shop-Prompt. Ausstellungsstücke aus den Definitionen
-- (nicht jede Stufe, docs/10 §25), ohne Scripts (docs/10 §69).
--
-- Vereinbarte Namen/Attribute:
--   Model "MachineShop"
--   Part  "CounterPromptPart" mit ProximityPrompt "ShopPrompt" (Attribute ShopId = "machine")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Drills = require(Shared.Definitions.Drills)

local DrillModelBuilder = require(script.Parent.DrillModelBuilder)

local MachineShopBuilder = {}

local ORANGE = Color3.fromRGB(222, 120, 40)
local ORANGE_DARK = Color3.fromRGB(160, 80, 26)
local CONCRETE = Color3.fromRGB(150, 148, 142)
local CONCRETE_DARK = Color3.fromRGB(110, 108, 104)
local STEEL = Color3.fromRGB(66, 70, 76)
local STEEL_DARK = Color3.fromRGB(42, 44, 48)
local HAZARD_YELLOW = Color3.fromRGB(240, 196, 40)
local HAZARD_BLACK = Color3.fromRGB(28, 28, 28)
local PEGBOARD = Color3.fromRGB(176, 150, 112)
local WOOD = Color3.fromRGB(130, 92, 58)
local WHITE = Color3.fromRGB(240, 240, 236)
local LIGHT = Color3.fromRGB(255, 236, 200)

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

local function surfaceText(target: BasePart, text: string, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
end

-- Stahlstütze als I-Profil
local function column(parent: Instance, name: string, height: number, cf: CFrame)
	part(parent, `{name}Web`, Vector3.new(0.3, height, 1), cf * CFrame.new(0, height / 2, 0), STEEL, Enum.Material.Metal)
	for _, x in { -0.45, 0.45 } do
		part(parent, `{name}Flange{x}`, Vector3.new(0.12, height, 1.2), cf * CFrame.new(x, height / 2, 0), STEEL, Enum.Material.Metal)
	end
end

-- Trapezblech-Wand: Grundplatte mit senkrechten Sicken
local function corrugatedWall(parent: Instance, name: string, width: number, height: number, cf: CFrame, color: Color3)
	part(parent, name, Vector3.new(width, height, 0.6), cf, color, Enum.Material.Metal)
	local ribs = math.floor(width / 2)
	for i = 1, ribs do
		local x = -width / 2 + (i - 0.5) * (width / ribs)
		part(parent, `{name}Rib{i}`, Vector3.new(0.5, height, 0.2), cf * CFrame.new(x, 0, -0.38), color:Lerp(Color3.new(0, 0, 0), 0.12), Enum.Material.Metal)
	end
end

local function hazardStrip(parent: Instance, name: string, length: number, cf: CFrame)
	local n = math.max(2, math.floor(length / 1.2))
	local w = length / n
	for i = 1, n do
		part(parent, `{name}{i}`, Vector3.new(w, 0.05, 0.6), cf * CFrame.new(-length / 2 + w * (i - 0.5), 0, 0), if i % 2 == 0 then HAZARD_BLACK else HAZARD_YELLOW, Enum.Material.SmoothPlastic)
	end
end

function MachineShopBuilder.build(parent: Instance): Model
	local cfg = LayoutConfig.MachineShop
	local center = LayoutConfig.MapCenter
	local pos = Vector3.new(center.X + cfg.Offset.X, LayoutConfig.GroundY + 1, center.Z + cfg.Offset.Y)
	-- LookVector (= lokale -Z, Rolltor) zeigt zur Platzmitte
	local o = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))

	local W, H, D = cfg.Size.X, cfg.Size.Y, cfg.Size.Z
	local t = 0.8
	local model = Instance.new("Model")
	model.Name = "MachineShop"

	local floor = part(model, "Floor", Vector3.new(W, 0.6, D), o * CFrame.new(0, 0.3, 0), CONCRETE, Enum.Material.Concrete)
	model.PrimaryPart = floor
	-- Gelbe Fahrlinie vom Tor zur Plattform
	hazardStrip(model, "FloorLineL", D - 6, o * CFrame.new(-7, 0.62, 0) * CFrame.Angles(0, math.rad(90), 0))
	hazardStrip(model, "FloorLineR", D - 6, o * CFrame.new(7, 0.62, 0) * CFrame.Angles(0, math.rad(90), 0))

	-- Wände (Trapezblech orange) und Sockel aus Beton
	corrugatedWall(model, "WallBack", W, H, o * CFrame.new(0, H / 2, D / 2 - t / 2) * CFrame.Angles(0, math.rad(180), 0), ORANGE)
	corrugatedWall(model, "WallLeft", D, H, o * CFrame.new(W / 2 - t / 2, H / 2, 0) * CFrame.Angles(0, math.rad(-90), 0), ORANGE)
	corrugatedWall(model, "WallRight", D, H, o * CFrame.new(-W / 2 + t / 2, H / 2, 0) * CFrame.Angles(0, math.rad(90), 0), ORANGE)
	part(model, "PlinthBack", Vector3.new(W, 2, t + 0.4), o * CFrame.new(0, 1, D / 2 - t / 2), CONCRETE_DARK, Enum.Material.Concrete)
	part(model, "PlinthLeft", Vector3.new(t + 0.4, 2, D), o * CFrame.new(W / 2 - t / 2, 1, 0), CONCRETE_DARK, Enum.Material.Concrete)
	part(model, "PlinthRight", Vector3.new(t + 0.4, 2, D), o * CFrame.new(-W / 2 + t / 2, 1, 0), CONCRETE_DARK, Enum.Material.Concrete)

	-- Front mit großem offenem Rolltor (docs/10 §26: große Hallentore)
	local front = -D / 2 + t / 2
	local doorW, doorH = 20, 12
	local sideW = (W - doorW) / 2
	for _, side in { 1, -1 } do
		local x = side * (doorW / 2 + sideW / 2)
		corrugatedWall(model, `Front{side}`, sideW, H, o * CFrame.new(x, H / 2, front), ORANGE)
	end
	part(model, "DoorHeader", Vector3.new(doorW, H - doorH, t), o * CFrame.new(0, doorH + (H - doorH) / 2, front), ORANGE_DARK, Enum.Material.Metal)
	-- Aufgerolltes Tor im Kasten über der Öffnung
	part(model, "DoorBox", Vector3.new(doorW + 1, 1.6, 1.6), o * CFrame.new(0, doorH + 0.8, front + 1.2), STEEL_DARK, Enum.Material.Metal)
	for _, side in { 1, -1 } do
		part(model, `DoorRail{side}`, Vector3.new(0.5, doorH, 0.8), o * CFrame.new(side * (doorW / 2 - 0.25), doorH / 2, front + 0.8), STEEL, Enum.Material.Metal)
		-- Warnanstrich an den Torpfosten (senkrechte Streifen)
		for i = 1, 8 do
			local h = doorH / 8
			part(model, `DoorPost{side}_{i}`, Vector3.new(0.7, h, 0.1), o * CFrame.new(side * (doorW / 2 + 0.35), h * (i - 0.5), front - 0.42), if i % 2 == 0 then HAZARD_BLACK else HAZARD_YELLOW, Enum.Material.SmoothPlastic)
		end
	end

	-- Stahlstützen und Dachträger
	for _, x in { -W / 2 + 1.2, W / 2 - 1.2 } do
		for _, z in { -D / 2 + 1.2, 0, D / 2 - 1.2 } do
			column(model, `Column{x}_{z}`, H, o * CFrame.new(x, 0.6, z))
		end
	end
	for i, z in { -D / 2 + 1.2, 0, D / 2 - 1.2 } do
		part(model, `Truss{i}`, Vector3.new(W - 1, 1, 0.6), o * CFrame.new(0, H - 0.6, z), STEEL, Enum.Material.Metal)
	end
	part(model, "Roof", Vector3.new(W + 2, 0.8, D + 2), o * CFrame.new(0, H + 0.4, 0), STEEL_DARK, Enum.Material.Metal)
	part(model, "RoofTrim", Vector3.new(W + 2.4, 0.6, 0.6), o * CFrame.new(0, H + 0.3, -D / 2 - 1), ORANGE_DARK, Enum.Material.Metal)

	-- Schild über dem Tor
	local sign = part(model, "Sign", Vector3.new(24, 4, 0.5), o * CFrame.new(0, H - 2.4, -D / 2 - 0.5), STEEL_DARK, Enum.Material.SmoothPlastic)
	surfaceText(sign, "⚙  MACHINES", ORANGE)
	part(model, "SignFrame", Vector3.new(24.6, 4.6, 0.3), o * CFrame.new(0, H - 2.4, -D / 2 - 0.3), ORANGE_DARK, Enum.Material.Metal)

	-- Maschinenplattform in der Mitte mit Ausstellungs-Drills (erste und letzte Stufe)
	local platform = Instance.new("Folder")
	platform.Name = "DrillDisplay"
	platform.Parent = model
	part(platform, "Platform", Vector3.new(24, 1, 20), o * CFrame.new(0, 1.1, 5), CONCRETE_DARK, Enum.Material.Concrete)
	part(platform, "PlatformTop", Vector3.new(23.4, 0.2, 19.4), o * CFrame.new(0, 1.7, 5), STEEL, Enum.Material.DiamondPlate)
	hazardStrip(platform, "PlatformEdge", 23.4, o * CFrame.new(0, 1.82, -4.3))
	local shown = { Drills.List[1], Drills.List[#Drills.List] }
	if shown[1] == shown[2] then
		shown = { shown[1] }
	end
	for i, def in shown do
		local x = if #shown == 1 then 0 else (i == 1 and -6 or 5)
		-- Bohrkopf zeigt leicht schräg zum Eingang
		local display = DrillModelBuilder.build(def, o * CFrame.new(x, 1.8, 6) * CFrame.Angles(0, math.rad(if i == 1 then 10 else -10), 0))
		display.Parent = platform
		local plate = part(platform, `InfoPlate{i}`, Vector3.new(3.6, 1.2, 0.2), o * CFrame.new(x, 2.4, -5.2) * CFrame.Angles(math.rad(-15), 0, 0), STEEL_DARK, Enum.Material.SmoothPlastic)
		surfaceText(plate, def.DisplayName:upper(), WHITE)
	end

	-- Werkzeugwand und Werkbank links (docs/10 §26)
	local tools = Instance.new("Folder")
	tools.Name = "Workshop"
	tools.Parent = model
	local wallX = W / 2 - t - 0.3
	part(tools, "Pegboard", Vector3.new(0.2, 6, 12), o * CFrame.new(wallX, 7, 4), PEGBOARD, Enum.Material.WoodPlanks)
	local toolDefs = {
		{ size = Vector3.new(0.2, 2.4, 0.3), y = 8.4, z = 0, color = STEEL },
		{ size = Vector3.new(0.2, 1.8, 0.6), y = 8.6, z = 1.5, color = ORANGE_DARK },
		{ size = Vector3.new(0.2, 2.8, 0.25), y = 8.2, z = 3, color = STEEL_DARK },
		{ size = Vector3.new(0.2, 1.4, 1.2), y = 7.0, z = 4.8, color = HAZARD_YELLOW },
		{ size = Vector3.new(0.2, 2.2, 0.35), y = 8.4, z = 6.6, color = STEEL },
		{ size = Vector3.new(0.2, 1.2, 0.9), y = 6.0, z = 8.2, color = Color3.fromRGB(190, 50, 40) },
	}
	for i, tool in toolDefs do
		part(tools, `Tool{i}`, tool.size, o * CFrame.new(wallX - 0.2, tool.y, tool.z - 0.5), tool.color, Enum.Material.Metal)
	end
	part(tools, "Workbench", Vector3.new(3, 0.4, 10), o * CFrame.new(wallX - 1.8, 3.4, 4), WOOD, Enum.Material.Wood)
	for _, z in { 0, 8 } do
		part(tools, `BenchLeg{z}`, Vector3.new(2.6, 3, 0.4), o * CFrame.new(wallX - 1.8, 1.7, z), STEEL_DARK, Enum.Material.Metal)
	end
	part(tools, "Vise", Vector3.new(1, 0.8, 0.8), o * CFrame.new(wallX - 1.8, 4, 1), STEEL, Enum.Material.Metal)
	part(tools, "Toolbox", Vector3.new(1.4, 1, 2.2), o * CFrame.new(wallX - 1.8, 4.1, 6), Color3.fromRGB(190, 50, 40), Enum.Material.Metal)
	-- Gasflaschen und Ersatzteilregal in der hinteren Ecke
	for i, z in { D / 2 - 2.2, D / 2 - 3.6 } do
		local bottle = part(tools, `GasBottle{i}`, Vector3.new(3.2, 1.1, 1.1), o * CFrame.new(wallX - 0.8, 2.2, z) * CFrame.Angles(0, 0, math.rad(90)), if i == 1 then Color3.fromRGB(60, 110, 60) else Color3.fromRGB(70, 90, 150), Enum.Material.Metal)
		bottle.Shape = Enum.PartType.Cylinder
	end

	-- Tresen rechts mit Shop-Prompt und Monitor (technische Displays, docs/10 §26)
	local counterCF = o * CFrame.new(-W / 2 + 6, 0, 2)
	part(model, "Counter", Vector3.new(3, 3.6, 12), counterCF * CFrame.new(0, 2.1, 0), STEEL_DARK, Enum.Material.Metal)
	part(model, "CounterTop", Vector3.new(3.6, 0.3, 12.6), counterCF * CFrame.new(0, 4.05, 0), ORANGE_DARK, Enum.Material.Metal)
	part(model, "CounterStripe", Vector3.new(0.05, 0.5, 12), counterCF * CFrame.new(-1.53, 3.4, 0), HAZARD_YELLOW, Enum.Material.SmoothPlastic)
	part(model, "MonitorStand", Vector3.new(0.4, 1, 0.4), counterCF * CFrame.new(0, 4.7, -3), STEEL, Enum.Material.Metal)
	local monitor = part(model, "Monitor", Vector3.new(0.3, 1.6, 2.4), counterCF * CFrame.new(0, 5.8, -3), STEEL_DARK, Enum.Material.SmoothPlastic)
	local screen = part(model, "MonitorScreen", Vector3.new(0.05, 1.3, 2.1), counterCF * CFrame.new(-0.18, 5.8, -3), Color3.fromRGB(40, 140, 200), Enum.Material.Neon)
	screen.Transparency = 0.2
	monitor.CastShadow = false
	local promptPart = part(model, "CounterPromptPart", Vector3.new(2, 4, 4), counterCF * CFrame.new(2.6, 3, 0), WHITE, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Machines"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ShopId", "machine")
	prompt.Parent = promptPart

	-- Hallenstrahler
	for i, z in { -D / 4, D / 4 } do
		for j, x in { -W / 4, W / 4 } do
			part(model, `LampWire{i}_{j}`, Vector3.new(0.1, 1.6, 0.1), o * CFrame.new(x, H - 1.9, z), STEEL_DARK, Enum.Material.Metal)
			local shade = part(model, `LampShade{i}_{j}`, Vector3.new(0.6, 2.4, 2.4), o * CFrame.new(x, H - 2.9, z) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
			shade.Shape = Enum.PartType.Cylinder
			local bulb = part(model, `Lamp{i}_{j}`, Vector3.new(1.4, 0.2, 1.4), o * CFrame.new(x, H - 3.25, z), LIGHT, Enum.Material.Neon)
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Range = 24
			light.Angle = 100
			light.Brightness = 1.4
			light.Color = LIGHT
			light.Parent = bulb
		end
	end

	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

return table.freeze(MachineShopBuilder)
