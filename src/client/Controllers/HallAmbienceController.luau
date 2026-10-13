--!strict
-- Hallen-Leben auf dem Client (Felix 2026-10-13: „nicht so leer und tot“). Rein lokale Optik:
--   * Spin:      Lüfter, Rundumleuchten, Ofentrommel und Schnecke (nur im Betrieb) drehen sich
--   * Shuttle:   Gabelstapler fährt im Gang hin und her
--   * Blink:     Kontroll-LEDs an Maschinen blinken unregelmäßig
--   * StaffPath: Arbeiter (einfache Figuren) laufen ihre Wege und arbeiten an den Enden
-- Tags/Attribute siehe Shared/Definitions/AmbientTags. Nur in Kameranähe wird animiert.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AmbientTags = require(Shared.Definitions.AmbientTags)

local HallAmbienceController = {}

-- Sichtweite für Animationen (Studs) und Prüfintervall der Entfernung (s)
local VIEW_DISTANCE = 320
local DISTANCE_CHECK = 0.5
local WALK_SPEED = 4.5

local SKIN = Color3.fromRGB(204, 150, 110)
local PANTS = Color3.fromRGB(44, 58, 90)
local HELMET = Color3.fromRGB(240, 196, 40)
local VESTS = { Color3.fromRGB(236, 120, 30), Color3.fromRGB(230, 200, 40), Color3.fromRGB(70, 160, 90) }

type Spin = { inst: Instance, base: CFrame, axis: Vector3, speed: number, angle: number, owner: Instance? }
type Shuttle = { model: Model, base: CFrame, travel: Vector3, speed: number, pause: number, t: number }
type Blink = { part: BasePart, color: Color3, nextAt: number, on: boolean }
type Staff = {
	path: Model,
	points: { Vector3 },
	figure: Model?,
	parts: { [string]: BasePart },
	index: number,
	dir: number,
	pos: Vector3,
	waitUntil: number,
	phase: number,
	vest: Color3,
	facing: CFrame,
}

local spins: { [Instance]: Spin } = {}
local shuttles: { [Instance]: Shuttle } = {}
local blinks: { [Instance]: Blink } = {}
local staff: { [Instance]: Staff } = {}
local visible: { [Instance]: boolean } = {}

local folder = Instance.new("Folder")
folder.Name = "HallAmbience"

local function pivotOf(inst: Instance): CFrame?
	if inst:IsA("Model") then
		return inst:GetPivot()
	elseif inst:IsA("BasePart") then
		return inst.CFrame
	end
	return nil
end

local function setPivot(inst: Instance, cf: CFrame)
	if inst:IsA("Model") then
		inst:PivotTo(cf)
	elseif inst:IsA("BasePart") then
		inst.CFrame = cf
	end
end

local function axisVector(axis: any): Vector3
	if axis == "X" then
		return Vector3.xAxis
	elseif axis == "Z" then
		return Vector3.zAxis
	end
	return Vector3.yAxis
end

-- Nächstes Vorfahren-Model mit Attribut "Running" (z. B. die Schmelze)
local function runningOwner(inst: Instance): Instance?
	local current = inst.Parent
	while current and current ~= workspace do
		if current:GetAttribute("Running") ~= nil then
			return current
		end
		current = current.Parent
	end
	return nil
end

-- Einfache Arbeiterfigur (wie die Worker im Schacht), Füße auf y = 0 des Modells
local function buildFigure(vest: Color3): (Model, { [string]: BasePart })
	local m = Instance.new("Model")
	m.Name = "Staff"
	local parts: { [string]: BasePart } = {}
	local function add(name: string, size: Vector3, color: Color3, material: Enum.Material?)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = true
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Parent = m
		parts[name] = p
	end
	add("Torso", Vector3.new(2, 2, 1), vest)
	add("Head", Vector3.new(1.2, 1.2, 1.2), SKIN)
	add("Helmet", Vector3.new(1.4, 0.5, 1.4), HELMET)
	add("ArmL", Vector3.new(0.9, 2, 0.9), vest)
	add("ArmR", Vector3.new(0.9, 2, 0.9), vest)
	add("LegL", Vector3.new(0.95, 2, 0.95), PANTS)
	add("LegR", Vector3.new(0.95, 2, 0.95), PANTS)
	m.Parent = folder
	return m, parts
end

-- Figur an Position/Richtung stellen; swing = Schwung der Beine (Laufen), work = Armbewegung
local function poseFigure(s: Staff, root: CFrame, swing: number, work: number)
	local p = s.parts
	local function limb(name: string, hip: Vector3, angle: number)
		local hinge = root * CFrame.new(hip) * CFrame.Angles(angle, 0, 0)
		p[name].CFrame = hinge * CFrame.new(0, -1, 0)
	end
	p.Torso.CFrame = root * CFrame.new(0, 3, 0)
	p.Head.CFrame = root * CFrame.new(0, 4.6, 0)
	p.Helmet.CFrame = root * CFrame.new(0, 5.25, 0)
	limb("LegL", Vector3.new(-0.5, 2, 0), swing)
	limb("LegR", Vector3.new(0.5, 2, 0), -swing)
	limb("ArmL", Vector3.new(-1.45, 4, 0), -swing * 0.8 + work)
	limb("ArmR", Vector3.new(1.45, 4, 0), swing * 0.8 + work * 0.6)
end

-- Registrierung ------------------------------------------------------------------------------

local function addSpin(inst: Instance)
	local base = pivotOf(inst)
	if not base then
		return
	end
	spins[inst] = {
		inst = inst,
		base = base,
		axis = axisVector(inst:GetAttribute("SpinAxis")),
		speed = math.rad(tonumber(inst:GetAttribute("SpinSpeed")) or 90),
		angle = math.random() * math.pi * 2,
		owner = if inst:GetAttribute("NeedsRunning") then runningOwner(inst) else nil,
	}
end

local function addShuttle(inst: Instance)
	if not inst:IsA("Model") then
		return
	end
	local travel = inst:GetAttribute("Travel")
	if typeof(travel) ~= "Vector3" then
		return
	end
	shuttles[inst] = {
		model = inst,
		base = inst:GetPivot(),
		travel = travel,
		speed = tonumber(inst:GetAttribute("Speed")) or 4,
		pause = tonumber(inst:GetAttribute("Pause")) or 3,
		t = math.random() * 10,
	}
end

local function addBlink(inst: Instance)
	if inst:IsA("BasePart") then
		blinks[inst] = { part = inst, color = inst.Color, nextAt = os.clock() + math.random() * 2, on = true }
	end
end

local function addStaff(inst: Instance)
	if not inst:IsA("Model") then
		return
	end
	local points = {}
	for i = 1, 32 do
		local p = inst:FindFirstChild(`P{i}`)
		if not (p and p:IsA("BasePart")) then
			break
		end
		table.insert(points, p.Position - Vector3.new(0, 0.1, 0))
	end
	if #points < 2 then
		return
	end
	local vest = inst:GetAttribute("Vest")
	staff[inst] = {
		path = inst,
		points = points,
		figure = nil,
		parts = {},
		index = 1,
		dir = 1,
		pos = points[1],
		waitUntil = os.clock() + math.random() * 3,
		phase = 0,
		vest = if typeof(vest) == "Color3" then vest else VESTS[math.random(1, #VESTS)],
		facing = CFrame.lookAt(points[1], points[2] * Vector3.new(1, 0, 1) + Vector3.new(0, points[1].Y, 0)).Rotation,
	}
end

local function removeStaff(inst: Instance)
	local s = staff[inst]
	if s and s.figure then
		s.figure:Destroy()
	end
	staff[inst] = nil
end

local function watch(tag: string, add: (Instance) -> (), remove: (Instance) -> ())
	for _, inst in CollectionService:GetTagged(tag) do
		task.defer(add, inst)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
		-- Modelle werden oft erst danach gefüllt/positioniert
		task.delay(0.5, function()
			if inst.Parent then
				add(inst)
			end
		end)
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
end

-- Schleife -----------------------------------------------------------------------------------

local function isVisible(inst: Instance, position: Vector3, camera: Vector3): boolean
	local v = (position - camera).Magnitude <= VIEW_DISTANCE
	visible[inst] = v
	return v
end

local function updateVisibility()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local c = camera.CFrame.Position
	for inst, s in spins do
		isVisible(inst, s.base.Position, c)
	end
	for inst, s in shuttles do
		isVisible(inst, s.base.Position, c)
	end
	for inst, b in blinks do
		isVisible(inst, b.part.Position, c)
	end
	for inst, s in staff do
		local v = isVisible(inst, s.points[1], c)
		if v and not s.figure then
			s.figure, s.parts = buildFigure(s.vest)
		elseif not v and s.figure then
			s.figure:Destroy()
			s.figure = nil
			s.parts = {}
		end
	end
end

local function step(dt: number)
	local now = os.clock()
	for inst, s in spins do
		if not visible[inst] then
			continue
		end
		if s.owner and s.owner:GetAttribute("Running") ~= true then
			continue
		end
		s.angle = (s.angle + s.speed * dt) % (math.pi * 2)
		setPivot(inst, s.base * CFrame.fromAxisAngle(s.axis, s.angle))
	end

	for inst, s in shuttles do
		if not visible[inst] then
			continue
		end
		local length = s.travel.Magnitude
		local drive = length / s.speed
		local cycle = (drive + s.pause) * 2
		s.t = (s.t + dt) % cycle
		local f
		if s.t < drive then
			f = s.t / drive
		elseif s.t < drive + s.pause then
			f = 1
		elseif s.t < drive * 2 + s.pause then
			f = 1 - (s.t - drive - s.pause) / drive
		else
			f = 0
		end
		-- weich anfahren und bremsen
		f = f * f * (3 - 2 * f)
		s.model:PivotTo(s.base * CFrame.new(s.travel * f))
	end

	for inst, b in blinks do
		if not visible[inst] or now < b.nextAt then
			continue
		end
		b.on = not b.on
		b.part.Color = if b.on then b.color else b.color:Lerp(Color3.new(0, 0, 0), 0.75)
		b.nextAt = now + (if b.on then 0.4 + math.random() * 2.5 else 0.15 + math.random() * 0.4)
	end

	for _, s in staff do
		if not s.figure then
			continue
		end
		local target = s.points[s.index]
		local flat = Vector3.new(target.X - s.pos.X, 0, target.Z - s.pos.Z)
		local swing, work = 0, 0
		if now < s.waitUntil then
			-- am Ziel arbeiten (Arme), sonst stehen
			s.phase += dt * 6
			work = -0.9 + math.sin(s.phase) * 0.5
		elseif flat.Magnitude < 0.2 then
			-- nächster Punkt; an den Enden umdrehen und arbeiten
			local nextIndex = s.index + s.dir
			if nextIndex < 1 or nextIndex > #s.points then
				s.dir = -s.dir
				nextIndex = s.index + s.dir
				s.waitUntil = now + 3 + math.random() * 5
			end
			s.index = nextIndex
		else
			local move = math.min(flat.Magnitude, WALK_SPEED * dt)
			s.pos += flat.Unit * move + Vector3.new(0, (target.Y - s.pos.Y) * math.min(1, dt * 4), 0)
			s.phase += dt * 9
			swing = math.sin(s.phase) * 0.6
		end
		local look = Vector3.new(target.X - s.pos.X, 0, target.Z - s.pos.Z)
		if look.Magnitude > 0.05 then
			s.facing = CFrame.lookAt(Vector3.zero, look).Rotation
		end
		poseFigure(s, CFrame.new(s.pos) * s.facing, swing, work)
	end
end

function HallAmbienceController.Init() end

function HallAmbienceController.Start()
	folder.Parent = workspace
	watch(AmbientTags.Spin, addSpin, function(inst)
		spins[inst] = nil
		visible[inst] = nil
	end)
	watch(AmbientTags.Shuttle, addShuttle, function(inst)
		shuttles[inst] = nil
		visible[inst] = nil
	end)
	watch(AmbientTags.Blink, addBlink, function(inst)
		blinks[inst] = nil
		visible[inst] = nil
	end)
	watch(AmbientTags.StaffPath, addStaff, function(inst)
		removeStaff(inst)
		visible[inst] = nil
	end)
	task.spawn(function()
		while true do
			updateVisibility()
			task.wait(DISTANCE_CHECK)
		end
	end)
	RunService.RenderStepped:Connect(step)
end

return HallAmbienceController
