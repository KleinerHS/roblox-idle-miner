--!strict
-- Zentrale Liste aller Remotes (docs/15 §8). Nur der Server erzeugt die Instanzen
-- (ReplicatedStorage.Remotes), der Client greift nur über diese Namen zu.
-- Neue Remotes ausschließlich hier eintragen.
--
-- Direction:
--   ServerToClient: nur FireClient/FireAllClients, Server ignoriert Client-Aufrufe
--   ClientToServer: Client-Anfrage, Server validiert jede Eingabe
-- RateLimit: max. Count Aufrufe pro Window Sekunden und Spieler (nur ClientToServer)

export type RemoteKind = "Event" | "Function"
export type RemoteDirection = "ServerToClient" | "ClientToServer"
export type RemoteDefinition = {
	Kind: RemoteKind,
	Direction: RemoteDirection,
	RateLimit: { Count: number, Window: number }?,
}

local Remotes: { [string]: RemoteDefinition } = {
	-- Vollständiger, für die Anzeige nötiger Spielerzustand (nach Laden und bei Änderungen).
	StateSnapshot = { Kind = "Event", Direction = "ServerToClient" },
	-- Client fragt den aktuellen Zustand an (z. B. nach eigenem Start).
	GetState = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 5, Window = 10 } },

	-- Plot-Zuweisung: PlotId des eigenen Grundstücks.
	PlotAssigned = { Kind = "Event", Direction = "ServerToClient" },
	GetMyPlot = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 5, Window = 10 } },

	-- Kurze Meldung an den Spieler: { Kind = "Info"|"Success"|"Warning"|"Special", Code, Args? }
	Notify = { Kind = "Event", Direction = "ServerToClient" },

	-- Ersteinrichtung der Firma: (name: string, logoId: string, colorId: string) -> Result
	SubmitCompanySetup = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 5, Window = 30 } },

	-- Elevator: Server öffnet die Auswahl nach gültigem Prompt: { Location: string }
	OpenElevatorMenu = { Kind = "Event", Direction = "ServerToClient" },
	-- Fahrtwunsch: (destination: "surface" | mineId) -> Result
	RequestTravel = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
	-- Übergangsanimation starten: { Title: string, Subtitle: string }
	ElevatorTransition = { Kind = "Event", Direction = "ServerToClient" },
	-- Aktueller Ort des Spielers: { Location: "surface" | mineId }
	LocationChanged = { Kind = "Event", Direction = "ServerToClient" },

	-- Manuelles Mining: (slotIndex: number) -> Result<{ OreId, Amount, Total, Capacity }>
	MineHit = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 12, Window = 5 } },

	-- Verkauf am Tresen: Server öffnet das Verkaufsfenster nach gültigem Prompt
	OpenSellMenu = { Kind = "Event", Direction = "ServerToClient" },
	-- Alles Verkaufbare verkaufen: (vehicleId: string?) -> Result<{ Cash, XP, Level, LevelsGained }>
	-- ohne vehicleId = Rucksack am Tresen, mit vehicleId = Fahrzeugladung in der Verkaufszone.
	-- OpenSellMenu kann { VehicleId } mitgeben (Fahrzeugverkauf).
	SellAll = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 5, Window = 10 } },

	-- Shops: Server öffnet den Shop nach gültigem Prompt: { ShopId: string }
	OpenShop = { Kind = "Event", Direction = "ServerToClient" },
	-- Kaufen: (category: "pickaxe" | "backpack", itemId: string) -> Result
	BuyItem = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
	-- Ausrüsten eines besessenen Items: (category, itemId) -> Result
	EquipItem = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 10, Window = 10 } },
	-- Maschine kaufen (mehrfach möglich, landet im Inventar): (drillTypeId: string) -> Result<instanceId>
	BuyMachine = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
	-- Fahrzeug kaufen (je Typ einmal, landet eingelagert im Fuhrpark): (vehicleTypeId: string) -> Result<vehicleId>
	BuyVehicle = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },

	-- Firmenlager: Server öffnet das Lagerfenster nach gültigem Prompt
	OpenStorage = { Kind = "Event", Direction = "ServerToClient" },
	-- Rucksack ins Lager abladen: () -> Result<{ Moved: number }>
	StorageDeposit = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
	-- Material aus dem Lager in den Rucksack: (oreId: string, amount: number) -> Result<{ Moved: number }>
	StorageWithdraw = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 10, Window = 10 } },

	-- Laptop: Server öffnet den Laptop nach gültigem Prompt (nur Besitzer)
	OpenLaptop = { Kind = "Event", Direction = "ServerToClient" },
	-- Worker einstellen: (mineId: string, role: "Mining" | "Transport", slot: number) -> Result
	HireWorker = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
	-- Worker entlassen: (workerId: string) -> Result
	FireWorker = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
	-- Laufzeitstatus: { [workerId]: "Working" | "Waiting" | "Unpaid", [drillId]: "Running" | "OutputFull" }
	WorkerStatus = { Kind = "Event", Direction = "ServerToClient" },
	-- Drills (Phase 5b): Server öffnet das Slot-Fenster nach gültigem Prompt: { MineId, Slot }
	OpenSlotMenu = { Kind = "Event", Direction = "ServerToClient" },
	-- Drill platzieren: (mineId: string, slot: number, drillTypeId: string) -> Result<drillId>
	PlaceDrill = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
	-- Drill entfernen (in der Mine oder am Laptop): (drillId: string) -> Result<drillId>
	RemoveDrill = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
	-- Garage (Phase 6): Server öffnet die Fahrzeugauswahl nach Betreten des Leuchtrings
	OpenGarage = { Kind = "Event", Direction = "ServerToClient" },
	-- Ausparken/Einsteigen: (vehicleId: string) -> Result<vehicleId>
	DriveVehicle = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 5, Window = 10 } },
	-- Einparken (Stellplatz frei, Ladung bleibt): (vehicleId: string) -> Result<vehicleId>
	StoreVehicle = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 5, Window = 10 } },
	-- Fahrzeug zurück auf den Stellplatz: (vehicleId: string) -> Result<vehicleId>
	ResetVehicle = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 3, Window = 10 } },
	-- Beladen am Verladeturm (Phase 6c): Server öffnet das Ladefenster: { VehicleId }
	OpenLoading = { Kind = "Event", Direction = "ServerToClient" },
	-- Laden: (vehicleId, oreId: string?, amount: number?) -> Result<{ Moved }>  (nil = alles/maximal)
	LoadVehicle = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 10, Window = 10 } },
	-- Entladen ins Lager: (vehicleId, oreId: string?) -> Result<{ Moved }>
	UnloadVehicle = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 10, Window = 10 } },
	-- Kapazitäts-Upgrade am Laptop: (kind: "storage" | "elevator") -> Result<{ Capacity: number }>
	BuyUpgrade = { Kind = "Function", Direction = "ClientToServer", RateLimit = { Count = 6, Window = 10 } },
}

return table.freeze(Remotes)
