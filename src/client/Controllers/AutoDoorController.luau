--!strict
-- Automatische Türen, rein optisch und lokal: Jede Tür (Model mit Tag "AutoDoor") öffnet, sobald
-- irgendein Spieler in Reichweite ist, und schließt wieder, wenn niemand mehr davor steht. Die
-- Flügel sind nicht kollidierend; der Server baut sie geschlossen.
--
-- Schiebetüren (Autohaus, Felix 2026-10-29): Attribute am Model Range (Studs), Slide (Weg je
-- Flügel), Center (Vector3), optional Frame (CFrame) + HalfSize (Vector3) als Rechteck. Attribute
-- am Flügel-Part: ClosedCF (CFrame), Dir (−1 / 1, Richtung entlang der lokalen X-Achse).
--
-- Drehtüren (Premium-Büro, D-082): Attribut Swing (Grad) am Model, jeder Flügel ist ein Model mit
-- Attribut SwingDir (−1 / 1) und einem Attachment "Hinge" (Drehachse = dessen Y-Achse). Ein
-- unsichtbares Part "DoorSensor" im Model ist der Bereich, in dem die Tür aufgeht. Positionen werden
-- beim Erfassen aus dem geschlossenen Zustand gelesen, die Tür darf also mit dem Gebäude bewegt werden.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AutoDoorController = {}

local TAG = "AutoDoor"
-- Sekunden für ganz auf bzw. ganz zu
local OPEN_TIME = 0.6

type Leaf = { part: BasePart, closed: CFrame, dir: number }
type SwingPart = { part: BasePart, rel: CFrame }
type SwingLeaf = { hinge: CFrame, dir: number, parts: { SwingPart } }
type Door = {
	model: Model,
	leaves: { Leaf },
	swingLeaves: { SwingLeaf },
	swing: number,
	center: Vector3,
	range: number,
	slide: number,
	open: number,
	frame: CFrame?,
	half: Vector3?,
}
local doors: { [Model]: Door } = {}

local function trackSwing(model: Model, swing: number)
	local swingLeaves: { SwingLeaf } = {}
	for _, leafModel in model:GetChildren() do
		local dir = leafModel:GetAttribute("SwingDir")
		local hinge = leafModel:FindFirstChild("Hinge", true)
		if leafModel:IsA("Model") and typeof(dir) == "number" and hinge and hinge:IsA("Attachment") then
			local hingeCF = hinge.WorldCFrame
			local parts: { SwingPart } = {}
			for _, d in leafModel:GetDescendants() do
				if d:IsA("BasePart") then
					table.insert(parts, { part = d, rel = hingeCF:ToObjectSpace(d.CFrame) })
				end
			end
			table.insert(swingLeaves, { hinge = hingeCF, dir = dir, parts = parts })
		end
	end
	local sensor = model:FindFirstChild("DoorSensor")
	if #swingLeaves == 0 or not (sensor and sensor:IsA("BasePart")) then
		return
	end
	doors[model] = {
		model = model,
		leaves = {},
		swingLeaves = swingLeaves,
		swing = math.rad(swing),
		center = sensor.Position,
		range = 0,
		slide = 0,
		open = 0,
		frame = sensor.CFrame,
		half = sensor.Size / 2,
	}
end

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local swing = model:GetAttribute("Swing")
	if typeof(swing) == "number" then
		trackSwing(model, swing)
		return
	end
	local leaves: { Leaf } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local cf = d:GetAttribute("ClosedCF")
			local dir = d:GetAttribute("Dir")
			if typeof(cf) == "CFrame" and typeof(dir) == "number" then
				table.insert(leaves, { part = d, closed = cf, dir = dir })
			end
		end
	end
	local center = model:GetAttribute("Center")
	local range = model:GetAttribute("Range")
	local slide = model:GetAttribute("Slide")
	if #leaves == 0 or typeof(center) ~= "Vector3" or typeof(range) ~= "number" or typeof(slide) ~= "number" then
		return
	end
	local frame = model:GetAttribute("Frame")
	local half = model:GetAttribute("HalfSize")
	doors[model] = {
		model = model,
		leaves = leaves,
		swingLeaves = {},
		swing = 0,
		center = center,
		range = range,
		slide = slide,
		open = 0,
		frame = if typeof(frame) == "CFrame" then frame else nil,
		half = if typeof(half) == "Vector3" then half else nil,
	}
end

local function untrack(model: Instance)
	if model:IsA("Model") then
		doors[model] = nil
	end
end

local function someoneNear(door: Door): boolean
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local frame, half = door.frame, door.half
			if frame and half then
				-- Rechteck vor/hinter der Tür
				local l = frame:PointToObjectSpace(root.Position)
				if math.abs(l.X) <= half.X and math.abs(l.Y) <= half.Y and math.abs(l.Z) <= half.Z then
					return true
				end
			elseif (root.Position - door.center).Magnitude <= door.range then
				return true
			end
		end
	end
	return false
end

local function step(dt: number)
	for model, door in doors do
		if not model.Parent then
			doors[model] = nil
			continue
		end
		local target = if someoneNear(door) then 1 else 0
		if door.open == target then
			continue
		end
		local delta = dt / OPEN_TIME
		door.open = if target > door.open then math.min(1, door.open + delta) else math.max(0, door.open - delta)
		-- weich anfahren und abbremsen
		local t = door.open
		local eased = t * t * (3 - 2 * t)
		for _, leaf in door.leaves do
			leaf.part.CFrame = leaf.closed * CFrame.new(leaf.dir * door.slide * eased, 0, 0)
		end
		for _, leaf in door.swingLeaves do
			local turned = leaf.hinge * CFrame.Angles(0, leaf.dir * door.swing * eased, 0)
			for _, p in leaf.parts do
				p.part.CFrame = turned * p.rel
			end
		end
	end
end

function AutoDoorController.Init() end

function AutoDoorController.Start()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(model)
		task.defer(track, model)
	end)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(untrack)
	for _, model in CollectionService:GetTagged(TAG) do
		task.spawn(track, model)
	end
	RunService.RenderStepped:Connect(step)
end

return AutoDoorController
