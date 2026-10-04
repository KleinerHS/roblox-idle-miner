--!strict
-- Kapazitäts-Upgrades für Lager und Elevator (docs/06 §10–11, §15–17, docs/09 §29–31).
-- Die Stufe ergibt sich aus der gespeicherten Kapazität: nächste Stufe = erste Stufe mit
-- größerer Kapazität. Dadurch braucht es kein eigenes Datenfeld und keine Migration.
-- Werte kommen ausschließlich aus BalanceConfig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)

export type UpgradeKind = "storage" | "elevator"
export type UpgradeTier = { Capacity: number, Cost: number, RequiredLevel: number }

local Upgrades = {}

local TIERS: { [string]: { UpgradeTier } } = {
	storage = BalanceConfig.Storage.Upgrades,
	elevator = BalanceConfig.Elevator.Upgrades,
}

function Upgrades.IsKind(kind: unknown): boolean
	return typeof(kind) == "string" and TIERS[kind] ~= nil
end

-- Nächste Stufe nach der aktuellen Kapazität; nil = maximal ausgebaut
function Upgrades.Next(kind: UpgradeKind, currentCapacity: number): UpgradeTier?
	for _, tier in TIERS[kind] do
		if tier.Capacity > currentCapacity then
			return tier
		end
	end
	return nil
end

-- Anzahl gekaufter Stufen und Gesamtzahl (für die Anzeige "Stufe 2 / 5")
function Upgrades.Progress(kind: UpgradeKind, currentCapacity: number): (number, number)
	local tiers = TIERS[kind]
	local done = 0
	for _, tier in tiers do
		if tier.Capacity <= currentCapacity then
			done += 1
		end
	end
	return done, #tiers
end

return table.freeze(Upgrades)
