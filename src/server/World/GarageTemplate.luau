--!strict
-- Garage im vorderen Hallenbereich (docs/07 §3–4, §18, D-008, D-016) mit Durchfahr-Verladestraße
-- (Phase 18b, D-052): Einfahrt durch die linke Hallenwand, geradeaus unter dem einen Verladerüssel
-- durch, Rechtskurve, Ausfahrt durch das Rolltor. Zwei Stellplätze zum Ausparken vor dem Rüssel,
-- leuchtender Auswahlring, Verladeturm hinter der Spur mit Portal über die Spur, Werkstatt-Details.
-- Akzente in der Firmenfarbe tragen das Attribut CompanyAccent (BuildingService färbt sie).
--
-- Vereinbarte Namen/Attribute:
--   Part "BaySpawn1"/"BaySpawn2"   – Fahrzeug-Spawn (Bodenmitte, LookVector zum Rolltor)
--   Part "GarageRing"              – Auslöser der Fahrzeugauswahl (Attribut GarageRing = true)
--   Part "LoadPoint1"              – Bezugspunkt des Verladerüssels über der Spur (Attribut Bay)
--   Part "ChuteTube{n}" (+ "ChuteTube{n}Mid"/"Inner", Teleskop), "ChuteNozzle{n}", "ChuteLamp{n}",
--   "BayDisplay{n}" – automatisches Beladen
--   Part "GarageDoor"              – Glas-Rolltor in der Hallen-Toröffnung (VehicleService)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LayoutConfig)
local FloatingText = require(script.Parent.FloatingText)
local AmbientProps = require(script.Parent.AmbientProps)

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
local function bay(garage: Model, index: number, o: CFrame)
	-- jeder Stellplatz ist ein eigenes Model (Markierung, Nummer, Radstopper, Spawnpunkt)
	local model = Instance.new("Model")
	model.Name = `Bay{index}`
	model.Parent = garage
	local cfg = LayoutConfig.Garage
	local c = cfg.Bays[index]
	local w, l = cfg.BaySize.X, cfg.BaySize.Y
	local base = o * CFrame.new(c.X, 0, c.Y) * CFrame.Angles(0, math.rad(cfg.BayYaw), 0)
	for _, side in { -1, 1 } do
		local line = part(model, `Bay{index}Side{side}`, Vector3.new(0.5, 0.06, l), base * CFrame.new(side * w / 2, 0.03, 0), YELLOW, Enum.Material.SmoothPlastic)
		flat(line)
	end
	local backLine = part(model, `Bay{index}Back`, Vector3.new(w + 0.5, 0.06, 0.5), base * CFrame.new(0, 0.03, l / 2), YELLOW, Enum.Material.SmoothPlastic)
	flat(backLine)
	-- Gestreifte Ausfahrtskante vorne (in Fahrtrichtung)
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
local function ring(garage: Model, o: CFrame)
	local model = Instance.new("Model")
	model.Name = "VehicleRing"
	model.Parent = garage
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

-- Verladestation (D-008, D-025; Felix 2026-10-13: „aufgebaut wie im echten Leben“, Rüssel über
-- der Ladefläche, Farben wie der Rest der Halle; 2026-10-19: nur noch ein Rüssel über einer
-- Durchfahrspur, D-052). Aufbau wie eine LKW-Verladestation:
--   * Stahlturm hinter der Spur (gelbe I-Profile, Kreuzverbände, Laufrost mit Geländer,
--     Steigleiter mit Rückenschutz) mit Vorratssilo, Trichter und Schieber
--   * Zuführrohr aus dem Lager oben ins Silo, an der Hallendecke abgehängt
--   * Portal vom Turm über die Spur mit Laufsteg; darunter ein Zwischenbunker, gespeist über eine
--     Förderschnecke aus dem Silo, Schieber und Faltenbalg-Verladerüssel (fährt bis auf die
--     Ladefläche aus), Statuslampe und Strahler
--   * Steuerkabine am Fuß des Turms
-- Beladen läuft automatisch (LoadingService), ohne Bedienung. Vereinbarte Namen:
-- LoadPoint1, ChuteTube1 (Attribut ChuteTop), ChuteNozzle1, ChuteLamp1, BayDisplay1.
local BEAM_Y = 24 -- Mitte der oberen Träger (Turm und Portal); hoch genug für Lastzüge
local DECK_Y = BEAM_Y + 1 -- Oberkante Laufrost
-- Unterkante des Rüssel-Faltenbalgs; das Teleskoprohr fährt von hier nach unten aus
local CHUTE_TOP = BEAM_Y - 6.1
local CHUTE_REST = 1.4
local ORANGE = Color3.fromRGB(226, 140, 40)
local GREY_BOX = Color3.fromRGB(120, 124, 130)
local SILO = Color3.fromRGB(200, 204, 210)

-- Träger zwischen zwei Weltpunkten
local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, w: number, h: number, color: Color3, material: Enum.Material?): Part
	return part(parent, name, Vector3.new(w, h, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color, material)
end

-- Rohr zwischen zwei Weltpunkten
local function tube(parent: Instance, name: string, a: Vector3, b: Vector3, d: number, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new((b - a).Magnitude, d, d), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- liegende Scheibe/stehender Zylinder (Achse senkrecht)
local function disc(parent: Instance, name: string, cf: CFrame, height: number, d: number, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(height, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Stütze als I-Profil (Steg + zwei Gurte), Fußplatte, gelb-schwarzer Anfahrschutz unten
local function column(parent: Instance, name: string, base: CFrame, height: number)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	part(m, "Web", Vector3.new(0.3, height, 0.9), base * CFrame.new(0, height / 2, 0), YELLOW)
	for _, s in { -1, 1 } do
		part(m, `Flange{s}`, Vector3.new(1.1, height, 0.22), base * CFrame.new(0, height / 2, s * 0.56), YELLOW)
	end
	part(m, "BasePlate", Vector3.new(1.8, 0.25, 1.8), base * CFrame.new(0, 0.125, 0), STEEL_DARK)
	for i = 1, 4 do
		local stripe = part(m, `Guard{i}`, Vector3.new(1.25, 0.5, 1.45), base * CFrame.new(0, 0.25 + i * 0.5, 0), if i % 2 == 0 then BLACK else YELLOW, Enum.Material.SmoothPlastic)
		stripe.CanCollide = false
	end
end

-- Geländer (Pfosten, Handlauf, Knieleiste, Fußleiste) zwischen zwei Weltpunkten auf Laufhöhe
local function railing(parent: Instance, name: string, a: Vector3, b: Vector3)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local dir = b - a
	local n = math.max(1, math.floor(dir.Magnitude / 3))
	for i = 0, n do
		local p = a + dir * (i / n)
		part(m, `Post{i}`, Vector3.new(0.22, 3.4, 0.22), CFrame.new(p + Vector3.new(0, 1.7, 0)), YELLOW)
	end
	beam(m, "HandRail", a + Vector3.new(0, 3.35, 0), b + Vector3.new(0, 3.35, 0), 0.22, 0.22, YELLOW)
	beam(m, "KneeRail", a + Vector3.new(0, 1.7, 0), b + Vector3.new(0, 1.7, 0), 0.16, 0.16, YELLOW)
	beam(m, "ToeBoard", a + Vector3.new(0, 0.25, 0), b + Vector3.new(0, 0.25, 0), 0.08, 0.5, YELLOW)
end

local function tower(model: Model, o: CFrame)
	local cfg = LayoutConfig.Garage
	-- Turm-Koordinaten: -Z zeigt vom Turm zur Spur
	local t = o * CFrame.new(cfg.Tower.X, 0, cfg.Tower.Y)
	local function at(x: number, y: number, z: number): CFrame
		return t * CFrame.new(x, y, z)
	end
	local function pos(x: number, y: number, z: number): Vector3
		return (t * CFrame.new(x, y, z)).Position
	end
	-- Rüssel über der Spurmitte, Portal-Stützen jenseits der Spur
	local spoutX = cfg.Chute.X - cfg.Tower.X
	local spoutZ = cfg.Chute.Y - cfg.Tower.Y
	local farZ = cfg.Lane.Z - cfg.Lane.Width / 2 - 3 - cfg.Tower.Y

	-- Fundament mit Warnkante
	local found = Instance.new("Model")
	found.Name = "TowerFoundation"
	found.Parent = model
	part(found, "Slab", Vector3.new(13, 0.6, 13), at(0, 0.3, 0), CONCRETE, Enum.Material.Concrete)
	for i = 1, 13 do
		local edge = part(found, `Edge{i}`, Vector3.new(1, 0.62, 0.3), at(-6.5 + i - 0.5, 0.31, -6.45), if i % 2 == 0 then BLACK else YELLOW, Enum.Material.SmoothPlastic)
		edge.CanCollide = false
	end

	-- Turmgerüst: 4 I-Stützen, Riegel auf 3 Ebenen, Kreuzverbände an drei Seiten
	local frame = Instance.new("Model")
	frame.Name = "TowerFrame"
	frame.Parent = model
	local L = 5
	for _, x in { -L, L } do
		for _, z in { -L, L } do
			column(frame, `Column{x}_{z}`, at(x, 0.6, z), BEAM_Y - 0.2)
		end
	end
	for i, y in { 7.5, 13, BEAM_Y } do
		local h = if y == BEAM_Y then 1.6 else 0.7
		beam(frame, `GirderFront{i}`, pos(-L, y, -L), pos(L, y, -L), 0.7, h, YELLOW)
		beam(frame, `GirderBack{i}`, pos(-L, y, L), pos(L, y, L), 0.7, h, YELLOW)
		beam(frame, `GirderLeft{i}`, pos(L, y, -L), pos(L, y, L), 0.7, h, YELLOW)
		beam(frame, `GirderRight{i}`, pos(-L, y, -L), pos(-L, y, L), 0.7, h, YELLOW)
	end
	local levels = { 1.2, 7.5, 13, BEAM_Y - 0.8 }
	for i = 1, #levels - 1 do
		local y0, y1 = levels[i], levels[i + 1]
		for _, x in { -L, L } do
			beam(frame, `BraceSideA{x}_{i}`, pos(x, y0, -L), pos(x, y1, L), 0.3, 0.3, STEEL_DARK)
			beam(frame, `BraceSideB{x}_{i}`, pos(x, y0, L), pos(x, y1, -L), 0.3, 0.3, STEEL_DARK)
		end
		beam(frame, `BraceBackA{i}`, pos(-L, y0, L), pos(L, y1, L), 0.3, 0.3, STEEL_DARK)
		beam(frame, `BraceBackB{i}`, pos(L, y0, L), pos(-L, y1, L), 0.3, 0.3, STEEL_DARK)
	end
	-- Laufrost oben mit Geländer (vorne offen zum Portal-Laufsteg)
	part(frame, "TowerPlatform", Vector3.new(12.4, 0.2, 12.4), at(0, DECK_Y - 0.1, 0), STEEL_LIGHT, Enum.Material.DiamondPlate)
	railing(frame, "RailBack", pos(-6.1, DECK_Y, 6.1), pos(6.1, DECK_Y, 6.1))
	railing(frame, "RailLeft", pos(6.1, DECK_Y, -6.1), pos(6.1, DECK_Y, 6.1))
	railing(frame, "RailRight", pos(-6.1, DECK_Y, -6.1), pos(-6.1, DECK_Y, 6.1))
	railing(frame, "RailFrontL", pos(6.1, DECK_Y, -6.1), pos(1.95, DECK_Y, -6.1))
	railing(frame, "RailFrontR", pos(-6.1, DECK_Y, -6.1), pos(-1.95, DECK_Y, -6.1))

	-- Steigleiter mit Rückenschutz an der Rückseite
	local ladder = Instance.new("Model")
	ladder.Name = "TowerLadder"
	ladder.Parent = model
	local lz = L + 0.9
	for _, s in { -1, 1 } do
		part(ladder, `Stile{s}`, Vector3.new(0.16, DECK_Y - 0.2, 0.16), at(s * 0.7, 0.6 + (DECK_Y - 0.2) / 2, lz), YELLOW)
	end
	for i = 1, math.floor(DECK_Y - 1) do
		part(ladder, `Rung{i}`, Vector3.new(1.4, 0.1, 0.1), at(0, 0.6 + i, lz), STEEL_LIGHT).CanCollide = false
	end
	for i = 0, math.floor((DECK_Y - 8) / 2.5) do
		local y = 8 + i * 2.5
		part(ladder, `HoopBack{i}`, Vector3.new(2, 0.12, 0.12), at(0, y, lz + 1.5), YELLOW).CanCollide = false
		for _, s in { -1, 1 } do
			part(ladder, `HoopSide{i}_{s}`, Vector3.new(0.12, 0.12, 1.5), at(s * 1, y, lz + 0.75), YELLOW).CanCollide = false
		end
	end
	for _, s in { -1, 0, 1 } do
		part(ladder, `CageStrap{s}`, Vector3.new(0.1, DECK_Y - 8, 0.1), at(s * 0.9, 8 + (DECK_Y - 8) / 2, lz + (if s == 0 then 1.5 else 0.9)), YELLOW).CanCollide = false
	end

	-- Silo auf dem Turm: Mantel mit Bändern und Firmenfarbe, Dach, Filter, Trichter, Schieber
	local silo = Instance.new("Model")
	silo.Name = "TowerSilo"
	silo.Parent = model
	local siloH = 6.6
	disc(silo, "Shell", at(0, DECK_Y + siloH / 2, 0), siloH, 9.4, SILO)
	for i, y in { DECK_Y + 0.4, DECK_Y + 2.4, DECK_Y + 4.8, DECK_Y + siloH - 0.3 } do
		disc(silo, `Band{i}`, at(0, y, 0), 0.25, 9.6, STEEL)
	end
	local band = disc(silo, "TowerHopperBand", at(0, DECK_Y + 3.6, 0), 0.9, 9.55, ACCENT_DEFAULT, Enum.Material.SmoothPlastic)
	accent(band)
	local roofY = DECK_Y + siloH
	disc(silo, "Roof1", at(0, roofY + 0.2, 0), 0.4, 9.7, STEEL_LIGHT)
	disc(silo, "Roof2", at(0, roofY + 0.6, 0), 0.4, 7.2, STEEL_LIGHT)
	disc(silo, "TowerSiloCap", at(0, roofY + 1, 0), 0.4, 4.4, STEEL_LIGHT)
	part(silo, "DustFilter", Vector3.new(1.8, 1.4, 1.8), at(-2.2, roofY + 1.5, -1), GREY_BOX)
	part(silo, "DustFilterFan", Vector3.new(1, 0.6, 1), at(-2.2, roofY + 2.5, -1), ORANGE)
	part(silo, "Hatch", Vector3.new(1.4, 0.3, 1.4), at(1.8, roofY + 0.95, -1.8), STEEL_DARK)
	AmbientProps.beacon(silo, "TowerBeacon", at(3.2, roofY + 0.4, -2.6))
	-- Füllstandsmarken am Mantel
	for i = 0, 4 do
		part(silo, `LevelMark{i}`, Vector3.new(0.6, 0.12, 0.08), at(0, DECK_Y + 0.8 + i * 1.3, -4.72), if i == 4 then Color3.fromRGB(200, 40, 40) else YELLOW, Enum.Material.SmoothPlastic).CanCollide = false
	end
	-- Trichter unter dem Rost (stufenweise kleiner) und Schieber mit Antrieb
	for i, d in { 8.6, 6.8, 5, 3.2 } do
		disc(silo, `Funnel{i}`, at(0, DECK_Y - 0.2 - 1.6 - (i - 1) * 1.5, 0), 1.5, d, SILO)
	end
	local gateY = DECK_Y - 0.2 - 1.6 - 4.5 - 1.15
	part(silo, "SlideGate", Vector3.new(2.6, 0.7, 2.6), at(0, gateY, 0), STEEL_DARK)
	tube(silo, "GateActuator", pos(1.3, gateY, 0), pos(3.6, gateY, 0), 0.45, ORANGE)
	part(silo, "Distributor", Vector3.new(2.4, 1.4, 2.4), at(0, gateY - 1.05, 0), GREY_BOX)

	-- Zuführrohr aus dem Lager: senkrecht am Einlass, oben unter der Decke ins Silodach
	local feed = Instance.new("Model")
	feed.Name = "TowerFeed"
	feed.Parent = model
	local pipeLen = cfg.TowerFeedLength
	local pipeY = roofY + 2.2
	local backZ = 4 + pipeLen
	tube(feed, "TowerFeedPipe", pos(0, pipeY, backZ), pos(0, pipeY, 2.4), 1.6, STEEL_LIGHT)
	tube(feed, "TowerFeedDrop", pos(0, 3, backZ), pos(0, pipeY + 0.8, backZ), 1.6, STEEL_LIGHT)
	tube(feed, "TowerFeedInlet", pos(0, pipeY + 0.8, 2.4), pos(0, roofY + 0.6, 2.4), 1.6, STEEL_LIGHT)
	local ceiling = LayoutConfig.HallWallHeight
	for i = 1, 3 do
		local z = 2.4 + i * (backZ - 2.4) / 4
		disc(feed, `Flange{i}`, at(0, pipeY, z) * CFrame.Angles(math.rad(90), 0, 0), 0.3, 1.9, STEEL)
		part(feed, `Hanger{i}`, Vector3.new(0.12, ceiling - pipeY, 0.12), at(0, pipeY + (ceiling - pipeY) / 2, z), STEEL_DARK).CanCollide = false
	end
	local intake = part(feed, "TowerIntake", Vector3.new(3, 3, 3), at(0, 1.5, backZ), GREY_BOX)
	intake.CastShadow = true
	part(feed, "IntakeGrate", Vector3.new(2.6, 0.1, 2.6), at(0, 3.05, backZ), STEEL_DARK, Enum.Material.DiamondPlate)
	FloatingText.title(feed, "TowerIntakeLabel", at(0, 6, backZ - 2), "From storage", 1.4)

	-- Portal vom Turm über die Spur: zwei Längsträger auf den Turmstützen und auf zwei Stützen
	-- jenseits der Spur, Querträger vorne, zwei Querriegel für den Bunker, Laufsteg obendrauf
	local portal = Instance.new("Model")
	portal.Name = "LoadingPortal"
	portal.Parent = model
	for _, x in { -L, L } do
		column(portal, `PortalColumn{x}`, at(x, 0, farZ), BEAM_Y - 0.8)
		beam(portal, `LongBeam{x}`, pos(x, BEAM_Y, -L + 0.4), pos(x, BEAM_Y, farZ - 0.6), 0.7, 1.6, YELLOW)
		-- Kopfbänder zwischen Stütze und Längsträger
		beam(portal, `KneeBrace{x}`, pos(x, BEAM_Y - 5, farZ), pos(x, BEAM_Y - 0.8, farZ + 4.5), 0.35, 0.35, YELLOW)
	end
	beam(portal, "CrossBeamFar", pos(-L - 0.6, BEAM_Y, farZ), pos(L + 0.6, BEAM_Y, farZ), 0.8, 1.6, YELLOW)
	for _, dz in { -3.1, 3.1 } do
		beam(portal, `BinBeam{dz}`, pos(-L + 0.35, BEAM_Y - 0.4, spoutZ + dz), pos(L - 0.35, BEAM_Y - 0.4, spoutZ + dz), 0.5, 0.8, YELLOW)
	end
	for _, x in { -L - 0.4, L + 0.4 } do
		local stripe = part(portal, `TowerCrossbeamStripe{x}`, Vector3.new(0.1, 0.5, -L - farZ - 1), at(x, BEAM_Y, (-L + farZ) / 2), ACCENT_DEFAULT, Enum.Material.SmoothPlastic)
		accent(stripe)
	end
	-- Laufsteg vom Turm bis zum Portalende
	local walkLen = -L - farZ
	part(portal, "Walkway", Vector3.new(3, 0.2, walkLen + 0.6), at(spoutX, DECK_Y - 0.1, -L - walkLen / 2), STEEL_LIGHT, Enum.Material.DiamondPlate)
	railing(portal, "WalkRailL", pos(spoutX + 1.6, DECK_Y, -L - 1.1), pos(spoutX + 1.6, DECK_Y, farZ + 0.3))
	railing(portal, "WalkRailR", pos(spoutX - 1.6, DECK_Y, -L - 1.1), pos(spoutX - 1.6, DECK_Y, farZ + 0.3))
	railing(portal, "WalkRailEnd", pos(spoutX - 1.6, DECK_Y, farZ + 0.3), pos(spoutX + 1.6, DECK_Y, farZ + 0.3))
	FloatingText.title(portal, "TowerLabel", at(spoutX, DECK_Y + 6, spoutZ), "Loading", 2.4, YELLOW)

	-- Der eine Rüssel: Förderschnecke vom Silo, Bunker, Schieber, Faltenbalg-Rüssel, Lampe, Strahler
	local i = 1
	local x = spoutX
	local station = Instance.new("Model")
	station.Name = `LoadStation{i}`
	station.Parent = model
	local binTop = BEAM_Y - 1.2
	local binH = 3.4
	-- Bunker mit Versteifungsrippen, Aufhängung, Trichterstufen, Schieber und Antrieb
	part(station, "Bin", Vector3.new(5, binH, 5), at(x, binTop - binH / 2, spoutZ), GREY_BOX)
	for _, s in { -1, 1 } do
		part(station, `Rib{s}`, Vector3.new(5.15, 0.25, 0.25), at(x, binTop - binH / 2 + s * 0.9, spoutZ - 2.55), YELLOW).CanCollide = false
		part(station, `RibBack{s}`, Vector3.new(5.15, 0.25, 0.25), at(x, binTop - binH / 2 + s * 0.9, spoutZ + 2.55), YELLOW).CanCollide = false
	end
	for _, s in { -1, 1 } do
		for _, zz in { -1, 1 } do
			part(station, `Hanger{s}_{zz}`, Vector3.new(0.3, BEAM_Y - 0.8 - binTop, 0.3), at(x + s * 2.2, (binTop + BEAM_Y - 0.8) / 2, spoutZ + zz * 3.1), YELLOW)
		end
	end
	local coneTop = binTop - binH
	part(station, "Cone1", Vector3.new(3.8, 0.8, 3.8), at(x, coneTop - 0.4, spoutZ), GREY_BOX)
	part(station, "Cone2", Vector3.new(2.6, 0.7, 2.6), at(x, coneTop - 1.15, spoutZ), GREY_BOX)
	local gate = coneTop - 1.5 - 0.3
	part(station, "Gate", Vector3.new(2.4, 0.6, 2.4), at(x, gate, spoutZ), STEEL_DARK)
	tube(station, "GateCylinder", pos(x + 1.2, gate, spoutZ), pos(x + 3.4, gate, spoutZ), 0.4, ORANGE)
	-- Faltenbalg (eingefahren) zwischen Schieber und Rüsselrohr
	local bellowTop = gate - 0.3
	local folds = 5
	local foldH = (bellowTop - CHUTE_TOP) / folds
	for k = 0, folds - 1 do
		local w = if k % 2 == 0 then 2.4 else 2
		part(station, `Bellow{k}`, Vector3.new(w, foldH, w), at(x, bellowTop - foldH * (k + 0.5), spoutZ), RUBBER, Enum.Material.Rubber).CanCollide = false
	end
	local tubePart = part(station, `ChuteTube{i}`, Vector3.new(1.7, CHUTE_REST, 1.7), at(x, CHUTE_TOP - CHUTE_REST / 2, spoutZ), Color3.fromRGB(40, 40, 42), Enum.Material.Fabric)
	tubePart:SetAttribute("ChuteTop", pos(x, CHUTE_TOP, spoutZ).Y)
	tubePart.CanCollide = false
	-- Teleskop: zwei weitere, schmalere Rohre stecken eingefahren im äußeren
	for k, n in { "Mid", "Inner" } do
		local w = 1.7 - k * 0.2
		local inner = part(station, `ChuteTube{i}{n}`, Vector3.new(w, CHUTE_REST, w), at(x, CHUTE_TOP - CHUTE_REST / 2, spoutZ), Color3.fromRGB(52 + k * 10, 52 + k * 10, 56 + k * 10), Enum.Material.Metal)
		inner.CanCollide = false
	end
	local nozzle = part(station, `ChuteNozzle{i}`, Vector3.new(2.5, 0.8, 2.5), at(x, CHUTE_TOP - CHUTE_REST - 0.4, spoutZ), RUBBER, Enum.Material.Rubber)
	nozzle.CanCollide = false
	local lp = part(station, `LoadPoint{i}`, Vector3.new(1, 1, 1), at(x, CHUTE_TOP - 6, spoutZ), WHITE, Enum.Material.SmoothPlastic)
	lp.Transparency = 1
	flat(lp)
	lp:SetAttribute("Bay", i)
	-- Förderschnecke vom Silo-Verteiler schräg hoch in die Turmseite des Bunkers (zwischen den
	-- Turmriegeln durch), Getriebemotor oben am unteren Ende
	local from = pos(x, gateY - 1.05, -1.2)
	local to = pos(x, binTop - 0.9, spoutZ + 2.2)
	tube(station, "ScrewConveyor", from, to, 1.1, STEEL_LIGHT)
	local dir = (to - from).Unit
	local motorAt = from + dir * 2.6 + Vector3.new(0, 0.9, 0)
	part(station, "ScrewMotor", Vector3.new(1, 0.9, 1.6), CFrame.lookAt(motorAt, motorAt + dir), ORANGE)
	for k = 1, 3 do
		local p = from + dir * ((to - from).Magnitude * k / 4)
		disc(station, `ScrewFlange{k}`, CFrame.lookAt(p, p + dir) * CFrame.Angles(math.rad(90), 0, 0), 0.25, 1.4, STEEL)
	end
	-- Statuslampe am Bunker zur Einfahrt hin (grün beladen, blau voll, orange leer, grau frei)
	local lamp = part(station, `ChuteLamp{i}`, Vector3.new(0.9, 0.9, 0.9), at(x - 2.75, coneTop + 0.6, spoutZ - 1.8), STEEL_LIGHT, Enum.Material.Neon)
	lamp.Shape = Enum.PartType.Ball
	local lampLight = Instance.new("PointLight")
	lampLight.Name = "Glow"
	lampLight.Range = 9
	lampLight.Enabled = false
	lampLight.Parent = lamp
	-- Strahler unter den Längsträgern links und rechts des Bunkers
	for _, s in { -1, 1 } do
		local flood = part(station, `Floodlight{s}`, Vector3.new(0.8, 0.4, 1.4), at(s * L, BEAM_Y - 1, spoutZ + s * 5), Color3.fromRGB(255, 250, 225), Enum.Material.Neon)
		flood.CanCollide = false
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Angle = 70
		spot.Range = 26
		spot.Brightness = 1.2
		spot.Parent = flood
	end
	-- Anzeige über der Spur vor dem Rüssel, zum ankommenden Fahrer gedreht (schaut nach +X)
	local displayCF = o * CFrame.new(cfg.Chute.X - 16, 15.5, cfg.Lane.Z) * CFrame.Angles(0, math.rad(-90), 0)
	FloatingText.create(model, `BayDisplay{i}`, displayCF, 7, {
		{ Name = "Title", Text = "Loading", Size = 1.4, Color = Color3.fromRGB(200, 208, 220) },
		{ Name = "Value", Text = "Ready", Size = 1.8 },
	})

	-- Steuerkabine am Turmfuß mit Fenster, Tür, Klimagerät und Schaltschrank
	local cabin = Instance.new("Model")
	cabin.Name = "ControlCabin"
	cabin.Parent = model
	local c = at(L + 4.8, 0, 2.2)
	part(cabin, "Body", Vector3.new(4.6, 3.8, 4), c * CFrame.new(0, 1.9, 0), Color3.fromRGB(226, 228, 230), Enum.Material.SmoothPlastic)
	part(cabin, "Roof", Vector3.new(5, 0.3, 4.4), c * CFrame.new(0, 3.95, 0), STEEL, Enum.Material.Metal)
	local window = part(cabin, "Window", Vector3.new(3, 1.4, 0.1), c * CFrame.new(-0.4, 2.5, -2.02), Color3.fromRGB(150, 200, 230), Enum.Material.Glass)
	window.Transparency = 0.3
	part(cabin, "Door", Vector3.new(0.1, 3, 1.5), c * CFrame.new(-2.32, 1.5, 0.8), STEEL_LIGHT, Enum.Material.Metal)
	part(cabin, "AC", Vector3.new(1.4, 1, 0.7), c * CFrame.new(1, 3, 2.35), STEEL_LIGHT, Enum.Material.Metal)
	part(cabin, "Cabinet", Vector3.new(1.6, 3, 0.8), c * CFrame.new(3.4, 1.5, 0), ORANGE, Enum.Material.Metal)
	local led = part(cabin, "CabinetLed", Vector3.new(0.3, 0.3, 0.1), c * CFrame.new(3.6, 2.5, -0.42), Color3.fromRGB(90, 220, 110), Enum.Material.Neon)
	led.CanCollide = false
	AmbientProps.blink(led)
end

-- Bodenmarkierung der Verladestraße: gelbe Randlinien von der Seitenöffnung bis zur Kurve, Bogen
-- zum Rolltor, Richtungspfeile, Ladefeld unter dem Rüssel, Schriftzug an der Einfahrt
local function lane(model: Model, o: CFrame)
	local cfg = LayoutConfig.Garage
	local laneCfg = cfg.Lane
	local folder = Instance.new("Model")
	folder.Name = "LoadingLane"
	folder.Parent = model
	local hallLeft = LayoutConfig.HallOffset.X + LayoutConfig.HallSize.X / 2
	local hallFront = LayoutConfig.HallOffset.Y - LayoutConfig.HallSize.Y / 2
	local half = laneCfg.Width / 2
	local straight = hallLeft - laneCfg.TurnX
	for _, s in { -1, 1 } do
		local line = part(folder, `LaneEdge{s}`, Vector3.new(straight, 0.06, 0.5), o * CFrame.new((hallLeft + laneCfg.TurnX) / 2, 0.03, laneCfg.Z + s * half), YELLOW, Enum.Material.SmoothPlastic)
		flat(line)
	end
	-- Rechtskurve: Mittelpunkt vor der Spur Richtung Tor
	local center = Vector2.new(laneCfg.TurnX, laneCfg.Z - laneCfg.TurnRadius)
	local segments = 14
	for _, s in { -1, 1 } do
		local r = laneCfg.TurnRadius + s * half
		for k = 1, segments do
			local a0 = math.rad(90 + (k - 1) / segments * 90)
			local a1 = math.rad(90 + k / segments * 90)
			local p0 = center + Vector2.new(math.cos(a0), math.sin(a0)) * r
			local p1 = center + Vector2.new(math.cos(a1), math.sin(a1)) * r
			local mid = (p0 + p1) / 2
			local len = (p1 - p0).Magnitude + 0.3
			local seg = part(folder, `TurnEdge{s}_{k}`, Vector3.new(0.5, 0.06, len), o * CFrame.lookAt(Vector3.new(mid.X, 0.03, mid.Y), Vector3.new(p1.X, 0.03, p1.Y)), YELLOW, Enum.Material.SmoothPlastic)
			flat(seg)
		end
		-- kurzes Stück geradeaus bis zum Tor
		local x = center.X - laneCfg.TurnRadius + s * -half
		local len = center.Y - hallFront
		local tail = part(folder, `ExitEdge{s}`, Vector3.new(0.5, 0.06, len), o * CFrame.new(x, 0.03, center.Y - len / 2), YELLOW, Enum.Material.SmoothPlastic)
		flat(tail)
	end
	-- Pfeile in Fahrtrichtung (-X) auf der Geraden
	for k, ax in { hallLeft - 12, cfg.Chute.X + 28, laneCfg.TurnX + 8 } do
		for _, s in { -1, 1 } do
			local tip = o * CFrame.new(ax - 2, 0.035, laneCfg.Z)
			local arm = part(folder, `Arrow{k}_{s}`, Vector3.new(0.6, 0.06, 4.6), tip * CFrame.Angles(0, math.rad(s * 45 - 90), 0) * CFrame.new(0, 0, -2.1), WHITE, Enum.Material.SmoothPlastic)
			flat(arm)
		end
		local shaft = part(folder, `ArrowShaft{k}`, Vector3.new(6, 0.06, 0.6), o * CFrame.new(ax + 1.4, 0.035, laneCfg.Z), WHITE, Enum.Material.SmoothPlastic)
		flat(shaft)
	end
	-- Ladefeld unter dem Rüssel (weißer Rahmen) mit Schrift
	local box = o * CFrame.new(cfg.Chute.X, 0.04, cfg.Chute.Y)
	for _, s in { -1, 1 } do
		flat(part(folder, `LoadBoxSide{s}`, Vector3.new(14, 0.06, 0.4), box * CFrame.new(0, 0, s * 7), WHITE, Enum.Material.SmoothPlastic))
		flat(part(folder, `LoadBoxEnd{s}`, Vector3.new(0.4, 0.06, 14), box * CFrame.new(s * 7, 0, 0), WHITE, Enum.Material.SmoothPlastic))
	end
	floorText(folder, "LoadBoxText", "LOAD", Vector2.new(8, 2.6), box * CFrame.new(5, 0.03, 0) * CFrame.Angles(0, math.rad(-90), 0), WHITE)
	floorText(folder, "LaneText", "LOADING LANE", Vector2.new(16, 3), o * CFrame.new(hallLeft - 22, 0.07, laneCfg.Z) * CFrame.Angles(0, math.rad(-90), 0), YELLOW)
end

-- Zustand eines Stellplatzes am Turm (LoadingService): Lampe, Anzeige, Schurrenlänge
local BAY_COLORS: { [string]: Color3 } = {
	Idle = Color3.fromRGB(150, 154, 160),
	Loading = Color3.fromRGB(70, 210, 90),
	Full = Color3.fromRGB(80, 160, 255),
	NoStock = Color3.fromRGB(255, 160, 30),
	Align = Color3.fromRGB(255, 200, 40),
}

function GarageTemplate.setBayState(model: Model, bay: number, state: string, title: string, value: string)
	local color = BAY_COLORS[state] or BAY_COLORS.Idle
	local lamp = model:FindFirstChild(`ChuteLamp{bay}`, true)
	if lamp and lamp:IsA("BasePart") then
		lamp.Color = color
		local glow = lamp:FindFirstChild("Glow")
		if glow and glow:IsA("PointLight") then
			glow.Color = color
			glow.Enabled = state ~= "Idle"
		end
	end
	local display = model:FindFirstChild(`BayDisplay{bay}`, true)
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
	local tube = model:FindFirstChild(`ChuteTube{bay}`, true)
	local nozzle = model:FindFirstChild(`ChuteNozzle{bay}`, true)
	if not (tube and tube:IsA("BasePart") and nozzle and nozzle:IsA("BasePart")) then
		return goals
	end
	local top = tube:GetAttribute("ChuteTop")
	if typeof(top) ~= "number" then
		return goals
	end
	local length = if bottomY then math.clamp(top - bottomY - 0.8, CHUTE_REST, 19) else CHUTE_REST
	local x, z = tube.Position.X, tube.Position.Z
	local rot = tube.CFrame - tube.Position
	-- Teleskop aus drei Rohren: gleich lang, gleichmäßig überlappend ausgefahren
	local segments = { tube }
	for _, n in { "Mid", "Inner" } do
		local seg = model:FindFirstChild(`ChuteTube{bay}{n}`, true)
		if seg and seg:IsA("BasePart") then
			table.insert(segments, seg)
		end
	end
	local count = #segments
	local segLen = math.min(length, math.max(CHUTE_REST, length / count + 0.4))
	for k, seg in segments do
		local segTop = top - (k - 1) * (if count > 1 then (length - segLen) / (count - 1) else 0)
		goals[seg] = { Size = Vector3.new(seg.Size.X, segLen, seg.Size.Z), CFrame = CFrame.new(x, segTop - segLen / 2, z) * rot }
	end
	goals[nozzle] = { CFrame = CFrame.new(x, top - length - 0.4, z) * rot }
	return goals
end

-- Deko-Ecke hinter der Verladestraße neben dem Auswahlring (Felix 2026-10-10: keine Werkstatt, nur
-- Deko, damit die Halle nicht leer wirkt): Hochregale mit Paletten und Kartons, Ölfässer,
-- Palettenstapel. Lokal zur Plotmitte, Bereich x 100..148, z −27..4 (frei von Spur, Ring, Turm).
local PALLET_WOOD = Color3.fromRGB(176, 140, 96)
local CARTON = { Color3.fromRGB(184, 146, 98), Color3.fromRGB(168, 130, 84), Color3.fromRGB(196, 160, 112) }
local RACK_UPRIGHT = Color3.fromRGB(40, 90, 150)
local RACK_BEAM = Color3.fromRGB(222, 120, 40)

-- Europalette (Unterkante = cf), 4 × 0.5 × 3.4
local function pallet(parent: Instance, name: string, cf: CFrame)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	part(parent, `{name}Deck`, Vector3.new(4, 0.15, 3.4), cf * CFrame.new(0, 0.425, 0), PALLET_WOOD, Enum.Material.WoodPlanks)
	for _, dz in { -1.4, 0, 1.4 } do
		part(parent, `{name}Runner{dz}`, Vector3.new(4, 0.35, 0.5), cf * CFrame.new(0, 0.175, dz), PALLET_WOOD:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.WoodPlanks)
	end
end

-- Palette mit 2 × 2 Kartonstapeln (zufällige Höhe bis maxLayers)
local function cartonPallet(parent: Instance, name: string, cf: CFrame, rng: Random, maxLayers: number)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
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
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
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
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	local d = part(parent, name, Vector3.new(2.6, 1.6, 1.6), cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), color)
	d.Shape = Enum.PartType.Cylinder
	local lid = part(parent, `{name}Lid`, Vector3.new(0.06, 1.3, 1.3), cf * CFrame.new(0, 2.62, 0) * CFrame.Angles(0, 0, math.rad(90)), color:Lerp(Color3.new(0, 0, 0), 0.25))
	lid.Shape = Enum.PartType.Cylinder
end

local function props(model: Model, o: CFrame)
	local deco = Instance.new("Folder")
	deco.Name = "Decoration"
	deco.Parent = model
	local rng = Random.new(17)
	local BLUE = Color3.fromRGB(40, 90, 150)
	local RED = Color3.fromRGB(190, 50, 40)
	local GREEN = Color3.fromRGB(60, 110, 60)

	-- Hochregale an der Lagergrenze (Front zur Spur) und an der Seitenwand
	highRack(deco, "RackFront", o * CFrame.new(118, 0, 2.2) * CFrame.Angles(0, math.rad(180), 0), 4, rng)
	highRack(deco, "RackSide", o * CFrame.new(147.4, 0, -12) * CFrame.Angles(0, math.rad(90), 0), 2, rng)

	-- Ölfässer auf Auffangwanne und eine Palette mit Fässern
	local spill = o * CFrame.new(106, 0, -23)
	local spillGroup = Instance.new("Model")
	spillGroup.Name = "SpillPallet"
	spillGroup.Parent = deco
	part(spillGroup, "SpillPallet", Vector3.new(4.4, 0.4, 4.4), spill * CFrame.new(0, 0.2, 0), YELLOW, Enum.Material.SmoothPlastic)
	for i, p in { Vector2.new(-0.95, -0.95), Vector2.new(0.95, -0.95), Vector2.new(0, 1) } do
		drum(spillGroup, `SpillDrum{i}`, spill * CFrame.new(p.X, 0.4, p.Y), if i == 3 then RED else BLUE)
	end
	local drumPallet = o * CFrame.new(112, 0, -23)
	local drumGroup = Instance.new("Model")
	drumGroup.Name = "DrumPallet"
	drumGroup.Parent = deco
	pallet(drumGroup, "DrumPallet", drumPallet)
	for i, p in { Vector2.new(-0.95, -0.8), Vector2.new(0.95, -0.8), Vector2.new(-0.95, 0.8), Vector2.new(0.95, 0.8) } do
		drum(drumGroup, `PalletDrum{i}`, drumPallet * CFrame.new(p.X, 0.5, p.Y), if i == 2 then GREEN else BLUE)
	end
	drum(deco, "LooseDrum1", o * CFrame.new(116.5, 0, -21.5), RED)
	drum(deco, "LooseDrum2", o * CFrame.new(117, 0, -24.6), BLUE)

	-- Kartonpaletten und ein Stapel leerer Paletten auf dem Boden
	cartonPallet(deco, "FloorPallet1", o * CFrame.new(103, 0, -6) * CFrame.Angles(0, math.rad(8), 0), rng, 3)
	cartonPallet(deco, "FloorPallet2", o * CFrame.new(108, 0, -6.5) * CFrame.Angles(0, math.rad(-4), 0), rng, 2)
	cartonPallet(deco, "FloorPallet3", o * CFrame.new(126, 0, -22) * CFrame.Angles(0, math.rad(90), 0), rng, 3)
	for i = 1, 6 do
		pallet(deco, `EmptyPallet{i}`, o * CFrame.new(103, (i - 1) * 0.5, -13) * CFrame.Angles(0, math.rad(if i % 2 == 0 then 3 else -2), 0))
	end

	-- Feuerlöscher an der Hallenstütze neben der Seitenöffnung
	local ext = o * CFrame.new(147.7, 3, -20.4)
	local extGroup = Instance.new("Model")
	extGroup.Name = "Extinguisher"
	extGroup.Parent = deco
	local extBody = part(extGroup, "Extinguisher", Vector3.new(1.2, 0.5, 0.5), ext * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)
	extBody.Shape = Enum.PartType.Cylinder
	part(extGroup, "ExtinguisherBracket", Vector3.new(0.5, 0.2, 0.4), ext * CFrame.new(0.25, 0.3, 0), STEEL_DARK)

	-- Werkstattecke rechts vom Tor (Felix: „nicht so leer und tot“) mit einem Arbeiter
	local shop = Instance.new("Folder")
	shop.Name = "Workshop"
	shop.Parent = model
	AmbientProps.workbench(shop, "Workbench", o * CFrame.new(-28, 0, -78.5) * CFrame.Angles(0, math.rad(180), 0))
	AmbientProps.drums(shop, "OilDrums", o * CFrame.new(-18, 0, -72), 4)
	AmbientProps.partsShelf(shop, "PartsShelf", o * CFrame.new(-42, 0, -66) * CFrame.Angles(0, math.rad(-90), 0))
	AmbientProps.tireStack(shop, "Tires1", o * CFrame.new(-42, 0, -52), 5)
	AmbientProps.tireStack(shop, "Tires2", o * CFrame.new(-42, 0, -47.5), 4)
	AmbientProps.cartonPallet(shop, "GarageWrapped", o * CFrame.new(-22, 0, -22), 3, true)
	AmbientProps.cartonPallet(shop, "GarageOpen", o * CFrame.new(-29, 0, -22), 2, false)
	AmbientProps.palletTruck(shop, "GaragePalletTruck", o * CFrame.new(-34, 0, -30) * CFrame.Angles(0, math.rad(60), 0))
	AmbientProps.cones(shop, "LaneCones", o * CFrame.new(-12, 0, -60) * CFrame.Angles(0, math.rad(90), 0), 4, 6)
	AmbientProps.staffPath(model, "StaffWorkshop", { (o * CFrame.new(-26, 0, -75)).Position, (o * CFrame.new(-36, 0, -56)).Position, (o * CFrame.new(-26, 0, -26)).Position })
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
	lane(model, o)
	props(model, o)
	door(model, plotCFrame)
	return model
end

return table.freeze(GarageTemplate)
