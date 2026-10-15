--!strict
-- Realistischer Gabelstapler (Felix 2026-10-13: „sehr realistisch, etwas größer als der in der
-- Halle“). Frontstapler mit Gasflasche: Fahrgestell, Gegengewicht, große Vorder- und kleine
-- Hinterräder mit Felgen, Fahrerschutzdach auf vier Pfosten, Sitz, Lenkrad, Hebel, Duplex-Mast
-- mit Ketten und Hubzylinder, Neigezylinder, Gabelträger mit Lastschutzgitter, zwei Gabeln,
-- Scheinwerfer, Rückleuchten, Warnleuchte (ohne Fahrer, Felix 2026-10-15) und optional eine Holzkiste auf den Gabeln.
--
-- build(parent, name, cf, withLoad?): cf = Mitte unter dem Fahrzeug auf Bodenhöhe, Gabeln
-- zeigen nach -Z. PrimaryPart = "Chassis".

local WoodCrate = require(script.Parent.WoodCrate)

local ForkliftBuilder = {}

local YELLOW = Color3.fromRGB(242, 178, 22)
local YELLOW_DARK = Color3.fromRGB(206, 146, 14)
local CHASSIS = Color3.fromRGB(46, 48, 52)
local STEEL = Color3.fromRGB(70, 74, 80)
local STEEL_LIGHT = Color3.fromRGB(150, 154, 160)
local TIRE = Color3.fromRGB(28, 28, 30)
local RIM = Color3.fromRGB(196, 198, 200)
local SEAT = Color3.fromRGB(34, 34, 36)
local TANK = Color3.fromRGB(226, 228, 230)

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

-- Stab zwischen zwei Punkten (lokal zu cf)
local function rod(parent: Instance, name: string, cf: CFrame, a: Vector3, b: Vector3, thickness: number, color: Color3, material: Enum.Material?): Part
	local wa, wb = cf:PointToWorldSpace(a), cf:PointToWorldSpace(b)
	return part(parent, name, Vector3.new(thickness, thickness, (wb - wa).Magnitude), CFrame.lookAt((wa + wb) / 2, wb), color, material)
end

-- Rad (Achse = X) mit Reifen, Felge und Nabe
local function wheel(parent: Instance, name: string, cf: CFrame, diameter: number, width: number, side: number)
	local tire = cylinder(parent, name, width, diameter, cf, TIRE, Enum.Material.Rubber)
	tire.CanCollide = false
	cylinder(parent, name .. "Rim", width + 0.04, diameter * 0.55, cf, RIM, Enum.Material.Metal).CanCollide = false
	cylinder(parent, name .. "Hub", width + 0.12, diameter * 0.2, cf * CFrame.new(side * 0.02, 0, 0), STEEL, Enum.Material.Metal).CanCollide = false
	for i = 0, 4 do
		local a = math.rad(i * 72)
		cylinder(parent, `{name}Nut{i}`, 0.1, 0.12, cf * CFrame.new(side * (width / 2 + 0.06), math.cos(a) * diameter * 0.17, math.sin(a) * diameter * 0.17), STEEL_LIGHT, Enum.Material.Metal).CanCollide = false
	end
end

function ForkliftBuilder.build(parent: Instance, name: string, cf: CFrame, withLoad: boolean?): Model
	local m = Instance.new("Model")
	m.Name = name

	-- Fahrgestell, Karosserie, Gegengewicht
	local chassis = part(m, "Chassis", Vector3.new(4.2, 1.2, 6.4), cf * CFrame.new(0, 1.3, 0.6), CHASSIS, Enum.Material.Metal)
	part(m, "Body", Vector3.new(4.6, 1.8, 4.6), cf * CFrame.new(0, 2.7, 0.9), YELLOW, Enum.Material.SmoothPlastic)
	part(m, "Hood", Vector3.new(3.8, 0.35, 2.8), cf * CFrame.new(0, 3.75, 1.5), YELLOW_DARK, Enum.Material.SmoothPlastic)
	part(m, "Floorplate", Vector3.new(3.6, 0.2, 1.6), cf * CFrame.new(0, 3.7, -0.75), CHASSIS, Enum.Material.DiamondPlate)
	part(m, "Counterweight", Vector3.new(4.8, 2.6, 1.6), cf * CFrame.new(0, 2.3, 3.9), YELLOW, Enum.Material.SmoothPlastic)
	cylinder(m, "CounterweightTop", 4.8, 1.6, cf * CFrame.new(0, 3.6, 3.9), YELLOW, Enum.Material.SmoothPlastic)
	part(m, "Bumper", Vector3.new(4.9, 0.6, 0.4), cf * CFrame.new(0, 1.4, 4.8), CHASSIS, Enum.Material.Metal)
	part(m, "TowPin", Vector3.new(0.6, 0.6, 0.6), cf * CFrame.new(0, 1.4, 5.1), STEEL, Enum.Material.Metal)
	for _, sx in { -1, 1 } do
		part(m, `Fender{sx}`, Vector3.new(0.9, 0.25, 3), cf * CFrame.new(sx * 2.05, 2.85, -1.45), YELLOW_DARK, Enum.Material.SmoothPlastic)
		part(m, `Step{sx}`, Vector3.new(0.5, 0.18, 1.4), cf * CFrame.new(sx * 2.45, 1.4, 0.1), STEEL_LIGHT, Enum.Material.DiamondPlate)
		part(m, `TailLight{sx}`, Vector3.new(0.6, 0.35, 0.08), cf * CFrame.new(sx * 1.8, 3.1, 4.74), Color3.fromRGB(220, 30, 30), Enum.Material.Neon).CanCollide = false
		part(m, `Stripe{sx}`, Vector3.new(0.05, 0.25, 4.2), cf * CFrame.new(sx * 2.31, 2.5, 0.9), CHASSIS, Enum.Material.SmoothPlastic).CanCollide = false
	end

	-- Räder: vorne groß (unter dem Mast), hinten klein (unter dem Gegengewicht)
	for _, sx in { -1, 1 } do
		wheel(m, `FrontWheel{sx}`, cf * CFrame.new(sx * 1.85, 1.35, -1.45), 2.7, 1.0, sx)
		wheel(m, `RearWheel{sx}`, cf * CFrame.new(sx * 1.75, 1.0, 3.0), 2.0, 0.8, sx)
	end

	-- Fahrerplatz: Sitz, Lenksäule mit Lenkrad, Armaturen, Hebel
	part(m, "SeatBase", Vector3.new(2, 0.5, 1.8), cf * CFrame.new(0, 4.15, 1.5), SEAT, Enum.Material.Fabric)
	part(m, "SeatBack", Vector3.new(2, 1.9, 0.45), cf * CFrame.new(0, 5.2, 2.45) * CFrame.Angles(math.rad(-10), 0, 0), SEAT, Enum.Material.Fabric)
	part(m, "Dashboard", Vector3.new(3.4, 1.1, 0.9), cf * CFrame.new(0, 4.25, -1.25), CHASSIS, Enum.Material.SmoothPlastic)
	part(m, "Display", Vector3.new(0.9, 0.5, 0.06), cf * CFrame.new(-0.9, 4.65, -0.78) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(80, 170, 240), Enum.Material.Neon).CanCollide = false
	rod(m, "SteeringColumn", cf, Vector3.new(0, 4.4, -1.0), Vector3.new(0, 5.4, -0.45), 0.25, CHASSIS, Enum.Material.Metal)
	cylinder(m, "SteeringWheel", 0.14, 1.5, cf * CFrame.new(0, 5.45, -0.42) * CFrame.Angles(math.rad(-55), 0, 0) * CFrame.Angles(0, 0, math.rad(90)), SEAT, Enum.Material.Rubber).CanCollide = false
	for i, x in { 0.75, 1.05, 1.35 } do
		rod(m, `Lever{i}`, cf, Vector3.new(x, 4.6, -0.9), Vector3.new(x, 5.5, -0.75), 0.1, STEEL_LIGHT, Enum.Material.Metal).CanCollide = false
		local knob = part(m, `LeverKnob{i}`, Vector3.new(0.28, 0.28, 0.28), cf * CFrame.new(x, 5.55, -0.74), SEAT, Enum.Material.Rubber)
		knob.Shape = Enum.PartType.Ball
		knob.CanCollide = false
	end

	-- Gasflasche hinten auf dem Gegengewicht
	cylinder(m, "GasTank", 3.4, 1.3, cf * CFrame.new(0, 5.15, 3.65), TANK, Enum.Material.Metal)
	for _, sx in { -1, 1 } do
		part(m, `TankStrap{sx}`, Vector3.new(0.15, 1.4, 1.4), cf * CFrame.new(sx * 1.1, 5.15, 3.65), STEEL, Enum.Material.Metal).CanCollide = false
	end
	cylinder(m, "TankValve", 0.4, 0.35, cf * CFrame.new(1.85, 5.15, 3.65), Color3.fromRGB(200, 160, 40), Enum.Material.Metal).CanCollide = false

	-- Fahrerschutzdach
	local roofY = 9.2
	for _, sx in { -1, 1 } do
		rod(m, `GuardFront{sx}`, cf, Vector3.new(sx * 2.05, 3.6, -1.95), Vector3.new(sx * 2.05, roofY, -1.6), 0.32, CHASSIS, Enum.Material.Metal)
		rod(m, `GuardRear{sx}`, cf, Vector3.new(sx * 2.05, 4.3, 3.05), Vector3.new(sx * 2.05, roofY, 2.7), 0.32, CHASSIS, Enum.Material.Metal)
		part(m, `GuardRail{sx}`, Vector3.new(0.32, 0.32, 4.6), cf * CFrame.new(sx * 2.05, roofY, 0.55), CHASSIS, Enum.Material.Metal)
		part(m, `Headlight{sx}`, Vector3.new(0.5, 0.5, 0.15), cf * CFrame.new(sx * 2.05, roofY - 0.8, -1.82), Color3.fromRGB(255, 250, 220), Enum.Material.Neon).CanCollide = false
		part(m, `Mirror{sx}`, Vector3.new(0.5, 0.35, 0.08), cf * CFrame.new(sx * 2.4, roofY - 1.6, -1.5), Color3.fromRGB(170, 190, 210), Enum.Material.Glass).CanCollide = false
	end
	for i = 0, 5 do
		part(m, `GuardSlat{i}`, Vector3.new(4.1, 0.16, 0.3), cf * CFrame.new(0, roofY + 0.08, -1.55 + i * 0.85), CHASSIS, Enum.Material.Metal)
	end
	local headlightGlow = Instance.new("SpotLight")
	headlightGlow.Angle = 60
	headlightGlow.Range = 18
	headlightGlow.Brightness = 1.5
	headlightGlow.Face = Enum.NormalId.Front
	headlightGlow.Parent = m:FindFirstChild("Headlight1")
	local beaconBase = part(m, "BeaconBase", Vector3.new(0.6, 0.25, 0.6), cf * CFrame.new(0, roofY + 0.3, 2.3), CHASSIS, Enum.Material.Metal)
	local beacon = part(m, "Beacon", Vector3.new(0.7, 0.7, 0.7), beaconBase.CFrame * CFrame.new(0, 0.45, 0), Color3.fromRGB(255, 150, 30), Enum.Material.Neon)
	beacon.Shape = Enum.PartType.Ball
	beacon.CanCollide = false

	-- Duplex-Mast: äußere und innere Profile, Traversen, Ketten, Hubzylinder
	local mastZ = -3.0
	local mastTop = 11.4
	for _, sx in { -1, 1 } do
		part(m, `MastOuter{sx}`, Vector3.new(0.5, mastTop - 0.6, 0.75), cf * CFrame.new(sx * 1.55, 0.6 + (mastTop - 0.6) / 2, mastZ), CHASSIS, Enum.Material.Metal)
		part(m, `MastInner{sx}`, Vector3.new(0.38, mastTop - 1.2, 0.5), cf * CFrame.new(sx * 1.12, 1.0 + (mastTop - 1.2) / 2, mastZ - 0.3), STEEL, Enum.Material.Metal)
		part(m, `Chain{sx}`, Vector3.new(0.14, mastTop - 2.4, 0.2), cf * CFrame.new(sx * 0.55, 2.2 + (mastTop - 2.4) / 2, mastZ + 0.1), Color3.fromRGB(30, 30, 30), Enum.Material.Metal).CanCollide = false
		rod(m, `TiltCylinder{sx}`, cf, Vector3.new(sx * 1.75, 2.6, -1.7), Vector3.new(sx * 1.6, 3.3, mastZ + 0.35), 0.35, STEEL_LIGHT, Enum.Material.Metal)
	end
	for i, y in { 1.0, 5.5, mastTop - 0.3 } do
		part(m, `MastCross{i}`, Vector3.new(3.6, 0.4, 0.55), cf * CFrame.new(0, y, mastZ + 0.05), CHASSIS, Enum.Material.Metal)
	end
	cylinder(m, "LiftCylinder", mastTop - 3, 0.55, cf * CFrame.new(0, 1.2 + (mastTop - 3) / 2, mastZ + 0.2) * CFrame.Angles(0, 0, math.rad(90)), STEEL_LIGHT, Enum.Material.Metal)
	cylinder(m, "ChainSheave", 1.6, 0.8, cf * CFrame.new(0, mastTop + 0.2, mastZ - 0.1), STEEL, Enum.Material.Metal)

	-- Gabelträger mit Lastschutzgitter und Gabeln
	local carZ = mastZ - 0.75
	part(m, "CarriageLow", Vector3.new(3.9, 0.45, 0.3), cf * CFrame.new(0, 1.05, carZ), CHASSIS, Enum.Material.Metal)
	part(m, "CarriageHigh", Vector3.new(3.9, 0.45, 0.3), cf * CFrame.new(0, 2.35, carZ), CHASSIS, Enum.Material.Metal)
	for i = 0, 4 do
		part(m, `BackrestBar{i}`, Vector3.new(0.18, 2.6, 0.18), cf * CFrame.new(-1.8 + i * 0.9, 3.75, carZ), CHASSIS, Enum.Material.Metal)
	end
	part(m, "BackrestTop", Vector3.new(3.9, 0.25, 0.25), cf * CFrame.new(0, 5.05, carZ), CHASSIS, Enum.Material.Metal)
	local forkLen = 5
	for _, sx in { -1, 1 } do
		part(m, `ForkShank{sx}`, Vector3.new(0.5, 2.2, 0.25), cf * CFrame.new(sx * 1.15, 1.25, carZ - 0.28), STEEL, Enum.Material.Metal)
		part(m, `ForkBlade{sx}`, Vector3.new(0.55, 0.2, forkLen), cf * CFrame.new(sx * 1.15, 0.25, carZ - 0.4 - forkLen / 2), STEEL, Enum.Material.Metal)
		part(m, `ForkTip{sx}`, Vector3.new(0.55, 0.1, 0.4), cf * CFrame.new(sx * 1.15, 0.2, carZ - 0.4 - forkLen - 0.2), STEEL, Enum.Material.Metal)
	end

	-- Ladung: Holzkiste auf den Gabeln
	if withLoad then
		local crate = WoodCrate.build(m, cf * CFrame.new(0, 0.36, carZ - 0.42 - WoodCrate.Size / 2))
		crate.Name = "Load"
		WoodCrate.setContent(crate, "Coal", Color3.fromRGB(44, 44, 46), 0.85)
		for _, d in crate:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanCollide = false
			end
		end
	end

	m.PrimaryPart = chassis
	m.Parent = parent
	return m
end

return table.freeze(ForkliftBuilder)
