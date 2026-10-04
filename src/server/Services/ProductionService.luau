--!strict
-- Produktion (docs/06 §2, §9–21, docs/15 §11–12): ein zentraler Takt für alle Spieler,
-- keine Schleife pro Worker. Kette je Mine:
--   Mining-Worker → Slot-Puffer → Transport-Worker → Elevator-Puffer → (Fahrt) → Lager
-- Jeder Schritt läuft nur, wenn der nächste Platz hat (Rückstau statt Vernichtung, §18–19).
-- Wirtschaft ist rein rechnerisch; die Figuren (WorkerVisualService) sind nur Darstellung.
--
-- Status je Worker: "Working" | "Waiting" | "Unpaid" → Remote "WorkerStatus" bei Änderung.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Mines = require(Shared.Definitions.Mines)
local Ores = require(Shared.Definitions.Ores)
local Types = require(Shared.Types)
local Signal = require(Shared.Util.Signal)

local DataService = require(script.Parent.DataService)
local StorageService = require(script.Parent.StorageService)
local WorkerService = require(script.Parent.WorkerService)
local RemoteService = require(script.Parent.RemoteService)

local TICK_SECONDS = 1

local ProductionService = {
	-- (player, mineId) wenn in einer Mine Erz abgebaut wurde (für Effekte)
	Mined = Signal.new() :: Signal.Signal<Player, string>,
	-- (player, mineId) wenn ein Transport-Worker Erz zum Elevator gebracht hat
	Transported = Signal.new() :: Signal.Signal<Player, string>,
}

-- Nachkommastellen der Raten (nur Laufzeit; ganze Einheiten stehen im Profil)
type Accumulators = { mining: { [string]: number }, transport: { [string]: number }, elevator: number }
local accumulators: { [Player]: Accumulators } = {}
local lastStatus: { [Player]: { [string]: string } } = {}

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

local function getAcc(player: Player): Accumulators
	local acc = accumulators[player]
	if not acc then
		acc = { mining = {}, transport = {}, elevator = 0 }
		accumulators[player] = acc
	end
	return acc
end

local function tickPlayer(player: Player)
	local data = DataService.Get(player)
	if not data or not data.Buildings.build_storage or next(data.Workers) == nil then
		return
	end
	local cfg = BalanceConfig.Workers
	local acc = getAcc(player)
	local status: { [string]: string } = {}

	-- Worker je Mine gruppieren (nur bezahlte arbeiten)
	type MineGroup = { mining: { Types.WorkerRecord }, transport: { Types.WorkerRecord } }
	local mines: { [string]: MineGroup } = {}
	for _, worker in data.Workers do
		local group = mines[worker.MineId]
		if not group then
			group = { mining = {}, transport = {} }
			mines[worker.MineId] = group
		end
		if not WorkerService.IsPaid(player, worker.Id) then
			status[worker.Id] = "Unpaid"
		elseif worker.Role == "Mining" then
			table.insert(group.mining, worker)
		else
			table.insert(group.transport, worker)
		end
	end

	local mined: { [string]: boolean } = {}
	local transported: { [string]: boolean } = {}
	DataService.MutateQuiet(player, function(d)
		local production = d.Production
		local elevatorFree = production.ElevatorCapacity - sum(production.ElevatorBuffer)

		for mineId, group in mines do
			local mine = Mines.Get(mineId)
			if not mine then
				continue
			end
			local buffer = production.MineBuffers[mineId] or 0
			-- Puffer: SlotBuffer je Mining-Slot mit Worker (mindestens einer, damit
			-- Transport-Worker Restmengen noch abholen können)
			local cap = cfg.SlotBuffer * math.max(1, #group.mining)

			-- 1) Mining-Worker füllen den Slot-Puffer
			if #group.mining > 0 then
				local a = (acc.mining[mineId] or 0) + #group.mining * cfg.Mining.OrePerMinute / 60 * TICK_SECONDS
				local whole = math.floor(a)
				local add = math.min(whole, cap - buffer)
				if add > 0 then
					buffer += add
					mined[mineId] = true
				end
				-- Bei vollem Puffer nicht "vorproduzieren"
				acc.mining[mineId] = if add < whole then math.min(a - whole, 1) else a - whole
				for _, worker in group.mining do
					status[worker.Id] = if buffer >= cap then "Waiting" else "Working"
				end
			end

			-- 2) Transport-Worker bringen Erz vom Slot-Puffer zum Elevator
			if #group.transport > 0 then
				local rate = cfg.Transport.CarryAmount / cfg.Transport.TripSeconds
				local a = (acc.transport[mineId] or 0) + #group.transport * rate * TICK_SECONDS
				local whole = math.floor(a)
				local move = math.min(whole, buffer, math.max(0, elevatorFree))
				if move > 0 then
					buffer -= move
					elevatorFree -= move
					production.ElevatorBuffer[mine.OreId] = (production.ElevatorBuffer[mine.OreId] or 0) + move
					transported[mineId] = true
				end
				acc.transport[mineId] = if move < whole then math.min(a - whole, 1) else a - whole
				for _, worker in group.transport do
					status[worker.Id] = if move > 0 or (buffer > 0 and elevatorFree > 0) then "Working" else "Waiting"
				end
			end

			production.MineBuffers[mineId] = if buffer > 0 then buffer else nil
		end
	end)

	-- 3) Elevator fährt alle CycleSeconds und lädt ins Lager (Rest bleibt im Elevator)
	acc.elevator += TICK_SECONDS
	if acc.elevator >= BalanceConfig.Elevator.CycleSeconds then
		acc.elevator = 0
		local load = data.Production.ElevatorCapacity
		local ids = {}
		for oreId, amount in data.Production.ElevatorBuffer do
			if amount > 0 then
				table.insert(ids, oreId)
			end
		end
		table.sort(ids, function(a, b)
			local oa, ob = Ores.Get(a), Ores.Get(b)
			return (if oa then oa.Tier else 999) < (if ob then ob.Tier else 999)
		end)
		for _, oreId in ids do
			if load <= 0 then
				break
			end
			local want = math.min(load, data.Production.ElevatorBuffer[oreId])
			local added = StorageService.Add(player, oreId, want)
			if added > 0 then
				load -= added
				DataService.MutateQuiet(player, function(d)
					d.Production.ElevatorBuffer[oreId] -= added
					if d.Production.ElevatorBuffer[oreId] <= 0 then
						d.Production.ElevatorBuffer[oreId] = nil
					end
				end)
			end
			if added < want then
				break -- Lager voll
			end
		end
	end

	for mineId in mined do
		ProductionService.Mined:Fire(player, mineId)
	end
	for mineId in transported do
		ProductionService.Transported:Fire(player, mineId)
	end

	-- Status nur bei Änderung an den Client
	local previous = lastStatus[player] or {}
	local changed = false
	for id, s in status do
		if previous[id] ~= s then
			changed = true
			break
		end
	end
	if not changed then
		for id in previous do
			if status[id] == nil then
				changed = true
				break
			end
		end
	end
	if changed then
		lastStatus[player] = status
		RemoteService.FireClient("WorkerStatus", player, status)
	end
end

function ProductionService.GetStatus(player: Player): { [string]: string }
	return lastStatus[player] or {}
end

function ProductionService.Init() end

function ProductionService.Start()
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(tickPlayer, player)
				if not ok then
					warn(`[Server][ProductionService] Tick-Fehler {player.Name}: {err}`)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		accumulators[player] = nil
		lastStatus[player] = nil
	end)
	WorkerService.WorkersChanged:Connect(function(player)
		-- neuer Status-Vergleich nach Einstellung/Entlassung
		lastStatus[player] = nil
	end)
end

return ProductionService
