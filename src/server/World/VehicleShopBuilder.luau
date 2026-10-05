--!strict
-- Fahrzeughaus in der Mitte (CENTRAL_AREA_REFERENCE.png: rechts, rot; docs/07 §5, §33–35,
-- docs/08 §15). Autohaus-Showroom: große Glasfront, polierter Boden, Drehteller mit
-- Ausstellungsfahrzeugen (erste und größte Stufe, docs/07 §34), Tresen mit Shop-Prompt.
-- Ausstellungsstücke ohne Scripts.
--
-- Vereinbarte Namen/Attribute:
--   Model "VehicleShop"
--   Part  "CounterPromptPart" mit ProximityPrompt "ShopPrompt" (Attribute ShopId = "vehicle")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Vehicles = require(Shared.Definitions.Vehicles)

local VehicleModelBuilder = require(script.Parent.VehicleModelBuilder)

local VehicleShopBuilder = {}

local RED = Color3.fromRGB(186, 46, 40)
local RED_DARK = Color3.fromRGB(130, 30, 28)
local FLOOR = Color3.fromRGB(214, 214, 210)
local WALL = Color3.fromRGB(236, 236, 232)
local STEEL = Color3.fromRGB(66, 70, 76)
local GLASS = Color3.fromRGB(170, 210, 230)
local WHITE = Color3.fromRGB(245, 245, 242)
local LIGHT = Color3.fromRGB(255, 244, 226)

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

function VehicleShopBuilder.build(parent: Instance): Model
	local cfg = LayoutConfig.VehicleShop
	local center = LayoutConfig.MapCenter
	local pos = Vector3.new(center.X + cfg.Offset.X, LayoutConfig.GroundY + 1, center.Z + cfg.Offset.Y)
	-- LookVector (= lokale -Z, Glasfront) zeigt zur Platzmitte
	local o = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))

	local W, H, D = cfg.Size.X, cfg.Size.Y, cfg.Size.Z
	local t = 0.8
	local model = Instance.new("Model")
	model.Name = "VehicleShop"

	local floor = part(model, "Floor", Vector3.new(W, 0.6, D), o * CFrame.new(0, 0.3, 0), FLOOR, Enum.Material.Marble)
	model.PrimaryPart = floor
	floor.Reflectance = 0.08

	-- Rückwand und Seiten (weiß mit rotem Sockel), rote Pfeiler an den Ecken
	part(model, "WallBack", Vector3.new(W, H, t), o * CFrame.new(0, H / 2, D / 2 - t / 2), WALL, Enum.Material.SmoothPlastic)
	part(model, "WallLeft", Vector3.new(t, H, D), o * CFrame.new(W / 2 - t / 2, H / 2, 0), WALL, Enum.Material.SmoothPlastic)
	part(model, "WallRight", Vector3.new(t, H, D), o * CFrame.new(-W / 2 + t / 2, H / 2, 0), WALL, Enum.Material.SmoothPlastic)
	part(model, "PlinthBack", Vector3.new(W, 1.6, t + 0.2), o * CFrame.new(0, 0.8, D / 2 - t / 2), RED_DARK, Enum.Material.SmoothPlastic)
	for _, x in { -W / 2, W / 2 } do
		for _, z in { -D / 2, D / 2 } do
			part(model, `Pillar{x}_{z}`, Vector3.new(2, H + 1, 2), o * CFrame.new(x, (H + 1) / 2, z), RED, Enum.Material.SmoothPlastic)
		end
	end

	-- Glasfront mit Sprossen und breitem Eingang in der Mitte
	local front = -D / 2 + t / 2
	local doorW, doorH = 10, 10
	local sideW = (W - doorW) / 2
	for _, side in { 1, -1 } do
		local x = side * (doorW / 2 + sideW / 2)
		local glass = part(model, `Glass{side}`, Vector3.new(sideW, H - 2, 0.3), o * CFrame.new(x, 1 + (H - 2) / 2, front), GLASS, Enum.Material.Glass)
		glass.Transparency = 0.55
		for i = 1, 3 do
			part(model, `Mullion{side}_{i}`, Vector3.new(0.4, H - 2, 0.5), o * CFrame.new(side * (doorW / 2 + sideW * i / 4), 1 + (H - 2) / 2, front), STEEL, Enum.Material.Metal)
		end
		part(model, `FrontSill{side}`, Vector3.new(sideW, 1, t), o * CFrame.new(x, 0.5, front), RED_DARK, Enum.Material.SmoothPlastic)
	end
	part(model, "DoorHeader", Vector3.new(doorW, H - doorH, t), o * CFrame.new(0, doorH + (H - doorH) / 2, front), RED, Enum.Material.SmoothPlastic)
	part(model, "Fascia", Vector3.new(W + 2, 2.2, 1.2), o * CFrame.new(0, H + 0.2, front - 0.3), RED, Enum.Material.SmoothPlastic)
	part(model, "Roof", Vector3.new(W + 2, 0.8, D + 2), o * CFrame.new(0, H + 0.4, 0), STEEL, Enum.Material.Metal)
	local sign = part(model, "Sign", Vector3.new(26, 4, 0.5), o * CFrame.new(0, H + 3.4, -D / 2 - 0.2), RED_DARK, Enum.Material.SmoothPlastic)
	surfaceText(sign, "🚚  VEHICLES", WHITE)

	-- Drehteller mit Ausstellungsfahrzeugen (erste und größte Stufe)
	local display = Instance.new("Folder")
	display.Name = "VehicleDisplay"
	display.Parent = model
	local shown = { Vehicles.List[1], Vehicles.List[#Vehicles.List] }
	if shown[1] == shown[2] then
		shown = { shown[1] }
	end
	for i, def in shown do
		local x = if #shown == 1 then 0 else (if i == 1 then 12 else -10)
		local turntable = part(display, `Turntable{i}`, Vector3.new(0.4, 22, 22), o * CFrame.new(x, 0.8, 4) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 62, 68), Enum.Material.Metal)
		turntable.Shape = Enum.PartType.Cylinder
		local ringPart = part(display, `TurntableRing{i}`, Vector3.new(0.42, 22.4, 22.4), o * CFrame.new(x, 0.78, 4) * CFrame.Angles(0, 0, math.rad(90)), RED, Enum.Material.Neon)
		ringPart.Shape = Enum.PartType.Cylinder
		ringPart.Transparency = 0.5
		local vehicle = VehicleModelBuilder.build(def, o * CFrame.new(x, 1, 4) * CFrame.Angles(0, math.rad(if i == 1 then 30 else -25), 0), false)
		vehicle.Parent = display
		local plate = part(display, `InfoStand{i}`, Vector3.new(3.4, 1.4, 0.2), o * CFrame.new(x, 2.2, -8) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(30, 32, 36), Enum.Material.SmoothPlastic)
		surfaceText(plate, def.DisplayName:upper(), WHITE)
		part(display, `InfoStandPost{i}`, Vector3.new(0.3, 1.6, 0.3), o * CFrame.new(x, 1.3, -7.9), STEEL, Enum.Material.Metal)
	end

	-- Verkaufstresen hinten links mit Prompt und Prospektständer
	local counterCF = o * CFrame.new(W / 2 - 7, 0, D / 2 - 6)
	part(model, "Counter", Vector3.new(10, 3.6, 3), counterCF * CFrame.new(0, 2.1, 0), WALL, Enum.Material.SmoothPlastic)
	part(model, "CounterTop", Vector3.new(10.6, 0.3, 3.6), counterCF * CFrame.new(0, 4.05, 0), RED, Enum.Material.SmoothPlastic)
	part(model, "CounterLogo", Vector3.new(4, 1.4, 0.1), counterCF * CFrame.new(0, 2.4, -1.55), RED_DARK, Enum.Material.SmoothPlastic)
	part(model, "Screen", Vector3.new(2.4, 1.6, 0.2), counterCF * CFrame.new(-2.5, 5.1, 0.5), Color3.fromRGB(30, 32, 36), Enum.Material.SmoothPlastic)
	local promptPart = part(model, "CounterPromptPart", Vector3.new(4, 4, 2), counterCF * CFrame.new(0, 3, -2.6), WHITE, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Vehicles"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ShopId", "vehicle")
	prompt.Parent = promptPart

	-- Pflanzen und Spots
	for i, x in { -W / 2 + 3, W / 2 - 3 } do
		part(model, `Planter{i}`, Vector3.new(2.4, 2, 2.4), o * CFrame.new(x, 1.6, -D / 2 + 3), Color3.fromRGB(70, 70, 74), Enum.Material.Concrete)
		local plant = part(model, `Plant{i}`, Vector3.new(3, 3, 3), o * CFrame.new(x, 4, -D / 2 + 3), Color3.fromRGB(60, 130, 70), Enum.Material.Grass)
		plant.Shape = Enum.PartType.Ball
	end
	for i, x in { -W / 4, W / 4 } do
		for j, z in { -D / 6, D / 4 } do
			local lamp = part(model, `Spot{i}_{j}`, Vector3.new(2, 0.2, 2), o * CFrame.new(x, H - 0.2, z), LIGHT, Enum.Material.Neon)
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Range = 26
			light.Angle = 90
			light.Brightness = 1.6
			light.Color = LIGHT
			light.Parent = lamp
		end
	end

	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

return table.freeze(VehicleShopBuilder)
