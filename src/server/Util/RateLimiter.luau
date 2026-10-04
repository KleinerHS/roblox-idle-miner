--!strict
-- Sliding-Window-Rate-Limit pro Spieler und Schlüssel (docs/15 §8).

local RateLimiter = {}

-- [player][key] = Liste von Zeitstempeln
local history: { [Player]: { [string]: { number } } } = {}

-- true, wenn der Aufruf erlaubt ist (und wird gezählt), sonst false.
function RateLimiter.allow(player: Player, key: string, count: number, window: number): boolean
	local now = os.clock()
	local perPlayer = history[player]
	if not perPlayer then
		perPlayer = {}
		history[player] = perPlayer
	end
	local stamps = perPlayer[key]
	if not stamps then
		stamps = {}
		perPlayer[key] = stamps
	end

	-- Abgelaufene Einträge entfernen
	local cutoff = now - window
	local firstValid = 1
	while stamps[firstValid] and stamps[firstValid] < cutoff do
		firstValid += 1
	end
	if firstValid > 1 then
		table.move(stamps, firstValid, #stamps, 1)
		for i = #stamps - firstValid + 2, #stamps do
			stamps[i] = nil
		end
	end

	if #stamps >= count then
		return false
	end
	table.insert(stamps, now)
	return true
end

function RateLimiter.clear(player: Player)
	history[player] = nil
end

return table.freeze(RateLimiter)
