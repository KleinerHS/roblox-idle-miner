--!strict
-- Sichtbare Worker im Mine Shaft (docs/05 §4, §11–18, docs/15 §12–13). REINE DARSTELLUNG:
-- Die Wirtschaft rechnet ProductionService; hier wird nichts gutgeschrieben.
-- Figuren entstehen nur, solange der Besitzer in der betreffenden Mine ist (Performance).
--
-- Mining-Worker: steht am eigenen Slot vor der Erzwand und hackt (wenn Status "Working").
-- Transport-Worker: läuft mit Kiste zwischen Abholpunkt am Slot und Elevator-Treppe.
-- Steht an dem Slot ein Drill, holt er am Auswurfschacht des Drills ab (docs/05 §32).
-- Worker kollidieren nicht mit Spielern oder untereinander (Kollisionsgruppen, §18).

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mines = require(Shared.Definitions.Mines)
local Drills = require(Shared.Definitions.Drills)

local DrillModelBuilder = require(script.Parent.Parent.World.DrillModelBuilder)
local DataService = require(script.Parent.DataService)
local DrillService = require(script.Parent.DrillService)
local ElevatorService = require(script.Parent.ElevatorService)
local WorkerService = require(script.Parent.WorkerService)
local ProductionService = require(script.Parent.ProductionService)

local WorkerVisualService = {}

local GROUP_WORKERS = "Workers"
local GROUP_PLAYERS = "Players"

local VEST = Color3.fromRGB(236, 120, 30)
local PANTS = Color3.fromRGB(44, 58, 90)
local SKIN = Color3.fromRGB(204, 150, 110)
local HELMET = Color3.fromRGB(240, 196, 40)
local WOOD = Color3.fromRGB(120, 84, 52)
local IRON = Color3.fromRGB(70, 72, 76)
local CRATE = Color3.fromRGB(166, 120, 72)

type Visual = { model: Model, workerId: string, alive: boolean }
-- [player] = Liste der aktuell gezeigten Figuren
local visuals: { [Player]: { Visual } } = {}
local template: Model? = nil

local function setGroup(model: Instance, group: string)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = group
		end
	end
end

local function weldTo(part: BasePart, target: BasePart, offset: CFrame)
	part.CFrame = target.CFrame * offset
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = target
	w.Part1 = part
	w.Parent = part
end

local function newPart(name: string, size: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Einheitlicher Mining-Worker-Look: Warnweste, Arbeitshose, gelber Schutzhelm (Platzhalter)
local function getTemplate(): Model
	if template then
		return template
	end
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = SKIN
	desc.LeftArmColor = SKIN
	desc.RightArmColor = SKIN
	desc.TorsoColor = VEST
	desc.LeftLegColor = PANTS
	desc.RightLegColor = PANTS
	local rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	rig.Name = "Worker"
	local head = rig:FindFirstChild("Head") :: BasePart
	local helmet = newPart("Helmet", Vector3.new(1.35, 0.6, 1.35), HELMET, Enum.Material.SmoothPlastic)
	helmet.Shape = Enum.PartType.Ball
	weldTo(helmet, head, CFrame.new(0, 0.42, 0))
	helmet.Parent = rig
	local brim = newPart("HelmetBrim", Vector3.new(1.5, 0.08, 1.5), HELMET, Enum.Material.SmoothPlastic)
	weldTo(brim, head, CFrame.new(0, 0.28, -0.05))
	brim.Parent = rig
	local humanoid = rig:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = 10
	template = rig
	return rig
end

local function spawnWorker(room: Model, cf: CFrame, role: string): Model
	local rig = getTemplate():Clone()
	rig:PivotTo(cf)
	local hand = rig:FindFirstChild("RightHand") :: BasePart
	if role == "Mining" then
		local handle = newPart("PickHandle", Vector3.new(0.25, 3.2, 0.25), WOOD, Enum.Material.Wood)
		weldTo(handle, hand, CFrame.new(0, -0.2, -1.2) * CFrame.Angles(math.rad(90), 0, 0))
		handle.Parent = rig
		local head = newPart("PickHead", Vector3.new(2.4, 0.3, 0.3), IRON, Enum.Material.Metal)
		weldTo(head, handle, CFrame.new(0, 1.5, 0))
		head.Parent = rig
	end
	setGroup(rig, GROUP_WORKERS)
	rig.Parent = room
	return rig
end

-- Schlagbewegung über die rechte Schulter (unabhängig von Animations-Assets)
local function swingLoop(v: Visual, player: Player)
	local arm = v.model:FindFirstChild("RightUpperArm")
	local shoulder = arm and arm:FindFirstChild("RightShoulder")
	if not (shoulder and shoulder:IsA("Motor6D")) then
		return
	end
	local rest = shoulder.C0
	local raised = rest * CFrame.Angles(math.rad(150), 0, 0)
	while v.alive and v.model.Parent do
		if ProductionService.GetStatus(player)[v.workerId] == "Working" then
			TweenService:Create(shoulder, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { C0 = raised }):Play()
			task.wait(0.4)
			TweenService:Create(shoulder, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { C0 = rest }):Play()
			task.wait(1.25)
		else
			shoulder.C0 = rest
			task.wait(1)
		end
	end
end

local function carryLoop(v: Visual, player: Player, pickup: Vector3, dropoff: Vector3)
	local humanoid = v.model:FindFirstChildOfClass("Humanoid")
	local torso = v.model:FindFirstChild("UpperTorso")
	if not (humanoid and torso and torso:IsA("BasePart")) then
		return
	end
	local crate: Part? = nil
	local function setCarrying(on: boolean)
		if on and not crate then
			local c = newPart("Crate", Vector3.new(1.8, 1.4, 1.4), CRATE, Enum.Material.WoodPlanks)
			weldTo(c, torso, CFrame.new(0, -0.3, -1.2))
			c.CollisionGroup = GROUP_WORKERS
			c.Parent = v.model
			crate = c
		elseif not on and crate then
			crate:Destroy()
			crate = nil
		end
	end
	local function walk(to: Vector3)
		humanoid:MoveTo(to)
		local done = false
		local conn = humanoid.MoveToFinished:Connect(function()
			done = true
		end)
		local started = os.clock()
		while v.alive and not done and os.clock() - started < 12 do
			task.wait(0.2)
		end
		conn:Disconnect()
	end
	while v.alive and v.model.Parent do
		if ProductionService.GetStatus(player)[v.workerId] == "Working" then
			walk(pickup)
			task.wait(0.8)
			setCarrying(true)
			walk(dropoff)
			task.wait(0.8)
			setCarrying(false)
		else
			setCarrying(false)
			task.wait(1)
		end
	end
end

local function clear(player: Player)
	for _, v in visuals[player] or {} do
		v.alive = false
		v.model:Destroy()
	end
	visuals[player] = nil
end

local function show(player: Player)
	clear(player)
	local data = DataService.Get(player)
	local location = ElevatorService.GetLocation(player)
	local mine = Mines.Get(location)
	local room = ElevatorService.GetRoom(player)
	if not data or not mine or not room then
		return
	end
	local podium = room:FindFirstChild("Podium", true)
	if not (podium and podium:IsA("BasePart")) then
		return
	end
	local list: { Visual } = {}
	for _, worker in data.Workers do
		if worker.MineId == mine.Id then
			local zone = room:FindFirstChild(`MiningSlot{worker.Slot}`, true)
			if zone and zone:IsA("BasePart") then
				-- zone.CFrame: LookVector zeigt in den Raum, +Z lokal zur Wand
				local floorY = podium.Position.Y - podium.Size.Y / 2
				if worker.Role == "Mining" then
					local spot = zone.CFrame * CFrame.new(-3.5, 0, 2.5)
					local pos = Vector3.new(spot.Position.X, floorY + 3, spot.Position.Z)
					local wallDir = -zone.CFrame.LookVector
					local rig = spawnWorker(room, CFrame.lookAt(pos, pos + wallDir), "Mining")
					local v = { model = rig, workerId = worker.Id, alive = true }
					table.insert(list, v)
					task.spawn(swingLoop, v, player)
				else
					local pickupCF = zone.CFrame * CFrame.new(2, 0, -6)
					local pickup = Vector3.new(pickupCF.Position.X, floorY + 3, pickupCF.Position.Z)
					local drill = DrillService.DrillAt(data, mine.Id, worker.Slot)
					local def = drill and Drills.Get(drill.Type)
					if def then
						local output = DrillModelBuilder.outputPoint(DrillModelBuilder.slotCFrame(zone, floorY, def), def)
						pickup = Vector3.new(output.X, floorY + 3, output.Z)
					end
					local front = podium.CFrame * CFrame.new(0, 0, -podium.Size.Z / 2 - 7)
					local dropoff = Vector3.new(front.Position.X + (worker.Slot - 1.5) * 4, floorY + 3, front.Position.Z)
					local rig = spawnWorker(room, CFrame.new(pickup), "Transport")
					local v = { model = rig, workerId = worker.Id, alive = true }
					table.insert(list, v)
					task.spawn(carryLoop, v, player, pickup, dropoff)
				end
			end
		end
	end
	visuals[player] = list
end

function WorkerVisualService.Init()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP_WORKERS)
	end)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP_PLAYERS)
	end)
	PhysicsService:CollisionGroupSetCollidable(GROUP_WORKERS, GROUP_WORKERS, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_WORKERS, GROUP_PLAYERS, false)
	-- Spieler blockieren sich nicht gegenseitig (docs/13 §4, Phase 9)
	PhysicsService:CollisionGroupSetCollidable(GROUP_PLAYERS, GROUP_PLAYERS, false)
end

function WorkerVisualService.Start()
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			setGroup(character, GROUP_PLAYERS)
			character.DescendantAdded:Connect(function(d)
				if d:IsA("BasePart") then
					d.CollisionGroup = GROUP_PLAYERS
				end
			end)
		end)
		if player.Character then
			setGroup(player.Character, GROUP_PLAYERS)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(clear)

	ElevatorService.LocationChanged:Connect(function(player)
		task.spawn(show, player)
	end)
	WorkerService.WorkersChanged:Connect(function(player)
		if Mines.Get(ElevatorService.GetLocation(player)) then
			task.spawn(show, player)
		end
	end)
	DrillService.DrillsChanged:Connect(function(player)
		if Mines.Get(ElevatorService.GetLocation(player)) then
			task.spawn(show, player)
		end
	end)
end

return WorkerVisualService
