--!strict
-- Bausteine für eine lebendige Halle (Felix 2026-10-13: „nicht so leer und tot“): Rundumleuchten,
-- Wandlüfter, Laufwege für Arbeiter und Einrichtung (Werkbank, Fässer, Reifen, gewickelte
-- Paletten, Hubwagen, Spinde, Getränkeautomat, Pausentisch …). Jedes Objekt ist ein eigenes
-- Model, damit es in Studio einzeln verschoben werden kann. Bewegung macht der Client
-- (HallAmbienceController) anhand der Tags aus AmbientTags.
--
-- Alle Bauer: (parent, name, cf) mit cf = Mitte auf Bodenhöhe, -Z = Vorderseite.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AmbientTags = require(Shared.Definitions.AmbientTags)

local AmbientProps = {}

local YELLOW = Color3.fromRGB(236, 182, 40)
local ORANGE = Color3.fromRGB(226, 140, 40)
local STEEL = Color3.fromRGB(70, 74, 80)
local STEEL_DARK = Color3.fromRGB(42, 44, 48)
local STEEL_LIGHT = Color3.fromRGB(150, 154, 160)
local WOOD = Color3.fromRGB(150, 106, 64)
local WOOD_DARK = Color3.fromRGB(110, 76, 46)
local CARTON = Color3.fromRGB(196, 150, 96)
local RUBBER = Color3.fromRGB(30, 30, 32)
local RED = Color3.fromRGB(196, 40, 36)
local BLUE = Color3.fromRGB(46, 92, 160)
local GREEN = Color3.fromRGB(60, 140, 80)
local WHITE = Color3.fromRGB(236, 238, 240)
local BEACON = Color3.fromRGB(255, 150, 30)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
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

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Tag-Helfer ---------------------------------------------------------------------------------

function AmbientProps.spin(inst: Instance, axis: string, speed: number, needsRunning: boolean?)
	inst:SetAttribute("SpinAxis", axis)
	inst:SetAttribute("SpinSpeed", speed)
	if needsRunning then
		inst:SetAttribute("NeedsRunning", true)
	end
	CollectionService:AddTag(inst, AmbientTags.Spin)
end

function AmbientProps.shuttle(m: Model, travel: Vector3, speed: number, pause: number)
	m:SetAttribute("Travel", travel)
	m:SetAttribute("Speed", speed)
	m:SetAttribute("Pause", pause)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
		end
	end
	CollectionService:AddTag(m, AmbientTags.Shuttle)
end

function AmbientProps.blink(p: BasePart)
	CollectionService:AddTag(p, AmbientTags.Blink)
end

-- Laufweg für einen Arbeiter: unsichtbare Punkte P1..Pn (Bodenhöhe)
function AmbientProps.staffPath(parent: Instance, name: string, points: { Vector3 }, vest: Color3?)
	local m = model(parent, name)
	for i, p in points do
		local marker = part(m, `P{i}`, Vector3.new(1, 0.2, 1), CFrame.new(p + Vector3.new(0, 0.1, 0)), YELLOW)
		marker.Transparency = 1
		marker.CanCollide = false
		marker.CanQuery = false
	end
	m.PrimaryPart = m:FindFirstChild("P1") :: BasePart
	if vest then
		m:SetAttribute("Vest", vest)
	end
	CollectionService:AddTag(m, AmbientTags.StaffPath)
	return m
end

-- Bewegte/leuchtende Technik ------------------------------------------------------------------

-- Orange Rundumleuchte; dreht im Betrieb (oder immer, wenn needsRunning = false)
function AmbientProps.beacon(parent: Instance, name: string, cf: CFrame, needsRunning: boolean?)
	local m = model(parent, name)
	cylinder(m, "Base", 0.5, 1.4, cf * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL_DARK, Enum.Material.Metal)
	local dome = part(m, "Dome", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 0.9, 0), BEACON, Enum.Material.Neon)
	dome.Shape = Enum.PartType.Ball
	dome.Transparency = 0.15
	dome.CanCollide = false
	local rotor = part(m, "Rotor", Vector3.new(0.2, 0.2, 0.2), cf * CFrame.new(0, 0.9, 0), BEACON)
	rotor.Transparency = 1
	rotor.CanCollide = false
	rotor.CanQuery = false
	local light = Instance.new("SpotLight")
	light.Name = "Beam"
	light.Color = BEACON
	light.Angle = 50
	light.Range = 22
	light.Brightness = 4
	light.Face = Enum.NormalId.Front
	light.Parent = rotor
	AmbientProps.spin(rotor, "Y", 300, needsRunning)
	return m
end

-- Wandlüfter (Rahmen, Gitter, drehender Rotor); cf = Mitte, -Z zeigt in die Halle
function AmbientProps.wallFan(parent: Instance, name: string, cf: CFrame, size: number)
	local m = model(parent, name)
	local h = size / 2
	for _, s in { -1, 1 } do
		part(m, `FrameX{s}`, Vector3.new(size + 0.8, 0.4, 1), cf * CFrame.new(0, s * (h + 0.2), 0), STEEL, Enum.Material.Metal)
		part(m, `FrameY{s}`, Vector3.new(0.4, size, 1), cf * CFrame.new(s * (h + 0.2), 0, 0), STEEL, Enum.Material.Metal)
	end
	part(m, "Back", Vector3.new(size, size, 0.2), cf * CFrame.new(0, 0, 0.4), STEEL_DARK, Enum.Material.Metal)
	for i = -2, 2 do
		part(m, `Grill{i}`, Vector3.new(size, 0.12, 0.12), cf * CFrame.new(0, i * size / 5, -0.55), STEEL_LIGHT, Enum.Material.Metal).CanCollide = false
	end
	local rotor = model(m, "Rotor")
	local hub = cylinder(rotor, "Hub", 0.6, size * 0.18, cf * CFrame.new(0, 0, -0.1) * CFrame.Angles(0, math.rad(90), 0), STEEL_DARK, Enum.Material.Metal)
	for i = 0, 3 do
		local blade = part(rotor, `Blade{i}`, Vector3.new(size * 0.42, size * 0.13, 0.12), cf * CFrame.new(0, 0, -0.1) * CFrame.Angles(0, 0, math.rad(i * 90)) * CFrame.new(size * 0.22, 0, 0) * CFrame.Angles(math.rad(20), 0, 0), STEEL_LIGHT, Enum.Material.Metal)
		blade.CanCollide = false
	end
	hub.CanCollide = false
	rotor.PrimaryPart = hub
	-- Hub ist ein Zylinder (Achse = lokales X des Hubs) → um X drehen
	AmbientProps.spin(rotor, "X", 240)
	return m
end

-- Einrichtung --------------------------------------------------------------------------------

function AmbientProps.workbench(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	part(m, "Top", Vector3.new(8, 0.4, 3), cf * CFrame.new(0, 3.4, 0), WOOD, Enum.Material.WoodPlanks)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(m, `Leg{sx}_{sz}`, Vector3.new(0.3, 3.2, 0.3), cf * CFrame.new(sx * 3.7, 1.6, sz * 1.3), STEEL, Enum.Material.Metal)
		end
	end
	part(m, "Shelf", Vector3.new(7.6, 0.2, 2.6), cf * CFrame.new(0, 1, 0), STEEL_LIGHT, Enum.Material.Metal)
	part(m, "Board", Vector3.new(8, 4, 0.2), cf * CFrame.new(0, 6, 1.4), Color3.fromRGB(70, 96, 140), Enum.Material.SmoothPlastic)
	part(m, "Vice", Vector3.new(0.8, 0.8, 1), cf * CFrame.new(-3, 4, -0.6), STEEL_DARK, Enum.Material.Metal)
	part(m, "Toolbox", Vector3.new(1.8, 0.9, 0.9), cf * CFrame.new(2, 4.05, 0.2), RED, Enum.Material.Metal)
	for i, x in { -2.6, -1.6, -0.4, 0.8, 2.2 } do
		part(m, `Tool{i}`, Vector3.new(0.25, 1.2 + (i % 2) * 0.5, 0.12), cf * CFrame.new(x, 6, 1.24), STEEL_LIGHT, Enum.Material.Metal).CanCollide = false
	end
	local lamp = part(m, "Lamp", Vector3.new(3, 0.25, 0.6), cf * CFrame.new(0, 8.2, 1.1), WHITE, Enum.Material.Neon)
	lamp.CanCollide = false
	return m
end

function AmbientProps.drums(parent: Instance, name: string, cf: CFrame, count: number)
	local m = model(parent, name)
	part(m, "SpillTray", Vector3.new(5.6, 0.5, 5.6), cf * CFrame.new(0, 0.25, 0), YELLOW, Enum.Material.Metal)
	local colors = { BLUE, RED, BLUE, GREEN }
	for i = 1, math.min(count, 4) do
		local ox = if i % 2 == 1 then -1.35 else 1.35
		local oz = if i <= 2 then -1.35 else 1.35
		local drum = cylinder(m, `Drum{i}`, 3.4, 2.4, cf * CFrame.new(ox, 0.5 + 1.7, oz) * CFrame.Angles(0, 0, math.rad(90)), colors[i], Enum.Material.Metal)
		for _, y in { -1, 1 } do
			cylinder(m, `Ring{i}_{y}`, 0.15, 2.5, drum.CFrame * CFrame.new(y * 1.1, 0, 0), STEEL_DARK, Enum.Material.Metal)
		end
	end
	return m
end

function AmbientProps.tireStack(parent: Instance, name: string, cf: CFrame, count: number)
	local m = model(parent, name)
	for i = 1, count do
		-- leicht versetzt und mit Felge sichtbar, damit der Stapel nicht wie ein Fass aussieht
		local c = cf * CFrame.new(math.sin(i * 2.1) * 0.25, 0.55 + (i - 1) * 1.15, math.cos(i * 1.7) * 0.25)
		cylinder(m, `Tire{i}`, 1.05, 3.6, c * CFrame.Angles(0, 0, math.rad(90)), RUBBER, Enum.Material.Rubber)
		cylinder(m, `Rim{i}`, 1.1, 1.9, c * CFrame.Angles(0, 0, math.rad(90)), STEEL_LIGHT, Enum.Material.Metal).CanCollide = false
	end
	return m
end

-- Palette mit Kartons, optional stretch-gewickelt
function AmbientProps.cartonPallet(parent: Instance, name: string, cf: CFrame, layers: number, wrapped: boolean)
	local m = model(parent, name)
	part(m, "Pallet", Vector3.new(5, 0.6, 5), cf * CFrame.new(0, 0.3, 0), WOOD_DARK, Enum.Material.WoodPlanks)
	for l = 1, layers do
		for ix = -1, 1, 2 do
			for iz = -1, 1, 2 do
				part(m, `Box{l}_{ix}_{iz}`, Vector3.new(2.3, 1.5, 2.3), cf * CFrame.new(ix * 1.2, 0.6 + (l - 0.5) * 1.5, iz * 1.2), CARTON, Enum.Material.Cardboard)
			end
		end
	end
	if wrapped then
		local wrap = part(m, "Wrap", Vector3.new(4.9, layers * 1.5 + 0.1, 4.9), cf * CFrame.new(0, 0.6 + layers * 0.75, 0), WHITE, Enum.Material.Glass)
		wrap.Transparency = 0.6
		wrap.CanCollide = false
	end
	return m
end

-- Gabelhubwagen nach Felix' Vorlage (2026-10-15): gelbes Gestell mit hohem Rahmen und dreieckigen
-- Seitenblechen, zwei Gabeln mit schrägen Spitzen, Rollenfenstern und Tandem-Lastrollen, großes
-- schwarzes Lenkrad, Hydraulikpumpe mit Feder, schwarze Vierkant-Deichsel mit Rohrschlaufe und Hebel.
-- Gabeln zeigen nach -Z, Deichsel hinten (+Z).
function AmbientProps.palletTruck(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	local PAINT = Color3.fromRGB(240, 172, 20)
	local BLACK = Color3.fromRGB(24, 24, 26)
	local function wedge(n: string, size: Vector3, wcf: CFrame, color: Color3)
		local w = Instance.new("WedgePart")
		w.Name = n
		w.Anchored = true
		w.CanTouch = false
		w.Size = size
		w.CFrame = wcf
		w.Color = color
		w.Material = Enum.Material.SmoothPlastic
		w.Parent = m
	end
	-- Gabeln mit schrägen Spitzen, Rollenfenstern und Tandemrollen
	local forkLen, forkY = 4.6, 0.33
	for _, sx in { -1, 1 } do
		local x = sx * 0.85
		part(m, `Fork{sx}`, Vector3.new(0.75, 0.35, forkLen), cf * CFrame.new(x, forkY, -0.7), PAINT, Enum.Material.SmoothPlastic)
		wedge(`ForkTip{sx}`, Vector3.new(0.75, 0.35, 0.55), cf * CFrame.new(x, forkY, -0.7 - forkLen / 2 - 0.275), PAINT)
		part(m, `RollerWindow{sx}`, Vector3.new(0.45, 0.03, 0.75), cf * CFrame.new(x, forkY + 0.18, -2.35), BLACK, Enum.Material.SmoothPlastic).CanCollide = false
		for k, z in { -2.55, -2.15 } do
			cylinder(m, `LoadRoller{sx}_{k}`, 0.3, 0.3, cf * CFrame.new(x, 0.15, z), BLACK, Enum.Material.Rubber).CanCollide = false
		end
		part(m, `PushRod{sx}`, Vector3.new(0.1, 0.1, 3.4), cf * CFrame.new(x, 0.2, -0.5), STEEL_DARK, Enum.Material.Metal).CanCollide = false
	end
	-- Querträger, hoher Rahmen, dreieckige Seitenbleche, Bolzen
	part(m, "CrossMember", Vector3.new(2.45, 0.35, 0.6), cf * CFrame.new(0, forkY, 1.85), PAINT, Enum.Material.SmoothPlastic)
	part(m, "Frame", Vector3.new(2.45, 0.8, 0.5), cf * CFrame.new(0, 0.9, 2.35), PAINT, Enum.Material.SmoothPlastic)
	part(m, "FrameTop", Vector3.new(1.3, 0.12, 0.55), cf * CFrame.new(0, 1.36, 2.35), PAINT, Enum.Material.SmoothPlastic)
	for _, sx in { -1, 1 } do
		wedge(`Gusset{sx}`, Vector3.new(0.7, 0.8, 1.5), cf * CFrame.new(sx * 0.85, 0.9, 1.35), PAINT)
		cylinder(m, `Pin{sx}`, 0.06, 0.18, cf * CFrame.new(sx * 1.25, 0.45, 1.95), STEEL_DARK, Enum.Material.Metal).CanCollide = false
	end
	-- Lenkrad mit Gabel, Hydraulikpumpe mit Feder
	cylinder(m, "SteerWheel", 0.35, 0.95, cf * CFrame.new(0, 0.48, 2.95), BLACK, Enum.Material.Rubber)
	cylinder(m, "SteerHub", 0.4, 0.35, cf * CFrame.new(0, 0.48, 2.95), STEEL_LIGHT, Enum.Material.Metal)
	for _, sx in { -1, 1 } do
		part(m, `WheelFork{sx}`, Vector3.new(0.08, 0.9, 0.5), cf * CFrame.new(sx * 0.24, 0.8, 2.95), BLACK, Enum.Material.Metal)
	end
	local pump = cylinder(m, "Pump", 0.9, 0.5, cf * CFrame.new(0, 1.65, 2.9) * CFrame.Angles(0, 0, math.rad(90)), BLACK, Enum.Material.Metal)
	pump.CanCollide = false
	for k = 0, 3 do
		cylinder(m, `Spring{k}`, 0.05, 0.62, cf * CFrame.new(0, 1.3 + k * 0.22, 2.9) * CFrame.Angles(0, 0, math.rad(90)), STEEL_LIGHT, Enum.Material.Metal).CanCollide = false
	end
	cylinder(m, "PumpCap", 0.12, 0.6, cf * CFrame.new(0, 2.14, 2.9) * CFrame.Angles(0, 0, math.rad(90)), BLACK, Enum.Material.Metal).CanCollide = false
	local function cylinderBetween(parent: Instance, n: string, wa: Vector3, wb: Vector3, d: number, color: Color3): Part
		local p = part(parent, n, Vector3.new((wb - wa).Magnitude, d, d), CFrame.lookAt((wa + wb) / 2, wb) * CFrame.Angles(0, math.rad(90), 0), color, Enum.Material.Metal)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	-- Deichsel und Griff exakt nach Felix' Detailfoto (2026-10-15):
	--   * Deichsel: schwarzes Vierkantrohr, läuft gerade durch die Mitte der Schlaufe bis zum oberen
	--     Bogen und ist dort verschweißt
	--   * Schlaufe: dickes rundes Rohr, breiter ovaler Bügel (≈ 1,6 × so breit wie hoch), oben
	--     gleichmäßig rund, links schräg nach unten zur Deichsel, rechts unten waagrecht hinein
	--   * innen rechts ein flacher Hebel mit Fingerrillen aus einem Schlitz der Deichsel, kleine
	--     Feder darüber; gelber Warnaufkleber vorne auf der Deichsel
	local d0, d1 = Vector3.new(0, 2.15, 2.95), Vector3.new(0, 3.75, 3.4)
	local dir = (d1 - d0).Unit
	local normal = Vector3.xAxis:Cross(dir).Unit -- Vorderseite (zum Bediener)
	local function loopPoint(u: number, v: number): Vector3
		return d1 + Vector3.xAxis * u + dir * v
	end
	local function box(n: string, a: Vector3, b: Vector3, width: number, thick: number, color: Color3, material: Enum.Material?): Part
		local wa, wb = cf:PointToWorldSpace(a), cf:PointToWorldSpace(b)
		local up = cf:VectorToWorldSpace(normal)
		local p = part(m, n, Vector3.new(width, thick, (wb - wa).Magnitude), CFrame.lookAt((wa + wb) / 2, wb, up), color, material or Enum.Material.Metal)
		p.CanCollide = false
		return p
	end
	local TUBE = 0.13
	-- Mittellinie der Schlaufe direkt aus dem Foto (Pixel, Deichselmitte x = 710, rechter Anschluss
	-- y = 850), geglättet mit Catmull-Rom-Kurve → viele kurze Segmente ohne Kanten
	local PX, SV = 0.00194, 0.9
	local photo = {
		{ 785, 850 }, { 950, 845 }, { 1080, 830 }, { 1180, 790 }, { 1235, 700 }, { 1250, 560 },
		{ 1230, 420 }, { 1170, 300 }, { 1060, 210 }, { 900, 150 }, { 710, 125 }, { 560, 130 },
		{ 430, 150 }, { 330, 195 }, { 275, 270 }, { 280, 360 }, { 320, 440 }, { 420, 560 },
		{ 520, 680 }, { 610, 770 }, { 670, 820 },
	}
	local function fromPhoto(x: number, y: number): Vector3
		return loopPoint((x - 710) * PX, 0.35 + (850 - y) * PX * SV)
	end
	local ctrl = {}
	for _, xy in photo do
		table.insert(ctrl, fromPhoto(xy[1], xy[2]))
	end
	local points = {}
	for i = 1, #ctrl - 1 do
		local p0, p1, p2, p3 = ctrl[math.max(1, i - 1)], ctrl[i], ctrl[i + 1], ctrl[math.min(#ctrl, i + 2)]
		for k = 0, 2 do
			local t = k / 3
			local t2, t3 = t * t, t * t * t
			table.insert(points, 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
		end
	end
	table.insert(points, ctrl[#ctrl])
	table.insert(points, 1, loopPoint(0.1, 0.35)) -- Anschluss rechts unten an der Deichsel
	table.insert(points, loopPoint(0.08, 0.35 + 30 * PX * SV)) -- Anschluss links unten an der Deichsel
	for i = 1, #points - 1 do
		local p, q = points[i], points[i + 1]
		local wa, wb = cf:PointToWorldSpace(p), cf:PointToWorldSpace(q)
		local seg = cylinderBetween(m, `Loop{i}`, wa, wb, TUBE, BLACK)
		seg.CanCollide = false
		local joint = part(m, `LoopJoint{i}`, Vector3.new(TUBE, TUBE, TUBE), CFrame.new(wa), BLACK, Enum.Material.Metal)
		joint.Shape = Enum.PartType.Ball
		joint.CanCollide = false
	end
	-- Vierkant-Deichsel bis zum oberen Bogen, kleine Schweißnaht oben
	local topV = 0.35 + (850 - 125) * PX * SV
	box("Drawbar", d0, loopPoint(0, topV), 0.26, 0.26, BLACK)
	box("WeldTop", loopPoint(0, topV - 0.02), loopPoint(0, topV + 0.04), 0.3, 0.28, Color3.fromRGB(44, 44, 48))
	-- Schlitz rechts in der Deichsel, Feder darüber, flacher Hebel mit Fingerrillen (Unterkante)
	local function pv(x: number, y: number): (number, number)
		return (x - 710) * PX, 0.35 + (850 - y) * PX * SV
	end
	local _, sv0 = pv(790, 545)
	local _, sv1 = pv(790, 345)
	box("LeverSlot", loopPoint(0.132, sv0), loopPoint(0.132, sv1), 0.02, 0.14, Color3.fromRGB(10, 10, 12))
	local lever = Color3.fromRGB(52, 54, 58)
	local la, lb, lc, ld = Vector3.new(pv(790, 430)), Vector3.new(pv(930, 462)), Vector3.new(pv(1010, 495)), Vector3.new(pv(1065, 535))
	box("Lever", loopPoint(0.12, la.Y), loopPoint(lb.X, lb.Y), 0.2, 0.08, lever)
	box("LeverMid", loopPoint(lb.X - 0.01, lb.Y), loopPoint(lc.X, lc.Y), 0.18, 0.08, lever)
	box("LeverTip", loopPoint(lc.X - 0.01, lc.Y), loopPoint(ld.X, ld.Y), 0.15, 0.08, lever)
	for k = 0, 3 do
		local gu, gv = pv(835 + k * 30, 470 + k * 6)
		local g = part(m, `FingerGroove{k}`, Vector3.new(0.05, 0.05, 0.1), cf * CFrame.new(loopPoint(gu, gv)), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
		g.Shape = Enum.PartType.Ball
		g.CanCollide = false
	end
	local _, spring0 = pv(775, 395)
	for k = 0, 4 do
		local at = loopPoint(0.15, spring0 + k * 0.03)
		local coil = part(m, `Spring{k}`, Vector3.new(0.025, 0.08, 0.08), cf * CFrame.lookAt(at, at + dir) * CFrame.Angles(0, math.rad(90), 0), STEEL_LIGHT, Enum.Material.Metal)
		coil.Shape = Enum.PartType.Cylinder
		coil.CanCollide = false
	end
	-- gelber Warnaufkleber vorne auf der Deichsel (Höhe wie im Foto)
	local _, st0 = pv(0, 555)
	local _, st1 = pv(0, 365)
	box("WarningSticker", loopPoint(0, st0) + normal * 0.135, loopPoint(0, st1) + normal * 0.135, 0.2, 0.01, Color3.fromRGB(240, 200, 40), Enum.Material.SmoothPlastic)
	return m
end

function AmbientProps.lockers(parent: Instance, name: string, cf: CFrame, count: number)
	local m = model(parent, name)
	for i = 1, count do
		local x = (i - (count + 1) / 2) * 2.1
		local body = part(m, `Locker{i}`, Vector3.new(2, 6.5, 2), cf * CFrame.new(x, 3.25, 0), Color3.fromRGB(80, 110, 150), Enum.Material.Metal)
		part(m, `Vent{i}`, Vector3.new(1.2, 0.6, 0.1), body.CFrame * CFrame.new(0, 2.4, -1.02), STEEL_DARK, Enum.Material.Metal).CanCollide = false
		part(m, `Handle{i}`, Vector3.new(0.15, 0.6, 0.12), body.CFrame * CFrame.new(0.6, 0, -1.05), STEEL_LIGHT, Enum.Material.Metal).CanCollide = false
	end
	return m
end

function AmbientProps.vending(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	part(m, "Body", Vector3.new(3.4, 6.6, 2.6), cf * CFrame.new(0, 3.3, 0), RED, Enum.Material.SmoothPlastic)
	local glass = part(m, "Window", Vector3.new(2.2, 4.2, 0.1), cf * CFrame.new(-0.4, 3.9, -1.32), Color3.fromRGB(180, 220, 255), Enum.Material.Neon)
	glass.Transparency = 0.35
	glass.CanCollide = false
	for row = 0, 3 do
		for col = 0, 2 do
			part(m, `Can{row}_{col}`, Vector3.new(0.4, 0.6, 0.1), cf * CFrame.new(-1.1 + col * 0.7, 2.4 + row * 1, -1.38), if (row + col) % 2 == 0 then YELLOW else GREEN).CanCollide = false
		end
	end
	part(m, "Panel", Vector3.new(0.6, 1.6, 0.1), cf * CFrame.new(1.2, 4, -1.32), STEEL_DARK).CanCollide = false
	return m
end

function AmbientProps.waterCooler(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	part(m, "Body", Vector3.new(1.4, 3.2, 1.4), cf * CFrame.new(0, 1.6, 0), WHITE)
	local bottle = cylinder(m, "Bottle", 1.8, 1.2, cf * CFrame.new(0, 4.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 180, 240), Enum.Material.Glass)
	bottle.Transparency = 0.3
	part(m, "Tap", Vector3.new(0.3, 0.3, 0.3), cf * CFrame.new(0, 2.4, -0.8), BLUE).CanCollide = false
	return m
end

-- Pausentisch mit Hockern, Kaffeetasse
function AmbientProps.breakTable(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	part(m, "Top", Vector3.new(6, 0.3, 3.4), cf * CFrame.new(0, 3, 0), WHITE)
	for _, sx in { -1, 1 } do
		part(m, `Leg{sx}`, Vector3.new(0.3, 2.85, 2.6), cf * CFrame.new(sx * 2.6, 1.45, 0), STEEL_LIGHT, Enum.Material.Metal)
		for _, sz in { -1, 1 } do
			cylinder(m, `Stool{sx}_{sz}`, 0.3, 1.4, cf * CFrame.new(sx * 1.5, 1.9, sz * 2.6) * CFrame.Angles(0, 0, math.rad(90)), BLUE)
			part(m, `StoolLeg{sx}_{sz}`, Vector3.new(0.25, 1.75, 0.25), cf * CFrame.new(sx * 1.5, 0.9, sz * 2.6), STEEL, Enum.Material.Metal)
		end
	end
	cylinder(m, "Mug", 0.5, 0.45, cf * CFrame.new(1, 3.4, -0.4) * CFrame.Angles(0, 0, math.rad(90)), WHITE).CanCollide = false
	part(m, "Newspaper", Vector3.new(1.4, 0.05, 1), cf * CFrame.new(-1.2, 3.18, 0.3) * CFrame.Angles(0, math.rad(12), 0), Color3.fromRGB(220, 220, 210)).CanCollide = false
	return m
end

-- Niedriges Lagerregal mit Kartons
function AmbientProps.partsShelf(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(m, `Post{sx}_{sz}`, Vector3.new(0.3, 7, 0.3), cf * CFrame.new(sx * 4.8, 3.5, sz * 1.3), BLUE, Enum.Material.Metal)
		end
	end
	for level, y in { 0.4, 2.6, 4.8, 6.9 } do
		part(m, `Board{level}`, Vector3.new(9.6, 0.2, 2.8), cf * CFrame.new(0, y, 0), STEEL_LIGHT, Enum.Material.Metal)
		if level < 4 then
			for i = 0, 3 do
				local w = 1.6 + (i + level) % 2 * 0.5
				part(m, `Box{level}_{i}`, Vector3.new(w, 1.3, 1.8), cf * CFrame.new(-3.6 + i * 2.4, y + 0.75, 0), if (i + level) % 3 == 0 then BLUE else CARTON, Enum.Material.Cardboard)
			end
		end
	end
	return m
end

function AmbientProps.cones(parent: Instance, name: string, cf: CFrame, count: number, spacing: number)
	local m = model(parent, name)
	for i = 1, count do
		local c = cf * CFrame.new((i - (count + 1) / 2) * spacing, 0, 0)
		part(m, `ConeBase{i}`, Vector3.new(1.4, 0.2, 1.4), c * CFrame.new(0, 0.1, 0), ORANGE)
		local cone = cylinder(m, `Cone{i}`, 2, 0.8, c * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), ORANGE)
		cylinder(m, `ConeBand{i}`, 0.35, 0.85, cone.CFrame, WHITE).CanCollide = false
	end
	return m
end

return table.freeze(AmbientProps)
