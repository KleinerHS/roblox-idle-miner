--!strict
-- LKW-Laden etwas außerhalb der Mitte (D-058, Felix 2026-10-22: „ein LKW-Laden, der etwas außerhalb
-- der Mitte ist; genug Platz, um alle LKWs auszustellen, und noch 2 extra Plätze“).
-- Große Halle mit Glasfront und fünf langen Stellplätzen (Lastzüge mit allen Anhängern), Tresen
-- vorne rechts, Vorplatz mit Zufahrt zum großen Parkplatz. Ausstellungsstücke verankert, ohne Scripts.
--
-- Vereinbarte Namen/Attribute:
--   Model "TruckShop"
--   Part  "CounterPromptPart" mit ProximityPrompt "ShopPrompt" (Attribute ShopId = "truck")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Vehicles = require(Shared.Definitions.Vehicles)

local VehicleModelBuilder = require(script.Parent.VehicleModelBuilder)
local ShopInterior = require(script.Parent.ShopInterior)

local TruckShopBuilder = {}

local ORANGE = Color3.fromRGB(240, 146, 34)
local ORANGE_DARK = Color3.fromRGB(176, 96, 20)
local WALL = Color3.fromRGB(206, 210, 214)
local WALL_DARK = Color3.fromRGB(70, 74, 80)
local FLOOR = Color3.fromRGB(120, 124, 128)
local FRAME = Color3.fromRGB(46, 50, 56)
local GLASS = Color3.fromRGB(170, 210, 230)
local WHITE = Color3.fromRGB(244, 244, 240)
local YELLOW = Color3.fromRGB(240, 200, 40)
local LIGHT = Color3.fromRGB(255, 246, 230)
local ASPHALT = Color3.fromRGB(62, 64, 68)
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

local function surfaceText(target: BasePart, text: string, color: Color3, face: Enum.NormalId?, font: Font?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = font or Font.fromEnum(Enum.Font.GothamBlack)
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
end

-- Rahmen der Halle: Ausrichtung wie die anderen Shops (Eingang zum Kreisverkehr)
function TruckShopBuilder.frame(): CFrame
	local cfg = LayoutConfig.TruckShop
	local center = LayoutConfig.MapCenter
	local pos = Vector3.new(center.X + cfg.Offset.X, LayoutConfig.GroundY + 1, center.Z + cfg.Offset.Y)
	local a = math.rad(cfg.SectorAngle)
	return CFrame.lookAt(pos, pos - Vector3.new(math.cos(a), 0, -math.sin(a)))
end

-- Länge der Zufahrt vom Vorplatz bis an den Kreisverkehr (D-061), entlang der Hallenachse
function TruckShopBuilder.drivewayLength(): number
	local cfg = LayoutConfig.TruckShop
	local c = LayoutConfig.MapCenter
	local o = TruckShopBuilder.frame()
	local start = (o * CFrame.new(0, 0, -cfg.Size.Z / 2 - cfg.ApronDepth)).Position
	local p = Vector2.new(start.X - c.X, start.Z - c.Z)
	local d = Vector2.new(o.LookVector.X, o.LookVector.Z).Unit
	local b = p:Dot(d)
	local disc = b * b - (p:Dot(p) - LayoutConfig.RoundaboutOuter ^ 2)
	if disc < 0 then
		return cfg.DrivewayLength
	end
	-- 1 Stud in die Fahrbahn hinein, damit keine Lücke bleibt
	return -b - math.sqrt(disc) + 1
end

-- Ausstellungs-LKW mit allen Anhängern (verankert)
local function displayTruck(parent: Instance, def: Vehicles.VehicleDefinition, cf: CFrame)
	local model = VehicleModelBuilder.build(def, cf, false)
	model.Parent = parent
	local vendor = ServerStorage:FindFirstChild("Vendor")
	local bodies = vendor and vendor:FindFirstChild("VehicleBodies")
	local trailers = bodies and bodies:FindFirstChild(`{def.Id}_Trailers`)
	if trailers then
		for _, t in trailers:GetChildren() do
			if t:IsA("Model") then
				local c = t:Clone()
				c.Name = `{def.Id}_Trailer{t.Name}`
				for _, d in c:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = d.Transparency < 0.98 and d.Name ~= "CargoFill"
						if d.Name == "CargoFill" then
							d.Transparency = 1
						end
					end
				end
				c:PivotTo(cf)
				c.Parent = parent
			end
		end
	end
end

function TruckShopBuilder.build(parent: Instance): Model
	local cfg = LayoutConfig.TruckShop
	local o = TruckShopBuilder.frame()
	local W, H, D = cfg.Size.X, cfg.Size.Y, cfg.Size.Z
	local hw, hd = W / 2, D / 2
	local model = Instance.new("Model")
	model.Name = "TruckShop"

	-- Boden, Stellplatzmarkierungen
	local floor = part(model, "Floor", Vector3.new(W, 0.6, D), o * CFrame.new(0, 0.3, 0), FLOOR, Enum.Material.Concrete)
	floor.Reflectance = 0.05
	model.PrimaryPart = floor
	local floorTop = 0.6
	local bays = cfg.Bays
	local bayW = (W - 12) / bays
	for i = 0, bays do
		local x = -hw + 6 + i * bayW
		local line = part(model, `BayLine{i}`, Vector3.new(0.4, 0.05, D - 29), o * CFrame.new(x, floorTop + 0.03, -7.5), YELLOW, Enum.Material.SmoothPlastic)
		line.CanCollide = false
	end

	-- Wände: hinten und an den Seiten Trapezblech mit Fensterband, vorne Glasfront
	local wallH = H
	part(model, "WallBack", Vector3.new(W, wallH, 1), o * CFrame.new(0, floorTop + wallH / 2, hd - 0.5), WALL, Enum.Material.DiamondPlate)
	for _, side in { -1, 1 } do
		part(model, `WallSide{side}`, Vector3.new(1, wallH, D), o * CFrame.new(side * (hw - 0.5), floorTop + wallH / 2, 0), WALL, Enum.Material.DiamondPlate)
		local band = part(model, `WindowBand{side}`, Vector3.new(1.1, 3, D - 16), o * CFrame.new(side * (hw - 0.5), floorTop + wallH - 5, 0), GLASS, Enum.Material.Glass)
		band.Transparency = 0.4
		part(model, `Plinth{side}`, Vector3.new(1.2, 2, D), o * CFrame.new(side * (hw - 0.5), floorTop + 1, 0), WALL_DARK, Enum.Material.Concrete)
	end
	part(model, "PlinthBack", Vector3.new(W, 2, 1.2), o * CFrame.new(0, floorTop + 1, hd - 0.5), WALL_DARK, Enum.Material.Concrete)
	-- Glasfront mit zwei großen offenen Toren (durchfahrbar)
	local gateW = 24
	local gates = { -hw / 2, hw / 2 }
	local x = -hw
	local panel = 8
	local i = 0
	while x < hw - 0.1 do
		local mid = x + panel / 2
		local inGate = false
		for _, g in gates do
			if math.abs(mid - g) < gateW / 2 then
				inGate = true
			end
		end
		i += 1
		if not inGate then
			local glass = part(model, `FrontGlass{i}`, Vector3.new(panel - 0.4, wallH - 2, 0.3), o * CFrame.new(mid, floorTop + 1 + (wallH - 2) / 2, -hd), GLASS, Enum.Material.Glass)
			glass.Transparency = 0.6
			glass.CastShadow = false
		end
		part(model, `FrontMullion{i}`, Vector3.new(0.5, wallH, 0.6), o * CFrame.new(x, floorTop + wallH / 2, -hd), FRAME, Enum.Material.Metal)
		x += panel
	end
	part(model, "FrontMullionEnd", Vector3.new(0.5, wallH, 0.6), o * CFrame.new(hw, floorTop + wallH / 2, -hd), FRAME, Enum.Material.Metal)
	for k, g in gates do
		part(model, `GateHeader{k}`, Vector3.new(gateW + 1, 3, 0.8), o * CFrame.new(g, floorTop + wallH - 1.5, -hd), FRAME, Enum.Material.Metal)
		local glow = part(model, `GateLight{k}`, Vector3.new(gateW, 0.3, 0.3), o * CFrame.new(g, floorTop + wallH - 3.2, -hd - 0.4), LIGHT, Enum.Material.Neon)
		glow.CastShadow = false
	end
	-- Dach mit Oberlichtern und Stahlträgern
	local roofY = floorTop + wallH + 0.5
	part(model, "Roof", Vector3.new(W + 2, 1, D + 2), o * CFrame.new(0, roofY, 0), WALL_DARK, Enum.Material.Metal)
	for k = -2, 2 do
		local sky = part(model, `Skylight{k}`, Vector3.new(4, 0.3, D - 20), o * CFrame.new(k * (W / 5), roofY - 0.6, 0), LIGHT, Enum.Material.Neon)
		sky.CastShadow = false
		part(model, `Truss{k}`, Vector3.new(0.8, 1.6, D), o * CFrame.new(k * (W / 5) + W / 10, roofY - 1.3, 0), FRAME, Enum.Material.Metal)
	end
	-- Orange Attika mit Schriftzug
	local fascia = part(model, "Fascia", Vector3.new(W + 2, 6, 1), o * CFrame.new(0, roofY + 2.5, -hd - 1), ORANGE, Enum.Material.SmoothPlastic)
	local sign = part(model, "Sign", Vector3.new(46, 4.6, 0.3), fascia.CFrame * CFrame.new(0, 0, -0.65), ORANGE, Enum.Material.SmoothPlastic)
	surfaceText(sign, "🚛  TRUCKS", WHITE, nil, Font.new("rbxasset://fonts/families/FredokaOne.json"))
	for _, side in { -1, 1 } do
		part(model, `FasciaSide{side}`, Vector3.new(1, 6, D + 2), o * CFrame.new(side * (hw + 1), roofY + 2.5, 0), ORANGE_DARK, Enum.Material.SmoothPlastic)
	end
	-- Vordach über dem Vorplatz mit Lichtern
	part(model, "Canopy", Vector3.new(W, 0.8, 10), o * CFrame.new(0, floorTop + wallH - 4, -hd - 5), WALL_DARK, Enum.Material.Metal)
	for k = -4, 4 do
		local spot = part(model, `CanopyLight{k}`, Vector3.new(2, 0.15, 2), o * CFrame.new(k * (W / 9), floorTop + wallH - 4.5, -hd - 5), LIGHT, Enum.Material.Neon)
		spot.CastShadow = false
	end

	-- Ausstellung: LKW nach Stufe, danach freie Stellplätze
	local display = Instance.new("Folder")
	display.Name = "TruckDisplay"
	display.Parent = model
	local trucks = {}
	for _, def in Vehicles.List do
		if def.Dealer == "truck" then
			table.insert(trucks, def)
		end
	end
	table.sort(trucks, function(a, b)
		return a.Tier < b.Tier
	end)
	for b = 1, bays do
		local bx = -hw + 6 + (b - 0.5) * bayW
		local def = trucks[b]
		local front = o * CFrame.new(bx, floorTop, -hd + 18)
		local stand = part(display, `InfoStand{b}`, Vector3.new(10, 2.6, 0.3), o * CFrame.new(bx, floorTop + 2.4, -hd + 6) * CFrame.Angles(math.rad(-15), 0, 0), FRAME, Enum.Material.SmoothPlastic)
		part(display, `InfoStandPost{b}`, Vector3.new(0.4, 2, 0.4), o * CFrame.new(bx, floorTop + 1, -hd + 6.2), WALL_DARK, Enum.Material.Metal)
		if def then
			displayTruck(display, def, front)
			surfaceText(stand, def.DisplayName:upper(), WHITE)
		else
			surfaceText(stand, "COMING SOON", ORANGE)
			local plate = part(display, `FreeBay{b}`, Vector3.new(bayW - 4, 0.08, D - 39), o * CFrame.new(bx, floorTop + 0.05, -4.5), Color3.fromRGB(100, 104, 108), Enum.Material.SmoothPlastic)
			plate.CanCollide = false
		end
		for k, z in { -hd + 26, 0, hd - 26 } do
			local spot = part(display, `Spot{b}_{k}`, Vector3.new(2.4, 0.2, 2.4), o * CFrame.new(bx, roofY - 2.2, z), LIGHT, Enum.Material.Neon)
			spot.CastShadow = false
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Range = 30
			light.Angle = 80
			light.Brightness = 1.5
			light.Color = LIGHT
			light.Parent = spot
		end
	end

	-- Tresen vorne rechts an der Seitenwand neben Stellplatz 5, Front zur Halle
	-- (vorher mitten auf der Infotafel von Stellplatz 5)
	local counterCF = o * CFrame.new(hw - 4, floorTop, -hd + 12) * CFrame.Angles(0, math.rad(90), 0)
	part(model, "Counter", Vector3.new(10, 3.6, 3), counterCF * CFrame.new(0, 1.8, 0), WHITE, Enum.Material.SmoothPlastic)
	part(model, "CounterTop", Vector3.new(10.6, 0.3, 3.6), counterCF * CFrame.new(0, 3.75, 0), FRAME, Enum.Material.Marble)
	part(model, "CounterStripe", Vector3.new(10, 0.6, 0.1), counterCF * CFrame.new(0, 2.6, -1.55), ORANGE, Enum.Material.Neon)
	local promptPart = part(model, "CounterPromptPart", Vector3.new(4, 4, 2), counterCF * CFrame.new(0, 2.4, -2.6), WHITE, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Trucks"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ShopId", "truck")
	prompt.Parent = promptPart

	-- Vorplatz, Zufahrt Richtung Mitte, Pylon und Pflanzen
	local apron = cfg.ApronDepth
	local forecourt = part(model, "Forecourt", Vector3.new(W, 0.2, apron), o * CFrame.new(0, 0.1, -hd - apron / 2), ASPHALT, Enum.Material.Asphalt)
	forecourt.CanCollide = false
	local driveLen = TruckShopBuilder.drivewayLength()
	local drive = part(model, "Driveway", Vector3.new(cfg.DrivewayWidth, 0.2, driveLen), o * CFrame.new(0, 0.1, -hd - apron - driveLen / 2 + 1), ASPHALT, Enum.Material.Asphalt)
	drive.CanCollide = false
	for _, side in { -1, 1 } do
		local edge = part(model, `DriveLine{side}`, Vector3.new(0.4, 0.05, driveLen), o * CFrame.new(side * (cfg.DrivewayWidth / 2 - 1), 0.23, -hd - apron - driveLen / 2 + 1), WHITE, Enum.Material.SmoothPlastic)
		edge.CanCollide = false
	end
	local pylonCF = o * CFrame.new(hw - 4, 0, -hd - apron + 3)
	part(model, "PylonBase", Vector3.new(4, 0.6, 4), pylonCF * CFrame.new(0, 0.3, 0), WALL_DARK, Enum.Material.Concrete)
	local pylon = part(model, "Pylon", Vector3.new(4, 18, 1.6), pylonCF * CFrame.new(0, 9.6, 0), ORANGE, Enum.Material.SmoothPlastic)
	surfaceText(pylon, "T\nR\nU\nC\nK\nS", WHITE)
	for k, px in { -hw + 4, -hw / 2 - 16, hw / 2 + 16 } do
		part(model, `Planter{k}`, Vector3.new(4, 2, 4), o * CFrame.new(px, 1, -hd - 3), WALL_DARK, Enum.Material.Concrete)
		local plant = part(model, `Plant{k}`, Vector3.new(4.6, 4.6, 4.6), o * CFrame.new(px, 4, -hd - 3), GREEN, Enum.Material.Grass)
		plant.Shape = Enum.PartType.Ball
	end

	-- Innenausbau wie ein echter Nutzfahrzeug-Händler (D-063): hinten Verkaufsplätze, Lounge mit
	-- Kaffee und Fernseher, Ersatzteiltheke mit Regal; Reifenstapel und Poster an den Seiten.
	-- Die Stellplätze (auch die zwei freien) bleiben frei für Lastzüge.
	local inside = Instance.new("Folder")
	inside.Name = "Interior"
	inside.Parent = model
	local rng = Random.new(65)
	local DARK = Color3.fromRGB(30, 32, 36)
	local ceilingY = roofY - 0.6
	local signY = roofY - 6
	local backZ = hd - 1.2
	local goods = { ORANGE, YELLOW, Color3.fromRGB(60, 110, 190), Color3.fromRGB(190, 50, 40), WALL }

	-- Kundenzone hinten: heller Boden
	ShopInterior.rug(inside, "CustomerFloor", o * CFrame.new(0, floorTop, hd - 11), W - 4, 20, Color3.fromRGB(196, 192, 184))
	part(inside, "ZoneLine", Vector3.new(W - 4, 0.05, 0.5), o * CFrame.new(0, floorTop + 0.06, hd - 21), YELLOW, Enum.Material.SmoothPlastic).CanCollide = false

	-- Verkaufsplätze
	for k, x in { -30, -10, 10 } do
		local deskCF = o * CFrame.new(x, floorTop, hd - 14)
		ShopInterior.desk(inside, `SalesDesk{k}`, deskCF, WHITE, ORANGE_DARK)
		ShopInterior.officeChair(inside, `StaffChair{k}`, deskCF * CFrame.new(0, 0, 2.8) * CFrame.Angles(0, math.rad(180), 0), DARK)
		for _, dx in { -1.6, 1.6 } do
			ShopInterior.officeChair(inside, `GuestChair{k}{dx}`, deskCF * CFrame.new(dx, 0, -3), ORANGE_DARK)
		end
	end
	ShopInterior.hangingSign(inside, "SalesSign", o * CFrame.new(-10, signY, hd - 14), "FLEET SALES", ORANGE, WHITE, 12, ceilingY)
	ShopInterior.brochureStand(inside, "Brochures", o * CFrame.new(0, floorTop, hd - 20), { ORANGE, WHITE, DARK })
	ShopInterior.plant(inside, "SalesPlant", o * CFrame.new(-20, floorTop, hd - 8), 6)

	-- Lounge hinten links (lokal +X)
	ShopInterior.sofa(inside, "LoungeSofa", o * CFrame.new(38, floorTop, hd - 6) * CFrame.Angles(0, 0, 0), 10, DARK)
	ShopInterior.coffeeTable(inside, "LoungeTable", o * CFrame.new(38, floorTop, hd - 11))
	for k, dx in { -6, 6 } do
		ShopInterior.armchair(inside, `LoungeChair{k}`, o * CFrame.new(38 + dx, floorTop, hd - 15) * CFrame.Angles(0, math.rad(180 + (if dx < 0 then 30 else -30)), 0), ORANGE_DARK)
	end
	ShopInterior.tv(inside, "LoungeTV", o * CFrame.new(38, 11, backZ), 10, "🚛 ROAD TRAINS", ORANGE_DARK)
	ShopInterior.coffeeCorner(inside, "Coffee", o * CFrame.new(24, floorTop, hd - 2.4))
	ShopInterior.hangingSign(inside, "LoungeSign", o * CFrame.new(38, signY, hd - 12), "LOUNGE", DARK, ORANGE, 8, ceilingY)

	-- Ersatzteiltheke hinten rechts (lokal −X) mit Regalwand
	local partsCF = o * CFrame.new(-42, floorTop, hd - 10)
	part(inside, "PartsCounter", Vector3.new(14, 3.6, 2.6), partsCF * CFrame.new(0, 1.8, 0), FRAME, Enum.Material.Metal)
	part(inside, "PartsCounterTop", Vector3.new(14.4, 0.3, 3), partsCF * CFrame.new(0, 3.75, 0), ORANGE_DARK, Enum.Material.Metal)
	ShopInterior.officeChair(inside, "PartsChair", partsCF * CFrame.new(2, 0, 3) * CFrame.Angles(0, math.rad(180), 0), DARK)
	ShopInterior.wallShelf(inside, "PartsShelf", o * CFrame.new(-42, floorTop, backZ - 0.2), 20, 4, goods, rng)
	ShopInterior.hangingSign(inside, "PartsSign", o * CFrame.new(-42, signY, hd - 10), "PARTS & TIRES", YELLOW, DARK, 12, ceilingY)

	-- Seitenwände: Reifenstapel zwischen den Hallenträgern, Poster
	for _, side in { -1, 1 } do
		for k, z in { -30, 0, 30 } do
			ShopInterior.tireStack(inside, `Tires{side}{k}`, o * CFrame.new(side * (hw - 3.4), floorTop, z), 4, 1.9)
		end
		ShopInterior.poster(inside, `Poster{side}`, o * CFrame.new(side * (hw - 1.1), 12, -15) * CFrame.Angles(0, math.rad(side * 90), 0), 8, 10, if side > 0 then "BUILT\nTO HAUL" else "MORE\nCARGO!", if side > 0 then ORANGE else DARK, WHITE)
	end
	ShopInterior.clock(inside, "Clock", o * CFrame.new(0, 14, backZ))
	ShopInterior.exitSign(inside, "ExitSign", o * CFrame.new(-hw / 2, floorTop + wallH - 3.8, -hd + 0.6) * CFrame.Angles(0, math.rad(180), 0))

	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

return table.freeze(TruckShopBuilder)
