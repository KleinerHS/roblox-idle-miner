--!strict
-- Erzeugt alle Remotes aus Shared/Remotes und kapselt Server-Handler mit
-- Richtungsprüfung, Rate-Limit und Fehlerbehandlung (docs/15 §8).
-- Typ-/Wertprüfung der Argumente macht jeder Handler selbst mit Util/Validate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteDefinitions = require(Shared.Remotes)
local Result = require(Shared.Util.Result)
local Log = require(Shared.Util.Log)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)

local TAG = "RemoteService"

local RemoteService = {}

local folder: Folder
local events: { [string]: RemoteEvent } = {}
local functions: { [string]: RemoteFunction } = {}

local function getDefinition(name: string): RemoteDefinitions.RemoteDefinition
	local def = RemoteDefinitions[name]
	assert(def, `Unbekanntes Remote "{name}" – in Shared/Remotes eintragen`)
	return def
end

local function passesRateLimit(player: Player, name: string, def: RemoteDefinitions.RemoteDefinition): boolean
	local limit = def.RateLimit
	if not limit then
		return true
	end
	if RateLimiter.allow(player, name, limit.Count, limit.Window) then
		return true
	end
	Log.debug(TAG, `Rate-Limit: {player.Name} → {name}`)
	return false
end

function RemoteService.Init()
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		existing:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "Remotes"

	for name, def in RemoteDefinitions do
		if def.Kind == "Event" then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
			events[name] = remote
			if def.Direction == "ServerToClient" then
				-- Client-Aufrufe verwerfen, damit sich keine Event-Warteschlange aufbaut.
				remote.OnServerEvent:Connect(function() end)
			end
		else
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
			functions[name] = remote
		end
	end

	-- Erst nach vollständigem Aufbau sichtbar machen, damit der Client nie einen halben Ordner sieht.
	folder.Parent = ReplicatedStorage

	Players.PlayerRemoving:Connect(function(player)
		RateLimiter.clear(player)
	end)
end

function RemoteService.Start() end

-- Client → Server Event. Handler bekommt ungeprüfte Argumente (unknown) und muss validieren.
function RemoteService.OnEvent(name: string, handler: (player: Player, ...unknown) -> ())
	local def = getDefinition(name)
	assert(def.Kind == "Event" and def.Direction == "ClientToServer", `{name} ist kein ClientToServer-Event`)
	events[name].OnServerEvent:Connect(function(player: Player, ...: unknown)
		if not passesRateLimit(player, name, def) then
			return
		end
		local ok, message = pcall(handler, player, ...)
		if not ok then
			Log.error(TAG, `Handler {name} fehlgeschlagen ({player.Name}): {message}`)
		end
	end)
end

-- Client → Server Function. Rückgabe ist immer ein Result.
function RemoteService.OnInvoke(name: string, handler: (player: Player, ...unknown) -> Result.Result<any>)
	local def = getDefinition(name)
	assert(def.Kind == "Function" and def.Direction == "ClientToServer", `{name} ist keine ClientToServer-Function`)
	functions[name].OnServerInvoke = function(player: Player, ...: unknown): Result.Result<any>
		if not passesRateLimit(player, name, def) then
			return Result.err(Result.Codes.RATE_LIMITED)
		end
		local ok, response = pcall(handler, player, ...)
		if not ok then
			Log.error(TAG, `Handler {name} fehlgeschlagen ({player.Name}): {response}`)
			return Result.err(Result.Codes.INTERNAL_ERROR)
		end
		return response
	end
end

function RemoteService.FireClient(name: string, player: Player, ...: any)
	local def = getDefinition(name)
	assert(def.Kind == "Event" and def.Direction == "ServerToClient", `{name} ist kein ServerToClient-Event`)
	events[name]:FireClient(player, ...)
end

function RemoteService.FireAllClients(name: string, ...: any)
	local def = getDefinition(name)
	assert(def.Kind == "Event" and def.Direction == "ServerToClient", `{name} ist kein ServerToClient-Event`)
	events[name]:FireAllClients(...)
end

return RemoteService
