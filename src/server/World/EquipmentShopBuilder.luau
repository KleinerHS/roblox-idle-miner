--!strict
-- Equipment-Shop in der Mitte (PLATZHALTER nach CENTRAL_AREA_REFERENCE.png, docs/10 §21–23):
-- blaue Front mit Schild "EQUIPMENT", Mining-Fachhandel aus Holz und Metall, Spitzhacken
-- an Wandhalterungen, Rucksäcke auf Tischen, Tresen mit Shop-Prompt.
-- Die Ausstellungsstücke werden aus den Definitionen gebaut (eine Hacke pro Pickaxe-Stufe,
-- ein Rucksack pro Backpack-Stufe) und haben keine Scripts (docs/10 §69).
--
-- Vereinbarte Namen/Attribute:
--   Model "EquipmentShop"
--   Part  "CounterPromptPart" mit ProximityPrompt "ShopPrompt" (Attribute ShopId = "equipment")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Pickaxes = require(Shared.Definitions.Pickaxes)
local Backpacks = require(Shared.Definitions.Backpacks)

local ShopDecor = require(script.Parent.ShopDecor)
local PickaxeModels = require(script.Parent.PickaxeModels)
local BackpackModels = require(script.Parent.BackpackModels)
local ShopInterior = require(script.Parent.ShopInterior)

local EquipmentShopBuilder = {}

local BLUE = Color3.fromRGB(44, 92, 170)
local BLUE_DARK = Color3.fromRGB(30, 62, 120)
local WOOD = Color3.fromRGB(150, 106, 66)
local WOOD_DARK = Color3.fromRGB(100, 70, 44)
local METAL = Color3.fromRGB(70, 74, 80)
local FLOOR = Color3.fromRGB(120, 92, 64)
local ROOF = Color3.fromRGB(96, 100, 108)
local GLASS = Color3.fromRGB(170, 210, 230)
local WHITE = Color3.fromRGB(240, 240, 236)
local LIGHT = Color3.fromRGB(255, 226, 180)
local CANVAS = { Color3.fromRGB(120, 96, 64), Color3.fromRGB(70, 96, 70), Color3.fromRGB(150, 70, 50) }

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

local function surfaceText(target: BasePart, text: string, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
end

-- Ausstellungs-Spitzhacke an der Wand (Kopf oben, leicht schräg)
local function displayPickaxe(parent: Instance, cf: CFrame, headColor: Color3, scale: number?)
	local s = scale or 1
	part(parent, "Handle", Vector3.new(0.3, 3.6, 0.3) * s, cf, WOOD, Enum.Material.Wood)
	part(parent, "Head", Vector3.new(3, 0.35, 0.35) * s, cf * CFrame.new(0, 1.7 * s, 0), headColor, Enum.Material.Metal)
	part(parent, "Hook", Vector3.new(0.6, 0.2, 0.6) * s, cf * CFrame.new(0, 1.2 * s, 0.3 * s), METAL, Enum.Material.Metal)
end

-- Ausstellungs-Rucksack (Größe wächst mit der Kapazität)
-- Größe je Stufe (Phase 12b: flacher, damit alle Stufen auf den Tisch passen)
local function backpackScale(tier: number): number
	return 0.9 + tier * 0.12
end

local function displayBackpack(parent: Instance, cf: CFrame, tier: number)
	local s = backpackScale(tier)
	local color = CANVAS[((tier - 1) % #CANVAS) + 1]
	part(parent, "Bag", Vector3.new(1.6 * s, 2 * s, 1 * s), cf * CFrame.new(0, s, 0), color, Enum.Material.Fabric)
	part(parent, "Flap", Vector3.new(1.65 * s, 0.6 * s, 1.05 * s), cf * CFrame.new(0, 1.8 * s, 0), color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Fabric)
	part(parent, "Pocket", Vector3.new(1 * s, 0.7 * s, 0.3), cf * CFrame.new(0, 0.7 * s, -0.55 * s), color:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Fabric)
end

function EquipmentShopBuilder.build(parent: Instance): Model
	local cfg = LayoutConfig.EquipmentShop
	local center = LayoutConfig.MapCenter
	local pos = Vector3.new(center.X + cfg.Offset.X, LayoutConfig.GroundY + 1, center.Z + cfg.Offset.Y)
	-- LookVector (= lokale -Z, Eingang) zeigt zur Platzmitte
	-- D-057: mit SectorAngle parallel zum Sektor ausgerichtet (Eingang zum Kreisverkehr)
	local sector = (cfg :: any).SectorAngle
	local o = if typeof(sector) == "number"
		then CFrame.lookAt(pos, pos - Vector3.new(math.cos(math.rad(sector)), 0, -math.sin(math.rad(sector))))
		else CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))

	local W, H, D = cfg.Size.X, cfg.Size.Y, cfg.Size.Z
	local t = 0.8
	local model = Instance.new("Model")
	model.Name = "EquipmentShop"

	local floor = part(model, "Floor", Vector3.new(W, 0.6, D), o * CFrame.new(0, 0.3, 0), FLOOR, Enum.Material.WoodPlanks)
	model.PrimaryPart = floor

	-- Außenwände blau, innen Holz
	part(model, "WallBack", Vector3.new(W, H, t), o * CFrame.new(0, H / 2, D / 2 - t / 2), BLUE, Enum.Material.Metal)
	part(model, "WallLeft", Vector3.new(t, H, D), o * CFrame.new(W / 2 - t / 2, H / 2, 0), BLUE, Enum.Material.Metal)
	part(model, "WallRight", Vector3.new(t, H, D), o * CFrame.new(-W / 2 + t / 2, H / 2, 0), BLUE, Enum.Material.Metal)
	part(model, "InnerBack", Vector3.new(W - 2 * t, H - 1, 0.3), o * CFrame.new(0, H / 2, D / 2 - t - 0.15), WOOD, Enum.Material.WoodPlanks)

	-- Front mit Eingang und Schaufenstern
	local front = -D / 2 + t / 2
	local doorW, doorH = 12, 12
	local sideW = (W - doorW) / 2
	for _, side in { 1, -1 } do
		local x = side * (doorW / 2 + sideW / 2)
		part(model, `FrontBase{side}`, Vector3.new(sideW, 2.6, t), o * CFrame.new(x, 1.3, front), BLUE_DARK, Enum.Material.Metal)
		-- große Schaufenster (D-060)
		local glass = part(model, `Window{side}`, Vector3.new(sideW - 2, 10, 0.3), o * CFrame.new(x, 7.6, front), GLASS, Enum.Material.Glass)
		glass.Transparency = 0.4
		for _, dy in { -5.2, 5.2 } do
			part(model, `WindowFrame{side}_{dy}`, Vector3.new(sideW - 1.4, 0.5, 0.5), o * CFrame.new(x, 7.6 + dy, front - 0.1), WHITE, Enum.Material.SmoothPlastic)
		end
		for _, dx in { -1, 1 } do
			part(model, `WindowPost{side}_{dx}`, Vector3.new(0.5, 10.9, 0.5), o * CFrame.new(x + dx * (sideW / 2 - 0.95), 7.6, front - 0.1), WHITE, Enum.Material.SmoothPlastic)
		end
		part(model, `FrontUpper{side}`, Vector3.new(sideW, H - 12.6, t), o * CFrame.new(x, 12.6 + (H - 12.6) / 2, front), BLUE, Enum.Material.Metal)
		ShopDecor.awning(model, `WindowAwning{side}`, o * CFrame.new(x, 13.4, front - 0.5), sideW - 1, 4.5, BLUE, WHITE)
		part(model, `DoorPost{side}`, Vector3.new(0.8, doorH, 1), o * CFrame.new(side * (doorW / 2 + 0.4), doorH / 2, front), BLUE_DARK, Enum.Material.Metal)
	end
	part(model, "DoorHeader", Vector3.new(doorW + 1.6, H - doorH, t), o * CFrame.new(0, doorH + (H - doorH) / 2, front), BLUE, Enum.Material.Metal)

	part(model, "Roof", Vector3.new(W + 2, 0.8, D + 2), o * CFrame.new(0, H + 0.4, 0), ROOF, Enum.Material.Metal)
	local sign = part(model, "Sign", Vector3.new(W * 0.6, 4, 0.5), o * CFrame.new(0, H - 3.4, -D / 2 - 0.4), BLUE_DARK, Enum.Material.SmoothPlastic)
	surfaceText(sign, "PICKAXES · BACKPACKS", WHITE)
	part(model, "Awning", Vector3.new(doorW + 6, 0.4, 4), o * CFrame.new(0, doorH + 0.8, -D / 2 - 2) * CFrame.Angles(math.rad(-8), 0, 0), BLUE_DARK, Enum.Material.Metal)

	-- Einladend (D-060): großes Dachschild, Fahne, Pflanzen, Bank
	ShopDecor.roofSign(model, "RoofSign", o * CFrame.new(0, H + 4.8, -D / 2 + 2), W * 0.7, 6, "⛏ PICKAXES", BLUE, WHITE, BLUE_DARK)
	-- Riesen-Spitzhacke auf dem Dach entfernt (Felix 2026-10-28)
	for _, side in { -1, 1 } do
		-- keine Fahnen mehr (Felix 2026-10-28 blaue, 2026-10-29 weiße entfernt)
		ShopDecor.planter(model, `DoorPlanter{side}`, o * CFrame.new(side * (doorW / 2 + 2.2), 0.6, -D / 2 - 2), 2.6)
	end
	local benchCF = o * CFrame.new(-W / 4, 0.6, -D / 2 - 3.5) * CFrame.Angles(0, math.rad(180), 0)
	part(model, "BenchSeat", Vector3.new(5, 0.3, 1.6), benchCF * CFrame.new(0, 1.5, 0), WOOD, Enum.Material.Wood)
	part(model, "BenchBack", Vector3.new(5, 1.4, 0.3), benchCF * CFrame.new(0, 2.3, 0.75), WOOD, Enum.Material.Wood)
	for _, dx in { -2, 2 } do
		part(model, `BenchLeg{dx}`, Vector3.new(0.3, 1.4, 1.4), benchCF * CFrame.new(dx, 0.7, 0), METAL, Enum.Material.Metal)
	end

	-- Innenausbau wie ein echter Fachmarkt (D-063): Eingang mit Diebstahlsicherung und Körben,
	-- Kassen vorne, Neuheiten-Podeste, Gangregale mit Hängeschildern, Rucksack-Abteilung mit
	-- Puppen, große Spitzhacken-Wand hinten, Personaltür, Poster, Uhr, Rasterdecke.
	local inside = Instance.new("Folder")
	inside.Name = "Interior"
	inside.Parent = model
	local rng = Random.new(63)
	local ceilingY = H - 0.4
	local goods = { BLUE, Color3.fromRGB(240, 196, 40), Color3.fromRGB(200, 70, 50), Color3.fromRGB(70, 74, 80), Color3.fromRGB(230, 230, 226), Color3.fromRGB(60, 130, 80) }

	-- Boden: Fliesen im Eingang und an den Kassen, Holz im Verkaufsraum
	ShopInterior.rug(inside, "EntranceTiles", o * CFrame.new(0, 0.6, -D / 2 + 7), W - 2 * t, 12, Color3.fromRGB(200, 196, 188))
	ShopInterior.rug(inside, "EntranceMat", o * CFrame.new(0, 0.62, -D / 2 + 3), doorW, 4, Color3.fromRGB(40, 44, 52))
	for _, side in { -1, 1 } do
		ShopInterior.securityGate(inside, `SecurityGate{side}`, o * CFrame.new(side * (doorW / 2 + 0.6), 0.6, -D / 2 + 6))
	end
	ShopInterior.basketStack(inside, "Baskets", o * CFrame.new(doorW / 2 + 4, 0.6, -D / 2 + 4), BLUE)
	ShopInterior.basketStack(inside, "Baskets2", o * CFrame.new(doorW / 2 + 6.2, 0.6, -D / 2 + 4), Color3.fromRGB(200, 70, 50))
	ShopInterior.exitSign(inside, "ExitSign", o * CFrame.new(0, doorH + 1.2, -D / 2 + t + 0.2) * CFrame.Angles(0, math.rad(180), 0))

	-- Ein kleiner Verkaufstresen rechts vom Eingang (lokal −X) mit Verkäufer dahinter
	-- (Felix 2026-10-27: statt zwei Supermarktkassen). Kundenseite zeigt zur Ladenmitte (+X).
	local deskCF = o * CFrame.new(-doorW / 2 - 9, 0.6, -D / 2 + 9) * CFrame.Angles(0, math.rad(-90), 0)
	part(inside, "Desk", Vector3.new(9, 3.4, 2.8), deskCF * CFrame.new(0, 1.7, 0), WOOD_DARK, Enum.Material.WoodPlanks)
	part(inside, "DeskFront", Vector3.new(9.1, 2.2, 0.1), deskCF * CFrame.new(0, 1.7, -1.45), BLUE, Enum.Material.SmoothPlastic)
	part(inside, "DeskTop", Vector3.new(9.6, 0.3, 3.4), deskCF * CFrame.new(0, 3.55, 0), WOOD, Enum.Material.Wood)
	part(inside, "Register", Vector3.new(1.4, 0.9, 1.2), deskCF * CFrame.new(2.6, 4.15, 0.4), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
	part(inside, "RegisterScreen", Vector3.new(1.2, 0.8, 0.1), deskCF * CFrame.new(2.6, 4.9, 0.2) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(60, 150, 210), Enum.Material.Neon)
	local bell = part(inside, "Bell", Vector3.new(0.4, 0.6, 0.6), deskCF * CFrame.new(0.6, 3.95, -0.8) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(210, 180, 90), Enum.Material.Metal)
	bell.Shape = Enum.PartType.Cylinder
	displayPickaxe(inside, deskCF * CFrame.new(-2.8, 5, 0.6) * CFrame.Angles(0, 0, math.rad(20)), Color3.fromRGB(150, 210, 230), 0.8)
	ShopInterior.plant(inside, "DeskPlant", deskCF * CFrame.new(-4, 3.7, 0.6), 2.2)
	ShopInterior.helmet(inside, "DeskHelmet", deskCF * CFrame.new(-0.9, 3.7, 0.5), Color3.fromRGB(240, 196, 40))
	ShopInterior.clerk(inside, "Clerk", deskCF * CFrame.new(0, 0, 2.6), BLUE)
	ShopInterior.hangingSign(inside, "CheckoutSign", deskCF * CFrame.new(0, ceilingY - 4.6, 0), "PAY HERE", BLUE_DARK, WHITE, 8, ceilingY)
	local checkoutA = deskCF * CFrame.new(0, 0, -3.2) * CFrame.Angles(0, math.rad(90), 0)
	local _ = rng

	local promptPart = part(model, "CounterPromptPart", Vector3.new(3, 4, 4), checkoutA * CFrame.new(0, 2.4, 0), WHITE, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Pickaxes"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ShopId", "equipment")
	prompt:SetAttribute("Tab", "pickaxe")
	prompt.Parent = promptPart

	-- Rucksack-Kasse links vom Eingang (lokal +X), Spiegelbild der Spitzhacken-Kasse
	-- (Felix 2026-10-28: dasselbe Podium, aber die Kasse zum Auswählen links beim Reinkommen)
	local bpCF = o * CFrame.new(doorW / 2 + 9, 0.6, -D / 2 + 9) * CFrame.Angles(0, math.rad(90), 0)
	local GREEN = Color3.fromRGB(70, 96, 70)
	part(inside, "BackpackDesk", Vector3.new(9, 3.4, 2.8), bpCF * CFrame.new(0, 1.7, 0), WOOD_DARK, Enum.Material.WoodPlanks)
	part(inside, "BackpackDeskFront", Vector3.new(9.1, 2.2, 0.1), bpCF * CFrame.new(0, 1.7, -1.45), GREEN, Enum.Material.SmoothPlastic)
	part(inside, "BackpackDeskTop", Vector3.new(9.6, 0.3, 3.4), bpCF * CFrame.new(0, 3.55, 0), WOOD, Enum.Material.Wood)
	part(inside, "BackpackRegister", Vector3.new(1.4, 0.9, 1.2), bpCF * CFrame.new(-2.6, 4.15, 0.4), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
	part(inside, "BackpackRegisterScreen", Vector3.new(1.2, 0.8, 0.1), bpCF * CFrame.new(-2.6, 4.9, 0.2) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(110, 200, 120), Enum.Material.Neon)
	local deskPack = Backpacks.List[2] and BackpackModels.standing(Backpacks.List[2], 1)
	if deskPack then
		deskPack:PivotTo(bpCF * CFrame.new(2.4, 3.7, 0.3) * CFrame.Angles(0, math.rad(180), 0))
		deskPack.Parent = inside
	end
	ShopInterior.plant(inside, "BackpackDeskPlant", bpCF * CFrame.new(4, 3.7, 0.6), 2.2)
	ShopInterior.clerk(inside, "BackpackClerk", bpCF * CFrame.new(0, 0, 2.6), GREEN)
	ShopInterior.hangingSign(inside, "BackpackCheckoutSign", bpCF * CFrame.new(0, ceilingY - 4.6, 0), "BACKPACKS", GREEN, WHITE, 9, ceilingY)
	local bpPromptPart = part(model, "BackpackPromptPart", Vector3.new(3, 4, 4), bpCF * CFrame.new(0, 0, -3.2) * CFrame.new(0, 2.4, 0), WHITE, Enum.Material.SmoothPlastic)
	bpPromptPart.Transparency = 1
	bpPromptPart.CanCollide = false
	bpPromptPart.CanQuery = false
	local bpPrompt = Instance.new("ProximityPrompt")
	bpPrompt.Name = "ShopPrompt"
	bpPrompt.ActionText = "Shop"
	bpPrompt.ObjectText = "Backpacks"
	bpPrompt.HoldDuration = 0
	bpPrompt.MaxActivationDistance = 10
	bpPrompt.RequiresLineOfSight = false
	bpPrompt:SetAttribute("ShopId", "equipment")
	bpPrompt:SetAttribute("Tab", "backpack")
	bpPrompt.Parent = bpPromptPart

	-- Podium für die Shop-Ansicht (D-070): Marmorsäule mitten im Laden, leer; beim Einkaufen setzt
	-- der Client das gewählte Item darauf und die Kamera auf „ShowcaseCamera“ (Felix 2026-10-27:
	-- Regale dahinter weg, mittiger, nicht leuchtend, wie eine Marmor-/Quarzsäule)
	local MARBLE = Color3.fromRGB(236, 234, 230)
	local GOLD = Color3.fromRGB(200, 170, 100)
	local px, pz = 0, 2
	local base = o * CFrame.new(px, 0.6, pz)
	local function cyl(name: string, h: number, r: number, y: number, color: Color3, mat: Enum.Material)
		local c = part(inside, name, Vector3.new(h, r * 2, r * 2), base * CFrame.new(0, y + h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), color, mat)
		c.Shape = Enum.PartType.Cylinder
		return c
	end
	ShopInterior.rug(inside, "ShowcaseRug", base, 18, 18, Color3.fromRGB(150, 60, 50))
	cyl("PodiumStep", 0.5, 5.2, 0, MARBLE, Enum.Material.Marble)
	cyl("PodiumBase", 0.7, 4.2, 0.5, MARBLE, Enum.Material.Marble)
	cyl("PodiumBaseTrim", 0.15, 4.25, 1.2, GOLD, Enum.Material.Metal)
	cyl("PodiumShaft", 2.6, 3.2, 1.35, MARBLE, Enum.Material.Marble)
	-- Kanneluren (senkrechte Rillen) an der Säule
	for k = 0, 15 do
		local a = math.rad(k * 22.5)
		local flute = part(inside, `PodiumFlute{k}`, Vector3.new(0.25, 2.4, 0.25), base * CFrame.Angles(0, a, 0) * CFrame.new(0, 2.65, -3.15), Color3.fromRGB(214, 212, 206), Enum.Material.Marble)
		flute.CanCollide = false
	end
	cyl("PodiumCapTrim", 0.15, 3.65, 3.95, GOLD, Enum.Material.Metal)
	cyl("PodiumCap", 0.6, 3.8, 4.1, MARBLE, Enum.Material.Marble)
	local top = base * CFrame.new(0, 4.7, 0)
	local spot = part(model, "ShowcaseSpot", Vector3.new(1, 1, 1), top, WHITE, Enum.Material.SmoothPlastic)
	spot.Transparency = 1
	spot.CanCollide = false
	spot.CanQuery = false
	spot:SetAttribute("ShopId", "equipment")
	-- Spot von der Decke aufs Podium (sichtbares Licht nur als Beleuchtung, keine Leuchtfläche)
	local lampCF = base * CFrame.new(0, H - 1.2, 0)
	local lamp = part(inside, "ShowcaseLamp", Vector3.new(1.6, 0.4, 1.6), lampCF, Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
	lamp.CanCollide = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Range = H
	light.Angle = 40
	light.Brightness = 2.5
	light.Color = LIGHT
	light.Parent = lamp
	local camPos = (base * CFrame.new(0, 10, -19)).Position
	local camPart = part(model, "ShowcaseCamera", Vector3.new(1, 1, 1), CFrame.lookAt(camPos, top.Position + Vector3.new(0, 1.8, 0)), WHITE, Enum.Material.SmoothPlastic)
	camPart.Transparency = 1
	camPart.CanCollide = false
	camPart.CanQuery = false

	-- Rucksack-Abteilung an der linken Wand (lokal +X): Puppen vorne, Tisch mit allen Stufen dahinter
	ShopInterior.hangingSign(inside, "BackpackSign", o * CFrame.new(W / 2 - 9, ceilingY - 4, 4) * CFrame.Angles(0, math.rad(90), 0), "BACKPACKS", Color3.fromRGB(70, 96, 70), WHITE, 12, ceilingY)
	for k, z in { -12, -6, 0 } do
		local back = ShopInterior.mannequin(inside, `Mannequin{k}`, o * CFrame.new(W / 2 - 11, 0.6, z) * CFrame.Angles(0, math.rad(-90), 0), CANVAS[k], Color3.fromRGB(240, 196, 40))
		local tier = #Backpacks.List - 3 + k
		local worn = BackpackModels.clone(Backpacks.List[tier])
		if worn then
			-- Vorlagen-Pivot = Befestigungspunkt am Rücken (D-074)
			worn:PivotTo(back * CFrame.new(0, 0.2, 0.03))
			worn.Parent = inside
		else
			displayBackpack(inside, back * CFrame.new(0, -1.6, 0.2) * CFrame.Angles(0, math.rad(180), 0), tier)
		end
	end
	-- endet vor der Pflanze in der hinteren Ecke
	ShopInterior.wallShelf(inside, "GearShelf", o * CFrame.new(W / 2 - t - 1.1, 0.6, 12.5) * CFrame.Angles(0, math.rad(90), 0), 19, 4, goods, rng)

	-- Spitzhacken-Wand hinten: alle Stufen in zwei Reihen (D-071: 3D-Modelle aus dem Pack),
	-- Preisschild mit Namen, Spots über der oberen Reihe
	local racks = Instance.new("Folder")
	racks.Name = "PickaxeDisplay"
	racks.Parent = model
	part(racks, "RackBoard", Vector3.new(W - 10, 11.4, 0.4), o * CFrame.new(0, 8.6, D / 2 - t - 0.5), WOOD_DARK, Enum.Material.Wood)
	local header = part(racks, "RackHeader", Vector3.new(W - 10, 2.2, 0.3), o * CFrame.new(0, 15.2, D / 2 - t - 0.6), BLUE, Enum.Material.SmoothPlastic)
	ShopInterior.text(header, "⛏  PICKAXES  ·  FROM STARTER TO LEGENDARY", WHITE, Enum.NormalId.Front)
	local count = #Pickaxes.List
	local perRow = math.ceil(count / 2)
	local spacing = math.min(7, (W - 14) / perRow)
	local rowBase = { 9.2, 3.6 } -- Unterkante der Hacke je Reihe
	local rowHeight = 4.1
	for i, def in Pickaxes.List do
		local row = if i <= perRow then 1 else 2
		local inRow = if row == 1 then perRow else count - perRow
		local k = if row == 1 then i else i - perRow
		-- lokal +X ist vom Gang aus links: Stufe 1 oben links
		local x = ((inRow - 1) * spacing) / 2 - (k - 1) * spacing
		local y = rowBase[row]
		local holder = Instance.new("Folder")
		holder.Name = def.Id
		holder.Parent = racks
		-- Kopf zeigt vom Gang aus gesehen nach rechts oben
		local cf = o * CFrame.new(x, y + 0.6, D / 2 - t - 1.1) * CFrame.Angles(0, math.rad(180), 0) * CFrame.Angles(0, 0, math.rad(-8))
		if not PickaxeModels.place(def, holder, cf, rowHeight) then
			displayPickaxe(holder, o * CFrame.new(x, y + 2.4, D / 2 - t - 1) * CFrame.Angles(0, 0, math.rad(12)), def.HeadColor, 1.1)
		end
		local tag = part(holder, "Tag", Vector3.new(spacing - 0.6, 0.6, 0.1), o * CFrame.new(x, y + 0.1, D / 2 - t - 0.8), WHITE, Enum.Material.SmoothPlastic)
		ShopInterior.text(tag, def.DisplayName, BLUE_DARK, Enum.NormalId.Front, true)
		if row == 1 and k % 2 == 1 then
			local spot = part(holder, "Spot", Vector3.new(1, 0.3, 1), o * CFrame.new(x, ceilingY - 0.3, D / 2 - 5), LIGHT, Enum.Material.Neon)
			spot.CanCollide = false
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Range = 22
			light.Angle = 45
			light.Brightness = 1.2
			light.Color = LIGHT
			light.Parent = spot
		end
	end
	-- Rucksack-Tisch vor der linken hinteren Ecke, endet vor der Spitzhacken-Wand
	local tables = Instance.new("Folder")
	tables.Name = "BackpackDisplay"
	tables.Parent = model
	local tableCF = o * CFrame.new(W / 2 - 12, 0, 14)
	part(tables, "Table", Vector3.new(4, 0.4, 20), tableCF * CFrame.new(0, 3.2, 0), WOOD, Enum.Material.Wood)
	for _, z in { -9, 9 } do
		part(tables, `TableLeg{z}`, Vector3.new(3.4, 3, 0.4), tableCF * CFrame.new(0, 1.5, z), WOOD_DARK, Enum.Material.Wood)
	end
	-- D-074: alle Stufen als echte Modelle in zwei Reihen (vordere Reihe die ersten Stufen, hintere
	-- erhöht auf einer Stufe), Vorderseite zur Ladenmitte
	local count = #Backpacks.List
	local perRow = math.ceil(count / 2)
	part(tables, "Riser", Vector3.new(1.6, 0.8, 19.4), tableCF * CFrame.new(1, 3.8, 0), WOOD_DARK, Enum.Material.Wood)
	for row = 1, 2 do
		local first = (row - 1) * perRow + 1
		local last = math.min(count, row * perRow)
		local defs = {}
		for i = first, last do
			table.insert(defs, Backpacks.List[i])
		end
		local models = {}
		local widths, total = {}, 0
		for i, def in defs do
			local m = BackpackModels.standing(def, 0.9)
			models[i] = m
			local w = if m then select(2, m:GetBoundingBox()).X else 1.65 * backpackScale(first + i - 1)
			widths[i] = w
			total += w
		end
		local gap = math.max(0.1, (19 - total) / math.max(1, #defs - 1))
		local x, y = if row == 1 then -0.9 else 1, if row == 1 then 3.4 else 4.2
		local z = -9.5
		for i, def in defs do
			local holder = Instance.new("Folder")
			holder.Name = def.Id
			holder.Parent = tables
			local cf = tableCF * CFrame.new(x, y, z + widths[i] / 2)
			local m = models[i]
			if m then
				m:PivotTo(cf * CFrame.Angles(0, math.rad(90), 0))
				m.Parent = holder
			else
				displayBackpack(holder, cf * CFrame.Angles(0, math.rad(-90), 0), first + i - 1)
			end
			z += widths[i] + gap
		end
	end

	-- Hinten rechts: Probierecke mit Fels, Personaltür, Poster, Uhr
	local rock = part(inside, "TryRock", Vector3.new(6, 4, 5), o * CFrame.new(-W / 2 + 10, 2.6, 16) * CFrame.Angles(0.2, 0.6, 0.1), Color3.fromRGB(110, 106, 100), Enum.Material.Rock)
	rock.CanCollide = true
	-- Spitzhacke im Fels entfernt (Felix 2026-10-28), Fels und Schild bleiben
	local trySign = part(inside, "TrySign", Vector3.new(5, 1.4, 0.2), o * CFrame.new(-W / 2 + 10, 2.4, 11.6) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(240, 196, 40), Enum.Material.SmoothPlastic)
	ShopInterior.text(trySign, "TRY IT!", Color3.fromRGB(26, 27, 30), Enum.NormalId.Front)
	ShopInterior.door(inside, "StaffDoor", o * CFrame.new(-W / 2 + t + 0.2, 0.6, 22) * CFrame.Angles(0, math.rad(-90), 0), "STAFF ONLY", Color3.fromRGB(70, 74, 80))
	ShopInterior.poster(inside, "PosterDeeper", o * CFrame.new(-W / 2 + t + 0.2, 9, 4) * CFrame.Angles(0, math.rad(-90), 0), 6, 8, "MINE\nDEEPER!", Color3.fromRGB(200, 70, 50), WHITE)
	ShopInterior.poster(inside, "PosterSafety", o * CFrame.new(-W / 2 + t + 0.2, 9, -6) * CFrame.Angles(0, math.rad(-90), 0), 6, 8, "SAFETY\nFIRST", Color3.fromRGB(240, 196, 40), Color3.fromRGB(26, 27, 30))
	ShopInterior.clock(inside, "Clock", o * CFrame.new(-W / 2 + 22, 15.5, D / 2 - t - 0.5))
	ShopInterior.plant(inside, "PlantFrontL", o * CFrame.new(W / 2 - 3, 0.6, -D / 2 + 3), 6)
	ShopInterior.plant(inside, "PlantFrontR", o * CFrame.new(-W / 2 + 3, 0.6, -D / 2 + 3), 6)
	ShopInterior.plant(inside, "PlantBack", o * CFrame.new(W / 2 - 3, 0.6, D / 2 - 3), 6)

	-- Rasterdecke mit Lichtpanels
	part(inside, "Ceiling", Vector3.new(W - 2 * t, 0.3, D - 2 * t), o * CFrame.new(0, H - 0.15, 0), Color3.fromRGB(230, 230, 226), Enum.Material.SmoothPlastic)
	ShopInterior.ceilingLights(inside, "CeilingLights", o * CFrame.new(0, 0, 0), W - 8, D - 8, H - 0.4, 12, LIGHT)

	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

return table.freeze(EquipmentShopBuilder)
