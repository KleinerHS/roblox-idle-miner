--!strict
-- Worker (docs/05 §5–7, §21–23, D-004): Einstellen und Entlassen am Laptop, Lohn jede
-- Minute, unbezahlte Worker pausieren und arbeiten weiter, sobald wieder Geld da ist.
-- Die Produktion selbst rechnet ProductionService; die Figuren macht WorkerVisualService.
--
-- Laptop: Der Prompt am Laptop in der Hütte öffnet den Laptop (nur Besitzer).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Mines = require(Shared.Definitions.Mines)
local WorkerRoles = require(Shared.Definitions.WorkerRoles)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local BuildingService = require(script.Parent.BuildingService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "WorkerService"
-- Maximale Entfernung zum Laptop für Einstellen/Entlassen
local LAPTOP_DISTANCE = 12

local WorkerService = {
	-- (player) nachdem Worker eingestellt/entlassen wurden
	WorkersChanged = Signal.new() :: Signal.Signal<Player>,
}

-- Unbezahlte Worker je Spieler (Laufzeitzustand, nach Join zunächst alle bezahlt)
local unpaid: { [Player]: { [string]: boolean } } = {}

local function laptopPart(player: Player): BasePart?
	local office = BuildingService.GetModel(player, "build_office")
	local laptop = office and office:FindFirstChild("Laptop")
	local base = laptop and laptop:FindFirstChild("Base")
	return if base and base:IsA("BasePart") then base else nil
end

function WorkerService.IsNearLaptop(player: Player): boolean
	local base = laptopPart(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (base and root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - base.Position).Magnitude <= LAPTOP_DISTANCE
end

-- Worker in fester Reihenfolge (Einstellungsreihenfolge) für deterministische Lohnzahlung
local function sortedWorkers(data: Types.PlayerData): { Types.WorkerRecord }
	local list = {}
	for _, worker in data.Workers do
		table.insert(list, worker)
	end
	table.sort(list, function(a, b)
		return (tonumber(a.Id:sub(2)) or 0) < (tonumber(b.Id:sub(2)) or 0)
	end)
	return list
end

local function slotTaken(data: Types.PlayerData, mineId: string, role: string, slot: number): boolean
	for _, worker in data.Workers do
		if worker.MineId == mineId and worker.Role == role and worker.Slot == slot then
			return true
		end
	end
	-- Mining-Slot ist Worker ODER Drill (docs/05 §26)
	if role == "Mining" then
		for _, drill in data.Machines.Drills do
			if drill.MineId == mineId and drill.Slot == slot then
				return true
			end
		end
	end
	return false
end

local function hire(player: Player, mineId: unknown, role: unknown, slot: unknown)
	if typeof(mineId) ~= "string" or typeof(role) ~= "string" or typeof(slot) ~= "number" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local mine = Mines.Get(mineId)
	local roleDef = WorkerRoles.Get(role)
	if not mine or not roleDef or slot % 1 ~= 0 or slot < 1 or slot > roleDef.Slots then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not data.Buildings.build_storage then
		return Result.err(Result.Codes.STORAGE_REQUIRED)
	end
	if not WorkerService.IsNearLaptop(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	if not Mines.IsAccessible(mine, data.MiningLevel, data.UnlockedMines) then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if slotTaken(data, mine.Id, roleDef.Id, slot) then
		return Result.err(Result.Codes.SLOT_TAKEN)
	end
	if data.Cash < roleDef.HireCost then
		return Result.err(Result.Codes.NOT_ENOUGH_MONEY)
	end

	-- Prüfung und Änderung ohne Yield dazwischen → kein Doppel-Hire durch Spam
	local newId = ""
	DataService.Mutate(player, function(d)
		d.Cash -= roleDef.HireCost
		d.WorkerSeq += 1
		newId = `w{d.WorkerSeq}`
		d.Workers[newId] = { Id = newId, Role = roleDef.Id, MineId = mine.Id, Slot = slot :: number }
	end)
	DataService.RequestSave(player)
	Log.debug(TAG, `{player.Name} stellt {roleDef.Id} ein: {mine.Id} Slot {slot} ({newId})`)
	WorkerService.WorkersChanged:Fire(player)
	RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "WORKER_HIRED", Args = { Name = roleDef.DisplayName } })
	return Result.ok(newId)
end

local function fire(player: Player, workerId: unknown)
	if typeof(workerId) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	local worker = data.Workers[workerId :: string]
	if not worker then
		return Result.err(Result.Codes.NOT_OWNED)
	end
	if not WorkerService.IsNearLaptop(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	local roleDef = WorkerRoles.Get(worker.Role)
	local refund = if roleDef then math.floor(roleDef.HireCost * BalanceConfig.Workers.FireRefund) else 0
	DataService.Mutate(player, function(d)
		d.Workers[workerId :: string] = nil
		d.Cash += refund
	end)
	if unpaid[player] then
		unpaid[player][workerId :: string] = nil
	end
	DataService.RequestSave(player)
	WorkerService.WorkersChanged:Fire(player)
	return Result.ok(workerId)
end

-- Lohnabrechnung (docs/05 §6–7): Worker in Einstellungsreihenfolge bezahlen, solange Geld
-- reicht; der Rest pausiert bis zur nächsten Abrechnung.
local function payroll(player: Player)
	local data = DataService.Get(player)
	if not data or next(data.Workers) == nil then
		return
	end
	local unpaidNow: { [string]: boolean } = {}
	local total = 0
	DataService.Mutate(player, function(d)
		for _, worker in sortedWorkers(d) do
			local roleDef = WorkerRoles.Get(worker.Role)
			local wage = if roleDef then roleDef.WagePerMinute else 0
			if d.Cash >= wage then
				d.Cash -= wage
				total += wage
			else
				unpaidNow[worker.Id] = true
			end
		end
	end)
	local wasUnpaid = unpaid[player] and next(unpaid[player]) ~= nil
	unpaid[player] = unpaidNow
	if next(unpaidNow) ~= nil then
		RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = "WORKERS_UNPAID" })
	elseif wasUnpaid then
		RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "WORKERS_PAID" })
	end
	local unpaidCount = 0
	for _ in unpaidNow do
		unpaidCount += 1
	end
	Log.debug(TAG, `{player.Name} Lohn {total} gezahlt, unbezahlt: {unpaidCount}`)
end

function WorkerService.IsPaid(player: Player, workerId: string): boolean
	local set = unpaid[player]
	return not (set and set[workerId])
end

function WorkerService.Init()
	RemoteService.OnInvoke("HireWorker", hire)
	RemoteService.OnInvoke("FireWorker", fire)
end

function WorkerService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if prompt:GetAttribute("Laptop") ~= true then
			return
		end
		if not PlotService.IsOwnerOf(player, prompt) then
			RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = Result.Codes.NOT_OWNER })
			return
		end
		if DataService.IsLoaded(player) then
			RemoteService.FireClient("OpenLaptop", player)
		end
	end)

	-- Zentrale Lohnabrechnung für alle Spieler (keine Schleife pro Worker, docs/15 §11)
	task.spawn(function()
		while true do
			task.wait(BalanceConfig.Workers.PayrollSeconds)
			for _, player in Players:GetPlayers() do
				task.spawn(payroll, player)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		unpaid[player] = nil
	end)
end

return WorkerService
