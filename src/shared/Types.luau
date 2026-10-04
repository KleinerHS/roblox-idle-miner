--!strict
-- Gemeinsame Typen für Server und Client.

-- Menge je ID, z. B. { ore_coal = 12 }
export type ItemCounts = { [string]: number }

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
	Buildings: { [string]: boolean },
	PrestigeCount: number,
}

return {}
