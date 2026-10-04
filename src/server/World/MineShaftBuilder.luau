--!strict
-- Baut den Mine-Shaft-Raum eines Plots (PLATZHALTER-Geometrie nach MINE_SHAFT_REFERENCE.png,
-- docs/00 §13): ein kompakter Raum, eine Ebene, Elevator mittig auf Podest mit Treppe,
-- zwei Erzbereiche an gegenüberliegenden Wänden, Holzstützen, Lampen, Kisten, Fässer.
-- Keine Schienen, keine Loren, keine Förderbänder.
--
-- Jeder Plot hat genau einen Raum unter sich. Beim Wechsel der Mine wird er nur
-- umkonfiguriert (Erzfarbe, Felsfarbe, Schild), nicht neu gebaut (D-014).
--
-- Vereinbarte Namen/Attribute:
--   Model "MineShaft_<plotId>"  Attribute PlotId, MineId
--   Part  "ArrivalPoint"        Ankunft im Käfig
--   Part  "ElevatorPromptPart"  mit ProximityPrompt (Attribute ElevatorKind = "Mine")
--   Part  "MiningSlot<n>"       unsichtbare Abbauzone, Attribute SlotIndex, Tag "MiningSlot"
--   Attribute "Recolor" = "Rock" | "Ore" an allen umzufärbenden Teilen

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Mines = require(Shared.Definitions.Mines)
local Ores = require(Shared.Definitions.Ores)

local MineShaftBuilder = {}

local DIRT = Color3.fromRGB(96, 80, 64)
local WOOD = Color3.fromRGB(128, 88, 54)
local WOOD_DARK = Color3.fromRGB(92, 62, 40)
local STEEL = Color3.fromRGB(70, 74, 80)
local STEEL_DARK = Color3.fromRGB(44, 46, 50)
local WARNING_YELLOW = Color3.fromRGB(232, 184, 52)
local LAMP = Color3.fromRGB(255, 232, 200)
local BARREL_RED = Color3.fromRGB(170, 40, 36)
local CRATE = Color3.fromRGB(176, 128, 74)

-- Gleicher Seed für alle Plots → alle Räume sehen identisch aus.
local LAYOUT_SEED = 1337

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

function MineShaftBuilder.getRoomOrigin(plotCFrame: CFrame): CFrame
	return plotCFrame * CFrame.new(0, -LayoutConfig.MineShaft.DepthBelowPlot, 0)
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

	-- Unregelmäßige Felsbrocken vor den Wänden, damit keine glatte Box entsteht (docs/00 §13)
	local boulders = Instance.new("Folder")
	boulders.Name = "Boulders"
	boulders.Parent = model
	local index = 0
	local function placeAlong(fromX: number, fromZ: number, toX: number, toZ: number, inward: Vector3)
		local length = math.sqrt((toX - fromX) ^ 2 + (toZ - fromZ) ^ 2)
		local count = math.floor(length / 9)
		for i = 0, count do
			local a = i / math.max(count, 1)
			local x = fromX + (toX - fromX) * a
			local z = fromZ + (toZ - fromZ) * a
			for _, y in { 4, 13 } do
				index += 1
				local s = rng:NextNumber(7, 12)
				local offset = inward * rng:NextNumber(0.5, 2.5)
				local cf = o
					* CFrame.new(x + offset.X, y + rng:NextNumber(-1.5, 1.5), z + offset.Z)
					* CFrame.Angles(rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi))
				rock(boulders, `Boulder{index}`, Vector3.new(s, s * rng:NextNumber(0.7, 1), s * rng:NextNumber(0.7, 1)), cf)
			end
		end
	end
	local hx, hz = W / 2, D / 2
	placeAlong(-hx, hz, hx, hz, Vector3.new(0, 0, -1)) -- hinten
	placeAlong(-hx, -hz, hx, -hz, Vector3.new(0, 0, 1)) -- vorne
	placeAlong(hx, -hz, hx, hz, Vector3.new(-1, 0, 0)) -- links (+X)
	placeAlong(-hx, -hz, -hx, hz, Vector3.new(1, 0, 0)) -- rechts (-X)
end

local function buildTimber(model: Model, o: CFrame)
	local size = LayoutConfig.MineShaft.Size
	local W, H, D = size.X, size.Y, size.Z
	local folder = Instance.new("Folder")
	folder.Name = "Timber"
	folder.Parent = model
	-- Holzverbau an der Rückwand: Pfosten + durchgehender Balken
	for i, x in { -40, -24, -8, 8, 24, 40 } do
		part(folder, `BackPost{i}`, Vector3.new(1.6, H - 1, 1.6), o * CFrame.new(x, (H - 1) / 2, D / 2 - 3.5), WOOD, Enum.Material.Wood)
	end
	part(folder, "BackBeam", Vector3.new(W - 6, 1.6, 1.6), o * CFrame.new(0, H - 2, D / 2 - 3.5), WOOD_DARK, Enum.Material.Wood)
	-- Deckenbalken quer durch den Raum
	for i, z in { -20, 0, 20 } do
		part(folder, `CeilingBeam{i}`, Vector3.new(W - 4, 1.4, 1.4), o * CFrame.new(0, H - 0.8, z), WOOD_DARK, Enum.Material.Wood)
	end
end

-- Holzstützkonstruktion + Erzader + Abbauzone für einen Mining-Slot (docs/19 §5: zwei Holzstützen pro Mine)
local function buildSlot(model: Model, o: CFrame, slotIndex: number, plotId: number, rng: Random)
	local slot = LayoutConfig.MineShaft.Slots[slotIndex]
	local W = LayoutConfig.MineShaft.Size.X
	local side = if slot.X > 0 then 1 else -1 -- Richtung zur Wand
	local wallX = side * (W / 2 - 2)
	local folder = Instance.new("Folder")
	folder.Name = `Slot{slotIndex}`
	folder.Parent = model

	-- Stützrahmen: zwei Pfosten + Kopfbalken vor der Erzader
	local frameX = wallX - side * 9
	for i, dz in { -8, 8 } do
		part(folder, `SupportPost{i}`, Vector3.new(1.8, 15, 1.8), o * CFrame.new(frameX, 7.5, slot.Y + dz), WOOD, Enum.Material.Wood)
	end
	part(folder, "SupportBeam", Vector3.new(1.8, 1.8, 19), o * CFrame.new(frameX, 15.6, slot.Y), WOOD_DARK, Enum.Material.Wood)
	part(folder, "SupportBrace", Vector3.new(9, 1.2, 1.2), o * CFrame.new(frameX + side * 4.5, 15.6, slot.Y), WOOD_DARK, Enum.Material.Wood)

	-- Erzader: Haufen aus Brocken an der Wand, unendlich (wird nie abgebaut, docs/03 §3)
	local vein = Instance.new("Folder")
	vein.Name = "OreVein"
	vein.Parent = folder
	for i = 1, 16 do
		local r = rng:NextNumber(0, 7)
		local angle = rng:NextNumber(-math.pi / 2, math.pi / 2)
		local x = wallX - side * (math.cos(angle) * r * 0.8)
		local z = slot.Y + math.sin(angle) * r * 1.3
		local s = rng:NextNumber(2.4, 4.6)
		local y = s / 2 + math.max(0, (7 - r)) * 0.55 + rng:NextNumber(0, 1.2)
		local chunk = part(vein, `Chunk{i}`, Vector3.new(s, s * rng:NextNumber(0.75, 1), s), o * CFrame.new(x, y, z) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3)), Color3.new(0, 0, 0), Enum.Material.Slate)
		chunk:SetAttribute("Recolor", "Ore")
	end
	-- Erz in der Wand eingebettet
	for i = 1, 5 do
		local chunk = part(vein, `WallSeam{i}`, Vector3.new(2.5, rng:NextNumber(2, 4), rng:NextNumber(3, 6)), o * CFrame.new(wallX + side * 0.6, rng:NextNumber(5, 12), slot.Y + rng:NextNumber(-6, 6)) * CFrame.Angles(rng:NextNumber(0, 1), 0, rng:NextNumber(0, 1)), Color3.new(0, 0, 0), Enum.Material.Slate)
		chunk:SetAttribute("Recolor", "Ore")
	end

	-- Unsichtbare Abbauzone für Schritt 2c (Distanzprüfung, Ziel des Mining-Requests)
	local zone = part(folder, `MiningSlot{slotIndex}`, Vector3.new(12, 10, 18), o * CFrame.new(wallX - side * 5, 5, slot.Y), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	zone.Transparency = 1
	zone.CanCollide = false
	zone:SetAttribute("SlotIndex", slotIndex)
	zone:SetAttribute("PlotId", plotId)
	CollectionService:AddTag(zone, "MiningSlot")

	-- Lampe über dem Slot
	local lamp = part(folder, "Lamp", Vector3.new(1.2, 1.2, 1.2), o * CFrame.new(frameX, 14.4, slot.Y), LAMP, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 26
	light.Brightness = 1.8
	light.Color = LAMP
	light.Parent = lamp
end

local function buildElevator(model: Model, o: CFrame, plotId: number)
	local c = LayoutConfig.MineShaft.ElevatorCenter
	local base = o * CFrame.new(c.X, 0, c.Y)
	local folder = Instance.new("Folder")
	folder.Name = "Elevator"
	folder.Parent = model

	local podiumH = 3
	part(folder, "Podium", Vector3.new(24, podiumH, 24), base * CFrame.new(0, podiumH / 2, 0), Color3.fromRGB(84, 82, 80), Enum.Material.Concrete)
	for i = 1, 3 do
		local h = podiumH * i / 4
		part(folder, `Step{i}`, Vector3.new(9, h, 2), base * CFrame.new(0, h / 2, -12 - (4 - i) * 2 + 1), Color3.fromRGB(96, 94, 92), Enum.Material.Concrete)
	end
	local top = podiumH

	local S, CH = 18, 16
	local half = S / 2
	part(folder, "CarFloor", Vector3.new(S - 1, 0.4, S - 1), base * CFrame.new(0, top + 0.2, 0), STEEL, Enum.Material.DiamondPlate)
	for i, p in { Vector2.new(half, half), Vector2.new(-half, half), Vector2.new(half, -half), Vector2.new(-half, -half) } do
		part(folder, `Post{i}`, Vector3.new(1.2, CH, 1.2), base * CFrame.new(p.X, top + CH / 2, p.Y), STEEL_DARK, Enum.Material.Metal)
	end
	for i, def in {
		{ Vector3.new(S + 1.2, 1, 1), Vector3.new(0, top + CH, -half) },
		{ Vector3.new(S + 1.2, 1, 1), Vector3.new(0, top + CH, half) },
		{ Vector3.new(1, 1, S + 1.2), Vector3.new(half, top + CH, 0) },
		{ Vector3.new(1, 1, S + 1.2), Vector3.new(-half, top + CH, 0) },
	} do
		part(folder, `TopBeam{i}`, def[1], base * CFrame.new(def[2]), STEEL_DARK, Enum.Material.Metal)
	end
	local function grid(name: string, size: Vector3, cf: CFrame)
		local g = part(folder, name, size, cf, Color3.fromRGB(60, 62, 66), Enum.Material.DiamondPlate)
		g.Transparency = 0.85
	end
	grid("Grid_Back", Vector3.new(S - 1.2, CH - 1, 0.2), base * CFrame.new(0, top + CH / 2, half))
	grid("Grid_Left", Vector3.new(0.2, CH - 1, S - 1.2), base * CFrame.new(half, top + CH / 2, 0))
	grid("Grid_Right", Vector3.new(0.2, CH - 1, S - 1.2), base * CFrame.new(-half, top + CH / 2, 0))
	for i = 1, 3 do
		part(folder, `Stripe{i}`, Vector3.new(S - 1.2, 0.5, 0.3), base * CFrame.new(0, top + i * (CH / 4), -half), if i % 2 == 0 then WARNING_YELLOW else STEEL_DARK, Enum.Material.Metal)
	end
	part(folder, "Cable", Vector3.new(0.25, 40, 0.25), base * CFrame.new(0, top + CH + 20, 0), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)

	-- Schild am Podest: Shaft-Nummer (docs/12 §25)
	local sign = part(folder, "ShaftSign", Vector3.new(12, 2.4, 0.3), base * CFrame.new(0, top + CH + 1.9, -half - 0.3), STEEL_DARK, Enum.Material.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = WARNING_YELLOW
	label.Text = "MINE"
	label.Parent = gui

	local arrival = part(folder, "ArrivalPoint", Vector3.new(2, 1, 2), base * CFrame.new(0, top + 3, 2), STEEL, Enum.Material.SmoothPlastic)
	arrival.Transparency = 1
	arrival.CanCollide = false
	arrival.CanQuery = false

	local promptPart = part(folder, "ElevatorPromptPart", Vector3.new(4, 4, 4), base * CFrame.new(0, top + 3, 0), STEEL, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ElevatorPrompt"
	prompt.ActionText = "Use Elevator"
	prompt.ObjectText = "Elevator"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ElevatorKind", "Mine")
	prompt:SetAttribute("PlotId", plotId)
	prompt.Parent = promptPart
end

local function buildProps(model: Model, o: CFrame, rng: Random)
	local size = LayoutConfig.MineShaft.Size
	local W, H, D = size.X, size.Y, size.Z
	local folder = Instance.new("Folder")
	folder.Name = "Props"
	folder.Parent = model

	-- Wandlampen
	for i, p in { Vector2.new(-30, D / 2 - 5), Vector2.new(30, D / 2 - 5), Vector2.new(-12, D / 2 - 5), Vector2.new(12, D / 2 - 5), Vector2.new(-20, -D / 2 + 5), Vector2.new(20, -D / 2 + 5) } do
		local lamp = part(folder, `WallLamp{i}`, Vector3.new(1, 1, 1), o * CFrame.new(p.X, H - 6, p.Y), LAMP, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 1.4
		light.Color = LAMP
		light.Parent = lamp
	end

	-- Kisten
	for i, p in { Vector3.new(-20, 0, D / 2 - 7), Vector3.new(-16, 0, D / 2 - 8), Vector3.new(18, 0, D / 2 - 7), Vector3.new(14, 0, -10), Vector3.new(-13, 0, -12), Vector3.new(-26, 0, -26), Vector3.new(26, 0, -27) } do
		local s = rng:NextNumber(2.6, 3.6)
		part(folder, `Crate{i}`, Vector3.new(s, s, s), o * CFrame.new(p.X, s / 2, p.Z) * CFrame.Angles(0, rng:NextNumber(0, 1), 0), CRATE, Enum.Material.WoodPlanks)
	end

	-- Fässer
	for i, p in { Vector2.new(-24, D / 2 - 6), Vector2.new(27, D / 2 - 7) } do
		local barrel = part(folder, `Barrel{i}`, Vector3.new(3.4, 2.6, 2.6), o * CFrame.new(p.X, 1.7, p.Y) * CFrame.Angles(0, 0, math.rad(90)), BARREL_RED, Enum.Material.Metal)
		barrel.Shape = Enum.PartType.Cylinder
	end

	-- Werkzeugregal an der Rückwand
	local shelf = part(folder, "Shelf", Vector3.new(7, 6, 1.6), o * CFrame.new(-32, 3, D / 2 - 5), WOOD, Enum.Material.Wood)
	for i = 1, 3 do
		part(folder, `ShelfItem{i}`, Vector3.new(1.4, 1, 1), shelf.CFrame * CFrame.new(-2.2 + i * 1.4, -1 + (i % 2) * 2, -0.2), STEEL_DARK, Enum.Material.Metal)
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
	buildTimber(model, o)
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

return table.freeze(MineShaftBuilder)
