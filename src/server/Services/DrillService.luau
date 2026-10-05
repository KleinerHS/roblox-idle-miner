--!strict
-- Drills platzieren und entfernen (docs/05 §24–26, docs/10 §30–32, §38–39).
-- Ablauf: Spieler steht in seiner Mine am Mining-Slot → Prompt "Manage Slot" → Server prüft
-- und öffnet das Slot-Fenster → Client wählt einen verfügbaren Drill-Typ → Server platziert
-- ein freies Exemplar. Entfernen am Slot oder am Laptop; der Drill geht zurück ins Inventar,
-- Erz im Slot-Puffer bleibt erhalten (kein Verlust, keine Duplikation).
-- Ein Mining-Slot ist leer, hat einen Worker ODER einen Drill (docs/05 §26).

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mines = require(Shared.Definitions.Mines)
local Drills = require(Shared.Definitions.Drills)
local WorkerRoles = require(Shared.Definitions.WorkerRoles)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local ElevatorService = require(script.Parent.ElevatorService)
local WorkerService = require(script.Parent.WorkerService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "DrillService"

local DrillService = {
	-- (player) nachdem ein Drill platziert oder entfernt wurde
	DrillsChanged = Signal.new() :: Signal.Signal<Player>,
}

local function miningSlots(): number
	local role = WorkerRoles.Get("Mining")
	return if role then role.Slots else 0
end

local function workerAt(data: Types.PlayerData, mineId: string, slot: number): boolean
	for _, worker in data.Workers do
		if worker.MineId == mineId and worker.Role == "Mining" and worker.Slot == slot then
			return true
		end
	end
	return false
end

function DrillService.DrillAt(data: Types.PlayerData, mineId: string, slot: number): Types.DrillRecord?
	for _, drill in data.Machines.Drills do
		if drill.MineId == mineId and drill.Slot == slot then
			return drill
		end
	end
	return nil
end

-- Freies Exemplar eines Typs, deterministisch das mit der kleinsten Nummer
local function availableOfType(data: Types.PlayerData, typeId: string): Types.DrillRecord?
	local best: Types.DrillRecord? = nil
	local bestNumber = math.huge
	for _, drill in data.Machines.Drills do
		if drill.Type == typeId and drill.MineId == nil then
			local n = tonumber(drill.Id:sub(2)) or 0
			if n < bestNumber then
				best, bestNumber = drill, n
			end
		end
	end
	return best
end

local function place(player: Player, mineId: unknown, slot: unknown, typeId: unknown)
	if typeof(mineId) ~= "string" or typeof(slot) ~= "number" or typeof(typeId) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local mine = Mines.Get(mineId)
	if not mine or not Drills.Get(typeId) or slot % 1 ~= 0 or slot < 1 or slot > miningSlots() then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not data.Buildings.build_storage then
		return Result.err(Result.Codes.STORAGE_REQUIRED)
	end
	-- Nur in der eigenen Mine, in der man gerade steht (docs/10 §31: Enter Mine)
	if ElevatorService.GetLocation(player) ~= mine.Id then
		return Result.err(Result.Codes.NOT_IN_MINE)
	end
	if not Mines.IsAccessible(mine, data.MiningLevel) then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if workerAt(data, mine.Id, slot :: number) or DrillService.DrillAt(data, mine.Id, slot :: number) then
		return Result.err(Result.Codes.SLOT_TAKEN)
	end
	local drill = availableOfType(data, typeId :: string)
	if not drill then
		return Result.err(Result.Codes.NOT_OWNED)
	end

	-- Prüfung und Änderung ohne Yield dazwischen → kein Doppel-Platzieren durch Spam
	local id = drill.Id
	DataService.Mutate(player, function(d)
		local record = d.Machines.Drills[id]
		record.MineId = mine.Id
		record.Slot = slot :: number
	end)
	DataService.RequestSave(player)
	Log.debug(TAG, `{player.Name} platziert {typeId} ({id}) in {mine.Id} Slot {slot}`)
	DrillService.DrillsChanged:Fire(player)
	local def = Drills.Get(typeId :: string)
	RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "DRILL_PLACED", Args = { Name = if def then def.DisplayName else typeId } })
	return Result.ok(id)
end

local function remove(player: Player, drillId: unknown)
	if typeof(drillId) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	local drill = data.Machines.Drills[drillId :: string]
	if not drill then
		return Result.err(Result.Codes.NOT_OWNED)
	end
	if not drill.MineId then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	-- Entfernen in der Mine des Drills oder am Laptop
	if ElevatorService.GetLocation(player) ~= drill.MineId and not WorkerService.IsNearLaptop(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	DataService.Mutate(player, function(d)
		local record = d.Machines.Drills[drillId :: string]
		record.MineId = nil
		record.Slot = nil
	end)
	DataService.RequestSave(player)
	Log.debug(TAG, `{player.Name} entfernt {drill.Type} ({drillId})`)
	DrillService.DrillsChanged:Fire(player)
	local def = Drills.Get(drill.Type)
	RemoteService.FireClient("Notify", player, { Kind = "Info", Code = "DRILL_REMOVED", Args = { Name = if def then def.DisplayName else drill.Type } })
	return Result.ok(drillId)
end

function DrillService.Init()
	RemoteService.OnInvoke("PlaceDrill", place)
	RemoteService.OnInvoke("RemoveDrill", remove)
end

function DrillService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if prompt.Name ~= "SlotPrompt" then
			return
		end
		local slot = prompt:GetAttribute("SlotIndex")
		if typeof(slot) ~= "number" then
			return
		end
		if prompt:GetAttribute("PlotId") ~= PlotService.GetPlotId(player) then
			RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = Result.Codes.NOT_OWNER })
			return
		end
		local mine = Mines.Get(ElevatorService.GetLocation(player))
		if mine and DataService.IsLoaded(player) then
			RemoteService.FireClient("OpenSlotMenu", player, { MineId = mine.Id, Slot = slot })
		end
	end)
end

return DrillService
