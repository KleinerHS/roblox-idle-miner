--!strict
-- Verkaufsgebäude in der Mitte (PLATZHALTER nach CENTRAL_AREA_REFERENCE.png, docs/07 §22,
-- docs/08 §9–10): Holz-/Glasfront mit grünem Schild, Vordach, Verkaufstresen innen,
-- markierte Fahrzeug-Verkaufszone davor (Funktion folgt mit den Fahrzeugen, Phase 6).
--
-- Vereinbarte Namen/Attribute:
--   Model "SellingBuilding"
--   Part  "CounterPromptPart" mit ProximityPrompt "SellPrompt" (Attribute SellCounter = true)
--   Part  "VehicleSellZone"   (Tag "SellZone", noch ohne Funktion)

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LayoutConfig)

local SellingBuilder = {}

local WOOD = Color3.fromRGB(150, 104, 64)
local WOOD_DARK = Color3.fromRGB(104, 70, 44)
local GREEN = Color3.fromRGB(46, 140, 70)
local GREEN_DARK = Color3.fromRGB(30, 96, 48)
local ROOF = Color3.fromRGB(96, 100, 108)
local TILE = Color3.fromRGB(196, 190, 178)
local GLASS = Color3.fromRGB(170, 210, 230)
local WHITE = Color3.fromRGB(240, 240, 236)
local CONCRETE = Color3.fromRGB(150, 148, 142)
local LIGHT = Color3.fromRGB(255, 236, 200)

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

local function surfaceText(target: BasePart, text: string, color: Color3, face: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
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

-- Baut das Gebäude. Eingang (lokal -Z) zeigt von der Mitte weg zur Straße.
function SellingBuilder.build(parent: Instance): Model
	local cfg = LayoutConfig.SellingBuilding
	local center = LayoutConfig.MapCenter
	local pos = Vector3.new(center.X + cfg.Offset.X, LayoutConfig.GroundY + 1, center.Z + cfg.Offset.Y)
	-- LookVector (= lokale -Z, Vorderseite) zeigt von der Mitte weg zur Straße
	local outward = Vector3.new(pos.X - center.X, 0, pos.Z - center.Z)
	local o = CFrame.lookAt(pos, pos + outward)

	local W, H, D = cfg.Size.X, cfg.Size.Y, cfg.Size.Z
	local t = 0.8
	local model = Instance.new("Model")
	model.Name = "SellingBuilding"

	local floor = part(model, "Floor", Vector3.new(W, 0.6, D), o * CFrame.new(0, 0.3, 0), TILE, Enum.Material.Slate)
	model.PrimaryPart = floor

	-- Wände: Holzverkleidung, Rückwand und Seiten geschlossen
	part(model, "WallBack", Vector3.new(W, H, t), o * CFrame.new(0, H / 2, D / 2 - t / 2), WOOD, Enum.Material.WoodPlanks)
	part(model, "WallLeft", Vector3.new(t, H, D), o * CFrame.new(W / 2 - t / 2, H / 2, 0), WOOD, Enum.Material.WoodPlanks)
	part(model, "WallRight", Vector3.new(t, H, D), o * CFrame.new(-W / 2 + t / 2, H / 2, 0), WOOD, Enum.Material.WoodPlanks)

	-- Front (lokal -Z): Eingang mittig, große Fenster links/rechts, grüne Eckpfeiler
	local front = -D / 2 + t / 2
	local doorW, doorH = 10, 10
	local sideW = (W - doorW) / 2
	for _, side in { 1, -1 } do
		local x = side * (doorW / 2 + sideW / 2)
		part(model, `FrontBase{side}`, Vector3.new(sideW, 3, t), o * CFrame.new(x, 1.5, front), WOOD_DARK, Enum.Material.WoodPlanks)
		local glass = part(model, `Window{side}`, Vector3.new(sideW - 2, 7, 0.3), o * CFrame.new(x, 6.5, front), GLASS, Enum.Material.Glass)
		glass.Transparency = 0.45
		part(model, `WindowFrameTop{side}`, Vector3.new(sideW, 0.5, t + 0.1), o * CFrame.new(x, 10.25, front), WOOD_DARK, Enum.Material.Wood)
		part(model, `FrontUpper{side}`, Vector3.new(sideW, H - 10.5, t), o * CFrame.new(x, 10.5 + (H - 10.5) / 2, front), WOOD, Enum.Material.WoodPlanks)
		part(model, `Pillar{side}`, Vector3.new(1.4, H, 1.4), o * CFrame.new(side * (W / 2 - 0.7), H / 2, front), GREEN_DARK, Enum.Material.SmoothPlastic)
		part(model, `DoorPost{side}`, Vector3.new(0.8, doorH, 1), o * CFrame.new(side * (doorW / 2 + 0.4), doorH / 2, front), GREEN_DARK, Enum.Material.SmoothPlastic)
	end
	part(model, "DoorHeader", Vector3.new(doorW + 1.6, H - doorH, t), o * CFrame.new(0, doorH + (H - doorH) / 2, front), WOOD, Enum.Material.WoodPlanks)

	-- Dach mit Überstand und grüner Blende
	part(model, "Roof", Vector3.new(W + 2, 0.8, D + 2), o * CFrame.new(0, H + 0.4, 0), ROOF, Enum.Material.Metal)
	part(model, "Fascia", Vector3.new(W + 2, 1.2, 0.4), o * CFrame.new(0, H + 0.2, -D / 2 - 1), GREEN, Enum.Material.SmoothPlastic)

	-- Großes Schild "$ SELL" über dem Eingang
	local sign = part(model, "Sign", Vector3.new(20, 4, 0.5), o * CFrame.new(0, H - 2.6, -D / 2 - 0.4), GREEN, Enum.Material.SmoothPlastic)
	surfaceText(sign, "$  SELL", WHITE, Enum.NormalId.Front)

	-- Vordach über dem Eingang
	part(model, "Awning", Vector3.new(doorW + 6, 0.4, 4), o * CFrame.new(0, doorH + 0.8, -D / 2 - 2) * CFrame.Angles(math.rad(-8), 0, 0), WOOD_DARK, Enum.Material.Wood)

	-- Verkaufstresen innen an der Rückwand
	local counterZ = D / 2 - 6
	part(model, "Counter", Vector3.new(18, 3.6, 2.4), o * CFrame.new(0, 2.1, counterZ), WOOD_DARK, Enum.Material.Wood)
	part(model, "CounterTop", Vector3.new(18.6, 0.3, 3), o * CFrame.new(0, 4.05, counterZ), GREEN_DARK, Enum.Material.SmoothPlastic)
	part(model, "Register", Vector3.new(1.6, 1.2, 1.2), o * CFrame.new(-5, 4.8, counterZ), Color3.fromRGB(50, 52, 56), Enum.Material.Metal)
	part(model, "Scale", Vector3.new(2.4, 0.3, 2), o * CFrame.new(4, 4.35, counterZ), Color3.fromRGB(170, 172, 176), Enum.Material.Metal)
	local board = part(model, "PriceBoard", Vector3.new(12, 5, 0.3), o * CFrame.new(0, 10, D / 2 - t - 0.2), Color3.fromRGB(34, 36, 40), Enum.Material.SmoothPlastic)
	surfaceText(board, "ORE BUYER", Color3.fromRGB(120, 220, 140), Enum.NormalId.Front)

	local promptPart = part(model, "CounterPromptPart", Vector3.new(4, 4, 2), o * CFrame.new(0, 3, counterZ - 2.5), WHITE, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	prompt.ActionText = "Sell Ore"
	prompt.ObjectText = "Counter"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("SellCounter", true)
	prompt.Parent = promptPart

	-- Deckenlampen
	for i, x in { -12, 0, 12 } do
		local lamp = part(model, `Lamp{i}`, Vector3.new(4, 0.3, 1.2), o * CFrame.new(x, H - 0.5, 0), LIGHT, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1
		light.Color = LIGHT
		light.Parent = lamp
	end

	-- Vorplatz und Fahrzeug-Verkaufszone (Fahrzeugverkauf folgt in Phase 6)
	part(model, "Forecourt", Vector3.new(W + 8, 0.4, 8), o * CFrame.new(0, 0.2, -D / 2 - 4), CONCRETE, Enum.Material.Concrete)
	local zone = part(model, "VehicleSellZone", Vector3.new(30, 0.2, 16), o * CFrame.new(0, 0.1, -D / 2 - 18), Color3.fromRGB(58, 60, 64), Enum.Material.Asphalt)
	CollectionService:AddTag(zone, "SellZone")
	for i, x in { -15, -5, 5, 15 } do
		part(model, `ZoneLine{i}`, Vector3.new(0.4, 0.05, 14), o * CFrame.new(x, 0.23, -D / 2 - 18), WHITE, Enum.Material.SmoothPlastic)
	end
	for _, side in { 1, -1 } do
		part(model, `Bench{side}`, Vector3.new(5, 0.5, 1.6), o * CFrame.new(side * 16, 1.4, -D / 2 - 3), WOOD, Enum.Material.Wood)
		part(model, `Planter{side}`, Vector3.new(3, 1.6, 3), o * CFrame.new(side * 9, 0.8, -D / 2 - 3), WOOD_DARK, Enum.Material.WoodPlanks)
		local bush = part(model, `Bush{side}`, Vector3.new(2.8, 2.8, 2.8), o * CFrame.new(side * 9, 2.6, -D / 2 - 3), Color3.fromRGB(70, 130, 60), Enum.Material.Grass)
		bush.Shape = Enum.PartType.Ball
	end

	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

return table.freeze(SellingBuilder)
