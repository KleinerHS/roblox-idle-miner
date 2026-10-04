--!strict
-- Zentrales Logging (docs/15 §20). Debug-Ausgaben nur bei GameConfig.Debug = true,
-- Warnungen und Fehler immer.

local RunService = game:GetService("RunService")

local GameConfig = require(script.Parent.Parent.Config.GameConfig)

local SIDE = if RunService:IsServer() then "Server" else "Client"

local Log = {}

function Log.debug(tag: string, message: string)
	if GameConfig.Debug then
		print(`[{SIDE}][{tag}] {message}`)
	end
end

function Log.info(tag: string, message: string)
	print(`[{SIDE}][{tag}] {message}`)
end

function Log.warn(tag: string, message: string)
	warn(`[{SIDE}][{tag}] {message}`)
end

-- Fehler protokollieren, ohne den aktuellen Thread abzubrechen.
function Log.error(tag: string, message: string)
	task.spawn(error, `[{SIDE}][{tag}] {message}`, 0)
end

return table.freeze(Log)
