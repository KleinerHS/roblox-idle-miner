--!strict
-- Garage im vorderen Hallenbereich (docs/07 §3–4, §18, D-008, D-016). PLATZHALTER-Optik nach
-- FACTORY_MASTERPLAN_TOPDOWN.png: zwei Stellplätze mit Bodenmarkierung und Nummer, leuchtender
-- Auswahlring, Verladeturm mit Auslegern über beiden Stellplätzen, Werkstatt-Details.
-- Akzente in der Firmenfarbe tragen das Attribut CompanyAccent (BuildingService färbt sie).
--
-- Vereinbarte Namen/Attribute:
--   Part "BaySpawn1"/"BaySpawn2"   – Fahrzeug-Spawn (Bodenmitte, LookVector zum Rolltor)
--   Part "GarageRing"              – Auslöser der Fahrzeugauswahl (Attribut GarageRing = true)
--   Part "LoadPoint1"/"LoadPoint2" – Bezugspunkt der Ladeschurre über dem Stellplatz (Attribut Bay)
--   Part "ChuteTube{n}"/"ChuteNozzle{n}", "ChuteLamp{n}", "BayDisplay{n}" – automatisches Beladen
--   Part "GarageDoor"              – Glas-Rolltor in der Hallen-Toröffnung (VehicleService)

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

-- Verladeturm (D-008, D-025): hohes Stahlgitter-Gerüst mit Silo, Zuführrohr aus dem Lager,
-- Ausleger über beiden Stellplätzen mit ausfahrbaren Teleskop-Schurren, Statuslampe und
-- Anzeige je Stellplatz. Beladen läuft automatisch (LoadingService), ohne Bedienung.
local TOWER_HEIGHT = 22
local BOOM_Y = 18
-- Unterkante der Schurrenhülse; das Teleskoprohr fährt von hier nach unten aus
local CHUTE_TOP = 16.4
local CHUTE_REST = 1.6

local function tower(model: Model, o: CFrame)
	local cfg = LayoutConfig.Garage
	local t = o * CFrame.new(cfg.Tower.X, 0, cfg.Tower.Y)
	local H = TOWER_HEIGHT
	part(model, "TowerFoundation", Vector3.new(11, 0.8, 11), t * CFrame.new(0, 0.4, 0), CONCRETE, Enum.Material.Concrete)
	for i = 1, 12 do
		local edge = part(model, `TowerFoundationEdge{i}`, Vector3.new(11 / 12, 0.82, 0.3), t * CFrame.new(-5.5 + 11 / 12 * (i - 0.5), 0.41, -5.45), if i % 2 == 0 then BLACK else YELLOW, Enum.Material.SmoothPlastic)
		edge.CanCollide = false
	end
	-- Vier Eckstiele (I-Profil-Optik) mit Fußplatten
	for _, x in { -4, 4 } do
		for _, z in { -4, 4 } do
			part(model, `TowerLeg{x}_{z}`, Vector3.new(1, H, 1), t * CFrame.new(x, 0.8 + H / 2, z), STEEL)
			part(model, `TowerFoot{x}_{z}`, Vector3.new(1.8, 0.3, 1.8), t * CFrame.new(x, 0.95, z), STEEL_DARK)
		end
	end
	-- Riegel auf allen vier Seiten und Kreuzverbände auf zwei Seiten
	for level = 1, 4 do
		local y = 0.8 + level * (H / 4)
		part(model, `TowerGirderF{level}`, Vector3.new(9, 0.6, 0.6), t * CFrame.new(0, y, -4), STEEL)
		part(model, `TowerGirderB{level}`, Vector3.new(9, 0.6, 0.6), t * CFrame.new(0, y, 4), STEEL)
		part(model, `TowerGirderL{level}`, Vector3.new(0.6, 0.6, 9), t * CFrame.new(-4, y, 0), STEEL)
		part(model, `TowerGirderR{level}`, Vector3.new(0.6, 0.6, 9), t * CFrame.new(4, y, 0), STEEL)
		local mid = y - H / 8
		local diagonal = math.sqrt(8 ^ 2 + (H / 4) ^ 2)
		local angle = math.atan2(H / 4, 8)
		for _, side in { -4, 4 } do
			part(model, `TowerBraceA{level}_{side}`, Vector3.new(0.3, 0.3, diagonal), t * CFrame.new(side, mid, 0) * CFrame.Angles(angle, 0, 0), STEEL_LIGHT)
			part(model, `TowerBraceB{level}_{side}`, Vector3.new(0.3, 0.3, diagonal), t * CFrame.new(side, mid, 0) * CFrame.Angles(-angle, 0, 0), STEEL_LIGHT)
		end
	end
	-- Wartungsleiter
	part(model, "TowerLadder", Vector3.new(1.6, H, 0.2), t * CFrame.new(0, 0.8 + H / 2, 4.6), STEEL_LIGHT, Enum.Material.DiamondPlate)
	part(model, "TowerPlatform", Vector3.new(10, 0.4, 10), t * CFrame.new(0, 0.8 + H, 0), STEEL_LIGHT, Enum.Material.DiamondPlate)
	part(model, "TowerRail", Vector3.new(10, 0.2, 0.2), t * CFrame.new(0, 0.8 + H + 1.2, -5), YELLOW, Enum.Material.SmoothPlastic)

	-- Silo oben mit Firmenfarbband und Trichter nach unten
	local siloBase = 0.8 + H + 0.2
	local silo = part(model, "TowerSilo", Vector3.new(7, 8, 8), t * CFrame.new(0, siloBase + 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL_LIGHT)
	silo.Shape = Enum.PartType.Cylinder
	local band = part(model, "TowerHopperBand", Vector3.new(1.2, 8.2, 8.2), t * CFrame.new(0, siloBase + 5, 0) * CFrame.Angles(0, 0, math.rad(90)), ACCENT_DEFAULT, Enum.Material.SmoothPlastic)
	band.Shape = Enum.PartType.Cylinder
	accent(band)
	local cap = part(model, "TowerSiloCap", Vector3.new(0.6, 8.4, 8.4), t * CFrame.new(0, siloBase + 7.2, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL_DARK)
	cap.Shape = Enum.PartType.Cylinder
	for i, d in { 6, 4.4, 2.8 } do
		local cone = part(model, `TowerFunnel{i}`, Vector3.new(1, d, d), t * CFrame.new(0, H - (i - 1) * 1 + 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL)
		cone.Shape = Enum.PartType.Cylinder
	end
	-- Zuführrohr vom Lager (hinten, +Z) über das Silo: Material kommt direkt aus dem Lager
	local pipeLen = 30
	local pipe = part(model, "TowerFeedPipe", Vector3.new(pipeLen, 1.6, 1.6), t * CFrame.new(0, siloBase + 5.6, 4 + pipeLen / 2) * CFrame.Angles(0, math.rad(90), 0), STEEL_LIGHT)
	pipe.Shape = Enum.PartType.Cylinder
	for i = 1, 5 do
		part(model, `TowerFeedClamp{i}`, Vector3.new(2, 0.4, 0.4), t * CFrame.new(0, siloBase + 5.6, 4 + i * pipeLen / 6), STEEL_DARK)
	end
	local drop = part(model, "TowerFeedDrop", Vector3.new(siloBase + 5.6, 1.6, 1.6), t * CFrame.new(0, (siloBase + 5.6) / 2, 4 + pipeLen) * CFrame.Angles(0, 0, math.rad(90)), STEEL_LIGHT)
	drop.Shape = Enum.PartType.Cylinder
	local intake = part(model, "TowerIntake", Vector3.new(3, 3, 3), t * CFrame.new(0, 1.5, 4 + pipeLen), STEEL)
	intake.CastShadow = true
	local intakeSign = part(model, "TowerIntakeSign", Vector3.new(2.6, 0.9, 0.1), t * CFrame.new(0, 2, 4 + pipeLen + 1.55), STEEL_DARK, Enum.Material.SmoothPlastic)
	local intakeGui = Instance.new("SurfaceGui")
	intakeGui.Face = Enum.NormalId.Back
	intakeGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	intakeGui.PixelsPerStud = 40
	intakeGui.LightInfluence = 0
	intakeGui.Parent = intakeSign
	local intakeLabel = Instance.new("TextLabel")
	intakeLabel.Size = UDim2.fromScale(1, 1)
	intakeLabel.BackgroundTransparency = 1
	intakeLabel.Font = Enum.Font.GothamBlack
	intakeLabel.TextScaled = true
	intakeLabel.TextColor3 = YELLOW
	intakeLabel.Text = "FROM STORAGE"
	intakeLabel.Parent = intakeGui

	-- Ausleger nach vorn und Querträger über den Stellplätzen
	local armZ = cfg.Bays[1].Y + cfg.BaySize.Y / 2 - 3 -- über dem Heck der Fahrzeuge
	local armLen = cfg.Tower.Y - armZ
	part(model, "TowerArm", Vector3.new(1.8, 1.8, armLen + 4), t * CFrame.new(0, BOOM_Y, -(armLen + 4) / 2 + 4), STEEL)
	part(model, "TowerArmTie", Vector3.new(0.3, 0.3, armLen), t * CFrame.new(0, BOOM_Y + 3, -armLen / 2), STEEL_LIGHT)
	local x1, x2 = cfg.Bays[1].X - cfg.Tower.X, cfg.Bays[2].X - cfg.Tower.X
	local span = math.abs(x2 - x1) + cfg.BaySize.X + 2 -- Stützen außerhalb der Stellplätze
	part(model, "TowerCrossbeam", Vector3.new(span, 1.6, 1.6), t * CFrame.new((x1 + x2) / 2, BOOM_Y, -armLen), STEEL)
	local stripe = part(model, "TowerCrossbeamStripe", Vector3.new(span, 0.5, 0.1), t * CFrame.new((x1 + x2) / 2, BOOM_Y, -armLen - 0.85), ACCENT_DEFAULT, Enum.Material.SmoothPlastic)
	accent(stripe)
	-- Stützen am Ende des Querträgers
	for i, x in { (x1 + x2) / 2 - span / 2 + 0.6, (x1 + x2) / 2 + span / 2 - 0.6 } do
		part(model, `TowerCrossbeamPost{i}`, Vector3.new(0.9, BOOM_Y, 0.9), t * CFrame.new(x, BOOM_Y / 2 + 0.4, -armLen), STEEL)
		part(model, `TowerCrossbeamPostStripe{i}`, Vector3.new(0.95, 2, 0.95), t * CFrame.new(x, 1.4, -armLen), YELLOW, Enum.Material.SmoothPlastic)
	end
	-- Schild "LOADING" über dem Querträger
	local sign = part(model, "TowerSign", Vector3.new(10, 2, 0.2), t * CFrame.new((x1 + x2) / 2, BOOM_Y + 2, -armLen - 0.5), STEEL_DARK, Enum.Material.SmoothPlastic)
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

	-- Je Stellplatz: Laufkatze, Schurrenhülse, Teleskoprohr, Düse, Lampe, Anzeige vorne
	for i, x in { x1, x2 } do
		part(model, `ChuteTrolley{i}`, Vector3.new(3.4, 1.6, 2.6), t * CFrame.new(x, BOOM_Y - 1.6, -armLen), STEEL_LIGHT)
		part(model, `ChuteSleeve{i}`, Vector3.new(2, 1.2, 2), t * CFrame.new(x, CHUTE_TOP + 0.6, -armLen), STEEL)
		local tube = part(model, `ChuteTube{i}`, Vector3.new(1.4, CHUTE_REST, 1.4), t * CFrame.new(x, CHUTE_TOP - CHUTE_REST / 2, -armLen), STEEL_LIGHT)
		tube:SetAttribute("ChuteTop", (t * CFrame.new(x, CHUTE_TOP, -armLen)).Position.Y)
		tube.CanCollide = false
		local nozzle = part(model, `ChuteNozzle{i}`, Vector3.new(2, 0.8, 2), t * CFrame.new(x, CHUTE_TOP - CHUTE_REST - 0.4, -armLen), RUBBER, Enum.Material.Rubber)
		nozzle.CanCollide = false
		local lp = part(model, `LoadPoint{i}`, Vector3.new(1, 1, 1), t * CFrame.new(x, CHUTE_TOP - 6, -armLen), WHITE, Enum.Material.SmoothPlastic)
		lp.Transparency = 1
		flat(lp)
		lp:SetAttribute("Bay", i)
		local lamp = part(model, `ChuteLamp{i}`, Vector3.new(0.8, 0.8, 0.8), t * CFrame.new(x + 2, BOOM_Y - 1.6, -armLen - 1), STEEL_LIGHT, Enum.Material.Neon)
		lamp.Shape = Enum.PartType.Ball
		local lampLight = Instance.new("PointLight")
		lampLight.Name = "Glow"
		lampLight.Range = 8
		lampLight.Enabled = false
		lampLight.Parent = lamp
		-- Anzeige vorne am Stellplatz, zum Fahrer gedreht (schaut zur Hallenrückseite)
		local bayCenter = cfg.Bays[i]
		local displayCF = o * CFrame.new(bayCenter.X, 14.5, bayCenter.Y - cfg.BaySize.Y / 2 - 1) * CFrame.Angles(0, math.rad(180), 0)
		part(model, `BayDisplayPost{i}`, Vector3.new(0.5, 16, 0.5), o * CFrame.new(bayCenter.X + cfg.BaySize.X / 2 + 0.6, 8, bayCenter.Y - cfg.BaySize.Y / 2 - 1), STEEL_DARK)
		part(model, `BayDisplayArm{i}`, Vector3.new(cfg.BaySize.X / 2 + 0.6, 0.4, 0.4), o * CFrame.new(bayCenter.X + cfg.BaySize.X / 4 + 0.3, 15.9, bayCenter.Y - cfg.BaySize.Y / 2 - 1), STEEL_DARK)
		local display = part(model, `BayDisplay{i}`, Vector3.new(6, 2.4, 0.3), displayCF, Color3.fromRGB(24, 27, 33), Enum.Material.SmoothPlastic)
		display.CanCollide = false
		local dgui = Instance.new("SurfaceGui")
		dgui.Name = "Display"
		dgui.Face = Enum.NormalId.Front
		dgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		dgui.PixelsPerStud = 50
		dgui.LightInfluence = 0
		dgui.Parent = display
		for j, name in { "Title", "Value" } do
			local l = Instance.new("TextLabel")
			l.Name = name
			l.Position = UDim2.fromScale(0.04, if j == 1 then 0.06 else 0.48)
			l.Size = UDim2.fromScale(0.92, if j == 1 then 0.38 else 0.46)
			l.BackgroundTransparency = 1
			l.Font = Enum.Font.GothamBlack
			l.TextScaled = true
			l.TextColor3 = if j == 1 then Color3.fromRGB(165, 172, 184) else Color3.fromRGB(240, 242, 245)
			l.Text = if j == 1 then `BAY {i}` else "READY"
			l.Parent = dgui
		end
	end
end

-- Zustand eines Stellplatzes am Turm (LoadingService): Lampe, Anzeige, Schurrenlänge
local BAY_COLORS: { [string]: Color3 } = {
	Idle = Color3.fromRGB(150, 154, 160),
	Loading = Color3.fromRGB(70, 210, 90),
	Full = Color3.fromRGB(80, 160, 255),
	NoStock = Color3.fromRGB(255, 160, 30),
}

function GarageTemplate.setBayState(model: Model, bay: number, state: string, title: string, value: string)
	local color = BAY_COLORS[state] or BAY_COLORS.Idle
	local lamp = model:FindFirstChild(`ChuteLamp{bay}`)
	if lamp and lamp:IsA("BasePart") then
		lamp.Color = color
		local glow = lamp:FindFirstChild("Glow")
		if glow and glow:IsA("PointLight") then
			glow.Color = color
			glow.Enabled = state ~= "Idle"
		end
	end
	local display = model:FindFirstChild(`BayDisplay{bay}`)
	local gui = display and display:FindFirstChild("Display")
	if gui then
		local t = gui:FindFirstChild("Title")
		local v = gui:FindFirstChild("Value")
		if t and t:IsA("TextLabel") then
			t.Text = title
		end
		if v and v:IsA("TextLabel") then
			v.Text = value
			v.TextColor3 = if state == "Idle" then Color3.fromRGB(240, 242, 245) else color
		end
	end
end

-- Zielgrößen der Schurre: Länge des Teleskoprohrs bis zur Höhe bottomY (Weltkoordinate).
-- nil = eingefahren. Gibt { [Part] = { Size, CFrame } } für einen Tween zurück.
function GarageTemplate.chuteGoals(model: Model, bay: number, bottomY: number?): { [BasePart]: { [string]: any } }
	local goals = {}
	local tube = model:FindFirstChild(`ChuteTube{bay}`)
	local nozzle = model:FindFirstChild(`ChuteNozzle{bay}`)
	if not (tube and tube:IsA("BasePart") and nozzle and nozzle:IsA("BasePart")) then
		return goals
	end
	local top = tube:GetAttribute("ChuteTop")
	if typeof(top) ~= "number" then
		return goals
	end
	local length = if bottomY then math.clamp(top - bottomY - 0.8, CHUTE_REST, 14) else CHUTE_REST
	local x, z = tube.Position.X, tube.Position.Z
	local rot = tube.CFrame - tube.Position
	goals[tube] = { Size = Vector3.new(tube.Size.X, length, tube.Size.Z), CFrame = CFrame.new(x, top - length / 2, z) * rot }
	goals[nozzle] = { CFrame = CFrame.new(x, top - length - 0.4, z) * rot }
	return goals
end

-- Deko-Ecke rechts neben dem Auswahlring (Felix 2026-10-10: keine Werkstatt, nur Deko, damit die
-- Halle nicht leer wirkt): Hochregale mit Paletten und Kartons, Ölfässer, Palettenstapel.
-- Lokal zur Plotmitte, Bereich x 76..104, z −54..−6 (frei von Ring, Stellplätzen, Turm, Stützen).
local PALLET_WOOD = Color3.fromRGB(176, 140, 96)
local CARTON = { Color3.fromRGB(184, 146, 98), Color3.fromRGB(168, 130, 84), Color3.fromRGB(196, 160, 112) }
local RACK_UPRIGHT = Color3.fromRGB(40, 90, 150)
local RACK_BEAM = Color3.fromRGB(222, 120, 40)

-- Europalette (Unterkante = cf), 4 × 0.5 × 3.4
local function pallet(parent: Instance, name: string, cf: CFrame)
	part(parent, `{name}Deck`, Vector3.new(4, 0.15, 3.4), cf * CFrame.new(0, 0.425, 0), PALLET_WOOD, Enum.Material.WoodPlanks)
	for _, dz in { -1.4, 0, 1.4 } do
		part(parent, `{name}Runner{dz}`, Vector3.new(4, 0.35, 0.5), cf * CFrame.new(0, 0.175, dz), PALLET_WOOD:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.WoodPlanks)
	end
end

-- Palette mit 2 × 2 Kartonstapeln (zufällige Höhe bis maxLayers)
local function cartonPallet(parent: Instance, name: string, cf: CFrame, rng: Random, maxLayers: number)
	pallet(parent, name, cf)
	for ix, dx in { -0.95, 0.95 } do
		for iz, dz in { -0.8, 0.8 } do
			local layers = rng:NextInteger(1, maxLayers)
			for layer = 1, layers do
				local box = cf * CFrame.new(dx, 0.5 + (layer - 0.5) * 1.25, dz)
				part(parent, `{name}Carton{ix}{iz}_{layer}`, Vector3.new(1.8, 1.25, 1.5), box, CARTON[rng:NextInteger(1, #CARTON)], Enum.Material.Cardboard)
				if layer == layers then
					local tape = part(parent, `{name}Tape{ix}{iz}`, Vector3.new(1.82, 0.03, 0.3), box * CFrame.new(0, 0.635, 0), Color3.fromRGB(150, 110, 60), Enum.Material.SmoothPlastic)
					tape.CanCollide = false
				end
			end
		end
	end
end

-- Hochregal: Länge entlang lokal X, Front zu lokal +Z, Unterkante = cf. bays Fächer à 6 Studs,
-- drei Ebenen (Boden, 4.6, 9.2) mit Kartonpaletten; Stapelhöhe bleibt unter dem nächsten Träger.
local function highRack(parent: Instance, name: string, cf: CFrame, bays: number, rng: Random)
	local length = bays * 6
	for i = 0, bays do
		local x = -length / 2 + i * 6
		for _, dz in { -1.4, 1.4 } do
			part(parent, `{name}Upright{i}_{dz}`, Vector3.new(0.35, 13.5, 0.35), cf * CFrame.new(x, 6.75, dz), RACK_UPRIGHT)
		end
		for _, y in { 2.3, 6.9, 11.5 } do
			part(parent, `{name}Brace{i}_{y}`, Vector3.new(0.15, 0.15, 2.45), cf * CFrame.new(x, y, 0), RACK_UPRIGHT)
		end
	end
	for level, y in { 4.6, 9.2 } do
		for _, dz in { -1.4, 1.4 } do
			part(parent, `{name}Beam{level}_{dz}`, Vector3.new(length, 0.4, 0.25), cf * CFrame.new(0, y, dz), RACK_BEAM)
		end
	end
	for b = 1, bays do
		local x = -length / 2 + (b - 0.5) * 6
		for level, y in { 0, 4.8, 9.4 } do
			if level == 1 or rng:NextNumber() < 0.85 then
				cartonPallet(parent, `{name}Pallet{b}_{level}`, cf * CFrame.new(x, y, 0), rng, if level == 1 then 3 else 2)
			end
		end
	end
end

local function drum(parent: Instance, name: string, cf: CFrame, color: Color3)
	local d = part(parent, name, Vector3.new(2.6, 1.6, 1.6), cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), color)
	d.Shape = Enum.PartType.Cylinder
	local lid = part(parent, `{name}Lid`, Vector3.new(0.06, 1.3, 1.3), cf * CFrame.new(0, 2.62, 0) * CFrame.Angles(0, 0, math.rad(90)), color:Lerp(Color3.new(0, 0, 0), 0.25))
	lid.Shape = Enum.PartType.Cylinder
end

local function props(model: Model, o: CFrame)
	local cfg = LayoutConfig.Garage
	local deco = Instance.new("Folder")
	deco.Name = "Decoration"
	deco.Parent = model
	local rng = Random.new(17)
	local BLUE = Color3.fromRGB(40, 90, 150)
	local RED = Color3.fromRGB(190, 50, 40)
	local GREEN = Color3.fromRGB(60, 110, 60)

	-- Hochregale an Vorder- und Seitenwand
	highRack(deco, "RackFront", o * CFrame.new(90, 0, -52.2), 4, rng)
	highRack(deco, "RackSide", o * CFrame.new(102.4, 0, -42) * CFrame.Angles(0, math.rad(90), 0), 2, rng)

	-- Ölfässer auf Auffangwanne und eine Palette mit Fässern
	local spill = o * CFrame.new(99, 0, -9)
	part(deco, "SpillPallet", Vector3.new(4.4, 0.4, 4.4), spill * CFrame.new(0, 0.2, 0), YELLOW, Enum.Material.SmoothPlastic)
	for i, p in { Vector2.new(-0.95, -0.95), Vector2.new(0.95, -0.95), Vector2.new(0, 1) } do
		drum(deco, `SpillDrum{i}`, spill * CFrame.new(p.X, 0.4, p.Y), if i == 3 then RED else BLUE)
	end
	local drumPallet = o * CFrame.new(99.5, 0, -26)
	pallet(deco, "DrumPallet", drumPallet)
	for i, p in { Vector2.new(-0.95, -0.8), Vector2.new(0.95, -0.8), Vector2.new(-0.95, 0.8), Vector2.new(0.95, 0.8) } do
		drum(deco, `PalletDrum{i}`, drumPallet * CFrame.new(p.X, 0.5, p.Y), if i == 2 then GREEN else BLUE)
	end
	drum(deco, "LooseDrum1", o * CFrame.new(95.5, 0, -24.5), RED)
	drum(deco, "LooseDrum2", o * CFrame.new(96, 0, -27.6), BLUE)

	-- Kartonpaletten und ein Stapel leerer Paletten auf dem Boden
	cartonPallet(deco, "FloorPallet1", o * CFrame.new(86, 0, -40) * CFrame.Angles(0, math.rad(8), 0), rng, 3)
	cartonPallet(deco, "FloorPallet2", o * CFrame.new(91, 0, -40.5) * CFrame.Angles(0, math.rad(-4), 0), rng, 2)
	cartonPallet(deco, "FloorPallet3", o * CFrame.new(84, 0, -18) * CFrame.Angles(0, math.rad(90), 0), rng, 3)
	for i = 1, 6 do
		pallet(deco, `EmptyPallet{i}`, o * CFrame.new(80, (i - 1) * 0.5, -46) * CFrame.Angles(0, math.rad(if i % 2 == 0 then 3 else -2), 0))
	end

	-- Feuerlöscher an der Hallenstütze
	local ext = o * CFrame.new(102.7, 3, -35)
	local extBody = part(deco, "Extinguisher", Vector3.new(1.2, 0.5, 0.5), ext * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)
	extBody.Shape = Enum.PartType.Cylinder
	part(deco, "ExtinguisherBracket", Vector3.new(0.5, 0.2, 0.4), ext * CFrame.new(0.25, 0.3, 0), STEEL_DARK)

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
