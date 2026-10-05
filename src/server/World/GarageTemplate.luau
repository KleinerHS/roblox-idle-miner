--!strict
-- Garage im vorderen Hallenbereich (docs/07 §3–4, §18, D-008, D-016). PLATZHALTER-Optik nach
-- FACTORY_MASTERPLAN_TOPDOWN.png: zwei Stellplätze mit Bodenmarkierung und Nummer, leuchtender
-- Auswahlring, Verladeturm mit Auslegern über beiden Stellplätzen, Werkstatt-Details.
-- Akzente in der Firmenfarbe tragen das Attribut CompanyAccent (BuildingService färbt sie).
--
-- Vereinbarte Namen/Attribute:
--   Part "BaySpawn1"/"BaySpawn2"   – Fahrzeug-Spawn (Bodenmitte, LookVector zum Rolltor)
--   Part "GarageRing"              – Auslöser der Fahrzeugauswahl (Attribut GarageRing = true)
--   Part "LoadPoint1"/"LoadPoint2" – Ende der Ladeschurre über dem Stellplatz (Phase 6c)
--   Part "TowerPanel"              – Bedienpult am Verladeturm (Prompt in Phase 6c)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LayoutConfig)

local GarageTemplate = {}

local YELLOW = Color3.fromRGB(236, 182, 40)
local BLACK = Color3.fromRGB(30, 30, 30)
local WHITE = Color3.fromRGB(235, 235, 230)
local STEEL = Color3.fromRGB(70, 74, 80)
local STEEL_DARK = Color3.fromRGB(44, 46, 50)
local STEEL_LIGHT = Color3.fromRGB(150, 154, 160)
local CONCRETE = Color3.fromRGB(120, 118, 114)
local RUBBER = Color3.fromRGB(28, 28, 30)
local RING = Color3.fromRGB(90, 200, 255)
local CABINET = Color3.fromRGB(190, 50, 40)
local ACCENT_DEFAULT = Color3.fromRGB(242, 166, 46)

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

local function flat(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
end

local function accent(p: BasePart)
	p:SetAttribute("CompanyAccent", true)
end

local function floorText(parent: Instance, name: string, text: string, size: Vector2, cf: CFrame, color: Color3)
	local p = part(parent, name, Vector3.new(size.X, 0.05, size.Y), cf, Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
	p.Transparency = 1
	flat(p)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0.6
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
end

-- Stellplatz: gelbe Umrandung, Nummer, Radstopper hinten, unsichtbarer Spawnpunkt
local function bay(model: Model, index: number, o: CFrame)
	local cfg = LayoutConfig.Garage
	local c = cfg.Bays[index]
	local w, l = cfg.BaySize.X, cfg.BaySize.Y
	local base = o * CFrame.new(c.X, 0, c.Y)
	for _, side in { -1, 1 } do
		local line = part(model, `Bay{index}Side{side}`, Vector3.new(0.5, 0.06, l), base * CFrame.new(side * w / 2, 0.03, 0), YELLOW, Enum.Material.SmoothPlastic)
		flat(line)
	end
	local backLine = part(model, `Bay{index}Back`, Vector3.new(w + 0.5, 0.06, 0.5), base * CFrame.new(0, 0.03, l / 2), YELLOW, Enum.Material.SmoothPlastic)
	flat(backLine)
	-- Gestreifte Einfahrtskante vorne (zum Tor)
	for i = 1, 8 do
		local stripe = part(model, `Bay{index}Front{i}`, Vector3.new(w / 8, 0.06, 0.5), base * CFrame.new(-w / 2 + w / 8 * (i - 0.5), 0.03, -l / 2), if i % 2 == 0 then BLACK else YELLOW, Enum.Material.SmoothPlastic)
		flat(stripe)
	end
	floorText(model, `Bay{index}Number`, tostring(index), Vector2.new(5, 5), base * CFrame.new(0, 0.07, l / 2 - 4) * CFrame.Angles(0, math.rad(180), 0), WHITE)
	-- Radstopper hinten
	for _, side in { -1, 1 } do
		part(model, `Bay{index}WheelStop{side}`, Vector3.new(3, 0.6, 0.8), base * CFrame.new(side * 3, 0.3, l / 2 - 1.2), YELLOW, Enum.Material.SmoothPlastic)
	end
	local spawn = part(model, `BaySpawn{index}`, Vector3.new(2, 1, 2), base * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, 0), WHITE, Enum.Material.SmoothPlastic)
	spawn.Transparency = 1
	flat(spawn)
	spawn:SetAttribute("Bay", index)
end

-- Leuchtring zur Fahrzeugauswahl mit Schrift "VEHICLES"
local function ring(model: Model, o: CFrame)
	local cfg = LayoutConfig.Garage
	local center = o * CFrame.new(cfg.Ring.X, 0, cfg.Ring.Y)
	local r = cfg.RingRadius
	local segments = 28
	for i = 1, segments do
		local a = (i - 1) / segments * math.pi * 2
		local seg = part(model, `RingSeg{i}`, Vector3.new(0.6, 0.12, 2 * math.pi * r / segments + 0.1), center * CFrame.Angles(0, a, 0) * CFrame.new(r, 0.08, 0), RING, Enum.Material.Neon)
		flat(seg)
	end
	local glow = part(model, "RingGlow", Vector3.new(0.1, r * 2, r * 2), center * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), RING, Enum.Material.Neon)
	glow.Shape = Enum.PartType.Cylinder
	glow.Transparency = 0.85
	flat(glow)
	local light = Instance.new("PointLight")
	light.Color = RING
	light.Range = 12
	light.Brightness = 1.2
	light.Parent = glow
	floorText(model, "RingLabel", "VEHICLES", Vector2.new(9, 2.2), center * CFrame.new(0, 0.07, -r - 2.2) * CFrame.Angles(0, math.rad(180), 0), RING)
	-- Auslöser: flacher Zylinder, der den Spieler erkennt (Touched auf dem Server)
	local trigger = part(model, "GarageRing", Vector3.new(4, r * 2 - 1, r * 2 - 1), center * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)), RING, Enum.Material.SmoothPlastic)
	trigger.Shape = Enum.PartType.Cylinder
	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.CanQuery = false
	trigger.CanTouch = true
	trigger:SetAttribute("GarageRing", true)
end

-- Verladeturm (D-008): Stahlgerüst mit Trichter, Ausleger nach vorn und Querträger über
-- beiden Stellplätzen, Teleskop-Schurren, Bedienpult am Fuß.
local function tower(model: Model, o: CFrame)
	local cfg = LayoutConfig.Garage
	local t = o * CFrame.new(cfg.Tower.X, 0, cfg.Tower.Y)
	local H = 13
	part(model, "TowerFoundation", Vector3.new(7, 0.6, 7), t * CFrame.new(0, 0.3, 0), CONCRETE, Enum.Material.Concrete)
	for _, x in { -2.5, 2.5 } do
		for _, z in { -2.5, 2.5 } do
			part(model, `TowerLeg{x}_{z}`, Vector3.new(0.7, H, 0.7), t * CFrame.new(x, 0.6 + H / 2, z), STEEL)
		end
	end
	-- Diagonalverbände
	for i, y in { 3.5, 8 } do
		for _, z in { -2.5, 2.5 } do
			part(model, `TowerBrace{i}_{z}`, Vector3.new(0.3, 6.4, 0.3), t * CFrame.new(0, y, z) * CFrame.Angles(0, 0, math.rad(if i == 1 then 50 else -50)), STEEL_LIGHT)
		end
	end
	-- Trichter oben (Firmenfarbe als Akzent)
	local hopper = part(model, "TowerHopper", Vector3.new(6, 3, 6), t * CFrame.new(0, H + 2, 0), STEEL_LIGHT)
	local band = part(model, "TowerHopperBand", Vector3.new(6.2, 0.8, 6.2), t * CFrame.new(0, H + 3.1, 0), ACCENT_DEFAULT, Enum.Material.SmoothPlastic)
	accent(band)
	part(model, "TowerHopperFunnel", Vector3.new(3.6, 1.6, 3.6), t * CFrame.new(0, H - 0.2, 0), STEEL)
	hopper.CastShadow = true
	-- Zuführrohr von hinten (aus Richtung Lager)
	part(model, "TowerFeedPipe", Vector3.new(1.4, 1.4, 14), t * CFrame.new(0, H + 2, 9.5), STEEL_LIGHT)
	-- Ausleger nach vorn und Querträger über den Stellplätzen
	local armZ = cfg.Bays[1].Y + cfg.BaySize.Y / 2 - 3 -- über dem Heck der Fahrzeuge
	local armLen = cfg.Tower.Y - armZ
	local armY = 11
	part(model, "TowerArm", Vector3.new(1.4, 1.4, armLen), t * CFrame.new(0, armY, -armLen / 2), STEEL)
	local x1, x2 = cfg.Bays[1].X - cfg.Tower.X, cfg.Bays[2].X - cfg.Tower.X
	part(model, "TowerCrossbeam", Vector3.new(math.abs(x2 - x1) + 2, 1.2, 1.2), t * CFrame.new((x1 + x2) / 2, armY, -armLen), STEEL)
	local stripe = part(model, "TowerCrossbeamStripe", Vector3.new(math.abs(x2 - x1) + 2, 0.4, 0.1), t * CFrame.new((x1 + x2) / 2, armY, -armLen - 0.65), ACCENT_DEFAULT, Enum.Material.SmoothPlastic)
	accent(stripe)
	-- Schurren je Stellplatz
	for i, x in { x1, x2 } do
		part(model, `ChuteHead{i}`, Vector3.new(2.4, 1.6, 2.4), t * CFrame.new(x, armY - 1.4, -armLen), STEEL_LIGHT)
		part(model, `ChuteTube{i}`, Vector3.new(1.4, 2.6, 1.4), t * CFrame.new(x, armY - 3.5, -armLen), STEEL)
		part(model, `ChuteNozzle{i}`, Vector3.new(1.8, 0.8, 1.8), t * CFrame.new(x, armY - 5.2, -armLen), RUBBER, Enum.Material.Rubber)
		local lp = part(model, `LoadPoint{i}`, Vector3.new(1, 1, 1), t * CFrame.new(x, armY - 5.8, -armLen), WHITE, Enum.Material.SmoothPlastic)
		lp.Transparency = 1
		flat(lp)
		lp:SetAttribute("Bay", i)
		-- Warnleuchte an der Schurre
		local lamp = part(model, `ChuteLamp{i}`, Vector3.new(0.5, 0.5, 0.5), t * CFrame.new(x + 1.4, armY - 1.4, -armLen), YELLOW, Enum.Material.Neon)
		lamp.Shape = Enum.PartType.Ball
	end
	-- Bedienpult am Fuß des Turms (Prompt kommt mit dem Beladen in Phase 6c)
	part(model, "TowerPanelPost", Vector3.new(0.6, 3.2, 0.6), t * CFrame.new(-4.5, 2.2, -3), STEEL_DARK)
	local panel = part(model, "TowerPanel", Vector3.new(2.4, 1.8, 0.4), t * CFrame.new(-4.5, 4.4, -3) * CFrame.Angles(math.rad(-20), 0, 0), STEEL_LIGHT, Enum.Material.SmoothPlastic)
	local screen = part(model, "TowerPanelScreen", Vector3.new(2, 1.3, 0.1), t * CFrame.new(-4.5, 4.45, -3.25) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(90, 170, 255), Enum.Material.Neon)
	screen.Transparency = 0.15
	panel.CastShadow = true
	-- Schild "LOADING"
	local sign = part(model, "TowerSign", Vector3.new(7, 1.6, 0.2), t * CFrame.new((x1 + x2) / 2, armY + 1.7, -armLen - 0.4), STEEL_DARK, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = YELLOW
	label.Text = "LOADING"
	label.Parent = gui
end

-- Werkstatt-Details am rechten Rand der Garage
local function props(model: Model, o: CFrame)
	local cfg = LayoutConfig.Garage
	local p = o * CFrame.new(cfg.Ring.X + 14, 0, cfg.Ring.Y + 14)
	-- Werkzeugschrank
	part(model, "ToolCabinet", Vector3.new(6, 4.4, 2), p * CFrame.new(0, 2.2, 0), CABINET)
	for i = 1, 4 do
		part(model, `ToolDrawer{i}`, Vector3.new(5.6, 0.08, 0.1), p * CFrame.new(0, 0.8 + i * 0.85, -1.02), STEEL_DARK)
	end
	-- Reifenstapel
	for i = 1, 4 do
		local tire = part(model, `Tire{i}`, Vector3.new(1.2, 3.2, 3.2), o * CFrame.new(cfg.Ring.X + 14, 0.6 + (i - 1) * 1.2, cfg.Ring.Y - 6) * CFrame.Angles(0, 0, math.rad(90)), RUBBER, Enum.Material.Rubber)
		tire.Shape = Enum.PartType.Cylinder
	end
	-- Ölfass
	local barrel = part(model, "OilBarrel", Vector3.new(3.2, 2.2, 2.2), o * CFrame.new(cfg.Ring.X + 14, 1.6, cfg.Ring.Y + 6) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 90, 150))
	barrel.Shape = Enum.PartType.Cylinder
	-- Firmenfarbener Streifen auf dem Boden entlang der Garage (dezenter Akzent)
	local line = part(model, "GarageAccentLine", Vector3.new(0.6, 0.06, 40), o * CFrame.new(cfg.Ring.X - 9, 0.03, cfg.Ring.Y + 4), ACCENT_DEFAULT, Enum.Material.SmoothPlastic)
	flat(line)
	accent(line)
end

-- Glas-Rolltor in der Hallen-Toröffnung (docs/07 §3, §19). Geschlossen füllt es die Öffnung;
-- zum Öffnen rollt es sich nach oben in den Rollkasten (VehicleService tweened Größe/Lage).
local function door(model: Model, plotCFrame: CFrame)
	local doorW, doorH = LayoutConfig.DoorWidth, LayoutConfig.DoorHeight
	local z = LayoutConfig.HallOffset.Y - LayoutConfig.HallSize.Y / 2 - 0.9
	local base = plotCFrame * CFrame.new(LayoutConfig.DoorCenterX, LayoutConfig.HallFloorTop, z)
	local curtain = part(model, "GarageDoor", Vector3.new(doorW, doorH, 0.35), base * CFrame.new(0, doorH / 2, 0), Color3.fromRGB(170, 205, 225), Enum.Material.Glass)
	curtain.Transparency = 0.45
	curtain:SetAttribute("OpenHeight", 0.8)
	-- Lamellen als Linien (eine Fläche, damit das Rollen nur ein Teil bewegt)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 10
		gui.LightInfluence = 1
		gui.Parent = curtain
		local slats = math.floor(doorH / 2)
		for i = 1, slats do
			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0, 0.5)
			line.Position = UDim2.fromScale(0, i / slats)
			line.Size = UDim2.new(1, 0, 0, 3)
			line.BackgroundColor3 = Color3.fromRGB(90, 96, 104)
			line.BorderSizePixel = 0
			line.Parent = gui
		end
	end
	-- Sensor-Leuchte über dem Tor
	local sensor = part(model, "DoorSensor", Vector3.new(1.2, 0.6, 0.6), base * CFrame.new(doorW / 2 - 2, doorH + 3, -0.8), Color3.fromRGB(90, 200, 120), Enum.Material.Neon)
	sensor.CanCollide = false
end

function GarageTemplate.build(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Garage"
	local o = plotCFrame * CFrame.new(0, LayoutConfig.HallFloorTop, 0)
	for i = 1, #LayoutConfig.Garage.Bays do
		bay(model, i, o)
	end
	ring(model, o)
	tower(model, o)
	props(model, o)
	door(model, plotCFrame)
	return model
end

return table.freeze(GarageTemplate)
