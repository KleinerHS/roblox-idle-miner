--!strict
-- Gemeinsame Bausteine, damit die Shops in der Mitte einladender wirken (D-060, Felix 2026-10-22:
-- „der Pickaxe- und Drill-Shop muss auch größer und einladender wirken“): gestreifte Markise,
-- großes beleuchtetes Dachschild, Fahnenmasten, Pflanzkübel, Schaufenster-Podest mit Spot.
-- Alle Funktionen arbeiten im lokalen Rahmen `cf` (LookVector = Blickrichtung nach vorne).

local ShopDecor = {}

local STEEL = Color3.fromRGB(58, 62, 68)
local LIGHT = Color3.fromRGB(255, 236, 196)
local GREEN = Color3.fromRGB(70, 140, 80)
local GREEN_DARK = Color3.fromRGB(52, 112, 62)
local POT = Color3.fromRGB(70, 72, 78)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

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
ShopDecor.part = part

function ShopDecor.text(target: BasePart, text: string, color: Color3, face: Enum.NormalId?, stroke: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
	if stroke then
		local s = Instance.new("UIStroke")
		s.Color = stroke
		s.Thickness = 3
		s.Parent = label
	end
end

-- Gestreifte Markise über der Front: cf = Mitte der Oberkante an der Wand, ragt nach vorne (-Z)
function ShopDecor.awning(parent: Instance, name: string, cf: CFrame, width: number, depth: number, a: Color3, b: Color3)
	local stripes = math.max(2, math.floor(width / 2.4))
	local w = width / stripes
	local tilt = CFrame.Angles(math.rad(-22), 0, 0)
	for i = 1, stripes do
		local x = -width / 2 + (i - 0.5) * w
		part(parent, `{name}Stripe{i}`, Vector3.new(w + 0.02, 0.25, depth), cf * CFrame.new(x, 0, 0) * tilt * CFrame.new(0, 0, -depth / 2), if i % 2 == 0 then a else b, Enum.Material.Fabric).CastShadow = true
	end
	-- Volant (gezackt wirkende Kante)
	local edge = cf * tilt * CFrame.new(0, 0, -depth)
	for i = 1, stripes do
		local x = -width / 2 + (i - 0.5) * w
		part(parent, `{name}Valance{i}`, Vector3.new(w + 0.02, 0.9, 0.15), edge * CFrame.new(x, -0.45, 0) * CFrame.Angles(math.rad(22), 0, 0), if i % 2 == 0 then a else b, Enum.Material.Fabric)
	end
end

-- Großes Dachschild mit Lichterkante: cf = Mitte des Schildes, Vorderseite zeigt nach -Z
function ShopDecor.roofSign(parent: Instance, name: string, cf: CFrame, width: number, height: number, text: string, bg: Color3, fg: Color3, frame: Color3)
	local board = part(parent, name, Vector3.new(width, height, 0.6), cf, bg, Enum.Material.SmoothPlastic)
	ShopDecor.text(board, text, fg, Enum.NormalId.Front, frame)
	part(parent, `{name}Frame`, Vector3.new(width + 1, height + 1, 0.4), cf * CFrame.new(0, 0, 0.3), frame, Enum.Material.Metal)
	-- Glühbirnen rundherum
	local n = math.floor(width / 2.2)
	for i = 0, n do
		local x = -width / 2 + i * (width / n)
		for _, y in { -height / 2 - 0.25, height / 2 + 0.25 } do
			local bulb = part(parent, `{name}Bulb{i}_{y}`, Vector3.new(0.5, 0.5, 0.5), cf * CFrame.new(x, y, -0.4), LIGHT, Enum.Material.Neon)
			bulb.Shape = Enum.PartType.Ball
			bulb.CastShadow = false
			bulb.CanCollide = false
		end
	end
	-- Stützen auf das Dach
	for _, x in { -width / 3, width / 3 } do
		part(parent, `{name}Leg{x}`, Vector3.new(0.5, height, 0.5), cf * CFrame.new(x, -height, 0.8), STEEL, Enum.Material.Metal)
	end
	local glow = Instance.new("SurfaceLight")
	glow.Face = Enum.NormalId.Front
	glow.Range = 16
	glow.Brightness = 1.2
	glow.Color = LIGHT
	glow.Parent = board
	return board
end

-- Fahnenmast mit Wimpel: cf = Fußpunkt
function ShopDecor.flag(parent: Instance, name: string, cf: CFrame, color: Color3, height: number?)
	local h = height or 14
	part(parent, `{name}Base`, Vector3.new(1.4, 0.6, 1.4), cf * CFrame.new(0, 0.3, 0), STEEL, Enum.Material.Concrete)
	part(parent, `{name}Pole`, Vector3.new(0.35, h, 0.35), cf * CFrame.new(0, h / 2, 0), Color3.fromRGB(220, 222, 226), Enum.Material.Metal)
	part(parent, `{name}Banner`, Vector3.new(0.12, 5, 2.6), cf * CFrame.new(0, h - 3.2, -1.45), color, Enum.Material.Fabric)
	local tip = part(parent, `{name}Tip`, Vector3.new(0.6, 0.6, 0.6), cf * CFrame.new(0, h + 0.3, 0), Color3.fromRGB(230, 190, 60), Enum.Material.Metal)
	tip.Shape = Enum.PartType.Ball
end

-- Pflanzkübel mit Busch
function ShopDecor.planter(parent: Instance, name: string, cf: CFrame, size: number?)
	local s = size or 3
	part(parent, `{name}Pot`, Vector3.new(s, s * 0.7, s), cf * CFrame.new(0, s * 0.35, 0), POT, Enum.Material.Concrete)
	local bush = part(parent, `{name}Bush`, Vector3.new(s * 1.3, s * 1.2, s * 1.3), cf * CFrame.new(0, s * 0.7 + s * 0.45, 0), GREEN, Enum.Material.Grass)
	bush.Shape = Enum.PartType.Ball
	local top = part(parent, `{name}Top`, Vector3.new(s * 0.8, s * 0.8, s * 0.8), cf * CFrame.new(0, s * 0.7 + s * 1.05, 0), GREEN_DARK, Enum.Material.Grass)
	top.Shape = Enum.PartType.Ball
end

-- Rundes Podest mit Leuchtrand und Spot von oben: cf = Fußpunkt, gibt die Oberkante zurück
function ShopDecor.podium(parent: Instance, name: string, cf: CFrame, radius: number, ring: Color3, spotHeight: number): CFrame
	local base = part(parent, `{name}Base`, Vector3.new(1.2, radius * 2, radius * 2), cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
	base.Shape = Enum.PartType.Cylinder
	local glow = part(parent, `{name}Ring`, Vector3.new(0.2, radius * 2 + 0.3, radius * 2 + 0.3), cf * CFrame.new(0, 1.15, 0) * CFrame.Angles(0, 0, math.rad(90)), ring, Enum.Material.Neon)
	glow.Shape = Enum.PartType.Cylinder
	glow.CanCollide = false
	local spot = part(parent, `{name}Spot`, Vector3.new(1.4, 0.3, 1.4), cf * CFrame.new(0, spotHeight, 0), LIGHT, Enum.Material.Neon)
	spot.CanCollide = false
	spot.CastShadow = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Range = spotHeight + 4
	light.Angle = 45
	light.Brightness = 2
	light.Color = LIGHT
	light.Parent = spot
	return cf * CFrame.new(0, 1.2, 0)
end

return table.freeze(ShopDecor)
