--!strict
-- PLATZHALTER-Modelle für Hallenwände, Dach und Lager (D-002, D-010, docs/04 §18,
-- docs/06 §13–16, FACTORY_MASTERPLAN_TOPDOWN.png). Maße aus LayoutConfig.
--
-- Vereinbarte Namen/Attribute:
--   Lager: Part "StorageDisplay" (SurfaceGui "Display" mit "Amount" und "Fill"),
--          Part "StorageTerminalPart" mit ProximityPrompt "StoragePrompt" (Attribute StorageTerminal = true)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LayoutConfig)

local HallTemplates = {}

local WALL = Color3.fromRGB(176, 182, 190)
local WALL_DARK = Color3.fromRGB(96, 100, 108)
local CONCRETE = Color3.fromRGB(130, 128, 124)
local STEEL = Color3.fromRGB(70, 74, 80)
local GLASS = Color3.fromRGB(170, 210, 230)
local RACK = Color3.fromRGB(226, 150, 40)
local CRATE = Color3.fromRGB(176, 128, 74)
local CRATE_DARK = Color3.fromRGB(140, 100, 58)
local SILO = Color3.fromRGB(186, 190, 196)
local LIGHT = Color3.fromRGB(255, 240, 214)
local YELLOW = Color3.fromRGB(236, 182, 40)

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

-- Hallenrechteck (lokal zur Plotmitte): Mitte X/Z, halbe Breite/Tiefe, Bodenhöhe
local function hall(): (number, number, number, number, number)
	local size, offset = LayoutConfig.HallSize, LayoutConfig.HallOffset
	return offset.X, offset.Y, size.X / 2, size.Y / 2, LayoutConfig.HallFloorTop
end

-- Wandstück mit Sockel, Hauptfläche, Fensterband und Attika (von unten nach oben)
local function wallSegment(parent: Instance, name: string, length: number, cf: CFrame, thickness: number, height: number)
	local band0, band1 = height - 13, height - 9
	part(parent, name .. "_Base", Vector3.new(length, 3, thickness + 0.2), cf * CFrame.new(0, 1.5, 0), CONCRETE, Enum.Material.Concrete)
	part(parent, name .. "_Main", Vector3.new(length, band0 - 3, thickness), cf * CFrame.new(0, 3 + (band0 - 3) / 2, 0), WALL, Enum.Material.Metal)
	local glass = part(parent, name .. "_Windows", Vector3.new(length, band1 - band0, thickness * 0.4), cf * CFrame.new(0, band0 + (band1 - band0) / 2, 0), GLASS, Enum.Material.Glass)
	glass.Transparency = 0.35
	part(parent, name .. "_Top", Vector3.new(length, height - band1, thickness), cf * CFrame.new(0, band1 + (height - band1) / 2, 0), WALL, Enum.Material.Metal)
end

-- Außenwände der Halle mit großem Rolltor vorne (docs/00 §9)
function HallTemplates.buildWalls(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "HallWalls"
	local cx, cz, hx, hz, y0 = hall()
	local H, t = LayoutConfig.HallWallHeight, 1.6
	local base = plotCFrame * CFrame.new(cx, y0, cz)

	wallSegment(model, "Back", hx * 2 + t, base * CFrame.new(0, 0, hz), t, H)
	wallSegment(model, "Left", hz * 2, base * CFrame.new(hx, 0, 0) * CFrame.Angles(0, math.rad(90), 0), t, H)
	wallSegment(model, "Right", hz * 2, base * CFrame.new(-hx, 0, 0) * CFrame.Angles(0, math.rad(90), 0), t, H)

	-- Vorderwand mit Toröffnung
	local doorX, doorW, doorH = LayoutConfig.DoorCenterX - cx, LayoutConfig.DoorWidth, LayoutConfig.DoorHeight
	local leftStart, leftEnd = doorX + doorW / 2, hx + t / 2
	local rightStart, rightEnd = -hx - t / 2, doorX - doorW / 2
	wallSegment(model, "FrontLeft", leftEnd - leftStart, base * CFrame.new((leftStart + leftEnd) / 2, 0, -hz), t, H)
	wallSegment(model, "FrontRight", rightEnd - rightStart, base * CFrame.new((rightStart + rightEnd) / 2, 0, -hz), t, H)
	part(model, "DoorLintel", Vector3.new(doorW, H - doorH, t), base * CFrame.new(doorX, doorH + (H - doorH) / 2, -hz), WALL, Enum.Material.Metal)
	-- Rolltor (offen): Rollkasten oben, Führungsschienen, Glaslamellen als Andeutung
	part(model, "DoorHousing", Vector3.new(doorW + 2, 2.4, 2.4), base * CFrame.new(doorX, doorH + 1.2, -hz - 1.3), WALL_DARK, Enum.Material.Metal)
	for _, side in { 1, -1 } do
		part(model, `DoorRail{side}`, Vector3.new(0.8, doorH, 0.8), base * CFrame.new(doorX + side * (doorW / 2 + 0.4), doorH / 2, -hz - 0.9), STEEL, Enum.Material.Metal)
		part(model, `DoorStripe{side}`, Vector3.new(0.9, doorH, 0.2), base * CFrame.new(doorX + side * (doorW / 2 + 0.4), doorH / 2, -hz - 1.35), YELLOW, Enum.Material.SmoothPlastic)
	end
	local slats = part(model, "DoorSlats", Vector3.new(doorW, 1.2, 0.3), base * CFrame.new(doorX, doorH - 0.6, -hz - 0.6), GLASS, Enum.Material.Glass)
	slats.Transparency = 0.3

	-- Stahlstützen innen entlang der Wände
	for x = -hx + 21, hx - 21, 21 do
		part(model, `ColumnBack{x}`, Vector3.new(1.2, H, 1.2), base * CFrame.new(x, H / 2, hz - 1.4), STEEL, Enum.Material.Metal)
	end
	for z = -hz + 20, hz - 20, 20 do
		part(model, `ColumnL{z}`, Vector3.new(1.2, H, 1.2), base * CFrame.new(hx - 1.4, H / 2, z), STEEL, Enum.Material.Metal)
		part(model, `ColumnR{z}`, Vector3.new(1.2, H, 1.2), base * CFrame.new(-hx + 1.4, H / 2, z), STEEL, Enum.Material.Metal)
	end
	return model
end

-- Flachdach mit Oberlichtern und Hallenleuchten
function HallTemplates.buildRoof(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "HallRoof"
	local cx, cz, hx, hz, y0 = hall()
	local H = LayoutConfig.HallWallHeight
	local base = plotCFrame * CFrame.new(cx, y0 + H, cz)

	-- Dachfläche in Streifen, dazwischen Oberlichter
	local depth = hz * 2 + 2
	local stripW = 30
	local skyW = 6
	local x = -hx - 1
	local i = 0
	while x < hx + 1 do
		i += 1
		local w = math.min(stripW, hx + 1 - x)
		part(model, `RoofStrip{i}`, Vector3.new(w, 1, depth), base * CFrame.new(x + w / 2, 0.5, 0), WALL_DARK, Enum.Material.Metal)
		x += w
		if x < hx + 1 then
			local sw = math.min(skyW, hx + 1 - x)
			local sky = part(model, `Skylight{i}`, Vector3.new(sw, 0.4, depth - 8), base * CFrame.new(x + sw / 2, 0.6, 0), GLASS, Enum.Material.Glass)
			sky.Transparency = 0.5
			part(model, `SkylightFrameA{i}`, Vector3.new(sw, 1, 4), base * CFrame.new(x + sw / 2, 0.5, depth / 2 - 2), WALL_DARK, Enum.Material.Metal)
			part(model, `SkylightFrameB{i}`, Vector3.new(sw, 1, 4), base * CFrame.new(x + sw / 2, 0.5, -depth / 2 + 2), WALL_DARK, Enum.Material.Metal)
			x += sw
		end
	end
	-- Attika rundum
	part(model, "ParapetFront", Vector3.new(hx * 2 + 2, 1.6, 0.8), base * CFrame.new(0, 1.8, -hz - 0.6), WALL, Enum.Material.Metal)
	part(model, "ParapetBack", Vector3.new(hx * 2 + 2, 1.6, 0.8), base * CFrame.new(0, 1.8, hz + 0.6), WALL, Enum.Material.Metal)

	-- Hallenleuchten (hängend)
	for lx = -hx + 30, hx - 30, 45 do
		for lz = -hz + 30, hz - 30, 40 do
			local lamp = part(model, `Lamp{lx}_{lz}`, Vector3.new(5, 0.4, 1.4), base * CFrame.new(lx, -3, lz), LIGHT, Enum.Material.Neon)
			part(model, `LampRod{lx}_{lz}`, Vector3.new(0.2, 2.8, 0.2), base * CFrame.new(lx, -1.4, lz), STEEL, Enum.Material.Metal)
			local light = Instance.new("PointLight")
			light.Range = 40
			light.Brightness = 1.2
			light.Color = LIGHT
			light.Shadows = false
			light.Parent = lamp
		end
	end
	return model
end

-- Regal mit Kisten (Stahlrahmen orange wie im Masterplan)
local function rack(parent: Instance, name: string, cf: CFrame, width: number, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	local depth, height = 3.2, 10
	for _, x in { -width / 2, 0, width / 2 } do
		for _, z in { -depth / 2, depth / 2 } do
			part(folder, "Upright", Vector3.new(0.4, height, 0.4), cf * CFrame.new(x, height / 2, z), RACK, Enum.Material.Metal)
		end
	end
	for level, y in { 0.4, 3.6, 6.8 } do
		part(folder, `Shelf{level}`, Vector3.new(width + 0.4, 0.3, depth + 0.2), cf * CFrame.new(0, y, 0), STEEL, Enum.Material.DiamondPlate)
		for slot = 1, 3 do
			if rng:NextNumber() < 0.8 then
				local s = rng:NextNumber(2.2, 2.8)
				local x = -width / 2 + (slot - 0.5) * (width / 3)
				part(folder, `Crate{level}_{slot}`, Vector3.new(s, s, s * 0.95), cf * CFrame.new(x, y + 0.15 + s / 2, 0) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), if rng:NextNumber() < 0.5 then CRATE else CRATE_DARK, Enum.Material.WoodPlanks)
			end
		end
	end
end

-- Lagerbereich: Regale wie im Bild plus Silo mit gut lesbarer Füllanzeige (D-010),
-- Terminal zum Abladen/Entnehmen (D-004).
function HallTemplates.buildStorage(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Storage"
	local zone = LayoutConfig.HallZones.Storage
	local o = plotCFrame * CFrame.new(zone.Center.X, LayoutConfig.HallFloorTop, zone.Center.Y)
	local hw, hd = zone.Size.X / 2, zone.Size.Y / 2
	local rng = Random.new(4242)

	-- Regalreihen hinten und in der Mitte
	rack(model, "RackBackA", o * CFrame.new(10, 0, hd - 4), 14, rng)
	rack(model, "RackBackB", o * CFrame.new(-6, 0, hd - 4), 14, rng)
	rack(model, "RackMidA", o * CFrame.new(10, 0, 6), 14, rng)
	rack(model, "RackMidB", o * CFrame.new(-6, 0, 6), 14, rng)
	-- Paletten und lose Kisten am Boden
	for i, p in { Vector2.new(22, -6), Vector2.new(24, 2), Vector2.new(-2, -10) } do
		part(model, `Pallet{i}`, Vector3.new(4, 0.5, 4), o * CFrame.new(p.X, 0.25, p.Y), CRATE_DARK, Enum.Material.WoodPlanks)
		part(model, `PalletCrate{i}`, Vector3.new(3, 3, 3), o * CFrame.new(p.X, 2, p.Y) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), CRATE, Enum.Material.WoodPlanks)
	end

	-- Silo rechts im Lagerbereich (lokal -X), Anzeige zeigt nach vorne (-Z)
	local siloCF = o * CFrame.new(-hw + 9, 0, 2)
	local r, h = 6.5, 22
	local body = part(model, "SiloBody", Vector3.new(h, r * 2, r * 2), siloCF * CFrame.new(0, 3 + h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), SILO, Enum.Material.Metal)
	body.Shape = Enum.PartType.Cylinder
	for i = 1, 3 do
		local ring = part(model, `SiloRing{i}`, Vector3.new(0.4, r * 2 + 0.3, r * 2 + 0.3), siloCF * CFrame.new(0, 3 + i * (h / 4), 0) * CFrame.Angles(0, 0, math.rad(90)), WALL_DARK, Enum.Material.Metal)
		ring.Shape = Enum.PartType.Cylinder
	end
	local cap = part(model, "SiloCap", Vector3.new(r * 1.6, r * 1.6, r * 1.6), siloCF * CFrame.new(0, 3 + h, 0), SILO, Enum.Material.Metal)
	cap.Shape = Enum.PartType.Ball
	for i, p in { Vector2.new(r - 1, r - 1), Vector2.new(-r + 1, r - 1), Vector2.new(r - 1, -r + 1), Vector2.new(-r + 1, -r + 1) } do
		part(model, `SiloLeg{i}`, Vector3.new(0.8, 3.4, 0.8), siloCF * CFrame.new(p.X, 1.7, p.Y), STEEL, Enum.Material.Metal)
	end
	part(model, "SiloPipe", Vector3.new(1.2, 1.2, 12), siloCF * CFrame.new(r + 1, h - 2, 6) , WALL_DARK, Enum.Material.Metal)
	part(model, "SiloLadder", Vector3.new(1.4, h, 0.3), siloCF * CFrame.new(r * 0.7, 3 + h / 2, -r * 0.75) * CFrame.Angles(0, math.rad(45), 0), STEEL, Enum.Material.DiamondPlate)

	-- Füllanzeige am Silo (aus normaler Entfernung lesbar, docs/06 §16)
	local display = part(model, "StorageDisplay", Vector3.new(9, 4.5, 0.3), siloCF * CFrame.new(0, 9, -r - 0.4), Color3.fromRGB(24, 27, 33), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Parent = display
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.3, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(165, 172, 184)
	title.Text = "STORAGE"
	title.Parent = gui
	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Position = UDim2.fromScale(0, 0.3)
	amount.Size = UDim2.new(1, 0, 0.42, 0)
	amount.BackgroundTransparency = 1
	amount.Font = Enum.Font.GothamBlack
	amount.TextScaled = true
	amount.TextColor3 = Color3.fromRGB(240, 242, 245)
	amount.Text = "0 / 0"
	amount.Parent = gui
	local barBack = Instance.new("Frame")
	barBack.Name = "Bar"
	barBack.Position = UDim2.fromScale(0.06, 0.78)
	barBack.Size = UDim2.fromScale(0.88, 0.14)
	barBack.BackgroundColor3 = Color3.fromRGB(48, 53, 63)
	barBack.BorderSizePixel = 0
	barBack.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(88, 196, 120)
	fill.BorderSizePixel = 0
	fill.Parent = barBack

	-- Terminal vorne im Lagerbereich: Rucksack abladen / Material entnehmen
	local terminalCF = o * CFrame.new(10, 0, -hd + 6)
	part(model, "TerminalPost", Vector3.new(1.4, 3.6, 1.4), terminalCF * CFrame.new(0, 1.8, 0), STEEL, Enum.Material.Metal)
	local screen = part(model, "TerminalScreen", Vector3.new(3, 2, 0.4), terminalCF * CFrame.new(0, 4.2, 0) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(90, 170, 255), Enum.Material.Neon)
	screen.Transparency = 0.1
	local promptPart = part(model, "StorageTerminalPart", Vector3.new(3, 4, 3), terminalCF * CFrame.new(0, 3, -1.5), WALL, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StoragePrompt"
	prompt.ActionText = "Storage"
	prompt.ObjectText = "Company Storage"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("StorageTerminal", true)
	prompt.Parent = promptPart

	return model
end

-- Füllanzeige aktualisieren
function HallTemplates.setStorageDisplay(storageModel: Model, used: number, capacity: number, text: string)
	local display = storageModel:FindFirstChild("StorageDisplay")
	local gui = display and display:FindFirstChild("Display")
	if not gui then
		return
	end
	local amount = gui:FindFirstChild("Amount")
	if amount and amount:IsA("TextLabel") then
		amount.Text = text
	end
	local bar = gui:FindFirstChild("Bar")
	local fill = bar and bar:FindFirstChild("Fill")
	if fill and fill:IsA("Frame") then
		local ratio = if capacity > 0 then math.clamp(used / capacity, 0, 1) else 0
		fill.Size = UDim2.fromScale(ratio, 1)
		fill.BackgroundColor3 = if ratio >= 1 then Color3.fromRGB(226, 92, 92) elseif ratio >= 0.8 then Color3.fromRGB(240, 180, 70) else Color3.fromRGB(88, 196, 120)
	end
end

return table.freeze(HallTemplates)
