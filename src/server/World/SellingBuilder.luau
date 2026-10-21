--!strict
-- Verkaufskreis in der Platzmitte (D-056, Felix 2026-10-21): statt Verkaufsgebäude ein großer
-- grüner Kreis in der Insel des Kreisverkehrs. Wer hindurchfährt (oder zu Fuß hineinläuft),
-- verkauft automatisch – ohne Fenster (SellingService).
--
-- Vereinbarte Namen:
--   Model "SellCircle" mit Part "Zone" (Mitte/Radius des Verkaufsbereichs, Attribut Radius)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LayoutConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.LayoutConfig)

local SellingBuilder = {}

local GREEN = Color3.fromRGB(70, 210, 100)
local GREEN_GLOW = Color3.fromRGB(90, 255, 120)

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function SellingBuilder.build(parent: Instance): Model
	local cfg = LayoutConfig.SellCircle
	local c = LayoutConfig.MapCenter
	local topY = LayoutConfig.GroundY + 1 + 0.12
	local R = cfg.Radius

	local model = Instance.new("Model")
	model.Name = "SellCircle"

	-- Fläche: flache Scheibe, leicht durchscheinend
	local zone = part(model, "Zone", Vector3.new(0.1, R * 2, R * 2), CFrame.new(c.X, topY - 0.05, c.Z) * CFrame.Angles(0, 0, math.rad(90)), GREEN, Enum.Material.SmoothPlastic)
	zone.Shape = Enum.PartType.Cylinder
	zone.Transparency = 0.35
	zone:SetAttribute("Radius", R)
	model.PrimaryPart = zone

	-- Leuchtender Rand aus Segmenten
	local segments = 72
	local width = 1.6
	local mid = R - width / 2
	local segLen = 2 * math.pi * mid / segments + 0.3
	for i = 1, segments do
		local a = (i - 0.5) / segments * math.pi * 2
		part(model, `Rim{i}`, Vector3.new(width, 0.12, segLen), CFrame.new(c.X + math.cos(a) * mid, topY + 0.02, c.Z + math.sin(a) * mid) * CFrame.Angles(0, -a, 0), GREEN_GLOW, Enum.Material.Neon)
	end

	-- Schriftzug auf dem Boden (von allen Zufahrten lesbar genug) und Schild darüber
	local label = part(model, "Label", Vector3.new(R * 1.2, 0.05, R * 0.45), CFrame.new(c.X, topY + 0.03, c.Z), GREEN, Enum.Material.SmoothPlastic)
	label.Transparency = 1
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = label
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextTransparency = 0.1
	text.Text = "SELL"
	text.Parent = gui

	-- „SELL“ groß in der Luft über dem Kreis, runde, freundliche Schrift (Felix 2026-10-21)
	local anchor = part(model, "SignAnchor", Vector3.new(1, 1, 1), CFrame.new(c.X, topY + 24, c.Z), GREEN, Enum.Material.SmoothPlastic)
	anchor.Transparency = 1
	local sign = Instance.new("BillboardGui")
	sign.Name = "SellSign"
	sign.Size = UDim2.fromScale(40, 15) -- in Studs: wächst mit der Welt, wirkt wie ein Schriftzug
	sign.MaxDistance = 900
	sign.LightInfluence = 0
	sign.Parent = anchor
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular)
	signText.TextScaled = true
	signText.TextColor3 = Color3.fromRGB(255, 255, 255)
	signText.Text = "SELL"
	signText.Parent = sign
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(190, 255, 170), Color3.fromRGB(70, 220, 110))
	gradient.Rotation = 90
	gradient.Parent = signText
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(20, 90, 45)
	stroke.Thickness = 4
	stroke.Parent = signText

	model.Parent = parent
	return model
end

return table.freeze(SellingBuilder)
