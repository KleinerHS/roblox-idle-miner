--!strict
-- Offline-Produktion (docs/14 §7–16, docs/06 §48–50, docs/05 §44): rechnet die Produktionskette
-- für die Abwesenheit nach – ohne Figuren, ohne Sekunden-Takt.
--
-- Verfahren (D-032): Die Zeit wird in Abschnitte zu STEP_SECONDS (= eine Elevator-Fahrt)
-- geteilt, höchstens 3600 / 10 = 360 Abschnitte. Je Abschnitt laufen dieselben Regeln wie
-- online, nur mit Raten × Abschnittsdauer:
--   kein Lohn offline (D-040): alle Worker arbeiten
--   → Mining-Worker/Drills füllen den Slot-Puffer (bis Kapazität)
--   → Slot-Puffer direkt in den Elevator (bis Elevator-Kapazität, D-041)
--   → Elevator-Fahrt ins Lager (bis Lagerkapazität, niedrigste Erz-Stufe zuerst)
--   → Förderband Lager → Schmelzer (bis Trichterkapazität)
--   → Schmelzer (Rezeptwahl wie online, bis Ablagekapazität)
--   → Förderband Schmelzer → Lager (bis Lagerkapazität)
-- Jeder Schritt läuft nur, solange der nächste Platz hat (Engpass statt Vernichtung).
-- Kein Geld aus Produktion (docs/14 §8), Fahrzeuge bleiben unberührt (§14).
-- Reine Funktion auf dem Profil: keine Instanzen, keine Remotes, damit testbar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Mines = require(Shared.Definitions.Mines)
local Drills = require(Shared.Definitions.Drills)
local Ores = require(Shared.Definitions.Ores)
local Conveyors = require(Shared.Definitions.Conveyors)
local Materials = require(Shared.Definitions.Materials)
local SmelterLogic = require(Shared.Util.SmelterLogic)
local Types = require(Shared.Types)
local CrateLogic = require(Shared.Util.CrateLogic)

local STEP_SECONDS = BalanceConfig.Elevator.CycleSeconds
local PAYROLL_SECONDS = BalanceConfig.Workers.PayrollSeconds
local STORAGE_STEP = "build_storage"
local SMELTER_STEP = "build_smelter"

export type Summary = {
	Seconds: number,
	-- abgebautes Erz je Erz-ID (Worker und Drills)
	Mined: { [string]: number },
	-- geschmolzene Barren je Barren-ID
	Smelted: { [string]: number },
	-- Zugang im Lager je Material (Erz per Elevator, Barren per Förderband)
	Stored: { [string]: number },
	WagesPaid: number,
	-- Worker-Minuten ohne Lohn (pausiert)
	UnpaidMinutes: number,
	StorageUsed: number,
	StorageCapacity: number,
	-- Sekunden nach dem Logout, ab denen das Lager voll war (nil = nie)
	StorageFullAfter: number?,
}

local OfflineSimulation = {}

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, n in items do
		total += n
	end
	return total
end

local function add(counts: { [string]: number }, id: string, n: number)
	if n > 0 then
		counts[id] = (counts[id] or 0) + n
	end
end

local function take(counts: Types.ItemCounts, id: string, n: number)
	counts[id] -= n
	if counts[id] <= 0 then
		counts[id] = nil
	end
end

local function conveyorRate(data: Types.PlayerData, slot: string): number
	for _, record in data.Machines.Conveyors do
		if record.Slot == slot then
			local def = Conveyors.Get(record.Type)
			return if def then def.Throughput / 60 else 0
		end
	end
	return 0
end

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

-- Simuliert `seconds` Sekunden Abwesenheit direkt auf `data` (innerhalb von DataService.Mutate
-- aufrufen) und gibt die Zusammenfassung zurück. Der Aufrufer kappt seconds auf
-- GameConfig.Offline.MaxSeconds. Drills laufen als Rate (OrePerCycle / CycleSeconds).
function OfflineSimulation.run(data: Types.PlayerData, seconds: number): Summary
	local summary: Summary = {
		Seconds = seconds,
		Mined = {},
		Smelted = {},
		Stored = {},
		WagesPaid = 0,
		UnpaidMinutes = 0,
		StorageUsed = sum(data.Storage.Items),
		StorageCapacity = data.Storage.Capacity,
		StorageFullAfter = nil,
	}
	if not data.Buildings[STORAGE_STEP] then
		return summary
	end
	local steps = math.floor(seconds / STEP_SECONDS)
	local cfg = BalanceConfig.Workers
	local production = data.Production
	local smelterBuilt = data.Buildings[SMELTER_STEP] == true
	local toSmelterRate = if smelterBuilt then conveyorRate(data, "StorageToSmelter") else 0
	local toStorageRate = if smelterBuilt then conveyorRate(data, "SmelterToStorage") else 0
	local workers = sortedWorkers(data)

	-- Bruchteile je Rate (wie die Akkumulatoren online)
	local accMining: { [string]: number } = {}
	local accToSmelter, accToStorage, accSmelt = 0, 0, 0
	local paid: { [string]: boolean } = {}

	-- Kisten-Logik (D-037): Platz je Sorte
	local function storageFree(id: string): number
		return CrateLogic.freeFor(data.Storage.Items, data.Storage.Crates, id)
	end

	for step = 0, steps - 1 do
		local t = step * STEP_SECONDS

		-- Offline wird kein Lohn bezahlt (Felix 2026-10-16, D-040): alle Worker arbeiten, das
		-- Geld bleibt unverändert. Online gilt der Lohn weiter (WorkerService).
		if t % PAYROLL_SECONDS == 0 then
			paid = {}
			for _, worker in workers do
				paid[worker.Id] = true
			end
		end

		-- Mines: Worker/Drills → Slot-Puffer → Transport → Elevator-Puffer
		local mines: { [string]: { mining: number, transport: number, drills: { Types.DrillRecord } } } = {}
		local function group(mineId: string)
			local g = mines[mineId]
			if not g then
				g = { mining = 0, transport = 0, drills = {} }
				mines[mineId] = g
			end
			return g
		end
		for _, worker in workers do
			if paid[worker.Id] then
				local g = group(worker.MineId)
				if worker.Role == "Mining" then
					g.mining += 1
				else
					g.transport += 1
				end
			end
		end
		for _, drill in data.Machines.Drills do
			if drill.MineId then
				table.insert(group(drill.MineId).drills, drill)
			end
		end

		local elevatorFree = production.ElevatorCapacity - sum(production.ElevatorBuffer)
		for mineId, g in mines do
			local mine = Mines.Get(mineId)
			if not mine then
				continue
			end
			local buffer = production.MineBuffers[mineId] or 0
			local cap = cfg.SlotBuffer * g.mining
			for _, drill in g.drills do
				local def = Drills.Get(drill.Type)
				cap += if def then Drills.OutputCapacity(def, drill.Level) else 0
			end
			cap = math.max(cap, cfg.SlotBuffer)

			local rate = g.mining * cfg.Mining.OrePerMinute / 60
			for _, drill in g.drills do
				local def = Drills.Get(drill.Type)
				if def then
					rate += def.OrePerCycle / def.CycleSeconds * Drills.Multiplier(drill.Level)
				end
			end
			if rate > 0 then
				local a = (accMining[mineId] or 0) + rate * STEP_SECONDS
				local whole = math.floor(a)
				local produced = math.min(whole, math.max(0, cap - buffer))
				buffer += produced
				add(summary.Mined, mine.OreId, produced)
				-- Bei vollem Puffer nicht vorproduzieren
				accMining[mineId] = if produced < whole then 0 else a - whole
			end

			-- direkt in den Elevator (D-041)
			local moved = math.min(buffer, math.max(0, elevatorFree))
			if moved > 0 then
				buffer -= moved
				elevatorFree -= moved
				production.ElevatorBuffer[mine.OreId] = (production.ElevatorBuffer[mine.OreId] or 0) + moved
			end
			production.MineBuffers[mineId] = if buffer > 0 then buffer else nil
		end

		-- Elevator-Fahrt ins Lager (niedrigste Stufe zuerst, wie online)
		local load = production.ElevatorCapacity
		local ids = {}
		for oreId, amount in production.ElevatorBuffer do
			if amount > 0 then
				table.insert(ids, oreId)
			end
		end
		table.sort(ids, function(a, b)
			local oa, ob = Ores.Get(a), Ores.Get(b)
			return (if oa then oa.Tier else 999) < (if ob then ob.Tier else 999)
		end)
		for _, oreId in ids do
			local n = math.min(load, production.ElevatorBuffer[oreId], storageFree(oreId))
			if n <= 0 then
				continue
			end
			take(production.ElevatorBuffer, oreId, n)
			data.Storage.Items[oreId] = (data.Storage.Items[oreId] or 0) + n
			add(summary.Stored, oreId, n)
			load -= n
		end

		if smelterBuilt then
			-- Förderband Lager → Schmelzer (bevorzugtes Erz zuerst, sonst wertvollstes)
			if toSmelterRate > 0 then
				local a = accToSmelter + toSmelterRate * STEP_SECONDS
				local budget = math.floor(a)
				local smeltable = {}
				for id, n in data.Storage.Items do
					if n > 0 and SmelterLogic.IsSmeltable(id) then
						table.insert(smeltable, id)
					end
				end
				table.sort(smeltable, function(x, y)
					if x == data.Smelter.Priority then
						return true
					elseif y == data.Smelter.Priority then
						return false
					end
					local mx, my = Materials.Get(x), Materials.Get(y)
					return ((mx and mx.SellValue or 0) :: number) > ((my and my.SellValue or 0) :: number)
				end)
				local moved = 0
				for _, id in smeltable do
					local n = math.min(data.Storage.Items[id], budget - moved, CrateLogic.freeFor(data.Smelter.Input, BalanceConfig.Smelter.InputCrates, id))
					if n > 0 then
						take(data.Storage.Items, id, n)
						data.Smelter.Input[id] = (data.Smelter.Input[id] or 0) + n
						moved += n
					end
				end
				accToSmelter = math.min(a - moved, 1)
			end

			-- Schmelzer: ein Barren je Rezeptdauer, Rezeptwahl je Barren
			accSmelt += STEP_SECONDS
			while true do
				if SmelterLogic.Status(data.Smelter) ~= "Running" then
					accSmelt = 0
					break
				end
				local recipe = SmelterLogic.PickRecipe(data.Smelter)
				if not recipe or accSmelt < recipe.Seconds then
					break
				end
				accSmelt -= recipe.Seconds
				take(data.Smelter.Input, recipe.OreId, recipe.OrePerBar)
				data.Smelter.Output[recipe.BarId] = (data.Smelter.Output[recipe.BarId] or 0) + 1
				add(summary.Smelted, recipe.BarId, 1)
			end

			-- Förderband Schmelzer → Lager
			if toStorageRate > 0 then
				local a = accToStorage + toStorageRate * STEP_SECONDS
				local budget = math.floor(a)
				local moved = 0
				local barIds = {}
				for id in data.Smelter.Output do
					table.insert(barIds, id)
				end
				table.sort(barIds)
				for _, id in barIds do
					local n = math.min(data.Smelter.Output[id], budget - moved, storageFree(id))
					if n > 0 then
						take(data.Smelter.Output, id, n)
						data.Storage.Items[id] = (data.Storage.Items[id] or 0) + n
						add(summary.Stored, id, n)
						moved += n
					end
				end
				accToStorage = math.min(a - moved, 1)
			end
		end

		if summary.StorageFullAfter == nil and CrateLogic.isFull(data.Storage.Items, data.Storage.Crates) then
			summary.StorageFullAfter = t + STEP_SECONDS
		end
	end

	summary.StorageUsed = sum(data.Storage.Items)
	summary.StorageCapacity = data.Storage.Capacity
	return summary
end

-- Hat die Abwesenheit etwas bewirkt, das eine Zusammenfassung lohnt?
function OfflineSimulation.HasContent(summary: Summary): boolean
	return next(summary.Mined) ~= nil or next(summary.Smelted) ~= nil or next(summary.Stored) ~= nil or summary.WagesPaid > 0 or summary.UnpaidMinutes > 0
end

return OfflineSimulation
