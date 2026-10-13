--!strict
-- PLATZHALTER-Modelle für Hallenwände, Dach und Lager (D-002, D-010, docs/04 §18,
-- docs/06 §13–16, FACTORY_MASTERPLAN_TOPDOWN.png). Maße aus LayoutConfig.
--
-- Vereinbarte Namen/Attribute:
--   Lager: Part "StorageDisplay" (SurfaceGui "Display" mit "Amount", "Crates" und "Fill"),
--          Folder "Crates" mit Slot1..SlotN (Palette, Gitterbox, "Fill" = Erz),
--          Part "StorageTerminalPart" mit ProximityPrompt "StoragePrompt" (Attribute StorageTerminal = true)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LayoutConfig)
local BalanceConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.BalanceConfig)
local CrateRackBuilder = require(script.Parent.CrateRackBuilder)

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
-- Hochregallager (Phase 13b-3, Felix D-037): 32 große Regale in vier Reihen (eine Doppelreihe),
-- je 4 Palettenboxen übereinander (CrateRackBuilder). Vorne: Anzeige und Terminal.
-- 12 Regale je Reihe bis zur Bereichsmarkierung rechts (Felix 2026-10-13), Block nach rechts versetzt
local RACKS_PER_ROW = 12
local RACK_SHIFT_X = -18
local STORAGE_ROWS = {
	{ Z = -9, Face = -1 },
	{ Z = 15, Face = -1 },
	{ Z = 23.5, Face = 1 },
	{ Z = 47, Face = -1 },
}

function HallTemplates.buildStorage(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Storage"
	local zone = LayoutConfig.HallZones.Storage
	local o = plotCFrame * CFrame.new(zone.Center.X, LayoutConfig.HallFloorTop, zone.Center.Y)
	local hw, hd = zone.Size.X / 2, zone.Size.Y / 2

	CrateRackBuilder.build(model, o * CFrame.new(RACK_SHIFT_X, 0, 0), STORAGE_ROWS, RACKS_PER_ROW)

	-- Fahrwege: gelbe Linien vor den Reihen, Gabelstapler und lose Paletten links
	for i, z in { 35.25, 3 } do
		local lane = part(model, `LaneLine{i}`, Vector3.new(RACKS_PER_ROW * CrateRackBuilder.Bay + 8, 0.06, 0.5), o * CFrame.new(RACK_SHIFT_X, 0.03, z), YELLOW, Enum.Material.SmoothPlastic)
		lane.CanCollide = false
	end
	local frontLane = part(model, "LaneFront", Vector3.new(RACKS_PER_ROW * CrateRackBuilder.Bay + 8, 0.06, 0.5), o * CFrame.new(RACK_SHIFT_X, 0.03, -18), YELLOW, Enum.Material.SmoothPlastic)
	frontLane.CanCollide = false
	local fork = o * CFrame.new(hw - 18, 0, -20) * CFrame.Angles(0, math.rad(-20), 0)
	part(model, "ForkliftBody", Vector3.new(4, 2.4, 6), fork * CFrame.new(0, 2.2, 0), YELLOW, Enum.Material.SmoothPlastic)
	part(model, "ForkliftWeight", Vector3.new(4, 2.2, 1.4), fork * CFrame.new(0, 2.3, 3.4), STEEL, Enum.Material.Metal)
	part(model, "ForkliftRoof", Vector3.new(4, 0.25, 4.6), fork * CFrame.new(0, 7.9, 0.2), STEEL, Enum.Material.Metal)
	for _, dx in { -1.8, 1.8 } do
		part(model, `ForkliftPost{dx}`, Vector3.new(0.25, 4.6, 0.25), fork * CFrame.new(dx, 5.6, 2.4), STEEL, Enum.Material.Metal)
		part(model, `ForkliftMast{dx}`, Vector3.new(0.4, 7, 0.4), fork * CFrame.new(dx * 0.8, 4.4, -3.2), STEEL, Enum.Material.Metal)
		part(model, `ForkliftFork{dx}`, Vector3.new(0.4, 0.2, 3.4), fork * CFrame.new(dx * 0.6, 1.3, -4.9), STEEL, Enum.Material.Metal)
		for _, dz in { -1.8, 1.8 } do
			local w = part(model, `ForkliftWheel{dx}_{dz}`, Vector3.new(0.8, 1.8, 1.8), fork * CFrame.new(dx * 1.1, 0.9, dz), Color3.fromRGB(30, 30, 32), Enum.Material.Rubber)
			w.Shape = Enum.PartType.Cylinder
		end
	end
	for i = 1, 3 do
		part(model, `SparePallet{i}`, Vector3.new(6.2, 0.5, 6.2), o * CFrame.new(hw - 10, 0.25 + (i - 1) * 0.5, -40) * CFrame.Angles(0, math.rad(i * 3), 0), CRATE_DARK, Enum.Material.WoodPlanks)
	end

	-- Anzeige vorne (aus normaler Entfernung lesbar, docs/06 §16): Bestand und Kisten
	local displayCF = o * CFrame.new(0, 0, -hd + 6)
	for _, dx in { -5, 5 } do
		part(model, `DisplayPost{dx}`, Vector3.new(0.6, 9, 0.6), displayCF * CFrame.new(dx, 4.5, 0.3), STEEL, Enum.Material.Metal)
	end
	local display = part(model, "StorageDisplay", Vector3.new(12, 5, 0.3), displayCF * CFrame.new(0, 10, 0), Color3.fromRGB(24, 27, 33), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Parent = display
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.26, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(165, 172, 184)
	title.Text = "STORAGE"
	title.Parent = gui
	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Position = UDim2.fromScale(0, 0.26)
	amount.Size = UDim2.new(1, 0, 0.34, 0)
	amount.BackgroundTransparency = 1
	amount.Font = Enum.Font.GothamBlack
	amount.TextScaled = true
	amount.TextColor3 = Color3.fromRGB(240, 242, 245)
	amount.Text = "0 / 0"
	amount.Parent = gui
	local crates = Instance.new("TextLabel")
	crates.Name = "Crates"
	crates.Position = UDim2.fromScale(0, 0.6)
	crates.Size = UDim2.new(1, 0, 0.18, 0)
	crates.BackgroundTransparency = 1
	crates.Font = Enum.Font.GothamBold
	crates.TextScaled = true
	crates.TextColor3 = Color3.fromRGB(200, 205, 214)
	crates.Text = ""
	crates.Parent = gui
	local barBack = Instance.new("Frame")
	barBack.Name = "Bar"
	barBack.Position = UDim2.fromScale(0.06, 0.82)
	barBack.Size = UDim2.fromScale(0.88, 0.12)
	barBack.BackgroundColor3 = Color3.fromRGB(48, 53, 63)
	barBack.BorderSizePixel = 0
	barBack.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(88, 196, 120)
	fill.BorderSizePixel = 0
	fill.Parent = barBack

	-- Terminal vorne links im Lagerbereich: Rucksack abladen / Material entnehmen
	local terminalCF = o * CFrame.new(hw - 30, 0, -hd + 8)
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

-- Anzeige und Regalbelegung aktualisieren: gekaufte Kisten sichtbar, Sorten der Reihe nach
-- (Stufe), jede Sorte belegt ceil(Menge / Kistengröße) Kisten, Füllhöhe zeigt die Menge.
function HallTemplates.setStorageDisplay(storageModel: Model, storage: { Crates: number, Capacity: number, Items: { [string]: number } }, text: string)
	local used, capacity = 0, storage.Capacity
	for _, n in storage.Items do
		used += n
	end
	local display = storageModel:FindFirstChild("StorageDisplay", true)
	local gui = display and display:FindFirstChild("Display")
	if gui then
		local amount = gui:FindFirstChild("Amount")
		if amount and amount:IsA("TextLabel") then
			amount.Text = text
		end
		local size = BalanceConfig.Storage.CrateSize
		local usedCrates = 0
		for _, n in storage.Items do
			if n > 0 then
				usedCrates += math.ceil(n / size)
			end
		end
		local cratesLabel = gui:FindFirstChild("Crates")
		if cratesLabel and cratesLabel:IsA("TextLabel") then
			cratesLabel.Text = `{usedCrates} / {storage.Crates} crates`
		end
		local bar = gui:FindFirstChild("Bar")
		local fill = bar and bar:FindFirstChild("Fill")
		if fill and fill:IsA("Frame") then
			local ratio = if storage.Crates > 0 then math.clamp(usedCrates / storage.Crates, 0, 1) else 0
			fill.Size = UDim2.fromScale(ratio, 1)
			fill.BackgroundColor3 = if ratio >= 1 then Color3.fromRGB(226, 92, 92) elseif ratio >= 0.8 then Color3.fromRGB(240, 180, 70) else Color3.fromRGB(88, 196, 120)
		end
	end

	-- Kisten im Regal
	local slots = storageModel:FindFirstChild("Crates")
	if slots then
		CrateRackBuilder.update(slots, storage.Items, storage.Crates)
	end
end

return table.freeze(HallTemplates)
