--!strict
-- Drill-Modell (docs/10 §29): echte Mining-Maschine statt Box mit Zylinder.
-- Aufbau: Kufenrahmen mit Warnstreifen, Deck, Motorgehäuse mit Lüftungsgitter und Auspuff,
-- Ausleger mit Hydraulikzylindern, Getriebe und Bohrkopf mit Zähnen, Auswurfschacht hinten,
-- Bedienpult und Statuslampe. Größe wächst mit der Stufe (docs/10 §28).
--
-- Ausrichtung: cf = Mitte der Bodenfläche, LookVector (-Z) zeigt zur Erzwand.
-- Vereinbarte Namen (für Animation/Status in Phase 5b):
--   Model "Bit"          – Bohrkopf, dreht sich um die Längsachse (Pivot = Achse)
--   Part  "StatusLight"  – Neon-Lampe (Grün/Orange/Rot)
--   Part  "Body"         – Motorgehäuse (vibriert leicht)
--   Attachment "DustPoint" am Bohrkopf – Ursprung für Staub/Steinpartikel
-- Keine Scripts im Modell (docs/10 §69).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Drills = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Drills)

local DrillModelBuilder = {}

local STEEL = Color3.fromRGB(64, 68, 74)
local STEEL_DARK = Color3.fromRGB(40, 42, 46)
local STEEL_LIGHT = Color3.fromRGB(150, 154, 160)
local HAZARD_YELLOW = Color3.fromRGB(240, 196, 40)
local HAZARD_BLACK = Color3.fromRGB(28, 28, 28)
local CHROME = Color3.fromRGB(196, 200, 206)
local CARBIDE = Color3.fromRGB(90, 92, 98)
local RUBBER = Color3.fromRGB(30, 30, 32)
local STATUS_IDLE = Color3.fromRGB(255, 170, 40)

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
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
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

-- Zylinder entlang der lokalen Z-Achse (Roblox-Zylinder liegen entlang X)
local function cylinderZ(parent: Instance, name: string, length: number, diameter: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	return part(parent, name, Vector3.new(length, diameter, diameter), cframe * CFrame.Angles(0, math.rad(90), 0), color, material, Enum.PartType.Cylinder)
end

-- Zylinder zwischen zwei Punkten (für Hydraulik und Rohre)
local function cylinderBetween(parent: Instance, name: string, a: Vector3, b: Vector3, diameter: number, color: Color3, material: Enum.Material?): Part
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	return part(parent, name, Vector3.new(length, diameter, diameter), cf, color, material, Enum.PartType.Cylinder)
end

-- Gelb-schwarze Warnstreifen auf einer Fläche
local function hazard(parent: Instance, name: string, width: number, height: number, cf: CFrame, stripes: number)
	local w = width / stripes
	for i = 1, stripes do
		local x = -width / 2 + w * (i - 0.5)
		part(parent, `{name}{i}`, Vector3.new(w, height, 0.06), cf * CFrame.new(x, 0, 0), if i % 2 == 0 then HAZARD_BLACK else HAZARD_YELLOW, Enum.Material.SmoothPlastic)
	end
end

function DrillModelBuilder.build(def: Drills.DrillDefinition, cf: CFrame): Model
	local s = 1 + (def.Tier - 1) * 0.25
	local body = def.BodyColor
	local bodyDark = body:Lerp(Color3.new(0, 0, 0), 0.35)

	local model = Instance.new("Model")
	model.Name = def.Id
	model:SetAttribute("DrillType", def.Id)

	-- Hilfsfunktion für skalierte lokale Positionen
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x * s, y * s, z * s)
	end
	local function v(x: number, y: number, z: number): Vector3
		return Vector3.new(x * s, y * s, z * s)
	end

	-- Kufenrahmen mit Querträgern und Warnstreifen an den Enden
	for _, x in { -2, 2 } do
		part(model, `Skid{x}`, v(0.7, 0.6, 9.4), at(x, 0.3, 0.6), STEEL_DARK)
		part(model, `SkidFlange{x}`, v(0.9, 0.12, 9.4), at(x, 0.66, 0.6), STEEL)
		for _, z in { -4.1, 5.3 } do
			part(model, `SkidCap{x}_{z}`, v(0.72, 0.62, 0.2), at(x, 0.3, z), HAZARD_YELLOW, Enum.Material.SmoothPlastic)
		end
	end
	for i, z in { -3.4, -0.6, 2.2, 4.8 } do
		part(model, `CrossBeam{i}`, v(4, 0.4, 0.5), at(0, 0.45, z), STEEL)
	end
	local deck = part(model, "Deck", v(4.8, 0.25, 9), at(0, 0.85, 0.6), STEEL, Enum.Material.DiamondPlate)
	model.PrimaryPart = deck
	hazard(model, "DeckStripe", 4.8 * s, 0.25 * s, at(0, 0.85, -3.9) * CFrame.Angles(0, math.rad(180), 0), 8)

	-- Motorgehäuse hinten (Body), Gitter, Auspuff, Tank
	local bodyPart = part(model, "Body", v(4.2, 3, 4.2), at(0, 2.5, 2.4), body, Enum.Material.Metal)
	bodyPart.Name = "Body"
	part(model, "BodyRoof", v(4.4, 0.25, 4.4), at(0, 4.1, 2.4), bodyDark)
	-- Rechte Seite: Lüftungsgitter in der unteren Hälfte, oben Platz für das Typenschild
	for i = 1, 4 do
		part(model, `Louver{i}`, v(0.06, 0.18, 3), at(2.13, 1.3 + i * 0.32, 2.4), STEEL_DARK)
	end
	-- Typenschild auf beiden Seiten oben am Gehäuse (frei von Gittern und Anbauten)
	for _, side in { -1, 1 } do
		local plate = part(model, `NamePlate{side}`, v(0.06, 0.75, 3.4), at(side * 2.14, 3.4, 2.4), STEEL_DARK, Enum.Material.SmoothPlastic)
		local gui = Instance.new("SurfaceGui")
		gui.Face = if side > 0 then Enum.NormalId.Right else Enum.NormalId.Left
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0.3
		gui.Parent = plate
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(245, 245, 240)
		text.Text = def.DisplayName:upper()
		text.Parent = gui
	end
	part(model, "Grill", v(3.2, 0.1, 3.2), at(0, 4.25, 2.4), STEEL_DARK, Enum.Material.DiamondPlate)
	local exhaustBase = at(1.5, 4.2, 3.9).Position
	cylinderBetween(model, "Exhaust", exhaustBase, exhaustBase + v(0, 2.2, 0), 0.45 * s, STEEL_DARK)
	part(model, "ExhaustCap", v(0.6, 0.12, 0.6), at(1.5, 6.45, 3.9), STEEL_DARK)
	-- Satteltank außen an der linken Seite, unterhalb des Typenschilds, mit zwei Halteschellen
	cylinderZ(model, "FuelTank", 2.6 * s, 0.9 * s, at(-2.62, 1.55, 2.4), STEEL_LIGHT)
	for i, z in { 1.5, 3.3 } do
		part(model, `TankStrap{i}`, v(0.55, 0.12, 0.15), at(-2.4, 1.98, z), STEEL_DARK)
	end
	part(model, "Plate", v(1.6, 0.6, 0.06), at(0, 3.2, 4.53), CHROME, Enum.Material.SmoothPlastic)

	-- Ausleger nach vorn mit Hydraulik
	part(model, "BoomMount", v(2.2, 1.6, 1.4), at(0, 1.8, 0.1), bodyDark)
	part(model, "Boom", v(1.5, 1.5, 4.8), at(0, 2.6, -2.2), body, Enum.Material.Metal)
	part(model, "BoomTop", v(1.6, 0.2, 4.8), at(0, 3.4, -2.2), bodyDark)
	for _, x in { -1, 1 } do
		local base = at(x * 1.0, 1.0, -0.4).Position
		local top = at(x * 0.9, 2.3, -3.6).Position
		local mid = base:Lerp(top, 0.55)
		cylinderBetween(model, `HydraulicBarrel{x}`, base, mid, 0.42 * s, HAZARD_YELLOW, Enum.Material.SmoothPlastic)
		cylinderBetween(model, `HydraulicRod{x}`, mid, top, 0.22 * s, CHROME, Enum.Material.SmoothPlastic)
	end
	-- Hydraulikschläuche zum Motor
	cylinderBetween(model, "Hose1", at(0.5, 3.3, -0.2).Position, at(0.9, 3.6, 0.4).Position, 0.14 * s, RUBBER, Enum.Material.Rubber)
	cylinderBetween(model, "Hose2", at(-0.5, 3.3, -0.2).Position, at(-0.9, 3.6, 0.4).Position, 0.14 * s, RUBBER, Enum.Material.Rubber)

	-- Getriebe vorn am Ausleger
	cylinderZ(model, "Gearbox", 1.2 * s, 2.2 * s, at(0, 2.6, -5.2), STEEL_DARK)
	cylinderZ(model, "GearboxRing", 0.3 * s, 2.4 * s, at(0, 2.6, -4.65), HAZARD_YELLOW, Enum.Material.SmoothPlastic)

	-- Bohrkopf (dreht sich in 5b um seine Achse)
	local bit = Instance.new("Model")
	bit.Name = "Bit"
	bit.Parent = model
	local axis = at(0, 2.6, -6.4)
	local core = cylinderZ(bit, "BitCore", 1.6 * s, 1.7 * s, axis, CARBIDE)
	cylinderZ(bit, "BitTaper1", 0.8 * s, 1.2 * s, at(0, 2.6, -7.6), CARBIDE)
	cylinderZ(bit, "BitTaper2", 0.6 * s, 0.7 * s, at(0, 2.6, -8.3), CARBIDE)
	part(bit, "BitTip", v(0.4, 0.4, 0.5), at(0, 2.6, -8.75) * CFrame.Angles(0, 0, math.rad(45)), CHROME, Enum.Material.SmoothPlastic)
	-- Zähne in drei versetzten Ringen (wirkt wie eine Spirale)
	local rings = { { z = -5.9, r = 0.95, n = 6, off = 0 }, { z = -6.7, r = 0.95, n = 6, off = 20 }, { z = -7.5, r = 0.7, n = 5, off = 40 } }
	for ri, ring in rings do
		for i = 1, ring.n do
			local angle = math.rad(ring.off + (i - 1) * 360 / ring.n)
			local tooth = at(0, 2.6, ring.z) * CFrame.Angles(0, 0, angle) * CFrame.new(0, ring.r * s, 0) * CFrame.Angles(math.rad(-25), 0, 0)
			part(bit, `Tooth{ri}_{i}`, v(0.32, 0.5, 0.32), tooth, CHROME, Enum.Material.SmoothPlastic)
		end
	end
	-- Drehachse = Bohrachse (lokale Z-Achse von axis). Bewusst KEIN PrimaryPart: dessen Achsen
	-- sind wegen der Zylinder-Drehung vertauscht, der Client dreht um GetPivot() (= WorldPivot).
	bit.WorldPivot = axis

	-- Staub und kleine Steinpartikel an der Bohrspitze (nur im Betrieb, docs/05 §28).
	-- Hängt am feststehenden Getriebe, damit die Partikel nicht mitdrehen.
	local gearbox = model:FindFirstChild("Gearbox") :: BasePart
	local dust = Instance.new("Attachment")
	dust.Name = "DustPoint"
	dust.Parent = gearbox
	dust.WorldPosition = at(0, 2.6, -8.9).Position
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Dust"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(150, 140, 125))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8 * s), NumberSequenceKeypoint.new(1, 3 * s) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(1.2, 2)
	smoke.Rate = 10
	smoke.Speed = NumberRange.new(1.5, 3)
	smoke.SpreadAngle = Vector2.new(60, 60)
	smoke.Acceleration = Vector3.new(0, 0.6, 0)
	smoke.LightInfluence = 0.6
	smoke.Enabled = false
	smoke.Parent = dust
	local chips = Instance.new("ParticleEmitter")
	chips.Name = "Chips"
	chips.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	chips.Color = ColorSequence.new(Color3.fromRGB(90, 80, 70))
	chips.Size = NumberSequence.new(0.18 * s)
	chips.Lifetime = NumberRange.new(0.5, 0.9)
	chips.Rate = 18
	chips.Speed = NumberRange.new(5, 9)
	chips.SpreadAngle = Vector2.new(70, 70)
	chips.Acceleration = Vector3.new(0, -30, 0)
	chips.LightInfluence = 1
	chips.Enabled = false
	chips.Parent = dust

	-- Auswurfschacht hinten (Output-Bereich, docs/10 §29)
	part(model, "ChuteBack", v(2.4, 2, 0.2), at(0, 1.6, 5.15), STEEL)
	part(model, "ChuteFloor", v(2.4, 0.2, 1.6), at(0, 0.9, 5.9) * CFrame.Angles(math.rad(-20), 0, 0), STEEL)
	for _, x in { -1.2, 1.2 } do
		part(model, `ChuteSide{x}`, v(0.2, 1, 1.6), at(x, 1.3, 5.9), STEEL)
	end

	-- Bedienpult an der Seite mit Statuslampe
	part(model, "PanelPost", v(0.25, 1.6, 0.25), at(2.6, 1.7, 0.4), STEEL_DARK)
	part(model, "Panel", v(0.2, 1, 1.4), at(2.65, 2.8, 0.4), STEEL_LIGHT, Enum.Material.SmoothPlastic)
	part(model, "PanelButtonGreen", v(0.1, 0.25, 0.25), at(2.78, 2.95, 0.15), Color3.fromRGB(60, 200, 90), Enum.Material.Neon)
	part(model, "PanelButtonRed", v(0.1, 0.25, 0.25), at(2.78, 2.95, 0.65), Color3.fromRGB(220, 60, 50), Enum.Material.Neon)
	part(model, "LampPost", v(0.2, 0.9, 0.2), at(-1.6, 4.65, 1.2), STEEL_DARK)
	local lamp = part(model, "StatusLight", v(0.6, 0.6, 0.6), at(-1.6, 5.35, 1.2), STATUS_IDLE, Enum.Material.Neon, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Name = "Glow"
	light.Range = 8
	light.Brightness = 1.5
	light.Color = STATUS_IDLE
	light.Parent = lamp


	return model
end

-- Abstand Bohrspitze ↔ Modell-Ursprung und Auswurf ↔ Ursprung (lokal, in Studs)
local TIP_Z = 8.9
local OUTPUT_Z = 6.9
-- Seitlicher Versatz in der Abbauzone: links bleibt Platz für den Spieler (D-005)
local SLOT_SIDE_OFFSET = 3

-- Position eines Drills in einer Abbauzone (MineShaftBuilder "MiningSlotN"):
-- zone.LookVector zeigt in den Raum, die Erzwand liegt bei lokal +Z = zone.Size.Z / 2.
-- Ergebnis: Bodenmitte des Drills, LookVector zur Wand, Bohrspitze knapp vor der Wand.
function DrillModelBuilder.slotCFrame(zone: BasePart, floorY: number, def: Drills.DrillDefinition): CFrame
	local s = 1 + (def.Tier - 1) * 0.25
	local wallZ = zone.Size.Z / 2
	local spot = zone.CFrame * CFrame.new(SLOT_SIDE_OFFSET, 0, wallZ - TIP_Z * s - 0.6)
	local pos = Vector3.new(spot.Position.X, floorY, spot.Position.Z)
	return CFrame.lookAt(pos, pos - zone.CFrame.LookVector)
end

-- Abholpunkt hinter dem Auswurfschacht (für Transport-Worker), Bodenhöhe
function DrillModelBuilder.outputPoint(drillCF: CFrame, def: Drills.DrillDefinition): Vector3
	local s = 1 + (def.Tier - 1) * 0.25
	return (drillCF * CFrame.new(0, 0, OUTPUT_Z * s + 1.5)).Position
end

-- Statusanzeige (docs/05 §29): Grün = arbeitet, Orange = wartet, Rot = blockiert.
-- Partikel nur im Betrieb. Die Bohrkopf-Drehung macht der Client (Attribut "Status").
local STATUS_COLORS: { [string]: Color3 } = {
	Running = Color3.fromRGB(70, 210, 90),
	OutputFull = Color3.fromRGB(255, 160, 30),
	Idle = Color3.fromRGB(255, 160, 30),
	Blocked = Color3.fromRGB(225, 55, 45),
}

function DrillModelBuilder.setStatus(model: Model, status: string)
	if model:GetAttribute("Status") == status then
		return
	end
	model:SetAttribute("Status", status)
	local color = STATUS_COLORS[status] or STATUS_IDLE
	local lamp = model:FindFirstChild("StatusLight")
	if lamp and lamp:IsA("BasePart") then
		lamp.Color = color
		local glow = lamp:FindFirstChild("Glow")
		if glow and glow:IsA("PointLight") then
			glow.Color = color
		end
	end
	local running = status == "Running"
	for _, d in model:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.Enabled = running
		end
	end
end

return table.freeze(DrillModelBuilder)
