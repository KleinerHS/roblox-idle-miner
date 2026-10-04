--!strict
-- Hält den vom Server bestätigten Spielerzustand für die Anzeige (docs/15 §9).
-- Nur lesen: Änderungen passieren ausschließlich auf dem Server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.Types)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)

local TAG = "StateController"

local StateController = {
	Changed = Signal.new() :: Signal.Signal<Types.StateSnapshot>,
}

local current: Types.StateSnapshot? = nil

local lastLogLine = ""

local function apply(snapshot: Types.StateSnapshot)
	current = snapshot
	-- Nur loggen, wenn sich die Kernwerte ändern (Produktions-Snapshots kommen alle 2 s)
	local line = `Cash {NumberFormat.cash(snapshot.Cash)} · Level {snapshot.MiningLevel} · XP {snapshot.MiningXP}/{snapshot.MiningXPRequired} · Rucksack {snapshot.EquippedBackpack} ({snapshot.BackpackCapacity})`
	if line ~= lastLogLine then
		lastLogLine = line
		Log.debug(TAG, line)
	end
	StateController.Changed:Fire(snapshot)
end

function StateController.Init()
	Net.on("StateSnapshot", function(snapshot: Types.StateSnapshot)
		apply(snapshot)
	end)
end

function StateController.Start()
	-- Falls der erste Snapshot vor dem Verbinden des Handlers gesendet wurde.
	if current == nil then
		local result = Net.invoke("GetState")
		-- Während des Wartens kann bereits ein Snapshot per Event angekommen sein.
		if current ~= nil then
			return
		end
		if result.success then
			apply(result.value)
		else
			Log.debug(TAG, `GetState: {result.code} (Daten noch nicht geladen, Snapshot folgt)`)
		end
	end
end

function StateController.Get(): Types.StateSnapshot?
	return current
end

return StateController
