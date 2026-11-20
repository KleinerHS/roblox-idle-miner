--!strict
-- Baut den Mine-Shaft-Raum eines Plots. Seit D-098 kommt die sichtbare Geometrie aus Felix'
-- überarbeiteter Mine V5 (MineShaftLayout, erzeugt aus seinem OBJ mit tools/obj_to_luau.py):
-- Raum mit Holzverbau, zwei Abbauplätzen, Podest mit Treppe, Deko. Per Code kommen nur die
-- Funktionsteile dazu: Abbauzonen, Slot-Prompts, Beschriftungen, Lichter, Staub und der
-- Förderkorb (ElevatorCageBuilder, ebenfalls aus Felix' Modell).
--
-- Jeder Plot hat genau einen Raum unter sich. Beim Wechsel der Mine wird er nur
-- umkonfiguriert (Erzfarbe, Felsfarbe, Schild), nicht neu gebaut (D-014).
--
-- Vereinbarte Namen/Attribute:
--   Model "MineShaft_<plotId>"  Attribute PlotId, MineId
--   Folder "Cage" (ElevatorCageBuilder) mit ArrivalPoint, ElevatorPromptPart, Gate
--   Part  "MiningSlot<n>"       unsichtbare Abbauzone, Attribute SlotIndex, Tag "MiningSlot"
--   Attribute "Recolor" = "Rock" | "Ore" an allen umzufärbenden Teilen

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Mines = require(Shared.Definitions.Mines)
local Ores = require(Shared.Definitions.Ores)

local ElevatorCageBuilder = require(script.Parent.ElevatorCageBuilder)
local MineShaftLayout = require(script.Parent.MineShaftLayout)
local FloatingText = require(script.Parent.FloatingText)

local MineShaftBuilder = {}

local DIRT = Color3.fromRGB(96, 80, 64)
local YELLOW = Color3.fromRGB(236, 182, 40)
local LAMP = Color3.fromRGB(255, 214, 160)

-- Höhe des Holzverbaus (für die Slot-Beschriftung über dem Stützrahmen)
local TIMBER_HEIGHT = 15

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

function MineShaftBuilder.getRoomOrigin(plotCFrame: CFrame): CFrame
	return plotCFrame * CFrame.new(0, -LayoutConfig.MineShaft.DepthBelowPlot, 0)
end

-- Wand mit Holzverbau: Mittelpunkt, Richtung entlang der Wand (= RightVector, wenn man
-- in den Raum schaut), Normale in den Raum.
type Wall = { name: string, center: Vector3, along: Vector3, inward: Vector3, length: number }

local function walls(): { Wall }
	local size = LayoutConfig.MineShaft.Size
	local W, D = size.X, size.Z
	return {
		{ name = "Back", center = Vector3.new(0, 0, D / 2), along = Vector3.new(1, 0, 0), inward = Vector3.new(0, 0, -1), length = W },
		{ name = "Left", center = Vector3.new(W / 2, 0, 0), along = Vector3.new(0, 0, -1), inward = Vector3.new(-1, 0, 0), length = D },
		{ name = "Right", center = Vector3.new(-W / 2, 0, 0), along = Vector3.new(0, 0, 1), inward = Vector3.new(1, 0, 0), length = D },
	}
end

-- Position entlang einer Seitenwand für eine lokale Z-Koordinate
local function zToT(wall: Wall, z: number): number
	return z * wall.along.Z
end

-- CFrame auf einer Wand: t = Position entlang der Wand, inset = Abstand von der Wand.
-- LookVector zeigt in den Raum, RightVector entlang der Wand.
local function wallCFrame(o: CFrame, wall: Wall, t: number, y: number, inset: number): CFrame
	local pos = wall.center + wall.along * t + wall.inward * inset + Vector3.new(0, y, 0)
	return o * CFrame.lookAt(pos, pos + wall.inward)
end

-- Abbauplatz-Funktion (Geometrie kommt aus MineShaftLayout): unsichtbare Abbauzone, Prompt
-- zum Verwalten des Slots, schwebende Beschriftung.
local function buildSlotGameplay(model: Model, o: CFrame, slotIndex: number, plotId: number)
	local slot = LayoutConfig.MineShaft.Slots[slotIndex]
	local wall = if slot.X > 0 then walls()[2] else walls()[3]
	local t0 = zToT(wall, slot.Y)
	local folder = model:FindFirstChild(`Slot{slotIndex}`) or Instance.new("Folder")
	folder.Name = `Slot{slotIndex}`
	folder.Parent = model

	-- Unsichtbare Abbauzone für Schritt 2c: freie Fläche direkt vor der Erzwand
	local zone = part(folder, `MiningSlot{slotIndex}`, Vector3.new(16, 14, 12), wallCFrame(o, wall, t0, 7, 6), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	zone.Transparency = 1
	zone.CanCollide = false
	zone:SetAttribute("SlotIndex", slotIndex)
	zone:SetAttribute("PlotId", plotId)
	CollectionService:AddTag(zone, "MiningSlot")

	-- Slot verwalten (Drill platzieren/entfernen, docs/05 §25, docs/10 §31–32). Der Prompt
	-- sitzt an einem kleinen Pfosten im Raum vor dem Slot, nicht an der Wand.
	-- Beschriftung als schwebende Schrift über dem Stützrahmen statt Schild (wie in der Halle)
	FloatingText.title(folder, `SlotSign{slotIndex}`, wallCFrame(o, wall, t0, TIMBER_HEIGHT + 4.6, 4), `Mining Slot {slotIndex}`, 1.8, YELLOW).CanQuery = false
	local promptPart = part(folder, `SlotPromptPart{slotIndex}`, Vector3.new(1, 1, 1), wallCFrame(o, wall, t0 - 9.5, 3, 11), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SlotPrompt"
	prompt.ActionText = "Manage Slot"
	prompt.ObjectText = `Mining Slot {slotIndex}`
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("SlotIndex", slotIndex)
	prompt:SetAttribute("PlotId", plotId)
	prompt.Parent = promptPart
end


-- Lage des Förderkorbs im Raum V5 (Korbboden-Oberkante Mitte, lokal zum Raumursprung)
local CAGE_BASE = Vector3.new(0, 2.95, 24.65)
-- Vorderkante des Podests (lokal Z), davor schwebt die Schacht-Beschriftung
local PODIUM_FRONT_Z = 13.8

-- Teile, die nicht kollidieren (Deko am Boden/an der Decke, Lampen, Streifen)
local NO_COLLIDE = { "CeilingRock", "Pebble", "DirtPatch", "LampCord", "LampShade", "HangLamp", "EdgeStripe", "StepNosing", "Floodlight" }

local function lampLight(p: BasePart, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = brightness
	light.Color = LAMP
	light.Shadows = false
	light.Parent = p
end

-- Ein Teil aus dem Layout bauen und nach Namen ausstatten (Umfärben, Kollision, Licht)
local function layoutPart(model: Model, o: CFrame, e: { any }, folders: { [string]: Instance })
	local path = e[1] :: string
	local segments = string.split(path, "/")
	local parent: Instance = model
	local key = ""
	for i = 1, #segments - 1 do
		key ..= "/" .. segments[i]
		local f = folders[key]
		if not f then
			f = Instance.new("Folder")
			f.Name = segments[i]
			f.Parent = parent
			folders[key] = f
		end
		parent = f :: Instance
	end
	local name = segments[#segments]
	local cf = o * CFrame.new(e[3], e[4], e[5], e[6], e[7], e[8], e[9], e[10], e[11], e[12], e[13], e[14])
	local p = part(parent, name, Vector3.new(e[15], e[16], e[17]), cf, Color3.fromRGB(e[19], e[20], e[21]), (Enum.Material :: any)[e[18]])
	if e[2] == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	elseif e[2] == "Ball" then
		p.Shape = Enum.PartType.Ball
	end

	local top = segments[1]
	if top == "Ceiling" or top == "Boulders" or string.sub(top, 1, 5) == "Wall_" or string.find(name, "^CeilingRock") or string.find(name, "^Pebble") then
		p:SetAttribute("Recolor", "Rock")
	elseif string.find(path, "/OreVein/") then
		p:SetAttribute("Recolor", "Ore")
	end
	for _, prefix in NO_COLLIDE do
		if string.sub(name, 1, #prefix) == prefix then
			p.CanCollide = false
			if prefix == "DirtPatch" then
				p.CanQuery = false
			end
		end
	end
	if top == "Timber" and string.find(name, "Lamp%d+$") then
		lampLight(p, 20, 1.3)
	elseif string.find(top, "^Slot%d") and name == "Lamp" then
		lampLight(p, 26, 1.8)
	elseif string.find(name, "^HangLamp") then
		lampLight(p, 22, 1.1)
	elseif string.find(name, "^Floodlight") then
		local spot = Instance.new("SpotLight")
		spot.Angle = 80
		spot.Range = 30
		spot.Brightness = 1.4
		spot.Color = LAMP
		spot.Face = Enum.NormalId.Front
		spot.Parent = p
	end
end

-- Schwebender Staub im Lampenlicht
local function buildDust(model: Model, o: CFrame)
	local size = LayoutConfig.MineShaft.Size
	local W, H, D = size.X, size.Y, size.Z
	local folder = model:FindFirstChild("Atmosphere") or model
	local dustBox = part(folder, "DustVolume", Vector3.new(W - 4, H * 0.6, D - 4), o * CFrame.new(0, H * 0.45, 0), DIRT, Enum.Material.SmoothPlastic)
	dustBox.Transparency = 1
	dustBox.CanCollide = false
	dustBox.CanQuery = false
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(230, 200, 160))
	dust.Size = NumberSequence.new(0.12)
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(6, 10)
	dust.Rate = 12
	dust.Speed = NumberRange.new(0.2, 0.6)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.LightEmission = 0.4
	dust.Shape = Enum.ParticleEmitterShape.Box
	dust.Parent = dustBox
end

-- Förderkorb und Schacht-Beschriftung
local function buildElevatorGameplay(model: Model, o: CFrame, plotId: number)
	local folder = model:FindFirstChild("Elevator") or Instance.new("Folder")
	folder.Name = "Elevator"
	folder.Parent = model
	-- Shaft-Nummer als schwebende Schrift vor dem Förderkorb (docs/12 §25). Part "ShaftSign" mit
	-- TextLabel "Label", configure() setzt den Text.
	FloatingText.create(folder, "ShaftSign", o * CFrame.new(CAGE_BASE.X, 19.5, PODIUM_FRONT_Z - 0.5), 18, {
		{ Name = "Label", Text = "MINE", Size = 2.2, Color = YELLOW },
	}, 160).CanQuery = false
	ElevatorCageBuilder.build(folder, o * CFrame.new(CAGE_BASE), "Mine", plotId)
end

-- Baut den Raum für einen Plot (einmal beim Serverstart).
function MineShaftBuilder.build(parent: Instance, plotId: number, plotCFrame: CFrame): Model
	local model = Instance.new("Model")
	model.Name = `MineShaft_{plotId}`
	model:SetAttribute("PlotId", plotId)
	model:SetAttribute("MineId", "")

	local o = MineShaftBuilder.getRoomOrigin(plotCFrame)
	-- Geometrie aus Felix' Mine V5 (D-098), Funktionsteile per Code
	local folders: { [string]: Instance } = {}
	for _, e in MineShaftLayout do
		layoutPart(model, o, e, folders)
	end
	for slotIndex = 1, #LayoutConfig.MineShaft.Slots do
		buildSlotGameplay(model, o, slotIndex, plotId)
	end
	buildElevatorGameplay(model, o, plotId)
	buildDust(model, o)

	model.PrimaryPart = model:FindFirstChild("Floor") :: BasePart
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

-- Stellt den Raum auf eine Mine ein (Erzfarbe, Felsfarbe, Schild).
function MineShaftBuilder.configure(room: Model, mine: Mines.MineDefinition)
	if room:GetAttribute("MineId") == mine.Id then
		return
	end
	local ore = Ores.Get(mine.OreId)
	assert(ore, `Unbekanntes Erz {mine.OreId}`)
	local rockColor = Mines.RockColor(mine)
	for _, d in room:GetDescendants() do
		if d:IsA("BasePart") then
			local recolor = d:GetAttribute("Recolor")
			if recolor == "Rock" then
				d.Color = rockColor
			elseif recolor == "Ore" then
				d.Color = ore.Color
			end
		end
	end
	local sign = room:FindFirstChild("ShaftSign", true)
	local label = sign and sign:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.Text = `{Mines.Label(mine)} · {string.upper(ore.DisplayName)}`
	end
	room:SetAttribute("MineId", mine.Id)
end

-- Förderkorb des Raums
function MineShaftBuilder.getCage(room: Model): Instance?
	return room:FindFirstChild("Cage", true)
end

return table.freeze(MineShaftBuilder)
