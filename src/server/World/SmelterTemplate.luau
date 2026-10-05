--!strict
-- Schmelzer im linken Hallenbereich (docs/06 §28–35, FACTORY_MASTERPLAN_TOPDOWN.png).
-- PLATZHALTER-Optik: gemauerter Hochofen mit glühender Öffnung, Stahlgerüst, Kamin,
-- Einfülltrichter (Input) links, Barren-Rutsche mit Ablage (Output) rechts, Bedienterminal mit
-- Anzeige, Statuslampe. Effekte (Glut, Feuer, Funken, Rauch) nur im Betrieb (docs/06 §32).
-- Markierte Anschlüsse für die Förderbänder (Phase 7b, docs/06 §23).
--
-- Vereinbarte Namen/Attribute:
--   Part "SmelterTerminalPart" mit ProximityPrompt "SmelterPrompt" (Attribut SmelterTerminal = true)
--   Part "SmelterDisplay"      (SurfaceGui "Display": "Status", "Input", "Output")
--   Part "StatusLight", Part "FurnaceGlow", Emitter "Fire"/"Sparks"/"Smoke"
--   Part "BarStack1".."BarStack6" (sichtbare Barren, kosmetisch)
--   Part "ConveyorInPort"/"ConveyorOutPort" (Anschlusspunkte für Förderbänder)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LayoutConfig)

local SmelterTemplate = {}

local BRICK = Color3.fromRGB(120, 64, 48)
local BRICK_DARK = Color3.fromRGB(80, 44, 34)
local STEEL = Color3.fromRGB(70, 74, 80)
local STEEL_DARK = Color3.fromRGB(42, 44, 48)
local STEEL_LIGHT = Color3.fromRGB(150, 154, 160)
local CONCRETE = Color3.fromRGB(120, 118, 114)
local YELLOW = Color3.fromRGB(236, 182, 40)
local BLACK = Color3.fromRGB(30, 30, 30)
local GLOW = Color3.fromRGB(255, 120, 30)
local GLOW_OFF = Color3.fromRGB(60, 36, 28)
local BAR = Color3.fromRGB(196, 128, 70)
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
	-- Anschlusspunkt für ein Förderband: gelb-schwarz umrandete Bodenplatte
	local pad = part(model, name, Vector3.new(4, 0.08, 4), cf * CFrame.new(0, 0.04, 0), BLACK, Enum.Material.SmoothPlastic)
	pad.CanCollide = false
	for i, offset in { Vector3.new(0, 0.05, 1.9), Vector3.new(0, 0.05, -1.9) } do
		local edge = part(model, `{name}Edge{i}`, Vector3.new(4, 0.1, 0.25), cf * CFrame.new(offset), YELLOW, Enum.Material.SmoothPlastic)
		edge.CanCollide = false
	end
end

function SmelterTemplate.build(plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Smelter"
	local zone = LayoutConfig.HallZones.Smelter
	-- Front (lokal -Z) zeigt zur Hallenmitte (+X der Plotachse)
	local f = plotCFrame * CFrame.new(zone.Center.X + 4, LayoutConfig.HallFloorTop, zone.Center.Y - 8) * CFrame.Angles(0, math.rad(-90), 0)

	-- Fundament
	part(model, "Plinth", Vector3.new(30, 0.6, 22), f * CFrame.new(0, 0.3, 2), CONCRETE, Enum.Material.Concrete)
	for i = 1, 10 do
		local stripe = part(model, `PlinthEdge{i}`, Vector3.new(3, 0.62, 0.4), f * CFrame.new(-15 + 3 * (i - 0.5), 0.31, -8.8), if i % 2 == 0 then BLACK else YELLOW, Enum.Material.SmoothPlastic)
		stripe.CanCollide = false
	end

	-- Hochofen: Mauerwerk mit Stahlbändern
	local body = part(model, "FurnaceBody", Vector3.new(12, 12, 12), f * CFrame.new(0, 6.6, 3), BRICK, Enum.Material.Brick)
	body.CastShadow = true
	part(model, "FurnaceTop", Vector3.new(10, 3, 10), f * CFrame.new(0, 14.1, 3), BRICK_DARK, Enum.Material.Brick)
	for i, y in { 3, 8, 12.4 } do
		part(model, `Band{i}`, Vector3.new(12.4, 0.5, 12.4), f * CFrame.new(0, y, 3), STEEL_DARK)
	end
	-- Glühende Öffnung vorne (Glut nur im Betrieb)
	part(model, "MouthFrame", Vector3.new(6, 5, 0.6), f * CFrame.new(0, 4.6, -3.2), STEEL_DARK)
	local glow = part(model, "FurnaceGlow", Vector3.new(4.6, 3.6, 0.3), f * CFrame.new(0, 4.4, -3.4), GLOW_OFF, Enum.Material.Neon)
	glow.CanCollide = false
	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Color = GLOW
	light.Range = 18
	light.Brightness = 2
	light.Enabled = false
	light.Parent = glow
	local fireAttachment = Instance.new("Attachment")
	fireAttachment.Name = "FireAttachment"
	fireAttachment.Parent = glow
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "Fire"
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 80, 20))
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0.2) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	fire.Lifetime = NumberRange.new(0.5, 0.9)
	fire.Rate = 18
	fire.Speed = NumberRange.new(1, 2.5)
	fire.SpreadAngle = Vector2.new(20, 20)
	fire.LightEmission = 1
	fire.Enabled = false
	fire.Parent = fireAttachment
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120))
	sparks.Size = NumberSequence.new(0.2)
	sparks.Lifetime = NumberRange.new(0.4, 0.8)
	sparks.Rate = 10
	sparks.Speed = NumberRange.new(6, 10)
	sparks.SpreadAngle = Vector2.new(40, 40)
	sparks.Acceleration = Vector3.new(0, -25, 0)
	sparks.LightEmission = 1
	sparks.Enabled = false
	sparks.Parent = fireAttachment

	-- Kamin mit dezentem Rauch (endet unter dem Hallendach)
	local chimneyBase = f * CFrame.new(3, 15.6, 6)
	local chimney = part(model, "Chimney", Vector3.new(14, 3, 3), chimneyBase * CFrame.new(0, 7, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL)
	chimney.Shape = Enum.PartType.Cylinder
	local cap = part(model, "ChimneyCap", Vector3.new(0.6, 4, 4), chimneyBase * CFrame.new(0, 14.2, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL_DARK)
	cap.Shape = Enum.PartType.Cylinder
	local smokeAttachment = Instance.new("Attachment")
	smokeAttachment.Name = "SmokeAttachment"
	smokeAttachment.Parent = cap
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(110, 106, 102))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(1.5, 2.5)
	smoke.Rate = 4
	smoke.Speed = NumberRange.new(2, 3)
	smoke.Enabled = false
	smoke.Parent = smokeAttachment

	-- Stahlgerüst mit Laufsteg an der Seite
	for _, x in { -7.5, 7.5 } do
		for _, z in { -3.5, 9.5 } do
			part(model, `Frame{x}_{z}`, Vector3.new(0.6, 10, 0.6), f * CFrame.new(x, 5.6, z), STEEL)
		end
	end
	part(model, "Catwalk", Vector3.new(16, 0.4, 3), f * CFrame.new(0, 10.6, 10.6), STEEL_LIGHT, Enum.Material.DiamondPlate)
	part(model, "CatwalkRail", Vector3.new(16, 0.2, 0.2), f * CFrame.new(0, 12, 12), YELLOW, Enum.Material.SmoothPlastic)

	-- Einfülltrichter links (Input)
	local hopperCF = f * CFrame.new(-11, 0, 0)
	for _, x in { -2, 2 } do
		for _, z in { -2, 2 } do
			part(model, `HopperLeg{x}_{z}`, Vector3.new(0.5, 8, 0.5), hopperCF * CFrame.new(x, 4.6, z), STEEL)
		end
	end
	part(model, "Hopper", Vector3.new(5, 3, 5), hopperCF * CFrame.new(0, 10, 0), STEEL_LIGHT)
	part(model, "HopperFunnel", Vector3.new(3, 1.6, 3), hopperCF * CFrame.new(0, 7.8, 0), STEEL)
	part(model, "HopperChute", Vector3.new(6, 1, 1.6), hopperCF * CFrame.new(3.5, 8, 0) * CFrame.Angles(0, 0, math.rad(-15)), STEEL)
	local inSign = part(model, "InputSign", Vector3.new(4, 1.2, 0.2), hopperCF * CFrame.new(0, 12.4, -2.6), STEEL_DARK, Enum.Material.SmoothPlastic)
	label(inSign, Enum.NormalId.Front, "INPUT", YELLOW)
	port(model, "ConveyorInPort", hopperCF * CFrame.new(-4.5, 0.6, 0))

	-- Barren-Rutsche rechts (Output) mit sichtbaren Barrenstapeln
	local trayCF = f * CFrame.new(11, 0, 0)
	part(model, "OutputChute", Vector3.new(6, 0.6, 2.4), trayCF * CFrame.new(-3.5, 5, 0) * CFrame.Angles(0, 0, math.rad(25)), STEEL)
	part(model, "Tray", Vector3.new(5, 0.6, 5), trayCF * CFrame.new(0, 3, 0), STEEL_LIGHT, Enum.Material.DiamondPlate)
	for _, x in { -2.2, 2.2 } do
		for _, z in { -2.2, 2.2 } do
			part(model, `TrayLeg{x}_{z}`, Vector3.new(0.4, 2.7, 0.4), trayCF * CFrame.new(x, 1.65, z), STEEL)
		end
	end
	for i = 1, 6 do
		local row, col = math.floor((i - 1) / 3), (i - 1) % 3
		local bar = part(model, `BarStack{i}`, Vector3.new(1.2, 0.5, 3), trayCF * CFrame.new(-1.4 + col * 1.4, 3.55 + row * 0.5, 0), BAR, Enum.Material.Metal)
		bar.Transparency = 1
		bar.CanCollide = false
	end
	local outSign = part(model, "OutputSign", Vector3.new(4, 1.2, 0.2), trayCF * CFrame.new(0, 6.6, -2.6), STEEL_DARK, Enum.Material.SmoothPlastic)
	label(outSign, Enum.NormalId.Front, "OUTPUT", YELLOW)
	port(model, "ConveyorOutPort", trayCF * CFrame.new(4.5, 0.6, 0))

	-- Statuslampe auf dem Ofen
	local lamp = part(model, "StatusLight", Vector3.new(0.9, 0.9, 0.9), f * CFrame.new(-4, 16, -1), LAMP_IDLE, Enum.Material.Neon)
	lamp.Shape = Enum.PartType.Ball
	local lampLight = Instance.new("PointLight")
	lampLight.Name = "Glow"
	lampLight.Color = LAMP_IDLE
	lampLight.Range = 8
	lampLight.Parent = lamp

	-- Bedienterminal vorne mit Anzeige
	local terminalCF = f * CFrame.new(-5, 0, -8)
	part(model, "TerminalPost", Vector3.new(1.2, 3.6, 1.2), terminalCF * CFrame.new(0, 2.4, 0), STEEL_DARK)
	local display = part(model, "SmelterDisplay", Vector3.new(4, 2.6, 0.3), terminalCF * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(24, 27, 33), Enum.Material.SmoothPlastic)
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

function SmelterTemplate.setStatus(model: Model, status: string, inputText: string, outputText: string, outputFraction: number)
	local color = STATUS_COLORS[status] or LAMP_IDLE
	local running = status == "Running"
	local lamp = model:FindFirstChild("StatusLight")
	if lamp and lamp:IsA("BasePart") then
		lamp.Color = color
		local l = lamp:FindFirstChild("Glow")
		if l and l:IsA("PointLight") then
			l.Color = color
		end
	end
	local glow = model:FindFirstChild("FurnaceGlow")
	if glow and glow:IsA("BasePart") then
		glow.Color = if running then GLOW else GLOW_OFF
		local l = glow:FindFirstChild("Glow")
		if l and l:IsA("PointLight") then
			l.Enabled = running
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.Enabled = running
		end
	end
	local display = model:FindFirstChild("SmelterDisplay")
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
	-- Sichtbare Barren nach Füllstand der Ablage
	local shown = math.ceil(math.clamp(outputFraction, 0, 1) * 6)
	for i = 1, 6 do
		local bar = model:FindFirstChild(`BarStack{i}`)
		if bar and bar:IsA("BasePart") then
			bar.Transparency = if i <= shown then 0 else 1
		end
	end
end

return table.freeze(SmelterTemplate)
