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

local DataSchema = require(script.Parent.Parent.Data.DataSchema)
local DataService = require(script.Parent.DataService)
local BuildingService = require(script.Parent.BuildingService)

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
	--   game.ServerStorage.DevTools.SetCapacities:Invoke(game.Players:GetPlayers()[1], 1000, 100)
	local setCapacities = Instance.new("BindableFunction")
	setCapacities.Name = "SetCapacities"
	setCapacities.OnInvoke = function(player: Player, storage: number, elevator: number): string
		local ok = DataService.Mutate(player, function(data)
			data.Storage.Capacity = math.max(1, math.floor(storage))
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

	folder.Parent = ServerStorage
end

function DevService.Start() end

return DevService
