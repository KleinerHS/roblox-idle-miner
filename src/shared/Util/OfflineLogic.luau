--!strict
-- Offline-Geld (D-088, Felix' Balancing-Entwurf 2026-11-11): gemeinsame Regeln für Server
-- (Berechnung, Kauf) und Client (Laptop-App OFFLINE). Werte in BalanceConfig.Offline und
-- GameConfig.Offline. Stufe 0 = nichts gekauft; Stufen werden der Reihe nach gekauft und bei
-- Prestige zurückgesetzt.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)
local GameConfig = require(script.Parent.Parent.Config.GameConfig)

local cfg = BalanceConfig.Offline

local OfflineLogic = {}

export type Kind = "efficiency" | "duration"

-- Anteil der automatischen Bruttoleistung, der offline als Geld gutgeschrieben wird
function OfflineLogic.Efficiency(level: number): number
	local entry = cfg.EfficiencyLevels[level]
	return if entry then entry.Efficiency else cfg.Efficiency
end

-- Höchste angerechnete Abwesenheit in Sekunden
function OfflineLogic.MaxSeconds(level: number): number
	local entry = cfg.DurationLevels[level]
	return if entry then math.floor(entry.Hours * 3600) else GameConfig.Offline.MaxSeconds
end

-- Größtmögliche Abwesenheit über alle Stufen (DataService kappt die Rohzeit darauf)
function OfflineLogic.AbsoluteMaxSeconds(): number
	local max = GameConfig.Offline.MaxSeconds
	for level in cfg.DurationLevels do
		max = math.max(max, OfflineLogic.MaxSeconds(level))
	end
	return max
end

function OfflineLogic.IsKind(kind: unknown): boolean
	return kind == "efficiency" or kind == "duration"
end

-- Nächste Stufe: Preis und Mindest-Level (nil = Maximum)
function OfflineLogic.Next(kind: Kind, level: number): (number?, number?)
	local list = if kind == "efficiency" then cfg.EfficiencyLevels else cfg.DurationLevels
	local entry = list[level + 1]
	if not entry then
		return nil, nil
	end
	return entry.Price, entry.RequiredLevel
end

function OfflineLogic.MaxLevel(kind: Kind): number
	return #(if kind == "efficiency" then cfg.EfficiencyLevels else cfg.DurationLevels)
end

return table.freeze(OfflineLogic)
