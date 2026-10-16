--!strict
-- Schmelze rechts in der Halle, nach FACTORY_MASTERPLAN_TOPDOWN.png (Phase 13b-4/5, Felix D-037,
-- 2026-10-13 „1:1 wie im Bild“):
--   * hinten ein gelbes Stahlgerüst mit Kreuzverstrebungen, Laufrost, Geländer, Treppe; darauf
--     orange Maschinen und der graue Aufgabebehälter über dem Ofenende
--   * Eingangslager hinten links: 4 Hochregale × 4 Paletten (16 Kisten Erz)
--   * Drehrohrofen in Längsrichtung aus Abschnitten (Glocke, Hals, Trommel, Konus) mit Laufringen,
--     Tragrollen, Zahnkranz und Antrieb; vorne die glühende Spitze (Glut, Funken, Rauch nur im Betrieb)
--   * dahinter die Kühlstation und ein Rollenförderband mit Verteilband bis ins Ausgangslager
--     (4 Hochregale, 16 Kisten)
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

-- Sammlung mehrerer Einzelobjekte: Folder (in Studio wählt ein Klick das einzelne Objekt)
local function collection(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
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
local function store(parent: Instance, name: string, origin: CFrame, face: number, title: string): Folder
	local block = collection(parent, name)
	CrateRackBuilder.build(block, origin, { { Z = 0, Face = face } }, 4)
	FloatingText.title(block, `{name}Label`, origin * CFrame.new(0, 34, face * (CrateRackBuilder.Depth / 2 + 1)), title, 2.4, YELLOW)
	return block
end

-- Barrenstrecke vom Ofen zum Ausgangslager (Felix 2026-10-16): direkt hinter der Ofenspitze eine
-- Kühlstation (Kühlband im Gehäuse, Barren sichtbar von glühend nach stahlgrau, Lüfter mit Dampf,
-- Sprühleitungen, Wassertank, Schaltkasten), danach ein Rollenförderband geradeaus bis hinter das
-- Ausgangslager und dort ein Verteilband entlang der Regalrückseiten mit Abschiebern und Rutschen
-- in jedes Regal. Reine Optik; jedes Teil ist ein eigenes Model im Folder "BarLine".
-- rackXs = X-Mitten der Regale (lokal zur Plotmitte), rackBackZ = Z der Regalrückseite.
function SmelterTemplate.buildBarLine(parent: Instance, plotCFrame: CFrame, kilnX: number, tipZ: number, rackXs: { number }, rackBackZ: number): Folder
	local floorY = LayoutConfig.HallFloorTop
	local function at(x: number, y: number, z: number): CFrame
		return plotCFrame * CFrame.new(x, floorY + y, z)
	end
	local line = Instance.new("Folder")
	line.Name = "BarLine"
	line.Parent = parent
	local HOT = Color3.fromRGB(255, 120, 30)
	local COOL = Color3.fromRGB(150, 154, 160)
	local WATER = Color3.fromRGB(60, 120, 200)
	local beltY = 2.2 -- Oberkante der Rollen
	local function bar(m: Instance, name: string, cf: CFrame, color: Color3, hot: boolean)
		local b = part(m, name, Vector3.new(1.5, 0.45, 0.7), cf, color, if hot then Enum.Material.Neon else Enum.Material.Metal)
		b.CanCollide = false
	end

	-- Rollenförderband zwischen zwei Punkten auf einer Achse (X oder Z)
	local function rollerConveyor(name: string, a: Vector2, b: Vector2, withBars: boolean): Model
		local m = group(line, name)
		local dir = Vector3.new(b.X - a.X, 0, b.Y - a.Y)
		local len = dir.Magnitude
		local mid = Vector2.new((a.X + b.X) / 2, (a.Y + b.Y) / 2)
		local worldDir = plotCFrame:VectorToWorldSpace(dir.Unit)
		local base = CFrame.lookAt(at(mid.X, 0, mid.Y).Position, at(mid.X, 0, mid.Y).Position + worldDir, plotCFrame.UpVector)
		for _, sx in { -1, 1 } do
			part(m, `SideFrame{sx}`, Vector3.new(0.3, 0.6, len), base * CFrame.new(sx * 1.6, beltY - 0.35, 0), STEEL_DARK, Enum.Material.Metal)
			part(m, `Guide{sx}`, Vector3.new(0.15, 0.15, len), base * CFrame.new(sx * 1.7, beltY + 0.45, 0), YELLOW, Enum.Material.Metal)
		end
		local rollers = math.floor(len / 1.1)
		for i = 0, rollers do
			local z = -len / 2 + 0.3 + i * ((len - 0.6) / rollers)
			local r = part(m, `Roller{i}`, Vector3.new(3.1, 0.4, 0.4), base * CFrame.new(0, beltY - 0.2, z), STEEL_LIGHT, Enum.Material.Metal)
			r.Shape = Enum.PartType.Cylinder
		end
		local legs = math.max(1, math.floor(len / 4))
		for i = 0, legs do
			local z = -len / 2 + 0.4 + i * ((len - 0.8) / legs)
			for _, sx in { -1, 1 } do
				part(m, `Leg{i}_{sx}`, Vector3.new(0.3, beltY - 0.65, 0.3), base * CFrame.new(sx * 1.45, (beltY - 0.65) / 2, z), YELLOW, Enum.Material.Metal)
			end
			part(m, `LegTie{i}`, Vector3.new(2.9, 0.2, 0.2), base * CFrame.new(0, 0.5, z), YELLOW, Enum.Material.Metal)
		end
		if withBars then
			for i = 1, math.floor(len / 5) do
				bar(m, `Bar{i}`, base * CFrame.new(0, beltY + 0.23, -len / 2 + i * 5 - 2), COOL, false)
			end
		end
		return m
	end

	-- Kühlstation direkt hinter der Ofenspitze
	local z1 = tipZ - 1.4
	local z0 = z1 - 11
	local zc = (z0 + z1) / 2
	local cool = group(line, "CoolingStation")
	local W, Hh = 9, 5
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(cool, `Leg{sx}_{sz}`, Vector3.new(0.5, 1, 0.5), at(kilnX + sx * (W / 2 - 0.3), 0.5, zc + sz * 5.2), YELLOW, Enum.Material.Metal)
		end
		-- Seitenwände mit Sichtfenster und Rippen
		part(cool, `WallLow{sx}`, Vector3.new(0.3, 1.6, 11), at(kilnX + sx * W / 2, 1.8, zc), GREY_BOX, Enum.Material.Metal)
		part(cool, `WallHigh{sx}`, Vector3.new(0.3, 1.6, 11), at(kilnX + sx * W / 2, 5.2, zc), GREY_BOX, Enum.Material.Metal)
		local glass = part(cool, `Window{sx}`, Vector3.new(0.12, 1.8, 11), at(kilnX + sx * W / 2, 3.5, zc), Color3.fromRGB(60, 70, 80), Enum.Material.Glass)
		glass.Transparency = 0.45
		for i = 0, 7 do
			part(cool, `Rib{sx}_{i}`, Vector3.new(0.18, Hh, 0.18), at(kilnX + sx * (W / 2 + 0.12), 1 + Hh / 2, z0 + 0.2 + i * 1.51), STEEL_DARK, Enum.Material.Metal)
		end
	end
	part(cool, "Floor", Vector3.new(W, 0.3, 11), at(kilnX, 1.15, zc), STEEL_DARK, Enum.Material.DiamondPlate)
	part(cool, "Roof", Vector3.new(W + 0.4, 0.35, 11.4), at(kilnX, 1 + Hh + 0.17, zc), GREY_BOX, Enum.Material.Metal)
	part(cool, "InletWall", Vector3.new(W, Hh, 0.3), at(kilnX, 1 + Hh / 2, z1 - 0.15), GREY_BOX, Enum.Material.Metal)
	part(cool, "OutletHood", Vector3.new(W, 1.6, 0.3), at(kilnX, 1 + Hh - 0.8, z0 + 0.15), GREY_BOX, Enum.Material.Metal)
	part(cool, "CoolBelt", Vector3.new(3.4, 0.2, 11), at(kilnX, beltY - 0.1, zc), Color3.fromRGB(34, 36, 40), Enum.Material.DiamondPlate)
	-- Barren im Kühlband: vom Eingang (glühend) zum Ausgang (abgekühlt)
	for i = 0, 6 do
		local f = i / 6
		bar(cool, `CoolingBar{i}`, at(kilnX, beltY + 0.23, z1 - 1 - i * 1.5), HOT:Lerp(COOL, f), f < 0.5)
	end
	local heat = Instance.new("PointLight")
	heat.Name = "Heat"
	heat.Color = HOT
	heat.Range = 10
	heat.Brightness = 1.2
	heat.Parent = cool:FindFirstChild("CoolingBar0")
	-- Einlaufrutsche von der glühenden Ofenspitze in die Kühlstation
	local chuteTop, chuteBottom = at(kilnX, 8.2, tipZ - 0.6).Position, at(kilnX, 1 + Hh + 0.4, z1 - 1.2).Position
	local chuteLen = (chuteTop - chuteBottom).Magnitude
	local chuteCF = CFrame.lookAt((chuteTop + chuteBottom) / 2, chuteBottom)
	part(cool, "InletChute", Vector3.new(2.4, 0.25, chuteLen), chuteCF, STEEL_DARK, Enum.Material.Metal)
	part(cool, "InletGlow", Vector3.new(1.6, 0.05, chuteLen - 0.4), chuteCF * CFrame.new(0, 0.15, 0), HOT, Enum.Material.Neon).CanCollide = false
	for _, sx in { -1, 1 } do
		part(cool, `InletSide{sx}`, Vector3.new(0.2, 0.8, chuteLen), chuteCF * CFrame.new(sx * 1.2, 0.35, 0), STEEL, Enum.Material.Metal)
	end
	-- Lüfter mit drehendem Rotor und Dampf, Sprühleitungen, Wassertank, Schaltkasten
	for i, z in { zc + 2.6, zc - 2.6 } do
		local roofY = 1 + Hh + 0.35
		cylinder(cool, `FanHousing{i}`, 1.2, 2.8, at(kilnX, roofY + 0.6, z) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
		local rotor = group(cool, `FanRotor{i}`)
		local hub = part(rotor, "Hub", Vector3.new(0.6, 0.3, 0.6), at(kilnX, roofY + 1.3, z), STEEL_DARK, Enum.Material.Metal)
		rotor.PrimaryPart = hub
		for k = 0, 3 do
			part(rotor, `Blade{k}`, Vector3.new(1.1, 0.08, 0.4), at(kilnX, roofY + 1.3, z) * CFrame.Angles(0, math.rad(k * 90), 0) * CFrame.new(0.65, 0, 0) * CFrame.Angles(math.rad(18), 0, 0), STEEL_LIGHT, Enum.Material.Metal).CanCollide = false
		end
		AmbientProps.spin(rotor, "Y", 320)
		local steamAt = Instance.new("Attachment")
		steamAt.Name = "Steam"
		steamAt.Parent = hub
		local steam = Instance.new("ParticleEmitter")
		steam.Name = "Steam"
		steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		steam.Color = ColorSequence.new(Color3.fromRGB(235, 238, 240))
		steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 3.2) })
		steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
		steam.Lifetime = NumberRange.new(1.2, 2)
		steam.Rate = 6
		steam.Speed = NumberRange.new(2.5, 4)
		steam.EmissionDirection = Enum.NormalId.Top
		steam.Parent = steamAt
	end
	for _, sx in { -1, 1 } do
		cylinder(cool, `SprayPipe{sx}`, 10.4, 0.35, at(kilnX + sx * (W / 2 - 0.8), 1 + Hh + 0.6, zc) * CFrame.Angles(0, math.rad(90), 0), WATER, Enum.Material.Metal)
		for k = 0, 4 do
			part(cool, `Nozzle{sx}_{k}`, Vector3.new(0.2, 0.3, 0.2), at(kilnX + sx * (W / 2 - 0.8), 1 + Hh + 0.3, z0 + 1.2 + k * 2.2), STEEL_DARK, Enum.Material.Metal).CanCollide = false
		end
	end
	local tankX = kilnX + W / 2 + 1.8
	cylinder(cool, "WaterTank", 3.4, 2.4, at(tankX, 1.7, z0 + 2) * CFrame.Angles(0, 0, math.rad(90)), WATER, Enum.Material.SmoothPlastic)
	cylinder(cool, "WaterTankCap", 0.2, 2.5, at(tankX, 3.5, z0 + 2) * CFrame.Angles(0, 0, math.rad(90)), STEEL_DARK, Enum.Material.Metal)
	part(cool, "WaterRiser", Vector3.new(0.3, Hh - 1.2, 0.3), at(tankX, 3.5 + (Hh - 1.2) / 2, z0 + 2), WATER, Enum.Material.Metal)
	part(cool, "WaterFeed", Vector3.new(tankX - (kilnX + W / 2 - 0.8), 0.3, 0.3), at((tankX + kilnX + W / 2 - 0.8) / 2, 1 + Hh + 0.6, z0 + 2), WATER, Enum.Material.Metal)
	local box = part(cool, "ControlBox", Vector3.new(0.8, 1.6, 1.4), at(tankX - 0.6, 2.2, z1 - 2.5), ORANGE, Enum.Material.Metal)
	local led = part(cool, "Led", Vector3.new(0.12, 0.25, 0.25), box.CFrame * CFrame.new(0.45, 0.4, 0), Color3.fromRGB(90, 220, 110), Enum.Material.Neon)
	led.CanCollide = false
	AmbientProps.blink(led)
	FloatingText.title(cool, "CoolingLabel", at(kilnX, 10.5, zc), "Cooling", 1.8, YELLOW)

	-- Förderband geradeaus bis hinter das Ausgangslager
	local crossZ = rackBackZ + 2.6
	rollerConveyor("BarConveyor", Vector2.new(kilnX, z0 - 0.1), Vector2.new(kilnX, crossZ + 1.7), true)
	-- Verteilband entlang der Regalrückseiten, Abschieber und Rutschen in jedes Regal
	local minX, maxX = math.huge, -math.huge
	for _, x in rackXs do
		minX = math.min(minX, x)
		maxX = math.max(maxX, x)
	end
	rollerConveyor("DistributionConveyor", Vector2.new(maxX + 4.7, crossZ), Vector2.new(minX - 4.7, crossZ), true)
	for i, x0 in rackXs do
		-- nicht genau auf die Einmündung des Hauptbands setzen
		local x = if math.abs(x0 - kilnX) < 2.5 then x0 + (if x0 >= kilnX then 2.6 else -2.6) else x0
		local pusher = group(line, `Pusher{i}`)
		part(pusher, "Body", Vector3.new(1.8, 1.4, 1.2), at(x, beltY + 0.4, crossZ + 2.5), GREY_BOX, Enum.Material.Metal)
		cylinder(pusher, "Rod", 1.2, 0.3, at(x, beltY + 0.4, crossZ + 1.5) * CFrame.Angles(0, math.rad(90), 0), YELLOW, Enum.Material.Metal).CanCollide = false
		part(pusher, "Plate", Vector3.new(1.6, 0.6, 0.12), at(x, beltY + 0.4, crossZ + 0.9), STEEL_DARK, Enum.Material.Metal).CanCollide = false
		part(pusher, "Stand", Vector3.new(0.4, beltY - 0.3, 0.4), at(x, (beltY - 0.3) / 2, crossZ + 2.5), YELLOW, Enum.Material.Metal)
		local chute = group(line, `RackChute{i}`)
		local c0, c1 = at(x, beltY - 0.1, crossZ - 1.6).Position, at(x, 1.1, rackBackZ + 0.15).Position
		local cl = (c1 - c0).Magnitude
		local ccf = CFrame.lookAt((c0 + c1) / 2, c1)
		part(chute, "Slide", Vector3.new(2.2, 0.15, cl), ccf, STEEL_LIGHT, Enum.Material.DiamondPlate)
		for _, sx in { -1, 1 } do
			part(chute, `Side{sx}`, Vector3.new(0.12, 0.4, cl), ccf * CFrame.new(sx * 1.1, 0.2, 0), YELLOW, Enum.Material.Metal)
		end
	end
	return line
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
	local statusLamp = group(model, "StatusLamp")
	local lamp = part(statusLamp, "StatusLight", Vector3.new(1.2, 1.2, 1.2), at(kilnX + 6, kilnY + 6, frontZ + 3), LAMP_IDLE, Enum.Material.Neon)
	lamp.Shape = Enum.PartType.Ball
	part(statusLamp, "StatusLightPost", Vector3.new(0.4, kilnY + 5.4, 0.4), at(kilnX + 6, (kilnY + 5.4) / 2, frontZ + 3), STEEL_DARK)
	local lampLight = Instance.new("PointLight")
	lampLight.Name = "Glow"
	lampLight.Color = LAMP_IDLE
	lampLight.Range = 10
	lampLight.Parent = lamp

	-- Barrenstrecke: Kühlstation hinter der Ofenspitze, Förderband zum Ausgangslager, Verteilband
	local outputX, outputZ = zRight + 30, zFront + 37
	SmelterTemplate.buildBarLine(model, plotCFrame, kilnX, frontZ - 1.2, { outputX + 13.5, outputX + 4.5, outputX - 4.5, outputX - 13.5 }, outputZ + CrateRackBuilder.Depth / 2)

	-- Ausgangslager vorne (4 Hochregale, Fächer nach vorne zur Garage)
	store(model, "OutputStore", at(outputX, 0, outputZ), -1, "Bar Output")
	port(model, "ConveyorOutPort", at(outputX + 20, 0.6, outputZ + 8))

	-- Orange Maschinen am Boden (wie im Bild verteilt) mit kleinen Geländern
	local machines = collection(model, "Machines")
	machine(machines, "MachineA", at(zLeft - 12, 0, zz + 30) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(6, 5, 5))
	machine(machines, "MachineB", at(zLeft - 12, 0, zz + 6) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(5, 4, 4))
	machine(machines, "MachineC", at(zLeft - 30, 0, zz - 14), Vector3.new(5, 4.5, 4))
	machine(machines, "MachineD", at(zRight + 8, 0, zz - 26) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(4, 4, 4))

	-- Gelbe Rohrleitungen am Boden: von den Tanks (Wand) zum Ofen und zu den Maschinen
	local pipes = collection(model, "FloorPipes")
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
		local routeModel = group(pipes, `PipeRoute{r}`)
		for i = 1, #points - 1 do
			pipe(routeModel, `Pipe{r}_{i}`, points[i], points[i + 1], 0.9, YELLOW)
		end
		for i, p in points do
			part(routeModel, `Support{r}_{i}`, Vector3.new(1.4, p.Y - (plotCFrame.Position.Y + floorY), 1.4), CFrame.new(p.X, (p.Y + plotCFrame.Position.Y + floorY) / 2, p.Z), STEEL_DARK, Enum.Material.Metal)
		end
	end

	-- Kleine Geländer entlang des Ofens (Gehweg-Abgrenzung)
	local rails = collection(model, "KilnRailings")
	railing(rails, "RailLeftA", pos(kilnX + 15, 0, backZ - 14), pos(kilnX + 15, 0, backZ - 30))
	railing(rails, "RailLeftB", pos(kilnX + 15, 0, backZ - 38), pos(kilnX + 15, 0, frontZ + 4))
	railing(rails, "RailFront", pos(kilnX + 15, 0, frontZ + 4), pos(kilnX + 8, 0, frontZ + 4))

	-- Kistenpaletten vorne rechts (wie im Bild)
	local pallets = collection(model, "CratePallets")
	for i, p in { Vector2.new(zRight + 6, zFront + 8), Vector2.new(zRight + 13, zFront + 8), Vector2.new(zRight + 6, zFront + 15) } do
		cratePallet(pallets, `PalletStack{i}`, at(p.X, 0, p.Y))
	end

	-- Bedienpult (Felix 2026-10-15: wie ein mobiles Steuerpult, schwarz mit gelben Elementen):
	-- fahrbarer Fuß mit Lenkrollen und großen Hinterrädern, geneigter Korpus mit eingelassener
	-- Frontplatte, schräges Bedienfeld mit Joysticks, Not-Aus, Leuchttastern und Display, seitlicher
	-- Griff, Monitor am Mast. Vorderseite (Bediener) = lokal -Z, zur Hallenmitte.
	local terminal = group(model, "Terminal")
	local c = CFrame.lookAt(pos(kilnX + 20, 0, frontZ - 8), pos(0, 0, frontZ - 8))
	local BODY = Color3.fromRGB(26, 27, 30)
	local PANEL = Color3.fromRGB(46, 48, 54)
	local RUBBER = Color3.fromRGB(18, 18, 20)
	local function wedge(name: string, size: Vector3, cf: CFrame, color: Color3): WedgePart
		local w = Instance.new("WedgePart")
		w.Name = name
		w.Anchored = true
		w.CanTouch = false
		w.Size = size
		w.CFrame = cf
		w.Color = color
		w.Material = Enum.Material.SmoothPlastic
		w.Parent = terminal
		return w
	end
	-- Fuß: Sockel, abgeschrägte Front, gelbe Kante, Schriftzug an den Seiten
	local baseBlock = part(terminal, "Base", Vector3.new(3.4, 0.7, 3.4), c * CFrame.new(0, 0.75, 0.4), BODY, Enum.Material.SmoothPlastic)
	wedge("BaseNose", Vector3.new(3.4, 0.7, 0.9), c * CFrame.new(0, 0.75, -1.75), BODY)
	for _, sx in { -1, 1 } do
		part(terminal, `BaseTrimX{sx}`, Vector3.new(0.16, 0.12, 3.46), c * CFrame.new(sx * 1.65, 1.12, 0.4), YELLOW, Enum.Material.SmoothPlastic)
		part(terminal, `BaseTrimZ{sx}`, Vector3.new(3.46, 0.12, 0.16), c * CFrame.new(0, 1.12, 0.4 + sx * 1.65), YELLOW, Enum.Material.SmoothPlastic)
	end
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = 1
		gui.Parent = baseBlock
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = YELLOW
		label.Text = "SMELTER"
		label.Parent = gui
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0.18, 0)
		pad.PaddingBottom = UDim.new(0.18, 0)
		pad.PaddingLeft = UDim.new(0.15, 0)
		pad.PaddingRight = UDim.new(0.15, 0)
		pad.Parent = label
	end
	-- Lenkrollen vorne (Gabel + Rad), große Räder hinten
	for _, sx in { -1, 1 } do
		part(terminal, `CasterFork{sx}`, Vector3.new(0.18, 0.25, 0.4), c * CFrame.new(sx * 1.25, 0.28, -1.3), STEEL, Enum.Material.Metal)
		cylinder(terminal, `CasterWheel{sx}`, 0.2, 0.4, c * CFrame.new(sx * 1.25, 0.2, -1.3), RUBBER, Enum.Material.Rubber)
		cylinder(terminal, `RearWheel{sx}`, 0.32, 0.9, c * CFrame.new(sx * 1.88, 0.45, 1.6), RUBBER, Enum.Material.Rubber)
		cylinder(terminal, `RearHub{sx}`, 0.36, 0.4, c * CFrame.new(sx * 1.88, 0.45, 1.6), YELLOW, Enum.Material.Metal)
	end
	-- Korpus, leicht nach hinten geneigt, mit eingelassener Frontplatte und gelben Kanten
	local bodyCF = c * CFrame.new(0, 2.65, 0.55) * CFrame.Angles(math.rad(6), 0, 0)
	part(terminal, "Body", Vector3.new(2.3, 3.1, 1.5), bodyCF, BODY, Enum.Material.SmoothPlastic)
	part(terminal, "FrontRecess", Vector3.new(1.5, 1.9, 0.08), bodyCF * CFrame.new(0, -0.25, -0.77), PANEL, Enum.Material.SmoothPlastic)
	part(terminal, "RecessFrameTop", Vector3.new(1.7, 0.1, 0.1), bodyCF * CFrame.new(0, 0.75, -0.78), YELLOW, Enum.Material.SmoothPlastic)
	for _, sx in { -1, 1 } do
		part(terminal, `BodyEdge{sx}`, Vector3.new(0.12, 3.1, 0.12), bodyCF * CFrame.new(sx * 1.12, 0, -0.72), YELLOW, Enum.Material.SmoothPlastic)
		part(terminal, `Vent{sx}`, Vector3.new(0.06, 0.8, 0.8), bodyCF * CFrame.new(sx * 1.17, 0.6, 0.2), PANEL, Enum.Material.DiamondPlate)
	end
	-- Pultkopf mit schrägem Bedienfeld
	local headCF = c * CFrame.new(0, 4.55, 0.1) * CFrame.Angles(math.rad(-16), 0, 0)
	part(terminal, "Head", Vector3.new(3.2, 0.9, 2.2), headCF, BODY, Enum.Material.SmoothPlastic)
	part(terminal, "ControlPlate", Vector3.new(2.9, 0.06, 1.9), headCF * CFrame.new(0, 0.48, 0), PANEL, Enum.Material.SmoothPlastic)
	part(terminal, "FrontLip", Vector3.new(3.3, 0.3, 0.35), headCF * CFrame.new(0, 0.12, -1.2), YELLOW, Enum.Material.SmoothPlastic)
	part(terminal, "ArmPad", Vector3.new(3.1, 0.2, 0.45), headCF * CFrame.new(0, -0.1, -1.55), RUBBER, Enum.Material.Rubber)
	local top = headCF * CFrame.new(0, 0.51, 0)
	-- vier Joysticks (Gummimanschette, Hebel, gelber Knauf)
	for i, x in { -1.2, -0.85, -0.5, -0.15 } do
		cylinder(terminal, `JoyBoot{i}`, 0.16, 0.36, top * CFrame.new(x, 0.08, 0.05) * CFrame.Angles(0, 0, math.rad(90)), RUBBER, Enum.Material.Rubber)
		part(terminal, `JoyStick{i}`, Vector3.new(0.12, 0.6, 0.12), top * CFrame.new(x, 0.45, 0.05) * CFrame.Angles(math.rad(if i % 2 == 0 then 8 else -6), 0, 0), RUBBER, Enum.Material.SmoothPlastic).CanCollide = false
		local knob = part(terminal, `JoyKnob{i}`, Vector3.new(0.22, 0.3, 0.22), top * CFrame.new(x, 0.85, 0.05 + (if i % 2 == 0 then 0.06 else -0.05)), YELLOW, Enum.Material.SmoothPlastic)
		knob.CanCollide = false
	end
	-- Not-Aus (roter Pilz auf gelbem Ring), Leuchttaster, kleines Display
	cylinder(terminal, "EStopCollar", 0.08, 0.6, top * CFrame.new(0.75, 0.04, -0.1) * CFrame.Angles(0, 0, math.rad(90)), YELLOW, Enum.Material.SmoothPlastic)
	cylinder(terminal, "EStop", 0.22, 0.42, top * CFrame.new(0.75, 0.18, -0.1) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 30, 30), Enum.Material.SmoothPlastic)
	for i, b in { { 1.15, -0.25, YELLOW }, { 1.15, 0.15, Color3.fromRGB(70, 210, 90) }, { 0.75, 0.35, Color3.fromRGB(210, 30, 30) } } do
		local btn = cylinder(terminal, `Button{i}`, 0.1, 0.24, top * CFrame.new(b[1] :: number, 0.05, b[2] :: number) * CFrame.Angles(0, 0, math.rad(90)), b[3] :: Color3, Enum.Material.Neon)
		btn.CanCollide = false
	end
	local lcd = part(terminal, "MiniDisplay", Vector3.new(0.8, 0.04, 0.45), top * CFrame.new(1.0, 0.03, 0.62), Color3.fromRGB(90, 200, 255), Enum.Material.Neon)
	lcd.CanCollide = false
	local led = part(terminal, "Led", Vector3.new(0.12, 0.05, 0.12), top * CFrame.new(-1.3, 0.03, 0.75), Color3.fromRGB(90, 220, 110), Enum.Material.Neon)
	led.CanCollide = false
	AmbientProps.blink(led)
	-- Griff an der Seite (schwarz, gelbe Griffzone)
	local hx = -1.85
	for i, y in { 0.35, -0.55 } do
		part(terminal, `HandleArm{i}`, Vector3.new(0.5, 0.18, 0.18), headCF * CFrame.new(hx + 0.2, y, -0.3), BODY, Enum.Material.SmoothPlastic)
	end
	part(terminal, "HandleBar", Vector3.new(0.22, 1.2, 0.22), headCF * CFrame.new(hx - 0.05, -0.1, -0.3), BODY, Enum.Material.SmoothPlastic)
	part(terminal, "HandleGrip", Vector3.new(0.26, 0.6, 0.26), headCF * CFrame.new(hx - 0.05, -0.1, -0.3), YELLOW, Enum.Material.Rubber)
	-- Monitor am Mast
	local mastBase = (headCF * CFrame.new(0, 0.45, 0.85)).Position
	local monitorCF = c * CFrame.new(0, 6.55, 0.85) * CFrame.Angles(math.rad(-6), 0, 0)
	local mastTop = (monitorCF * CFrame.new(0, -0.6, 0.25)).Position
	local mast = part(terminal, "MonitorMast", Vector3.new(0.34, (mastTop - mastBase).Magnitude, 0.34), CFrame.lookAt((mastBase + mastTop) / 2, mastTop) * CFrame.Angles(math.rad(90), 0, 0), BODY, Enum.Material.Metal)
	mast.CanCollide = false
	part(terminal, "MastCollar", Vector3.new(0.5, 0.2, 0.5), CFrame.new(mastBase + Vector3.new(0, 0.1, 0)), YELLOW, Enum.Material.SmoothPlastic)
	part(terminal, "MonitorFrame", Vector3.new(3, 1.9, 0.25), monitorCF, BODY, Enum.Material.SmoothPlastic)
	part(terminal, "MonitorTrim", Vector3.new(3, 0.1, 0.27), monitorCF * CFrame.new(0, -0.98, 0), YELLOW, Enum.Material.SmoothPlastic)
	local screen = part(terminal, "TerminalScreen", Vector3.new(2.7, 1.6, 0.06), monitorCF * CFrame.new(0, 0.02, -0.14), Color3.fromRGB(14, 20, 28), Enum.Material.SmoothPlastic)
	screen.CanCollide = false
	-- Bildschirm: Ofen-Bedienoberfläche (Titel, Temperatur- und Durchsatzbalken, Kennzahlen)
	local ui = Instance.new("SurfaceGui")
	ui.Name = "ScreenUI"
	ui.Face = Enum.NormalId.Front
	ui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	ui.PixelsPerStud = 120
	ui.LightInfluence = 0
	ui.Brightness = 1.4
	ui.Parent = screen
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(16, 24, 34)
	bg.BorderSizePixel = 0
	bg.Parent = ui
	local function label(text: string, y: number, h: number, color: Color3, xAlign: Enum.TextXAlignment?)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0.06, y)
		t.Size = UDim2.fromScale(0.88, h)
		t.Font = Enum.Font.GothamBold
		t.TextScaled = true
		t.TextColor3 = color
		t.TextXAlignment = xAlign or Enum.TextXAlignment.Left
		t.Text = text
		t.Parent = bg
	end
	local function bar(y: number, fill: number, color: Color3)
		local track = Instance.new("Frame")
		track.Position = UDim2.fromScale(0.06, y)
		track.Size = UDim2.fromScale(0.88, 0.09)
		track.BackgroundColor3 = Color3.fromRGB(40, 50, 64)
		track.BorderSizePixel = 0
		track.Parent = bg
		local f = Instance.new("Frame")
		f.Size = UDim2.fromScale(fill, 1)
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Parent = track
	end
	local header = Instance.new("Frame")
	header.Size = UDim2.fromScale(1, 0.16)
	header.BackgroundColor3 = YELLOW
	header.BorderSizePixel = 0
	header.Parent = bg
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(26, 27, 30)
	title.Text = "  FURNACE CONTROL"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	label("Kiln temperature", 0.22, 0.1, Color3.fromRGB(200, 208, 220))
	bar(0.34, 0.78, Color3.fromRGB(255, 130, 40))
	label("Throughput", 0.48, 0.1, Color3.fromRGB(200, 208, 220))
	bar(0.6, 0.55, Color3.fromRGB(80, 200, 110))
	label("Drum  3.2 rpm    Feed  ON    Gas  OK", 0.76, 0.12, Color3.fromRGB(150, 200, 255))
	-- Kabel vom Pult zum Ofen
	part(terminal, "CableDrop", Vector3.new(0.22, 0.6, 0.22), c * CFrame.new(0, 0.7, 2.15), RUBBER, Enum.Material.Rubber)
	part(terminal, "CableFloor", Vector3.new(0.22, 0.18, 1.6), c * CFrame.new(0, 0.09, 2.95), RUBBER, Enum.Material.Rubber).CanCollide = false
	FloatingText.create(terminal, "SmelterDisplay", c * CFrame.new(0, 9, 0), 9, {
		{ Name = "Status", Text = "Idle", Size = 1.6, Color = LAMP_IDLE },
		{ Name = "Input", Text = "", Size = 1.1 },
		{ Name = "Output", Text = "", Size = 1.1 },
	})
	local promptPart = part(terminal, "SmelterTerminalPart", Vector3.new(3, 4, 3), c * CFrame.new(0, 3, -1.5), STEEL, Enum.Material.SmoothPlastic)
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

	-- Schwarze Rippenschläuche (Abluft) links im Ofenbereich, wie im Bild
	hose(model, "HoseA", at, zLeft - 53, zLeft - 13, zz - 40)
	hose(model, "HoseB", at, zLeft - 53, zLeft - 13, zz - 80)

	-- Anlagen mit gelbem Käfig
	local units = collection(model, "CagedUnits")
	cagedUnit(units, "UnitA", at(zLeft - 48, 0, zz + 37), Vector3.new(6, 5, 6))
	cagedUnit(units, "UnitB", at(zLeft - 48, 0, zz + 20), Vector3.new(6, 5, 6))
	cagedUnit(units, "UnitC", at(zLeft - 33, 0, zz - 63), Vector3.new(8, 5, 6))
	-- Schaltschränke unter dem Laufrost
	local cabinets = collection(model, "DeckCabinets")
	for i, x in { zRight + 9, zRight + 21, zRight + 32 } do
		local cab = group(cabinets, `Cabinet{i}`)
		local c = part(cab, "Body", Vector3.new(6, 7, 4), at(x, 3.5, zBack - 9), ORANGE, Enum.Material.Metal)
		part(cab, `CabinetDoor{i}`, Vector3.new(5, 6, 0.15), c.CFrame * CFrame.new(0, 0, -2.07), ORANGE_DARK, Enum.Material.Metal).CanCollide = false
		local led = part(cab, `CabinetLed{i}`, Vector3.new(0.4, 0.4, 0.12), c.CFrame * CFrame.new(1.8, 2.4, -2.2), Color3.fromRGB(90, 220, 110), Enum.Material.Neon)
		led.CanCollide = false
	end

	-- Kleine Zäune zur Hallenmitte (mit Durchgang in der Mitte), Poller an Lager und Kistenplatz
	local fences = collection(model, "ZoneFences")
	railing(fences, "FenceBack", pos(zLeft - 3, 0, zz + 42), pos(zLeft - 3, 0, zz + 72))
	railing(fences, "FenceFront", pos(zLeft - 3, 0, zFront + 6), pos(zLeft - 3, 0, zz - 58))
	local bollards = collection(model, "Bollards")
	for i, p in { Vector2.new(zRight + 10, zFront + 44), Vector2.new(zRight + 10, zFront + 29), Vector2.new(zRight + 50, zFront + 29) } do
		bollard(bollards, `Bollard{i}`, at(p.X, 0, p.Y))
	end

	-- Wand rechts innen: Kabeltrasse, Schaltkästen, Feuerlöscher
	local wall = collection(model, "WallDetails")
	local wx = hallRight + 2.8
	local tray = group(wall, "CableTray")
	part(tray, "Tray", Vector3.new(1.2, 0.3, zone.Size.Y - 10), at(wx, 14, zz), STEEL_LIGHT, Enum.Material.DiamondPlate)
	part(tray, "Cables", Vector3.new(0.8, 0.4, zone.Size.Y - 10), at(wx, 14.3, zz), BLACK, Enum.Material.Fabric)
	for z = zFront + 13, zBack - 9, 20 do
		part(tray, `TrayBracket{z}`, Vector3.new(2.2, 0.25, 0.4), at(hallRight + 1.9, 13.8, z), STEEL, Enum.Material.Metal)
	end
	for i, z in { zz - 32, zz - 10 } do
		local eb = group(wall, `ElectricBox{i}`)
		local box = part(eb, "Box", Vector3.new(1.2, 6, 4), at(hallRight + 2.6, 4.5, z), Color3.fromRGB(150, 160, 170), Enum.Material.Metal)
		part(eb, "Sign", Vector3.new(0.12, 0.8, 0.8), box.CFrame * CFrame.new(0.66, 1.8, 0), YELLOW, Enum.Material.SmoothPlastic).CanCollide = false
	end
	for i, z in { zz - 48, zz + 32 } do
		local ex = group(wall, `Extinguisher{i}`)
		cylinder(ex, "Body", 2.2, 0.8, at(hallRight + 1.65, 2.5, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 30, 30), Enum.Material.SmoothPlastic)
		part(ex, "Sign", Vector3.new(0.12, 1.2, 1.2), at(hallRight + 0.9, 5, z), Color3.fromRGB(200, 30, 30), Enum.Material.SmoothPlastic).CanCollide = false
	end

	-- Leben: Rundumleuchten im Betrieb, Arbeiter auf dem Gehweg, blinkende Kontroll-LEDs
	AmbientProps.beacon(model, "BeaconFeedBin", at(kilnX + 4, gh + 11.4, backZ - 3), true)
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
