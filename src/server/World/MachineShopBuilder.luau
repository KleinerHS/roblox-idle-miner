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
local ShopDecor = require(script.Parent.ShopDecor)
local ShopInterior = require(script.Parent.ShopInterior)

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
local STEEL_LIGHT_C = Color3.fromRGB(150, 154, 160)

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
	-- D-057: mit SectorAngle parallel zum Sektor ausgerichtet (Eingang zum Kreisverkehr)
	local sector = (cfg :: any).SectorAngle
	local o = if typeof(sector) == "number"
		then CFrame.lookAt(pos, pos - Vector3.new(math.cos(math.rad(sector)), 0, -math.sin(math.rad(sector))))
		else CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))

	local W, H, D = cfg.Size.X, cfg.Size.Y, cfg.Size.Z
	local t = 0.8
	local model = Instance.new("Model")
	model.Name = "MachineShop"

	local floor = part(model, "Floor", Vector3.new(W, 0.6, D), o * CFrame.new(0, 0.3, 0), CONCRETE, Enum.Material.Concrete)
	model.PrimaryPart = floor
	-- Gelbe Leitlinien im Eingangsbereich
	hazardStrip(model, "FloorLineL", 12, o * CFrame.new(-7, 0.62, -D / 2 + 8) * CFrame.Angles(0, math.rad(90), 0))
	hazardStrip(model, "FloorLineR", 12, o * CFrame.new(7, 0.62, -D / 2 + 8) * CFrame.Angles(0, math.rad(90), 0))

	-- Wände (Trapezblech orange) und Sockel aus Beton
	corrugatedWall(model, "WallBack", W, H, o * CFrame.new(0, H / 2, D / 2 - t / 2) * CFrame.Angles(0, math.rad(180), 0), ORANGE)
	corrugatedWall(model, "WallLeft", D, H, o * CFrame.new(W / 2 - t / 2, H / 2, 0) * CFrame.Angles(0, math.rad(-90), 0), ORANGE)
	corrugatedWall(model, "WallRight", D, H, o * CFrame.new(-W / 2 + t / 2, H / 2, 0) * CFrame.Angles(0, math.rad(90), 0), ORANGE)
	part(model, "PlinthBack", Vector3.new(W, 2, t + 0.4), o * CFrame.new(0, 1, D / 2 - t / 2), CONCRETE_DARK, Enum.Material.Concrete)
	part(model, "PlinthLeft", Vector3.new(t + 0.4, 2, D), o * CFrame.new(W / 2 - t / 2, 1, 0), CONCRETE_DARK, Enum.Material.Concrete)
	part(model, "PlinthRight", Vector3.new(t + 0.4, 2, D), o * CFrame.new(-W / 2 + t / 2, 1, 0), CONCRETE_DARK, Enum.Material.Concrete)

	-- Front mit großem offenem Rolltor (docs/10 §26: große Hallentore)
	local front = -D / 2 + t / 2
	local doorW, doorH = 28, 16
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

	-- Einladend (D-060): Dachschild, Vordach, Strahler, Fahnen, Pflanzen, Drill im Schaufenster draußen
	ShopDecor.roofSign(model, "RoofSign", o * CFrame.new(0, H + 5, -D / 2 + 2), W * 0.7, 6.4, "⚙ DRILLS & MACHINES", ORANGE, WHITE, STEEL_DARK)
	ShopDecor.awning(model, "DoorAwning", o * CFrame.new(0, doorH + 2.4, -D / 2 - 0.5), doorW + 8, 5, ORANGE, STEEL_DARK)
	for k = -2, 2 do
		local x = k * (W / 5)
		if math.abs(x) > doorW / 2 + 2 then
			part(model, `FloodArm{k}`, Vector3.new(0.3, 0.3, 2), o * CFrame.new(x, H - 6, -D / 2 - 1), STEEL_DARK, Enum.Material.Metal)
			local head = part(model, `Flood{k}`, Vector3.new(1.4, 0.9, 1), o * CFrame.new(x, H - 6.3, -D / 2 - 2) * CFrame.Angles(math.rad(-35), 0, 0), LIGHT, Enum.Material.Neon)
			head.CastShadow = false
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Range = 20
			light.Angle = 70
			light.Brightness = 1.2
			light.Color = LIGHT
			light.Parent = head
		end
	end
	for _, side in { -1, 1 } do
		ShopDecor.flag(model, `Flag{side}`, o * CFrame.new(side * (W / 2 + 3), 0, -D / 2 - 2), if side > 0 then ORANGE else STEEL_DARK)
		ShopDecor.planter(model, `DoorPlanter{side}`, o * CFrame.new(side * (doorW / 2 + 2.5), 0.6, -D / 2 - 2), 2.6)
	end
	do
		local showDef = Drills.List[math.min(#Drills.List, 3)]
		local top = ShopDecor.podium(model, "Showcase", o * CFrame.new(W / 2 - 10, 0, -D / 2 - 6), 3.2, ORANGE, H - 2)
		local show = DrillModelBuilder.build(showDef, top * CFrame.new(0, 0.2, 0))
		show.Name = "ShowcaseDrill"
		show.Parent = model
		local plate = part(model, "ShowcasePlate", Vector3.new(5, 1.2, 0.2), top * CFrame.new(0, -0.4, -3.5) * CFrame.Angles(math.rad(-20), 0, 0), STEEL_DARK, Enum.Material.SmoothPlastic)
		surfaceText(plate, showDef.DisplayName:upper(), WHITE)
	end

	-- Maschinenplattform in der Mitte mit allen drei Drills (Rückmeldung Felix 2026-10-10)
	local platform = Instance.new("Folder")
	platform.Name = "DrillDisplay"
	platform.Parent = model
	part(platform, "Platform", Vector3.new(32, 1, 22), o * CFrame.new(0, 1.1, 6), CONCRETE_DARK, Enum.Material.Concrete)
	part(platform, "PlatformTop", Vector3.new(31.4, 0.2, 21.4), o * CFrame.new(0, 1.7, 6), STEEL, Enum.Material.DiamondPlate)
	hazardStrip(platform, "PlatformEdge", 31.4, o * CFrame.new(0, 1.82, -4.4))
	-- Vom Eingang aus gesehen links nach rechts: MK1, MK2, MK3 (lokal +X ist links)
	local slots = { 10.5, 0, -10.5 }
	-- Ausgestellt sind MK1–MK3 (Plattform hat drei Plätze); höhere Stufen nur im Shop-Fenster
	for i, def in Drills.List do
		if i > #slots then
			break
		end
		local x = slots[i]
		-- Bohrkopf zeigt zum Eingang
		local display = DrillModelBuilder.build(def, o * CFrame.new(x, 1.8, 7))
		display.Parent = platform
		part(platform, `InfoStandPost{i}`, Vector3.new(0.3, 1.8, 0.3), o * CFrame.new(x - 3, 1.5, -7.2), STEEL_DARK, Enum.Material.Metal)
		local plate = part(platform, `InfoPlate{i}`, Vector3.new(3.6, 1.2, 0.2), o * CFrame.new(x - 3, 2.6, -7.3) * CFrame.Angles(math.rad(-15), 0, 0), STEEL_DARK, Enum.Material.SmoothPlastic)
		surfaceText(plate, def.DisplayName:upper(), WHITE)
	end

	-- Werkstatt links (lokal +X): zwischen den Wandstützen bei z = 0 und z = D/2 − 1.2
	local tools = Instance.new("Folder")
	tools.Name = "Workshop"
	tools.Parent = model
	local wallX = W / 2 - t - 0.1 -- Innenseite der linken Wand
	local benchZ, benchLen = 9.5, 13
	-- Lochwand mit Werkzeugen, darüber ein Regalbrett mit Dosen
	part(tools, "Pegboard", Vector3.new(0.2, 5, benchLen + 1), o * CFrame.new(wallX - 0.1, 7.2, benchZ), PEGBOARD, Enum.Material.WoodPlanks)
	part(tools, "PegboardFrame", Vector3.new(0.25, 5.4, benchLen + 1.4), o * CFrame.new(wallX - 0.05, 7.2, benchZ), STEEL_DARK, Enum.Material.Metal)
	local toolDefs = {
		{ size = Vector3.new(0.15, 2.2, 0.3), y = 7.8, z = -5, color = STEEL }, -- Schraubenschlüssel
		{ size = Vector3.new(0.15, 0.5, 1), y = 8.8, z = -5, color = STEEL },
		{ size = Vector3.new(0.15, 1.8, 0.25), y = 7.6, z = -3.4, color = WOOD }, -- Hammer
		{ size = Vector3.new(0.15, 0.5, 1.1), y = 8.4, z = -3.4, color = STEEL_DARK },
		{ size = Vector3.new(0.15, 1.6, 0.2), y = 7.6, z = -2, color = HAZARD_YELLOW }, -- Schraubendreher
		{ size = Vector3.new(0.15, 1.6, 0.2), y = 7.6, z = -1.4, color = Color3.fromRGB(190, 50, 40) },
		{ size = Vector3.new(0.15, 1.6, 0.2), y = 7.6, z = -0.8, color = Color3.fromRGB(60, 110, 190) },
		{ size = Vector3.new(0.15, 1.2, 2.6), y = 7.6, z = 1.2, color = STEEL }, -- Säge
		{ size = Vector3.new(0.15, 1.6, 0.6), y = 7.4, z = 3.6, color = ORANGE_DARK }, -- Akkuschrauber
		{ size = Vector3.new(0.15, 1, 0.9), y = 6.3, z = 3.6, color = STEEL_DARK },
	}
	for i, tool in toolDefs do
		part(tools, `Tool{i}`, tool.size, o * CFrame.new(wallX - 0.28, tool.y, benchZ + tool.z), tool.color, Enum.Material.Metal)
	end
	part(tools, "Shelf", Vector3.new(1.2, 0.2, benchLen), o * CFrame.new(wallX - 0.7, 10.2, benchZ), STEEL_DARK, Enum.Material.Metal)
	for i = 1, 6 do
		local can = part(tools, `PaintCan{i}`, Vector3.new(0.9, 0.8, 0.8), o * CFrame.new(wallX - 0.7, 10.75, benchZ - 5.5 + i * 1.6) * CFrame.Angles(0, 0, math.rad(90)), ({ ORANGE, HAZARD_YELLOW, Color3.fromRGB(60, 110, 190), Color3.fromRGB(190, 50, 40) })[(i - 1) % 4 + 1], Enum.Material.Metal)
		can.Shape = Enum.PartType.Cylinder
	end
	-- Werkbank mit Unterschränken
	local benchX = wallX - 1.9
	part(tools, "Workbench", Vector3.new(3.4, 0.35, benchLen), o * CFrame.new(benchX, 3.6, benchZ), WOOD, Enum.Material.Wood)
	part(tools, "WorkbenchEdge", Vector3.new(0.15, 0.4, benchLen), o * CFrame.new(benchX - 1.7, 3.6, benchZ), STEEL_DARK, Enum.Material.Metal)
	for i, dz in { -4.5, 4.5 } do
		part(tools, `BenchCabinet{i}`, Vector3.new(3, 2.8, 3.4), o * CFrame.new(benchX, 2, benchZ + dz), Color3.fromRGB(190, 50, 40), Enum.Material.Metal)
		for d = 1, 3 do
			part(tools, `BenchDrawer{i}_{d}`, Vector3.new(0.08, 0.06, 3), o * CFrame.new(benchX - 1.53, 1.1 + d * 0.75, benchZ + dz), STEEL_DARK, Enum.Material.Metal)
		end
	end
	part(tools, "BenchLegMid", Vector3.new(0.3, 2.8, 0.3), o * CFrame.new(benchX - 1.3, 2, benchZ), STEEL_DARK, Enum.Material.Metal)
	-- Schraubstock, Schleifbock, Ständerbohrmaschine, Arbeitsleuchte
	part(tools, "Vise", Vector3.new(1.2, 0.7, 1), o * CFrame.new(benchX - 0.9, 4.15, benchZ - 5.4), STEEL, Enum.Material.Metal)
	part(tools, "ViseJaw", Vector3.new(0.3, 0.5, 1.1), o * CFrame.new(benchX - 1.6, 4.2, benchZ - 5.4), STEEL_DARK, Enum.Material.Metal)
	part(tools, "GrinderBody", Vector3.new(1, 0.8, 1.4), o * CFrame.new(benchX, 4.2, benchZ - 1), Color3.fromRGB(60, 110, 60), Enum.Material.Metal)
	for _, dz in { -0.95, 0.95 } do
		local disc = part(tools, `GrinderDisc{dz}`, Vector3.new(0.3, 1.1, 1.1), o * CFrame.new(benchX, 4.3, benchZ - 1 + dz) * CFrame.Angles(0, math.rad(90), 0), STEEL_LIGHT_C, Enum.Material.Slate)
		disc.Shape = Enum.PartType.Cylinder
	end
	part(tools, "DrillPressBase", Vector3.new(1.4, 0.2, 1.4), o * CFrame.new(benchX, 3.88, benchZ + 4.6), STEEL_DARK, Enum.Material.Metal)
	part(tools, "DrillPressColumn", Vector3.new(0.25, 3, 0.25), o * CFrame.new(benchX + 0.4, 5.3, benchZ + 4.6), STEEL, Enum.Material.Metal)
	part(tools, "DrillPressHead", Vector3.new(1, 0.9, 0.9), o * CFrame.new(benchX - 0.1, 6.6, benchZ + 4.6), ORANGE_DARK, Enum.Material.Metal)
	part(tools, "DrillPressChuck", Vector3.new(0.15, 0.9, 0.15), o * CFrame.new(benchX - 0.3, 5.75, benchZ + 4.6), STEEL_DARK, Enum.Material.Metal)
	part(tools, "LampPost", Vector3.new(0.15, 2.2, 0.15), o * CFrame.new(benchX + 1, 4.85, benchZ + 2.55), STEEL_DARK, Enum.Material.Metal)
	part(tools, "LampArm", Vector3.new(0.12, 0.12, 2.2), o * CFrame.new(benchX + 1, 6.4, benchZ + 1.6) * CFrame.Angles(math.rad(30), 0, 0), STEEL_DARK, Enum.Material.Metal)
	local workLamp = part(tools, "WorkLamp", Vector3.new(0.7, 0.4, 0.7), o * CFrame.new(benchX + 1, 6.9, benchZ + 0.6), LIGHT, Enum.Material.Neon)
	local workLight = Instance.new("SpotLight")
	workLight.Face = Enum.NormalId.Bottom
	workLight.Range = 10
	workLight.Angle = 70
	workLight.Brightness = 1.2
	workLight.Color = LIGHT
	workLight.Parent = workLamp
	-- Werkzeugwagen vor der Werkbank
	local cart = o * CFrame.new(benchX - 4.4, 0, benchZ - 2)
	part(tools, "ToolCart", Vector3.new(1.6, 2.4, 2.4), cart * CFrame.new(0, 2, 0), Color3.fromRGB(190, 50, 40), Enum.Material.Metal)
	part(tools, "ToolCartTop", Vector3.new(1.7, 0.12, 2.5), cart * CFrame.new(0, 3.26, 0), STEEL_DARK, Enum.Material.Metal)
	for _, dz in { -0.9, 0.9 } do
		for _, dx in { -0.6, 0.6 } do
			local wheel = part(tools, `CartWheel{dx}_{dz}`, Vector3.new(0.25, 0.5, 0.5), cart * CFrame.new(dx, 0.85, dz), STEEL_DARK, Enum.Material.Rubber)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	-- Gasflaschen vorne links (frei von Stützen)
	for i, z in { -16.2, -15 } do
		local bottle = part(tools, `GasBottle{i}`, Vector3.new(3.2, 1.1, 1.1), o * CFrame.new(wallX - 1, 2.2, z) * CFrame.Angles(0, 0, math.rad(90)), if i == 1 then Color3.fromRGB(60, 110, 60) else Color3.fromRGB(70, 90, 150), Enum.Material.Metal)
		bottle.Shape = Enum.PartType.Cylinder
	end
	part(tools, "BottleChain", Vector3.new(0.1, 0.1, 2.6), o * CFrame.new(wallX - 0.45, 3, -15.6), STEEL_DARK, Enum.Material.Metal)

	-- Kasse direkt rechts hinter dem Eingang (lokal −X; Rückmeldung Felix)
	local counterCF = o * CFrame.new(-W / 2 + 5, 0, -D / 2 + 9)
	part(model, "Counter", Vector3.new(3, 3.6, 9), counterCF * CFrame.new(0, 2.4, 0), STEEL_DARK, Enum.Material.Metal)
	part(model, "CounterTop", Vector3.new(3.6, 0.3, 9.6), counterCF * CFrame.new(0, 4.35, 0), ORANGE_DARK, Enum.Material.Metal)
	part(model, "CounterStripe", Vector3.new(0.05, 0.5, 9), counterCF * CFrame.new(1.53, 3.6, 0), HAZARD_YELLOW, Enum.Material.SmoothPlastic)
	part(model, "Register", Vector3.new(1.2, 0.6, 1.4), counterCF * CFrame.new(0, 4.8, -2.4), STEEL, Enum.Material.Metal)
	part(model, "MonitorStand", Vector3.new(0.4, 0.8, 0.4), counterCF * CFrame.new(0, 4.9, 1.6), STEEL, Enum.Material.Metal)
	local monitor = part(model, "Monitor", Vector3.new(0.3, 1.6, 2.4), counterCF * CFrame.new(0, 5.9, 1.6), STEEL_DARK, Enum.Material.SmoothPlastic)
	local screen = part(model, "MonitorScreen", Vector3.new(0.05, 1.3, 2.1), counterCF * CFrame.new(0.18, 5.9, 1.6), Color3.fromRGB(40, 140, 200), Enum.Material.Neon)
	screen.Transparency = 0.2
	monitor.CastShadow = false
	local cashSign = part(model, "CashSign", Vector3.new(6.5, 1.4, 0.2), counterCF * CFrame.new(0, 9, 0), STEEL_DARK, Enum.Material.SmoothPlastic)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 40
	signGui.LightInfluence = 0
	signGui.Parent = cashSign
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Font = Enum.Font.GothamBlack
	signLabel.TextScaled = true
	signLabel.TextColor3 = ORANGE
	signLabel.Text = "$  CASHIER"
	signLabel.Parent = signGui
	for _, dz in { -2.2, 2.2 } do
		part(model, `CashSignChain{dz}`, Vector3.new(0.06, H - 9.7, 0.06), counterCF * CFrame.new(dz * 1.3, 9.7 + (H - 9.7) / 2, 0), STEEL_DARK, Enum.Material.Metal)
	end
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

	-- Dekoration: Teileregale hinten, Spinde, Ölfässer, Ersatzbohrköpfe, Laufkran, Schilder
	local deco = Instance.new("Folder")
	deco.Name = "Decoration"
	deco.Parent = model
	local boxColors = { ORANGE, Color3.fromRGB(60, 110, 190), HAZARD_YELLOW, Color3.fromRGB(70, 74, 80), Color3.fromRGB(190, 50, 40) }
	local rng = Random.new(77)
	for r, rackX in { -18, -2 } do
		local rack = o * CFrame.new(rackX, 0, D / 2 - t - 1.3)
		for _, dx in { -4, 4 } do
			part(deco, `Rack{r}Post{dx}`, Vector3.new(0.3, 8, 0.3), rack * CFrame.new(dx, 4.6, -0.8), ORANGE_DARK, Enum.Material.Metal)
			part(deco, `Rack{r}PostB{dx}`, Vector3.new(0.3, 8, 0.3), rack * CFrame.new(dx, 4.6, 0.8), ORANGE_DARK, Enum.Material.Metal)
		end
		for level = 1, 3 do
			local y = 0.6 + level * 2.4
			part(deco, `Rack{r}Shelf{level}`, Vector3.new(8.4, 0.2, 2), rack * CFrame.new(0, y, 0), STEEL, Enum.Material.Metal)
			for b = 1, 4 do
				local bh = rng:NextNumber(0.8, 1.6)
				part(deco, `Rack{r}Box{level}_{b}`, Vector3.new(rng:NextNumber(1.1, 1.5), bh, 1.5), rack * CFrame.new(-3 + (b - 1) * 2, y + 0.1 + bh / 2, 0), boxColors[rng:NextInteger(1, #boxColors)], Enum.Material.SmoothPlastic)
			end
		end
	end
	-- Spinde an der rechten Wand
	for i = 1, 4 do
		local locker = o * CFrame.new(-W / 2 + t + 1.1, 0, 2.6 + (i - 1) * 1.6)
		part(deco, `Locker{i}`, Vector3.new(1.4, 5.5, 1.5), locker * CFrame.new(0, 3.35, 0), Color3.fromRGB(60, 90, 130), Enum.Material.Metal)
		part(deco, `LockerVent{i}`, Vector3.new(0.05, 0.6, 1), locker * CFrame.new(0.72, 5.3, 0), STEEL_DARK, Enum.Material.Metal)
		part(deco, `LockerHandle{i}`, Vector3.new(0.08, 0.5, 0.12), locker * CFrame.new(0.74, 3.6, 0.5), STEEL_LIGHT_C, Enum.Material.Metal)
	end
	-- Ölfässer auf Auffangwanne
	part(deco, "SpillPallet", Vector3.new(4, 0.4, 4), o * CFrame.new(-W / 2 + 3.6, 0.8, 13.2), HAZARD_YELLOW, Enum.Material.SmoothPlastic)
	for i, p in { Vector2.new(-0.9, -0.9), Vector2.new(0.9, -0.9), Vector2.new(0, 0.9) } do
		local drum = part(deco, `Drum{i}`, Vector3.new(2.6, 1.6, 1.6), o * CFrame.new(-W / 2 + 3.6 + p.X, 2.3, 13.2 + p.Y) * CFrame.Angles(0, 0, math.rad(90)), if i == 3 then Color3.fromRGB(190, 50, 40) else Color3.fromRGB(40, 90, 150), Enum.Material.Metal)
		drum.Shape = Enum.PartType.Cylinder
	end
	-- Ersatzbohrköpfe auf einem Ständer neben der Plattform
	local stand = o * CFrame.new(15, 0, -9.5)
	part(deco, "BitStandBase", Vector3.new(2.4, 0.3, 2.4), stand * CFrame.new(0, 0.75, 0), STEEL_DARK, Enum.Material.Metal)
	for i = 1, 3 do
		local a = math.rad(i * 120)
		local bitCF = stand * CFrame.new(math.cos(a) * 0.6, 1.4, math.sin(a) * 0.6)
		local core = part(deco, `SpareBit{i}`, Vector3.new(1, 0.7, 0.7), bitCF * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 92, 98), Enum.Material.Metal)
		core.Shape = Enum.PartType.Cylinder
		part(deco, `SpareBitTip{i}`, Vector3.new(0.3, 0.4, 0.3), bitCF * CFrame.new(0, 0.7, 0), STEEL_LIGHT_C, Enum.Material.SmoothPlastic)
	end
	-- Laufkran mit Kette und Haken über der Plattform
	part(deco, "CraneRail", Vector3.new(W - 4, 0.8, 0.8), o * CFrame.new(0, H - 1.8, 7), STEEL_DARK, Enum.Material.Metal)
	part(deco, "CraneTrolley", Vector3.new(1.6, 1, 1.4), o * CFrame.new(10.5, H - 2.7, 7), HAZARD_YELLOW, Enum.Material.Metal)
	part(deco, "CraneChain", Vector3.new(0.15, 4, 0.15), o * CFrame.new(10.5, H - 5.2, 7), STEEL_DARK, Enum.Material.Metal)
	part(deco, "CraneHook", Vector3.new(0.6, 0.6, 0.3), o * CFrame.new(10.5, H - 7.4, 7), HAZARD_YELLOW, Enum.Material.Metal)
	-- Sicherheitsschilder innen an der Frontwand und Feuerlöscher an Stützen
	for i, text in { "SAFETY FIRST", "PPE REQUIRED" } do
		local sign = part(deco, `SafetySign{i}`, Vector3.new(4, 1.4, 0.1), o * CFrame.new(if i == 1 then -16 else 16, 8, -D / 2 + t + 0.1), Color3.fromRGB(30, 110, 60), Enum.Material.SmoothPlastic)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0.5
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = WHITE
		label.Text = text
		label.Parent = gui
	end
	for i, z in { -D / 2 + 1.2, D / 2 - 1.2 } do
		local extCF = o * CFrame.new(-W / 2 + t + 0.75, 3.4, z + (if i == 1 then 1.4 else -1.4))
		part(deco, `ExtinguisherBracket{i}`, Vector3.new(0.8, 0.2, 0.6), extCF * CFrame.new(-0.45, 0.3, 0), STEEL_DARK, Enum.Material.Metal)
		local ext = part(deco, `Extinguisher{i}`, Vector3.new(1.2, 0.5, 0.5), extCF * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)
		ext.Shape = Enum.PartType.Cylinder
	end
	-- Eingangsmatte
	part(deco, "EntranceMat", Vector3.new(12, 0.08, 4), o * CFrame.new(0, 0.64, -D / 2 + 3), STEEL_DARK, Enum.Material.Fabric)

	-- Innenausbau wie ein echter Maschinenhändler (D-063): Showroom vorne, weitere Drills auf
	-- Podesten, Verkaufsplätze, Wartebereich mit Kaffee, Ersatzteiltheke hinten rechts,
	-- Servicebereich hinten links, Hängeschilder, Bodenmarkierungen, Hallenbeleuchtung.
	local inside = Instance.new("Folder")
	inside.Name = "Interior"
	inside.Parent = model
	local rng2 = Random.new(64)
	local DARK = Color3.fromRGB(30, 32, 36)
	local signY = H - 5
	local goods = { ORANGE, HAZARD_YELLOW, Color3.fromRGB(60, 110, 190), Color3.fromRGB(190, 50, 40), STEEL_LIGHT_C }

	-- Bodenzonen: Gehweg-Linien und Servicebereich
	ShopInterior.rug(inside, "ServiceFloor", o * CFrame.new(W / 2 - 13, 0.6, D / 2 - 12), 22, 20, Color3.fromRGB(96, 98, 102))
	local serviceText = part(inside, "ServiceFloorText", Vector3.new(14, 0.05, 3), o * CFrame.new(W / 2 - 13, 0.64, D / 2 - 20), Color3.fromRGB(96, 98, 102), Enum.Material.SmoothPlastic)
	serviceText.CanCollide = false
	ShopInterior.text(serviceText, "SERVICE AREA", HAZARD_YELLOW, Enum.NormalId.Top, true)

	-- Weitere Drills (Stufe 4–6) auf Podesten im vorderen Showroom
	for k = 4, math.min(6, #Drills.List) do
		local def = Drills.List[k]
		local x = W / 2 - 30 + (k - 4) * 10
		local top = ShopDecor.podium(inside, `DrillPodium{k}`, o * CFrame.new(x, 0.6, -D / 2 + 16), 3.4, ORANGE, H - 3)
		local d = DrillModelBuilder.build(def, top * CFrame.new(0, 0.2, 0))
		d.Parent = inside
		local plate = part(inside, `DrillPlate{k}`, Vector3.new(5, 1.1, 0.2), top * CFrame.new(0, -0.4, -3.8) * CFrame.Angles(math.rad(-20), 0, 0), STEEL_DARK, Enum.Material.SmoothPlastic)
		surfaceText(plate, def.DisplayName:upper(), WHITE)
	end
	ShopInterior.hangingSign(inside, "ShowroomSign", o * CFrame.new(0, signY, -2), "SHOWROOM", ORANGE, WHITE, 12, H - 1)

	-- Verkaufsplätze an der rechten Wand (lokal −X): Schreibtisch, Mitarbeiter, zwei Kundenstühle
	for k, z in { -6, 8 } do
		local deskCF = o * CFrame.new(-W / 2 + 9, 0.6, z) * CFrame.Angles(0, math.rad(-90), 0)
		ShopInterior.desk(inside, `SalesDesk{k}`, deskCF, WHITE, ORANGE_DARK)
		ShopInterior.officeChair(inside, `StaffChair{k}`, deskCF * CFrame.new(0, 0, 2.8) * CFrame.Angles(0, math.rad(180), 0), STEEL_DARK)
		for _, dx in { -1.6, 1.6 } do
			ShopInterior.officeChair(inside, `GuestChair{k}{dx}`, deskCF * CFrame.new(dx, 0, -3), Color3.fromRGB(160, 70, 30))
		end
	end
	ShopInterior.hangingSign(inside, "SalesSign", o * CFrame.new(-W / 2 + 11, signY, 1) * CFrame.Angles(0, math.rad(90), 0), "SALES", STEEL_DARK, ORANGE, 8, H - 1)
	ShopInterior.poster(inside, "PosterPower", o * CFrame.new(-W / 2 + t + 0.25, 10, -6) * CFrame.Angles(0, math.rad(-90), 0), 6, 7, "MORE\nPOWER!", ORANGE, WHITE)
	ShopInterior.poster(inside, "PosterDrill", o * CFrame.new(-W / 2 + t + 0.25, 10, 8) * CFrame.Angles(0, math.rad(-90), 0), 6, 7, "DRILL\nDEEPER", STEEL_DARK, HAZARD_YELLOW)
	ShopInterior.brochureStand(inside, "Brochures", o * CFrame.new(-W / 2 + 16, 0.6, 1) * CFrame.Angles(0, math.rad(-90), 0), { ORANGE, HAZARD_YELLOW, WHITE })
	ShopInterior.plant(inside, "SalesPlant", o * CFrame.new(-W / 2 + 4, 0.6, 15), 6)

	-- Wartebereich vorne rechts neben der Kasse: Sessel, Tisch, Kaffee, Fernseher
	local wait = o * CFrame.new(-W / 2 + 12, 0.6, -D / 2 + 17)
	for k, dx in { -4, 0, 4 } do
		ShopInterior.armchair(inside, `WaitChair{k}`, wait * CFrame.new(dx, 0, 2.5) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(70, 74, 80))
	end
	ShopInterior.coffeeTable(inside, "WaitTable", wait * CFrame.new(0, 0, -1.5))
	ShopInterior.coffeeCorner(inside, "Coffee", o * CFrame.new(-W / 2 + 26, 0.6, -D / 2 + 3) * CFrame.Angles(0, math.rad(180), 0))
	ShopInterior.tv(inside, "WaitTV", o * CFrame.new(-W / 2 + t + 0.3, 9, -D / 2 + 17) * CFrame.Angles(0, math.rad(-90), 0), 8, "⚙ NEW: " .. Drills.List[math.min(#Drills.List, 6)].DisplayName:upper(), ORANGE_DARK)

	-- Ersatzteiltheke hinten rechts mit Regalwand
	local partsCF = o * CFrame.new(-W / 2 + 12, 0.6, D / 2 - 12)
	part(inside, "PartsCounter", Vector3.new(14, 3.6, 2.6), partsCF * CFrame.new(0, 1.8, 0), STEEL_DARK, Enum.Material.Metal)
	part(inside, "PartsCounterTop", Vector3.new(14.4, 0.3, 3), partsCF * CFrame.new(0, 3.75, 0), ORANGE_DARK, Enum.Material.Metal)
	part(inside, "PartsBell", Vector3.new(0.6, 0.4, 0.6), partsCF * CFrame.new(-5, 4.1, -0.6), HAZARD_YELLOW, Enum.Material.Metal)
	ShopInterior.officeChair(inside, "PartsChair", partsCF * CFrame.new(2, 0, 3) * CFrame.Angles(0, math.rad(180), 0), STEEL_DARK)
	ShopInterior.wallShelf(inside, "PartsShelf", o * CFrame.new(-W / 2 + 12, 0.6, D / 2 - t - 1.1), 20, 4, goods, rng2)
	ShopInterior.hangingSign(inside, "PartsSign", o * CFrame.new(-W / 2 + 12, signY, D / 2 - 12), "PARTS", HAZARD_YELLOW, DARK, 8, H - 1)

	-- Servicebereich hinten links: Drill auf Hebebühne, Werkzeugwagen, Reifen/Ersatzteile
	local service = o * CFrame.new(W / 2 - 13, 0.6, D / 2 - 11)
	part(inside, "LiftBase", Vector3.new(10, 0.6, 12), service * CFrame.new(0, 0.3, 0), HAZARD_YELLOW, Enum.Material.Metal)
	for _, dx in { -4.2, 4.2 } do
		part(inside, `LiftArm{dx}`, Vector3.new(0.8, 3, 10), service * CFrame.new(dx, 2.1, 0), STEEL, Enum.Material.Metal)
	end
	part(inside, "LiftDeck", Vector3.new(9.4, 0.4, 11), service * CFrame.new(0, 3.8, 0), STEEL_DARK, Enum.Material.DiamondPlate)
	local serviced = DrillModelBuilder.build(Drills.List[1], service * CFrame.new(0, 4, 0) * CFrame.Angles(0, math.rad(90), 0))
	serviced.Name = "ServiceDrill"
	serviced.Parent = inside
	ShopInterior.tireStack(inside, "SpareWheels", service * CFrame.new(-8.5, 0, -6), 3, 1.4)
	ShopInterior.hangingSign(inside, "ServiceSign", o * CFrame.new(W / 2 - 13, signY, D / 2 - 22), "SERVICE", STEEL_DARK, HAZARD_YELLOW, 9, H - 1)

	-- Eingang: Notausgang-Schild, Pflanzen, Uhr
	ShopInterior.exitSign(inside, "ExitSign", o * CFrame.new(0, doorH + 2.4, -D / 2 + t + 0.2) * CFrame.Angles(0, math.rad(180), 0))
	ShopInterior.plant(inside, "EntrancePlantL", o * CFrame.new(doorW / 2 + 3, 0.6, -D / 2 + 3), 5)
	ShopInterior.plant(inside, "EntrancePlantR", o * CFrame.new(-doorW / 2 - 3, 0.6, -D / 2 + 3), 5)
	ShopInterior.clock(inside, "Clock", o * CFrame.new(0, H - 6, D / 2 - t - 0.5))

	-- Hallenstrahler-Raster
	for ix = -2, 2 do
		for iz = -2, 2 do
			local x, z = ix * (W / 5.5), iz * (D / 5.5)
			local lamp = part(inside, `HighBay{ix}_{iz}`, Vector3.new(2.4, 0.3, 2.4), o * CFrame.new(x, H - 2.2, z), LIGHT, Enum.Material.Neon)
			lamp.CanCollide = false
			lamp.CastShadow = false
			part(inside, `HighBayHood{ix}_{iz}`, Vector3.new(3, 0.8, 3), o * CFrame.new(x, H - 1.7, z), STEEL_DARK, Enum.Material.Metal).CanCollide = false
			if (ix + iz) % 2 == 0 then
				local light = Instance.new("SpotLight")
				light.Face = Enum.NormalId.Bottom
				light.Range = 26
				light.Angle = 100
				light.Brightness = 1
				light.Color = LIGHT
				light.Parent = lamp
			end
		end
	end

	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

return table.freeze(MachineShopBuilder)
