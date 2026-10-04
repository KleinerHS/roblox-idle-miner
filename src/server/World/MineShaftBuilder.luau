--!strict
-- Baut den Mine-Shaft-Raum eines Plots (PLATZHALTER-Geometrie nach MINE_SHAFT_REFERENCE.png,
-- docs/00 §13): ein kompakter Raum auf einer Ebene, Förderkorb mittig-hinten auf einem Podest
-- mit Treppe, Abbauplatz 1 hinten links, Abbauplatz 2 rechts. Die Wände sind mit
-- Holzverbau (Türstöcke mit Kappe, Kopfbändern und Bretterverschalung) gegen den Fels
-- gesichert; an den Abbauplätzen hält ein schwerer Stützrahmen die offene Erzwand.
-- Keine Schienen, keine Loren, keine Förderbänder.
--
-- Jeder Plot hat genau einen Raum unter sich. Beim Wechsel der Mine wird er nur
-- umkonfiguriert (Erzfarbe, Felsfarbe, Schild), nicht neu gebaut (D-014).
--
-- Vereinbarte Namen/Attribute:
--   Model "MineShaft_<plotId>"  Attribute PlotId, MineId
--   Folder "Cage" (ElevatorCageBuilder) mit ArrivalPoint, ElevatorPromptPart, Gate
--   Part  "MiningSlot<n>"       unsichtbare Abbauzone, Attribute SlotIndex, Tag "MiningSlot"
--   Attribute "Recolor" = "Rock" | "Ore" an allen umzufärbenden Teilen

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Mines = require(Shared.Definitions.Mines)
local Ores = require(Shared.Definitions.Ores)

local ElevatorCageBuilder = require(script.Parent.ElevatorCageBuilder)

local MineShaftBuilder = {}

local DIRT = Color3.fromRGB(96, 80, 64)
-- Verwittertes Grubenholz in leicht unterschiedlichen Tönen
local WOOD_TONES = {
	Color3.fromRGB(92, 64, 42),
	Color3.fromRGB(104, 72, 46),
	Color3.fromRGB(82, 58, 40),
	Color3.fromRGB(110, 80, 52),
}
local WOOD_PLANK = Color3.fromRGB(78, 56, 38)
local IRON = Color3.fromRGB(46, 46, 48)
local YELLOW = Color3.fromRGB(236, 182, 40)
local LAMP = Color3.fromRGB(255, 214, 160)
local BARREL_RED = Color3.fromRGB(160, 38, 34)
local CRATE = Color3.fromRGB(166, 120, 72)
local CONCRETE = Color3.fromRGB(88, 86, 84)

-- Gleicher Seed für alle Plots → alle Räume sehen identisch aus.
local LAYOUT_SEED = 1337

-- Höhe des Holzverbaus und Abstand der Türstöcke
local TIMBER_HEIGHT = 15
local BAY = 12

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.Parent = parent
	return p
end

local function rock(parent: Instance, name: string, size: Vector3, cframe: CFrame): Part
	local p = part(parent, name, size, cframe, Color3.new(0.5, 0.5, 0.5), Enum.Material.Rock)
	p:SetAttribute("Recolor", "Rock")
	return p
end

local function wood(parent: Instance, name: string, size: Vector3, cframe: CFrame, rng: Random): Part
	return part(parent, name, size, cframe, WOOD_TONES[rng:NextInteger(1, #WOOD_TONES)], Enum.Material.Wood)
end

function MineShaftBuilder.getRoomOrigin(plotCFrame: CFrame): CFrame
	return plotCFrame * CFrame.new(0, -LayoutConfig.MineShaft.DepthBelowPlot, 0)
end

-- Wand mit Holzverbau: Mittelpunkt, Richtung entlang der Wand (= RightVector, wenn man
-- in den Raum schaut), Normale in den Raum.
type Wall = { name: string, center: Vector3, along: Vector3, inward: Vector3, length: number }

local function walls(): { Wall }
	local size = LayoutConfig.MineShaft.Size
	local W, D = size.X, size.Z
	return {
		{ name = "Back", center = Vector3.new(0, 0, D / 2), along = Vector3.new(1, 0, 0), inward = Vector3.new(0, 0, -1), length = W },
		{ name = "Left", center = Vector3.new(W / 2, 0, 0), along = Vector3.new(0, 0, -1), inward = Vector3.new(-1, 0, 0), length = D },
		{ name = "Right", center = Vector3.new(-W / 2, 0, 0), along = Vector3.new(0, 0, 1), inward = Vector3.new(1, 0, 0), length = D },
	}
end

-- Position entlang einer Seitenwand für eine lokale Z-Koordinate
local function zToT(wall: Wall, z: number): number
	return z * wall.along.Z
end

-- CFrame auf einer Wand: t = Position entlang der Wand, inset = Abstand von der Wand.
-- LookVector zeigt in den Raum, RightVector entlang der Wand.
local function wallCFrame(o: CFrame, wall: Wall, t: number, y: number, inset: number): CFrame
	local pos = wall.center + wall.along * t + wall.inward * inset + Vector3.new(0, y, 0)
	return o * CFrame.lookAt(pos, pos + wall.inward)
end

-- Bereich einer Wand (in t), den ein Abbauplatz frei lässt
local function slotOnWall(wall: Wall): Vector2?
	for _, slot in LayoutConfig.MineShaft.Slots do
		if (wall.name == "Left" and slot.X > 0) or (wall.name == "Right" and slot.X < 0) then
			local t = zToT(wall, slot.Y)
			return Vector2.new(t - 8, t + 8)
		end
	end
	return nil
end

local function buildShell(model: Model, o: CFrame, rng: Random)
	local size = LayoutConfig.MineShaft.Size
	local W, H, D = size.X, size.Y, size.Z
	local t = 4

	part(model, "Floor", Vector3.new(W + 2 * t, 2, D + 2 * t), o * CFrame.new(0, -1, 0), DIRT, Enum.Material.Ground)
	rock(model, "Ceiling", Vector3.new(W + 2 * t, 3, D + 2 * t), o * CFrame.new(0, H + 1.5, 0))
	rock(model, "Wall_Back", Vector3.new(W + 2 * t, H, t), o * CFrame.new(0, H / 2, D / 2 + t / 2))
	rock(model, "Wall_Front", Vector3.new(W + 2 * t, H, t), o * CFrame.new(0, H / 2, -D / 2 - t / 2))
	rock(model, "Wall_Left", Vector3.new(t, H, D), o * CFrame.new(W / 2 + t / 2, H / 2, 0))
	rock(model, "Wall_Right", Vector3.new(t, H, D), o * CFrame.new(-W / 2 - t / 2, H / 2, 0))

	local boulders = Instance.new("Folder")
	boulders.Name = "Boulders"
	boulders.Parent = model
	local n = 0
	local function boulder(pos: Vector3, s: number)
		n += 1
		rock(boulders, `Boulder{n}`, Vector3.new(s, s * rng:NextNumber(0.7, 1), s * rng:NextNumber(0.75, 1)), o * CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3)))
	end
	-- Vorderwand: offener, grober Fels (dort kein Holzverbau)
	for x = -W / 2, W / 2, 8 do
		boulder(Vector3.new(x + rng:NextNumber(-2, 2), rng:NextNumber(3, 6), -D / 2 + rng:NextNumber(0.5, 2)), rng:NextNumber(7, 11))
		boulder(Vector3.new(x + rng:NextNumber(-2, 2), rng:NextNumber(12, 17), -D / 2 + rng:NextNumber(0, 1.5)), rng:NextNumber(7, 10))
	end
	-- Fels über dem Holzverbau, dicht an der Wand
	for _, wall in walls() do
		for tt = -wall.length / 2, wall.length / 2, 8 do
			local pos = wall.center + wall.along * (tt + rng:NextNumber(-2, 2)) + wall.inward * rng:NextNumber(0, 1.2)
			boulder(pos + Vector3.new(0, rng:NextNumber(18, 21), 0), rng:NextNumber(6, 9))
		end
	end
	-- Felsbrocken in den vorderen Ecken
	for _, c in { Vector3.new(W / 2 - 4, 3, -D / 2 + 4), Vector3.new(-W / 2 + 4, 3, -D / 2 + 4) } do
		boulder(c, 10)
		boulder(c + Vector3.new(0, 7, 0), 8)
	end
end

-- Türstockausbau an Rück- und Seitenwänden: Stempel (Pfosten), Kappe, Kopfbänder,
-- Bretterverschalung zwischen den Stempeln, Laternen an jedem zweiten Stempel.
-- Der Holzverbau hält sichtbar den Fels hinter und über sich.
local function buildTimberLining(model: Model, o: CFrame, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "Timber"
	folder.Parent = model

	for _, wall in walls() do
		local gap = slotOnWall(wall)
		local half = wall.length / 2 - 3
		local positions: { number } = {}
		local tt = -half
		while tt <= half + 0.01 do
			if not (gap and tt > gap.X - 1 and tt < gap.Y + 1) then
				table.insert(positions, tt)
			end
			tt += BAY
		end

		for i, t in positions do
			-- Stempel, leicht schief und unterschiedlich dick wie echtes Grubenholz
			local tilt = CFrame.Angles(rng:NextNumber(-0.025, 0.025), 0, rng:NextNumber(-0.025, 0.025))
			local thick = rng:NextNumber(1.5, 1.9)
			wood(folder, `{wall.name}Post{i}`, Vector3.new(thick, TIMBER_HEIGHT, thick), wallCFrame(o, wall, t, TIMBER_HEIGHT / 2, 1.4) * tilt, rng)
			wood(folder, `{wall.name}Foot{i}`, Vector3.new(thick + 0.8, 0.5, thick + 0.8), wallCFrame(o, wall, t, 0.25, 1.4), rng)

			local nextT = positions[i + 1]
			if nextT and nextT - t <= BAY + 0.1 then
				local mid = (t + nextT) / 2
				local span = nextT - t
				-- Kappe (waagerechter Balken auf den Stempeln)
				wood(folder, `{wall.name}Cap{i}`, Vector3.new(span + 1.6, 1.4, 1.8), wallCFrame(o, wall, mid, TIMBER_HEIGHT + 0.6, 1.4), rng)
				-- Kopfbänder: Diagonalstreben vom Stempel schräg nach oben zur Kappe
				local knee1 = wallCFrame(o, wall, t + 1.6, TIMBER_HEIGHT - 1.6, 1.4) * CFrame.Angles(0, 0, math.rad(-45))
				local knee2 = wallCFrame(o, wall, nextT - 1.6, TIMBER_HEIGHT - 1.6, 1.4) * CFrame.Angles(0, 0, math.rad(45))
				wood(folder, `{wall.name}KneeA{i}`, Vector3.new(0.7, 4.2, 0.7), knee1, rng)
				wood(folder, `{wall.name}KneeB{i}`, Vector3.new(0.7, 4.2, 0.7), knee2, rng)
				-- Bretterverschalung hinter den Stempeln
				local lagging = part(folder, `{wall.name}Lagging{i}`, Vector3.new(span - 1.4, TIMBER_HEIGHT - 0.6, 0.35), wallCFrame(o, wall, mid, (TIMBER_HEIGHT - 0.6) / 2 + 0.3, 0.35), WOOD_PLANK, Enum.Material.WoodPlanks)
				lagging.Color = WOOD_PLANK:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.15))
				-- Zwei vorstehende Bohlen für Tiefe
				for j, y in { 4.5, 10 } do
					wood(folder, `{wall.name}Board{i}_{j}`, Vector3.new(span - 1.4, 0.7, 0.35), wallCFrame(o, wall, mid, y + rng:NextNumber(-0.4, 0.4), 0.7), rng)
				end
			end

			-- Laterne an jedem zweiten Stempel
			if i % 2 == 0 then
				local bracket = wallCFrame(o, wall, t, 11.5, 2.6)
				part(folder, `{wall.name}LampArm{i}`, Vector3.new(0.25, 0.25, 1.6), bracket * CFrame.new(0, 0.9, 0.3), IRON, Enum.Material.Metal)
				part(folder, `{wall.name}LampCap{i}`, Vector3.new(0.9, 0.25, 0.9), bracket * CFrame.new(0, 0.55, -0.5), IRON, Enum.Material.Metal)
				local bulb = part(folder, `{wall.name}Lamp{i}`, Vector3.new(0.6, 0.8, 0.6), bracket * CFrame.new(0, 0, -0.5), LAMP, Enum.Material.Neon)
				local light = Instance.new("PointLight")
				light.Range = 20
				light.Brightness = 1.3
				light.Color = LAMP
				light.Shadows = false
				light.Parent = bulb
			end
		end
	end
end

-- Abbauplatz: schwerer Stützrahmen über der offenen Erzwand, Erzflöz in der Wand,
-- freie Arbeitsfläche davor, unsichtbare Abbauzone.
local function buildSlot(model: Model, o: CFrame, slotIndex: number, plotId: number, rng: Random)
	local slot = LayoutConfig.MineShaft.Slots[slotIndex]
	local wall = if slot.X > 0 then walls()[2] else walls()[3]
	local t0 = zToT(wall, slot.Y)
	local folder = Instance.new("Folder")
	folder.Name = `Slot{slotIndex}`
	folder.Parent = model

	-- Schwerer Stützrahmen: zwei dicke Stempel, doppelte Kappe, Kopfbänder
	wood(folder, "PortalPostA", Vector3.new(2.3, TIMBER_HEIGHT + 1, 2.3), wallCFrame(o, wall, t0 - 7.5, (TIMBER_HEIGHT + 1) / 2, 1.8), rng)
	wood(folder, "PortalPostB", Vector3.new(2.3, TIMBER_HEIGHT + 1, 2.3), wallCFrame(o, wall, t0 + 7.5, (TIMBER_HEIGHT + 1) / 2, 1.8), rng)
	wood(folder, "PortalKneeA", Vector3.new(0.9, 5, 0.9), wallCFrame(o, wall, t0 - 5.4, TIMBER_HEIGHT - 1.4, 1.8) * CFrame.Angles(0, 0, math.rad(-45)), rng)
	wood(folder, "PortalKneeB", Vector3.new(0.9, 5, 0.9), wallCFrame(o, wall, t0 + 5.4, TIMBER_HEIGHT - 1.4, 1.8) * CFrame.Angles(0, 0, math.rad(45)), rng)
	wood(folder, "PortalCap", Vector3.new(18, 1.8, 2.4), wallCFrame(o, wall, t0, TIMBER_HEIGHT + 1.6, 1.8), rng)
	wood(folder, "PortalCap2", Vector3.new(17, 1.2, 2), wallCFrame(o, wall, t0, TIMBER_HEIGHT + 3, 1.8), rng)

	-- Laterne mittig an der Kappe
	local lampCF = wallCFrame(o, wall, t0, TIMBER_HEIGHT - 0.6, 3.2)
	part(folder, "LampChain", Vector3.new(0.15, 1.4, 0.15), lampCF * CFrame.new(0, 1.3, 0), IRON, Enum.Material.Metal)
	local bulb = part(folder, "Lamp", Vector3.new(0.8, 1, 0.8), lampCF, LAMP, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 26
	light.Brightness = 1.8
	light.Color = LAMP
	light.Parent = bulb

	-- Erzflöz in der offenen Wand zwischen den Stempeln
	local vein = Instance.new("Folder")
	vein.Name = "OreVein"
	vein.Parent = folder
	for i = 1, 9 do
		local cf = wallCFrame(o, wall, t0 + rng:NextNumber(-6, 6), rng:NextNumber(2, 13), 0.4) * CFrame.Angles(0, 0, rng:NextNumber(-0.6, 0.6))
		local chunk = part(vein, `Seam{i}`, Vector3.new(rng:NextNumber(3, 5.5), rng:NextNumber(2, 4), 2.2), cf, Color3.new(0, 0, 0), Enum.Material.Slate)
		chunk:SetAttribute("Recolor", "Ore")
	end

	-- Vor der Erzwand bleibt der Boden frei: Arbeitsplatz für Spieler, Worker und Drills
	-- (Rückmeldung Felix 2026-10-04, keine Erzhaufen mehr).

	-- Unsichtbare Abbauzone für Schritt 2c: freie Fläche direkt vor der Erzwand
	local zone = part(folder, `MiningSlot{slotIndex}`, Vector3.new(16, 14, 12), wallCFrame(o, wall, t0, 7, 6), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	zone.Transparency = 1
	zone.CanCollide = false
	zone:SetAttribute("SlotIndex", slotIndex)
	zone:SetAttribute("PlotId", plotId)
	CollectionService:AddTag(zone, "MiningSlot")
end

local function buildElevator(model: Model, o: CFrame, plotId: number)
	local c = LayoutConfig.MineShaft.ElevatorCenter
	local base = o * CFrame.new(c.X, 0, c.Y)
	local folder = Instance.new("Folder")
	folder.Name = "Elevator"
	folder.Parent = model

	local P, podiumH = 22, 2.4
	local halfP = P / 2
	part(folder, "Podium", Vector3.new(P, podiumH, P), base * CFrame.new(0, podiumH / 2, 0), CONCRETE, Enum.Material.Concrete)
	part(folder, "PodiumEdge", Vector3.new(P + 0.4, 0.3, P + 0.4), base * CFrame.new(0, podiumH - 0.15, 0), Color3.fromRGB(64, 62, 60), Enum.Material.Concrete)
	-- Treppe vorne
	for i = 1, 3 do
		local h = podiumH * i / 4
		part(folder, `Step{i}`, Vector3.new(8, h, 1.6), base * CFrame.new(0, h / 2, -halfP - 0.8 - (3 - i) * 1.6), Color3.fromRGB(100, 98, 94), Enum.Material.Concrete)
	end
	-- Geländer um das Podest, vorne frei für Treppe und Tor
	local railY = podiumH + 1.8
	local function rail(name: string, from: Vector3, to: Vector3)
		local mid = (from + to) / 2
		local len = (to - from).Magnitude
		part(folder, name, Vector3.new(0.3, 0.3, len), base * CFrame.lookAt(mid, to), YELLOW, Enum.Material.Metal)
	end
	local corners = {
		Vector3.new(halfP - 0.4, railY, -halfP + 0.4),
		Vector3.new(halfP - 0.4, railY, halfP - 0.4),
		Vector3.new(-halfP + 0.4, railY, halfP - 0.4),
		Vector3.new(-halfP + 0.4, railY, -halfP + 0.4),
	}
	rail("RailLeft", corners[1], corners[2])
	rail("RailBack", corners[2], corners[3])
	rail("RailRight", corners[3], corners[4])
	for i, corner in corners do
		part(folder, `RailPost{i}`, Vector3.new(0.35, 1.8, 0.35), base * CFrame.new(corner.X, podiumH + 0.9, corner.Z), YELLOW, Enum.Material.Metal)
	end

	-- Schild am Podest neben der Treppe: Shaft-Nummer (docs/12 §25)
	local sign = part(folder, "ShaftSign", Vector3.new(6.5, 1.6, 0.2), base * CFrame.new(-7.5, podiumH / 2, -halfP - 0.15), Color3.fromRGB(30, 30, 32), Enum.Material.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = YELLOW
	label.Text = "MINE"
	label.Parent = gui

	-- Kisten auf dem Podest wie im Referenzbild
	part(folder, "PodiumCrate1", Vector3.new(2.4, 2.4, 2.4), base * CFrame.new(halfP - 1.8, podiumH + 1.2, halfP - 1.8), CRATE, Enum.Material.WoodPlanks)
	part(folder, "PodiumCrate2", Vector3.new(2, 2, 2), base * CFrame.new(halfP - 1.6, podiumH + 1, -halfP + 1.6), CRATE, Enum.Material.WoodPlanks)

	ElevatorCageBuilder.build(folder, base * CFrame.new(0, podiumH + 0.25, 0), "Mine", plotId)
end

local function buildProps(model: Model, o: CFrame, rng: Random)
	local size = LayoutConfig.MineShaft.Size
	local W, D = size.X, size.Z
	local folder = Instance.new("Folder")
	folder.Name = "Props"
	folder.Parent = model

	-- Holzgeländer entlang der Vorderkante (wie im Referenzbild), Mitte frei
	for _, sideX in { 1, -1 } do
		local x0, x1 = sideX * 8, sideX * (W / 2 - 8)
		local z = -D / 2 + 6
		local n = 0
		local x = x0
		while math.abs(x) <= math.abs(x1) + 0.01 do
			n += 1
			wood(folder, `FencePost{sideX}_{n}`, Vector3.new(0.8, 3.4, 0.8), o * CFrame.new(x, 1.7, z + rng:NextNumber(-0.3, 0.3)), rng)
			x += sideX * 6
		end
		local len = math.abs(x1 - x0)
		for j, y in { 1.4, 2.8 } do
			wood(folder, `FenceRail{sideX}_{j}`, Vector3.new(len + 0.8, 0.4, 0.4), o * CFrame.new((x0 + x1) / 2, y, z), rng)
		end
	end

	-- Kisten, Fässer, Werkzeugregal wie im Referenzbild
	for i, p in { Vector3.new(-20, 0, D / 2 - 6), Vector3.new(-16.5, 0, D / 2 - 5.5), Vector3.new(16, 0, D / 2 - 6), Vector3.new(12, 0, -8), Vector3.new(-12, 0, -11), Vector3.new(-26, 0, -24), Vector3.new(24, 0, -25) } do
		local s = rng:NextNumber(2.6, 3.4)
		part(folder, `Crate{i}`, Vector3.new(s, s, s), o * CFrame.new(p.X, s / 2, p.Z) * CFrame.Angles(0, rng:NextNumber(0, 1), 0), CRATE, Enum.Material.WoodPlanks)
	end
	for i, p in { Vector2.new(-24, D / 2 - 5), Vector2.new(-40, -16), Vector2.new(27, D / 2 - 5) } do
		local barrel = part(folder, `Barrel{i}`, Vector3.new(3.2, 2.4, 2.4), o * CFrame.new(p.X, 1.6, p.Y) * CFrame.Angles(0, 0, math.rad(90)), BARREL_RED, Enum.Material.Metal)
		barrel.Shape = Enum.PartType.Cylinder
		local band = part(folder, `BarrelBand{i}`, Vector3.new(0.3, 2.5, 2.5), barrel.CFrame * CFrame.new(0.8, 0, 0), IRON, Enum.Material.Metal)
		band.Shape = Enum.PartType.Cylinder
	end
	local rack = wood(folder, "ToolRack", Vector3.new(6, 5, 1.2), o * CFrame.new(-31, 2.5, D / 2 - 3.2), rng)
	for i = 1, 3 do
		part(folder, `RackTool{i}`, Vector3.new(0.3, 4.4, 0.3), rack.CFrame * CFrame.new(-2 + i * 1.2, 0, -0.8) * CFrame.Angles(0.15, 0, 0), WOOD_TONES[3], Enum.Material.Wood)
		part(folder, `RackHead{i}`, Vector3.new(1.4, 0.4, 0.3), rack.CFrame * CFrame.new(-2 + i * 1.2, 2.2, -0.9), IRON, Enum.Material.Metal)
	end
end

-- Baut den Raum für einen Plot (einmal beim Serverstart).
function MineShaftBuilder.build(parent: Instance, plotId: number, plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = `MineShaft_{plotId}`
	model:SetAttribute("PlotId", plotId)
	model:SetAttribute("MineId", "")

	local o = MineShaftBuilder.getRoomOrigin(plotCFrame)
	local rng = Random.new(LAYOUT_SEED)
	buildShell(model, o, rng)
	buildTimberLining(model, o, rng)
	for slotIndex = 1, #LayoutConfig.MineShaft.Slots do
		buildSlot(model, o, slotIndex, plotId, rng)
	end
	buildElevator(model, o, plotId)
	buildProps(model, o, rng)

	model.PrimaryPart = model:FindFirstChild("Floor") :: BasePart
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

-- Stellt den Raum auf eine Mine ein (Erzfarbe, Felsfarbe, Schild).
function MineShaftBuilder.configure(room: Model, mine: Mines.MineDefinition)
	if room:GetAttribute("MineId") == mine.Id then
		return
	end
	local ore = Ores.Get(mine.OreId)
	assert(ore, `Unbekanntes Erz {mine.OreId}`)
	local rockColor = Mines.RockColor(mine)
	for _, d in room:GetDescendants() do
		if d:IsA("BasePart") then
			local recolor = d:GetAttribute("Recolor")
			if recolor == "Rock" then
				d.Color = rockColor
			elseif recolor == "Ore" then
				d.Color = ore.Color
			end
		end
	end
	local sign = room:FindFirstChild("ShaftSign", true)
	local label = sign and sign:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.Text = `{Mines.Label(mine)} · {string.upper(ore.DisplayName)}`
	end
	room:SetAttribute("MineId", mine.Id)
end

-- Förderkorb des Raums
function MineShaftBuilder.getCage(room: Model): Instance?
	return room:FindFirstChild("Cage", true)
end

return table.freeze(MineShaftBuilder)
