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
}

return table.freeze(Remotes)
