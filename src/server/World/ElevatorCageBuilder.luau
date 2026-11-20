--!strict
-- Gemeinsamer Bergbau-Förderkorb für Oberfläche und Mine Shaft (docs/04 §16, docs/19 §7).
-- Seit D-098 Felix' Förderkorb V5 (CageLayout, erzeugt aus seinem OBJ mit tools/obj_to_luau.py):
-- Stahlkorb mit Gitterstäben, zwei Schiebetoren, Bedienpult, Kennschild „01“, Dach mit
-- Warnleuchte und Seilwinde. Per Code kommen nur Lichter, Ankunftspunkt und Prompt dazu.
--
-- Vereinbarte Namen (werden von ElevatorService genutzt):
--   Part   "CarFloor"           Korbboden (Bezug für die Torlagen)
--   Folder "Gate" mit Folder "LeafLeft"/"LeafRight" (Tor, über setGate bewegt)
--   Part   "ArrivalPoint"       Ankunft im Korb, Blick nach vorne (-Z)
--   Part   "ElevatorPromptPart" mit ProximityPrompt "ElevatorPrompt"
--   Part   "Beacon"             Warnleuchte (leuchtet während der Fahrt)

local TweenService = game:GetService("TweenService")

local CageLayout = require(script.Parent.CageLayout)

local ElevatorCageBuilder = {}

-- Innenmaß des Korbs und Höhe (lokal, Boden-Oberkante = y 0, vorne = -Z)
ElevatorCageBuilder.Size = 16
ElevatorCageBuilder.Height = 14

local STEEL = Color3.fromRGB(58, 62, 68)
local BEACON_ON = Color3.fromRGB(255, 140, 30)

local GATE_OPEN_SECONDS = 0.6

-- Pfade aus Felix' Modell mit Sonderrolle
local RENAME = {
	["Korb/Boden"] = "CarFloor",
	["Dach/Warnleuchte"] = "Beacon",
}
-- Der Korb ist gegenüber Felix' Ansicht gespiegelt übernommen (siehe tools/obj_to_luau.py):
-- sein „Rechts“-Tor liegt in Roblox bei +X (LeafLeft), „Links“ bei −X (LeafRight).
local LEAF_PREFIX = {
	["Korb/Schiebetore/Rechts/"] = "LeafLeft",
	["Korb/Schiebetore/Links/"] = "LeafRight",
}

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

local function light(p: BasePart, range: number, brightness: number, color: Color3)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = brightness
	l.Color = color
	l.Shadows = false
	l.Parent = p
end

-- Baut den Korb. `base` = Mitte der Bodenoberkante, -Z = Vorderseite mit Tor.
function ElevatorCageBuilder.build(parent: Instance, base: CFrame, kind: "Surface" | "Mine", plotId: number?): Folder
	local cage = Instance.new("Folder")
	cage.Name = "Cage"
	cage.Parent = parent
	local gate = Instance.new("Folder")
	gate.Name = "Gate"
	gate.Parent = cage
	local leaves: { [string]: Folder } = {}
	for _, leafName in LEAF_PREFIX do
		local leaf = Instance.new("Folder")
		leaf.Name = leafName
		leaf.Parent = gate
		leaves[leafName] = leaf
	end

	-- Tor-Teile merken; ihre geschlossene Lage wird nach dem Bau relativ zum Boden gespeichert
	local leafParts: { { p: BasePart, dir: number } } = {}
	for _, e in CageLayout :: { { any } } do
		local path = e[1] :: string
		local target: Instance = cage
		local leafName: string? = nil
		for prefix, name in LEAF_PREFIX do
			if string.sub(path, 1, #prefix) == prefix then
				target = leaves[name]
				leafName = name
			end
		end
		local segments = string.split(path, "/")
		local name = RENAME[path] or segments[#segments]
		local cf = base * CFrame.new(e[3], e[4], e[5], e[6], e[7], e[8], e[9], e[10], e[11], e[12], e[13], e[14])
		local p = part(target, name, Vector3.new(e[15], e[16], e[17]), cf, Color3.fromRGB(e[19], e[20], e[21]), (Enum.Material :: any)[e[18]])
		if e[2] == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		elseif e[2] == "Ball" then
			p.Shape = Enum.PartType.Ball
		end
		if leafName then
			table.insert(leafParts, { p = p, dir = if leafName == "LeafLeft" then 1 else -1 })
		end
		if name == "Innenleuchte" then
			light(p, 16, 1, Color3.fromRGB(255, 236, 210))
		elseif name == "Beacon" then
			p:SetAttribute("OffColor", p.Color)
			p:SetAttribute("OffMaterial", p.Material.Name)
			local beaconLight = Instance.new("PointLight")
			beaconLight.Name = "BeaconLight"
			beaconLight.Color = Color3.fromRGB(255, 150, 40)
			beaconLight.Range = 14
			beaconLight.Brightness = 3
			beaconLight.Enabled = false
			beaconLight.Parent = p
		end
	end

	-- Das Modell steht mit offenen Toren: geschlossene Lage = aktuelle Lage minus Schub (BUG-019)
	local floor = cage:FindFirstChild("CarFloor") :: BasePart
	local slide = ElevatorCageBuilder.Size / 2 - 0.4
	for _, lp in leafParts do
		local shift = floor.CFrame.RightVector * (lp.dir * slide)
		lp.p:SetAttribute("ClosedOffset", floor.CFrame:ToObjectSpace(lp.p.CFrame - shift))
	end

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
-- Alle Lagen werden aus dem aktuellen Korbboden berechnet (BUG-019). Ältere Körbe aus dem
-- HallLayout tragen nur eine absolute "ClosedCFrame" aus der Bauzeit, die nach dem Verschieben
-- falsch ist (Flügel flogen weg/verdrehten sich). Für sie wird die geschlossene Lage einmalig aus
-- der aktuellen, offenen Lage abgeleitet (gebaute Körbe stehen immer offen).
function ElevatorCageBuilder.setGate(cage: Instance, open: boolean, animate: boolean)
	local gate = cage:FindFirstChild("Gate")
	local floor = cage:FindFirstChild("CarFloor")
	if not gate or not (floor and floor:IsA("BasePart")) then
		return
	end
	local floorCFrame = floor.CFrame
	local slide = ElevatorCageBuilder.Size / 2 - 0.4
	for _, leafName in { "LeafLeft", "LeafRight" } do
		local leaf = gate:FindFirstChild(leafName)
		if leaf then
			local dir = if leafName == "LeafLeft" then 1 else -1
			local shift = floorCFrame.RightVector * (dir * slide)
			for _, p in leaf:GetChildren() do
				if p:IsA("BasePart") then
					local offset = p:GetAttribute("ClosedOffset")
					if typeof(offset) ~= "CFrame" then
						-- Altbestand: Korb steht offen, also geschlossene Lage = aktuelle Lage − Schub
						offset = floorCFrame:ToObjectSpace(p.CFrame - shift)
						p:SetAttribute("ClosedOffset", offset)
					end
					local closed = floorCFrame * (offset :: CFrame)
					local target = if open then closed + shift else closed
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

-- Warnleuchte während der Fahrt an/aus
function ElevatorCageBuilder.setBeacon(cage: Instance, on: boolean)
	local beacon = cage:FindFirstChild("Beacon")
	if beacon and beacon:IsA("BasePart") then
		local offColor = beacon:GetAttribute("OffColor")
		local offMaterial = beacon:GetAttribute("OffMaterial")
		beacon.Material = if on then Enum.Material.Neon elseif typeof(offMaterial) == "string" then (Enum.Material :: any)[offMaterial] else Enum.Material.SmoothPlastic
		beacon.Color = if on then BEACON_ON elseif typeof(offColor) == "Color3" then offColor else Color3.fromRGB(120, 70, 20)
		local light = beacon:FindFirstChild("BeaconLight")
		if light and light:IsA("PointLight") then
			light.Enabled = on
		end
	end
end

ElevatorCageBuilder.GateSeconds = GATE_OPEN_SECONDS

return ElevatorCageBuilder
