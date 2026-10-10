--!strict
-- Prestige-Boni (docs/12 §57–58, docs/11 §44–45): gemeinsame Formel für Server (Verkauf,
-- Mining-Cooldown) und Client (Anzeige, eigener Cooldown). Werte in BalanceConfig.Prestige.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BalanceConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.BalanceConfig)

local cfg = BalanceConfig.Prestige

local PrestigeLogic = {}

-- Faktor auf den Geld-Erlös beim Verkauf (XP bleibt unverändert)
function PrestigeLogic.MoneyMultiplier(count: number): number
	return 1 + cfg.MoneyBonusPerPrestige * math.max(0, count)
end

-- Faktor auf die Mining Speed der Spitzhacke (gedeckelt)
function PrestigeLogic.SpeedMultiplier(count: number): number
	return 1 + math.min(cfg.SpeedBonusPerPrestige * math.max(0, count), cfg.SpeedBonusMax)
end

function PrestigeLogic.IsAvailable(level: number): boolean
	return level >= cfg.RequiredLevel
end

return table.freeze(PrestigeLogic)
