--!strict
-- Automatische Schiebetüren (Autohaus, Felix 2026-10-29). Rein optisch und lokal: Jede Tür
-- (Model mit Tag "AutoDoor") öffnet, sobald irgendein Spieler in Reichweite ist, und schließt
-- wieder, wenn niemand mehr davor steht. Die Flügel sind nicht kollidierend; der Server baut sie
-- geschlossen. Attribute am Model: Range (Studs), Slide (Weg je Flügel), Center (Vector3).
-- Attribute am Flügel: ClosedCF (CFrame), Dir (−1 / 1, Richtung entlang der lokalen X-Achse).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AutoDoorController = {}

local TAG = "AutoDoor"
-- Sekunden für ganz auf bzw. ganz zu
local OPEN_TIME = 0.6

type Leaf = { part: BasePart, closed: CFrame, dir: number }
type Door = { model: Model, leaves: { Leaf }, center: Vector3, range: number, slide: number, open: number }
local doors: { [Model]: Door } = {}

local function track(model: Instance)
	if not model:IsA("Model") then
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
	doors[model] = { model = model, leaves = leaves, center = center, range = range, slide = slide, open = 0 }
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
		if root and root:IsA("BasePart") and (root.Position - door.center).Magnitude <= door.range then
			return true
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
