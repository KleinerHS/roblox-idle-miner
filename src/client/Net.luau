--!strict
-- Client-Zugriff auf die zentral registrierten Remotes (ReplicatedStorage.Remotes).
-- Der Client erzeugt nie eigene Remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteDefinitions = require(Shared.Remotes)
local Result = require(Shared.Util.Result)

local folder = ReplicatedStorage:WaitForChild("Remotes")

local Net = {}

local function getRemote(name: string): Instance
	assert(RemoteDefinitions[name], `Unbekanntes Remote "{name}"`)
	return folder:WaitForChild(name)
end

function Net.on(name: string, handler: (...any) -> ()): RBXScriptConnection
	local remote = getRemote(name)
	assert(remote:IsA("RemoteEvent"), `{name} ist kein RemoteEvent`)
	return remote.OnClientEvent:Connect(handler)
end

function Net.fire(name: string, ...: any)
	local remote = getRemote(name)
	assert(remote:IsA("RemoteEvent"), `{name} ist kein RemoteEvent`)
	remote:FireServer(...)
end

-- Ruft eine RemoteFunction auf. Liefert immer ein Result, auch bei Verbindungsfehlern.
function Net.invoke(name: string, ...: any): Result.Result<any>
	local remote = getRemote(name)
	assert(remote:IsA("RemoteFunction"), `{name} ist keine RemoteFunction`)
	local args = table.pack(...)
	local ok, response = pcall(function()
		return remote:InvokeServer(table.unpack(args, 1, args.n))
	end)
	if not ok or typeof(response) ~= "table" then
		return Result.err(Result.Codes.INTERNAL_ERROR)
	end
	return response
end

return table.freeze(Net)
