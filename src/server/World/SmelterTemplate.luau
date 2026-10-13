--!strict
-- Schmelze rechts in der Halle wie FACTORY_MASTERPLAN_TOPDOWN.png (Phase 13b-4, Felix D-037):
--   * Eingangslager hinten: 4 Hochregale × 4 Paletten (16 Kisten Erz)
--   * Drehrohrofen in Längsrichtung mit Laufringen, Tragrollen, Zahnkranz und Antrieb; vorne die
--     Brennerhaube mit glühender Öffnung (Glut, Feuer, Funken, Rauch nur im Betrieb)
--   * Schnecke von der Haube zum Ausgangslager vorne: 4 Hochregale × 4 Paletten (16 Kisten Barren)
--   * Zuführband (Optik) vom Eingangslager zum Aufgabetrichter, Abgaskamin, Bedienterminal
--   * außen an der rechten Wand zwei Tanks mit Leitungen in die Halle
-- Förderbänder: Lager → Eingangslager (StorageToSmelter), Ausgangslager → Lager (SmelterToStorage).
--
-- Vereinbarte Namen/Attribute:
--   Part "SmelterTerminalPart" mit ProximityPrompt "SmelterPrompt" (Attribut SmelterTerminal = true)
--   Part "SmelterDisplay"      (SurfaceGui "Display": "Status", "Input", "Output")
--   Part "StatusLight", Part "FurnaceGlow", Part "KilnHotZone", Emitter "Fire"/"Sparks"/"Smoke"
--   Model "InputStore"/"OutputStore" mit Folder "Crates" (Slot1..16, CrateRackBuilder)
--   Part "ConveyorInPort"/"ConveyorOutPort" (Anschlusspunkte der Förderbänder)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local BalanceConfig = require(Shared.Config.BalanceConfig)

local CrateRackBuilder = require(script.Parent.CrateRackBuilder)

local SmelterTemplate = {}

local SHELL = Color3.fromRGB(150, 116, 92)
local SHELL_DARK = Color3.fromRGB(92, 70, 56)
local STEEL = Color3.fromRGB(70, 74, 80)
local STEEL_DARK = Color3.fromRGB(42, 44, 48)
local STEEL_LIGHT = Color3.fromRGB(150, 154, 160)
local TANK = Color3.fromRGB(196, 200, 206)
local CONCRETE = Color3.fromRGB(120, 118, 114)
local ORANGE = Color3.fromRGB(226, 150, 40)
local YELLOW = Color3.fromRGB(236, 182, 40)
local BLACK = Color3.fromRGB(30, 30, 30)
local GLOW = Color3.fromRGB(255, 120, 30)
local GLOW_HOT = Color3.fromRGB(255, 150, 60)
local GLOW_OFF = Color3.fromRGB(60, 36, 28)
local HOT_OFF = Color3.fromRGB(110, 82, 66)
local LAMP_IDLE = Color3.fromRGB(255, 160, 30)

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanTouch = false
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function cylinder(parent: Instance, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(length, diameter, diameter), cf, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function label(target: BasePart, face: Enum.NormalId, text: string, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = target
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.TextColor3 = color
	l.Text = text
	l.Parent = gui
end

local function port(model: Model, name: string, cf: CFrame)
	local p = part(model, name, Vector3.new(3, 0.2, 3), cf, YELLOW, Enum.Material.SmoothPlastic)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
end

-- Hochregal-Block (4 Regale) mit Schild
local function store(model: Model, name: string, origin: CFrame, face: number, title: string): Model
	local block = Instance.new("Model")
	block.Name = name
	CrateRackBuilder.build(block, origin, { { Z = 0, Face = face } }, 4)
	local sign = part(block, `{name}Sign`, Vector3.new(14, 2.4, 0.3), origin * CFrame.new(0, 33, face * (CrateRackBuilder.Depth / 2 + 0.2)), STEEL_DARK, Enum.Material.SmoothPlastic)
	label(sign, if face < 0 then Enum.NormalId.Front else Enum.NormalId.Back, title, YELLOW)
	block.Parent = model
	return block
end

function SmelterTemplate.build(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Smelter"
	local zone = LayoutConfig.HallZones.Smelter
	local floorY = LayoutConfig.HallFloorTop
	-- Positionen lokal zur Plotmitte (X/Z), y über Hallenboden
	local function at(x: number, y: number, z: number): CFrame
		return plotCFrame * CFrame.new(x, floorY + y, z)
	end
	local zx, zz = zone.Center.X, zone.Center.Y
	local hallRight = LayoutConfig.HallOffset.X - LayoutConfig.HallSize.X / 2

	-- Bodenplatte mit Warnkante
	local slabCF = at(zx, 0, zz)
	part(model, "Floor", Vector3.new(zone.Size.X - 4, 0.12, zone.Size.Y - 4), slabCF * CFrame.new(0, 0.06, 0), CONCRETE, Enum.Material.Concrete).CanCollide = false
	for i = 1, 20 do
		local stripe = part(model, `ZoneEdge{i}`, Vector3.new(0.6, 0.14, (zone.Size.Y - 4) / 20), slabCF * CFrame.new(zone.Size.X / 2 - 2, 0.07, -(zone.Size.Y - 4) / 2 + (zone.Size.Y - 4) / 20 * (i - 0.5)), if i % 2 == 0 then BLACK else YELLOW, Enum.Material.SmoothPlastic)
		stripe.CanCollide = false
	end

	-- Eingangslager hinten (4 Hochregale, Fächer nach vorne)
	local inputZ = zz + zone.Size.Y / 2 - 13
	local inputX = zx + 20
	store(model, "InputStore", at(inputX, 0, inputZ), -1, "ORE INPUT")
	port(model, "ConveyorInPort", at(inputX + 20, 0.6, inputZ - 8))

	-- Drehrohrofen in Längsrichtung (Z), Aufgabe hinten, Brennerhaube vorne
	local kilnX = zx - 27
	local backZ, frontZ = zz + 67, zz + 7
	local kilnLen = backZ - frontZ
	local kilnY = 9
	local kilnD = 13
	local axis = at(kilnX, kilnY, (backZ + frontZ) / 2) * CFrame.Angles(math.rad(-2), 0, 0) * CFrame.Angles(0, math.rad(90), 0)
	cylinder(model, "KilnShell", kilnLen, kilnD, axis, SHELL, Enum.Material.Metal)
	for i, t in { -0.38, 0, 0.38 } do
		cylinder(model, `RidingRing{i}`, 1.6, kilnD + 1.4, axis * CFrame.new(t * kilnLen, 0, 0), STEEL_DARK, Enum.Material.Metal)
		-- Tragrollen auf einem Betonsockel
		local pierZ = (backZ + frontZ) / 2 + t * kilnLen
		part(model, `Pier{i}`, Vector3.new(16, kilnY - kilnD / 2 - 0.4, 4), at(kilnX, (kilnY - kilnD / 2 - 0.4) / 2, pierZ), CONCRETE, Enum.Material.Concrete)
		for _, side in { -1, 1 } do
			cylinder(model, `Roller{i}_{side}`, 2, 2.6, at(kilnX + side * 4.6, kilnY - kilnD / 2 - 0.6, pierZ) * CFrame.Angles(0, math.rad(90), 0), STEEL, Enum.Material.Metal)
		end
	end
	cylinder(model, "GirthGear", 1.2, kilnD + 2.4, axis * CFrame.new(0.18 * kilnLen, 0, 0), STEEL, Enum.Material.DiamondPlate)
	part(model, "DriveMotor", Vector3.new(4, 4, 6), at(kilnX + 10, 2, (backZ + frontZ) / 2 - 0.18 * kilnLen * 0.95), ORANGE, Enum.Material.Metal)
	part(model, "DriveGearbox", Vector3.new(3, 3, 3), at(kilnX + 8, 2.5 + 1.5, (backZ + frontZ) / 2 - 0.18 * kilnLen * 0.95 - 4), STEEL_DARK, Enum.Material.Metal)
	-- heiße Zone vorne am Rohr: glüht im Betrieb
	local hot = cylinder(model, "KilnHotZone", 8, kilnD + 0.3, axis * CFrame.new(kilnLen / 2 - 5, 0, 0), HOT_OFF, Enum.Material.Metal)
	hot.CanCollide = false

	-- Aufgabe hinten: Trichter und Zuführband vom Eingangslager
	local feedCF = at(kilnX, 0, backZ + 3)
	part(model, "FeedHousing", Vector3.new(14, 16, 6), feedCF * CFrame.new(0, 8, 0), SHELL_DARK, Enum.Material.Metal)
	part(model, "FeedHopper", Vector3.new(7, 4, 6), feedCF * CFrame.new(0, 18, 0), STEEL_LIGHT, Enum.Material.Metal)
	local beltLen = (inputX - 18) - (kilnX + 4)
	part(model, "FeedBelt", Vector3.new(beltLen, 0.6, 3), at(kilnX + 4 + beltLen / 2, 19.5, backZ + 3), STEEL_DARK, Enum.Material.DiamondPlate)
	for i = 0, 3 do
		part(model, `FeedBeltLeg{i}`, Vector3.new(0.5, 19.2, 0.5), at(kilnX + 9 + i * (beltLen - 8) / 3, 9.6, backZ + 3), STEEL, Enum.Material.Metal)
	end

	-- Brennerhaube vorne mit glühender Öffnung
	local hoodCF = at(kilnX, 0, frontZ - 4)
	part(model, "Hood", Vector3.new(18, 20, 8), hoodCF * CFrame.new(0, 10, 0), SHELL_DARK, Enum.Material.Metal)
	part(model, "HoodRoof", Vector3.new(19, 1, 9), hoodCF * CFrame.new(0, 20.5, 0), STEEL_DARK, Enum.Material.Metal)
	part(model, "MouthFrame", Vector3.new(10, 9, 0.6), hoodCF * CFrame.new(0, 9, -4.2), STEEL_DARK, Enum.Material.Metal)
	local glow = part(model, "FurnaceGlow", Vector3.new(8.4, 7.4, 0.3), hoodCF * CFrame.new(0, 9, -4.45), GLOW_OFF, Enum.Material.Neon)
	glow.CanCollide = false
	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Color = GLOW
	light.Range = 30
	light.Brightness = 3
	light.Enabled = false
	light.Parent = glow
	local fireAttachment = Instance.new("Attachment")
	fireAttachment.Name = "FireAttachment"
	fireAttachment.Parent = glow
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "Fire"
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 80, 20))
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.6), NumberSequenceKeypoint.new(1, 0.3) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	fire.Lifetime = NumberRange.new(0.5, 0.9)
	fire.Rate = 26
	fire.Speed = NumberRange.new(1, 3)
	fire.SpreadAngle = Vector2.new(25, 25)
	fire.LightEmission = 1
	fire.Enabled = false
	fire.Parent = fireAttachment
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120))
	sparks.Size = NumberSequence.new(0.25)
	sparks.Lifetime = NumberRange.new(0.4, 0.9)
	sparks.Rate = 14
	sparks.Speed = NumberRange.new(6, 11)
	sparks.SpreadAngle = Vector2.new(45, 45)
	sparks.Acceleration = Vector3.new(0, -25, 0)
	sparks.LightEmission = 1
	sparks.Enabled = false
	sparks.Parent = fireAttachment
	-- Brennerrohr seitlich in die Haube
	cylinder(model, "BurnerPipe", 10, 1.6, hoodCF * CFrame.new(11, 12, 0), STEEL_LIGHT, Enum.Material.Metal)
	-- Abgaskamin bis unters Dach, Rauch nur im Betrieb
	local stackH = LayoutConfig.HallWallHeight - 22.5
	local stack = cylinder(model, "Stack", stackH, 3.4, hoodCF * CFrame.new(-5, 21 + stackH / 2, 2) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
	local smokeAttachment = Instance.new("Attachment")
	smokeAttachment.Name = "SmokeAttachment"
	smokeAttachment.Position = Vector3.new(stackH / 2, 0, 0)
	smokeAttachment.Parent = stack
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(110, 106, 102))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(1, 1.6)
	smoke.Rate = 5
	smoke.Speed = NumberRange.new(2, 3)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Enabled = false
	smoke.Parent = smokeAttachment

	-- Statuslampe auf der Haube
	local lamp = part(model, "StatusLight", Vector3.new(1.2, 1.2, 1.2), hoodCF * CFrame.new(6, 21.6, -3), LAMP_IDLE, Enum.Material.Neon)
	lamp.Shape = Enum.PartType.Ball
	local lampLight = Instance.new("PointLight")
	lampLight.Name = "Glow"
	lampLight.Color = LAMP_IDLE
	lampLight.Range = 10
	lampLight.Parent = lamp

	-- Schnecke von der Haube schräg hinab zum Ausgangslager
	local outputZ = zz - 58
	local outputX = zx - 20
	local screwFrom = at(kilnX, 3.5, frontZ - 8.5)
	local screwTo = at(outputX - 10, 8, outputZ + CrateRackBuilder.Depth / 2 + 3)
	local mid = (screwFrom.Position + screwTo.Position) / 2
	local screwLen = (screwTo.Position - screwFrom.Position).Magnitude
	local screwCF = CFrame.lookAt(mid, screwTo.Position)
	part(model, "Screw", Vector3.new(2.6, 2.6, screwLen), screwCF, STEEL, Enum.Material.Metal)
	for i = 1, math.floor(screwLen / 4) do
		part(model, `ScrewRing{i}`, Vector3.new(3, 3, 0.4), screwCF * CFrame.new(0, 0, -screwLen / 2 + i * 4), STEEL_DARK, Enum.Material.Metal)
	end
	for i, t in { 0.3, 0.7 } do
		local p = screwFrom.Position:Lerp(screwTo.Position, t)
		local h = p.Y - (plotCFrame.Position.Y + floorY)
		part(model, `ScrewLeg{i}`, Vector3.new(0.5, h, 0.5), CFrame.new(p.X, p.Y - h / 2, p.Z), STEEL, Enum.Material.Metal)
	end

	-- Ausgangslager vorne (4 Hochregale, Fächer nach vorne zur Garage)
	store(model, "OutputStore", at(outputX, 0, outputZ), -1, "BAR OUTPUT")
	port(model, "ConveyorOutPort", at(outputX + 20, 0.6, outputZ + 8))

	-- Bedienterminal vorne an der Haube, Anzeige zur Hallenmitte
	local terminalCF = CFrame.lookAt(at(kilnX + 20, 0, frontZ - 10).Position, at(0, 0, frontZ - 10).Position)
	part(model, "TerminalPost", Vector3.new(1.2, 3.6, 1.2), terminalCF * CFrame.new(0, 2.4, 0), STEEL_DARK)
	local display = part(model, "SmelterDisplay", Vector3.new(5, 3, 0.3), terminalCF * CFrame.new(0, 5.4, 0) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(24, 27, 33), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Parent = display
	for i, name in { "Status", "Input", "Output" } do
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Position = UDim2.fromScale(0.05, (i - 1) * 0.32 + 0.04)
		l.Size = UDim2.fromScale(0.9, 0.28)
		l.BackgroundTransparency = 1
		l.Font = if i == 1 then Enum.Font.GothamBlack else Enum.Font.GothamBold
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = if i == 1 then LAMP_IDLE else Color3.fromRGB(220, 224, 230)
		l.Text = if i == 1 then "IDLE" else ""
		l.Parent = gui
	end
	local promptPart = part(model, "SmelterTerminalPart", Vector3.new(3, 4, 3), terminalCF * CFrame.new(0, 3, -1.5), STEEL, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SmelterPrompt"
	prompt.ActionText = "Smelter"
	prompt.ObjectText = "Furnace Control"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("SmelterTerminal", true)
	prompt.Parent = promptPart

	-- Zwei Tanks außen an der rechten Hallenwand mit Leitungen in die Halle
	local tankX = hallRight - 20
	for i, tz in { zz + 48, zz + 14 } do
		local base = at(tankX, -floorY + 1, tz)
		for _, dx in { -6, 6 } do
			for _, dz in { -6, 6 } do
				part(model, `TankLeg{i}_{dx}_{dz}`, Vector3.new(0.8, 6, 0.8), base * CFrame.new(dx, 3, dz), STEEL, Enum.Material.Metal)
			end
		end
		cylinder(model, `Tank{i}`, 28, 18, base * CFrame.new(0, 6 + 14, 0) * CFrame.Angles(0, 0, math.rad(90)), TANK, Enum.Material.Metal)
		local dome = part(model, `TankDome{i}`, Vector3.new(18, 7, 18), base * CFrame.new(0, 34, 0), TANK, Enum.Material.Metal)
		dome.Shape = Enum.PartType.Ball
		for _, y in { 12, 20, 28 } do
			cylinder(model, `TankBand{i}_{y}`, 0.6, 18.4, base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL_LIGHT, Enum.Material.Metal)
		end
		part(model, `TankLadder{i}`, Vector3.new(1.4, 30, 0.3), base * CFrame.new(0, 21, -9.2), STEEL_DARK, Enum.Material.DiamondPlate)
		cylinder(model, `TankPipe{i}`, 20 - 9, 1.6, base * CFrame.new(9 + (20 - 9) / 2, 18, 0), STEEL_LIGHT, Enum.Material.Metal)
	end

	return model
end

-- Status und Anzeige setzen (docs/06 §32–33): Grün läuft, Orange wartet, Rot blockiert.
local STATUS_COLORS: { [string]: Color3 } = {
	Running = Color3.fromRGB(70, 210, 90),
	WaitingForInput = LAMP_IDLE,
	Idle = LAMP_IDLE,
	OutputFull = Color3.fromRGB(225, 55, 45),
}
local STATUS_TEXT: { [string]: string } = {
	Running = "RUNNING",
	WaitingForInput = "WAITING FOR INPUT",
	Idle = "IDLE",
	OutputFull = "OUTPUT FULL",
}

function SmelterTemplate.setStatus(model: Model, status: string, inputText: string, outputText: string)
	local color = STATUS_COLORS[status] or LAMP_IDLE
	local running = status == "Running"
	local lamp = model:FindFirstChild("StatusLight", true)
	if lamp and lamp:IsA("BasePart") then
		lamp.Color = color
		local l = lamp:FindFirstChild("Glow")
		if l and l:IsA("PointLight") then
			l.Color = color
		end
	end
	local glow = model:FindFirstChild("FurnaceGlow", true)
	if glow and glow:IsA("BasePart") then
		glow.Color = if running then GLOW else GLOW_OFF
		local l = glow:FindFirstChild("Glow")
		if l and l:IsA("PointLight") then
			l.Enabled = running
		end
	end
	local hot = model:FindFirstChild("KilnHotZone", true)
	if hot and hot:IsA("BasePart") then
		hot.Color = if running then GLOW_HOT else HOT_OFF
		hot.Material = if running then Enum.Material.Neon else Enum.Material.Metal
	end
	for _, d in model:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.Enabled = running
		end
	end
	local display = model:FindFirstChild("SmelterDisplay", true)
	local gui = display and display:FindFirstChild("Display")
	if gui then
		local statusLabel = gui:FindFirstChild("Status")
		if statusLabel and statusLabel:IsA("TextLabel") then
			statusLabel.Text = STATUS_TEXT[status] or status
			statusLabel.TextColor3 = color
		end
		local inputLabel = gui:FindFirstChild("Input")
		if inputLabel and inputLabel:IsA("TextLabel") then
			inputLabel.Text = inputText
		end
		local outputLabel = gui:FindFirstChild("Output")
		if outputLabel and outputLabel:IsA("TextLabel") then
			outputLabel.Text = outputText
		end
	end
end

-- Kisten im Eingangs- und Ausgangslager anzeigen (alle 16 Plätze je Lager sind vorhanden)
function SmelterTemplate.setCrates(model: Model, input: { [string]: number }, output: { [string]: number })
	local cfg = BalanceConfig.Smelter
	for name, items in { InputStore = input, OutputStore = output } do
		local block = model:FindFirstChild(name, true)
		local crates = block and block:FindFirstChild("Crates")
		if crates then
			CrateRackBuilder.update(crates, items, if name == "InputStore" then cfg.InputCrates else cfg.OutputCrates)
		end
	end
end

return table.freeze(SmelterTemplate)
