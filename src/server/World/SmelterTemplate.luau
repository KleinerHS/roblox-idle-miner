--!strict
-- Schmelze rechts in der Halle, nach FACTORY_MASTERPLAN_TOPDOWN.png (Phase 13b-4/5, Felix D-037,
-- 2026-10-13 „1:1 wie im Bild“):
--   * hinten ein gelbes Stahlgerüst mit Kreuzverstrebungen, Laufrost, Geländer, Treppe; darauf
--     orange Maschinen und der graue Aufgabebehälter über dem Ofenende
--   * Eingangslager hinten links: 4 Hochregale × 4 Paletten (16 Kisten Erz)
--   * Drehrohrofen in Längsrichtung aus Abschnitten (Glocke, Hals, Trommel, Konus) mit Laufringen,
--     Tragrollen, Zahnkranz und Antrieb; vorne die glühende Spitze (Glut, Funken, Rauch nur im Betrieb)
--   * davor die Schnecke im offenen gelben Rahmen bis zum Ausgangslager (4 Hochregale, 16 Kisten)
--   * gelbe Rohrleitungen am Boden, orange Maschinenkästen mit kleinen Geländern, Kistenpaletten
--   * außen an der rechten Wand zwei Tanks mit Leitungen in die Halle
-- Info-Anzeigen als schwebende Schrift (FloatingText). Jedes Objekt ist ein eigenes Model.
--
-- Vereinbarte Namen/Attribute (rekursiv gesucht):
--   Part "SmelterTerminalPart" mit ProximityPrompt "SmelterPrompt" (Attribut SmelterTerminal = true)
--   Part "SmelterDisplay"      (BillboardGui "Display": "Status", "Input", "Output")
--   Part "StatusLight", Part "FurnaceGlow", Part "KilnHotZone", Emitter "Fire"/"Sparks"/"Smoke"
--   Model "InputStore"/"OutputStore" (Regale mit Slot-Models, CrateRackBuilder)
--   Part "ConveyorInPort"/"ConveyorOutPort" (Anschlusspunkte der Förderbänder)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local BalanceConfig = require(Shared.Config.BalanceConfig)

local CrateRackBuilder = require(script.Parent.CrateRackBuilder)
local FloatingText = require(script.Parent.FloatingText)
local AmbientProps = require(script.Parent.AmbientProps)

local SmelterTemplate = {}

local SHELL = Color3.fromRGB(176, 112, 70)
local SHELL_LIGHT = Color3.fromRGB(196, 136, 92)
local SHELL_DARK = Color3.fromRGB(110, 76, 56)
local STEEL = Color3.fromRGB(70, 74, 80)
local STEEL_DARK = Color3.fromRGB(42, 44, 48)
local STEEL_LIGHT = Color3.fromRGB(150, 154, 160)
local GREY_BOX = Color3.fromRGB(120, 124, 130)
local TANK = Color3.fromRGB(196, 200, 206)
local CONCRETE = Color3.fromRGB(120, 118, 114)
local ORANGE = Color3.fromRGB(226, 140, 40)
local ORANGE_DARK = Color3.fromRGB(176, 104, 30)
local YELLOW = Color3.fromRGB(236, 182, 40)
local CRATE = Color3.fromRGB(206, 120, 70)
local CRATE_DARK = Color3.fromRGB(150, 86, 50)
local BLACK = Color3.fromRGB(30, 30, 30)
local GLOW = Color3.fromRGB(255, 140, 40)
local GLOW_OFF = Color3.fromRGB(70, 44, 32)
local HOT_ON = Color3.fromRGB(255, 120, 40)
local HOT_OFF = SHELL_DARK
local LAMP_IDLE = Color3.fromRGB(255, 160, 30)

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

local function cylinder(parent: Instance, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(length, diameter, diameter), cf, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function group(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Balken zwischen zwei Punkten (Weltkoordinaten)
local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, material: Enum.Material?): Part
	local len = (b - a).Magnitude
	return part(parent, name, Vector3.new(thickness, thickness, len), CFrame.lookAt((a + b) / 2, b), color, material)
end

-- Rohr zwischen zwei Punkten (Weltkoordinaten)
local function pipe(parent: Instance, name: string, a: Vector3, b: Vector3, diameter: number, color: Color3): Part
	local len = (b - a).Magnitude
	local p = part(parent, name, Vector3.new(len, diameter, diameter), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), color, Enum.Material.Metal)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function port(parent: Instance, name: string, cf: CFrame)
	local p = part(parent, name, Vector3.new(3, 0.2, 3), cf, YELLOW, Enum.Material.SmoothPlastic)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
end

-- kleines gelbes Geländer (Pfosten + zwei Holme) entlang einer Linie
local function railing(parent: Instance, name: string, a: Vector3, b: Vector3)
	local m = group(parent, name)
	local dir = b - a
	local n = math.max(1, math.floor(dir.Magnitude / 4))
	for i = 0, n do
		local p = a + dir * (i / n)
		part(m, `Post{i}`, Vector3.new(0.3, 3.4, 0.3), CFrame.new(p + Vector3.new(0, 1.7, 0)), YELLOW, Enum.Material.Metal)
	end
	beam(m, "RailTop", a + Vector3.new(0, 3.3, 0), b + Vector3.new(0, 3.3, 0), 0.25, YELLOW)
	beam(m, "RailMid", a + Vector3.new(0, 1.7, 0), b + Vector3.new(0, 1.7, 0), 0.2, YELLOW)
end

-- oranger Maschinenkasten (Pumpe/Schaltschrank) mit Bedienfeld und Geländer davor
local function machine(parent: Instance, name: string, cf: CFrame, size: Vector3)
	local m = group(parent, name)
	part(m, "Base", Vector3.new(size.X + 1, 0.4, size.Z + 1), cf * CFrame.new(0, 0.2, 0), STEEL_DARK, Enum.Material.DiamondPlate)
	part(m, "Body", size, cf * CFrame.new(0, 0.4 + size.Y / 2, 0), ORANGE, Enum.Material.Metal)
	part(m, "Top", Vector3.new(size.X - 0.6, 0.4, size.Z - 0.6), cf * CFrame.new(0, 0.6 + size.Y, 0), ORANGE_DARK, Enum.Material.Metal)
	local panel = part(m, "Panel", Vector3.new(size.X * 0.5, size.Y * 0.4, 0.12), cf * CFrame.new(0, 0.4 + size.Y * 0.6, -size.Z / 2 - 0.06), Color3.fromRGB(40, 46, 56), Enum.Material.SmoothPlastic)
	panel.CanCollide = false
	local led = part(m, "Led", Vector3.new(0.4, 0.4, 0.12), cf * CFrame.new(size.X * 0.15, 0.4 + size.Y * 0.68, -size.Z / 2 - 0.13), Color3.fromRGB(90, 220, 110), Enum.Material.Neon)
	led.CanCollide = false
	for _, sx in { -1, 1 } do
		cylinder(m, `Pipe{sx}`, 1.4, 0.7, cf * CFrame.new(sx * (size.X / 2 + 0.5), 0.4 + size.Y * 0.3, 0), YELLOW, Enum.Material.Metal)
	end
	local front = (cf * CFrame.new(0, 0, -size.Z / 2 - 2.5)).Position
	local right = cf.RightVector * (size.X / 2 + 1.5)
	railing(m, "Railing", front - right, front + right)
end

-- Palette mit 2×2 orangen Kisten
local function cratePallet(parent: Instance, name: string, cf: CFrame)
	local m = group(parent, name)
	part(m, "Pallet", Vector3.new(6, 0.5, 6), cf * CFrame.new(0, 0.25, 0), CRATE_DARK, Enum.Material.WoodPlanks)
	for i, o in { Vector2.new(-1.45, -1.45), Vector2.new(1.45, -1.45), Vector2.new(-1.45, 1.45), Vector2.new(1.45, 1.45) } do
		local c = part(m, `Crate{i}`, Vector3.new(2.8, 2.6, 2.8), cf * CFrame.new(o.X, 1.8, o.Y), CRATE, Enum.Material.WoodPlanks)
		part(m, `CrateBand{i}`, Vector3.new(2.84, 0.3, 2.84), c.CFrame, CRATE_DARK, Enum.Material.Wood)
	end
end

-- Schwarzer Rippenschlauch (Abluft) auf gelben Böcken, entlang X von x1 nach x2
local function hose(parent: Instance, name: string, at: (number, number, number) -> CFrame, x1: number, x2: number, z: number)
	local m = group(parent, name)
	local y, d = 2.8, 4
	local len = math.abs(x2 - x1)
	local mid = (x1 + x2) / 2
	cylinder(m, "Duct", len, d, at(mid, y, z), BLACK, Enum.Material.Fabric)
	for i = 1, math.floor(len / 1.4) do
		local x = math.min(x1, x2) + i * 1.4
		cylinder(m, `Rib{i}`, 0.35, d + 0.3, at(x, y, z), Color3.fromRGB(56, 58, 62), Enum.Material.Rubber)
	end
	for i = 0, math.floor(len / 7) do
		local x = math.min(x1, x2) + 1 + i * ((len - 2) / math.floor(len / 7))
		for _, sz in { -1, 1 } do
			part(m, `StandPost{i}_{sz}`, Vector3.new(0.4, y + 0.6, 0.4), at(x, (y + 0.6) / 2, z + sz * (d / 2 + 0.5)), YELLOW, Enum.Material.Metal)
		end
		part(m, `StandBar{i}`, Vector3.new(0.4, 0.4, d + 1.4), at(x, y + 0.6, z), YELLOW, Enum.Material.Metal)
		part(m, `StandFoot{i}`, Vector3.new(0.4, 0.4, d + 1.4), at(x, 0.2, z), YELLOW, Enum.Material.Metal)
	end
	-- Abluftkästen an beiden Enden
	for i, x in { x1, x2 } do
		local dir = if x == math.min(x1, x2) then -1 else 1
		part(m, `EndBox{i}`, Vector3.new(5, 6, 6), at(x + dir * 2.5, 3, z), GREY_BOX, Enum.Material.Metal)
		part(m, `EndCap{i}`, Vector3.new(5.6, 0.5, 6.6), at(x + dir * 2.5, 6.25, z), STEEL_DARK, Enum.Material.Metal)
	end
	return m
end

-- Anlage mit gelbem Schutzkäfig (wie im Bild: oranger Kasten, graue Haube, gelber Rahmen)
local function cagedUnit(parent: Instance, name: string, cf: CFrame, size: Vector3)
	local m = group(parent, name)
	part(m, "Base", Vector3.new(size.X + 2, 0.4, size.Z + 2), cf * CFrame.new(0, 0.2, 0), STEEL_DARK, Enum.Material.DiamondPlate)
	part(m, "Body", size, cf * CFrame.new(0, 0.4 + size.Y / 2, 0), ORANGE, Enum.Material.Metal)
	part(m, "Hood", Vector3.new(size.X - 1, 1, size.Z - 1), cf * CFrame.new(0, 0.9 + size.Y, 0), GREY_BOX, Enum.Material.Metal)
	local hx, hz, h = size.X / 2 + 0.7, size.Z / 2 + 0.7, size.Y + 2
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(m, `Post{sx}_{sz}`, Vector3.new(0.35, h, 0.35), cf * CFrame.new(sx * hx, 0.4 + h / 2, sz * hz), YELLOW, Enum.Material.Metal)
		end
		part(m, `TopX{sx}`, Vector3.new(0.3, 0.3, hz * 2), cf * CFrame.new(sx * hx, 0.4 + h, 0), YELLOW, Enum.Material.Metal)
		part(m, `TopZ{sx}`, Vector3.new(hx * 2, 0.3, 0.3), cf * CFrame.new(0, 0.4 + h, sx * hz), YELLOW, Enum.Material.Metal)
		part(m, `MidZ{sx}`, Vector3.new(hx * 2, 0.25, 0.25), cf * CFrame.new(0, 0.4 + h * 0.5, sx * hz), YELLOW, Enum.Material.Metal)
	end
	local led = part(m, "Led", Vector3.new(0.4, 0.4, 0.12), cf * CFrame.new(size.X * 0.3, 0.4 + size.Y * 0.75, -size.Z / 2 - 0.06), Color3.fromRGB(90, 220, 110), Enum.Material.Neon)
	led.CanCollide = false
	return m
end

-- Gelber Poller
local function bollard(parent: Instance, name: string, cf: CFrame)
	local m = group(parent, name)
	cylinder(m, "Body", 3, 0.9, cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), YELLOW, Enum.Material.SmoothPlastic)
	cylinder(m, "Band", 0.4, 0.95, cf * CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, Enum.Material.SmoothPlastic)
end

-- Hochregal-Block (4 Regale) mit schwebendem Titel
local function store(parent: Instance, name: string, origin: CFrame, face: number, title: string): Model
	local block = group(parent, name)
	CrateRackBuilder.build(block, origin, { { Z = 0, Face = face } }, 4)
	FloatingText.title(block, `{name}Label`, origin * CFrame.new(0, 34, face * (CrateRackBuilder.Depth / 2 + 1)), title, 2.4, YELLOW)
	return block
end

function SmelterTemplate.build(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Smelter"
	-- Betriebszustand für die Client-Animation (Ofentrommel, Schnecke, Rundumleuchten)
	model:SetAttribute("Running", false)
	local zone = LayoutConfig.HallZones.Smelter
	local floorY = LayoutConfig.HallFloorTop
	-- Positionen lokal zur Plotmitte (X/Z), y über Hallenboden
	local function at(x: number, y: number, z: number): CFrame
		return plotCFrame * CFrame.new(x, floorY + y, z)
	end
	local function pos(x: number, y: number, z: number): Vector3
		return at(x, y, z).Position
	end
	local zx, zz = zone.Center.X, zone.Center.Y
	local zLeft, zRight = zx + zone.Size.X / 2, zx - zone.Size.X / 2 -- +X = links im Bild
	local zBack, zFront = zz + zone.Size.Y / 2, zz - zone.Size.Y / 2
	local hallRight = LayoutConfig.HallOffset.X - LayoutConfig.HallSize.X / 2

	-- Bodenplatte mit Warnkante zur Hallenmitte
	local floor = group(model, "SmelterFloor")
	local slabCF = at(zx, 0, zz)
	part(floor, "Floor", Vector3.new(zone.Size.X - 4, 0.12, zone.Size.Y - 4), slabCF * CFrame.new(0, 0.06, 0), CONCRETE, Enum.Material.Concrete).CanCollide = false
	for i = 1, 24 do
		local stripe = part(floor, `ZoneEdge{i}`, Vector3.new(0.6, 0.14, (zone.Size.Y - 4) / 24), slabCF * CFrame.new(zone.Size.X / 2 - 2, 0.07, -(zone.Size.Y - 4) / 2 + (zone.Size.Y - 4) / 24 * (i - 0.5)), if i % 2 == 0 then BLACK else YELLOW, Enum.Material.SmoothPlastic)
		stripe.CanCollide = false
	end

	-- Eingangslager hinten links (4 Hochregale, Fächer nach vorne)
	local inputX, inputZ = zLeft - 31, zBack - 13
	store(model, "InputStore", at(inputX, 0, inputZ), -1, "Ore Input")
	port(model, "ConveyorInPort", at(inputX + 20, 0.6, inputZ - 8))

	-- Drehrohrofen (Längsachse Z): Glocke hinten, Hals, Trommel, Konus, glühende Spitze vorne
	local kiln = group(model, "Kiln")
	local kilnX, kilnY = zRight + 24, 9.5
	local backZ, frontZ = zBack - 34, zz + 4
	local function onAxis(z: number): CFrame
		return at(kilnX, kilnY, z) * CFrame.Angles(0, math.rad(90), 0)
	end
	local segments = {
		{ "Bell", backZ, backZ - 18, 16, SHELL },
		{ "Neck", backZ - 18, backZ - 27, 11, SHELL_DARK },
		{ "Drum", backZ - 27, backZ - 44, 15, SHELL_LIGHT },
		{ "Cone1", backZ - 44, backZ - 49, 12.5, SHELL },
		{ "Cone2", backZ - 49, frontZ + 2, 10, SHELL_DARK },
	}
	for _, seg in segments do
		local a, b = seg[2] :: number, seg[3] :: number
		cylinder(kiln, `Kiln{seg[1]}`, a - b, seg[4] :: number, onAxis((a + b) / 2), seg[5] :: Color3, Enum.Material.Metal)
	end
	for i, z in { backZ - 9, backZ - 35 } do
		cylinder(kiln, `RidingRing{i}`, 1.8, (if i == 1 then 16 else 15) + 1.6, onAxis(z), STEEL_DARK, Enum.Material.Metal)
		local d = if i == 1 then 17.6 else 16.6
		part(kiln, `Pier{i}`, Vector3.new(14, kilnY - d / 2, 5), at(kilnX, (kilnY - d / 2) / 2, z), CONCRETE, Enum.Material.Concrete)
		for _, side in { -1, 1 } do
			cylinder(kiln, `Roller{i}_{side}`, 2.2, 2.8, at(kilnX + side * 4.8, kilnY - d / 2 + 0.6, z) * CFrame.Angles(0, math.rad(90), 0), STEEL, Enum.Material.Metal)
		end
	end
	-- Flansche an den Übergängen der Ofenabschnitte
	for i = 1, #segments - 1 do
		local z = segments[i][3] :: number
		local d = math.max(segments[i][4] :: number, segments[i + 1][4] :: number) + 0.6
		cylinder(kiln, `Flange{i}`, 0.6, d, onAxis(z), STEEL_DARK, Enum.Material.Metal)
	end
	-- Längsleisten auf Trommel und Konus: drehen sich im Betrieb mit (sichtbare Rotation)
	local spinner = group(kiln, "KilnSpin")
	local axis = part(spinner, "Axis", Vector3.new(0.2, 0.2, 0.2), onAxis(backZ - 35), STEEL_DARK)
	axis.Transparency = 1
	axis.CanCollide = false
	axis.CanQuery = false
	spinner.PrimaryPart = axis
	local barRuns = {
		{ backZ - 27.5, backZ - 33.6, 7.6 }, -- Trommel vor dem Laufring
		{ backZ - 36.4, backZ - 43.5, 7.6 }, -- Trommel hinter dem Laufring
		{ backZ - 49.5, frontZ + 2.5, 5.1 }, -- vorderer Konus
	}
	for r, run in barRuns do
		local a, b, radius = run[1], run[2], run[3]
		for i = 0, 7 do
			local bar = part(spinner, `Bar{r}_{i}`, Vector3.new(math.abs(a - b), 0.5, 0.9), onAxis((a + b) / 2) * CFrame.Angles(math.rad(i * 45), 0, 0) * CFrame.new(0, radius, 0), SHELL_DARK, Enum.Material.Metal)
			bar.CanCollide = false
		end
	end
	AmbientProps.spin(spinner, "X", 30, true)
	cylinder(kiln, "GirthGear", 1.4, 18, onAxis(backZ - 22), STEEL, Enum.Material.DiamondPlate)
	part(kiln, "DriveMotor", Vector3.new(4, 4, 6), at(kilnX + 11, 2.4, backZ - 22), ORANGE, Enum.Material.Metal)
	part(kiln, "DriveGearbox", Vector3.new(3.4, 3.4, 3.4), at(kilnX + 8, 3.6, backZ - 22), STEEL_DARK, Enum.Material.Metal)
	-- heiße Zone (glüht im Betrieb) und glühende Spitze
	local hot = cylinder(kiln, "KilnHotZone", 4, 12.7, onAxis(backZ - 46.5), HOT_OFF, Enum.Material.Metal)
	hot.CanCollide = false
	local tip = cylinder(kiln, "KilnTip", 3, 7.4, onAxis(frontZ + 0.5), STEEL_DARK, Enum.Material.Metal)
	tip.CanCollide = true
	local glow = part(kiln, "FurnaceGlow", Vector3.new(5.4, 5.4, 0.4), at(kilnX, kilnY, frontZ - 1.2), GLOW_OFF, Enum.Material.Neon)
	glow.Shape = Enum.PartType.Cylinder
	glow.Size = Vector3.new(0.4, 5.4, 5.4)
	glow.CFrame = onAxis(frontZ - 1.2)
	glow.CanCollide = false
	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Color = GLOW
	light.Range = 32
	light.Brightness = 3
	light.Enabled = false
	light.Parent = glow
	local fireAttachment = Instance.new("Attachment")
	fireAttachment.Name = "FireAttachment"
	fireAttachment.Parent = glow
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "Fire"
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 180, 70), Color3.fromRGB(255, 80, 20))
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.2), NumberSequenceKeypoint.new(1, 0.3) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	fire.Lifetime = NumberRange.new(0.4, 0.8)
	fire.Rate = 22
	fire.Speed = NumberRange.new(1, 2.5)
	fire.SpreadAngle = Vector2.new(25, 25)
	fire.LightEmission = 1
	fire.Enabled = false
	fire.Parent = fireAttachment
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120))
	sparks.Size = NumberSequence.new(0.25)
	sparks.Lifetime = NumberRange.new(0.4, 0.9)
	sparks.Rate = 14
	sparks.Speed = NumberRange.new(5, 10)
	sparks.SpreadAngle = Vector2.new(45, 45)
	sparks.Acceleration = Vector3.new(0, -25, 0)
	sparks.LightEmission = 1
	sparks.Enabled = false
	sparks.Parent = fireAttachment

	-- Gelbes Stahlgerüst hinten über dem Ofenende mit Kreuzverstrebungen, Rost, Geländer, Treppe
	local gantry = group(model, "Gantry")
	local gx1, gx2 = zRight + 3, kilnX + 16
	local gz1, gz2 = backZ - 12, zBack - 2
	local gh = 20
	local xs = { gx1, (gx1 + gx2) / 2, gx2 }
	local zs = { gz1, (gz1 + gz2) / 2, gz2 }
	for _, x in xs do
		for _, z in zs do
			-- vorne mittig stünde die Stütze in der Ofenglocke
			if z == gz1 and x == xs[2] then
				continue
			end
			part(gantry, `Column{x}_{z}`, Vector3.new(0.9, gh, 0.9), at(x, gh / 2, z), YELLOW, Enum.Material.Metal)
		end
	end
	for _, z in zs do
		beam(gantry, `BeamX{z}`, pos(gx1, gh, z), pos(gx2, gh, z), 0.8, YELLOW)
		if z ~= gz1 then -- vorne würde der untere Riegel durch die Glocke laufen
			beam(gantry, `BeamXLow{z}`, pos(gx1, gh * 0.5, z), pos(gx2, gh * 0.5, z), 0.5, YELLOW)
		end
	end
	for _, x in xs do
		beam(gantry, `BeamZ{x}`, pos(x, gh, gz1), pos(x, gh, gz2), 0.8, YELLOW)
	end
	-- Kreuzverstrebungen auf den Außenseiten (die „gelben Verstrebungen“)
	for i = 1, #zs - 1 do
		for _, x in { gx1, gx2 } do
			beam(gantry, `BraceA{x}_{i}`, pos(x, 0.5, zs[i]), pos(x, gh * 0.5, zs[i + 1]), 0.35, YELLOW)
			beam(gantry, `BraceB{x}_{i}`, pos(x, gh * 0.5, zs[i]), pos(x, 0.5, zs[i + 1]), 0.35, YELLOW)
			beam(gantry, `BraceC{x}_{i}`, pos(x, gh * 0.5, zs[i]), pos(x, gh, zs[i + 1]), 0.35, YELLOW)
			beam(gantry, `BraceD{x}_{i}`, pos(x, gh, zs[i]), pos(x, gh * 0.5, zs[i + 1]), 0.35, YELLOW)
		end
	end
	for i = 1, #xs - 1 do
		beam(gantry, `BraceBackA{i}`, pos(xs[i], 0.5, gz2), pos(xs[i + 1], gh, gz2), 0.35, YELLOW)
		beam(gantry, `BraceBackB{i}`, pos(xs[i], gh, gz2), pos(xs[i + 1], 0.5, gz2), 0.35, YELLOW)
	end
	part(gantry, "Deck", Vector3.new(math.abs(gx2 - gx1), 0.4, gz2 - gz1), at((gx1 + gx2) / 2, gh + 0.6, (gz1 + gz2) / 2), STEEL_LIGHT, Enum.Material.DiamondPlate)
	railing(gantry, "DeckRailFront", pos(gx1, gh + 0.8, gz1), pos(gx2, gh + 0.8, gz1))
	railing(gantry, "DeckRailSide", pos(gx2, gh + 0.8, gz1), pos(gx2, gh + 0.8, gz2 - 12)) -- Lücke hinten fürs Zuführband
	-- Treppe an der linken Seite (zur Hallenmitte)
	local stairs = group(gantry, "Stairs")
	local steps = 14
	for i = 1, steps do
		part(stairs, `Step{i}`, Vector3.new(3, 0.3, 1.4), at(gx2 + 2.4, i * (gh / steps), gz1 + 2 + i * 1.3), STEEL_LIGHT, Enum.Material.DiamondPlate)
	end
	beam(stairs, "Stringer", pos(gx2 + 3.9, 0.5, gz1 + 2), pos(gx2 + 3.9, gh + 0.6, gz1 + 2 + steps * 1.3), 0.4, YELLOW)
	-- Aufgabebehälter (grau) über dem Ofenende, orange Maschinen auf dem Rost
	part(gantry, "FeedBin", Vector3.new(14, 10, 12), at(kilnX, gh + 5.8, backZ - 3), GREY_BOX, Enum.Material.Metal)
	part(gantry, "FeedBinLid", Vector3.new(12, 0.6, 10), at(kilnX, gh + 11.1, backZ - 3), STEEL_DARK, Enum.Material.Metal)
	part(gantry, "FeedChute", Vector3.new(5, gh - kilnY - 6, 5), at(kilnX, kilnY + 6 + (gh - kilnY - 6) / 2, backZ - 3), STEEL, Enum.Material.Metal)
	machine(gantry, "DeckMachineA", at(gx1 + 6, gh + 0.8, gz2 - 6), Vector3.new(6, 4, 5))
	machine(gantry, "DeckMachineB", at((gx1 + gx2) / 2 + 2, gh + 0.8, gz2 - 6), Vector3.new(5, 3.6, 4))

	-- Zuführband vom Eingangslager hoch zum Aufgabebehälter
	local feed = group(model, "FeedConveyor")
	local beltFrom = pos(inputX - 19, 2, inputZ - 6)
	local beltTo = pos(gx2 + 1.5, gh + 1, gz2 - 6)
	local beltLen = (beltTo - beltFrom).Magnitude
	local beltCF = CFrame.lookAt((beltFrom + beltTo) / 2, beltTo)
	part(feed, "Belt", Vector3.new(3, 0.5, beltLen), beltCF, STEEL_DARK, Enum.Material.DiamondPlate)
	for _, sx in { -1, 1 } do
		part(feed, `Side{sx}`, Vector3.new(0.3, 1, beltLen), beltCF * CFrame.new(sx * 1.6, 0.5, 0), YELLOW, Enum.Material.Metal)
	end
	for i = 1, 4 do
		local p = beltFrom:Lerp(beltTo, i / 5)
		local h = p.Y - (plotCFrame.Position.Y + floorY)
		part(feed, `Leg{i}`, Vector3.new(0.5, h, 0.5), CFrame.new(p.X, p.Y - h / 2, p.Z), YELLOW, Enum.Material.Metal)
	end

	-- Abgaskamin am Konus, Rauch nur im Betrieb
	local stackH = LayoutConfig.HallWallHeight - kilnY - 7
	local stack = cylinder(model, "Stack", stackH, 3.2, at(kilnX - 5, kilnY + 5 + stackH / 2, backZ - 47) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
	local smokeAttachment = Instance.new("Attachment")
	smokeAttachment.Name = "SmokeAttachment"
	smokeAttachment.Position = Vector3.new(stackH / 2, 0, 0)
	smokeAttachment.Parent = stack
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(110, 106, 102))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(1, 1.6)
	smoke.Rate = 5
	smoke.Speed = NumberRange.new(2, 3)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Enabled = false
	smoke.Parent = smokeAttachment

	-- Statuslampe an der Spitze
	local lamp = part(model, "StatusLight", Vector3.new(1.2, 1.2, 1.2), at(kilnX + 6, kilnY + 6, frontZ + 3), LAMP_IDLE, Enum.Material.Neon)
	lamp.Shape = Enum.PartType.Ball
	part(model, "StatusLightPost", Vector3.new(0.4, kilnY + 5.4, 0.4), at(kilnX + 6, (kilnY + 5.4) / 2, frontZ + 3), STEEL_DARK)
	local lampLight = Instance.new("PointLight")
	lampLight.Name = "Glow"
	lampLight.Color = LAMP_IDLE
	lampLight.Range = 10
	lampLight.Parent = lamp

	-- Schnecke im offenen gelben Rahmen von der Spitze zum Ausgangslager
	local screw = group(model, "Screw")
	local outputX, outputZ = zRight + 30, zFront + 37
	local sFrom = pos(kilnX, 4, frontZ - 3)
	local sTo = pos(kilnX, 6, outputZ + CrateRackBuilder.Depth / 2 + 2)
	local sLen = (sTo - sFrom).Magnitude
	local sCF = CFrame.lookAt((sFrom + sTo) / 2, sTo)
	local screwSpin = group(screw, "ScrewSpin")
	local core = part(screwSpin, "Core", Vector3.new(1.2, 1.2, sLen), sCF, STEEL_DARK, Enum.Material.Metal)
	core.CanCollide = false
	screwSpin.PrimaryPart = core
	local turns = math.floor(sLen / 1.2)
	for i = 1, turns do
		local flight = part(screwSpin, `Flight{i}`, Vector3.new(4.2, 0.25, 1), sCF * CFrame.new(0, 0, -sLen / 2 + i * 1.2) * CFrame.Angles(0, 0, math.rad(i * 30)), SHELL_LIGHT, Enum.Material.Metal)
		flight.CanCollide = false
	end
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			part(screw, `Rail{sx}_{sy}`, Vector3.new(0.35, 0.35, sLen), sCF * CFrame.new(sx * 2.6, sy * 2.6, 0), YELLOW, Enum.Material.Metal)
		end
	end
	AmbientProps.spin(screwSpin, "Z", 120, true)
	local frames = math.floor(sLen / 5)
	for i = 0, frames do
		local f = sCF * CFrame.new(0, 0, -sLen / 2 + i * (sLen / frames))
		for _, sx in { -1, 1 } do
			part(screw, `Hoop{i}_{sx}`, Vector3.new(0.3, 5.5, 0.3), f * CFrame.new(sx * 2.6, 0, 0), YELLOW, Enum.Material.Metal)
		end
		part(screw, `HoopTop{i}`, Vector3.new(5.5, 0.3, 0.3), f * CFrame.new(0, 2.6, 0), YELLOW, Enum.Material.Metal)
		local legH = f.Position.Y - 2.6 - (plotCFrame.Position.Y + floorY)
		for _, sx in { -1, 1 } do
			part(screw, `Leg{i}_{sx}`, Vector3.new(0.35, legH, 0.35), CFrame.new((f * CFrame.new(sx * 2.6, -2.6 - legH / 2, 0)).Position), YELLOW, Enum.Material.Metal)
		end
	end

	-- Ausgangslager vorne (4 Hochregale, Fächer nach vorne zur Garage)
	store(model, "OutputStore", at(outputX, 0, outputZ), -1, "Bar Output")
	port(model, "ConveyorOutPort", at(outputX + 20, 0.6, outputZ + 8))

	-- Orange Maschinen am Boden (wie im Bild verteilt) mit kleinen Geländern
	local machines = group(model, "Machines")
	machine(machines, "MachineA", at(zLeft - 12, 0, zz + 30) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(6, 5, 5))
	machine(machines, "MachineB", at(zLeft - 12, 0, zz + 6) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(5, 4, 4))
	machine(machines, "MachineC", at(zLeft - 30, 0, zz - 14), Vector3.new(5, 4.5, 4))
	machine(machines, "MachineD", at(zRight + 8, 0, zz - 26) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(4, 4, 4))

	-- Gelbe Rohrleitungen am Boden: von den Tanks (Wand) zum Ofen und zu den Maschinen
	local pipes = group(model, "FloorPipes")
	local py = 1.6
	local route = {
		pos(zRight + 1.5, py, zz + 48), pos(kilnX - 9, py, zz + 48), pos(kilnX - 9, py, zz + 10),
	}
	local route2 = {
		pos(zRight + 1.5, py + 1.2, zz + 14), pos(zRight + 12, py + 1.2, zz + 14), pos(zRight + 12, py + 1.2, zz - 17),
	}
	local route3 = {
		pos(kilnX + 9, py, zz + 50), pos(zLeft - 18, py, zz + 50), pos(zLeft - 18, py, zz + 6),
	}
	for r, points in { route, route2, route3 } do
		for i = 1, #points - 1 do
			pipe(pipes, `Pipe{r}_{i}`, points[i], points[i + 1], 0.9, YELLOW)
		end
		for i, p in points do
			part(pipes, `Support{r}_{i}`, Vector3.new(1.4, p.Y - (plotCFrame.Position.Y + floorY), 1.4), CFrame.new(p.X, (p.Y + plotCFrame.Position.Y + floorY) / 2, p.Z), STEEL_DARK, Enum.Material.Metal)
		end
	end

	-- Kleine Geländer entlang des Ofens (Gehweg-Abgrenzung)
	local rails = group(model, "KilnRailings")
	railing(rails, "RailLeftA", pos(kilnX + 15, 0, backZ - 14), pos(kilnX + 15, 0, backZ - 30))
	railing(rails, "RailLeftB", pos(kilnX + 15, 0, backZ - 38), pos(kilnX + 15, 0, frontZ + 4))
	railing(rails, "RailFront", pos(kilnX + 15, 0, frontZ + 4), pos(kilnX + 8, 0, frontZ + 4))

	-- Kistenpaletten vorne rechts (wie im Bild)
	local pallets = group(model, "CratePallets")
	for i, p in { Vector2.new(zRight + 6, zFront + 8), Vector2.new(zRight + 13, zFront + 8), Vector2.new(zRight + 6, zFront + 15) } do
		cratePallet(pallets, `PalletStack{i}`, at(p.X, 0, p.Y))
	end

	-- Bedienterminal mit schwebender Anzeige (zur Hallenmitte)
	local terminal = group(model, "Terminal")
	local terminalCF = CFrame.lookAt(pos(kilnX + 20, 0, frontZ - 8), pos(0, 0, frontZ - 8))
	part(terminal, "TerminalPost", Vector3.new(1.2, 3.6, 1.2), terminalCF * CFrame.new(0, 1.8, 0), STEEL_DARK)
	local screen = part(terminal, "TerminalScreen", Vector3.new(2.6, 1.8, 0.3), terminalCF * CFrame.new(0, 4.1, 0) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(90, 170, 255), Enum.Material.Neon)
	screen.Transparency = 0.1
	FloatingText.create(terminal, "SmelterDisplay", terminalCF * CFrame.new(0, 8.5, 0), 9, {
		{ Name = "Status", Text = "Idle", Size = 1.6, Color = LAMP_IDLE },
		{ Name = "Input", Text = "", Size = 1.1 },
		{ Name = "Output", Text = "", Size = 1.1 },
	})
	local promptPart = part(terminal, "SmelterTerminalPart", Vector3.new(3, 4, 3), terminalCF * CFrame.new(0, 3, -1.5), STEEL, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SmelterPrompt"
	prompt.ActionText = "Smelter"
	prompt.ObjectText = "Furnace Control"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("SmelterTerminal", true)
	prompt.Parent = promptPart

	-- Trichter über dem Ende der Schnecke (quadratischer Kasten mit Spitzdach wie im Bild)
	local hopper = group(model, "Hopper")
	local hz = zFront + 51
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(hopper, `Leg{sx}_{sz}`, Vector3.new(0.5, 9.2, 0.5), at(kilnX + sx * 4.5, 4.6, hz + sz * 4.5), YELLOW, Enum.Material.Metal)
		end
	end
	part(hopper, "Box", Vector3.new(9.6, 3.2, 9.6), at(kilnX, 9.2 + 1.6, hz), STEEL, Enum.Material.Metal)
	part(hopper, "Roof1", Vector3.new(7.2, 1.2, 7.2), at(kilnX, 9.2 + 3.8, hz), STEEL_LIGHT, Enum.Material.DiamondPlate)
	part(hopper, "Roof2", Vector3.new(4.4, 1, 4.4), at(kilnX, 9.2 + 4.9, hz), STEEL_LIGHT, Enum.Material.DiamondPlate)
	part(hopper, "Roof3", Vector3.new(1.6, 1, 1.6), at(kilnX, 9.2 + 5.9, hz), STEEL_DARK, Enum.Material.Metal)

	-- Schwarze Rippenschläuche (Abluft) links im Ofenbereich, wie im Bild
	hose(model, "HoseA", at, zLeft - 53, zLeft - 13, zz - 40)
	hose(model, "HoseB", at, zLeft - 53, zLeft - 13, zz - 80)

	-- Anlagen mit gelbem Käfig
	local units = group(model, "CagedUnits")
	cagedUnit(units, "UnitA", at(zLeft - 48, 0, zz + 37), Vector3.new(6, 5, 6))
	cagedUnit(units, "UnitB", at(zLeft - 48, 0, zz + 20), Vector3.new(6, 5, 6))
	cagedUnit(units, "UnitC", at(zLeft - 33, 0, zz - 63), Vector3.new(8, 5, 6))
	-- Schaltschränke unter dem Laufrost
	local cabinets = group(model, "DeckCabinets")
	for i, x in { zRight + 9, zRight + 21, zRight + 32 } do
		local c = part(cabinets, `Cabinet{i}`, Vector3.new(6, 7, 4), at(x, 3.5, zBack - 9), ORANGE, Enum.Material.Metal)
		part(cabinets, `CabinetDoor{i}`, Vector3.new(5, 6, 0.15), c.CFrame * CFrame.new(0, 0, -2.07), ORANGE_DARK, Enum.Material.Metal).CanCollide = false
		local led = part(cabinets, `CabinetLed{i}`, Vector3.new(0.4, 0.4, 0.12), c.CFrame * CFrame.new(1.8, 2.4, -2.2), Color3.fromRGB(90, 220, 110), Enum.Material.Neon)
		led.CanCollide = false
	end

	-- Kleine Zäune zur Hallenmitte (mit Durchgang in der Mitte), Poller an Lager und Kistenplatz
	local fences = group(model, "ZoneFences")
	railing(fences, "FenceBack", pos(zLeft - 3, 0, zz + 42), pos(zLeft - 3, 0, zz + 72))
	railing(fences, "FenceFront", pos(zLeft - 3, 0, zFront + 6), pos(zLeft - 3, 0, zz - 58))
	local bollards = group(model, "Bollards")
	for i, p in { Vector2.new(zRight + 10, zFront + 44), Vector2.new(zRight + 10, zFront + 29), Vector2.new(zRight + 50, zFront + 29) } do
		bollard(bollards, `Bollard{i}`, at(p.X, 0, p.Y))
	end

	-- Wand rechts innen: Kabeltrasse, Schaltkästen, Feuerlöscher
	local wall = group(model, "WallDetails")
	local wx = hallRight + 2.8
	part(wall, "CableTray", Vector3.new(1.2, 0.3, zone.Size.Y - 10), at(wx, 14, zz), STEEL_LIGHT, Enum.Material.DiamondPlate)
	part(wall, "Cables", Vector3.new(0.8, 0.4, zone.Size.Y - 10), at(wx, 14.3, zz), BLACK, Enum.Material.Fabric)
	for z = zFront + 13, zBack - 9, 20 do
		part(wall, `TrayBracket{z}`, Vector3.new(2.2, 0.25, 0.4), at(hallRight + 1.9, 13.8, z), STEEL, Enum.Material.Metal)
	end
	for i, z in { zz - 32, zz - 10 } do
		local box = part(wall, `ElectricBox{i}`, Vector3.new(1.2, 6, 4), at(hallRight + 2.6, 4.5, z), Color3.fromRGB(150, 160, 170), Enum.Material.Metal)
		part(wall, `ElectricSign{i}`, Vector3.new(0.12, 0.8, 0.8), box.CFrame * CFrame.new(0.66, 1.8, 0), YELLOW, Enum.Material.SmoothPlastic).CanCollide = false
	end
	for i, z in { zz - 48, zz + 32 } do
		cylinder(wall, `Extinguisher{i}`, 2.2, 0.8, at(hallRight + 1.65, 2.5, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 30, 30), Enum.Material.SmoothPlastic)
		part(wall, `ExtinguisherSign{i}`, Vector3.new(0.12, 1.2, 1.2), at(hallRight + 0.9, 5, z), Color3.fromRGB(200, 30, 30), Enum.Material.SmoothPlastic).CanCollide = false
	end

	-- Leben: Rundumleuchten im Betrieb, Arbeiter auf dem Gehweg, blinkende Kontroll-LEDs
	AmbientProps.beacon(model, "BeaconFeedBin", at(kilnX + 4, gh + 11.4, backZ - 3), true)
	AmbientProps.beacon(model, "BeaconHopper", at(kilnX + 4.3, 12.4, hz - 4.3), true)
	AmbientProps.staffPath(model, "StaffKiln", { pos(kilnX + 24, 0, frontZ - 16), pos(kilnX + 24, 0, frontZ + 20), pos(kilnX + 22, 0, frontZ + 40) })
	AmbientProps.staffPath(model, "StaffOutput", { pos(outputX + 19, 0, outputZ - 11), pos(outputX - 13, 0, outputZ - 11) })
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name:match("Led%d*$") then
			AmbientProps.blink(d)
		end
	end

	-- Zwei Tanks außen an der rechten Hallenwand mit Leitungen in die Halle
	local tankX = hallRight - 20
	for i, tz in { zz + 48, zz + 14 } do
		local tank = group(model, `Tank{i}`)
		local base = at(tankX, -floorY + 1, tz)
		for _, dx in { -6, 6 } do
			for _, dz in { -6, 6 } do
				part(tank, `Leg{dx}_{dz}`, Vector3.new(0.8, 6, 0.8), base * CFrame.new(dx, 3, dz), STEEL, Enum.Material.Metal)
			end
		end
		cylinder(tank, "Body", 28, 18, base * CFrame.new(0, 6 + 14, 0) * CFrame.Angles(0, 0, math.rad(90)), TANK, Enum.Material.Metal)
		local dome = part(tank, "Dome", Vector3.new(18, 7, 18), base * CFrame.new(0, 34, 0), TANK, Enum.Material.Metal)
		dome.Shape = Enum.PartType.Ball
		for _, y in { 12, 20, 28 } do
			cylinder(tank, `Band{y}`, 0.6, 18.4, base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL_LIGHT, Enum.Material.Metal)
		end
		part(tank, "Ladder", Vector3.new(1.4, 30, 0.3), base * CFrame.new(0, 21, -9.2), STEEL_DARK, Enum.Material.DiamondPlate)
		railing(tank, "TopRail", (base * CFrame.new(-6, 37.4, -7)).Position, (base * CFrame.new(6, 37.4, -7)).Position)
		cylinder(tank, "Pipe", 20 - 9, 1.6, base * CFrame.new(9 + (20 - 9) / 2, 18, 0), YELLOW, Enum.Material.Metal)
	end

	return model
end

-- Status und Anzeige setzen (docs/06 §32–33): Grün läuft, Orange wartet, Rot blockiert.
local STATUS_COLORS: { [string]: Color3 } = {
	Running = Color3.fromRGB(110, 220, 120),
	WaitingForInput = LAMP_IDLE,
	Idle = LAMP_IDLE,
	OutputFull = Color3.fromRGB(240, 90, 80),
}
local STATUS_TEXT: { [string]: string } = {
	Running = "Smelting…",
	WaitingForInput = "Waiting for ore",
	Idle = "Idle",
	OutputFull = "Output full",
}

function SmelterTemplate.setStatus(model: Model, status: string, inputText: string, outputText: string)
	local color = STATUS_COLORS[status] or LAMP_IDLE
	local running = status == "Running"
	model:SetAttribute("Running", running)
	local lamp = model:FindFirstChild("StatusLight", true)
	if lamp and lamp:IsA("BasePart") then
		lamp.Color = color
		local l = lamp:FindFirstChild("Glow")
		if l and l:IsA("PointLight") then
			l.Color = color
		end
	end
	local glow = model:FindFirstChild("FurnaceGlow", true)
	if glow and glow:IsA("BasePart") then
		glow.Color = if running then GLOW else GLOW_OFF
		local l = glow:FindFirstChild("Glow")
		if l and l:IsA("PointLight") then
			l.Enabled = running
		end
	end
	local hot = model:FindFirstChild("KilnHotZone", true)
	if hot and hot:IsA("BasePart") then
		hot.Color = if running then HOT_ON else HOT_OFF
		hot.Material = if running then Enum.Material.Neon else Enum.Material.Metal
	end
	for _, d in model:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.Enabled = running
		end
	end
	local display = model:FindFirstChild("SmelterDisplay", true)
	local gui = display and display:FindFirstChild("Display")
	if gui then
		local statusLabel = gui:FindFirstChild("Status")
		if statusLabel and statusLabel:IsA("TextLabel") then
			statusLabel.Text = STATUS_TEXT[status] or status
			statusLabel.TextColor3 = color
		end
		local inputLabel = gui:FindFirstChild("Input")
		if inputLabel and inputLabel:IsA("TextLabel") then
			inputLabel.Text = inputText
		end
		local outputLabel = gui:FindFirstChild("Output")
		if outputLabel and outputLabel:IsA("TextLabel") then
			outputLabel.Text = outputText
		end
	end
end

-- Kisten im Eingangs- und Ausgangslager anzeigen (alle 16 Plätze je Lager sind vorhanden)
function SmelterTemplate.setCrates(model: Model, input: { [string]: number }, output: { [string]: number })
	local cfg = BalanceConfig.Smelter
	for name, items in { InputStore = input, OutputStore = output } do
		local block = model:FindFirstChild(name, true)
		if block then
			CrateRackBuilder.update(block, items, if name == "InputStore" then cfg.InputCrates else cfg.OutputCrates)
		end
	end
end

return table.freeze(SmelterTemplate)
