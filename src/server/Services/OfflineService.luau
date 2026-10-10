--!strict
-- Offline-Produktion beim Login (docs/14 §7–17, Phase 10). Die Abwesenheit kommt
-- ausschließlich aus der Serverzeit (DataService.GetOfflineSeconds, max. 1 Stunde); die
-- Rechnung selbst macht OfflineSimulation. Danach bekommt der Client eine Zusammenfassung
-- („WHILE YOU WERE AWAY“) mit nur serverseitig bestätigten Werten.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Log = require(Shared.Util.Log)

local DataService = require(script.Parent.DataService)
local RemoteService = require(script.Parent.RemoteService)
local OfflineSimulation = require(script.Parent.Parent.Util.OfflineSimulation)

local TAG = "OfflineService"

local OfflineService = {}

-- Rechnet `seconds` Abwesenheit nach und schickt bei Bedarf die Zusammenfassung.
-- Auch von DevTools.SimulateOffline genutzt (gleicher Weg wie beim echten Login).
function OfflineService.Apply(player: Player, seconds: number): OfflineSimulation.Summary?
	seconds = math.clamp(math.floor(seconds), 0, GameConfig.Offline.MaxSeconds)
	if seconds <= 0 then
		return nil
	end
	local summary: OfflineSimulation.Summary? = nil
	DataService.Mutate(player, function(data)
		summary = OfflineSimulation.run(data, seconds)
	end)
	if not summary then
		return nil
	end
	local result = summary :: OfflineSimulation.Summary
	local mined = 0
	for _, n in result.Mined do
		mined += n
	end
	Log.info(TAG, `{player.Name}: {seconds} s offline, {mined} Erz abgebaut, Lohn {result.WagesPaid}, Lager {result.StorageUsed}/{result.StorageCapacity}`)
	if seconds >= GameConfig.Offline.MinSummarySeconds and OfflineSimulation.HasContent(result) then
		RemoteService.FireClient("OfflineSummary", player, result)
	end
	return result
end

function OfflineService.Init() end

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
