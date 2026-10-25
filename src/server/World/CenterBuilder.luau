--!strict
-- Gestaltung der Map-Mitte (D-057, Felix 2026-10-22: „viel schöner und einladender … großer
-- Parkplatz … so ähnlich wie im Bild im Plan“, CENTRAL_AREA_REFERENCE.png). Die echte Mitte bleibt
-- der grüne Verkaufskreis (SellingBuilder, D-056) in der Insel des Kreisverkehrs.
--
-- Aufbau (alles aus LayoutConfig.Center abgeleitet, deterministisch):
--   * Wiese statt grauer Pflasterfläche, Holzzaun am Platzrand (Lücken an den Straßen)
--   * Promenade (Pflasterring) um den Kreisverkehr mit Blumenbeeten, Bänken und Laternen
--   * Gehwege mit Laternen entlang der Speichenstraßen
--   * Parkplätze vor den drei Shops und ein großer Parkplatz in einem freien Sektor
--   * Park mit Teich und Garten mit Pavillon und Picknicktischen in den übrigen Sektoren
--   * viele Bäume, Büsche und Blumen auf den freien Wiesenflächen
-- Reine Optik; keine Spiellogik hängt davon ab. Straßen/Kreisverkehr baut EnvironmentBuilder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local GameConfig = require(Shared.Config.GameConfig)

local EnvironmentBuilder = require(script.Parent.EnvironmentBuilder)

local CenterBuilder = {}

local TOP = LayoutConfig.GroundY + 1

local GRASS = Color3.fromRGB(98, 146, 72)
local PAVING = Color3.fromRGB(184, 176, 164)
local PAVING_DARK = Color3.fromRGB(148, 140, 130)
local COBBLE = Color3.fromRGB(170, 160, 146)
local GRAVEL = Color3.fromRGB(196, 182, 150)
local ASPHALT = Color3.fromRGB(62, 64, 68)
local LINE_WHITE = Color3.fromRGB(236, 236, 232)
local WOOD = Color3.fromRGB(128, 88, 56)
local WOOD_DARK = Color3.fromRGB(96, 66, 42)
local SOIL = Color3.fromRGB(86, 62, 44)
local LEAF = { Color3.fromRGB(64, 120, 58), Color3.fromRGB(78, 136, 62), Color3.fromRGB(56, 108, 52) }
local FLOWERS = {
	Color3.fromRGB(226, 72, 84),
	Color3.fromRGB(246, 204, 70),
	Color3.fromRGB(236, 128, 186),
	Color3.fromRGB(150, 104, 214),
	Color3.fromRGB(250, 250, 244),
	Color3.fromRGB(244, 146, 62),
}
local WATER = Color3.fromRGB(70, 140, 176)
local SAND = Color3.fromRGB(204, 186, 140)
local STEEL = Color3.fromRGB(58, 62, 68)
local GLASS = Color3.fromRGB(176, 214, 230)

-- ---------------------------------------------------------------------------------------------
-- Bausteine

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

-- Flache Bodenplatte (nicht kollidierend, damit Fahrzeuge nicht hängen bleiben)
local function flat(parent: Instance, name: string, size: Vector2, cf: CFrame, topY: number, color: Color3, material: Enum.Material): Part
	local p = part(parent, name, Vector3.new(size.X, 0.1, size.Y), cf.Rotation + Vector3.new(cf.X, topY - 0.05, cf.Z), color, material)
	p.CanCollide = false
	p.CanQuery = false
	return p
end

local function disc(parent: Instance, name: string, radius: number, thickness: number, pos: Vector3, topY: number, color: Color3, material: Enum.Material): Part
	return part(parent, name, Vector3.new(thickness, radius * 2, radius * 2), CFrame.new(pos.X, topY - thickness / 2, pos.Z) * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
end

-- Ring aus tangentialen Segmenten (Oberkante topY)
local function annulus(parent: Instance, name: string, inner: number, outer: number, topY: number, color: Color3, material: Enum.Material, segments: number)
	local c = LayoutConfig.MapCenter
	local mid = (inner + outer) / 2
	local segLen = 2 * math.pi * outer / segments + 0.4
	for i = 1, segments do
		local a = (i - 0.5) / segments * math.pi * 2
		local cf = CFrame.new(c.X + math.cos(a) * mid, 0, c.Z + math.sin(a) * mid) * CFrame.Angles(0, -a, 0)
		flat(parent, `{name}{i}`, Vector2.new(outer - inner, segLen), cf, topY, color, material)
	end
end

local function bush(parent: Instance, name: string, pos: Vector3, size: number, rng: Random)
	local b = part(parent, name, Vector3.new(size * 1.3, size, size * 1.2), CFrame.new(pos + Vector3.new(0, size * 0.4, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), LEAF[rng:NextInteger(1, #LEAF)], Enum.Material.Grass, Enum.PartType.Ball)
	b.CanCollide = false
end

local function flowerPatch(parent: Instance, name: string, pos: Vector3, radius: number, count: number, rng: Random)
	local m = Instance.new("Model")
	m.Name = name
	local color = FLOWERS[rng:NextInteger(1, #FLOWERS)]
	for i = 1, count do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * radius
		local p = pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local stem = part(m, `Leaf{i}`, Vector3.new(0.9, 0.7, 0.9), CFrame.new(p + Vector3.new(0, 0.3, 0)), LEAF[1], Enum.Material.Grass, Enum.PartType.Ball)
		stem.CanCollide = false
		local bloom = part(m, `Bloom{i}`, Vector3.new(0.6, 0.6, 0.6), CFrame.new(p + Vector3.new(0, 0.8, 0)), if rng:NextNumber() < 0.75 then color else FLOWERS[rng:NextInteger(1, #FLOWERS)], Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		bloom.CanCollide = false
	end
	m.Parent = parent
end

-- Holzkasten mit Blumen (Länge entlang lokal X)
local function flowerBed(parent: Instance, name: string, cf: CFrame, length: number, depth: number, rng: Random)
	local m = Instance.new("Model")
	m.Name = name
	part(m, "Box", Vector3.new(length, 1.1, depth), cf * CFrame.new(0, 0.55, 0), WOOD, Enum.Material.WoodPlanks)
	part(m, "Soil", Vector3.new(length - 0.5, 0.2, depth - 0.5), cf * CFrame.new(0, 1.1, 0), SOIL, Enum.Material.Ground)
	local n = math.floor(length * depth / 2.2)
	for i = 1, n do
		local p = cf * CFrame.new(rng:NextNumber(-length / 2 + 0.6, length / 2 - 0.6), 1.2, rng:NextNumber(-depth / 2 + 0.6, depth / 2 - 0.6))
		local leaf = part(m, `Leaf{i}`, Vector3.new(1, 0.8, 1), p * CFrame.new(0, 0.3, 0), LEAF[rng:NextInteger(1, #LEAF)], Enum.Material.Grass, Enum.PartType.Ball)
		leaf.CanCollide = false
		local bloom = part(m, `Bloom{i}`, Vector3.new(0.65, 0.65, 0.65), p * CFrame.new(0, 0.85, 0), FLOWERS[rng:NextInteger(1, #FLOWERS)], Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		bloom.CanCollide = false
	end
	m.Parent = parent
end

-- Parkbank, Sitzfläche zeigt nach lokal -Z
local function bench(parent: Instance, name: string, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = name
	part(m, "Seat", Vector3.new(5, 0.3, 1.6), cf * CFrame.new(0, 1.5, 0), WOOD, Enum.Material.Wood)
	part(m, "Back", Vector3.new(5, 1.4, 0.3), cf * CFrame.new(0, 2.3, 0.75), WOOD, Enum.Material.Wood)
	for _, dx in { -2, 2 } do
		part(m, `Leg{dx}`, Vector3.new(0.3, 1.4, 1.4), cf * CFrame.new(dx, 0.7, 0), STEEL, Enum.Material.Metal)
	end
	m.Parent = parent
end

local function picnicTable(parent: Instance, name: string, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = name
	part(m, "Top", Vector3.new(6, 0.3, 2.6), cf * CFrame.new(0, 2.6, 0), WOOD, Enum.Material.WoodPlanks)
	for _, dz in { -2.1, 2.1 } do
		part(m, `Bench{dz}`, Vector3.new(6, 0.25, 1), cf * CFrame.new(0, 1.5, dz), WOOD, Enum.Material.WoodPlanks)
	end
	for _, dx in { -2.4, 2.4 } do
		part(m, `Leg{dx}`, Vector3.new(0.4, 2.5, 4.6), cf * CFrame.new(dx, 1.25, 0), WOOD_DARK, Enum.Material.Wood)
	end
	m.Parent = parent
end

-- Offener Pavillon mit Glasdach (wie im Referenzbild rechts vorne)
local function pavilion(parent: Instance, name: string, cf: CFrame, w: number, d: number, rng: Random)
	local m = Instance.new("Model")
	m.Name = name
	flat(m, "Floor", Vector2.new(w + 2, d + 2), cf, TOP + 0.08, PAVING, Enum.Material.Pavement)
	local h = 9
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(m, `Post{sx}{sz}`, Vector3.new(0.8, h, 0.8), cf * CFrame.new(sx * w / 2, h / 2, sz * d / 2), WOOD_DARK, Enum.Material.Wood)
		end
	end
	for _, sz in { -1, 1 } do
		part(m, `Beam{sz}`, Vector3.new(w + 1, 0.6, 0.6), cf * CFrame.new(0, h, sz * d / 2), WOOD_DARK, Enum.Material.Wood)
	end
	for i = -2, 2 do
		part(m, `Rafter{i}`, Vector3.new(0.4, 0.4, d + 1), cf * CFrame.new(i * w / 5, h + 0.4, 0), WOOD, Enum.Material.Wood)
	end
	local roof = part(m, "Roof", Vector3.new(w + 1.6, 0.2, d + 1.6), cf * CFrame.new(0, h + 0.75, 0), GLASS, Enum.Material.Glass)
	roof.Transparency = 0.45
	for i = 1, 2 do
		picnicTable(m, `Table{i}`, cf * CFrame.new((i - 1.5) * w / 2.2, TOP - cf.Y, 0))
	end
	for _, sx in { -1, 1 } do
		flowerBed(m, `Bed{sx}`, cf * CFrame.new(sx * (w / 2 + 2.6), 0, 0) * CFrame.Angles(0, math.rad(90), 0), d, 2, rng)
	end
	m.Parent = parent
end

-- ---------------------------------------------------------------------------------------------
-- Geometrie: Speichenstraßen, Sektoren, belegte Flächen

-- Speiche: Straßenstück vom Platzrand (tStart) bis zum Kreisverkehr (tEnd) entlang dir
type Spoke = { origin: Vector3, dir: Vector3, tStart: number, tEnd: number }
type Rect = { cf: CFrame, half: Vector2 }

local function plotCFrame(plotId: number): CFrame
	local center = LayoutConfig.MapCenter
	local angle = math.rad(LayoutConfig.PlotAngles[plotId])
	local pos = Vector3.new(center.X + math.cos(angle) * LayoutConfig.PlotRingRadius, TOP, center.Z - math.sin(angle) * LayoutConfig.PlotRingRadius)
	return CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
end

local function flat2(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

-- erster Schnitt (von außen kommend) einer Speiche mit dem Kreis um die Mitte
local function hitT(origin: Vector3, dir: Vector3, radius: number): number
	local c = LayoutConfig.MapCenter
	local o = flat2(origin) - Vector2.new(c.X, c.Z)
	local d = flat2(dir).Unit
	local b = o:Dot(d)
	local disc0 = b * b - (o:Dot(o) - radius * radius)
	return -b - math.sqrt(math.max(disc0, 0))
end

local spokes: { Spoke } = {}
for plotId = 1, GameConfig.MaxPlots do
	local cf = plotCFrame(plotId)
	local origin = (cf * CFrame.new(LayoutConfig.DoorCenterX, 0, 0)).Position
	local dir = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
	table.insert(spokes, {
		origin = origin,
		dir = dir,
		tStart = hitT(origin, dir, LayoutConfig.CenterPlazaRadius + 20),
		tEnd = hitT(origin, dir, LayoutConfig.RoundaboutOuter - 4),
	})
end

-- Abstand zur nächsten Speichenstraße (nur das echte Straßenstück)
local function spokeDistance(p: Vector3): number
	local best = math.huge
	for _, s in spokes do
		local rel = flat2(p - s.origin)
		local d = flat2(s.dir)
		local along = math.clamp(rel:Dot(d), s.tStart, s.tEnd)
		best = math.min(best, (rel - d * along).Magnitude)
	end
	return best
end

local rects: { Rect } = {}
local function occupy(cf: CFrame, size: Vector2, margin: number)
	table.insert(rects, { cf = cf, half = size / 2 + Vector2.new(margin, margin) })
end
local function inRect(p: Vector3): boolean
	for _, r in rects do
		local l = r.cf:PointToObjectSpace(Vector3.new(p.X, r.cf.Y, p.Z))
		if math.abs(l.X) <= r.half.X and math.abs(l.Z) <= r.half.Y then
			return true
		end
	end
	return false
end

-- Frei für Deko (nicht auf Straße, Kreisverkehr, Promenade, belegter Fläche, außerhalb des Zauns)
local function isFree(p: Vector3, margin: number): boolean
	local cfg = LayoutConfig
	local c = cfg.MapCenter
	local r = flat2(p - c).Magnitude
	if r < cfg.Center.PromenadeOuter + margin or r > cfg.Center.FenceRadius - margin then
		return false
	end
	if spokeDistance(p) < cfg.RoadWidth / 2 + cfg.Center.SidewalkWidth + margin then
		return false
	end
	return not inRect(p)
end

-- Sektorrahmen: Ursprung Platzmitte, LookVector = Richtung des Sektors (Grad wie PlotAngles)
local function sectorFrame(deg: number): CFrame
	local c = LayoutConfig.MapCenter
	local a = math.rad(deg)
	local base = Vector3.new(c.X, TOP, c.Z)
	return CFrame.lookAt(base, base + Vector3.new(math.cos(a), 0, -math.sin(a)))
end

-- Freie Breite zwischen den beiden Straßen eines Sektors in Entfernung r (seitliche Koordinaten
-- im Sektorrahmen, Straßenkante inkl. Gehweg)
local function sectorSpan(frame: CFrame, r: number): (number, number)
	local f, right = flat2(frame.LookVector), flat2(frame.RightVector)
	local o = flat2(frame.Position)
	local lo, hi = -math.huge, math.huge
	for _, s in spokes do
		local d = flat2(s.dir)
		local denom = f:Dot(d)
		local t = if math.abs(denom) > 0.05 then (r - f:Dot(flat2(s.origin) - o)) / denom else math.huge
		if t >= s.tStart and t <= s.tEnd then
			local p = flat2(s.origin) + d * t
			local lat = right:Dot(p - o)
			local edge = LayoutConfig.RoadWidth / 2 + LayoutConfig.Center.SidewalkWidth + 3
			if lat > 0 then
				hi = math.min(hi, lat - edge)
			else
				lo = math.max(lo, lat + edge)
			end
		end
	end
	return lo, hi
end

-- ---------------------------------------------------------------------------------------------
-- Teile der Mitte

-- Parkplatz: Reihen quer zur Sektorrichtung, Stellplätze 4.6 breit, 9 tief, Fahrgassen 8.
-- frame zeigt mit LookVector nach außen; doubleRows Doppelreihen (Rücken an Rücken).
local function parkingLot(parent: Instance, name: string, frame: CFrame, stalls: number, doubleRows: number, rng: Random)
	local m = Instance.new("Model")
	m.Name = name
	local stallW, stallD, aisle = 4.6, 9, 8
	local width = stalls * stallW
	local depth = doubleRows * stallD * 2 + (doubleRows + 1) * aisle
	flat(m, "Asphalt", Vector2.new(width + 14, depth), frame, TOP + 0.04, ASPHALT, Enum.Material.Asphalt)
	-- Bordstein ringsum (flach), Inseln mit Bäumen an den Reihenenden
	local z = -depth / 2 + aisle
	for row = 1, doubleRows do
		for half = 0, 1 do
			local rowZ = z + half * stallD
			for i = 0, stalls do
				local x = -width / 2 + i * stallW
				flat(m, `Line{row}_{half}_{i}`, Vector2.new(0.3, stallD - 0.6), frame * CFrame.new(x, 0, rowZ + stallD / 2), TOP + 0.06, LINE_WHITE, Enum.Material.SmoothPlastic)
			end
		end
		flat(m, `Mid{row}`, Vector2.new(width, 0.3), frame * CFrame.new(0, 0, z + stallD), TOP + 0.06, LINE_WHITE, Enum.Material.SmoothPlastic)
		for _, side in { -1, 1 } do
			local islandCF = frame * CFrame.new(side * (width / 2 + 3.6), 0, z + stallD)
			part(m, `Island{row}{side}`, Vector3.new(5.6, 0.5, stallD * 2 - 1), islandCF * CFrame.new(0, 0.25, 0), PAVING_DARK, Enum.Material.Concrete)
			part(m, `IslandGrass{row}{side}`, Vector3.new(4.8, 0.1, stallD * 2 - 1.8), islandCF * CFrame.new(0, 0.53, 0), GRASS, Enum.Material.Grass)
			EnvironmentBuilder.pine(m, 6000 + row * 10 + (side + 1), islandCF.Position + Vector3.new(0, 0.5, 0), rng:NextNumber(0.6, 0.8), rng)
			EnvironmentBuilder.streetLamp(m, `Lamp{row}{side}`, islandCF * CFrame.new(0, 0.5, stallD - 1.5) * CFrame.Angles(0, math.rad(side * 90), 0))
		end
		z += stallD * 2 + aisle
	end
	m.Parent = parent
	occupy(frame, Vector2.new(width + 14, depth), 2)
end

local function promenade(parent: Instance, rng: Random)
	local cfg = LayoutConfig
	local c = cfg.MapCenter
	local folder = Instance.new("Folder")
	folder.Name = "Promenade"
	folder.Parent = parent
	annulus(folder, "Ring", cfg.RoundaboutOuter, cfg.Center.PromenadeOuter, TOP + 0.03, COBBLE, Enum.Material.Cobblestone, 72)
	annulus(folder, "Edge", cfg.Center.PromenadeOuter - 0.6, cfg.Center.PromenadeOuter + 0.4, TOP + 0.05, PAVING_DARK, Enum.Material.Concrete, 72)
	-- Dekoration rund um den Kreisverkehr, nicht auf den Einmündungen
	local r = (cfg.RoundaboutOuter + cfg.Center.PromenadeOuter) / 2 + 2
	local n = 0
	for deg = 0, 359, 8 do
		local a = math.rad(deg)
		local p = Vector3.new(c.X + math.cos(a) * r, TOP, c.Z + math.sin(a) * r)
		if spokeDistance(p) < cfg.RoadWidth / 2 + 8 then
			continue
		end
		n += 1
		local face = CFrame.lookAt(p, Vector3.new(c.X, TOP, c.Z))
		local kind = n % 3
		if kind == 1 then
			flowerBed(folder, `Bed{n}`, face, 6, 2.4, rng)
		elseif kind == 2 then
			bench(folder, `Bench{n}`, face * CFrame.Angles(0, math.rad(180), 0))
		else
			EnvironmentBuilder.streetLamp(folder, `Lamp{n}`, CFrame.lookAt(p + (p - Vector3.new(c.X, TOP, c.Z)).Unit * 4, Vector3.new(c.X, TOP, c.Z)))
		end
	end
end

-- Gehwege und Laternen entlang der Speichen innerhalb des Platzes
local function sidewalks(parent: Instance)
	local cfg = LayoutConfig
	local c = cfg.MapCenter
	local folder = Instance.new("Folder")
	folder.Name = "Sidewalks"
	folder.Parent = parent
	local w = cfg.Center.SidewalkWidth
	for i, s in spokes do
		local d = s.dir
		-- t-Bereich: vom Platzrand bis zur Promenade
		local t0, t1 = hitT(s.origin, d, cfg.CenterPlazaRadius), hitT(s.origin, d, cfg.Center.PromenadeOuter)
		local len = t1 - t0
		local mid = s.origin + d * ((t0 + t1) / 2)
		local cf = CFrame.lookAt(mid, mid + d)
		for _, side in { -1, 1 } do
			flat(folder, `Walk{i}{side}`, Vector2.new(w, len), cf * CFrame.new(side * (cfg.RoadWidth / 2 + w / 2), 0, 0), TOP + 0.03, PAVING, Enum.Material.Pavement)
			local count = math.floor(len / 34)
			for k = 1, count do
				local z = -len / 2 + (k - 0.5) * (len / count) + (if side > 0 then 8 else -8)
				EnvironmentBuilder.streetLamp(folder, `Lamp{i}{side}{k}`, cf * CFrame.new(side * (cfg.RoadWidth / 2 + w - 1), 0, z) * CFrame.Angles(0, math.rad(if side > 0 then 90 else -90), 0))
			end
		end
	end
end

local function fence(parent: Instance)
	local cfg = LayoutConfig
	local c = cfg.MapCenter
	local folder = Instance.new("Folder")
	folder.Name = "Fence"
	folder.Parent = parent
	local R = cfg.Center.FenceRadius
	local segLen = 8
	local segments = math.floor(2 * math.pi * R / segLen)
	for i = 1, segments do
		local a = (i - 0.5) / segments * math.pi * 2
		local p = Vector3.new(c.X + math.cos(a) * R, TOP, c.Z + math.sin(a) * R)
		if spokeDistance(p) < cfg.RoadWidth / 2 + cfg.Center.SidewalkWidth + 2 or inRect(p) then
			continue
		end
		local cf = CFrame.new(p) * CFrame.Angles(0, -a, 0)
		part(folder, `Post{i}`, Vector3.new(0.6, 3.2, 0.6), cf * CFrame.new(0, 1.6, -segLen / 2), WOOD_DARK, Enum.Material.Wood)
		for k, y in { 1.2, 2.5 } do
			part(folder, `Rail{i}_{k}`, Vector3.new(0.3, 0.4, segLen), cf * CFrame.new(0, y, 0), WOOD, Enum.Material.Wood)
		end
	end
end

-- Teich mit Sandufer, Steinen, Schilf und Bänken
local function pond(parent: Instance, name: string, pos: Vector3, radius: number, rng: Random)
	local m = Instance.new("Model")
	m.Name = name
	disc(m, "Shore", radius + 3, 0.12, pos, TOP + 0.06, SAND, Enum.Material.Sand).CanCollide = false
	local water = disc(m, "Water", radius, 0.12, pos, TOP + 0.1, WATER, Enum.Material.Glass)
	water.Transparency = 0.2
	water.Reflectance = 0.15
	water.CanCollide = false
	for i = 1, 9 do
		local a = rng:NextNumber(0, math.pi * 2)
		EnvironmentBuilder.boulder(m, `Stone{i}`, pos + Vector3.new(math.cos(a) * (radius + 2), TOP, math.sin(a) * (radius + 2)) - Vector3.new(0, pos.Y, 0), rng:NextNumber(1.2, 2.6), rng)
	end
	for i = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local p = pos + Vector3.new(math.cos(a) * (radius - 1), 0, math.sin(a) * (radius - 1))
		local reed = part(m, `Reed{i}`, Vector3.new(0.25, rng:NextNumber(2, 3.4), 0.25), CFrame.new(p.X, TOP + 1.2, p.Z) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2)), LEAF[3], Enum.Material.Grass)
		reed.CanCollide = false
	end
	for i, a in { 0.6, 2.4, 4.4 } do
		local p = pos + Vector3.new(math.cos(a) * (radius + 6), 0, math.sin(a) * (radius + 6))
		bench(m, `Bench{i}`, CFrame.lookAt(Vector3.new(p.X, TOP, p.Z), Vector3.new(pos.X, TOP, pos.Z)) * CFrame.Angles(0, math.rad(180), 0))
	end
	m.Parent = parent
	occupy(CFrame.new(pos.X, TOP, pos.Z), Vector2.new(radius * 2 + 16, radius * 2 + 16), 0)
end

-- Kiesweg von der Promenade nach außen bis zu einem Ziel
local function path(parent: Instance, name: string, from: Vector3, to: Vector3)
	local mid = (from + to) / 2
	local len = (Vector3.new(to.X, 0, to.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude
	flat(parent, name, Vector2.new(5, len), CFrame.lookAt(Vector3.new(mid.X, TOP, mid.Z), Vector3.new(to.X, TOP, to.Z)), TOP + 0.03, GRAVEL, Enum.Material.Pebble)
end

function CenterBuilder.build(parent: Instance): Folder
	local cfg = LayoutConfig
	local cc = cfg.Center
	local c = cfg.MapCenter
	local rng = Random.new(cc.Seed)
	local folder = Instance.new("Folder")
	folder.Name = "CenterArea"
	table.clear(rects)

	-- Wiese über der alten Pflasterfläche
	disc(folder, "Lawn", cfg.CenterPlazaRadius, 0.1, Vector3.new(c.X, 0, c.Z), TOP + 0.01, GRASS, Enum.Material.Grass).CanCollide = false

	-- Belegte Flächen: Shops (Eingang zur Mitte), Hütten, Wahrzeichen
	for _, shop in { cfg.EquipmentShop, cfg.MachineShop, cfg.VehicleShop } do
		local pos = Vector3.new(c.X + shop.Offset.X, TOP, c.Z + shop.Offset.Y)
		local sector = (shop :: any).SectorAngle
		local cf = if typeof(sector) == "number"
			then CFrame.lookAt(pos, pos - sectorFrame(sector).LookVector)
			else CFrame.lookAt(pos, Vector3.new(c.X, TOP, c.Z))
		occupy(cf, Vector2.new(shop.Size.X, shop.Size.Z), 4)
		-- Vorplatz mit Blumenkästen links und rechts vom Eingang
		local front = cf * CFrame.new(0, 0, -shop.Size.Z / 2 - 4)
		flat(folder, "Forecourt", Vector2.new(shop.Size.X, 8), front, TOP + 0.04, PAVING, Enum.Material.Pavement)
		for _, sx in { -1, 1 } do
			flowerBed(folder, "ShopBed", front * CFrame.new(sx * (shop.Size.X / 2 - 4), 0, 1), 6, 2, rng)
		end
		occupy(front, Vector2.new(shop.Size.X, 8), 1)
	end
	-- Zufahrt zum LKW-Laden (D-058) bleibt frei, auch am Zaun
	do
		local t = cfg.TruckShop
		local pos = Vector3.new(c.X + t.Offset.X, TOP, c.Z + t.Offset.Y)
		local o = CFrame.lookAt(pos, pos - sectorFrame(t.SectorAngle).LookVector)
		-- Halle mit Vorplatz und Zufahrt (die Halle steht seit 2026-10-25 innerhalb des Zauns)
		occupy(o, Vector2.new(t.Size.X, t.Size.Z), 4)
		local len = t.DrivewayLength + t.ApronDepth
		occupy(o * CFrame.new(0, 0, -t.Size.Z / 2 - len / 2), Vector2.new(math.max(t.DrivewayWidth, t.Size.X), len), 3)
	end
	for _, pos in cfg.Environment.Cabins do
		occupy(CFrame.new(c.X + pos.X, TOP, c.Z + pos.Y), Vector2.new(24, 24), 6)
	end
	for _, pos in { cfg.Environment.WaterTower, cfg.Environment.Windmill } do
		occupy(CFrame.new(c.X + pos.X, TOP, c.Z + pos.Y), Vector2.new(20, 20), 2)
	end

	promenade(folder, rng)
	sidewalks(folder)
	fence(folder)

	-- Parkplätze vor den Shops: mittig zwischen den Straßen, zwischen Shop und Promenade
	local lots = Instance.new("Folder")
	lots.Name = "Parking"
	lots.Parent = folder
	for i, shop in { cfg.EquipmentShop, cfg.MachineShop, cfg.VehicleShop } do
		local sector = (shop :: any).SectorAngle
		local deg = if typeof(sector) == "number" then sector else math.deg(math.atan2(-shop.Offset.Y, shop.Offset.X))
		local frame = sectorFrame(deg)
		local depth = 2 * 9 + 2 * 8
		local outer = sectorFrame(deg).LookVector:Dot(Vector3.new(shop.Offset.X, 0, shop.Offset.Y)) - shop.Size.Z / 2 - 9
		local rMid = outer - depth / 2
		local lo1, hi1 = sectorSpan(frame, outer - depth)
		local lo2, hi2 = sectorSpan(frame, outer)
		local lo, hi = math.max(lo1, lo2), math.min(hi1, hi2)
		local stalls = math.min(cc.ShopLotStalls, math.floor((hi - lo - 14) / 4.6))
		if stalls >= 3 then
			parkingLot(lots, `ShopLot{i}`, frame * CFrame.new((lo + hi) / 2, 0, -rMid) * CFrame.Angles(0, math.rad(180), 0), stalls, 1, rng)
		end
	end
	-- Großer Parkplatz im freien Sektor
	do
		-- Doppelreihen nach außen gestaffelt; jede so breit, wie der Sektor dort Platz hat
		local frame = sectorFrame(cc.BigLotAngle)
		local inner = cc.PromenadeOuter + 10
		local block = 2 * 9 + 2 * 8
		local firstLo, firstHi = 0, 0
		for row = 1, cc.BigLotDoubleRows do
			local r0 = inner + (row - 1) * (block - 8)
			local lo1, hi1 = sectorSpan(frame, r0)
			local lo2, hi2 = sectorSpan(frame, r0 + block)
			local lo, hi = math.max(lo1, lo2), math.min(hi1, hi2)
			if row == 1 then
				firstLo, firstHi = lo, hi
			end
			local stalls = math.min(cc.BigLotMaxStalls, math.floor((hi - lo - 14) / 4.6))
			if stalls >= 3 then
				parkingLot(lots, `BigLot{row}`, frame * CFrame.new((lo + hi) / 2, 0, -(r0 + block / 2)) * CFrame.Angles(0, math.rad(180), 0), stalls, 1, rng)
			end
		end
		local _ = firstLo
		local sign = part(lots, "BigLotSign", Vector3.new(0.4, 6, 0.4), frame * CFrame.new(firstHi - 4, 3, -(inner - 3)), STEEL, Enum.Material.Metal)
		local board = part(lots, "BigLotBoard", Vector3.new(4, 4, 0.3), sign.CFrame * CFrame.new(0, 3.5, 0), Color3.fromRGB(40, 92, 170), Enum.Material.SmoothPlastic)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0.5
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = "P"
		label.Parent = gui
	end

	-- Park mit Teich und Garten mit Pavillon
	local parks = Instance.new("Folder")
	parks.Name = "Parks"
	parks.Parent = folder
	do
		local frame = sectorFrame(cc.PondAngle)
		local r = cc.PromenadeOuter + 40
		local lo, hi = sectorSpan(frame, r)
		local pos = (frame * CFrame.new((lo + hi) / 2, 0, -r)).Position
		pond(parks, "Pond", pos, 16, rng)
		path(parks, "PondPath", (frame * CFrame.new((lo + hi) / 2, 0, -cc.PromenadeOuter)).Position, pos)
	end
	do
		local frame = sectorFrame(cc.GardenAngle)
		local r = cc.GardenRadius
		local lo, hi = sectorSpan(frame, r)
		local cf = frame * CFrame.new((lo + hi) / 2, 0, -r)
		pavilion(parks, "Pavilion", cf, 16, 10, rng)
		occupy(cf, Vector2.new(40, 22), 4)
		-- Kiesweg vom Teich (gleicher Sektor) bis zum Pavillon
		path(parks, "GardenPath", (frame * CFrame.new((lo + hi) / 2, 0, -(cc.PromenadeOuter + 40 + 24))).Position, (cf * CFrame.new(0, 0, 7)).Position)
		-- Blumenreihen hinter dem Pavillon
		for k = 1, 3 do
			local bedCF = cf * CFrame.new(0, 0, -14 - k * 6)
			if isFree(bedCF.Position, 2) then
				flowerBed(parks, `GardenBed{k}`, bedCF, 14, 2.4, rng)
				occupy(bedCF, Vector2.new(14, 2.4), 2)
			end
		end
	end

	-- Bäume, Büsche und Blumen auf den freien Wiesenflächen
	local nature = Instance.new("Folder")
	nature.Name = "Nature"
	nature.Parent = folder
	local trees, tries = 0, 0
	local placedTrees: { Vector3 } = {}
	-- Alleen: Baumreihen hinter den Gehwegen, mit Blumen dazwischen
	for i, sp in spokes do
		local t0, t1 = hitT(sp.origin, sp.dir, cc.FenceRadius - 6), hitT(sp.origin, sp.dir, cc.PromenadeOuter + 8)
		local cf = CFrame.lookAt(sp.origin, sp.origin + sp.dir)
		local lateral = cfg.RoadWidth / 2 + cc.SidewalkWidth + 4
		for _, side in { -1, 1 } do
			local t = t0 + (if side > 0 then 4 else 15)
			local k = 0
			while t < t1 do
				k += 1
				local p = (cf * CFrame.new(side * lateral, 0, -t)).Position
				if not inRect(p) then
					EnvironmentBuilder.pine(nature, 9000 + i * 100 + k * 2 + (side + 1) / 2, p, rng:NextNumber(0.7, 0.9), rng)
					table.insert(placedTrees, p)
					local f = (cf * CFrame.new(side * lateral, 0, -t - cc.AlleySpacing / 2)).Position
					if not inRect(f) then
						flowerPatch(nature, `AlleyFlowers{i}_{side}_{k}`, f, 1.8, 7, rng)
					end
				end
				t += cc.AlleySpacing
			end
		end
	end
	while trees < cc.TreeCount and tries < cc.TreeCount * 30 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber((cc.PromenadeOuter + 6) ^ 2, (cc.FenceRadius - 4) ^ 2))
		local p = Vector3.new(c.X + math.cos(a) * r, TOP, c.Z + math.sin(a) * r)
		if not isFree(p, 4) then
			continue
		end
		local tooClose = false
		for _, q in placedTrees do
			if (q - p).Magnitude < 9 then
				tooClose = true
				break
			end
		end
		if tooClose then
			continue
		end
		trees += 1
		table.insert(placedTrees, p)
		EnvironmentBuilder.pine(nature, 7000 + trees, p, rng:NextNumber(0.6, 1.15), rng)
	end
	local bushes = 0
	tries = 0
	while bushes < cc.BushCount and tries < cc.BushCount * 30 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(cc.PromenadeOuter + 4, cc.FenceRadius - 2)
		local p = Vector3.new(c.X + math.cos(a) * r, TOP, c.Z + math.sin(a) * r)
		if isFree(p, 1.5) then
			bushes += 1
			bush(nature, `Bush{bushes}`, p, rng:NextNumber(2, 3.6), rng)
			if rng:NextNumber() < 0.5 then
				flowerPatch(nature, `Flowers{bushes}`, p + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), 1.6, 6, rng)
			end
		end
	end
	local rocks = 0
	tries = 0
	while rocks < cc.RockCount and tries < cc.RockCount * 30 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(cc.FenceRadius - 40, cc.FenceRadius - 6)
		local p = Vector3.new(c.X + math.cos(a) * r, TOP, c.Z + math.sin(a) * r)
		if isFree(p, 3) then
			rocks += 1
			EnvironmentBuilder.boulder(nature, `Rock{rocks}`, p, rng:NextNumber(2.5, 5), rng)
		end
	end

	folder.Parent = parent
	return folder
end

-- Für Planung/Tests: freie seitliche Spanne eines Sektors in Entfernung r
function CenterBuilder.sectorSpan(deg: number, r: number): (number, number)
	return sectorSpan(sectorFrame(deg), r)
end

return table.freeze(CenterBuilder)
