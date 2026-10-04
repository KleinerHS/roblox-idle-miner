--!strict
-- Prüfhelfer für Remote-Eingaben. Alles vom Client ist `unknown`, bis es hier geprüft wurde.

local Validate = {}

local MAX_ID_LENGTH = 64

-- Endliche Zahl (kein NaN, kein inf)
function Validate.number(value: unknown, min: number?, max: number?): boolean
	if typeof(value) ~= "number" then
		return false
	end
	local n = value :: number
	if n ~= n or n == math.huge or n == -math.huge then
		return false
	end
	if min and n < min then
		return false
	end
	if max and n > max then
		return false
	end
	return true
end

function Validate.integer(value: unknown, min: number?, max: number?): boolean
	return Validate.number(value, min, max) and (value :: number) % 1 == 0
end

function Validate.string(value: unknown, minLength: number?, maxLength: number?): boolean
	if typeof(value) ~= "string" then
		return false
	end
	local s = value :: string
	if not utf8.len(s) then
		return false
	end
	local length = utf8.len(s) :: number
	if minLength and length < minLength then
		return false
	end
	if maxLength and length > maxLength then
		return false
	end
	return true
end

-- Interne ID wie "ore_coal": Kleinbuchstaben, Ziffern, Unterstrich.
function Validate.id(value: unknown): boolean
	if typeof(value) ~= "string" then
		return false
	end
	local s = value :: string
	return #s > 0 and #s <= MAX_ID_LENGTH and s:match("^[a-z0-9_]+$") ~= nil
end

-- ID, die in einer Definitionstabelle existiert
function Validate.idIn(value: unknown, lookup: { [string]: any }): boolean
	return Validate.id(value) and lookup[value :: string] ~= nil
end

return table.freeze(Validate)
