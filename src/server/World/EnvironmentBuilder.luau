--!strict
-- Umgebung der Map (Phase 13a, docs/19 §4, MAP_MASTERPLAN_TOPDOWN.png, CENTRAL_AREA_REFERENCE.png):
-- Wiese statt Baseplate, Bergkette mit Schneegipfeln rund um die Map, Nadelwald, Felsen, Seen
-- zwischen den Plots, Straßenmarkierungen und Laternen an den Zufahrten, Platz mit Brunnen,
-- Wasserturm und Windrad. Reine Optik: keine Spiellogik hängt davon ab.
--
-- Alles wird deterministisch (fester Zufalls-Seed) aus LayoutConfig abgeleitet, damit jeder Server
-- dieselbe Welt baut. Bäume/Felsen meiden Plots, Straßen, Platz, Seen und die Bergkette.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local GameConfig = require(Shared.Config.GameConfig)

local EnvironmentBuilder = {}

local GRASS = Color3.fromRGB(92, 138, 70)
local GRASS_DARK = Color3.fromRGB(70, 112, 56)
local BARK = Color3.fromRGB(92, 64, 44)
local NEEDLES = { Color3.fromRGB(44, 92, 52), Color3.fromRGB(38, 82, 48), Color3.fromRGB(54, 104, 58) }
local ROCK = Color3.fromRGB(118, 116, 112)
local ROCK_DARK = Color3.fromRGB(92, 90, 88)
local SNOW = Color3.fromRGB(240, 244, 248)
local WATER = Color3.fromRGB(62, 128, 168)
local SAND = Color3.fromRGB(196, 178, 132)
local PAVING = Color3.fromRGB(176, 170, 160)
local PAVING_DARK = Color3.fromRGB(140, 134, 126)
local LINE_YELLOW = Color3.fromRGB(232, 190, 56)
local LINE_WHITE = Color3.fromRGB(236, 236, 232)
local STEEL = Color3.fromRGB(58, 62, 68)
local LAMP = Color3.fromRGB(255, 232, 186)
local WOOD = Color3.fromRGB(122, 86, 56)

-- Bodenoberkante der Umgebung: knapp unter Plots/Straßen/Platz (Oberkante 1.0), über der Baseplate
local GROUND_TOP = LayoutConfig.GroundY + 0.9
local TOP = LayoutConfig.GroundY + 1

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

-- Flache Scheibe (Zylinder liegend) mit Oberkante bei topY
local function disc(parent: Instance, name: string, radius: number, thickness: number, x: number, z: number, topY: number, color: Color3, material: Enum.Material): Part
	return part(parent, name, Vector3.new(thickness, radius * 2, radius * 2), CFrame.new(x, topY - thickness / 2, z) * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
end

-- Plot-CFrame wie PlotBuilder.getPlotCFrame (Mitte, -Z zur Map-Mitte)
local function plotCFrame(plotId: number): CFrame
	local center = LayoutConfig.MapCenter
	local angle = math.rad(LayoutConfig.PlotAngles[plotId])
	local pos = Vector3.new(center.X + math.cos(angle) * LayoutConfig.PlotRingRadius, LayoutConfig.GroundY, center.Z - math.sin(angle) * LayoutConfig.PlotRingRadius)
	return CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
end

-- Sperrflächen für Bäume/Felsen
type Blocker = (p: Vector3) -> boolean
local function makeBlockers(lakes: { Vector3 }): { Blocker }
	local cfg = LayoutConfig
	local plots = {}
	for plotId = 1, GameConfig.MaxPlots do
		table.insert(plots, plotCFrame(plotId))
	end
	local halfX, halfZ = cfg.PlotSize.X / 2, cfg.PlotSize.Y / 2
	local roadLen = cfg.PlotRingRadius - halfZ - cfg.CenterPlazaRadius
	return {
		-- Plots mit Rand
		function(p)
			for _, cf in plots do
				local l = cf:PointToObjectSpace(p)
				if math.abs(l.X) < halfX + 18 and math.abs(l.Z) < halfZ + 18 then
					return true
				end
			end
			return false
		end,
		-- Zufahrtsstraßen mit Gehweg/Laternen
		function(p)
			for _, cf in plots do
				local l = cf:PointToObjectSpace(p)
				if math.abs(l.X - cfg.DoorCenterX) < cfg.RoadWidth / 2 + 14 and l.Z < -halfZ + 10 and l.Z > -halfZ - roadLen - 10 then
					return true
				end
			end
			return false
		end,
		-- Platz in der Mitte
		function(p)
			return Vector2.new(p.X - cfg.MapCenter.X, p.Z - cfg.MapCenter.Z).Magnitude < cfg.CenterPlazaRadius + 14
		end,
		-- Freiflächen um Wasserturm und Windrad
		function(p)
			for _, spot in cfg.Environment.LandmarkClearings do
				if Vector2.new(p.X - spot.X, p.Z - spot.Z).Magnitude < spot.Y then
					return true
				end
			end
			return false
		end,
		-- Seen
		function(p)
			for _, lake in lakes do
				if Vector2.new(p.X - lake.X, p.Z - lake.Z).Magnitude < lake.Y + 14 then
					return true
				end
			end
			return false
		end,
	}
end

local function blocked(blockers: { Blocker }, p: Vector3): boolean
	for _, b in blockers do
		if b(p) then
			return true
		end
	end
	return false
end

-- Nadelbaum: Stamm und vier gestufte Nadelscheiben
local function pine(parent: Instance, index: number, pos: Vector3, scale: number, rng: Random)
	local tree = Instance.new("Model")
	tree.Name = `Pine{index}`
	local trunkH = 5 * scale
	local trunk = part(tree, "Trunk", Vector3.new(trunkH, 1.4 * scale, 1.4 * scale), CFrame.new(pos + Vector3.new(0, trunkH / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), BARK, Enum.Material.Wood, Enum.PartType.Cylinder)
	trunk.CanCollide = true
	local color = NEEDLES[rng:NextInteger(1, #NEEDLES)]
	local radii = { 6, 4.8, 3.5, 2.2 }
	for i, r in radii do
		local y = trunkH - 0.6 * scale + (i - 1) * 2.9 * scale
		local layer = part(tree, `Needles{i}`, Vector3.new(3.4 * scale, r * 2 * scale, r * 2 * scale), CFrame.new(pos + Vector3.new(0, y + 1.7 * scale, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), math.rad(90)), color:Lerp(Color3.new(0, 0, 0), (i - 1) * -0.02), Enum.Material.Grass, Enum.PartType.Cylinder)
		layer.CanCollide = false
		layer.CastShadow = true
	end
	local tip = part(tree, "Tip", Vector3.new(1.6 * scale, 2.2 * scale, 1.6 * scale), CFrame.new(pos + Vector3.new(0, trunkH + 12.4 * scale, 0)), color, Enum.Material.Grass)
	tip.CanCollide = false
	tree.PrimaryPart = trunk
	tree.Parent = parent
end

local function boulder(parent: Instance, name: string, pos: Vector3, size: number, rng: Random)
	local r = part(parent, name, Vector3.new(size * rng:NextNumber(0.9, 1.4), size * rng:NextNumber(0.6, 0.9), size * rng:NextNumber(0.9, 1.3)), CFrame.new(pos + Vector3.new(0, size * 0.25, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.4, 0.4)), if rng:NextNumber() < 0.5 then ROCK else ROCK_DARK, Enum.Material.Rock)
	r.CanCollide = true
end

-- Berg aus mehreren gekippten Felsblöcken; die oberste Spitze ist verschneit. Die Schneekappe
-- teilt Lage und Ausrichtung des obersten Blocks und sitzt genau in dessen oberer Ecke.
local function mountain(parent: Instance, index: number, pos: Vector3, height: number, rng: Random)
	local m = Instance.new("Model")
	m.Name = `Mountain{index}`
	local base = height * 1.1
	local top: Part? = nil
	for i = 1, 3 do
		local s = base * (1 - (i - 1) * 0.22)
		local offset = Vector3.new(rng:NextNumber(-0.2, 0.2) * base, 0, rng:NextNumber(-0.2, 0.2) * base)
		top = part(m, `Rock{i}`, Vector3.new(s, s, s), CFrame.new(pos + offset + Vector3.new(0, height * (0.05 + (i - 1) * 0.18), 0)) * CFrame.Angles(math.rad(rng:NextNumber(35, 50)), rng:NextNumber(0, math.pi * 2), math.rad(rng:NextNumber(35, 50))), if i == 1 then ROCK_DARK else ROCK, Enum.Material.Rock)
	end
	local rock = top :: Part
	-- höchste Ecke des obersten Blocks
	local best, bestY = Vector3.zero, -math.huge
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = rock.CFrame:VectorToWorldSpace(Vector3.new(sx, sy, sz) * rock.Size / 2)
				if corner.Y > bestY then
					best, bestY = corner, corner.Y
				end
			end
		end
	end
	local k = 0.38
	part(m, "Snow", rock.Size * k * 1.03, (rock.CFrame - rock.Position) + rock.Position + best * (1 - k), SNOW, Enum.Material.Snow)
	m.Parent = parent
end

local function lake(parent: Instance, index: number, center: Vector3, radius: number)
	local folder = Instance.new("Folder")
	folder.Name = `Lake{index}`
	folder.Parent = parent
	-- drei überlappende Kreise ergeben eine natürliche Form
	local blobs = { Vector3.new(0, 0, 0), Vector3.new(radius * 0.45, 0, radius * 0.2), Vector3.new(-radius * 0.35, 0, -radius * 0.3) }
	for i, o in blobs do
		local r = radius * (if i == 1 then 1 else 0.7)
		disc(folder, `Shore{i}`, r + 4, 0.2, center.X + o.X, center.Z + o.Z, GROUND_TOP + 0.04 + i * 0.002, SAND, Enum.Material.Sand)
		local w = disc(folder, `Water{i}`, r, 0.2, center.X + o.X, center.Z + o.Z, GROUND_TOP + 0.08 + i * 0.002, WATER, Enum.Material.Glass)
		w.Transparency = 0.15
		w.Reflectance = 0.15
		w.CanCollide = false
	end
end

local function streetLamp(parent: Instance, name: string, cf: CFrame)
	local lamp = Instance.new("Model")
	lamp.Name = name
	part(lamp, "Base", Vector3.new(1.2, 0.6, 1.2), cf * CFrame.new(0, 0.3, 0), STEEL, Enum.Material.Metal)
	part(lamp, "Pole", Vector3.new(0.45, 12, 0.45), cf * CFrame.new(0, 6.3, 0), STEEL, Enum.Material.Metal)
	part(lamp, "Arm", Vector3.new(0.3, 0.3, 3), cf * CFrame.new(0, 12.1, -1.4), STEEL, Enum.Material.Metal)
	local head = part(lamp, "Head", Vector3.new(1.4, 0.5, 1.8), cf * CFrame.new(0, 11.8, -2.8), STEEL, Enum.Material.Metal)
	local bulb = part(lamp, "Bulb", Vector3.new(1.1, 0.12, 1.4), cf * CFrame.new(0, 11.5, -2.8), LAMP, Enum.Material.Neon)
	bulb.CanCollide = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Range = 26
	light.Angle = 110
	light.Brightness = 1
	light.Color = LAMP
	light.Parent = bulb
	head.CanCollide = false
	lamp.Parent = parent
end

-- Markierungen und Laternen an einer Zufahrtsstraße (Straße selbst baut PlotBuilder)
local function roadDetails(parent: Instance, plotId: number)
	local cfg = LayoutConfig
	local cf = plotCFrame(plotId)
	local halfZ = cfg.PlotSize.Y / 2
	local length = cfg.PlotRingRadius - halfZ - cfg.CenterPlazaRadius
	local x = cfg.DoorCenterX
	local folder = Instance.new("Folder")
	folder.Name = `RoadDetails{plotId}`
	folder.Parent = parent
	local roadTop = cfg.GroundY + 1.05
	-- Mittellinie gestrichelt, Randlinien durchgehend, Gehwege mit Bordstein
	local dash, gap = 6, 6
	local z = -halfZ - 4
	local i = 0
	while z - dash > -halfZ - length + 4 do
		i += 1
		local d = part(folder, `CenterDash{i}`, Vector3.new(0.5, 0.04, dash), cf * CFrame.new(x, roadTop + 0.02, z - dash / 2), LINE_YELLOW, Enum.Material.SmoothPlastic)
		d.CanCollide = false
		z -= dash + gap
	end
	for _, side in { -1, 1 } do
		local edge = part(folder, `EdgeLine{side}`, Vector3.new(0.4, 0.04, length), cf * CFrame.new(x + side * (cfg.RoadWidth / 2 - 1.2), roadTop + 0.02, -halfZ - length / 2), LINE_WHITE, Enum.Material.SmoothPlastic)
		edge.CanCollide = false
		part(folder, `Sidewalk{side}`, Vector3.new(5, 1.2, length), cf * CFrame.new(x + side * (cfg.RoadWidth / 2 + 2.5), cfg.GroundY + 0.6, -halfZ - length / 2), PAVING, Enum.Material.Pavement)
		part(folder, `Curb{side}`, Vector3.new(0.6, 1.3, length), cf * CFrame.new(x + side * (cfg.RoadWidth / 2 + 0.3), cfg.GroundY + 0.65, -halfZ - length / 2), PAVING_DARK, Enum.Material.Concrete)
		-- Laternen versetzt auf beiden Seiten
		local count = math.floor(length / 36)
		for n = 1, count do
			local lz = -halfZ - (n - 0.5) * (length / count) + (if side > 0 then 9 else -9)
			streetLamp(folder, `Lamp{side}_{n}`, cf * CFrame.new(x + side * (cfg.RoadWidth / 2 + 3.6), cfg.GroundY + 1.2, lz) * CFrame.Angles(0, math.rad(if side > 0 then 90 else -90), 0))
		end
	end
end

-- Brunnen mit Beeten, Bänken und Laternen in der Platzmitte
local function plazaCenter(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Plaza"
	folder.Parent = parent
	local c = LayoutConfig.MapCenter
	disc(folder, "PlazaRing", 32, 0.1, c.X, c.Z, TOP + 0.05, PAVING_DARK, Enum.Material.Cobblestone)
	disc(folder, "PlazaInner", 26, 0.1, c.X, c.Z, TOP + 0.07, PAVING, Enum.Material.Cobblestone)
	-- Brunnen: Becken, Wasser, Säule mit zwei Schalen
	disc(folder, "FountainRim", 10, 1.6, c.X, c.Z, TOP + 1.7, Color3.fromRGB(160, 150, 136), Enum.Material.Concrete)
	local water = disc(folder, "FountainWater", 9.2, 0.3, c.X, c.Z, TOP + 1.75, WATER, Enum.Material.Glass)
	water.Transparency = 0.2
	water.CanCollide = false
	part(folder, "FountainColumn", Vector3.new(6, 1.8, 1.8), CFrame.new(c.X, TOP + 4.5, c.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(170, 160, 146), Enum.Material.Concrete, Enum.PartType.Cylinder)
	disc(folder, "FountainBowl1", 4.2, 0.7, c.X, c.Z, TOP + 5.2, Color3.fromRGB(170, 160, 146), Enum.Material.Concrete)
	part(folder, "FountainColumn2", Vector3.new(3, 1, 1), CFrame.new(c.X, TOP + 6.5, c.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(170, 160, 146), Enum.Material.Concrete, Enum.PartType.Cylinder)
	disc(folder, "FountainBowl2", 2.2, 0.5, c.X, c.Z, TOP + 8, Color3.fromRGB(170, 160, 146), Enum.Material.Concrete)
	local spout = part(folder, "FountainSpout", Vector3.new(0.8, 2.4, 0.8), CFrame.new(c.X, TOP + 9.2, c.Z), WATER, Enum.Material.Glass)
	spout.Transparency = 0.35
	spout.CanCollide = false
	local splash = Instance.new("ParticleEmitter")
	splash.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	splash.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	splash.Size = NumberSequence.new(0.4, 0.1)
	splash.Transparency = NumberSequence.new(0.3, 1)
	splash.Lifetime = NumberRange.new(0.8, 1.2)
	splash.Rate = 30
	splash.Speed = NumberRange.new(6, 9)
	splash.SpreadAngle = Vector2.new(25, 25)
	splash.Acceleration = Vector3.new(0, -20, 0)
	splash.Parent = spout
	-- Beete mit Bäumen, Bänke und Laternen im Kreis
	local rng = Random.new(5)
	for i = 0, 5 do
		local a = math.rad(i * 60 + 30)
		local px, pz = c.X + math.cos(a) * 20, c.Z + math.sin(a) * 20
		part(folder, `Planter{i}`, Vector3.new(6, 1.2, 6), CFrame.new(px, TOP + 0.6, pz) * CFrame.Angles(0, -a, 0), WOOD, Enum.Material.WoodPlanks)
		part(folder, `PlanterSoil{i}`, Vector3.new(5.4, 0.2, 5.4), CFrame.new(px, TOP + 1.25, pz) * CFrame.Angles(0, -a, 0), GRASS_DARK, Enum.Material.Grass)
		pine(folder, 1000 + i, Vector3.new(px, TOP + 1.2, pz), 0.55, rng)
		local ba = math.rad(i * 60)
		local bench = CFrame.new(c.X + math.cos(ba) * 24, TOP, c.Z + math.sin(ba) * 24) * CFrame.Angles(0, -ba + math.rad(90), 0)
		part(folder, `BenchSeat{i}`, Vector3.new(5, 0.3, 1.6), bench * CFrame.new(0, 1.5, 0), WOOD, Enum.Material.Wood)
		part(folder, `BenchBack{i}`, Vector3.new(5, 1.4, 0.3), bench * CFrame.new(0, 2.3, 0.75), WOOD, Enum.Material.Wood)
		for _, dx in { -2, 2 } do
			part(folder, `BenchLeg{i}_{dx}`, Vector3.new(0.3, 1.4, 1.4), bench * CFrame.new(dx, 0.7, 0), STEEL, Enum.Material.Metal)
		end
		streetLamp(folder, `PlazaLamp{i}`, CFrame.new(c.X + math.cos(a) * 29, TOP, c.Z + math.sin(a) * 29) * CFrame.Angles(0, -a - math.rad(90), 0))
	end
end

-- Parkplätze vor den Shops und Grüninseln in den freien Sektoren des Platzes (Referenzbild)
local function plazaDressing(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "PlazaDressing"
	folder.Parent = parent
	local cfg = LayoutConfig
	local c = cfg.MapCenter
	local rng = Random.new(cfg.Environment.Seed + 7)
	-- Parkplatz vor einem Shop: Asphalt mit weißen Stellplatzlinien, quer zur Blickrichtung
	local function parking(name: string, shop: { Offset: Vector2, Size: Vector3 }, stalls: number)
		local pos = Vector3.new(c.X + shop.Offset.X, TOP, c.Z + shop.Offset.Y)
		local toCenter = (Vector3.new(c.X, TOP, c.Z) - pos).Unit
		local frontDist = shop.Size.Z / 2 + 12 + 9
		local lotCF = CFrame.lookAt(pos + toCenter * frontDist, pos + toCenter * (frontDist + 1))
		local width = stalls * 4.6
		part(folder, `{name}Lot`, Vector3.new(width + 2, 0.08, 18), lotCF * CFrame.new(0, 0.04, 0), Color3.fromRGB(64, 66, 70), Enum.Material.Asphalt).CanCollide = false
		for i = 0, stalls do
			local line = part(folder, `{name}Stall{i}`, Vector3.new(0.3, 0.04, 9), lotCF * CFrame.new(-width / 2 + i * 4.6, 0.1, 4), LINE_WHITE, Enum.Material.SmoothPlastic)
			line.CanCollide = false
		end
		local back = part(folder, `{name}BackLine`, Vector3.new(width, 0.04, 0.3), lotCF * CFrame.new(0, 0.1, 8.5), LINE_WHITE, Enum.Material.SmoothPlastic)
		back.CanCollide = false
	end
	parking("VehicleShop", cfg.VehicleShop, 6)
	parking("MachineShop", cfg.MachineShop, 5)
	parking("EquipmentShop", cfg.EquipmentShop, 5)
	-- Baumreihe am Platzrand, ausgenommen Straßeneinmündungen und Shops
	local function angleFree(deg: number): boolean
		local function near(target: number, width: number): boolean
			local d = math.abs(((deg - target + 180) % 360) - 180)
			return d < width
		end
		for _, roadAngle in cfg.PlotAngles do
			if near(roadAngle, 11) then
				return false
			end
		end
		for _, sector in { { 0, 34 }, { 61, 24 }, { 180, 20 }, { 270, 18 } } do
			if near(sector[1], sector[2]) then
				return false
			end
		end
		return true
	end
	for deg = 0, 359, 9 do
		if angleFree(deg) then
			local a = math.rad(deg)
			local r = cfg.CenterPlazaRadius - 9
			local tx, tz = c.X + math.cos(a) * r, c.Z - math.sin(a) * r
			part(folder, `EdgePlanter{deg}`, Vector3.new(5, 1, 5), CFrame.new(tx, TOP + 0.5, tz) * CFrame.Angles(0, a, 0), WOOD, Enum.Material.WoodPlanks)
			part(folder, `EdgePlanterSoil{deg}`, Vector3.new(4.4, 0.2, 4.4), CFrame.new(tx, TOP + 1.05, tz) * CFrame.Angles(0, a, 0), GRASS_DARK, Enum.Material.Grass)
			pine(folder, 3000 + deg, Vector3.new(tx, TOP + 1, tz), rng:NextNumber(0.55, 0.75), rng)
		end
	end
	-- Grüninseln mit Bäumen, Felsen, Bank und Laterne
	for i, angle in { 125, 225, 305 } do
		local a = math.rad(angle)
		local ix, iz = c.X + math.cos(a) * 100, c.Z - math.sin(a) * 100
		disc(folder, `Island{i}Curb`, 21, 0.5, ix, iz, TOP + 0.45, PAVING_DARK, Enum.Material.Concrete)
		disc(folder, `Island{i}`, 20, 0.5, ix, iz, TOP + 0.5, GRASS, Enum.Material.Grass)
		for t = 1, 4 do
			local ta = rng:NextNumber(0, math.pi * 2)
			local tr = rng:NextNumber(4, 14)
			pine(folder, 2000 + i * 10 + t, Vector3.new(ix + math.cos(ta) * tr, TOP + 0.5, iz + math.sin(ta) * tr), rng:NextNumber(0.7, 1.1), rng)
		end
		boulder(folder, `Island{i}Rock`, Vector3.new(ix + rng:NextNumber(-8, 8), TOP + 0.5, iz + rng:NextNumber(-8, 8)), rng:NextNumber(2.5, 4), rng)
		local toCenter = -a + math.rad(90)
		local bench = CFrame.new(ix - math.cos(a) * 16, TOP + 0.5, iz + math.sin(a) * 16) * CFrame.Angles(0, toCenter + math.rad(180), 0)
		part(folder, `Island{i}BenchSeat`, Vector3.new(5, 0.3, 1.6), bench * CFrame.new(0, 1.5, 0), WOOD, Enum.Material.Wood)
		part(folder, `Island{i}BenchBack`, Vector3.new(5, 1.4, 0.3), bench * CFrame.new(0, 2.3, 0.75), WOOD, Enum.Material.Wood)
		streetLamp(folder, `Island{i}Lamp`, CFrame.new(ix - math.cos(a) * 18 + 4, TOP + 0.5, iz + math.sin(a) * 18) * CFrame.Angles(0, toCenter, 0))
	end
end

-- Wasserturm (hinter dem Machine-Shop) und Windrad (hinter dem Fahrzeughaus), wie im Referenzbild
local function landmarks(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Landmarks"
	folder.Parent = parent
	local c = LayoutConfig.MapCenter
	-- Wasserturm
	local a = math.rad(62)
	local tower = CFrame.new(c.X + math.cos(a) * 185, GROUND_TOP, c.Z - math.sin(a) * 185)
	for _, dx in { -4, 4 } do
		for _, dz in { -4, 4 } do
			part(folder, `TowerLeg{dx}_{dz}`, Vector3.new(0.8, 26, 0.8), tower * CFrame.new(dx, 13, dz), WOOD, Enum.Material.Wood)
		end
	end
	for level = 1, 3 do
		for _, rot in { 0, 90 } do
			part(folder, `TowerBrace{level}_{rot}`, Vector3.new(0.4, 0.4, 11.5), tower * CFrame.Angles(0, math.rad(rot), 0) * CFrame.new(0, level * 7, 0), WOOD, Enum.Material.Wood)
		end
	end
	part(folder, "TowerTank", Vector3.new(10, 13, 13), tower * CFrame.new(0, 31, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 110, 76), Enum.Material.WoodPlanks, Enum.PartType.Cylinder)
	for _, y in { 27.5, 31, 34.5 } do
		part(folder, `TowerBand{y}`, Vector3.new(0.4, 13.3, 13.3), tower * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	part(folder, "TowerRoof", Vector3.new(8, 8, 8), tower * CFrame.new(0, 38.5, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0), Color3.fromRGB(110, 90, 72), Enum.Material.WoodPlanks)
	-- Windrad
	local w = CFrame.new(c.X + 190, GROUND_TOP, c.Z - 6) * CFrame.Angles(0, math.rad(-90), 0)
	for _, dx in { -3, 3 } do
		part(folder, `MillLeg{dx}`, Vector3.new(0.6, 34, 0.6), w * CFrame.new(dx, 17, 0) * CFrame.Angles(0, 0, math.rad(-dx * 1.2)), STEEL, Enum.Material.Metal)
		part(folder, `MillLegB{dx}`, Vector3.new(0.6, 34, 0.6), w * CFrame.new(0, 17, dx) * CFrame.Angles(math.rad(dx * 1.2), 0, 0), STEEL, Enum.Material.Metal)
	end
	part(folder, "MillHub", Vector3.new(1.4, 1.6, 1.6), w * CFrame.new(0, 34, -1.6) * CFrame.Angles(0, math.rad(90), 0), STEEL, Enum.Material.Metal, Enum.PartType.Cylinder)
	for i = 0, 11 do
		part(folder, `MillBlade{i}`, Vector3.new(0.2, 7, 1.4), w * CFrame.new(0, 34, -2.1) * CFrame.Angles(0, 0, math.rad(i * 30)) * CFrame.new(0, 4.4, 0) * CFrame.Angles(0, math.rad(20), 0), Color3.fromRGB(200, 196, 188), Enum.Material.Metal)
	end
	part(folder, "MillTail", Vector3.new(0.2, 3, 5), w * CFrame.new(0, 34, 3), Color3.fromRGB(200, 196, 188), Enum.Material.Metal)
end

function EnvironmentBuilder.build(parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Environment"
	local cfg = LayoutConfig
	local env = cfg.Environment
	local c = cfg.MapCenter
	local rng = Random.new(env.Seed)

	-- Wiese (über der Baseplate, unter Plots/Straßen)
	disc(folder, "Ground", env.GroundRadius, 2, c.X, c.Z, GROUND_TOP, GRASS, Enum.Material.Grass)

	-- Seen zwischen den Plots
	local lakes: { Vector3 } = {}
	for i, angle in env.LakeAngles do
		local a = math.rad(angle)
		local center = Vector3.new(c.X + math.cos(a) * env.LakeRadius, env.LakeSize, c.Z - math.sin(a) * env.LakeRadius)
		table.insert(lakes, center)
		lake(folder, i, Vector3.new(center.X, 0, center.Z), env.LakeSize)
	end
	local blockers = makeBlockers(lakes)

	-- Bergkette mit Schneegipfeln
	local mountains = Instance.new("Folder")
	mountains.Name = "Mountains"
	mountains.Parent = folder
	for i = 1, env.MountainCount do
		local a = (i / env.MountainCount) * math.pi * 2 + rng:NextNumber(-0.05, 0.05)
		local r = rng:NextNumber(env.MountainInner, env.MountainOuter)
		mountain(mountains, i, Vector3.new(c.X + math.cos(a) * r, GROUND_TOP, c.Z + math.sin(a) * r), rng:NextNumber(env.MountainMinHeight, env.MountainMaxHeight), rng)
	end

	-- Nadelwald und Felsen
	local forest = Instance.new("Folder")
	forest.Name = "Forest"
	forest.Parent = folder
	local placed, tries = 0, 0
	while placed < env.TreeCount and tries < env.TreeCount * 12 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber((cfg.CenterPlazaRadius + 10) ^ 2, env.ForestOuter ^ 2))
		local p = Vector3.new(c.X + math.cos(a) * r, GROUND_TOP, c.Z + math.sin(a) * r)
		if not blocked(blockers, p) then
			placed += 1
			pine(forest, placed, p, rng:NextNumber(0.8, 1.5), rng)
		end
	end
	local rocks = Instance.new("Folder")
	rocks.Name = "Rocks"
	rocks.Parent = folder
	local rockCount = 0
	tries = 0
	while rockCount < env.RockCount and tries < env.RockCount * 12 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(cfg.CenterPlazaRadius + 20, env.MountainInner)
		local p = Vector3.new(c.X + math.cos(a) * r, GROUND_TOP, c.Z + math.sin(a) * r)
		if not blocked(blockers, p) then
			rockCount += 1
			boulder(rocks, `Rock{rockCount}`, p, rng:NextNumber(3, 9), rng)
			if rng:NextNumber() < 0.5 then
				boulder(rocks, `Rock{rockCount}b`, p + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4)), rng:NextNumber(2, 4), rng)
			end
		end
	end

	-- Straßen: Markierungen, Gehwege, Laternen
	for plotId = 1, GameConfig.MaxPlots do
		roadDetails(folder, plotId)
	end

	plazaCenter(folder)
	plazaDressing(folder)
	landmarks(folder)

	folder.Parent = parent
	return folder
end

return table.freeze(EnvironmentBuilder)
