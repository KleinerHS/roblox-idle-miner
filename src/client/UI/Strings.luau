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

	-- Mining
	BACKPACK_FULL = "Backpack full! Sell your ore at the surface.",
	TOO_FAR = "Move closer to the ore.",
	NOT_IN_MINE = "You can only mine inside a mine.",
	COOLDOWN = "",
	NO_PICKAXE = "Equip your pickaxe first.",
	MINED = "+{Amount} {Ore}",

	-- Verkauf
	NOTHING_TO_SELL = "Nothing to sell.",

	-- Shop
	ITEM_PURCHASED = "{Name} purchased and equipped!",
	NOT_OWNED = "You don't own this item yet.",

	-- Worker
	SLOT_TAKEN = "This slot is already taken.",
	STORAGE_REQUIRED = "Build the Storage first to hire workers.",
	WORKER_HIRED = "{Name} hired!",
	WORKERS_UNPAID = "Not enough money for wages – some workers paused.",
	WORKERS_PAID = "All workers are paid and working again.",

	-- Lager
	STORAGE_FULL = "Storage is full!",
	STORAGE_MOVED = "{Amount} ore moved.",

	-- Upgrades
	UPGRADE_PURCHASED = "{Name} upgraded to {Capacity}!",
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

Strings.Sell = table.freeze({
	Title = "SELL ORE",
	Empty = "Your backpack is empty. Mine some ore first.",
	NotSellable = "not sellable yet",
	Total = "TOTAL",
	SellAll = "SELL ALL",
	Pending = "SELLING…",
	Sold = "SOLD",
	Close = "X",
})

Strings.Shop = table.freeze({
	EquipmentTitle = "EQUIPMENT",
	Pickaxes = "PICKAXES",
	Backpacks = "BACKPACKS",
	Power = "Mining Power",
	Speed = "Mining Speed",
	Capacity = "Capacity",
	Buy = "BUY %s",
	Equip = "EQUIP",
	Equipped = "EQUIPPED",
	Owned = "OWNED",
	ComingSoon = "COMING SOON",
	Locked = "LOCKED",
	RequiresLevel = "Requires Mining Level %d",
	Close = "X",
})

Strings.Storage = table.freeze({
	Title = "COMPANY STORAGE",
	Empty = "Storage is empty.",
	Take = "TAKE",
	Deposit = "DEPOSIT BACKPACK (%s)",
})

Strings.Laptop = table.freeze({
	Apps = { "DASHBOARD", "EMPLOYEES", "STORAGE", "ELEVATOR", "PRODUCTION", "COMPANY" },
	ComingSoon = "This app is coming soon.",
	Employees = "EMPLOYEES",
	NeedStorage = "Build the Storage first to hire workers.",
	NoMines = "No mines unlocked.",
	MiningSlot = "Mining Slot %d",
	TransportSlot = "Transport Slot %d",
	Empty = "Empty",
	Hire = "HIRE %s",
	Fire = "FIRE",
	Wage = "%s / min",
	Buffer = "Ore waiting at slots: %s",
	Elevator = "Elevator: %s / %s",
	Status = { Working = "Working", Waiting = "Waiting", Unpaid = "Unpaid" },
	Close = "X",

	-- Dashboard
	Dashboard = "DASHBOARD",
	MiningLevel = "Mining Level",
	Cash = "Cash",
	StorageCard = "Storage",
	EmployeesCard = "Employees",
	ProductionCard = "Production",
	ActiveCount = "%d Active",
	WaitingCount = "%d Waiting",
	UnpaidCount = "%d Unpaid",
	NoEmployees = "No employees yet",
	NotBuilt = "Not built yet",
	ElevatorLoad = "Elevator %s / %s",
	PerMinute = "%s ore / min",

	-- Storage-App
	StorageTitle = "STORAGE",
	StorageEmpty = "Storage is empty.",
	StorageNotBuilt = "Build the Storage in your hall first.",
	-- Elevator-App
	ElevatorTitle = "ELEVATOR",
	ElevatorNotBuilt = "Build the Elevator first.",
	Capacity = "Capacity",
	PerTrip = "%s ore per trip",
	TripEvery = "One trip every %d s · up to %s ore / min",
	CurrentLoad = "Waiting in elevator: %s",
	ElevatorStatus = { Idle = "Idle", Transporting = "Transporting", StorageFull = "Storage Full" },
	-- Upgrade-Karte
	Upgrade = "UPGRADE",
	UpgradeLevel = "Upgrade %d / %d",
	Current = "Current",
	Next = "Next",
	Cost = "Cost",
	RequiresLevel = "Requires Mining Level %d",
	UpgradeButton = "UPGRADE %s",
	MaxLevel = "MAX LEVEL",
	MaxLevelSub = "Fully upgraded.",
})

Strings.Hud = table.freeze({
	MiningLevel = "MINING LEVEL %d",
	XP = "%s / %s XP",
	LevelUp = "LEVEL UP!",
	LevelUpSub = "Mining Level %d",
	MineUnlocked = "NEW MINE UNLOCKED",
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
