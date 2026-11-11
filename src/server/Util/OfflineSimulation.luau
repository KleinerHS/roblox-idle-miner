--!strict
-- Offline-Geld (D-088, Felix' Balancing-Entwurf 2026-11-11; ersetzt die Material-Nachrechnung
-- D-032): Während der Abwesenheit gibt es Geld statt Material.
--
--   Geld = Bruttowert je Sekunde × Efficiency × Sekunden × Prestige-Geldfaktor (abgerundet)
--
-- Bruttowert = Verkaufswert des Erzes, das die installierte Firma liefern würde:
--   * alle eingestellten Mining-Worker (offline kein Lohn, D-040) und platzierten Drills (mit Level)
--   * gedeckelt durch den Elevator (Kapazität / Fahrtdauer), niedrigste Erzstufe zuerst wie online
--   * ohne Lager/Puffer-Grenze, ohne Schmelzer (Erzwert)
-- Kein Material, keine XP, kein Lohn, Fahrzeuge unberührt. Ohne Elevator und Lager kein Geld,
-- weil online dann auch nichts ankommt. Reine Funktion auf dem Profil, damit testbar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Mines = require(Shared.Definitions.Mines)
local Drills = require(Shared.Definitions.Drills)
local Ores = require(Shared.Definitions.Ores)
local Types = require(Shared.Types)
local PrestigeLogic = require(Shared.Util.PrestigeLogic)

export type Summary = {
	Seconds: number,
	-- gutgeschriebenes Geld
	Cash: number,
	-- angerechneter Anteil (0,3 = 30 %)
	Efficiency: number,
	-- Bruttowert der Firma je Minute (vor Efficiency)
	GrossPerMinute: number,
	-- Limit dieses Spielers in Sekunden und ob die Abwesenheit länger war
	MaxSeconds: number,
	Capped: boolean,
}

local OfflineSimulation = {}

-- Bruttowert der installierten automatischen Firma in $ je Sekunde (ohne Prestige-Bonus)
function OfflineSimulation.grossPerSecond(data: Types.PlayerData): number
	if not data.Buildings.build_elevator or not data.Buildings.build_storage then
		return 0
	end
	-- Erz je Sekunde je Erzsorte
	local rates: { [string]: number } = {}
	local function add(mineId: string?, rate: number)
		local mine = if mineId then Mines.Get(mineId) else nil
		if mine and rate > 0 then
			rates[mine.OreId] = (rates[mine.OreId] or 0) + rate
		end
	end
	for _, worker in data.Workers do
		if worker.Role == "Mining" then
			add(worker.MineId, BalanceConfig.Workers.Mining.OrePerMinute / 60)
		end
	end
	for _, drill in data.Machines.Drills do
		local def = Drills.Get(drill.Type)
		if def and drill.MineId then
			add(drill.MineId, def.OrePerCycle / def.CycleSeconds * Drills.Multiplier(drill.Level))
		end
	end
	-- Elevator-Deckel, niedrigste Stufe zuerst (wie ProductionService)
	local ids = {}
	for oreId in rates do
		table.insert(ids, oreId)
	end
	table.sort(ids, function(a, b)
		local oa, ob = Ores.Get(a), Ores.Get(b)
		return (if oa then oa.Tier else 999) < (if ob then ob.Tier else 999)
	end)
	local budget = data.Production.ElevatorCapacity / BalanceConfig.Elevator.CycleSeconds
	local value = 0
	for _, oreId in ids do
		local n = math.min(rates[oreId], budget)
		budget -= n
		local ore = Ores.Get(oreId)
		value += n * (if ore and ore.SellValue then ore.SellValue else 0)
		if budget <= 0 then
			break
		end
	end
	return value
end

-- Rechnet `seconds` Abwesenheit (bereits auf das Limit gekappt) und schreibt das Geld direkt ins
-- Profil (innerhalb von DataService.Mutate aufrufen).
function OfflineSimulation.run(data: Types.PlayerData, seconds: number, efficiency: number, maxSeconds: number, rawSeconds: number): Summary
	local gross = OfflineSimulation.grossPerSecond(data)
	local cash = math.floor(gross * efficiency * seconds * PrestigeLogic.MoneyMultiplier(data.Prestige.Count))
	if cash > 0 then
		data.Cash += cash
	end
	return {
		Seconds = seconds,
		Cash = cash,
		Efficiency = efficiency,
		GrossPerMinute = gross * 60,
		MaxSeconds = maxSeconds,
		Capped = rawSeconds > maxSeconds,
	}
end

-- Hat die Abwesenheit etwas bewirkt, das eine Zusammenfassung lohnt?
function OfflineSimulation.HasContent(summary: Summary): boolean
	return summary.Cash > 0
end

return OfflineSimulation
