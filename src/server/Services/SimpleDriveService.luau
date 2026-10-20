--!strict
-- Sehr einfache Fahrsteuerung für Lastzug-Zugmaschinen (Felix 2026-10-20: „mach es sehr einfach,
-- es muss nicht realistisch sein, nur gut zu fahren“). Gilt für Modelle mit Attribut SimpleDrive
-- (VehicleModelBuilder.buildSimple). Der Server rechnet alles (kein Netzwerkbesitz beim Spieler,
-- dadurch kein Ruckeln zwischen Zugmaschine und Anhängern):
--   * W/S aus dem Fahrersitz: beschleunigen, bremsen, rückwärts
--   * A/D: Lenkwinkel, der mit dem Tempo kleiner wird; Drehung wie ein Fahrzeug mit Radstand
--   * Ohne Fahrer bremst er bis zum Stillstand
-- Die Anhänger hängen physikalisch an der Zugmaschine (TrailerBuilder) und werden mitgezogen.

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Vehicles = require(Shared.Definitions.Vehicles)

local SimpleDriveService = {}

-- Fahrwerte (Studs, Sekunden). TODO_BALANCE: Feinabstimmung nach Felix' Fahrtest
local ACCELERATION = 9
local BRAKE = 24
local COAST = 5
local REVERSE_FACTOR = 0.35
local STEER_MAX = math.rad(40) -- Lenkwinkel im Stand
local STEER_AT_SPEED = math.rad(14) -- Lenkwinkel bei Höchsttempo
local STEER_RATE = math.rad(90) -- wie schnell das Lenkrad einschlägt (pro Sekunde)

type State = { speed: number, yaw: number, steer: number }
local states: { [Model]: State } = {}

local function yawOf(cf: CFrame): number
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local function step(model: Model, dt: number)
	local root = model.PrimaryPart
	local seat = model:FindFirstChild("DriveSeat")
	local drive = root and root:FindFirstChild("Drive")
	local heading = root and root:FindFirstChild("Heading")
	if not (root and seat and seat:IsA("VehicleSeat") and drive and drive:IsA("LinearVelocity") and heading and heading:IsA("AlignOrientation")) then
		return
	end
	local def = Vehicles.Get(model:GetAttribute("VehicleType") :: string)
	local maxSpeed = if def then def.MaxSpeed else 30
	local wheelbase = (model:GetAttribute("Wheelbase") :: number?) or 16

	local state = states[model]
	local actualYaw = yawOf(root.CFrame)
	if not state then
		state = { speed = 0, yaw = actualYaw, steer = 0 }
		states[model] = state
	end
	-- Von außen versetzt (Reset, Teleport): Richtung übernehmen
	if math.abs(math.atan2(math.sin(actualYaw - state.yaw), math.cos(actualYaw - state.yaw))) > 0.6 then
		state.yaw = actualYaw
		state.speed = 0
	end

	local throttle = if seat.Occupant then seat.ThrottleFloat else 0
	local steerInput = if seat.Occupant then seat.SteerFloat else 0

	-- Tempo
	local speed = state.speed
	if throttle > 0 then
		speed = if speed < 0 then math.min(0, speed + BRAKE * dt) else math.min(maxSpeed, speed + ACCELERATION * throttle * dt)
	elseif throttle < 0 then
		speed = if speed > 0 then math.max(0, speed - BRAKE * dt) else math.max(-maxSpeed * REVERSE_FACTOR, speed - ACCELERATION * dt)
	else
		local drag = (if seat.Occupant then COAST else BRAKE) * dt
		speed = if speed > 0 then math.max(0, speed - drag) else math.min(0, speed + drag)
	end
	-- Hängt er fest (Wand), nicht weiter „Schwung“ aufbauen
	local actual = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
	if math.abs(speed) > actual + 6 then
		speed = math.sign(speed) * (actual + 6)
	end
	state.speed = speed

	-- Lenkung: Einschlag folgt der Eingabe, Maximalwinkel nimmt mit dem Tempo ab
	local maxSteer = STEER_MAX + (STEER_AT_SPEED - STEER_MAX) * math.clamp(math.abs(speed) / maxSpeed, 0, 1)
	local target = -steerInput * maxSteer
	local delta = math.clamp(target - state.steer, -STEER_RATE * dt, STEER_RATE * dt)
	state.steer += delta
	state.yaw += speed / wheelbase * math.tan(state.steer) * dt

	local orientation = CFrame.Angles(0, state.yaw, 0)
	heading.CFrame = orientation
	local forward = orientation.LookVector
	drive.PlaneVelocity = Vector2.new(forward.X, forward.Z) * speed
end

function SimpleDriveService.Init() end

function SimpleDriveService.Start()
	RunService.Heartbeat:Connect(function(dt)
		local folder = workspace:FindFirstChild("Vehicles")
		if not folder then
			return
		end
		for _, model in folder:GetChildren() do
			if model:IsA("Model") and model:GetAttribute("SimpleDrive") then
				step(model, dt)
			end
		end
		for model in states do
			if not model.Parent then
				states[model] = nil
			end
		end
	end)
end

return SimpleDriveService
