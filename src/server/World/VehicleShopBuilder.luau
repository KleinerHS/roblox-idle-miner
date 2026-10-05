--!strict
-- Fahrzeughaus in der Mitte (CENTRAL_AREA_REFERENCE.png: rechts, rot; docs/07 §5, §33–35,
-- docs/08 §15, D-027): großer, moderner Showroom mit umlaufenden Glaswänden, schlanken weißen
-- Stützen, auskragendem Flachdach mit Lichtband, roter Attika mit Schild, LED-Wand innen,
-- drei Drehtellern (alle Fahrzeugstufen), Verkaufstresen, Lounge und Pylon vor dem Eingang.
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

local RED = Color3.fromRGB(196, 40, 36)
local RED_DARK = Color3.fromRGB(130, 26, 24)
local WHITE = Color3.fromRGB(242, 242, 240)
local FLOOR = Color3.fromRGB(226, 226, 222)
local FLOOR_DARK = Color3.fromRGB(70, 72, 78)
local FRAME = Color3.fromRGB(235, 236, 238)
local GLASS = Color3.fromRGB(175, 215, 235)
local DARK = Color3.fromRGB(30, 32, 36)
local STEEL = Color3.fromRGB(150, 154, 160)
local LIGHT = Color3.fromRGB(255, 246, 232)
local GREEN = Color3.fromRGB(70, 140, 80)

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

local function surfaceText(target: BasePart, text: string, color: Color3, face: Enum.NormalId?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
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

-- Glasfassade zwischen zwei Punkten (lokal), mit Pfosten alle `spacing` Studs und Riegel
local function glassWall(parent: Instance, name: string, o: CFrame, from: Vector3, to: Vector3, height: number, spacing: number, skipFrom: number?, skipTo: number?)
	local dir = to - from
	local length = dir.Magnitude
	local unit = dir.Unit
	local segments = math.max(1, math.floor(length / spacing + 0.5))
	local step = length / segments
	local yaw = math.atan2(-unit.Z, unit.X)
	for i = 0, segments - 1 do
		local a = i * step
		local mid = a + step / 2
		local skip = skipFrom and skipTo and mid > skipFrom and mid < skipTo
		local center = from + unit * mid
		if not skip then
			local glass = part(parent, `{name}Glass{i}`, Vector3.new(step - 0.3, height - 1.4, 0.25), o * CFrame.new(center.X, 0.9 + (height - 1.4) / 2, center.Z) * CFrame.Angles(0, yaw, 0), GLASS, Enum.Material.Glass)
			glass.Transparency = 0.62
			glass.CastShadow = false
			part(parent, `{name}Sill{i}`, Vector3.new(step, 0.5, 0.6), o * CFrame.new(center.X, 0.85, center.Z) * CFrame.Angles(0, yaw, 0), FRAME, Enum.Material.SmoothPlastic)
			part(parent, `{name}Transom{i}`, Vector3.new(step, 0.25, 0.4), o * CFrame.new(center.X, height * 0.62, center.Z) * CFrame.Angles(0, yaw, 0), FRAME, Enum.Material.SmoothPlastic)
		end
		local postPos = from + unit * a
		part(parent, `{name}Mullion{i}`, Vector3.new(0.35, height, 0.5), o * CFrame.new(postPos.X, 0.6 + height / 2, postPos.Z) * CFrame.Angles(0, yaw, 0), FRAME, Enum.Material.SmoothPlastic)
	end
	part(parent, `{name}Head`, Vector3.new(length, 0.5, 0.6), o * CFrame.new((from + to).X / 2, height + 0.35, (from + to).Z / 2) * CFrame.Angles(0, yaw, 0), FRAME, Enum.Material.SmoothPlastic)
end

function VehicleShopBuilder.build(parent: Instance): Model
	local cfg = LayoutConfig.VehicleShop
	local center = LayoutConfig.MapCenter
	local pos = Vector3.new(center.X + cfg.Offset.X, LayoutConfig.GroundY + 1, center.Z + cfg.Offset.Y)
	-- LookVector (= lokale -Z, Eingang) zeigt zur Platzmitte
	local o = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))

	local W, H, D = cfg.Size.X, cfg.Size.Y, cfg.Size.Z
	local hw, hd = W / 2, D / 2
	local model = Instance.new("Model")
	model.Name = "VehicleShop"

	-- Boden: heller polierter Stein mit dunklem Rand, Vorplatz
	local floor = part(model, "Floor", Vector3.new(W, 0.6, D), o * CFrame.new(0, 0.3, 0), FLOOR, Enum.Material.Marble)
	floor.Reflectance = 0.12
	model.PrimaryPart = floor
	part(model, "FloorBorder", Vector3.new(W + 1, 0.55, D + 1), o * CFrame.new(0, 0.27, 0), FLOOR_DARK, Enum.Material.Slate)
	part(model, "Forecourt", Vector3.new(W, 0.3, 10), o * CFrame.new(0, 0.15, -hd - 5), Color3.fromRGB(150, 150, 146), Enum.Material.Concrete)

	-- Glasfassaden: vorne (mit Eingang), links, rechts; hinten geschlossen
	local doorW = 12
	glassWall(model, "Front", o, Vector3.new(-hw, 0, -hd), Vector3.new(hw, 0, -hd), H, 6, hw - doorW / 2, hw + doorW / 2)
	glassWall(model, "Left", o, Vector3.new(hw, 0, -hd), Vector3.new(hw, 0, hd), H, 7)
	glassWall(model, "Right", o, Vector3.new(-hw, 0, hd), Vector3.new(-hw, 0, -hd), H, 7)
	-- Eingang: Rahmen, offene Schiebetüren (in die Seiten geschoben), Fußmatte
	for _, side in { -1, 1 } do
		part(model, `DoorFrame{side}`, Vector3.new(0.6, 11, 0.8), o * CFrame.new(side * doorW / 2, 6.1, -hd), DARK, Enum.Material.Metal)
		local leaf = part(model, `DoorLeaf{side}`, Vector3.new(doorW / 2 - 0.4, 10, 0.2), o * CFrame.new(side * (doorW / 2 + doorW / 4 - 0.2), 5.6, -hd + 0.5), GLASS, Enum.Material.Glass)
		leaf.Transparency = 0.55
	end
	part(model, "DoorHeader", Vector3.new(doorW + 1.2, 1.2, 0.8), o * CFrame.new(0, 11.6, -hd), DARK, Enum.Material.Metal)
	part(model, "DoorMat", Vector3.new(doorW - 2, 0.1, 4), o * CFrame.new(0, 0.65, -hd + 2.4), DARK, Enum.Material.Fabric)

	-- Rückwand: weiß mit roter Sockelleiste und großer LED-Wand
	part(model, "WallBack", Vector3.new(W, H, 1), o * CFrame.new(0, 0.6 + H / 2, hd - 0.5), WHITE, Enum.Material.SmoothPlastic)
	part(model, "WallBackPlinth", Vector3.new(W, 1.2, 1.1), o * CFrame.new(0, 1.2, hd - 0.5), RED_DARK, Enum.Material.SmoothPlastic)
	local led = part(model, "LedWall", Vector3.new(28, 9, 0.3), o * CFrame.new(-hw / 3, 11, hd - 1.1), DARK, Enum.Material.SmoothPlastic)
	local ledGui = Instance.new("SurfaceGui")
	ledGui.Face = Enum.NormalId.Front
	ledGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	ledGui.PixelsPerStud = 30
	ledGui.LightInfluence = 0
	ledGui.Parent = led
	local gradient = Instance.new("Frame")
	gradient.Size = UDim2.fromScale(1, 1)
	gradient.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	gradient.BorderSizePixel = 0
	gradient.Parent = ledGui
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(RED_DARK, Color3.fromRGB(40, 40, 46))
	grad.Rotation = 20
	grad.Parent = gradient
	local ledTitle = Instance.new("TextLabel")
	ledTitle.Position = UDim2.fromScale(0.06, 0.18)
	ledTitle.Size = UDim2.fromScale(0.88, 0.4)
	ledTitle.BackgroundTransparency = 1
	ledTitle.Font = Enum.Font.GothamBlack
	ledTitle.TextScaled = true
	ledTitle.TextColor3 = WHITE
	ledTitle.Text = "COMPANY FLEET"
	ledTitle.Parent = gradient
	local ledSub = Instance.new("TextLabel")
	ledSub.Position = UDim2.fromScale(0.06, 0.6)
	ledSub.Size = UDim2.fromScale(0.88, 0.2)
	ledSub.BackgroundTransparency = 1
	ledSub.Font = Enum.Font.GothamBold
	ledSub.TextScaled = true
	ledSub.TextColor3 = Color3.fromRGB(230, 230, 230)
	ledSub.Text = "Pickups · Vans · Trucks"
	ledSub.Parent = gradient

	-- Schlanke Stützen an den Ecken
	for _, x in { -hw, hw } do
		for _, z in { -hd, hd } do
			part(model, `Column{x}_{z}`, Vector3.new(1.2, H + 0.6, 1.2), o * CFrame.new(x, 0.6 + (H + 0.6) / 2, z), FRAME, Enum.Material.SmoothPlastic)
		end
	end

	-- Auskragendes Flachdach mit Lichtband und roter Attika
	local roofY = 0.6 + H + 0.8
	part(model, "Roof", Vector3.new(W + 6, 1, D + 10), o * CFrame.new(0, roofY, -2), WHITE, Enum.Material.SmoothPlastic)
	part(model, "RoofSoffit", Vector3.new(W + 5.6, 0.1, D + 9.6), o * CFrame.new(0, roofY - 0.55, -2), Color3.fromRGB(210, 210, 206), Enum.Material.SmoothPlastic)
	local band = part(model, "RoofLightBand", Vector3.new(W + 6, 0.25, 0.3), o * CFrame.new(0, roofY - 0.6, -hd - 6.8), LIGHT, Enum.Material.Neon)
	band.CastShadow = false
	local fascia = part(model, "Fascia", Vector3.new(W + 6, 3, 1), o * CFrame.new(0, roofY + 1.9, -hd - 7.4), RED, Enum.Material.SmoothPlastic)
	fascia.CastShadow = true
	part(model, "FasciaSide1", Vector3.new(1, 3, D + 10), o * CFrame.new(hw + 3.4, roofY + 1.9, -2), RED, Enum.Material.SmoothPlastic)
	part(model, "FasciaSide2", Vector3.new(1, 3, D + 10), o * CFrame.new(-hw - 3.4, roofY + 1.9, -2), RED, Enum.Material.SmoothPlastic)
	local sign = part(model, "Sign", Vector3.new(30, 2.6, 0.3), o * CFrame.new(0, roofY + 1.9, -hd - 7.95), RED, Enum.Material.SmoothPlastic)
	surfaceText(sign, "🚚  VEHICLES", WHITE)
	-- Downlights unter dem Vordach
	for i = -3, 3 do
		local spot = part(model, `CanopyLight{i}`, Vector3.new(1.2, 0.15, 1.2), o * CFrame.new(i * (W / 7), roofY - 0.62, -hd - 3.5), LIGHT, Enum.Material.Neon)
		spot.CastShadow = false
	end

	-- Drehteller mit allen Fahrzeugstufen, Infotafeln davor
	local display = Instance.new("Folder")
	display.Name = "VehicleDisplay"
	display.Parent = model
	local count = #Vehicles.List
	for i, def in Vehicles.List do
		local x = (i - (count + 1) / 2) * (W / count)
		local z = 2
		local turntable = part(display, `Turntable{i}`, Vector3.new(0.4, 24, 24), o * CFrame.new(x, 0.8, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(56, 58, 64), Enum.Material.Metal)
		turntable.Shape = Enum.PartType.Cylinder
		local ring = part(display, `TurntableRing{i}`, Vector3.new(0.42, 24.6, 24.6), o * CFrame.new(x, 0.78, z) * CFrame.Angles(0, 0, math.rad(90)), RED, Enum.Material.Neon)
		ring.Shape = Enum.PartType.Cylinder
		ring.Transparency = 0.45
		local vehicle = VehicleModelBuilder.build(def, o * CFrame.new(x, 1, z) * CFrame.Angles(0, math.rad(25 - (i - 1) * 25), 0), false)
		vehicle.Parent = display
		local plate = part(display, `InfoStand{i}`, Vector3.new(4.2, 1.8, 0.2), o * CFrame.new(x, 2.4, z - 14) * CFrame.Angles(math.rad(-15), 0, 0), DARK, Enum.Material.SmoothPlastic)
		surfaceText(plate, def.DisplayName:upper(), WHITE)
		part(display, `InfoStandPost{i}`, Vector3.new(0.3, 1.8, 0.3), o * CFrame.new(x, 1.4, z - 13.9), STEEL, Enum.Material.Metal)
		local spot = part(display, `Spot{i}`, Vector3.new(2.4, 0.2, 2.4), o * CFrame.new(x, 0.6 + H - 0.3, z), LIGHT, Enum.Material.Neon)
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 30
		light.Angle = 70
		light.Brightness = 2
		light.Color = LIGHT
		light.Parent = spot
	end

	-- Verkaufstresen hinten rechts mit Prompt, Lounge hinten links
	local counterCF = o * CFrame.new(hw - 11, 0, hd - 7)
	part(model, "Counter", Vector3.new(12, 3.6, 3), counterCF * CFrame.new(0, 2.4, 0), WHITE, Enum.Material.SmoothPlastic)
	part(model, "CounterTop", Vector3.new(12.6, 0.3, 3.6), counterCF * CFrame.new(0, 4.35, 0), DARK, Enum.Material.Marble)
	part(model, "CounterStripe", Vector3.new(12, 0.6, 0.1), counterCF * CFrame.new(0, 3.2, -1.55), RED, Enum.Material.Neon)
	part(model, "Screen", Vector3.new(2.6, 1.7, 0.2), counterCF * CFrame.new(-3, 5.4, 0.5), DARK, Enum.Material.SmoothPlastic)
	part(model, "Screen2", Vector3.new(2.6, 1.7, 0.2), counterCF * CFrame.new(3, 5.4, 0.5), DARK, Enum.Material.SmoothPlastic)
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
	local lounge = o * CFrame.new(-hw + 10, 0, hd - 8)
	part(model, "SofaBase", Vector3.new(9, 1.4, 3), lounge * CFrame.new(0, 1.3, 0), DARK, Enum.Material.Fabric)
	part(model, "SofaBack", Vector3.new(9, 2.2, 0.8), lounge * CFrame.new(0, 2.6, 1.1), DARK, Enum.Material.Fabric)
	part(model, "LoungeTable", Vector3.new(4, 0.3, 2.4), lounge * CFrame.new(0, 1.6, -3), WHITE, Enum.Material.Marble)
	part(model, "LoungeRug", Vector3.new(12, 0.08, 8), lounge * CFrame.new(0, 0.64, -1.5), Color3.fromRGB(150, 40, 36), Enum.Material.Fabric)

	-- Pflanzen innen an der Glasfront
	for i, x in { -hw + 3, hw - 3 } do
		part(model, `Planter{i}`, Vector3.new(2.6, 2.2, 2.6), o * CFrame.new(x, 1.7, -hd + 3), DARK, Enum.Material.Concrete)
		local plant = part(model, `Plant{i}`, Vector3.new(3.4, 3.4, 3.4), o * CFrame.new(x, 4.3, -hd + 3), GREEN, Enum.Material.Grass)
		plant.Shape = Enum.PartType.Ball
	end

	-- Pylon vor dem Eingang
	local pylonCF = o * CFrame.new(hw - 6, 0, -hd - 9)
	part(model, "PylonBase", Vector3.new(3, 0.6, 3), pylonCF * CFrame.new(0, 0.3, 0), DARK, Enum.Material.Concrete)
	local pylon = part(model, "Pylon", Vector3.new(2.4, 12, 1.2), pylonCF * CFrame.new(0, 6.6, 0), RED, Enum.Material.SmoothPlastic)
	surfaceText(pylon, "🚚", WHITE)
	local pylonLabel = part(model, "PylonLabel", Vector3.new(2.2, 6, 0.1), pylonCF * CFrame.new(0, 5, -0.66), RED_DARK, Enum.Material.SmoothPlastic)
	surfaceText(pylonLabel, "V\nE\nH\nI\nC\nL\nE\nS", WHITE)

	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

return table.freeze(VehicleShopBuilder)
