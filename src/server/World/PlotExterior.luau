--!strict
-- Außenbereich eines Plots wie in FACTORY_MASTERPLAN_TOPDOWN.png (Phase 13b-1): Holzzaun,
-- asphaltierter Vorplatz vor dem Glastor, Gehweg an der Hallenfront, Beete mit Bäumen,
-- Pförtnerhäuschen und Gabelstapler links vorne, Hochregale mit Kisten und Container rechts vorne,
-- Kies-Seitenhöfe mit Regalen, Reifen, Fässern und Felsen, Bäume am Zaun, Klimageräte hinten.
-- Rein optisch; gehört zum Plot (immer sichtbar, unabhängig vom Ausbau).
--
-- Koordinaten lokal zur Plotmitte (Bodenhöhe), -Z = Vorderseite/Straße, +X = im Bild links.
-- Der Außenbereich der Schmelze (Tanks rechts) kommt mit dem Schmelzer (Phase 13b-3).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LayoutConfig)

local EnvironmentBuilder = require(script.Parent.EnvironmentBuilder)
local ForkliftBuilder = require(script.Parent.ForkliftBuilder)

local PlotExterior = {}

local ASPHALT = Color3.fromRGB(58, 60, 64)
local PAVING = Color3.fromRGB(176, 170, 160)
local CURB = Color3.fromRGB(140, 134, 126)
local GRAVEL = Color3.fromRGB(150, 144, 134)
local SOIL = Color3.fromRGB(86, 66, 48)
local GRASS = Color3.fromRGB(92, 138, 70)
local FENCE_WOOD = Color3.fromRGB(122, 86, 56)
local FENCE_DARK = Color3.fromRGB(92, 64, 42)
local RACK_FRAME = Color3.fromRGB(222, 150, 40)
local CRATE = Color3.fromRGB(176, 128, 78)
local CRATE_DARK = Color3.fromRGB(138, 98, 58)
local STEEL = Color3.fromRGB(70, 74, 80)
local GREEN_BOOTH = Color3.fromRGB(70, 104, 76)
local CONTAINER = Color3.fromRGB(70, 110, 78)
local YELLOW = Color3.fromRGB(236, 182, 40)
local WHITE = Color3.fromRGB(236, 236, 232)
local CONCRETE_SILL = Color3.fromRGB(130, 128, 124)
local TIRE = Color3.fromRGB(30, 30, 32)
local BARREL = Color3.fromRGB(40, 90, 150)
local GLASS = Color3.fromRGB(170, 210, 230)

local GROUND = 1 -- Oberkante Plotboden

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

-- Flache Fläche mit Oberkante topY (lokal), Mittelpunkt x/z, Größe sx/sz
local function slab(parent: Instance, name: string, o: CFrame, x1: number, x2: number, z1: number, z2: number, topY: number, thickness: number, color: Color3, material: Enum.Material): Part
	local sx, sz = math.abs(x2 - x1), math.abs(z2 - z1)
	return part(parent, name, Vector3.new(sx, thickness, sz), o * CFrame.new((x1 + x2) / 2, topY - thickness / 2, (z1 + z2) / 2), color, material)
end

-- Holzzaun: Pfosten mit zwei Querlatten, von a nach b (lokal, X/Z)
local function fence(parent: Instance, name: string, o: CFrame, a: Vector2, b: Vector2)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	local dir = b - a
	local length = dir.Magnitude
	if length < 0.5 then
		return
	end
	local unit = dir.Unit
	local yaw = math.atan2(-unit.Y, unit.X)
	local mid = (a + b) / 2
	local rot = CFrame.Angles(0, yaw, 0)
	part(parent, `{name}RailTop`, Vector3.new(length, 0.35, 0.3), o * CFrame.new(mid.X, GROUND + 3.4, mid.Y) * rot, FENCE_WOOD, Enum.Material.WoodPlanks)
	part(parent, `{name}RailLow`, Vector3.new(length, 0.35, 0.3), o * CFrame.new(mid.X, GROUND + 1.7, mid.Y) * rot, FENCE_WOOD, Enum.Material.WoodPlanks)
	local posts = math.max(1, math.floor(length / 6))
	for i = 0, posts do
		local p = a + unit * (length * i / posts)
		part(parent, `{name}Post{i}`, Vector3.new(0.5, 4.4, 0.5), o * CFrame.new(p.X, GROUND + 2.2, p.Y), FENCE_DARK, Enum.Material.Wood)
	end
end

-- Kiste auf einer Palette (Erz-/Warenkiste wie im Bild)
local function crate(parent: Instance, name: string, cf: CFrame, size: number)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	part(parent, `{name}Pallet`, Vector3.new(size + 0.4, 0.4, size + 0.4), cf * CFrame.new(0, 0.2, 0), FENCE_DARK, Enum.Material.WoodPlanks)
	local box = part(parent, name, Vector3.new(size, size * 0.8, size), cf * CFrame.new(0, 0.4 + size * 0.4, 0), CRATE, Enum.Material.WoodPlanks)
	for _, dx in { -1, 1 } do
		part(parent, `{name}Slat{dx}`, Vector3.new(0.2, size * 0.8, size + 0.04), box.CFrame * CFrame.new(dx * (size / 2 - 0.15), 0, 0), CRATE_DARK, Enum.Material.Wood)
	end
end

-- Hochregal (orange) mit Kisten auf zwei Ebenen, Länge entlang lokal X
local function rack(parent: Instance, name: string, cf: CFrame, bays: number)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	local bayW = 5
	local length = bays * bayW
	for i = 0, bays do
		for _, dz in { -1.4, 1.4 } do
			part(parent, `{name}Upright{i}_{dz}`, Vector3.new(0.3, 9, 0.3), cf * CFrame.new(-length / 2 + i * bayW, 4.5, dz), RACK_FRAME, Enum.Material.Metal)
		end
	end
	for level, y in { 0.2, 4.4 } do
		if level > 1 then
			for _, dz in { -1.4, 1.4 } do
				part(parent, `{name}Beam{level}_{dz}`, Vector3.new(length, 0.35, 0.25), cf * CFrame.new(0, y - 0.2, dz), RACK_FRAME, Enum.Material.Metal)
			end
		end
		for b = 1, bays do
			crate(parent, `{name}Crate{level}_{b}`, cf * CFrame.new(-length / 2 + (b - 0.5) * bayW, y, 0), 3.4)
		end
	end
end

local function tireStack(parent: Instance, name: string, cf: CFrame, count: number)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	for i = 1, count do
		local tire = part(parent, `{name}{i}`, Vector3.new(1.1, 3.4, 3.4), cf * CFrame.new(0, 0.55 + (i - 1) * 1.15, 0) * CFrame.Angles(0, 0, math.rad(90)), TIRE, Enum.Material.Rubber, Enum.PartType.Cylinder)
		tire.CanCollide = true
	end
end

local function barrel(parent: Instance, name: string, cf: CFrame, color: Color3)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	part(parent, name, Vector3.new(2.8, 1.8, 1.8), cf * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Metal, Enum.PartType.Cylinder)
end

-- Beet mit Bordstein, Erde, Bäumen und Büschen
local function bed(parent: Instance, name: string, o: CFrame, x1: number, x2: number, z1: number, z2: number, trees: { Vector2 }, rng: Random)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	slab(parent, `{name}Curb`, o, x1 - 0.5, x2 + 0.5, z1 - 0.5, z2 + 0.5, GROUND + 0.5, 0.6, CURB, Enum.Material.Concrete)
	slab(parent, `{name}Soil`, o, x1, x2, z1, z2, GROUND + 0.6, 0.6, GRASS, Enum.Material.Grass)
	for i, t in trees do
		local world = (o * CFrame.new(t.X, GROUND + 0.6, t.Y)).Position
		EnvironmentBuilder.pine(parent, i, world, rng:NextNumber(0.8, 1.05), rng)
	end
	for i = 1, 3 do
		local bx = x1 + rng:NextNumber(0.15, 0.85) * (x2 - x1)
		local bz = z1 + rng:NextNumber(0.15, 0.85) * (z2 - z1)
		local bush = part(parent, `{name}Bush{i}`, Vector3.new(3, 2.4, 3), o * CFrame.new(bx, GROUND + 1.6, bz), Color3.fromRGB(64, 112, 58), Enum.Material.Grass, Enum.PartType.Ball)
		bush.CanCollide = false
	end
end

-- Pförtnerhäuschen (grün, Glasfenster, Flachdach)
local function guardBooth(parent: Instance, cf: CFrame)
	local obj = Instance.new("Model")
	obj.Name = "GuardBooth"
	obj.Parent = parent
	parent = obj
	part(parent, "BoothBase", Vector3.new(11, 0.6, 9), cf * CFrame.new(0, 0.3, 0), CURB, Enum.Material.Concrete)
	part(parent, "BoothBody", Vector3.new(10, 8, 8), cf * CFrame.new(0, 4.6, 0), GREEN_BOOTH, Enum.Material.Metal)
	part(parent, "BoothRoof", Vector3.new(11.4, 0.6, 9.4), cf * CFrame.new(0, 8.9, 0), STEEL, Enum.Material.Metal)
	for _, side in { -1, 1 } do
		local w = part(parent, `BoothWindow{side}`, Vector3.new(0.2, 2.8, 5.6), cf * CFrame.new(side * 5.05, 5.6, 0), GLASS, Enum.Material.Glass)
		w.Transparency = 0.3
	end
	local front = part(parent, "BoothWindowFront", Vector3.new(7, 2.8, 0.2), cf * CFrame.new(0, 5.6, -4.05), GLASS, Enum.Material.Glass)
	front.Transparency = 0.3
	part(parent, "BoothDoor", Vector3.new(3, 6.2, 0.2), cf * CFrame.new(2.6, 3.7, 4.05), STEEL, Enum.Material.Metal)
	local light = part(parent, "BoothLight", Vector3.new(1.2, 0.3, 1.2), cf * CFrame.new(0, 9.3, -4.2), Color3.fromRGB(255, 232, 186), Enum.Material.Neon)
	light.CanCollide = false
end

-- Gabelstapler (gleiches realistisches Modell wie in der Halle, ohne Fahrer)
local function forklift(parent: Instance, cf: CFrame)
	ForkliftBuilder.build(parent, "Forklift", cf, false)
end

-- Seecontainer (grün, mit Sicken)
local function container(parent: Instance, cf: CFrame)
	local obj = Instance.new("Model")
	obj.Name = "ShippingContainer"
	obj.Parent = parent
	parent = obj
	local box = part(parent, "Container", Vector3.new(24, 9, 9.6), cf * CFrame.new(0, 4.5, 0), CONTAINER, Enum.Material.Metal)
	for i = -5, 5 do
		part(parent, `ContainerRib{i}`, Vector3.new(0.5, 8.6, 9.8), box.CFrame * CFrame.new(i * 2.2, 0, 0), CONTAINER:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Metal)
	end
	part(parent, "ContainerDoorFrame", Vector3.new(0.2, 9, 9.6), box.CFrame * CFrame.new(12.05, 0, 0), STEEL, Enum.Material.Metal)
end

-- Klimagerät / Kompressor (hinter der Halle)
local function acUnit(parent: Instance, name: string, cf: CFrame)
	local obj = Instance.new("Model")
	obj.Name = name
	obj.Parent = parent
	parent = obj
	part(parent, name, Vector3.new(6, 4, 4), cf * CFrame.new(0, 2, 0), Color3.fromRGB(196, 198, 200), Enum.Material.Metal)
	local fan = part(parent, `{name}Fan`, Vector3.new(0.2, 3, 3), cf * CFrame.new(0, 4.05, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal, Enum.PartType.Cylinder)
	fan.CanCollide = false
end

function PlotExterior.build(model: Model, origin: CFrame)
	local folder = Instance.new("Folder")
	folder.Name = "Exterior"
	folder.Parent = model
	local cfg = LayoutConfig
	local halfX, halfZ = cfg.PlotSize.X / 2, cfg.PlotSize.Y / 2
	local hx, hz = cfg.HallSize.X / 2, cfg.HallSize.Y / 2
	local hallFront = cfg.HallOffset.Y - hz
	local hallBack = cfg.HallOffset.Y + hz
	local hallLeft, hallRight = cfg.HallOffset.X + hx, cfg.HallOffset.X - hx
	local entranceL = cfg.DoorCenterX + cfg.EntranceWidth / 2
	local entranceR = cfg.DoorCenterX - cfg.EntranceWidth / 2
	local rng = Random.new(cfg.Environment.Seed + 31)
	local o = origin

	-- Holzzaun rundum mit Lücke für den Vorplatz
	local e = 1.5
	fence(folder, "FenceBack", o, Vector2.new(-halfX + e, halfZ - e), Vector2.new(halfX - e, halfZ - e))
	-- Linker Zaun mit Tor für die Verladestraße (D-052)
	local gate = cfg.Garage.Gate
	fence(folder, "FenceLeft", o, Vector2.new(halfX - e, -halfZ + e), Vector2.new(halfX - e, gate.Z1))
	fence(folder, "FenceLeftRear", o, Vector2.new(halfX - e, gate.Z2), Vector2.new(halfX - e, halfZ - e))
	fence(folder, "FenceRight", o, Vector2.new(-halfX + e, -halfZ + e), Vector2.new(-halfX + e, halfZ - e))
	fence(folder, "FenceFrontLeft", o, Vector2.new(entranceL, -halfZ + e), Vector2.new(halfX - e, -halfZ + e))
	fence(folder, "FenceFrontRight", o, Vector2.new(-halfX + e, -halfZ + e), Vector2.new(entranceR, -halfZ + e))

	-- Vorplatz (Asphalt) vom Glastor bis zur Straße, mit Bordsteinen und Torzufahrt-Markierung
	slab(folder, "Forecourt", o, entranceR, entranceL, -halfZ, hallFront, GROUND + 0.05, 0.2, ASPHALT, Enum.Material.Asphalt)
	for _, x in { entranceR, entranceL } do
		slab(folder, `ForecourtCurb{x}`, o, x - 0.4, x + 0.4, -halfZ, hallFront - 8, GROUND + 0.35, 0.5, CURB, Enum.Material.Concrete)
	end
	local stop = slab(folder, "StopLine", o, cfg.DoorCenterX - cfg.DoorWidth / 2, cfg.DoorCenterX + cfg.DoorWidth / 2, hallFront - 6.4, hallFront - 5.6, GROUND + 0.1, 0.06, WHITE, Enum.Material.SmoothPlastic)
	stop.CanCollide = false
	-- Gehweg an der Hallenfront links und rechts vom Vorplatz
	slab(folder, "WalkwayLeft", o, entranceL, halfX - 3, hallFront - 8, hallFront, GROUND + 0.15, 0.3, PAVING, Enum.Material.Pavement)
	slab(folder, "WalkwayRight", o, -halfX + 3, entranceR, hallFront - 8, hallFront, GROUND + 0.15, 0.3, PAVING, Enum.Material.Pavement)

	-- Links vorne: Beete mit Bäumen, Pförtnerhäuschen, Gabelstapler, Laternen, Bänke
	local lx1, lx2 = entranceL + 6, halfX - 6
	bed(folder, "BedFrontLeftA", o, lx1, lx1 + 30, -halfZ + 8, -halfZ + 30, { Vector2.new(lx1 + 8, -halfZ + 18), Vector2.new(lx1 + 22, -halfZ + 14) }, rng)
	bed(folder, "BedFrontLeftB", o, lx2 - 40, lx2, -halfZ + 8, -halfZ + 26, { Vector2.new(lx2 - 30, -halfZ + 17), Vector2.new(lx2 - 12, -halfZ + 15) }, rng)
	slab(folder, "YardLeft", o, lx1, lx2, -halfZ + 30, hallFront - 8, GROUND + 0.1, 0.2, PAVING, Enum.Material.Pavement)
	guardBooth(folder, o * CFrame.new(lx1 + 12, GROUND, hallFront - 26) * CFrame.Angles(0, math.rad(-90), 0))
	forklift(folder, o * CFrame.new(lx1 + 40, GROUND + 0.1, hallFront - 22) * CFrame.Angles(0, math.rad(30), 0))
	for i = 1, 3 do
		crate(folder, `YardLeftCrate{i}`, o * CFrame.new(lx1 + 55 + i * 4.6, GROUND + 0.1, hallFront - 14), 3.6)
	end
	for i, z in { -halfZ + 12, hallFront - 14 } do
		EnvironmentBuilder.streetLamp(folder, `ForecourtLampL{i}`, o * CFrame.new(entranceL + 2.5, GROUND, z) * CFrame.Angles(0, math.rad(-90), 0))
		EnvironmentBuilder.streetLamp(folder, `ForecourtLampR{i}`, o * CFrame.new(entranceR - 2.5, GROUND, z) * CFrame.Angles(0, math.rad(90), 0))
	end

	-- Rechts vorne: Beet mit Baum, Pflasterfläche mit zwei Hochregalen und grünem Container
	local rx1, rx2 = -halfX + 6, entranceR - 6
	bed(folder, "BedFrontRightA", o, rx2 - 28, rx2, -halfZ + 8, -halfZ + 30, { Vector2.new(rx2 - 14, -halfZ + 19) }, rng)
	bed(folder, "BedFrontRightB", o, rx1, rx1 + 26, -halfZ + 8, -halfZ + 24, { Vector2.new(rx1 + 13, -halfZ + 16) }, rng)
	slab(folder, "YardRight", o, rx1, rx2, -halfZ + 30, hallFront - 8, GROUND + 0.1, 0.2, PAVING, Enum.Material.Pavement)
	rack(folder, "YardRackA", o * CFrame.new(rx2 - 30, GROUND + 0.1, hallFront - 13), 5)
	rack(folder, "YardRackB", o * CFrame.new(rx2 - 60, GROUND + 0.1, hallFront - 13), 4)
	container(folder, o * CFrame.new(rx1 + 32, GROUND + 0.1, hallFront - 14))

	-- Seitenhöfe: Kies, Regale/Reifen/Fässer links, Felsen und Bäume am Zaun
	local leftYardX = (hallLeft + halfX) / 2
	slab(folder, "GravelLeft", o, hallLeft, halfX - 3, hallFront, hallBack, GROUND + 0.08, 0.2, GRAVEL, Enum.Material.Pebble)
	slab(folder, "GravelRight", o, -halfX + 3, hallRight, hallFront, hallBack, GROUND + 0.08, 0.2, GRAVEL, Enum.Material.Pebble)
	rack(folder, "SideRackA", o * CFrame.new(leftYardX - 6, GROUND + 0.1, hallFront + 14) * CFrame.Angles(0, math.rad(90), 0), 6)
	rack(folder, "SideRackB", o * CFrame.new(leftYardX - 6, GROUND + 0.1, hallFront + 75) * CFrame.Angles(0, math.rad(90), 0), 4)
	for i = 1, 4 do
		tireStack(folder, `SideTires{i}`, o * CFrame.new(leftYardX + 8, GROUND + 0.1, hallFront + 92 + i * 4.2), rng:NextInteger(2, 5))
	end
	for i = 1, 3 do
		barrel(folder, `SideBarrel{i}`, o * CFrame.new(leftYardX + 8 + (i % 2) * 2, GROUND + 0.1, hallFront + 112 + i * 2.2), if i == 2 then Color3.fromRGB(190, 50, 40) else BARREL)
	end
	for i = 1, 6 do
		local z = hallFront + 130 + i * 18
		if z < hallBack + 6 then
			EnvironmentBuilder.pine(folder, 100 + i, (o * CFrame.new(halfX - 8, GROUND, z)).Position, rng:NextNumber(0.8, 1.1), rng)
		end
	end
	for i = 1, 5 do
		EnvironmentBuilder.boulder(folder, `SideRockL{i}`, (o * CFrame.new(halfX - 9, GROUND, hallFront + 50 + i * 22)).Position, rng:NextNumber(2.5, 5), rng)
		EnvironmentBuilder.boulder(folder, `SideRockR{i}`, (o * CFrame.new(-halfX + 9, GROUND, hallFront + 100 + i * 12)).Position, rng:NextNumber(2.5, 5), rng)
	end
	for i = 1, 3 do
		tireStack(folder, `SideTiresR{i}`, o * CFrame.new(-halfX + 10, GROUND + 0.1, hallFront + 6 + i * 4.2), rng:NextInteger(2, 4))
	end

	-- Verladestraße zwischen Zauntor und Hallenöffnung (D-052): Asphalt, Randlinien, Rampe auf
	-- Hallenbodenhöhe, Torpfosten mit Schild
	local laneCfg = cfg.Garage.Lane
	local lz1, lz2 = laneCfg.Z - laneCfg.Width / 2, laneCfg.Z + laneCfg.Width / 2
	slab(folder, "SideLane", o, hallLeft + 0.8, halfX + 0.5, lz1, lz2, GROUND + 0.12, 0.2, ASPHALT, Enum.Material.Asphalt)
	for _, z in { lz1 + 0.6, lz2 - 0.6 } do
		local line = slab(folder, `SideLaneEdge{z}`, o, hallLeft + 6, halfX - 1, z - 0.25, z + 0.25, GROUND + 0.14, 0.04, WHITE, Enum.Material.SmoothPlastic)
		line.CanCollide = false
	end
	local rampLen = 6
	local rampRise = cfg.HallFloorTop - (GROUND + 0.12)
	local ramp = Instance.new("WedgePart")
	ramp.Name = "SideLaneRamp"
	ramp.Anchored = true
	ramp.Size = Vector3.new(laneCfg.Width, rampRise, rampLen)
	-- Wedge steigt zur Halle hin (-X) an
	ramp.CFrame = o * CFrame.new(hallLeft + 1 + rampLen / 2, GROUND + 0.12 + rampRise / 2, laneCfg.Z) * CFrame.Angles(0, math.rad(-90), 0)
	ramp.Color = ASPHALT
	ramp.Material = Enum.Material.Asphalt
	ramp.Parent = folder
	-- Schwelle in der Wandöffnung auf Hallenbodenhöhe
	slab(folder, "SideLaneSill", o, hallLeft - 1, hallLeft + 1, lz1, lz2, cfg.HallFloorTop, 0.4, CONCRETE_SILL, Enum.Material.Concrete)
	for _, z in { gate.Z1, gate.Z2 } do
		part(folder, `GatePost{z}`, Vector3.new(1.2, 6, 1.2), o * CFrame.new(halfX - e, GROUND + 3, z), FENCE_DARK, Enum.Material.Wood)
	end

	-- Hinterhof: Bäume am Zaun, Klimageräte, Laternen
	local backZ = (hallBack + halfZ) / 2
	for i = 0, 12 do
		local x = -halfX + 20 + i * ((cfg.PlotSize.X - 40) / 12)
		EnvironmentBuilder.pine(folder, 200 + i, (o * CFrame.new(x, GROUND, halfZ - 9)).Position, rng:NextNumber(0.75, 1.05), rng)
	end
	for i = 1, 3 do
		acUnit(folder, `ACUnit{i}`, o * CFrame.new(cfg.DoorCenterX - 40 + i * 14, GROUND, hallBack + 6))
	end
	for i, x in { -halfX + 60, halfX - 60 } do
		EnvironmentBuilder.streetLamp(folder, `BackLamp{i}`, o * CFrame.new(x, GROUND, backZ + 4) * CFrame.Angles(0, math.rad(180), 0))
	end
end

return table.freeze(PlotExterior)
