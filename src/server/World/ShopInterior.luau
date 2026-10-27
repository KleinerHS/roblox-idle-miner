--!strict
-- Einrichtungs-Baukasten für die Läden (D-063, Felix 2026-10-26: „alle Läden von innen überarbeiten,
-- orientier dich an echten Läden vom Innenaufbau“). Alle Funktionen bauen im lokalen Rahmen `cf`:
-- Fußpunkt auf dem Boden, LookVector = Vorderseite (dort steht der Kunde bzw. sitzt die Person).
-- Reine Optik, keine Scripts.

local ShopInterior = {}

local STEEL = Color3.fromRGB(70, 74, 80)
local STEEL_DARK = Color3.fromRGB(40, 42, 46)
local STEEL_LIGHT = Color3.fromRGB(180, 184, 190)
local WHITE = Color3.fromRGB(244, 244, 240)
local WOOD = Color3.fromRGB(150, 108, 70)
local WOOD_DARK = Color3.fromRGB(96, 68, 44)
local BLACK = Color3.fromRGB(26, 27, 30)
local GREEN = Color3.fromRGB(70, 140, 80)
local GREEN_DARK = Color3.fromRGB(50, 110, 62)
local SCREEN = Color3.fromRGB(60, 150, 210)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local FONT_BOLD = Font.fromEnum(Enum.Font.GothamBold)

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
ShopInterior.part = part

local function deco(p: Part): Part
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function ShopInterior.text(target: BasePart, text: string, color: Color3, face: Enum.NormalId?, bold: boolean?, bg: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.3
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if bg then 0 else 1
	label.BackgroundColor3 = bg or Color3.new()
	label.FontFace = if bold then FONT_BOLD else FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = label
end

-- Topfpflanze (groß), size ≈ Gesamthöhe
function ShopInterior.plant(parent: Instance, name: string, cf: CFrame, size: number?)
	local s = size or 5
	local m = model(parent, name)
	local pot = part(m, "Pot", Vector3.new(s * 0.32, s * 0.4, s * 0.4), cf * CFrame.new(0, s * 0.16, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(230, 226, 218), Enum.Material.Concrete)
	pot.Shape = Enum.PartType.Cylinder
	part(m, "Stem", Vector3.new(0.25, s * 0.4, 0.25), cf * CFrame.new(0, s * 0.5, 0), WOOD_DARK, Enum.Material.Wood)
	for i, o in { Vector3.new(0, 0.78, 0), Vector3.new(0.18, 0.62, 0.1), Vector3.new(-0.16, 0.66, -0.12) } do
		local leaf = deco(part(m, `Leaves{i}`, Vector3.new(s * 0.42, s * 0.36, s * 0.42), cf * CFrame.new(o.X * s, o.Y * s, o.Z * s), if i == 1 then GREEN else GREEN_DARK, Enum.Material.Grass))
		leaf.Shape = Enum.PartType.Ball
	end
end

-- Schreibtisch mit Monitor, Tastatur, Tischlampe; Kunde sitzt vorne (-Z), Mitarbeiter hinten
function ShopInterior.desk(parent: Instance, name: string, cf: CFrame, top: Color3?, front: Color3?)
	local m = model(parent, name)
	part(m, "Top", Vector3.new(7, 0.3, 3.4), cf * CFrame.new(0, 2.9, 0), top or WHITE, Enum.Material.SmoothPlastic)
	part(m, "Front", Vector3.new(7, 2.6, 0.25), cf * CFrame.new(0, 1.45, -1.5), front or STEEL, Enum.Material.SmoothPlastic)
	for _, dx in { -3.3, 3.3 } do
		part(m, `Side{dx}`, Vector3.new(0.25, 2.75, 3.2), cf * CFrame.new(dx, 1.38, 0), front or STEEL, Enum.Material.SmoothPlastic)
	end
	part(m, "MonitorFoot", Vector3.new(1, 0.1, 0.7), cf * CFrame.new(1.2, 3.1, 0.6), BLACK)
	part(m, "MonitorArm", Vector3.new(0.2, 1, 0.2), cf * CFrame.new(1.2, 3.6, 0.7), BLACK)
	part(m, "Monitor", Vector3.new(2.6, 1.6, 0.15), cf * CFrame.new(1.2, 4.6, 0.6) * CFrame.Angles(0, math.rad(180), 0), BLACK)
	deco(part(m, "Screen", Vector3.new(2.4, 1.4, 0.02), cf * CFrame.new(1.2, 4.6, 0.69), SCREEN, Enum.Material.Neon)).Transparency = 0.3
	part(m, "Keyboard", Vector3.new(1.8, 0.08, 0.6), cf * CFrame.new(1.2, 3.09, 1.2), BLACK)
	part(m, "Papers", Vector3.new(1, 0.06, 1.3), cf * CFrame.new(-1.6, 3.08, -0.2) * CFrame.Angles(0, math.rad(12), 0), WHITE)
	part(m, "LampFoot", Vector3.new(0.6, 0.1, 0.6), cf * CFrame.new(-2.8, 3.1, 0.9), STEEL_DARK)
	part(m, "LampArm", Vector3.new(0.12, 1.4, 0.12), cf * CFrame.new(-2.8, 3.8, 0.9), STEEL_DARK)
	deco(part(m, "LampHead", Vector3.new(0.6, 0.3, 0.6), cf * CFrame.new(-2.8, 4.5, 0.7), Color3.fromRGB(255, 236, 200), Enum.Material.Neon))
end

-- Bürostuhl (Sitz zeigt nach -Z)
function ShopInterior.officeChair(parent: Instance, name: string, cf: CFrame, color: Color3?)
	local m = model(parent, name)
	local c = color or BLACK
	part(m, "Base", Vector3.new(1.8, 0.2, 1.8), cf * CFrame.new(0, 0.25, 0), STEEL_DARK)
	part(m, "Column", Vector3.new(0.3, 1.4, 0.3), cf * CFrame.new(0, 1, 0), STEEL_DARK)
	part(m, "Seat", Vector3.new(1.8, 0.4, 1.8), cf * CFrame.new(0, 1.8, 0), c, Enum.Material.Fabric)
	part(m, "Back", Vector3.new(1.7, 2, 0.3), cf * CFrame.new(0, 3, 0.85), c, Enum.Material.Fabric)
end

-- Sessel (Sitz zeigt nach -Z)
function ShopInterior.armchair(parent: Instance, name: string, cf: CFrame, color: Color3)
	local m = model(parent, name)
	part(m, "Seat", Vector3.new(3, 1.2, 3), cf * CFrame.new(0, 0.9, 0), color, Enum.Material.Fabric)
	part(m, "Back", Vector3.new(3, 2.2, 0.7), cf * CFrame.new(0, 2.1, 1.15), color, Enum.Material.Fabric)
	for _, dx in { -1.35, 1.35 } do
		part(m, `Arm{dx}`, Vector3.new(0.5, 1.8, 3), cf * CFrame.new(dx, 1.2, 0), color:Lerp(BLACK, 0.15), Enum.Material.Fabric)
	end
end

-- Sofa (Breite w, Sitz zeigt nach -Z)
function ShopInterior.sofa(parent: Instance, name: string, cf: CFrame, w: number, color: Color3)
	local m = model(parent, name)
	part(m, "Seat", Vector3.new(w, 1.2, 3), cf * CFrame.new(0, 0.9, 0), color, Enum.Material.Fabric)
	part(m, "Back", Vector3.new(w, 2.4, 0.8), cf * CFrame.new(0, 2.2, 1.1), color, Enum.Material.Fabric)
	for _, dx in { -1, 1 } do
		part(m, `Arm{dx}`, Vector3.new(0.6, 1.8, 3), cf * CFrame.new(dx * (w / 2 - 0.3), 1.2, 0), color:Lerp(BLACK, 0.15), Enum.Material.Fabric)
	end
	for i = 1, math.max(1, math.floor(w / 3)) do
		local x = -w / 2 + (i - 0.5) * (w / math.max(1, math.floor(w / 3)))
		part(m, `Cushion{i}`, Vector3.new(1.6, 1.2, 0.4), cf * CFrame.new(x, 2.1, 0.5) * CFrame.Angles(math.rad(-10), 0, 0), color:Lerp(WHITE, 0.25), Enum.Material.Fabric)
	end
end

function ShopInterior.coffeeTable(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	part(m, "Top", Vector3.new(4, 0.25, 2.2), cf * CFrame.new(0, 1.3, 0), WHITE, Enum.Material.Marble)
	part(m, "Leg", Vector3.new(3.4, 1.1, 1.6), cf * CFrame.new(0, 0.6, 0), STEEL_DARK)
	for i, c in { Color3.fromRGB(200, 60, 50), Color3.fromRGB(60, 110, 190) } do
		part(m, `Magazine{i}`, Vector3.new(1, 0.06, 1.3), cf * CFrame.new(-0.9 + i * 0.6, 1.46 + i * 0.03, 0) * CFrame.Angles(0, math.rad(i * 14), 0), c)
	end
end

-- Kaffeeautomat auf Theke + Wasserspender daneben
function ShopInterior.coffeeCorner(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	part(m, "Counter", Vector3.new(6, 3, 2.2), cf * CFrame.new(0, 1.5, 0), WOOD_DARK, Enum.Material.Wood)
	part(m, "CounterTop", Vector3.new(6.2, 0.2, 2.4), cf * CFrame.new(0, 3.1, 0), WHITE, Enum.Material.Marble)
	part(m, "Machine", Vector3.new(1.6, 2, 1.4), cf * CFrame.new(-1.6, 4.2, 0.2), BLACK, Enum.Material.Metal)
	deco(part(m, "MachineLight", Vector3.new(0.8, 0.3, 0.05), cf * CFrame.new(-1.6, 4.8, -0.52), Color3.fromRGB(120, 220, 255), Enum.Material.Neon))
	for i = 1, 3 do
		local cup = part(m, `Cup{i}`, Vector3.new(0.5, 0.35, 0.35), cf * CFrame.new(0.4 + i * 0.6, 3.38, -0.3) * CFrame.Angles(0, 0, math.rad(90)), WHITE)
		cup.Shape = Enum.PartType.Cylinder
	end
	part(m, "CoolerBody", Vector3.new(1.4, 3.2, 1.4), cf * CFrame.new(4.2, 1.6, 0), WHITE)
	local bottle = part(m, "CoolerBottle", Vector3.new(1.6, 1.1, 1.1), cf * CFrame.new(4.2, 4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 200, 235), Enum.Material.Glass)
	bottle.Shape = Enum.PartType.Cylinder
	bottle.Transparency = 0.3
end

-- Prospektständer
function ShopInterior.brochureStand(parent: Instance, name: string, cf: CFrame, colors: { Color3 })
	local m = model(parent, name)
	part(m, "Foot", Vector3.new(1.6, 0.15, 1.2), cf * CFrame.new(0, 0.1, 0), STEEL_DARK)
	part(m, "Back", Vector3.new(1.6, 4.2, 0.15), cf * CFrame.new(0, 2.3, 0.3), STEEL_LIGHT, Enum.Material.Metal)
	for row = 1, 3 do
		part(m, `Pocket{row}`, Vector3.new(1.5, 0.08, 0.5), cf * CFrame.new(0, 0.9 + row * 1.1, 0), STEEL_LIGHT, Enum.Material.Metal)
		part(m, `Brochure{row}`, Vector3.new(1.2, 1, 0.08), cf * CFrame.new(0, 1.4 + row * 1.1, 0.1) * CFrame.Angles(math.rad(-10), 0, 0), colors[(row - 1) % #colors + 1])
	end
end

-- Gondelregal (doppelseitig), Länge entlang lokal Z, mit Waren in Firmenfarben
function ShopInterior.gondola(parent: Instance, name: string, cf: CFrame, length: number, height: number, colors: { Color3 }, rng: Random)
	local m = model(parent, name)
	part(m, "Base", Vector3.new(3.6, 0.6, length), cf * CFrame.new(0, 0.3, 0), STEEL_DARK)
	part(m, "Spine", Vector3.new(0.3, height, length), cf * CFrame.new(0, height / 2, 0), WHITE)
	part(m, "EndCapA", Vector3.new(3.6, height, 0.3), cf * CFrame.new(0, height / 2, -length / 2), colors[1])
	part(m, "EndCapB", Vector3.new(3.6, height, 0.3), cf * CFrame.new(0, height / 2, length / 2), colors[1])
	for level = 1, 3 do
		local y = 0.6 + level * (height - 1) / 3.4
		for _, side in { -1, 1 } do
			part(m, `Shelf{level}{side}`, Vector3.new(1.5, 0.12, length - 0.4), cf * CFrame.new(side * 0.95, y, 0), STEEL_LIGHT, Enum.Material.Metal)
			-- Preisleiste
			deco(part(m, `PriceRail{level}{side}`, Vector3.new(0.05, 0.25, length - 0.6), cf * CFrame.new(side * 1.72, y - 0.1, 0), Color3.fromRGB(250, 214, 60)))
			local z = -length / 2 + 0.6
			local k = 0
			while z < length / 2 - 0.8 do
				k += 1
				local w = rng:NextNumber(0.7, 1.4)
				local h = rng:NextNumber(0.6, 1.2)
				local box = deco(part(m, `Item{level}{side}{k}`, Vector3.new(1.1, h, w), cf * CFrame.new(side * 1.05, y + 0.06 + h / 2, z + w / 2), colors[rng:NextInteger(1, #colors)]))
				box.CanCollide = false
				z += w + 0.15
			end
		end
	end
	return m
end

-- Wandregal (Rückseite an der Wand, Waren nach -Z), Länge entlang lokal X
function ShopInterior.wallShelf(parent: Instance, name: string, cf: CFrame, length: number, levels: number, colors: { Color3 }, rng: Random)
	local m = model(parent, name)
	part(m, "Back", Vector3.new(length, 1.2 + levels * 2.2, 0.2), cf * CFrame.new(0, (1.2 + levels * 2.2) / 2, 0.9), WHITE)
	for level = 1, levels do
		local y = 0.4 + (level - 1) * 2.2
		part(m, `Shelf{level}`, Vector3.new(length, 0.15, 1.8), cf * CFrame.new(0, y, 0), STEEL_LIGHT, Enum.Material.Metal)
		local x = -length / 2 + 0.4
		local k = 0
		while x < length / 2 - 0.8 do
			k += 1
			local w = rng:NextNumber(0.8, 1.6)
			local h = rng:NextNumber(0.7, 1.6)
			deco(part(m, `Item{level}_{k}`, Vector3.new(w, h, 1.2), cf * CFrame.new(x + w / 2, y + 0.08 + h / 2, -0.1), colors[rng:NextInteger(1, #colors)]))
			x += w + 0.2
		end
	end
	for _, dx in { -length / 2, length / 2 } do
		part(m, `Post{dx}`, Vector3.new(0.2, 1.2 + levels * 2.2, 1.9), cf * CFrame.new(dx, (1.2 + levels * 2.2) / 2, 0), STEEL_DARK)
	end
	return m
end

-- Hängendes Schild an zwei Seilen (Text auf beiden Seiten)
function ShopInterior.hangingSign(parent: Instance, name: string, cf: CFrame, text: string, bg: Color3, fg: Color3, width: number?, ceilingY: number?)
	local m = model(parent, name)
	local w = width or 8
	local board = part(m, "Board", Vector3.new(w, 1.8, 0.2), cf, bg)
	deco(board)
	ShopInterior.text(board, text, fg, Enum.NormalId.Front)
	ShopInterior.text(board, text, fg, Enum.NormalId.Back)
	if ceilingY then
		local len = ceilingY - cf.Y
		for _, dx in { -w / 2 + 0.6, w / 2 - 0.6 } do
			deco(part(m, `Wire{dx}`, Vector3.new(0.06, len, 0.06), cf * CFrame.new(dx, len / 2 + 0.9, 0), STEEL_DARK))
		end
	end
end

-- Poster an der Wand (Vorderseite nach -Z)
function ShopInterior.poster(parent: Instance, name: string, cf: CFrame, w: number, h: number, title: string, bg: Color3, fg: Color3)
	local m = model(parent, name)
	deco(part(m, "Frame", Vector3.new(w + 0.4, h + 0.4, 0.1), cf * CFrame.new(0, 0, 0.05), BLACK))
	local board = deco(part(m, "Poster", Vector3.new(w, h, 0.1), cf, bg))
	ShopInterior.text(board, title, fg, Enum.NormalId.Front)
end

-- Wanduhr
function ShopInterior.clock(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	local face = deco(part(m, "Face", Vector3.new(0.2, 2.2, 2.2), cf * CFrame.Angles(0, math.rad(90), 0), WHITE))
	face.Shape = Enum.PartType.Cylinder
	deco(part(m, "Hour", Vector3.new(0.12, 0.6, 0.05), cf * CFrame.new(0, 0.25, -0.12), BLACK))
	deco(part(m, "Minute", Vector3.new(0.08, 0.9, 0.05), cf * CFrame.new(0.3, 0.1, -0.13) * CFrame.Angles(0, 0, math.rad(-70)), BLACK))
end

-- Notausgang-Schild (leuchtend grün)
function ShopInterior.exitSign(parent: Instance, name: string, cf: CFrame)
	local board = deco(part(parent, name, Vector3.new(2.6, 0.9, 0.15), cf, Color3.fromRGB(30, 150, 70), Enum.Material.Neon))
	ShopInterior.text(board, "EXIT  ➜", WHITE, Enum.NormalId.Front, true)
end

-- Diebstahlsicherung am Eingang (Paar Säulen)
function ShopInterior.securityGate(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	part(m, "Foot", Vector3.new(0.8, 0.2, 1.4), cf * CFrame.new(0, 0.1, 0), STEEL_DARK)
	local pane = part(m, "Pane", Vector3.new(0.3, 5, 1.2), cf * CFrame.new(0, 2.7, 0), Color3.fromRGB(200, 220, 230), Enum.Material.Glass)
	pane.Transparency = 0.4
	deco(part(m, "Light", Vector3.new(0.32, 0.25, 1.22), cf * CFrame.new(0, 5.1, 0), Color3.fromRGB(120, 200, 255), Enum.Material.Neon))
end

-- Stapel Einkaufskörbe
function ShopInterior.basketStack(parent: Instance, name: string, cf: CFrame, color: Color3)
	local m = model(parent, name)
	for i = 1, 6 do
		part(m, `Basket{i}`, Vector3.new(1.8, 0.5, 1.3), cf * CFrame.new(0, 0.25 + (i - 1) * 0.32, 0), color, Enum.Material.SmoothPlastic)
	end
	part(m, "Handle", Vector3.new(0.1, 0.8, 1.2), cf * CFrame.new(0, 2.3, 0), STEEL_DARK)
end

-- Kasse: Theke mit Laufband, Kasse, Kartenterminal, Quengelregal (Kunde vorne bei -Z, Kassierer hinten)
function ShopInterior.checkout(parent: Instance, name: string, cf: CFrame, accent: Color3, rng: Random)
	local m = model(parent, name)
	part(m, "Body", Vector3.new(3, 3.2, 9), cf * CFrame.new(0, 1.6, 0), WHITE)
	part(m, "Stripe", Vector3.new(3.05, 0.5, 9.05), cf * CFrame.new(0, 2.2, 0), accent)
	part(m, "Belt", Vector3.new(2.2, 0.15, 5.5), cf * CFrame.new(0, 3.28, -1.6), BLACK, Enum.Material.Rubber)
	part(m, "Top", Vector3.new(3.2, 0.2, 3.2), cf * CFrame.new(0, 3.3, 2.8), STEEL_LIGHT, Enum.Material.Metal)
	part(m, "Register", Vector3.new(1.4, 0.8, 1.4), cf * CFrame.new(0.6, 3.8, 2.6), BLACK)
	part(m, "RegisterScreen", Vector3.new(0.12, 1.1, 1.4), cf * CFrame.new(0.6, 4.7, 3.2) * CFrame.Angles(0, 0, math.rad(-15)), BLACK)
	part(m, "CardTerminal", Vector3.new(0.6, 0.9, 0.4), cf * CFrame.new(-1.1, 3.8, 1.2) * CFrame.Angles(math.rad(-25), 0, 0), STEEL_DARK)
	-- Quengelregal am Kassenbeginn
	part(m, "ImpulseRack", Vector3.new(0.4, 4.2, 3), cf * CFrame.new(-2, 2.1, -3.2), STEEL_DARK)
	for level = 1, 3 do
		for k = 1, 4 do
			deco(part(m, `Impulse{level}{k}`, Vector3.new(0.5, 0.5, 0.6), cf * CFrame.new(-2.45, 0.6 + level * 1.1, -4.4 + k * 0.7), Color3.fromHSV(rng:NextNumber(), 0.7, 0.9)))
		end
	end
	-- Kassen-Nummer
	part(m, "LanePole", Vector3.new(0.2, 4, 0.2), cf * CFrame.new(1.2, 5.3, -4), STEEL_DARK)
	local num = part(m, "LaneLight", Vector3.new(1.2, 1, 0.3), cf * CFrame.new(1.2, 7.8, -4), accent, Enum.Material.Neon)
	deco(num)
	ShopInterior.text(num, "1", WHITE, Enum.NormalId.Front, true)
	ShopInterior.text(num, "1", WHITE, Enum.NormalId.Back, true)
end

-- Absperrpfosten mit Gurt (Warteschlange), Punkte entlang lokal Z
function ShopInterior.queue(parent: Instance, name: string, cf: CFrame, posts: number, spacing: number, belt: Color3)
	local m = model(parent, name)
	for i = 0, posts - 1 do
		part(m, `PostFoot{i}`, Vector3.new(1, 0.15, 1), cf * CFrame.new(0, 0.08, i * spacing), STEEL_DARK)
		part(m, `Post{i}`, Vector3.new(0.25, 3, 0.25), cf * CFrame.new(0, 1.6, i * spacing), STEEL_LIGHT, Enum.Material.Metal)
		if i > 0 then
			deco(part(m, `Belt{i}`, Vector3.new(0.08, 0.3, spacing), cf * CFrame.new(0, 2.8, (i - 0.5) * spacing), belt))
		end
	end
end

-- Schaufensterpuppe (stilisiert) mit Helm; gibt die Rücken-CFrame zurück (für Rucksack)
function ShopInterior.mannequin(parent: Instance, name: string, cf: CFrame, shirt: Color3, helmet: Color3?): CFrame
	local m = model(parent, name)
	part(m, "Stand", Vector3.new(1.6, 0.2, 1.6), cf * CFrame.new(0, 0.1, 0), STEEL_DARK)
	part(m, "Pole", Vector3.new(0.2, 2.4, 0.2), cf * CFrame.new(0, 1.3, 0), STEEL_LIGHT, Enum.Material.Metal)
	part(m, "Torso", Vector3.new(2, 2.4, 1), cf * CFrame.new(0, 3.7, 0), shirt, Enum.Material.Fabric)
	local head = part(m, "Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 5.6, 0), Color3.fromRGB(230, 226, 218))
	head.Shape = Enum.PartType.Ball
	if helmet then
		local hat = part(m, "Helmet", Vector3.new(1.5, 1.1, 1.5), cf * CFrame.new(0, 6, 0), helmet)
		hat.Shape = Enum.PartType.Ball
		deco(part(m, "Lamp", Vector3.new(0.5, 0.4, 0.2), cf * CFrame.new(0, 6.1, -0.75), Color3.fromRGB(255, 240, 200), Enum.Material.Neon))
	end
	return cf * CFrame.new(0, 3.7, 0.5)
end

-- Grubenhelm (für Regale)
function ShopInterior.helmet(parent: Instance, name: string, cf: CFrame, color: Color3)
	local h = deco(part(parent, name, Vector3.new(1.2, 0.9, 1.2), cf * CFrame.new(0, 0.45, 0), color))
	h.Shape = Enum.PartType.Ball
	deco(part(parent, `{name}Brim`, Vector3.new(1.5, 0.1, 1.5), cf * CFrame.new(0, 0.1, 0), color))
	deco(part(parent, `{name}Lamp`, Vector3.new(0.4, 0.3, 0.15), cf * CFrame.new(0, 0.55, -0.6), Color3.fromRGB(255, 240, 200), Enum.Material.Neon))
end

-- Schlüsselkasten an der Wand
function ShopInterior.keyCabinet(parent: Instance, name: string, cf: CFrame)
	local m = model(parent, name)
	part(m, "Box", Vector3.new(3, 2.4, 0.4), cf, STEEL_DARK, Enum.Material.Metal)
	for r = 1, 3 do
		for c = 1, 5 do
			deco(part(m, `Key{r}{c}`, Vector3.new(0.15, 0.4, 0.1), cf * CFrame.new(-1.2 + c * 0.4, 1 - r * 0.6, -0.25), Color3.fromRGB(220, 190, 70), Enum.Material.Metal))
		end
	end
end

-- Fernseher an der Wand
function ShopInterior.tv(parent: Instance, name: string, cf: CFrame, w: number, title: string, accent: Color3)
	local m = model(parent, name)
	part(m, "Bezel", Vector3.new(w, w * 0.58, 0.3), cf, BLACK)
	local screen = deco(part(m, "Screen", Vector3.new(w - 0.3, w * 0.58 - 0.3, 0.05), cf * CFrame.new(0, 0, -0.18), accent, Enum.Material.Neon))
	screen.Transparency = 0.15
	ShopInterior.text(screen, title, WHITE, Enum.NormalId.Front)
end

-- Rasterdecke mit Lichtpanels (unter dem Dach)
function ShopInterior.ceilingLights(parent: Instance, name: string, cf: CFrame, w: number, d: number, y: number, step: number, color: Color3)
	local m = model(parent, name)
	local nx, nz = math.max(1, math.floor(w / step)), math.max(1, math.floor(d / step))
	for ix = 1, nx do
		for iz = 1, nz do
			local x = -w / 2 + (ix - 0.5) * (w / nx)
			local z = -d / 2 + (iz - 0.5) * (d / nz)
			local panel = deco(part(m, `Panel{ix}_{iz}`, Vector3.new(3, 0.15, 3), cf * CFrame.new(x, y, z), color, Enum.Material.Neon))
			if (ix + iz) % 2 == 0 then
				local light = Instance.new("SurfaceLight")
				light.Face = Enum.NormalId.Bottom
				light.Range = 16
				light.Angle = 120
				light.Brightness = 0.8
				light.Color = color
				light.Parent = panel
			end
		end
	end
end

-- Bodenteppich / Zone (flach)
function ShopInterior.rug(parent: Instance, name: string, cf: CFrame, w: number, d: number, color: Color3, y: number?)
	local r = part(parent, name, Vector3.new(w, 0.06, d), cf * CFrame.new(0, (y or 0) + 0.03, 0), color, Enum.Material.Fabric)
	r.CanCollide = false
	r.CastShadow = false
	return r
end

-- Tür mit Schild (an der Wand, Vorderseite -Z)
function ShopInterior.door(parent: Instance, name: string, cf: CFrame, label: string, color: Color3)
	local m = model(parent, name)
	part(m, "Frame", Vector3.new(4.2, 8.2, 0.3), cf * CFrame.new(0, 4.1, 0.1), STEEL_DARK)
	part(m, "Leaf", Vector3.new(3.6, 7.8, 0.3), cf * CFrame.new(0, 3.9, 0), color)
	part(m, "Handle", Vector3.new(0.6, 0.15, 0.2), cf * CFrame.new(-1.2, 3.8, -0.2), STEEL_LIGHT, Enum.Material.Metal)
	local plate = deco(part(m, "Plate", Vector3.new(2.6, 0.7, 0.05), cf * CFrame.new(0, 6, -0.18), WHITE))
	ShopInterior.text(plate, label, BLACK, Enum.NormalId.Front, true)
end

-- Reifenstapel
function ShopInterior.tireStack(parent: Instance, name: string, cf: CFrame, count: number, r: number)
	local m = model(parent, name)
	for i = 1, count do
		local t = part(m, `Tire{i}`, Vector3.new(r * 0.55, r * 2, r * 2), cf * CFrame.new(0, (i - 0.5) * r * 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, Enum.Material.Rubber)
		t.Shape = Enum.PartType.Cylinder
		local rim = deco(part(m, `Rim{i}`, Vector3.new(r * 0.57, r * 1.1, r * 1.1), t.CFrame, STEEL_LIGHT, Enum.Material.Metal))
		rim.Shape = Enum.PartType.Cylinder
	end
end

-- Verkäufer hinter dem Tresen (Felix 2026-10-27): Roblox-Figur aus einer HumanoidDescription,
-- verankert, ohne Namensschild; Blick nach lokal -Z. Fällt bei Fehler auf eine Klötzchenfigur zurück.
function ShopInterior.clerk(parent: Instance, name: string, cf: CFrame, shirt: Color3)
	local ok, rig = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = Color3.fromRGB(234, 184, 146)
		desc.LeftArmColor = desc.HeadColor
		desc.RightArmColor = desc.HeadColor
		desc.LeftLegColor = Color3.fromRGB(40, 44, 52)
		desc.RightLegColor = desc.LeftLegColor
		desc.TorsoColor = shirt
		return game:GetService("Players"):CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and rig then
		rig.Name = name
		local hum = rig:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
		for _, d in rig:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
			end
		end
		local hrp = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hip = if hum then hum.HipHeight else 2
		if hrp then
			rig.PrimaryPart = hrp
			rig:PivotTo(cf * CFrame.new(0, hip + hrp.Size.Y / 2, 0))
		end
		rig.Parent = parent
		return
	end
	-- Rückfall: einfache Figur
	local m = model(parent, name)
	local skin = Color3.fromRGB(234, 184, 146)
	part(m, "Legs", Vector3.new(1.8, 2.4, 1), cf * CFrame.new(0, 1.2, 0), Color3.fromRGB(40, 44, 52))
	part(m, "Torso", Vector3.new(2, 2, 1), cf * CFrame.new(0, 3.4, 0), shirt)
	for _, x in { -1.3, 1.3 } do
		part(m, `Arm{x}`, Vector3.new(0.6, 2, 0.6), cf * CFrame.new(x, 3.4, 0), skin)
	end
	part(m, "Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 5, 0), skin)
end

return table.freeze(ShopInterior)
