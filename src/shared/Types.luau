--!strict
-- Gemeinsame Typen für Server und Client.

-- Menge je ID, z. B. { ore_coal = 12 }
export type ItemCounts = { [string]: number }

-- Angestellter Worker (docs/05 §21: fest an Mine + Slot gebunden)
export type WorkerRole = "Mining" | "Transport"
export type WorkerRecord = {
	Id: string,
	Role: WorkerRole,
	MineId: string,
	Slot: number,
}

-- Gekaufter Drill (docs/10 §38–39, §64): eigene Instanz-ID je Exemplar.
-- MineId/Slot gesetzt = platziert, nil = im Inventar verfügbar.
export type DrillRecord = {
	Id: string,
	Type: string,
	MineId: string?,
	Slot: number?,
}

-- Gekauftes Fahrzeug (docs/07 §48, D-009, D-016): Ladung gehört zur Fahrzeug-ID.
-- Bay gesetzt = steht auf diesem Garagen-Stellplatz (1/2), nil = eingelagert.
export type VehicleRecord = {
	Id: string,
	Type: string,
	Cargo: ItemCounts,
	Bay: number?,
}

-- Persistentes Spielerprofil. Struktur-Änderungen nur mit neuer DataVersion und
-- Migration (src/server/Data/DataSchema.luau, docs/14 §3).
export type PlayerData = {
	DataVersion: number,

	Cash: number,
	MiningLevel: number,
	-- XP innerhalb des aktuellen Levels
	MiningXP: number,

	Prestige: {
		Count: number,
	},

	Company: {
		Created: boolean,
		Name: string,
		LogoId: string,
		ColorId: string,
	},

	Equipment: {
		OwnedPickaxes: { [string]: boolean },
		EquippedPickaxe: string,
		OwnedBackpacks: { [string]: boolean },
		EquippedBackpack: string,
	},

	-- Inhalt des Rucksacks
	Backpack: ItemCounts,

	-- Gekaufte Tycoon-Bauschritte (BuildSteps-IDs)
	Buildings: { [string]: boolean },

	-- Freigeschaltete Minen (Mines-IDs)
	UnlockedMines: { [string]: boolean },

	-- Robux-Käufe, bleiben bei Prestige (docs/14 §21)
	Entitlements: { [string]: boolean },

	-- Firmenlager (ab DataVersion 2): Gesamtkapazität und Bestand je Material
	Storage: {
		Capacity: number,
		Items: ItemCounts,
	},

	-- Worker (ab DataVersion 3)
	Workers: { [string]: WorkerRecord },
	WorkerSeq: number,

	-- Produktionspuffer (ab DataVersion 3)
	Production: {
		MineBuffers: { [string]: number },
		ElevatorBuffer: ItemCounts,
		ElevatorCapacity: number,
	},

	-- Maschinen (ab DataVersion 4): gekaufte Drills mit Instanz-ID
	Machines: {
		Drills: { [string]: DrillRecord },
		Seq: number,
	},

	-- Fahrzeuge (ab DataVersion 5): Fuhrpark mit Ladung je Fahrzeug
	Vehicles: {
		Owned: { [string]: VehicleRecord },
		Seq: number,
	},

	Stats: {
		FirstJoinTime: number,
		JoinCount: number,
	},

	-- Letzter gültiger Serverzeitpunkt (os.time) für Offline-Berechnung (docs/14 §7)
	LastValidTime: number,
}

-- Was der Client zur Anzeige bekommt (docs/15 §9). Keine serverinternen Felder.
export type StateSnapshot = {
	Cash: number,
	MiningLevel: number,
	MiningXP: number,
	MiningXPRequired: number,
	Company: {
		Created: boolean,
		Name: string,
		LogoId: string,
		ColorId: string,
	},
	EquippedPickaxe: string,
	EquippedBackpack: string,
	OwnedPickaxes: { [string]: boolean },
	OwnedBackpacks: { [string]: boolean },
	Backpack: ItemCounts,
	BackpackCapacity: number,
	StorageCapacity: number,
	StorageItems: ItemCounts,
	Workers: { [string]: WorkerRecord },
	Drills: { [string]: DrillRecord },
	Vehicles: { [string]: VehicleRecord },
	MineBuffers: { [string]: number },
	ElevatorBuffer: ItemCounts,
	ElevatorCapacity: number,
	Buildings: { [string]: boolean },
	PrestigeCount: number,
}

return {}
