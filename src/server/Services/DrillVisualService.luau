--!strict
-- Sichtbare Drills im Mine Shaft (docs/05 §25, §28–29). REINE DARSTELLUNG: Die Produktion
-- rechnet ProductionService. Modelle entstehen nur, solange der Besitzer in der betreffenden
-- Mine ist (wie die Worker-Figuren, docs/15 §12–13).
--
-- Server setzt Statuslampe, Partikel und das Attribut "Status"; Bohrkopf-Drehung und
-- Vibration macht der Client (DrillAnimController) nur bei Status "Running" (docs/05 §43).
-- Drills kollidieren mit Spielern, nicht mit Worker-Figuren (Kollisionsgruppe "Machines").

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mines = require(Shared.Definitions.Mines)
local Drills = require(Shared.Definitions.Drills)

local DrillModelBuilder = require(script.Parent.Parent.World.DrillModelBuilder)
local DataService = require(script.Parent.DataService)
local ElevatorService = require(script.Parent.ElevatorService)
local ProductionService = require(script.Parent.ProductionService)
local DrillService = require(script.Parent.DrillService)

local DrillVisualService = {}

local GROUP_MACHINES = "Machines"
local GROUP_WORKERS = "Workers"
local TAG_DRILL = "Drill"

-- [player] = { [drillId] = Model }
local shown: { [Player]: { [string]: Model } } = {}

local function clear(player: Player)
	for _, model in shown[player] or {} do
		model:Destroy()
	end
	shown[player] = nil
end

local function applyStatus(player: Player, status: { [string]: string })
	for drillId, model in shown[player] or {} do
		DrillModelBuilder.setStatus(model, status[drillId] or "Idle")
	end
end

local function show(player: Player)
	clear(player)
	local data = DataService.Get(player)
	local mine = Mines.Get(ElevatorService.GetLocation(player))
	local room = ElevatorService.GetRoom(player)
	if not data or not mine or not room then
		return
	end
	local podium = room:FindFirstChild("Podium", true)
	if not (podium and podium:IsA("BasePart")) then
		return
	end
	local floorY = podium.Position.Y - podium.Size.Y / 2
	local folder = room:FindFirstChild("Drills")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Drills"
		folder.Parent = room
	end
	local list: { [string]: Model } = {}
	for _, drill in data.Machines.Drills do
		local def = Drills.Get(drill.Type)
		local zone = drill.Slot and room:FindFirstChild(`MiningSlot{drill.Slot}`, true)
		if drill.MineId == mine.Id and def and zone and zone:IsA("BasePart") then
			local model = DrillModelBuilder.build(def, DrillModelBuilder.slotCFrame(zone, floorY, def))
			model.Name = drill.Id
			model:SetAttribute("DrillId", drill.Id)
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					d.CollisionGroup = GROUP_MACHINES
				end
			end
			CollectionService:AddTag(model, TAG_DRILL)
			model.Parent = folder
			list[drill.Id] = model
		end
	end
	shown[player] = list
	applyStatus(player, ProductionService.GetStatus(player))
end

function DrillVisualService.Init()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP_MACHINES)
	end)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP_WORKERS)
	end)
	PhysicsService:CollisionGroupSetCollidable(GROUP_MACHINES, GROUP_WORKERS, false)
end

function DrillVisualService.Start()
	Players.PlayerRemoving:Connect(clear)
	ElevatorService.LocationChanged:Connect(function(player)
		task.spawn(show, player)
	end)
	DrillService.DrillsChanged:Connect(function(player)
		task.spawn(show, player)
	end)
	ProductionService.StatusChanged:Connect(applyStatus)
end

return DrillVisualService
