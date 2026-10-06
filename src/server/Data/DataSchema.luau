--!strict
-- Datenschema v7: zentrales Default-Profil und Migrationen (docs/14 §3, §20).
-- Regeln:
--  * Defaults gibt es nur hier.
--  * Jede Strukturänderung erhöht CURRENT_VERSION und bekommt eine Migration
--    in MIGRATIONS[alteVersion] (alteVersion → alteVersion + 1).
--  * Migrationen ändern nur Struktur, nie Werte "nach Gefühl".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Pickaxes = require(Shared.Definitions.Pickaxes)
local Backpacks = require(Shared.Definitions.Backpacks)
local Mines = require(Shared.Definitions.Mines)
local Types = require(Shared.Types)

local CURRENT_VERSION = 7

local DataSchema = {
	CurrentVersion = CURRENT_VERSION,
}

-- Vorlage für neue Spieler. Wird auch genutzt, um fehlende Felder alter Profile zu
-- ergänzen (Reconcile), deshalb keine zeitabhängigen Werte hier.
local TEMPLATE: Types.PlayerData = {
	DataVersion = CURRENT_VERSION,

	Cash = BalanceConfig.StartCash,
	MiningLevel = 1,
	MiningXP = 0,

	Prestige = {
		Count = 0,
	},

	Company = {
		Created = false,
		Name = "",
		LogoId = "",
		ColorId = "",
	},

	Equipment = {
		OwnedPickaxes = { [Pickaxes.StarterId] = true },
		EquippedPickaxe = Pickaxes.StarterId,
		OwnedBackpacks = { [Backpacks.StarterId] = true },
		EquippedBackpack = Backpacks.StarterId,
	},

	Backpack = {},
	Buildings = {},
	UnlockedMines = { [Mines.StartMineId] = true },
	Entitlements = {},

	-- Firmenlager (v2): ein gemeinsamer Bestand über alle Materialien (docs/06 §13–14)
	Storage = {
		Capacity = BalanceConfig.Storage.StartCapacity,
		Items = {},
	},

	-- Worker (v3): angestellte Mitarbeiter je Arbeitsplatz (docs/05 §21)
	Workers = {},
	WorkerSeq = 0,

	-- Produktionspuffer (v3): Erz an den Mining-Slots je Mine und im Elevator (docs/06 §20)
	Production = {
		MineBuffers = {},
		ElevatorBuffer = {},
		ElevatorCapacity = BalanceConfig.Elevator.StartCapacity,
	},

	-- Maschinen (v4): gekaufte Drills mit Instanz-ID, platziert oder im Inventar (docs/10 §38)
	Machines = {
		Drills = {},
		-- Förderbänder (v7) mit Instanz-ID, eingesetzt an einem festen Platz oder im Inventar
		Conveyors = {},
		Seq = 0,
	},

	-- Fahrzeuge (v5): Fuhrpark, Ladung je Fahrzeug, Garagen-Stellplatz (D-009, D-016)
	Vehicles = {
		Owned = {},
		Seq = 0,
	},

	-- Schmelzer (v6): Einfülltrichter, Barrenablage, Priorität ("" = wertvollstes zuerst, D-011)
	Smelter = {
		Input = {},
		Output = {},
		Priority = "",
	},

	Stats = {
		FirstJoinTime = 0,
		JoinCount = 0,
	},

	LastValidTime = 0,
}

-- Tiefe Kopie (für neue Profile, damit die Vorlage nie verändert wird).
local function deepCopy<T>(value: T): T
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value :: any do
		copy[k] = deepCopy(v)
	end
	return copy :: any
end

function DataSchema.getTemplate(): Types.PlayerData
	return deepCopy(TEMPLATE)
end

-- MIGRATIONS[n] überführt ein Profil von Version n nach n + 1.
local MIGRATIONS: { [number]: (data: { [string]: any }) -> () } = {
	-- v1 → v2: Firmenlager ergänzt (Phase 4)
	[1] = function(data)
		if typeof(data.Storage) ~= "table" then
			data.Storage = { Capacity = BalanceConfig.Storage.StartCapacity, Items = {} }
		end
	end,
	-- v2 → v3: Worker und Produktionspuffer ergänzt (Phase 4b)
	[2] = function(data)
		if typeof(data.Workers) ~= "table" then
			data.Workers = {}
		end
		if typeof(data.WorkerSeq) ~= "number" then
			data.WorkerSeq = 0
		end
		if typeof(data.Production) ~= "table" then
			data.Production = { MineBuffers = {}, ElevatorBuffer = {}, ElevatorCapacity = BalanceConfig.Elevator.StartCapacity }
		end
	end,
	-- v3 → v4: Maschinen-Inventar (Drills) ergänzt (Phase 5)
	[3] = function(data)
		if typeof(data.Machines) ~= "table" then
			data.Machines = { Drills = {}, Seq = 0 }
		end
	end,
	-- v4 → v5: Fahrzeuge ergänzt (Phase 6)
	[4] = function(data)
		if typeof(data.Vehicles) ~= "table" then
			data.Vehicles = { Owned = {}, Seq = 0 }
		end
	end,
	-- v5 → v6: Schmelzer ergänzt (Phase 7)
	[5] = function(data)
		if typeof(data.Smelter) ~= "table" then
			data.Smelter = { Input = {}, Output = {}, Priority = "" }
		end
	end,
	-- v6 → v7: Förderbänder ergänzt (Phase 7b)
	[6] = function(data)
		if typeof(data.Machines) == "table" and typeof(data.Machines.Conveyors) ~= "table" then
			data.Machines.Conveyors = {}
		end
	end,
}

-- Bringt ein geladenes Profil auf CURRENT_VERSION. Gibt false zurück, wenn das Profil
-- von einer neueren Spielversion stammt (dann darf dieser Server es nicht beschreiben).
function DataSchema.migrate(data: { [string]: any }): (boolean, string?)
	local version = data.DataVersion
	if typeof(version) ~= "number" then
		-- Profil ohne Version = frisch angelegt aus der Vorlage
		data.DataVersion = CURRENT_VERSION
		return true, nil
	end
	if version > CURRENT_VERSION then
		return false, `Profil-Version {version} ist neuer als Server-Version {CURRENT_VERSION}`
	end
	while version < CURRENT_VERSION do
		local step = MIGRATIONS[version]
		if not step then
			return false, `Keine Migration von Version {version}`
		end
		step(data)
		version += 1
		data.DataVersion = version
	end
	return true, nil
end

return table.freeze(DataSchema)
