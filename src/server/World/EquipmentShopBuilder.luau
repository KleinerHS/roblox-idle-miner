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
local function displayPickaxe(parent: Instance, cf: CFrame, headColor: Color3)
	part(parent, "Handle", Vector3.new(0.3, 3.6, 0.3), cf, WOOD, Enum.Material.Wood)
	part(parent, "Head", Vector3.new(3, 0.35, 0.35), cf * CFrame.new(0, 1.7, 0), headColor, Enum.Material.Metal)
	part(parent, "Hook", Vector3.new(0.6, 0.2, 0.6), cf * CFrame.new(0, 1.2, 0.3), METAL, Enum.Material.Metal)
end

-- Ausstellungs-Rucksack (Größe wächst mit der Kapazität)
local function displayBackpack(parent: Instance, cf: CFrame, tier: number)
	local s = 1 + tier * 0.25
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
	local o = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))

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
	local doorW, doorH = 9, 10
	local sideW = (W - doorW) / 2
	for _, side in { 1, -1 } do
		local x = side * (doorW / 2 + sideW / 2)
		part(model, `FrontBase{side}`, Vector3.new(sideW, 2.6, t), o * CFrame.new(x, 1.3, front), BLUE_DARK, Enum.Material.Metal)
		local glass = part(model, `Window{side}`, Vector3.new(sideW - 2, 7, 0.3), o * CFrame.new(x, 6.1, front), GLASS, Enum.Material.Glass)
		glass.Transparency = 0.4
		part(model, `FrontUpper{side}`, Vector3.new(sideW, H - 9.6, t), o * CFrame.new(x, 9.6 + (H - 9.6) / 2, front), BLUE, Enum.Material.Metal)
		part(model, `DoorPost{side}`, Vector3.new(0.8, doorH, 1), o * CFrame.new(side * (doorW / 2 + 0.4), doorH / 2, front), BLUE_DARK, Enum.Material.Metal)
	end
	part(model, "DoorHeader", Vector3.new(doorW + 1.6, H - doorH, t), o * CFrame.new(0, doorH + (H - doorH) / 2, front), BLUE, Enum.Material.Metal)

	part(model, "Roof", Vector3.new(W + 2, 0.8, D + 2), o * CFrame.new(0, H + 0.4, 0), ROOF, Enum.Material.Metal)
	local sign = part(model, "Sign", Vector3.new(22, 4, 0.5), o * CFrame.new(0, H - 2.8, -D / 2 - 0.4), BLUE_DARK, Enum.Material.SmoothPlastic)
	surfaceText(sign, "⛏  EQUIPMENT", WHITE)
	part(model, "Awning", Vector3.new(doorW + 6, 0.4, 4), o * CFrame.new(0, doorH + 0.8, -D / 2 - 2) * CFrame.Angles(math.rad(-8), 0, 0), BLUE_DARK, Enum.Material.Metal)

	-- Spitzhacken an der Rückwand (eine pro Stufe)
	local racks = Instance.new("Folder")
	racks.Name = "PickaxeDisplay"
	racks.Parent = model
	part(racks, "RackBoard", Vector3.new(W - 6, 5, 0.4), o * CFrame.new(0, 8.5, D / 2 - t - 0.5), WOOD_DARK, Enum.Material.Wood)
	local count = #Pickaxes.List
	for i, def in Pickaxes.List do
		local x = -((count - 1) * 4) / 2 + (i - 1) * 4
		local holder = Instance.new("Folder")
		holder.Name = def.Id
		holder.Parent = racks
		displayPickaxe(holder, o * CFrame.new(x, 8.5, D / 2 - t - 0.9) * CFrame.Angles(0, 0, math.rad(12)), def.HeadColor)
	end

	-- Rucksäcke auf einem Tisch an der linken Wand
	local tables = Instance.new("Folder")
	tables.Name = "BackpackDisplay"
	tables.Parent = model
	part(tables, "Table", Vector3.new(4, 0.4, 16), o * CFrame.new(W / 2 - 4, 3.2, 2), WOOD, Enum.Material.Wood)
	for _, z in { -5, 9 } do
		part(tables, `TableLeg{z}`, Vector3.new(3.4, 3, 0.4), o * CFrame.new(W / 2 - 4, 1.5, z), WOOD_DARK, Enum.Material.Wood)
	end
	for i, def in Backpacks.List do
		local holder = Instance.new("Folder")
		holder.Name = def.Id
		holder.Parent = tables
		displayBackpack(holder, o * CFrame.new(W / 2 - 4, 3.4, -4 + (i - 1) * 5) * CFrame.Angles(0, math.rad(-90), 0), i)
	end

	-- Tresen rechts mit Shop-Prompt
	local counterCF = o * CFrame.new(-W / 2 + 6, 0, 4)
	part(model, "Counter", Vector3.new(3, 3.6, 12), counterCF * CFrame.new(0, 2.1, 0), WOOD_DARK, Enum.Material.Wood)
	part(model, "CounterTop", Vector3.new(3.6, 0.3, 12.6), counterCF * CFrame.new(0, 4.05, 0), BLUE_DARK, Enum.Material.SmoothPlastic)
	part(model, "Register", Vector3.new(1.2, 1.2, 1.6), counterCF * CFrame.new(0, 4.8, -3), METAL, Enum.Material.Metal)
	local promptPart = part(model, "CounterPromptPart", Vector3.new(2, 4, 4), counterCF * CFrame.new(2.6, 3, 0), WHITE, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Equipment"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ShopId", "equipment")
	prompt.Parent = promptPart

	for i, x in { -10, 0, 10 } do
		local lamp = part(model, `Lamp{i}`, Vector3.new(3, 0.3, 1.2), o * CFrame.new(x, H - 0.5, 0), LIGHT, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1
		light.Color = LIGHT
		light.Parent = lamp
	end

	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

return table.freeze(EquipmentShopBuilder)
