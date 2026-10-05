--!strict
-- Fahren (docs/07 §13–15, §39): Der Fahrer besitzt die Physik seines Fahrzeugs; dieser
-- Controller übersetzt die Eingaben des VehicleSeat (W/S bzw. Pfeile, A/D) in Antrieb und
-- Lenkung. Kontrolliert statt arcadig: begrenzte Beschleunigung, Bremsen über den Motor,
-- Lenkwinkel nimmt mit der Geschwindigkeit ab, Rückwärts langsamer.
-- Kleine Fahranzeige: Geschwindigkeit, Ladung, RESET (zurück auf den Stellplatz).
-- Die normale Roblox-Kamera bleibt (docs/07 §15).
-- D-026: Fahrzeuge mit A-Chassis bringen Fahrphysik, Tacho und Sounds selbst mit; dann zeigt
-- dieser Controller nur Ladung und RESET (eigene Physik nur noch als Fallback).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Vehicles = require(Shared.Definitions.Vehicles)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Driving

-- Fahrgefühl (rein clientseitig, keine Wirtschaftswerte)
local MAX_STEER_SLOW = 32
local MAX_STEER_FAST = 12
local REVERSE_FACTOR = 0.4
local COAST_TORQUE_FACTOR = 0.25

local DrivingController = {}

local player = Players.LocalPlayer
local hud: ScreenGui
local speedLabel: TextLabel
local cargoLabel: TextLabel
local connection: RBXScriptConnection? = nil
local currentModel: Model? = nil

type Rig = {
	seat: VehicleSeat,
	chassis: BasePart,
	drive: { HingeConstraint },
	steer: { HingeConstraint },
	radius: number,
	maxSpeed: number,
	torque: number,
}

local function rigOf(model: Model): Rig?
	local seat = model:FindFirstChild("DriverSeat")
	local chassis = model.PrimaryPart
	local def = Vehicles.Get(model:GetAttribute("VehicleType") :: string? or "")
	local wheel = model:FindFirstChild("WheelRL")
	if not (seat and seat:IsA("VehicleSeat") and chassis and def and wheel and wheel:IsA("BasePart")) then
		return nil
	end
	local drive, steer = {}, {}
	for _, d in chassis:GetChildren() do
		if d:IsA("HingeConstraint") then
			if d.Name:sub(1, 5) == "Drive" then
				table.insert(drive, d)
			elseif d.Name:sub(1, 5) == "Steer" then
				table.insert(steer, d)
			end
		end
	end
	if #drive == 0 then
		return nil
	end
	return {
		seat = seat,
		chassis = chassis,
		drive = drive,
		steer = steer,
		radius = wheel.Size.Y / 2,
		maxSpeed = def.MaxSpeed,
		torque = drive[1].MotorMaxTorque,
	}
end

local function stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	local model = currentModel
	currentModel = nil
	hud.Enabled = false
	-- Parkbremse: Räder festhalten, Lenkung gerade
	local rig = model and rigOf(model)
	if rig then
		for _, h in rig.drive do
			h.AngularVelocity = 0
			h.MotorMaxTorque = rig.torque
		end
		for _, h in rig.steer do
			h.TargetAngle = 0
		end
	end
end

-- Nur Anzeige (A-Chassis fährt selbst): Ladung aktualisieren
local function startHudOnly(model: Model)
	stop()
	currentModel = model
	hud.Enabled = true
	speedLabel.Text = ""
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			stop()
			return
		end
		local cargo = model:GetAttribute("Cargo")
		local capacity = model:GetAttribute("Capacity")
		cargoLabel.Text = string.format(TEXT.Cargo, NumberFormat.withSeparators(if typeof(cargo) == "number" then cargo else 0), NumberFormat.withSeparators(if typeof(capacity) == "number" then capacity else 0))
	end)
end

local function start(model: Model)
	stop()
	local rig = rigOf(model)
	if not rig then
		return
	end
	currentModel = model
	hud.Enabled = true
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			stop()
			return
		end
		local throttle = rig.seat.ThrottleFloat
		local steerInput = rig.seat.SteerFloat
		local velocity = rig.chassis.CFrame:VectorToObjectSpace(rig.chassis.AssemblyLinearVelocity)
		local speed = -velocity.Z -- vorwärts positiv
		local target = if throttle >= 0 then throttle * rig.maxSpeed else throttle * rig.maxSpeed * REVERSE_FACTOR
		for _, h in rig.drive do
			-- Vorwärts = negative Drehung um die Fahrzeug-X-Achse
			h.AngularVelocity = -target / rig.radius
			h.MotorMaxTorque = if throttle == 0 then rig.torque * COAST_TORQUE_FACTOR else rig.torque
		end
		local t = math.clamp(math.abs(speed) / rig.maxSpeed, 0, 1)
		local maxAngle = MAX_STEER_SLOW + (MAX_STEER_FAST - MAX_STEER_SLOW) * t
		for _, h in rig.steer do
			h.TargetAngle = -steerInput * maxAngle
		end
		speedLabel.Text = string.format(TEXT.Speed, math.floor(math.abs(speed) + 0.5))
		local cargo = model:GetAttribute("Cargo")
		local capacity = model:GetAttribute("Capacity")
		cargoLabel.Text = string.format(TEXT.Cargo, NumberFormat.withSeparators(if typeof(cargo) == "number" then cargo else 0), NumberFormat.withSeparators(if typeof(capacity) == "number" then capacity else 0))
	end)
end

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not (humanoid and humanoid:IsA("Humanoid")) then
		return
	end
	humanoid.Seated:Connect(function(active, seatPart)
		if active and seatPart and seatPart:IsA("VehicleSeat") and (seatPart.Name == "DriverSeat" or seatPart.Name == "DriveSeat") then
			local model = seatPart:FindFirstAncestorOfClass("Model")
			-- A-Chassis-Teile liegen in Untermodellen: bis zum Fahrzeugmodell hochgehen
			while model and model:GetAttribute("OwnerUserId") == nil and model.Parent and model.Parent:IsA("Model") do
				model = model.Parent :: Model
			end
			if model and model:GetAttribute("OwnerUserId") == player.UserId then
				if model:FindFirstChild("A-Chassis Tune") then
					startHudOnly(model)
				else
					start(model)
				end
				return
			end
		end
		stop()
	end)
end

local function build()
	hud = Create("ScreenGui", {
		Name = "DrivingHud",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 12,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -140),
		Size = UDim2.fromOffset(330, 64),
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0.1,
		Parent = hud,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10) }),
	})
	speedLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(0.5, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 22,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		Parent = panel,
	})
	cargoLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(0.6, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		Parent = panel,
	})
	local reset: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(140, 40),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Font = UITheme.FontBold,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextPrimary,
		Text = TEXT.Reset,
		Parent = panel,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	reset.Activated:Connect(function()
		local model = currentModel
		local id = model and model:GetAttribute("VehicleId")
		if typeof(id) == "string" then
			local result = Net.invoke("ResetVehicle", id)
			if not result.success then
				NotificationController.Show("Warning", result.code)
			end
		end
	end)
	Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 4),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 13,
		TextColor3 = UITheme.Colors.TextSecondary,
		Text = TEXT.Exit,
		Parent = panel,
	})
end

function DrivingController.Init()
	build()
end

function DrivingController.Start()
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return DrivingController
