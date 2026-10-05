--!strict
-- Bohranimation der Drills (docs/05 §28, §43): Bohrkopf dreht sich, Motorgehäuse vibriert
-- leicht, nur solange der Server Status "Running" meldet und der Drill in Sichtweite ist.
-- Rein lokal und rein visuell; Statuslampe und Partikel setzt der Server.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DrillAnimController = {}

local TAG_DRILL = "Drill"
-- Umdrehungen pro Sekunde des Bohrkopfs (rein optisch)
local SPIN_SPEED = math.rad(540)
local VIBRATION = 0.03
local MAX_DISTANCE = 120

type Anim = { model: Model, bit: Model, body: BasePart, bodyRest: CFrame }
local anims: { [Model]: Anim } = {}

local player = Players.LocalPlayer

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local bit = model:WaitForChild("Bit", 5)
	local body = model:WaitForChild("Body", 5)
	if not (bit and bit:IsA("Model") and body and body:IsA("BasePart")) then
		return
	end
	anims[model] = { model = model, bit = bit, body = body, bodyRest = body.CFrame }
end

local function untrack(model: Instance)
	if model:IsA("Model") then
		anims[model] = nil
	end
end

local function step(dt: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	for model, anim in anims do
		if model:GetAttribute("Status") ~= "Running" then
			continue
		end
		if (anim.body.Position - root.Position).Magnitude > MAX_DISTANCE then
			continue
		end
		-- Drehung um die eigene Achse (Pivot = Bohrachse, LookVector zur Wand)
		local delta = SPIN_SPEED * dt
		anim.bit:PivotTo(anim.bit:GetPivot() * CFrame.Angles(0, 0, delta))
		-- Leichte Vibration des Motorgehäuses
		local jitter = Vector3.new((math.random() - 0.5) * VIBRATION, (math.random() - 0.5) * VIBRATION, (math.random() - 0.5) * VIBRATION)
		anim.body.CFrame = anim.bodyRest + jitter
	end
end

function DrillAnimController.Init() end

function DrillAnimController.Start()
	CollectionService:GetInstanceAddedSignal(TAG_DRILL):Connect(function(model)
		task.spawn(track, model)
	end)
	CollectionService:GetInstanceRemovedSignal(TAG_DRILL):Connect(untrack)
	for _, model in CollectionService:GetTagged(TAG_DRILL) do
		task.spawn(track, model)
	end
	RunService.RenderStepped:Connect(step)
end

return DrillAnimController
