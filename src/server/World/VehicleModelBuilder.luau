--!strict
-- Firmenfahrzeuge (docs/07 §6, §13–14, §35–37): clean, leicht stilisiert, glaubwürdig.
-- Drei Bauformen: Pickup (offene Ladefläche), Van (Kastenwagen), BoxTruck (Fahrerhaus +
-- Kofferaufbau). Ein Builder für Ausstellung (alles verankert) und Fahrbetrieb (Physik).
--
-- Ursprung cf = Boden unter der Fahrzeugmitte, LookVector (-Z) = Fahrtrichtung.
-- Fahrbetrieb (drivable = true):
--   Part "Chassis" trägt alle Karosserieteile (WeldConstraint, Massless) und ist schwer,
--   damit der Schwerpunkt tief liegt (keine Überschläge, docs/07 §13).
--   Hinterräder: HingeConstraint "DriveL"/"DriveR" (Motor) – Antrieb.
--   Vorderräder: Achsschenkel mit HingeConstraint "SteerL"/"SteerR" (Servo, Lenkung) und
--   freilaufendem Rad-Gelenk.
--   VehicleSeat "DriverSeat" – Eingaben liest der Client des Fahrers (VehicleController).
-- Vereinbarte Namen: "CargoFill" (sichtbare Ladung, kosmetisch), "DoorText" (SurfaceGui mit
-- Firmenname), Teile mit Attribut CompanyAccent (Firmenfarbe als Akzent, docs/07 §36).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vehicles = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Vehicles)

local VehicleModelBuilder = {}

local GLASS = Color3.fromRGB(120, 160, 185)
local TRIM = Color3.fromRGB(36, 38, 42)
local CHROME = Color3.fromRGB(196, 200, 206)
local TIRE = Color3.fromRGB(28, 28, 30)
local RIM = Color3.fromRGB(170, 174, 180)
local HEADLIGHT = Color3.fromRGB(255, 246, 220)
local TAILLIGHT = Color3.fromRGB(220, 40, 40)
local ACCENT_DEFAULT = Color3.fromRGB(242, 166, 46)
local CARGO = Color3.fromRGB(70, 66, 62)
local SEAT = Color3.fromRGB(50, 50, 54)

-- Maße je Bauform (Studs): Radius, Radbreite, Spurweite/2, Achsen vorne/hinten (Z), Breite
type Spec = { r: number, w: number, track: number, front: number, rear: number, width: number, length: number }
local SPECS: { [string]: Spec } = {
	Pickup = { r = 1.4, w = 1.1, track = 3.15, front = -5.2, rear = 4.6, width = 7.2, length = 16.4 },
	Van = { r = 1.5, w = 1.2, track = 3.2, front = -5.8, rear = 5.2, width = 7.4, length = 17.6 },
	BoxTruck = { r = 1.8, w = 1.5, track = 3.5, front = -7.6, rear = 7.4, width = 8.4, length = 24 },
}

type Ctx = { model: Model, cf: CFrame, parts: { BasePart }, def: Vehicles.VehicleDefinition }

local function box(ctx: Ctx, name: string, size: Vector3, x: number, y: number, z: number, color: Color3, material: Enum.Material?, rot: CFrame?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = ctx.cf * CFrame.new(x, y, z) * (rot or CFrame.identity)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.Parent = ctx.model
	table.insert(ctx.parts, p)
	return p
end

local function accentPart(p: BasePart)
	p:SetAttribute("CompanyAccent", true)
end

-- Lampen vorne/hinten, Stoßfänger, Kennzeichen (für alle Bauformen gleich aufgebaut)
local function lightsAndBumpers(ctx: Ctx, spec: Spec, frontZ: number, rearZ: number, lightY: number)
	local hw = spec.width / 2
	box(ctx, "BumperFront", Vector3.new(spec.width + 0.2, 0.8, 0.6), 0, spec.r + 0.1, frontZ - 0.2, TRIM)
	box(ctx, "BumperRear", Vector3.new(spec.width + 0.2, 0.8, 0.6), 0, spec.r + 0.1, rearZ + 0.2, TRIM)
	for _, side in { -1, 1 } do
		local head = box(ctx, `Headlight{side}`, Vector3.new(1.3, 0.7, 0.2), side * (hw - 1), lightY, frontZ - 0.05, HEADLIGHT, Enum.Material.Neon)
		head.CanCollide = false
		local tail = box(ctx, `Taillight{side}`, Vector3.new(0.9, 1, 0.2), side * (hw - 0.6), lightY, rearZ + 0.05, TAILLIGHT, Enum.Material.Neon)
		tail.CanCollide = false
	end
	box(ctx, "Plate", Vector3.new(2, 0.6, 0.1), 0, spec.r + 0.1, rearZ + 0.55, Color3.fromRGB(240, 240, 235))
end

-- Firmenname an der Fahrertür (Text wurde beim Firmen-Setup gefiltert, docs/07 §37)
local function doorText(p: BasePart, face: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "DoorText"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.5
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.86, 0.5)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = TRIM
	label.Text = ""
	label.Parent = gui
end

local function buildPickup(ctx: Ctx, spec: Spec)
	local paint = ctx.def.PaintColor
	local hw = spec.width / 2
	local floorY = spec.r + 0.8
	-- Fahrerhaus mit Motorhaube
	box(ctx, "Hood", Vector3.new(spec.width, 1.8, 4), 0, floorY + 0.9, -6, paint, Enum.Material.SmoothPlastic)
	local cabLower = box(ctx, "CabLower", Vector3.new(spec.width, 1.8, 4.4), 0, floorY + 0.9, -1.8, paint, Enum.Material.SmoothPlastic)
	box(ctx, "CabUpperFrame", Vector3.new(spec.width - 0.4, 2.4, 4), 0, floorY + 3, -1.6, paint, Enum.Material.SmoothPlastic)
	box(ctx, "Roof", Vector3.new(spec.width - 0.2, 0.3, 4.2), 0, floorY + 4.3, -1.6, paint, Enum.Material.SmoothPlastic)
	box(ctx, "Windshield", Vector3.new(spec.width - 0.8, 2.4, 0.2), 0, floorY + 2.9, -3.75, GLASS, Enum.Material.Glass, CFrame.Angles(math.rad(-18), 0, 0)).Transparency = 0.35
	for _, side in { -1, 1 } do
		box(ctx, `SideWindow{side}`, Vector3.new(0.12, 1.7, 2.8), side * (hw - 0.18), floorY + 3, -1.8, GLASS, Enum.Material.Glass).Transparency = 0.35
		local stripe = box(ctx, `AccentStripe{side}`, Vector3.new(0.06, 0.35, 13.6), side * (hw + 0.02), floorY + 1.2, 0.7, ACCENT_DEFAULT)
		accentPart(stripe)
	end
	doorText(cabLower, Enum.NormalId.Left)
	box(ctx, "Grille", Vector3.new(3.4, 1.1, 0.15), 0, floorY + 0.7, -8.05, TRIM)
	-- Ladefläche
	box(ctx, "BedFloor", Vector3.new(spec.width, 0.4, 8), 0, floorY + 0.2, 4.2, TRIM)
	box(ctx, "BedFront", Vector3.new(spec.width, 2, 0.35), 0, floorY + 1.4, 0.4, paint, Enum.Material.SmoothPlastic)
	box(ctx, "Tailgate", Vector3.new(spec.width, 2, 0.35), 0, floorY + 1.4, 8.05, paint, Enum.Material.SmoothPlastic)
	for _, side in { -1, 1 } do
		box(ctx, `BedSide{side}`, Vector3.new(0.35, 2, 8), side * (hw - 0.17), floorY + 1.4, 4.2, paint, Enum.Material.SmoothPlastic)
		box(ctx, `BedRail{side}`, Vector3.new(0.45, 0.15, 8), side * (hw - 0.17), floorY + 2.45, 4.2, CHROME)
	end
	local cargo = box(ctx, "CargoFill", Vector3.new(spec.width - 0.9, 1.6, 7.2), 0, floorY + 1.2, 4.2, CARGO, Enum.Material.Slate)
	cargo.Transparency = 1
	cargo.CanCollide = false
	lightsAndBumpers(ctx, spec, -8.2, 8.25, floorY + 0.9)
	return Vector3.new(-1.4, floorY + 0.6, -1.4)
end

local function buildVan(ctx: Ctx, spec: Spec)
	local paint = ctx.def.PaintColor
	local hw = spec.width / 2
	local floorY = spec.r + 0.8
	box(ctx, "Nose", Vector3.new(spec.width, 2.2, 2.6), 0, floorY + 1.1, -7.5, paint, Enum.Material.SmoothPlastic)
	local body = box(ctx, "Body", Vector3.new(spec.width, 5.6, 14.6), 0, floorY + 2.8, 1.1, paint, Enum.Material.SmoothPlastic)
	box(ctx, "Windshield", Vector3.new(spec.width - 0.6, 2.6, 0.2), 0, floorY + 3.6, -6.2, GLASS, Enum.Material.Glass, CFrame.Angles(math.rad(-25), 0, 0)).Transparency = 0.35
	for _, side in { -1, 1 } do
		box(ctx, `SideWindow{side}`, Vector3.new(0.12, 1.8, 2.6), side * (hw + 0.01), floorY + 3.9, -4.4, GLASS, Enum.Material.Glass).Transparency = 0.3
		local stripe = box(ctx, `AccentStripe{side}`, Vector3.new(0.06, 0.6, 12), side * (hw + 0.02), floorY + 1.8, 1.6, ACCENT_DEFAULT)
		accentPart(stripe)
		box(ctx, `SlideDoorSeam{side}`, Vector3.new(0.05, 4.4, 0.1), side * (hw + 0.02), floorY + 2.6, -0.5, TRIM)
	end
	doorText(body, Enum.NormalId.Left)
	box(ctx, "RearDoorSeam", Vector3.new(0.1, 5, 0.06), 0, floorY + 2.8, 8.42, TRIM)
	box(ctx, "Grille", Vector3.new(3.6, 1, 0.15), 0, floorY + 0.8, -8.85, TRIM)
	box(ctx, "RoofRack", Vector3.new(spec.width - 1.4, 0.25, 9), 0, floorY + 5.75, 2, CHROME)
	local cargo = box(ctx, "CargoFill", Vector3.new(spec.width - 1, 1, 8), 0, floorY + 0.7, 3.5, CARGO, Enum.Material.Slate)
	cargo.Transparency = 1
	cargo.CanCollide = false
	lightsAndBumpers(ctx, spec, -8.8, 8.45, floorY + 1)
	return Vector3.new(-1.5, floorY + 0.7, -4.2)
end

local function buildBoxTruck(ctx: Ctx, spec: Spec)
	local paint = ctx.def.PaintColor
	local hw = spec.width / 2
	local floorY = spec.r + 1
	-- Fahrerhaus
	local cab = box(ctx, "Cab", Vector3.new(spec.width - 0.2, 5, 5.4), 0, floorY + 2.5, -8.6, paint, Enum.Material.SmoothPlastic)
	box(ctx, "CabRoof", Vector3.new(spec.width - 0.4, 0.4, 5), 0, floorY + 5.2, -8.4, paint, Enum.Material.SmoothPlastic)
	box(ctx, "Windshield", Vector3.new(spec.width - 1, 2.4, 0.2), 0, floorY + 3.6, -11.35, GLASS, Enum.Material.Glass).Transparency = 0.35
	for _, side in { -1, 1 } do
		box(ctx, `SideWindow{side}`, Vector3.new(0.12, 1.8, 2.4), side * (hw - 0.08), floorY + 3.7, -9, GLASS, Enum.Material.Glass).Transparency = 0.3
		box(ctx, `Mirror{side}`, Vector3.new(0.3, 1.2, 0.5), side * (hw + 0.5), floorY + 3.4, -10.6, TRIM)
		box(ctx, `Step{side}`, Vector3.new(0.8, 0.25, 1.6), side * (hw - 0.3), spec.r + 0.6, -8.4, CHROME)
		-- Seitenschutz zwischen den Achsen
		box(ctx, `SideGuard{side}`, Vector3.new(0.2, 0.6, 8), side * (hw - 0.4), spec.r + 0.4, 0, CHROME)
	end
	doorText(cab, Enum.NormalId.Left)
	box(ctx, "Grille", Vector3.new(4.4, 1.8, 0.2), 0, floorY + 1.2, -11.4, TRIM)
	box(ctx, "Frame", Vector3.new(4.6, 0.8, 20), 0, spec.r + 0.6, 1, TRIM)
	-- Kofferaufbau mit Firmenstreifen
	local cargoBox = box(ctx, "CargoBox", Vector3.new(spec.width + 0.4, 8, 15.4), 0, floorY + 4.6, 3.8, Color3.fromRGB(238, 238, 234), Enum.Material.SmoothPlastic)
	for _, side in { -1, 1 } do
		local stripe = box(ctx, `AccentStripe{side}`, Vector3.new(0.06, 1, 15.4), side * (hw + 0.23), floorY + 2.4, 3.8, ACCENT_DEFAULT)
		accentPart(stripe)
		local stripe2 = box(ctx, `PaintStripe{side}`, Vector3.new(0.06, 0.4, 15.4), side * (hw + 0.23), floorY + 3.2, 3.8, paint)
		stripe2.CanCollide = false
	end
	doorText(cargoBox, Enum.NormalId.Left)
	box(ctx, "RollerDoor", Vector3.new(spec.width - 0.6, 7, 0.1), 0, floorY + 4.4, 11.55, Color3.fromRGB(200, 200, 196), Enum.Material.DiamondPlate)
	local cargo = box(ctx, "CargoFill", Vector3.new(spec.width - 1, 1, 12), 0, floorY + 1.2, 4, CARGO, Enum.Material.Slate)
	cargo.Transparency = 1
	cargo.CanCollide = false
	lightsAndBumpers(ctx, spec, -11.5, 11.6, floorY + 0.6)
	return Vector3.new(-1.8, floorY + 1.6, -8.4)
end

local function wheel(ctx: Ctx, spec: Spec, name: string, x: number, z: number): Part
	local tire = Instance.new("Part")
	tire.Name = name
	tire.Shape = Enum.PartType.Cylinder
	tire.Size = Vector3.new(spec.w, spec.r * 2, spec.r * 2)
	tire.CFrame = ctx.cf * CFrame.new(x, spec.r, z)
	tire.Color = TIRE
	tire.Material = Enum.Material.Rubber
	tire.CanTouch = false
	tire.Parent = ctx.model
	local rim = Instance.new("Part")
	rim.Name = name .. "Rim"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(spec.w + 0.06, spec.r * 1.15, spec.r * 1.15)
	rim.CFrame = tire.CFrame
	rim.Color = RIM
	rim.Material = Enum.Material.Metal
	rim.CanCollide = false
	rim.CanTouch = false
	rim.Massless = true
	rim.Parent = ctx.model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = tire
	weld.Part1 = rim
	weld.Parent = rim
	return tire
end

local function attachment(parent: BasePart, name: string, worldCF: CFrame, axis: Vector3, secondary: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.Parent = parent
	a.WorldPosition = worldCF.Position
	-- Axis/SecondaryAxis erwarten Richtungen im Raum des Parents
	a.Axis = parent.CFrame:VectorToObjectSpace(worldCF:VectorToWorldSpace(axis))
	a.SecondaryAxis = parent.CFrame:VectorToObjectSpace(worldCF:VectorToWorldSpace(secondary))
	return a
end

-- Baut ein Fahrzeug. drivable = false: Ausstellungsstück (verankert, ohne Sitz/Gelenke).
function VehicleModelBuilder.build(def: Vehicles.VehicleDefinition, cf: CFrame, drivable: boolean): Model
	local spec = SPECS[def.Style]
	local model = Instance.new("Model")
	model.Name = def.Id
	model:SetAttribute("VehicleType", def.Id)
	local ctx: Ctx = { model = model, cf = cf, parts = {}, def = def }

	-- Fahrgestell: unsichtbarer, schwerer Träger knapp über den Achsen
	local chassis = box(ctx, "Chassis", Vector3.new(spec.width - 1.6, 0.8, spec.length - 3), 0, spec.r + 0.2, (spec.front + spec.rear) / 2 + 0.2, TRIM)
	chassis.Transparency = 1
	model.PrimaryPart = chassis

	local seatPos: Vector3
	if def.Style == "Pickup" then
		seatPos = buildPickup(ctx, spec)
	elseif def.Style == "Van" then
		seatPos = buildVan(ctx, spec)
	else
		seatPos = buildBoxTruck(ctx, spec)
	end

	-- Fahrersitz (links) mit Lenkrad
	local seatCF = cf * CFrame.new(seatPos)
	local seat: BasePart
	if drivable then
		local vehicleSeat = Instance.new("VehicleSeat")
		vehicleSeat.Name = "DriverSeat"
		vehicleSeat.HeadsUpDisplay = false
		vehicleSeat.MaxSpeed = def.MaxSpeed
		vehicleSeat.Torque = 0
		vehicleSeat.TurnSpeed = 0
		seat = vehicleSeat
	else
		seat = Instance.new("Part")
		seat.Name = "DriverSeat"
	end
	seat.Size = Vector3.new(2, 0.8, 2)
	seat.CFrame = seatCF
	seat.Color = SEAT
	seat.Material = Enum.Material.Fabric
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.Parent = model
	table.insert(ctx.parts, seat)
	box(ctx, "SteeringWheel", Vector3.new(0.2, 1.1, 1.1), seatPos.X, seatPos.Y + 1.6, seatPos.Z - 1.6, TRIM, Enum.Material.SmoothPlastic, CFrame.Angles(math.rad(-35), math.rad(90), 0)).Shape = Enum.PartType.Cylinder

	-- Räder
	local wheels: { [string]: Part } = {}
	for _, side in { -1, 1 } do
		local suffix = if side < 0 then "L" else "R"
		wheels["F" .. suffix] = wheel(ctx, spec, "WheelF" .. suffix, side * spec.track, spec.front)
		wheels["R" .. suffix] = wheel(ctx, spec, "WheelR" .. suffix, side * spec.track, spec.rear)
	end

	if not drivable then
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		return model
	end

	-- Fahrbetrieb: Karosserie an das Chassis schweißen, masselos; Chassis schwer
	chassis.CustomPhysicalProperties = PhysicalProperties.new(4 + def.Tier, 0.3, 0, 1, 1)
	for _, p in ctx.parts do
		p.Anchored = false
		if p ~= chassis then
			p.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = p
			weld.Parent = p
		end
	end

	local grip = PhysicalProperties.new(0.9, 1.6, 0, 100, 1)
	for key, tire in wheels do
		tire.Anchored = false
		tire.CustomPhysicalProperties = grip
		local wheelCF = tire.CFrame
		if key:sub(1, 1) == "R" then
			-- Antriebsrad: Motor-Gelenk direkt am Chassis, Achse = Fahrzeug-X
			local a0 = attachment(chassis, "Drive" .. key, wheelCF, Vector3.xAxis, Vector3.yAxis)
			local a1 = attachment(tire, "Drive" .. key, wheelCF, Vector3.xAxis, Vector3.yAxis)
			local hinge = Instance.new("HingeConstraint")
			hinge.Name = "Drive" .. key:sub(2, 2)
			hinge.Attachment0 = a0
			hinge.Attachment1 = a1
			hinge.ActuatorType = Enum.ActuatorType.Motor
			hinge.MotorMaxTorque = 30000 * def.Tier
			hinge.MotorMaxAcceleration = 12 * def.Acceleration
			hinge.AngularVelocity = 0
			hinge.Parent = chassis
		else
			-- Lenkrad: Achsschenkel (Servo um die Hochachse) + freies Rad-Gelenk
			local knuckle = Instance.new("Part")
			knuckle.Name = "Knuckle" .. key
			knuckle.Size = Vector3.new(0.4, 0.4, 0.4)
			knuckle.CFrame = wheelCF
			knuckle.Transparency = 1
			knuckle.CanCollide = false
			knuckle.CanTouch = false
			knuckle.Massless = true
			knuckle.Parent = model
			local s0 = attachment(chassis, "Steer" .. key, wheelCF, Vector3.yAxis, Vector3.xAxis)
			local s1 = attachment(knuckle, "Steer" .. key, wheelCF, Vector3.yAxis, Vector3.xAxis)
			local steer = Instance.new("HingeConstraint")
			steer.Name = "Steer" .. key:sub(2, 2)
			steer.Attachment0 = s0
			steer.Attachment1 = s1
			steer.ActuatorType = Enum.ActuatorType.Servo
			steer.ServoMaxTorque = 1e6
			steer.AngularSpeed = 3
			steer.TargetAngle = 0
			steer.LimitsEnabled = true
			steer.LowerAngle = -35
			steer.UpperAngle = 35
			steer.Parent = chassis
			local w0 = attachment(knuckle, "Spin" .. key, wheelCF, Vector3.xAxis, Vector3.yAxis)
			local w1 = attachment(tire, "Spin" .. key, wheelCF, Vector3.xAxis, Vector3.yAxis)
			local spin = Instance.new("HingeConstraint")
			spin.Name = "Spin" .. key
			spin.Attachment0 = w0
			spin.Attachment1 = w1
			spin.Parent = knuckle
		end
	end
	return model
end

-- Fahrbares Fahrzeug auf A-Chassis (D-026): unsere Karosserie (Ausstellungs-Bau) wird auf das
-- A-Chassis-Kit gesetzt; Fahrphysik, Federung, Automatik, Anzeigen und Sounds liefert A-Chassis
-- (MPL-2.0, licenses/A-Chassis-LICENSE.txt). Kit und Abstimmungen liegen in der Place-Datei unter
-- ServerStorage.Vendor.AChassis (Kit + Tunes/<VehicleId>), da Rojo nur Code synchronisiert.
--   * Räder des Kits werden samt Aufhängung an unsere Achspositionen geschoben und auf unseren
--     Radius gebracht; die Felge hängt am Rad ("Parts" wird von A-Chassis mitverschweißt).
--   * "DriveSeat" sitzt an unserer Fahrerposition, die Karosserie liegt in car.Body.
--   * Die Abstimmung (Gewicht, Motor, Getriebe) kommt aus Tunes/<VehicleId>.
function VehicleModelBuilder.buildAChassis(def: Vehicles.VehicleDefinition, cf: CFrame, vendor: Instance): Model?
	local kit = vendor:FindFirstChild("Kit")
	local tunes = vendor:FindFirstChild("Tunes")
	local tuneTemplate = tunes and tunes:FindFirstChild(def.Id)
	if not (kit and kit:IsA("Model") and tuneTemplate) then
		return nil
	end
	local spec = SPECS[def.Style]
	local car = kit:Clone()
	car.Name = def.Id
	car:SetAttribute("VehicleType", def.Id)
	local seat = car:FindFirstChild("DriveSeat") :: VehicleSeat
	local wheels = car:FindFirstChild("Wheels") :: Model
	local body = car:FindFirstChild("Body") :: Model

	-- Kit-Bezugsrahmen: Mitte der Radaufstandspunkte, Blickrichtung des Fahrersitzes
	local sumPos, count, kitRadius = Vector3.zero, 0, 1.2
	for _, w in wheels:GetChildren() do
		if w:IsA("BasePart") then
			sumPos += w.Position
			count += 1
			kitRadius = w.Size.Y / 2
		end
	end
	local center = sumPos / math.max(1, count)
	local ground = Vector3.new(center.X, center.Y - kitRadius, center.Z)
	local look = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z).Unit
	local kitFrame = CFrame.lookAt(ground, ground + look)
	car:PivotTo(cf * kitFrame:Inverse() * car:GetPivot())

	-- Räder samt Aufhängung an unsere Achsen schieben und auf unseren Radius bringen
	local targets = {
		FL = Vector3.new(-spec.track, spec.r, spec.front),
		FR = Vector3.new(spec.track, spec.r, spec.front),
		RL = Vector3.new(-spec.track, spec.r, spec.rear),
		RR = Vector3.new(spec.track, spec.r, spec.rear),
	}
	for name, localPos in targets do
		local wheel = wheels:FindFirstChild(name)
		if wheel and wheel:IsA("BasePart") then
			local delta = (cf * CFrame.new(localPos)).Position - wheel.Position
			for _, d in wheel:GetDescendants() do
				if d:IsA("BasePart") then
					d.CFrame += delta
				end
			end
			wheel.CFrame += delta
			wheel.Size = Vector3.new(spec.w, spec.r * 2, spec.r * 2)
			wheel.Color = TIRE
			wheel.Material = Enum.Material.Rubber
			wheel.Transparency = 0
			local parts = wheel:FindFirstChild("Parts")
			if parts then
				local rim = Instance.new("Part")
				rim.Name = "Rim"
				rim.Shape = Enum.PartType.Cylinder
				rim.Size = Vector3.new(spec.w + 0.06, spec.r * 1.15, spec.r * 1.15)
				rim.CFrame = wheel.CFrame
				rim.Color = RIM
				rim.Material = Enum.Material.Metal
				rim.CanCollide = false
				rim.CanTouch = false
				rim.Anchored = true
				rim.Parent = parts
			end
		end
	end

	-- Unsere Karosserie (Ausstellungs-Bau) übernehmen: ohne eigenes Chassis, Sitz und Räder
	local display = VehicleModelBuilder.build(def, cf, false)
	local seatPart = display:FindFirstChild("DriverSeat")
	local seatCF = if seatPart and seatPart:IsA("BasePart") then seatPart.CFrame else cf * CFrame.new(-1.5, spec.r + 1.5, -2)
	for _, child in display:GetChildren() do
		local n = child.Name
		if n == "Chassis" or n == "DriverSeat" or n:sub(1, 5) == "Wheel" then
			child:Destroy()
		elseif child:IsA("BasePart") then
			child.Parent = body
		end
	end
	display:Destroy()
	-- Fahrersitz an unsere Position (Blickrichtung = Fahrtrichtung)
	seat.CFrame = seatCF
	seat.Color = SEAT
	seat.Transparency = 0
	seat.HeadsUpDisplay = false

	-- Abstimmung des Fahrzeugtyps einsetzen
	local oldTune = car:FindFirstChild("A-Chassis Tune")
	if oldTune then
		oldTune:Destroy()
	end
	local tune = tuneTemplate:Clone()
	tune.Name = "A-Chassis Tune"
	tune.Parent = car
	car.PrimaryPart = seat
	return car
end

-- Firmenfarbe und Firmenname anwenden (docs/07 §36–37)
function VehicleModelBuilder.applyCompany(model: Model, accent: Color3?, companyName: string)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("CompanyAccent") == true then
			d.Color = accent or ACCENT_DEFAULT
		elseif d:IsA("TextLabel") and d.Parent and d.Parent.Name == "DoorText" then
			d.Text = string.upper(companyName)
		end
	end
end

-- Sichtbare Ladung (rein kosmetisch, docs/07 §44): Füllhöhe nach Anteil
function VehicleModelBuilder.setCargoVisual(model: Model, fraction: number)
	local cargo = model:FindFirstChild("CargoFill", true)
	if cargo and cargo:IsA("BasePart") then
		cargo.Transparency = if fraction > 0 then 0 else 1
	end
end

return table.freeze(VehicleModelBuilder)
