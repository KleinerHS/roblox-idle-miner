--!strict
-- Zahlendarstellung für UI: kompakt (1.25K, 3.4M) und mit Tausendertrennern (docs/03 §12).

local NumberFormat = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- 1234 -> "1,234"
function NumberFormat.withSeparators(value: number): string
	local negative = value < 0
	local digits = tostring(math.floor(math.abs(value)))
	local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return if negative then "-" .. formatted else formatted
end

-- 999 -> "999", 1250 -> "1.25K", 3400000 -> "3.4M"
function NumberFormat.compact(value: number): string
	local absValue = math.abs(value)
	if absValue < 1000 then
		return tostring(math.floor(value))
	end
	local index = 1
	while absValue >= 1000 and index < #SUFFIXES do
		absValue /= 1000
		index += 1
	end
	-- Abschneiden statt Runden, damit nie mehr angezeigt wird als vorhanden ist.
	local truncated = math.floor(absValue * 100) / 100
	local text = string.format("%.2f", truncated):gsub("%.?0+$", "")
	return (if value < 0 then "-" else "") .. text .. SUFFIXES[index]
end

function NumberFormat.cash(value: number): string
	return "$" .. NumberFormat.compact(value)
end

return table.freeze(NumberFormat)
