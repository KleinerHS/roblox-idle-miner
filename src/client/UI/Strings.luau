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
	MINE_PURCHASED = "{Name} unlocked! Take the elevator down.",

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
	DRILL_PURCHASED = "{Name} purchased! Place it in a mine.",
	VEHICLE_PURCHASED = "{Name} purchased! Get it at the glowing ring in your garage.",
	GARAGE_REQUIRED = "Build the Garage first.",
	BAYS_FULL = "Both garage bays are taken. Park one of your vehicles first.",
	VEHICLE_FULL = "Your vehicle is full!",
	VEHICLE_RESET = "Vehicle returned to its garage bay.",
	NOTHING_TO_LOAD = "Nothing in storage to load.",
	SMELTER_FULL = "The smelter hopper is full.",
	SMELTER_FED = "{Amount} ore fed into the smelter.",
	SMELTER_COLLECTED = "{Amount} bars moved to storage.",
	VEHICLE_LOADED = "Your vehicle is fully loaded!",
	DRILL_PLACED = "{Name} placed and drilling!",
	DRILL_REMOVED = "{Name} moved back to your inventory.",
	NOT_OWNED = "You don't own this item yet.",

	-- Worker
	SLOT_TAKEN = "This slot is already taken.",
	STORAGE_REQUIRED = "Build the Storage first.",
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
	Buy = "BUY %s",
	BuyPrevious = "Buy the previous mine first",
	Close = "X",
})

Strings.Sell = table.freeze({
	Title = "SELL ORE",
	VehicleTitle = "SELL CARGO",
	VehicleEmpty = "Your vehicle is empty. Park it under the loading tower in your garage.",
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
	MachineTitle = "MACHINES",
	VehicleTitle = "VEHICLES",
	VehicleSpeed = "Top Speed",
	Vehicles = "VEHICLES",
	Drills = "DRILLS",
	Production = "Production",
	PerMinute = "%s ore / min",
	Output = "Output buffer",
	Inventory = "Inventory",
	InventoryValue = "Owned %d · Placed %d · Available %d",
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

	-- Drills (Phase 5b)
	DrillStatus = { Running = "Running", OutputFull = "Output Full", Idle = "Idle" },
	DrillRate = "%s ore / min",
	RemoveDrill = "REMOVE",
	ProductionTitle = "PRODUCTION",
	SmelterCard = "Smelter",
	NoMachines = "No machines yet. Buy drills at the Machine Shop in town.",
	InventoryTitle = "INVENTORY",
	InventoryLine = "%s × %d available",
	InventoryHint = "Place it at a mining slot inside a mine.",
})

Strings.DrillSlot = table.freeze({
	Title = "%s · MINING SLOT %d",
	WorkerHere = "A Mining Worker works here.",
	WorkerHint = "Fire the worker on the laptop to place a drill here.",
	EmptySlot = "This slot is free.",
	NoDrills = "No drills in your inventory. Buy one at the Machine Shop in town.",
	Available = "Available: %d",
	PerMinute = "%s ore / min",
	Place = "PLACE",
	Remove = "REMOVE",
	Status = { Running = "Running", OutputFull = "Output Full – needs transport", Idle = "Idle" },
	Close = "X",
})

Strings.Garage = table.freeze({
	Title = "GARAGE",
	Bays = "Bays in use: %d / %d",
	NoVehicles = "You don't own a vehicle yet. Buy one at the Vehicle shop in town.",
	Capacity = "Capacity %s",
	Cargo = "Cargo %s / %s",
	InBay = "In bay %d",
	Stored = "Parked away",
	Drive = "DRIVE",
	Store = "PARK AWAY",
	Reset = "RESET",
	Close = "X",
})

Strings.Smelter = table.freeze({
	Title = "SMELTER",
	Input = "Hopper %s / %s",
	Output = "Bars %s / %s",
	Status = { Running = "Running", WaitingForInput = "Waiting for input", OutputFull = "Output full – collect bars", Idle = "Idle" },
	Recipe = "Smelting: %s → %s",
	Feed = "FEED",
	FeedAll = "FEED ALL",
	Collect = "COLLECT BARS",
	NoOre = "No smeltable ore in storage. Metals like Copper, Tin and Iron can be smelted.",
	Priority = "Priority",
	Auto = "AUTO (most valuable)",
	Prefer = "PREFER",
	Preferred = "PREFERRED",
	StorageAmount = "In storage: %s",
	Close = "X",
})

Strings.Driving = table.freeze({
	Speed = "%d studs/s",
	Cargo = "CARGO %s / %s",
	Reset = "RESET VEHICLE",
	Exit = "Press Space to get out",
})

Strings.Hud = table.freeze({
	MiningLevel = "MINING LEVEL %d",
	XP = "%s / %s XP",
	LevelUp = "LEVEL UP!",
	LevelUpSub = "Mining Level %d",
	MineUnlocked = "NEW MINE UNLOCKED",
	MineAvailable = "NEW MINE FOR SALE",
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
