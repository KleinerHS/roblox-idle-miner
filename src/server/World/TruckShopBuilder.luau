--!strict
-- LKW-Laden etwas außerhalb der Mitte (D-058, Felix 2026-10-22: „ein LKW-Laden, der etwas außerhalb
-- der Mitte ist; genug Platz, um alle LKWs auszustellen, und noch 2 extra Plätze“).
-- Große Halle mit Glasfront und fünf langen Stellplätzen (Lastzüge mit allen Anhängern), Kundenzone
-- mit einem Tresen vorne, Vorplatz mit Zufahrt bis in den Kreisverkehr (dort spawnt ein gekaufter LKW). Ausstellungsstücke verankert, ohne Scripts.
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
local RoadFillet = require(script.Parent.RoadFillet)

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

-- Zufahrt: Startpunkt (Mitte der Vorplatzkante), Richtung zum Kreisel, quer
local function driveAxis(): (Vector3, Vector3, Vector3)
	local cfg = LayoutConfig.TruckShop
	local o = TruckShopBuilder.frame()
	local start = (o * CFrame.new(0, 0, -cfg.Size.Z / 2 - cfg.ApronDepth)).Position
	return start, o.LookVector, o.RightVector
end

-- Länge der Zufahrt vom Vorplatz bis in den Kreisverkehr: so weit, dass beide Ecken der Fahrbahn
-- im Kreisel liegen (Felix 2026-10-27: wie die anderen Straßen angebunden)
function TruckShopBuilder.drivewayLength(): number
	local cfg = LayoutConfig.TruckShop
	local start, u, n = driveAxis()
	local c = LayoutConfig.MapCenter
	local e1 = RoadFillet.ringEntry(start, u, n, -cfg.DrivewayWidth / 2, c, LayoutConfig.RoundaboutOuter - 1)
	local e2 = RoadFillet.ringEntry(start, u, n, cfg.DrivewayWidth / 2, c, LayoutConfig.RoundaboutOuter - 1)
	if not (e1 and e2) then
		return cfg.DrivewayLength
	end
	return math.max(e1, e2)
end

-- Spawnpunkt nach dem Kauf (Felix 2026-10-27): auf der Zufahrt vor dem Laden, Front zum
-- Kreisel; Boden-CFrame für die Fahrzeugvorlage (Pivot unter der Hinterachse der Zugmaschine)
function TruckShopBuilder.spawnCFrame(): CFrame
	local cfg = LayoutConfig.TruckShop
	local start, u = driveAxis()
	local c = LayoutConfig.MapCenter
	local toRing = RoadFillet.ringEntry(start, u, Vector3.zero, 0, c, LayoutConfig.RoundaboutOuter + cfg.SpawnRingGap) or 60
	local pos = start + u * (toRing - cfg.SpawnFrontOffset)
	pos = Vector3.new(pos.X, LayoutConfig.GroundY + 1.09, pos.Z)
	return CFrame.lookAt(pos, pos + Vector3.new(u.X, 0, u.Z))
end

-- Bereich, den ein gekaufter LKW samt Anhängern auf der Zufahrt belegt (Prüfung vor dem Spawn)
function TruckShopBuilder.spawnArea(): (CFrame, Vector3)
	local cfg = LayoutConfig.TruckShop
	local start, u = driveAxis()
	local front = (TruckShopBuilder.spawnCFrame().Position - start):Dot(u) + cfg.SpawnFrontOffset + 6
	-- hinten 6 Studs auf den Vorplatz hinein (dort steht das Heck des längsten Lastzugs)
	local mid = start + u * (front / 2 - 3)
	local y = LayoutConfig.GroundY + 6
	local area = CFrame.lookAt(Vector3.new(mid.X, y, mid.Z), Vector3.new(mid.X + u.X, y, mid.Z + u.Z))
	local size = Vector3.new(cfg.DrivewayWidth - 4, 10, front + 6)
	return area, size
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
	-- Kundenzone vorne (Felix 2026-10-27: Tresen vor den LKW, nicht ganz hinten)
	local FZ = cfg.FrontZone
	local bayStart, bayEnd = -hd + FZ, hd - 6
	for i = 0, bays do
		local x = -hw + 6 + i * bayW
		local line = part(model, `BayLine{i}`, Vector3.new(0.4, 0.05, bayEnd - bayStart), o * CFrame.new(x, floorTop + 0.03, (bayStart + bayEnd) / 2), YELLOW, Enum.Material.SmoothPlastic)
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
	-- Glasfront mit einem großen offenen Tor in der Mitte (Felix 2026-10-29: statt zwei Toren
	-- links/rechts, gegenüber der Zufahrt)
	local gateW = 32
	local gates = { 0 }
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
		local front = o * CFrame.new(bx, floorTop, bayStart + 18)
		local stand = part(display, `InfoStand{b}`, Vector3.new(10, 2.6, 0.3), o * CFrame.new(bx, floorTop + 2.4, bayStart - 1) * CFrame.Angles(math.rad(-15), 0, 0), FRAME, Enum.Material.SmoothPlastic)
		part(display, `InfoStandPost{b}`, Vector3.new(0.4, 2, 0.4), o * CFrame.new(bx, floorTop + 1, bayStart - 0.8), WALL_DARK, Enum.Material.Metal)
		if def then
			displayTruck(display, def, front)
			surfaceText(stand, def.DisplayName:upper(), WHITE)
		else
			surfaceText(stand, "COMING SOON", ORANGE)
			local plate = part(display, `FreeBay{b}`, Vector3.new(bayW - 4, 0.08, bayEnd - bayStart - 6), o * CFrame.new(bx, floorTop + 0.05, (bayStart + bayEnd) / 2), Color3.fromRGB(100, 104, 108), Enum.Material.SmoothPlastic)
			plate.CanCollide = false
		end
		for k, z in { bayStart + 14, (bayStart + bayEnd) / 2, bayEnd - 16 } do
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

	-- Ein Verkaufstresen vorne mittig in der Kundenzone, Front zum Eingang (Felix 2026-10-27)
	local counterCF = o * CFrame.new(0, floorTop, -hd + FZ / 2 + 1)
	part(model, "Counter", Vector3.new(16, 3.6, 3), counterCF * CFrame.new(0, 1.8, 0), WHITE, Enum.Material.SmoothPlastic)
	part(model, "CounterTop", Vector3.new(16.6, 0.3, 3.6), counterCF * CFrame.new(0, 3.75, 0), FRAME, Enum.Material.Marble)
	part(model, "CounterStripe", Vector3.new(16, 0.6, 0.1), counterCF * CFrame.new(0, 2.6, -1.55), ORANGE, Enum.Material.Neon)
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
	-- Zufahrt wie die anderen Straßen (Felix 2026-10-27): gleiche Höhe und Markierungen, runde
	-- Ausrundungen in den Kreisel und Ausschwenkkurven am Vorplatz
	local driveLen = TruckShopBuilder.drivewayLength()
	local dw = cfg.DrivewayWidth
	local ROAD = Color3.fromRGB(58, 60, 64)
	local roadTop = LayoutConfig.GroundY + 1.09
	local zStart = -hd - apron
	local function atTop(p: BasePart, top: number)
		p.CFrame = p.CFrame + Vector3.new(0, top - p.Size.Y / 2 - p.Position.Y, 0)
		p.CanCollide = false
	end
	local drive = part(model, "Driveway", Vector3.new(dw, 0.1, driveLen + 1), o * CFrame.new(0, 0, zStart - driveLen / 2 + 0.5), ROAD, Enum.Material.Asphalt)
	atTop(drive, roadTop)
	local start, u, n = driveAxis()
	local c = LayoutConfig.MapCenter
	local fillets = Instance.new("Folder")
	fillets.Name = "DrivewayCurves"
	fillets.Parent = model
	local filletStart = driveLen
	for _, side in { -1, 1 } do
		local nSide = n * side
		local E = start + nSide * (dw / 2)
		-- Kreisel-Seite
		local sAt = RoadFillet.toRing(fillets, `Ring{side}`, E, u, nSide, c, LayoutConfig.RoundaboutOuter, cfg.RingFillet, roadTop - 0.04, ROAD)
		if sAt then
			filletStart = math.min(filletStart, sAt)
		end
		-- Vorplatz-Seite: Ausschwenkkurve
		RoadFillet.toEdge(fillets, `Flare{side}`, E, u, nSide, cfg.FlareFillet, roadTop - 0.005, ROAD)
	end
	-- Markierungen: gelbe Mittellinie bis an den Kreisel, weiße Randlinien zwischen den Rundungen
	local ringAtCenter = RoadFillet.ringEntry(start, u, n, 0, c, LayoutConfig.RoundaboutOuter) or driveLen
	local zz = 4
	local k = 0
	while zz + 6 < ringAtCenter - 2 do
		k += 1
		local dash = part(model, `DriveDash{k}`, Vector3.new(0.5, 0.04, 6), o * CFrame.new(0, 0, zStart - zz - 3), YELLOW, Enum.Material.SmoothPlastic)
		atTop(dash, roadTop + 0.04)
		zz += 12
	end
	local edgeFrom, edgeTo = cfg.FlareFillet, filletStart
	if edgeTo > edgeFrom then
		for _, side in { -1, 1 } do
			local edge = part(model, `DriveLine{side}`, Vector3.new(0.4, 0.04, edgeTo - edgeFrom), o * CFrame.new(side * (dw / 2 - 1.2), 0, zStart - (edgeFrom + edgeTo) / 2), WHITE, Enum.Material.SmoothPlastic)
			atTop(edge, roadTop + 0.04)
		end
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

	-- Kundenzone vorne: heller Boden, Linie zu den Stellplätzen
	ShopInterior.rug(inside, "CustomerFloor", o * CFrame.new(0, floorTop, -hd + FZ / 2), W - 4, FZ - 2, Color3.fromRGB(196, 192, 184))
	part(inside, "ZoneLine", Vector3.new(W - 4, 0.05, 0.5), o * CFrame.new(0, floorTop + 0.06, -hd + FZ - 1), YELLOW, Enum.Material.SmoothPlastic).CanCollide = false
	-- Hinter dem Tresen: Mitarbeiter, Schild; daneben Prospekte und Pflanzen
	ShopInterior.officeChair(inside, "StaffChair", counterCF * CFrame.new(-3, 0, 3) * CFrame.Angles(0, math.rad(180), 0), DARK)
	ShopInterior.officeChair(inside, "StaffChair2", counterCF * CFrame.new(3, 0, 3) * CFrame.Angles(0, math.rad(180), 0), DARK)
	ShopInterior.hangingSign(inside, "SalesSign", counterCF * CFrame.new(0, signY - floorTop, 0), "FLEET SALES", ORANGE, WHITE, 14, ceilingY)
	ShopInterior.brochureStand(inside, "Brochures", counterCF * CFrame.new(10, 0, -1) * CFrame.Angles(0, math.rad(20), 0), { ORANGE, WHITE, DARK })
	for k, x in { -12, 12 } do
		ShopInterior.plant(inside, `CounterPlant{k}`, counterCF * CFrame.new(x, 0, 1), 5)
	end
	-- Lounge vorne links (lokal +X) in der Ecke
	local lounge = o * CFrame.new(hw - 10, floorTop, -hd + FZ - 5)
	-- Sofa und Tisch etwas weiter nach vorne (Felix 2026-10-29)
	ShopInterior.sofa(inside, "LoungeSofa", lounge * CFrame.new(0, 0, -6), 10, DARK)
	ShopInterior.coffeeTable(inside, "LoungeTable", lounge * CFrame.new(0, 0, -10.46))
	ShopInterior.tv(inside, "LoungeTV", o * CFrame.new(hw - 1.2, 10, -hd + FZ / 2) * CFrame.Angles(0, math.rad(90), 0), 9, "🚛 ROAD TRAINS", ORANGE_DARK)
	-- Kaffee vorne rechts an der Seitenwand
	ShopInterior.coffeeCorner(inside, "Coffee", o * CFrame.new(-hw + 2.4, floorTop, -hd + FZ / 2) * CFrame.Angles(0, math.rad(-90), 0))
	local _ = goods
	local _ = backZ

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
