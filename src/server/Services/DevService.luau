--!strict
-- Test-Werkzeuge NUR in Roblox Studio (im Live-Spiel wird nichts angelegt).
-- ServerStorage.DevTools.ResetProgress (BindableFunction): setzt den Spielstand eines
-- Spielers auf das Default-Profil zurück, damit der Ablauf ab Join erneut getestet werden
-- kann. Aufruf z. B. in der Server-Befehlszeile:
--   game.ServerStorage.DevTools.ResetProgress:Invoke(game.Players:GetPlayers()[1])

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Shared").Util.Log)
local BalanceConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.BalanceConfig)
local Vehicles = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Vehicles)

local DataSchema = require(script.Parent.Parent.Data.DataSchema)
local DataService = require(script.Parent.DataService)
local BuildingService = require(script.Parent.BuildingService)
local OfflineService = require(script.Parent.OfflineService)
local VehicleService = require(script.Parent.VehicleService)
local PlotService = require(script.Parent.PlotService)
local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)

local TAG = "DevService"

local DevService = {}

function DevService.Init()
	if not RunService:IsStudio() then
		return
	end
	local existing = ServerStorage:FindFirstChild("DevTools")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "DevTools"

	local reset = Instance.new("BindableFunction")
	reset.Name = "ResetProgress"
	reset.OnInvoke = function(player: Player): string
		local template = DataSchema.getTemplate()
		local ok = DataService.Mutate(player, function(data)
			local joins = data.Stats.JoinCount
			local firstJoin = data.Stats.FirstJoinTime
			for key in data :: any do
				(data :: any)[key] = nil
			end
			for key, value in template :: any do
				(data :: any)[key] = value
			end
			data.Stats.JoinCount = joins
			data.Stats.FirstJoinTime = firstJoin
		end)
		if not ok then
			return "Profil nicht geladen"
		end
		BuildingService.Rebuild(player)
		Log.info(TAG, `Spielstand von {player.Name} zurückgesetzt`)
		return "ok"
	end
	reset.Parent = folder

	-- Rucksack mit Kohle füllen (zum Testen von "Backpack full"):
	--   game.ServerStorage.DevTools.FillBackpack:Invoke(game.Players:GetPlayers()[1], 95)
	local fill = Instance.new("BindableFunction")
	fill.Name = "FillBackpack"
	fill.OnInvoke = function(player: Player, amount: number): string
		local ok = DataService.Mutate(player, function(data)
			data.Backpack.ore_coal = math.max(0, math.floor(amount))
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	fill.Parent = folder

	-- Geld setzen (zum Testen von Käufen):
	--   game.ServerStorage.DevTools.SetCash:Invoke(game.Players:GetPlayers()[1], 5000)
	local setCash = Instance.new("BindableFunction")
	setCash.Name = "SetCash"
	setCash.OnInvoke = function(player: Player, amount: number): string
		local ok = DataService.Mutate(player, function(data)
			data.Cash = math.max(0, math.floor(amount))
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	setCash.Parent = folder

	-- Mining Level setzen (XP im Level = 0):
	--   game.ServerStorage.DevTools.SetLevel:Invoke(game.Players:GetPlayers()[1], 5)
	local setLevel = Instance.new("BindableFunction")
	setLevel.Name = "SetLevel"
	setLevel.OnInvoke = function(player: Player, level: number): string
		local ok = DataService.Mutate(player, function(data)
			data.MiningLevel = math.max(1, math.floor(level))
			data.MiningXP = 0
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	setLevel.Parent = folder

	-- Lager- und Elevator-Kapazität setzen (zum Testen der Upgrades):
	-- storage = Lagerkapazität, wird auf ganze Kisten (D-037) aufgerundet:
	--   game.ServerStorage.DevTools.SetCapacities:Invoke(game.Players:GetPlayers()[1], 5000, 100)
	local setCapacities = Instance.new("BindableFunction")
	setCapacities.Name = "SetCapacities"
	setCapacities.OnInvoke = function(player: Player, storage: number, elevator: number): string
		local ok = DataService.Mutate(player, function(data)
			local size = BalanceConfig.Storage.CrateSize
			data.Storage.Crates = math.clamp(math.ceil(storage / size), 0, BalanceConfig.Storage.MaxCrates)
			data.Storage.Capacity = data.Storage.Crates * size
			data.Production.ElevatorCapacity = math.max(1, math.floor(elevator))
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	setCapacities.Parent = folder

	-- Alle gekauften Drills entfernen (Inventar und platzierte):
	--   game.ServerStorage.DevTools.ClearDrills:Invoke(game.Players:GetPlayers()[1])
	local clearDrills = Instance.new("BindableFunction")
	clearDrills.Name = "ClearDrills"
	clearDrills.OnInvoke = function(player: Player): string
		local ok = DataService.Mutate(player, function(data)
			table.clear(data.Machines.Drills)
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	clearDrills.Parent = folder

	-- Alle Fahrzeuge entfernen (Fuhrpark und Ladung):
	--   game.ServerStorage.DevTools.ClearVehicles:Invoke(game.Players:GetPlayers()[1])
	local clearVehicles = Instance.new("BindableFunction")
	clearVehicles.Name = "ClearVehicles"
	clearVehicles.OnInvoke = function(player: Player): string
		local ok = DataService.Mutate(player, function(data)
			table.clear(data.Vehicles.Owned)
		end)
		for _, model in workspace:FindFirstChild("Vehicles") and workspace.Vehicles:GetChildren() or {} do
			if model:GetAttribute("OwnerUserId") == player.UserId then
				model:Destroy()
			end
		end
		return if ok then "ok (Rejoin für saubere Garage)" else "Profil nicht geladen"
	end
	clearVehicles.Parent = folder

	-- Fahrzeug geben/nehmen (nur zum Testen neuer Karosserien):
	--   game.ServerStorage.DevTools.GiveVehicle:Invoke(game.Players:GetPlayers()[1], "vehicle_truck")
	local giveVehicle = Instance.new("BindableFunction")
	giveVehicle.Name = "GiveVehicle"
	giveVehicle.OnInvoke = function(player: Player, typeId: string): string
		local newId = ""
		local ok = DataService.Mutate(player, function(data)
			data.Vehicles.Seq += 1
			newId = `v{data.Vehicles.Seq}`
			data.Vehicles.Owned[newId] = { Id = newId, Type = typeId, Cargo = {} }
		end)
		return if ok then newId else "Profil nicht geladen"
	end
	giveVehicle.Parent = folder
	-- Alle Fahrzeugtypen geben, die der Spieler noch nicht hat (Felix-Test):
	--   game.ServerStorage.DevTools.GiveAllVehicles:Invoke(game.Players:GetPlayers()[1])
	local giveAll = Instance.new("BindableFunction")
	giveAll.Name = "GiveAllVehicles"
	giveAll.OnInvoke = function(player: Player): string
		local added = {}
		local ok = DataService.Mutate(player, function(data)
			local have: { [string]: boolean } = {}
			for _, v in data.Vehicles.Owned do
				have[v.Type] = true
			end
			for _, def in Vehicles.List do
				if not have[def.Id] then
					data.Vehicles.Seq += 1
					local newId = `v{data.Vehicles.Seq}`
					data.Vehicles.Owned[newId] = { Id = newId, Type = def.Id, Cargo = {} }
					table.insert(added, `{def.Id}={newId}`)
				end
			end
		end)
		if not ok then
			return "Profil nicht geladen"
		end
		return if #added > 0 then table.concat(added, ", ") else "alle Fahrzeuge schon vorhanden"
	end
	giveAll.Parent = folder
	local takeVehicle = Instance.new("BindableFunction")
	takeVehicle.Name = "TakeVehicle"
	takeVehicle.OnInvoke = function(player: Player, vehicleId: string): string
		local ok = DataService.Mutate(player, function(data)
			data.Vehicles.Owned[vehicleId] = nil
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	takeVehicle.Parent = folder
	-- Ausgeparktes Fahrzeug an eine Stelle des eigenen Grundstücks setzen (lokal X/Z, Blickrichtung
	-- in Grad: 0 = zur Straße/-Z, 90 = -X Richtung Verladestraße):
	--   game.ServerStorage.DevTools.PlaceVehicle:Invoke(game.Players:GetPlayers()[1], "v10", 60, -41, 90)
	local placeVehicle = Instance.new("BindableFunction")
	placeVehicle.Name = "PlaceVehicle"
	placeVehicle.OnInvoke = function(player: Player, vehicleId: string, x: number, z: number, yaw: number): string
		local plotId = PlotService.GetPlotId(player)
		if not plotId then
			return "kein Grundstück"
		end
		local cf = PlotBuilder.getPlotCFrame(plotId) * CFrame.new(x, 1.45, z) * CFrame.Angles(0, math.rad(yaw), 0)
		return if VehicleService.SpawnAt(player, vehicleId, cf) then "ok" else "Fahrzeug nicht ausgeparkt"
	end
	placeVehicle.Parent = folder

	-- Bauschritt setzen/entfernen (z. B. Garage wieder abbauen):
	--   game.ServerStorage.DevTools.SetBuilding:Invoke(game.Players:GetPlayers()[1], "build_garage", false)
	local setBuilding = Instance.new("BindableFunction")
	setBuilding.Name = "SetBuilding"
	setBuilding.OnInvoke = function(player: Player, stepId: string, built: boolean): string
		local ok = DataService.Mutate(player, function(data)
			data.Buildings[stepId] = if built then true else nil
		end)
		BuildingService.Rebuild(player)
		return if ok then "ok" else "Profil nicht geladen"
	end
	setBuilding.Parent = folder

	-- Material ins Lager legen (ohne Kapazitätsprüfung, nur zum Testen):
	--   game.ServerStorage.DevTools.AddStorage:Invoke(game.Players:GetPlayers()[1], "ore_copper", 200)
	local addStorage = Instance.new("BindableFunction")
	addStorage.Name = "AddStorage"
	addStorage.OnInvoke = function(player: Player, materialId: string, amount: number): string
		local ok = DataService.Mutate(player, function(data)
			local n = (data.Storage.Items[materialId] or 0) + math.floor(amount)
			data.Storage.Items[materialId] = if n > 0 then n else nil
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	addStorage.Parent = folder

	-- Ladung eines Fahrzeugs zurück ins Lager legen (zum Testen des Verladeturms):
	--   game.ServerStorage.DevTools.UnloadVehicle:Invoke(game.Players:GetPlayers()[1], "v4")
	local unload = Instance.new("BindableFunction")
	unload.Name = "UnloadVehicle"
	unload.OnInvoke = function(player: Player, vehicleId: string): string
		local moved = 0
		local ok = DataService.Mutate(player, function(data)
			local record = data.Vehicles.Owned[vehicleId]
			if not record then
				return
			end
			for material, n in record.Cargo do
				data.Storage.Items[material] = (data.Storage.Items[material] or 0) + n
				moved += n
			end
			record.Cargo = {}
		end)
		return if ok then `ok ({moved} zurück ins Lager)` else "Profil nicht geladen"
	end
	unload.Parent = folder

	-- Gekaufte Mine setzen/entfernen (ab Mine 03):
	--   game.ServerStorage.DevTools.SetMineUnlocked:Invoke(game.Players:GetPlayers()[1], "mine_003", false)
	local setMine = Instance.new("BindableFunction")
	setMine.Name = "SetMineUnlocked"
	setMine.OnInvoke = function(player: Player, mineId: string, unlocked: boolean): string
		local ok = DataService.Mutate(player, function(data)
			data.UnlockedMines[mineId] = if unlocked then true else nil
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	setMine.Parent = folder

	-- Förderbänder und Schmelzer-Inhalt leeren (Trichter, Ablage, Priorität):
	--   game.ServerStorage.DevTools.ClearSmelter:Invoke(game.Players:GetPlayers()[1])
	local clearSmelter = Instance.new("BindableFunction")
	clearSmelter.Name = "ClearSmelter"
	clearSmelter.OnInvoke = function(player: Player): string
		local ok = DataService.Mutate(player, function(data)
			table.clear(data.Machines.Conveyors)
			data.Smelter = { Input = {}, Output = {}, Priority = "" }
		end)
		return if ok then "ok" else "Profil nicht geladen"
	end
	clearSmelter.Parent = folder

	-- Offline-Zeit nachrechnen wie beim Login, inkl. Fenster „WHILE YOU WERE AWAY“ (Phase 10):
	--   game.ServerStorage.DevTools.SimulateOffline:Invoke(game.Players:GetPlayers()[1], 1800)
	local simulate = Instance.new("BindableFunction")
	simulate.Name = "SimulateOffline"
	simulate.OnInvoke = function(player: Player, seconds: number): string
		local summary = OfflineService.Apply(player, seconds)
		return if summary then `ok ({summary.Seconds} s)` else "nichts zu tun"
	end
	simulate.Parent = folder

	folder.Parent = ServerStorage
end

function DevService.Start() end

return DevService
