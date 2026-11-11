--!strict
-- Offline-Geld beim Login (docs/14 §7–17, seit D-088 Geld statt Material). Die Abwesenheit kommt
-- ausschließlich aus der Serverzeit (DataService.GetOfflineSeconds); gekappt auf das Limit des
-- Spielers (8 h, mit Upgrades mehr). Die Rechnung macht OfflineSimulation. Danach bekommt der
-- Client eine Zusammenfassung („WHILE YOU WERE AWAY“) mit nur serverseitig bestätigten Werten.
-- Außerdem: Kauf der Offline-Upgrades am Laptop (Effizienz, Dauer).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Log = require(Shared.Util.Log)
local Result = require(Shared.Util.Result)
local OfflineLogic = require(Shared.Util.OfflineLogic)

local DataService = require(script.Parent.DataService)
local RemoteService = require(script.Parent.RemoteService)
local WorkerService = require(script.Parent.WorkerService)
local OfflineSimulation = require(script.Parent.Parent.Util.OfflineSimulation)

local TAG = "OfflineService"

local OfflineService = {}

-- Rechnet `seconds` Abwesenheit nach und schickt bei Bedarf die Zusammenfassung.
-- Auch von DevTools.SimulateOffline genutzt (gleicher Weg wie beim echten Login).
function OfflineService.Apply(player: Player, seconds: number): OfflineSimulation.Summary?
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local raw = math.max(0, math.floor(seconds))
	local maxSeconds = OfflineLogic.MaxSeconds(data.Offline.DurationLevel)
	local counted = math.min(raw, maxSeconds)
	if counted <= 0 then
		return nil
	end
	local efficiency = OfflineLogic.Efficiency(data.Offline.EfficiencyLevel)
	local summary: OfflineSimulation.Summary? = nil
	DataService.Mutate(player, function(d)
		summary = OfflineSimulation.run(d, counted, efficiency, maxSeconds, raw)
	end)
	if not summary then
		return nil
	end
	local result = summary :: OfflineSimulation.Summary
	Log.info(TAG, `{player.Name}: {counted} s offline ({raw} s roh), +${result.Cash} ({math.floor(efficiency * 100 + 0.5)} % von {math.floor(result.GrossPerMinute)} $/min)`)
	if counted >= GameConfig.Offline.MinSummarySeconds and OfflineSimulation.HasContent(result) then
		RemoteService.FireClient("OfflineSummary", player, result)
	end
	return result
end

-- Nächste Stufe eines Offline-Upgrades am Laptop kaufen (D-088)
local function buyUpgrade(player: Player, kind: unknown)
	if not OfflineLogic.IsKind(kind) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local upgradeKind = kind :: OfflineLogic.Kind
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not WorkerService.IsNearLaptop(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	local level = if upgradeKind == "efficiency" then data.Offline.EfficiencyLevel else data.Offline.DurationLevel
	local price, requiredLevel = OfflineLogic.Next(upgradeKind, level)
	if not price or not requiredLevel then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	if data.MiningLevel < requiredLevel then
		return Result.err(Result.Codes.LEVEL_TOO_LOW)
	end
	if data.Cash < price then
		return Result.err(Result.Codes.NOT_ENOUGH_MONEY)
	end
	-- Prüfung und Änderung ohne Yield dazwischen → kein Doppelkauf durch Spam
	DataService.Mutate(player, function(d)
		d.Cash -= price :: number
		if upgradeKind == "efficiency" then
			d.Offline.EfficiencyLevel = level + 1
		else
			d.Offline.DurationLevel = level + 1
		end
	end)
	DataService.RequestSave(player)
	Log.debug(TAG, `{player.Name} kauft Offline-{upgradeKind} {level + 1} für {price}`)
	RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "OFFLINE_UPGRADE_PURCHASED", Args = {} })
	return Result.ok(level + 1)
end

function OfflineService.Init()
	RemoteService.OnInvoke("BuyOfflineUpgrade", buyUpgrade)
end

function OfflineService.Start()
	DataService.ProfileLoaded:Connect(function(player)
		local seconds = DataService.GetOfflineSeconds(player)
		local ok, err = pcall(OfflineService.Apply, player, seconds)
		if not ok then
			Log.warn(TAG, `Offline-Berechnung für {player.Name} fehlgeschlagen: {err}`)
		end
	end)
end

return OfflineService
