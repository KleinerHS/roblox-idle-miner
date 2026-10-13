--!strict
-- Schwebende Info-Schrift statt Schildern (Felix 2026-10-13): freundliche, runde Schrift ohne
-- Tafel, mit weicher Kontur, frei im Raum über dem Objekt. Ein unsichtbarer Anker-Part trägt eine
-- BillboardGui "Display" mit TextLabels (Namen wie bei den alten Anzeigen, damit die
-- Aktualisierung unverändert funktioniert).

local FloatingText = {}

export type Line = { Name: string, Text: string, Size: number, Color: Color3? }

local FONT = Enum.Font.FredokaOne
local STROKE = Color3.fromRGB(30, 34, 42)

-- Anker an `cf` (Mitte der Schrift), Breite in Studs; Zeilen von oben nach unten, Size = Höhe in Studs
function FloatingText.create(parent: Instance, name: string, cf: CFrame, width: number, lines: { Line }, maxDistance: number?): Part
	local anchor = Instance.new("Part")
	anchor.Name = name
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = cf
	anchor.Parent = parent

	local total = 0
	for _, line in lines do
		total += line.Size
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Display"
	gui.Size = UDim2.fromScale(width, total)
	gui.LightInfluence = 0
	gui.MaxDistance = maxDistance or 120
	gui.ResetOnSpawn = false
	gui.Parent = anchor
	local y = 0
	for _, line in lines do
		local label = Instance.new("TextLabel")
		label.Name = line.Name
		label.Position = UDim2.fromScale(0, y / total)
		label.Size = UDim2.fromScale(1, line.Size / total)
		label.BackgroundTransparency = 1
		label.Font = FONT
		label.TextScaled = true
		label.TextColor3 = line.Color or Color3.fromRGB(250, 250, 248)
		label.TextStrokeColor3 = STROKE
		label.TextStrokeTransparency = 0.55
		label.Text = line.Text
		label.Parent = gui
		y += line.Size
	end
	return anchor
end

-- Kurzer, einzeiliger Titel (z. B. „Ore Input“)
function FloatingText.title(parent: Instance, name: string, cf: CFrame, text: string, height: number?, color: Color3?): Part
	local h = height or 2.2
	return FloatingText.create(parent, name, cf, math.max(6, #text * h * 0.55), { { Name = "Title", Text = text, Size = h, Color = color } })
end

return table.freeze(FloatingText)
