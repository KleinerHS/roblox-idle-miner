--!strict
-- Einheitliche Rückgabewerte für Services und Remotes (docs/15 §19).
-- Die UI übersetzt Codes in Text; Services liefern nie Fließtext an den Client.

export type Ok<T> = { success: true, value: T }
export type Err = { success: false, code: string }
export type Result<T> = Ok<T> | Err

local Codes = table.freeze({
	OK = "OK",
	INVALID_ARGUMENT = "INVALID_ARGUMENT",
	RATE_LIMITED = "RATE_LIMITED",
	DATA_NOT_LOADED = "DATA_NOT_LOADED",
	NOT_OWNER = "NOT_OWNER",
	NO_PLOT = "NO_PLOT",
	NOT_ENOUGH_MONEY = "NOT_ENOUGH_MONEY",
	LEVEL_TOO_LOW = "LEVEL_TOO_LOW",
	NOT_AVAILABLE = "NOT_AVAILABLE",
	ALREADY_DONE = "ALREADY_DONE",
	NAME_INVALID = "NAME_INVALID",
	NAME_FILTERED = "NAME_FILTERED",
	FILTER_FAILED = "FILTER_FAILED",
	INTERNAL_ERROR = "INTERNAL_ERROR",
})

local Result = {
	Codes = Codes,
}

function Result.ok<T>(value: T): Ok<T>
	return { success = true, value = value }
end

function Result.err(code: string): Err
	return { success = false, code = code }
end

return table.freeze(Result)
