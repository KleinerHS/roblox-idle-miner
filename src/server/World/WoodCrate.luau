--!strict
-- Holz-Palettenkiste wie im Foto von Felix (2026-10-13): Europalette mit Klötzen, darauf eine
-- Kiste aus je 4 hellen Fichtenbrettern pro Seite mit schmalen Fugen und dunklen Eckpfosten.
-- Der Name des Inhalts steht wie aufgedruckt vorne auf dem Holz. Das Erz liegt als Füllung in
-- der Kiste (Farbe und Füllhöhe).
--
-- build(parent, cf): cf = Mitte der Unterseite, Vorderseite = -Z. Gibt das Model "Crate" zurück.
-- setContent(crate, name, color, fraction): Aufschrift und Füllung (name = "" → leer)

local WoodCrate = {}

WoodCrate.Size = 7.4 -- Grundfläche
local PALLET_H = 0.9
local PLANK_H = 1.2
local GAP = 0.13
local PLANKS = 4
local WALL_T = 0.22
local BOX_H = PLANKS * PLANK_H + (PLANKS - 1) * GAP
WoodCrate.Height = PALLET_H + BOX_H

local PINE = {
	Color3.fromRGB(226, 202, 160),
	Color3.fromRGB(216, 190, 146),
	Color3.fromRGB(232, 210, 172),
	Color3.fromRGB(210, 184, 140),
}
local POST = Color3.fromRGB(150, 122, 84)
local PALLET = Color3.fromRGB(190, 160, 116)
local PALLET_BLOCK = Color3.fromRGB(160, 132, 92)
local INK = Color3.fromRGB(52, 38, 26)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Wood
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function WoodCrate.build(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Crate"
	local s = WoodCrate.Size
	local h = s / 2

	-- Palette: zwei Bodenbretter, drei Klotzreihen, Deckbretter
	for i, z in { -h + 0.5, h - 0.5 } do
		part(m, `PalletBottom{i}`, Vector3.new(s, 0.16, 1), cf * CFrame.new(0, 0.08, z), PALLET)
	end
	for i, x in { -h + 0.5, 0, h - 0.5 } do
		for j, z in { -h + 0.5, 0, h - 0.5 } do
			part(m, `PalletBlock{i}_{j}`, Vector3.new(1, 0.5, 1), cf * CFrame.new(x, 0.41, z), PALLET_BLOCK)
		end
	end
	for i = 1, 5 do
		local z = -h + 0.6 + (i - 1) * (s - 1.2) / 4
		part(m, `PalletDeck{i}`, Vector3.new(s, 0.24, 1.1), cf * CFrame.new(0, PALLET_H - 0.12, z), PALLET)
	end

	-- Kiste: 4 Bretter je Seite mit Fugen, Eckpfosten innen
	local y0 = PALLET_H
	for k = 1, PLANKS do
		local y = y0 + (k - 1) * (PLANK_H + GAP) + PLANK_H / 2
		local tone = PINE[(k - 1) % #PINE + 1]
		part(m, `PlankFront{k}`, Vector3.new(s, PLANK_H, WALL_T), cf * CFrame.new(0, y, -h + WALL_T / 2), tone)
		part(m, `PlankBack{k}`, Vector3.new(s, PLANK_H, WALL_T), cf * CFrame.new(0, y, h - WALL_T / 2), PINE[k % #PINE + 1])
		part(m, `PlankLeft{k}`, Vector3.new(WALL_T, PLANK_H, s - WALL_T * 2), cf * CFrame.new(h - WALL_T / 2, y, 0), PINE[(k + 1) % #PINE + 1])
		part(m, `PlankRight{k}`, Vector3.new(WALL_T, PLANK_H, s - WALL_T * 2), cf * CFrame.new(-h + WALL_T / 2, y, 0), tone)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(m, `Post{sx}_{sz}`, Vector3.new(0.45, BOX_H, 0.45), cf * CFrame.new(sx * (h - WALL_T - 0.22), y0 + BOX_H / 2, sz * (h - WALL_T - 0.22)), POST)
		end
	end
	part(m, "Floor", Vector3.new(s - WALL_T * 2, 0.12, s - WALL_T * 2), cf * CFrame.new(0, y0 + 0.06, 0), PALLET)

	-- Füllung (Erz/Barren)
	local fill = part(m, "Fill", Vector3.new(s - WALL_T * 2 - 0.9, 0.2, s - WALL_T * 2 - 0.9), cf * CFrame.new(0, y0 + 0.2, 0), Color3.new(0.2, 0.2, 0.2), Enum.Material.Slate)
	fill.CanCollide = false
	fill.Transparency = 1

	-- Aufschrift vorne auf den mittleren Brettern (wie gestempelt)
	local plate = part(m, "LabelPlate", Vector3.new(s - 0.8, PLANK_H * 2 + GAP, 0.05), cf * CFrame.new(0, y0 + PLANK_H + GAP + PLANK_H / 2 + 0.05, -h - 0.03), INK, Enum.Material.SmoothPlastic)
	plate.Transparency = 1
	plate.CanCollide = false
	plate.CanQuery = false
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 1
	gui.MaxDistance = 140
	gui.Parent = plate
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = INK
	text.TextTransparency = 0.12
	text.Text = ""
	text.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.06, 0)
	pad.PaddingRight = UDim.new(0.06, 0)
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = text

	m.PrimaryPart = m:FindFirstChild("PalletDeck3") :: BasePart
	m.Parent = parent
	return m
end

-- Aufschrift und Füllung setzen; fraction 0..1
function WoodCrate.setContent(crate: Model, name: string, color: Color3?, fraction: number)
	local plate = crate:FindFirstChild("LabelPlate")
	local label = plate and plate:FindFirstChild("Label")
	local text = label and label:FindFirstChild("Text")
	if text and text:IsA("TextLabel") then
		text.Text = string.upper(name)
	end
	local fill = crate:FindFirstChild("Fill")
	local floor = crate:FindFirstChild("Floor")
	if fill and fill:IsA("BasePart") and floor and floor:IsA("BasePart") then
		if color and fraction > 0 then
			local hgt = math.max(0.2, (BOX_H - 0.4) * math.clamp(fraction, 0, 1))
			fill.Size = Vector3.new(fill.Size.X, hgt, fill.Size.Z)
			fill.CFrame = floor.CFrame * CFrame.new(0, 0.06 + hgt / 2, 0)
			fill.Color = color
			fill.Transparency = 0
		else
			fill.Transparency = 1
		end
	end
end

return table.freeze(WoodCrate)
