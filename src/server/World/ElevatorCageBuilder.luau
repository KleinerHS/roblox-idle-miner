--!strict
-- Gemeinsamer Bergbau-Förderkorb für Oberfläche und Mine Shaft (docs/04 §16, docs/19 §7):
-- Stahlrahmen aus I-Trägern, Gitterstäbe, Schiebegitter-Tor vorne, Dach mit Förderturm
-- und Seilrad, Bedienpult mit Leuchttastern, Warnleuchte, Innenlampe.
-- PLATZHALTER aus Parts, aber im finalen Stil; später durch Mesh-Modell ersetzbar.
--
-- Vereinbarte Namen (werden von ElevatorService genutzt):
--   Folder "Gate" mit Folder "LeafLeft"/"LeafRight" (Tor, über setGate bewegt)
--   Part   "ArrivalPoint"       Ankunft im Korb, Blick nach vorne (-Z)
--   Part   "ElevatorPromptPart" mit ProximityPrompt "ElevatorPrompt"
--   Part   "Beacon"             Warnleuchte (leuchtet während der Fahrt)

local TweenService = game:GetService("TweenService")

local ElevatorCageBuilder = {}

-- Innenmaß des Korbs und Höhe (lokal, Boden-Oberkante = y 0, vorne = -Z)
ElevatorCageBuilder.Size = 16
ElevatorCageBuilder.Height = 14

local STEEL = Color3.fromRGB(58, 62, 68)
local STEEL_LIGHT = Color3.fromRGB(96, 102, 110)
local STEEL_DARK = Color3.fromRGB(34, 36, 40)
local YELLOW = Color3.fromRGB(236, 182, 40)
local BLACK = Color3.fromRGB(28, 28, 30)
local CABLE = Color3.fromRGB(24, 24, 24)

local GATE_OPEN_SECONDS = 0.6

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.Parent = parent
	return p
end

local function cylinder(parent: Instance, name: string, length: number, diameter: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	-- Roblox-Zylinder liegen entlang der lokalen X-Achse
	local p = part(parent, name, Vector3.new(length, diameter, diameter), cframe, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Senkrechter I-Träger (zwei Gurte + Steg)
local function columnI(parent: Instance, name: string, height: number, cframe: CFrame)
	part(parent, name .. "_FlangeA", Vector3.new(1.1, height, 0.18), cframe * CFrame.new(0, 0, -0.45), STEEL)
	part(parent, name .. "_FlangeB", Vector3.new(1.1, height, 0.18), cframe * CFrame.new(0, 0, 0.45), STEEL)
	part(parent, name .. "_Web", Vector3.new(0.18, height, 0.8), cframe, STEEL_DARK)
end

-- Waagerechter I-Träger entlang der lokalen X-Achse von cframe
local function beamI(parent: Instance, name: string, length: number, cframe: CFrame)
	part(parent, name .. "_Top", Vector3.new(length, 0.18, 0.9), cframe * CFrame.new(0, 0.45, 0), STEEL)
	part(parent, name .. "_Bottom", Vector3.new(length, 0.18, 0.9), cframe * CFrame.new(0, -0.45, 0), STEEL)
	part(parent, name .. "_Web", Vector3.new(length, 0.8, 0.18), cframe, STEEL_DARK)
end

-- Gerade Strebe zwischen zwei Punkten (lokal zu base)
local function strut(parent: Instance, name: string, base: CFrame, from: Vector3, to: Vector3)
	local len = (to - from).Magnitude
	part(parent, name, Vector3.new(0.3, 0.3, len), base * CFrame.lookAt((from + to) / 2, to), STEEL_DARK)
end

-- Warnstreifen gelb/schwarz als Segmente entlang X
local function hazardStrip(parent: Instance, name: string, length: number, size: Vector2, cframe: CFrame)
	local count = math.max(2, math.floor(length / 1.2))
	local seg = length / count
	for i = 1, count do
		local x = -length / 2 + seg * (i - 0.5)
		part(parent, `{name}{i}`, Vector3.new(seg, size.X, size.Y), cframe * CFrame.new(x, 0, 0), if i % 2 == 0 then BLACK else YELLOW, Enum.Material.SmoothPlastic)
	end
end

-- Gitterwand aus senkrechten Stäben zwischen y0 und y1, Breite entlang lokalem X
local function barWall(parent: Instance, name: string, width: number, y0: number, y1: number, cframe: CFrame, spacing: number)
	local count = math.floor(width / spacing)
	local h = y1 - y0
	for i = 1, count - 1 do
		local x = -width / 2 + i * (width / count)
		cylinder(parent, `{name}Bar{i}`, h, 0.16, cframe * CFrame.new(x, y0 + h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), STEEL_LIGHT)
	end
end

-- Ein Torflügel: Rahmen + Stäbe + gelbes Band
local function gateLeaf(parent: Instance, name: string, width: number, height: number, cframe: CFrame)
	local leaf = Instance.new("Folder")
	leaf.Name = name
	leaf.Parent = parent
	part(leaf, "RailTop", Vector3.new(width, 0.25, 0.2), cframe * CFrame.new(0, height, 0), STEEL_DARK)
	part(leaf, "RailBottom", Vector3.new(width, 0.25, 0.2), cframe * CFrame.new(0, 0.3, 0), STEEL_DARK)
	part(leaf, "Band", Vector3.new(width, 0.5, 0.22), cframe * CFrame.new(0, height * 0.55, 0), YELLOW, Enum.Material.SmoothPlastic)
	part(leaf, "StileA", Vector3.new(0.25, height, 0.2), cframe * CFrame.new(-width / 2 + 0.12, height / 2, 0), STEEL_DARK)
	part(leaf, "StileB", Vector3.new(0.25, height, 0.2), cframe * CFrame.new(width / 2 - 0.12, height / 2, 0), STEEL_DARK)
	barWall(leaf, "Leaf", width, 0.3, height, cframe, 0.8)
	for _, d in leaf:GetDescendants() do
		if d:IsA("BasePart") then
			d:SetAttribute("ClosedCFrame", d.CFrame)
		end
	end
	return leaf
end

-- Baut den Korb. `base` = Mitte der Bodenoberkante, -Z = Vorderseite mit Tor.
function ElevatorCageBuilder.build(parent: Instance, base: CFrame, kind: "Surface" | "Mine", plotId: number?): Folder
	local S, H = ElevatorCageBuilder.Size, ElevatorCageBuilder.Height
	local half = S / 2
	local cage = Instance.new("Folder")
	cage.Name = "Cage"
	cage.Parent = parent

	-- Boden mit Schwellen-Warnstreifen
	part(cage, "CarFloor", Vector3.new(S + 1, 0.5, S + 1), base * CFrame.new(0, -0.25, 0), STEEL_LIGHT, Enum.Material.DiamondPlate)
	hazardStrip(cage, "Threshold", S, Vector2.new(0.06, 1), base * CFrame.new(0, 0.03, -half + 0.4))

	-- Eckstützen (I-Träger) und Rahmen
	for i, c in { Vector2.new(half, half), Vector2.new(-half, half), Vector2.new(half, -half), Vector2.new(-half, -half) } do
		columnI(cage, `Column{i}`, H, base * CFrame.new(c.X, H / 2, c.Y))
	end
	beamI(cage, "TopFront", S + 1, base * CFrame.new(0, H, -half))
	beamI(cage, "TopBack", S + 1, base * CFrame.new(0, H, half))
	beamI(cage, "TopLeft", S + 1, base * CFrame.new(half, H, 0) * CFrame.Angles(0, math.rad(90), 0))
	beamI(cage, "TopRight", S + 1, base * CFrame.new(-half, H, 0) * CFrame.Angles(0, math.rad(90), 0))
	beamI(cage, "MidBack", S, base * CFrame.new(0, 3.2, half))
	beamI(cage, "MidLeft", S, base * CFrame.new(half, 3.2, 0) * CFrame.Angles(0, math.rad(90), 0))
	beamI(cage, "MidRight", S, base * CFrame.new(-half, 3.2, 0) * CFrame.Angles(0, math.rad(90), 0))

	-- Wände: unten Riffelblech, oben Gitterstäbe (hinten, links, rechts). Vorne nur das Tor.
	part(cage, "KickBack", Vector3.new(S, 2.8, 0.15), base * CFrame.new(0, 1.4, half), STEEL, Enum.Material.DiamondPlate)
	part(cage, "KickLeft", Vector3.new(0.15, 2.8, S), base * CFrame.new(half, 1.4, 0), STEEL, Enum.Material.DiamondPlate)
	part(cage, "KickRight", Vector3.new(0.15, 2.8, S), base * CFrame.new(-half, 1.4, 0), STEEL, Enum.Material.DiamondPlate)
	barWall(cage, "Back", S, 3.6, H - 0.5, base * CFrame.new(0, 0, half), 1.0)
	barWall(cage, "Left", S, 3.6, H - 0.5, base * CFrame.new(half, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 1.0)
	barWall(cage, "Right", S, 3.6, H - 0.5, base * CFrame.new(-half, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 1.0)
	-- Diagonale Aussteifung an den Seiten
	for _, side in { 1, -1 } do
		local len = math.sqrt(S * S + (H - 4) ^ 2)
		local angle = math.atan2(H - 4, S)
		part(cage, `Brace{side}`, Vector3.new(0.25, 0.25, len), base * CFrame.new(side * (half + 0.3), 3.6 + (H - 4) / 2, 0) * CFrame.Angles(angle * side, 0, 0), STEEL_DARK)
	end

	-- Schiebegitter-Tor (zwei Flügel), Standard: offen
	local gate = Instance.new("Folder")
	gate.Name = "Gate"
	gate.Parent = cage
	local leafW = half - 0.1
	gateLeaf(gate, "LeafLeft", leafW, H - 1.2, base * CFrame.new(leafW / 2 + 0.05, 0, -half - 0.6))
	gateLeaf(gate, "LeafRight", leafW, H - 1.2, base * CFrame.new(-leafW / 2 - 0.05, 0, -half - 0.6))
	part(cage, "GateTrack", Vector3.new(S * 2, 0.3, 0.4), base * CFrame.new(0, H - 0.9, -half - 0.6), STEEL_DARK)
	hazardStrip(cage, "Header", S, Vector2.new(0.7, 0.25), base * CFrame.new(0, H - 1.8, -half - 0.85))

	-- Dach mit Luke
	part(cage, "Roof", Vector3.new(S + 1.4, 0.35, S + 1.4), base * CFrame.new(0, H + 0.65, 0), STEEL, Enum.Material.DiamondPlate)
	part(cage, "Hatch", Vector3.new(3.4, 0.2, 3.4), base * CFrame.new(3, H + 0.92, 3), STEEL_LIGHT, Enum.Material.DiamondPlate)

	-- Förderturm mit Seilrad
	local towerH = 9
	local legX = half - 1.5
	local towerBase = H + 0.8
	for _, side in { 1, -1 } do
		columnI(cage, `TowerLeg{side}`, towerH, base * CFrame.new(side * legX, towerBase + towerH / 2, 0))
		-- Abstrebungen der Turmbeine nach vorne und hinten zum Dach
		strut(cage, `TowerStrutBack{side}`, base, Vector3.new(side * legX, towerBase, half - 0.5), Vector3.new(side * legX, towerBase + towerH * 0.75, 0))
		strut(cage, `TowerStrutFront{side}`, base, Vector3.new(side * legX, towerBase, -half + 0.5), Vector3.new(side * legX, towerBase + towerH * 0.75, 0))
	end
	-- Kreuzverband zwischen den Turmbeinen
	strut(cage, "TowerCrossA", base, Vector3.new(legX, towerBase + 0.5, 0), Vector3.new(-legX, towerBase + towerH - 1, 0))
	strut(cage, "TowerCrossB", base, Vector3.new(-legX, towerBase + 0.5, 0), Vector3.new(legX, towerBase + towerH - 1, 0))
	beamI(cage, "TowerHead", S - 1, base * CFrame.new(0, H + 0.8 + towerH, 0))
	local sheaveCF = base * CFrame.new(0, H + 0.8 + towerH + 2.4, 0)
	cylinder(cage, "SheaveRim", 0.5, 4.6, sheaveCF, STEEL_DARK)
	cylinder(cage, "SheaveHub", 1.2, 0.9, sheaveCF, YELLOW, Enum.Material.SmoothPlastic)
	for i = 0, 3 do
		part(cage, `Spoke{i}`, Vector3.new(0.2, 4.2, 0.3), sheaveCF * CFrame.Angles(math.rad(i * 45), 0, 0), STEEL_LIGHT)
	end
	cylinder(cage, "Axle", S - 3, 0.35, sheaveCF, STEEL_LIGHT)
	for _, z in { -1.2, 1.2 } do
		local cableLen = towerH + 2.4
		part(cage, `Cable{z}`, Vector3.new(0.15, cableLen, 0.15), base * CFrame.new(0, H + 0.8 + cableLen / 2, z), CABLE)
	end

	-- Bedienpult an der rechten vorderen Stütze (außen) mit Leuchttastern
	local panelCF = base * CFrame.new(-half - 1.1, 4.2, -half + 1)
	part(cage, "ControlPanel", Vector3.new(1.2, 2.2, 1), panelCF, YELLOW, Enum.Material.SmoothPlastic)
	part(cage, "ControlFace", Vector3.new(0.05, 1.8, 0.8), panelCF * CFrame.new(-0.62, 0, 0), STEEL_DARK)
	local up = part(cage, "ButtonUp", Vector3.new(0.1, 0.35, 0.35), panelCF * CFrame.new(-0.66, 0.45, 0), Color3.fromRGB(90, 220, 110), Enum.Material.Neon)
	up.Shape = Enum.PartType.Cylinder
	local down = part(cage, "ButtonDown", Vector3.new(0.1, 0.35, 0.35), panelCF * CFrame.new(-0.66, -0.15, 0), Color3.fromRGB(230, 70, 60), Enum.Material.Neon)
	down.Shape = Enum.PartType.Cylinder
	part(cage, "PanelPost", Vector3.new(0.3, 3.2, 0.3), base * CFrame.new(-half - 1.1, 1.6, -half + 1), STEEL_DARK)

	-- Warnleuchte auf dem Dach (leuchtet während der Fahrt)
	local beacon = cylinder(cage, "Beacon", 0.8, 0.9, base * CFrame.new(half - 0.8, H + 1.25, -half + 0.8) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 70, 20), Enum.Material.SmoothPlastic)
	local beaconLight = Instance.new("PointLight")
	beaconLight.Name = "BeaconLight"
	beaconLight.Color = Color3.fromRGB(255, 150, 40)
	beaconLight.Range = 14
	beaconLight.Brightness = 3
	beaconLight.Enabled = false
	beaconLight.Parent = beacon

	-- Innenlampe
	local lamp = part(cage, "CeilingLamp", Vector3.new(3, 0.2, 1), base * CFrame.new(0, H - 0.6, 0), Color3.fromRGB(255, 240, 210), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 14
	light.Brightness = 1
	light.Color = Color3.fromRGB(255, 236, 210)
	light.Parent = lamp

	-- Ankunft und Bedienung
	local arrival = part(cage, "ArrivalPoint", Vector3.new(2, 1, 2), base * CFrame.new(0, 3, 2), STEEL, Enum.Material.SmoothPlastic)
	arrival.Transparency = 1
	arrival.CanCollide = false
	arrival.CanQuery = false

	local promptPart = part(cage, "ElevatorPromptPart", Vector3.new(4, 4, 4), base * CFrame.new(0, 3, 0), STEEL, Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ElevatorPrompt"
	prompt.ActionText = "Use Elevator"
	prompt.ObjectText = "Elevator"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ElevatorKind", kind)
	if plotId then
		prompt:SetAttribute("PlotId", plotId)
	end
	prompt.Parent = promptPart

	ElevatorCageBuilder.setGate(cage, true, false)
	return cage
end

-- Tor öffnen/schließen. Offen = Flügel seitlich vor die Seitenwände geschoben.
function ElevatorCageBuilder.setGate(cage: Instance, open: boolean, animate: boolean)
	local gate = cage:FindFirstChild("Gate")
	if not gate then
		return
	end
	local slide = ElevatorCageBuilder.Size / 2 - 0.4
	for _, leafName in { "LeafLeft", "LeafRight" } do
		local leaf = gate:FindFirstChild(leafName)
		if leaf then
			local dir = if leafName == "LeafLeft" then 1 else -1
			for _, p in leaf:GetChildren() do
				if p:IsA("BasePart") then
					local closed = p:GetAttribute("ClosedCFrame")
					if typeof(closed) == "CFrame" then
						-- Verschieben entlang der lokalen X-Achse des Korbs (Breite)
						local offset = closed.Rotation:Inverse() * (cage:FindFirstChild("CarFloor") :: BasePart).CFrame.RightVector * (dir * slide)
						local target = if open then closed * CFrame.new(offset) else closed
						if animate then
							TweenService:Create(p, TweenInfo.new(GATE_OPEN_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = target }):Play()
						else
							p.CFrame = target
						end
					end
				end
			end
		end
	end
end

-- Warnleuchte während der Fahrt an/aus
function ElevatorCageBuilder.setBeacon(cage: Instance, on: boolean)
	local beacon = cage:FindFirstChild("Beacon")
	if beacon and beacon:IsA("BasePart") then
		beacon.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		beacon.Color = if on then Color3.fromRGB(255, 140, 30) else Color3.fromRGB(120, 70, 20)
		local light = beacon:FindFirstChild("BeaconLight")
		if light and light:IsA("PointLight") then
			light.Enabled = on
		end
	end
end

ElevatorCageBuilder.GateSeconds = GATE_OPEN_SECONDS

return ElevatorCageBuilder
