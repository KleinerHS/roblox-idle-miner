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

	folder.Parent = ServerStorage
end

function DevService.Start() end

return DevService
