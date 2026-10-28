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

-- 3D-Modelle (D-075): Bohrkopfträger dreht um sein lokales X (15–30 U/min laut Paket, hier etwas
-- schneller für die Spielansicht), Schneidrollen ab MK20 gegenläufig um ihr eigenes X
local ROTOR_SPEED = math.rad(180)
local ROLLER_SPEED = math.rad(-360)

type Anim = { model: Model, bit: Model?, body: BasePart?, bodyRest: CFrame?, rotor: Model?, rollers: { Model }, ref: BasePart }
local anims: { [Model]: Anim } = {}

local player = Players.LocalPlayer

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	-- 3D-Vorlage mit Rotor (D-075)
	local rotor = model:WaitForChild("Rotor", 2)
	if rotor and rotor:IsA("Model") then
		local rollers = {}
		for _, child in rotor:GetChildren() do
			if child:IsA("Model") and string.sub(child.Name, 1, 7) == "Roller_" then
				table.insert(rollers, child)
			end
		end
		local ref = model:FindFirstChild("StatusLight") or rotor:FindFirstChildWhichIsA("BasePart", true)
		if ref and ref:IsA("BasePart") then
			anims[model] = { model = model, rotor = rotor, rollers = rollers, ref = ref }
		end
		return
	end
	local bit = model:WaitForChild("Bit", 5)
	local body = model:WaitForChild("Body", 5)
	if not (bit and bit:IsA("Model") and body and body:IsA("BasePart")) then
		return
	end
	anims[model] = { model = model, bit = bit, body = body, bodyRest = body.CFrame, rollers = {}, ref = body }
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
		if (anim.ref.Position - root.Position).Magnitude > MAX_DISTANCE then
			continue
		end
		local rotor = anim.rotor
		if rotor then
			-- erst der ganze Träger (Rollen drehen mit), dann jede Rolle um ihre eigene Achse
			rotor:PivotTo(rotor:GetPivot() * CFrame.Angles(ROTOR_SPEED * dt, 0, 0))
			for _, roller in anim.rollers do
				roller:PivotTo(roller:GetPivot() * CFrame.Angles(ROLLER_SPEED * dt, 0, 0))
			end
			continue
		end
		local bit, body, bodyRest = anim.bit, anim.body, anim.bodyRest
		if not (bit and body and bodyRest) then
			continue
		end
		-- Drehung um die eigene Achse (Pivot = Bohrachse, LookVector zur Wand)
		local delta = SPIN_SPEED * dt
		bit:PivotTo(bit:GetPivot() * CFrame.Angles(0, 0, delta))
		-- Leichte Vibration des Motorgehäuses
		local jitter = Vector3.new((math.random() - 0.5) * VIBRATION, (math.random() - 0.5) * VIBRATION, (math.random() - 0.5) * VIBRATION)
		body.CFrame = bodyRest + jitter
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
