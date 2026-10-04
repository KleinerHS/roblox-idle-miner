--!strict
-- Alle Spieler-Texte an einer Stelle (Spielsprache Englisch, spätere Lokalisierung möglich).
-- Codes kommen vom Server (Result.Codes / Notify-Codes) und werden hier übersetzt.

local Strings = {}

local MESSAGES: { [string]: string } = {
	-- Allgemein
	INVALID_ARGUMENT = "Something went wrong. Please try again.",
	RATE_LIMITED = "Slow down a little and try again.",
	DATA_NOT_LOADED = "Your data is still loading.",
	INTERNAL_ERROR = "Something went wrong. Please try again.",
	NOT_OWNER = "This is not your company.",
	NOT_AVAILABLE = "Not available yet.",
	ALREADY_DONE = "Already done.",
	NOT_ENOUGH_MONEY = "Not enough money. You need {Price}.",
	LEVEL_TOO_LOW = "Requires Mining Level {Level}.",

	-- Firma
	NAME_INVALID = "Company name must be 3–24 characters.",
	NAME_FILTERED = "This name is not allowed. Please choose another one.",
	FILTER_FAILED = "Name could not be checked right now. Please try again.",
	COMPANY_FOUNDED = "{Name} is open for business!",

	-- Tycoon
	BUILD_PURCHASED = "{Name} built!",
}

-- Text zu einem Code; {Platzhalter} werden aus args ersetzt.
function Strings.message(code: string, args: { [string]: any }?): string
	local text = MESSAGES[code] or MESSAGES.INTERNAL_ERROR
	if args then
		text = text:gsub("{(%w+)}", function(key: string)
			local value = args[key]
			if key == "Price" and typeof(value) == "number" then
				return "$" .. tostring(value)
			end
			return if value ~= nil then tostring(value) else ""
		end)
	end
	return text
end

Strings.Elevator = table.freeze({
	Title = "SELECT MINE",
	Surface = "SURFACE",
	SurfaceSub = "Back to your company",
	Go = "GO",
	Here = "YOU ARE HERE",
	Locked = "LOCKED",
	RequiresLevel = "Requires Mining Level %d",
	ComingSoon = "Coming soon",
	Close = "X",
})

Strings.CompanySetup = table.freeze({
	Title = "Found your company",
	Subtitle = "Choose a name, a logo and your company color.",
	NameLabel = "COMPANY NAME",
	NamePlaceholder = "e.g. Deep Rock Mining",
	LogoLabel = "LOGO",
	ColorLabel = "COLOR",
	Confirm = "FOUND COMPANY",
	Pending = "CHECKING…",
})

return table.freeze(Strings)
