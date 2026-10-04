--!strict
-- Kapazitäts-Upgrades für Lager und Elevator über den Laptop (docs/09 §29–31).
-- Server prüft: Gebäude vorhanden, Spieler am Laptop, Level, Geld, nächste Stufe vorhanden.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Upgrades = require(Shared.Definitions.Upgrades)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Log = require(Shared.Util.Log)

local DataService = require(script.Parent.DataService)
local RemoteService = require(script.Parent.RemoteService)
local WorkerService = require(script.Parent.WorkerService)

local TAG = "UpgradeService"

-- Benötigtes Gebäude je Upgrade-Art
local REQUIRED_BUILDING: { [string]: string } = {
	storage = "build_storage",
	elevator = "build_elevator",
}

local UpgradeService = {}

local function currentCapacity(data: Types.PlayerData, kind: Upgrades.UpgradeKind): number
	return if kind == "storage" then data.Storage.Capacity else data.Production.ElevatorCapacity
end

local function buy(player: Player, kind: unknown)
	if not Upgrades.IsKind(kind) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local upgradeKind = kind :: Upgrades.UpgradeKind
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not data.Buildings[REQUIRED_BUILDING[upgradeKind]] then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if not WorkerService.IsNearLaptop(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	local tier = Upgrades.Next(upgradeKind, currentCapacity(data, upgradeKind))
	if not tier then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	if data.MiningLevel < tier.RequiredLevel then
		return Result.err(Result.Codes.LEVEL_TOO_LOW)
	end
	if data.Cash < tier.Cost then
		return Result.err(Result.Codes.NOT_ENOUGH_MONEY)
	end

	-- Prüfung und Änderung ohne Yield dazwischen → kein Doppelkauf durch Spam
	DataService.Mutate(player, function(d)
		d.Cash -= tier.Cost
		if upgradeKind == "storage" then
			d.Storage.Capacity = tier.Capacity
		else
			d.Production.ElevatorCapacity = tier.Capacity
		end
	end)
	DataService.RequestSave(player)
	Log.debug(TAG, `{player.Name} kauft {upgradeKind}-Upgrade → {tier.Capacity} für {tier.Cost}`)
	RemoteService.FireClient("Notify", player, {
		Kind = "Success",
		Code = "UPGRADE_PURCHASED",
		Args = { Name = if upgradeKind == "storage" then "Storage" else "Elevator", Capacity = tier.Capacity },
	})
	return Result.ok({ Capacity = tier.Capacity })
end

function UpgradeService.Init()
	RemoteService.OnInvoke("BuyUpgrade", buy)
end

function UpgradeService.Start() end

return UpgradeService
