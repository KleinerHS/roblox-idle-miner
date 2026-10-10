--!strict
-- Prestige-Reset als reine Funktion auf dem Profil (docs/12 §53–64, D-012, D-033), damit
-- PrestigeService ihn atomar in DataService.Mutate ausführt und er ohne Spieler testbar ist.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage:WaitForChild("Shared").Types)
local DataSchema = require(script.Parent.Parent.Data.DataSchema)

local PrestigeReset = {}

-- Neues Profil aus der Vorlage, mit allem, was Prestige überdauert
function PrestigeReset.apply(d: Types.PlayerData, now: number)
	local template = DataSchema.getTemplate()
	local keep = {
		Prestige = { Count = d.Prestige.Count + 1 },
		Company = d.Company,
		Equipment = d.Equipment,
		Entitlements = d.Entitlements,
		Settings = d.Settings,
		Stats = d.Stats,
		Vehicles = d.Vehicles,
		-- IDs laufen weiter, damit keine alte Instanz-ID erneut vergeben wird
		WorkerSeq = d.WorkerSeq,
		MachineSeq = d.Machines.Seq,
	}
	for key in d :: any do
		(d :: any)[key] = nil
	end
	for key, value in template :: any do
		(d :: any)[key] = value
	end
	d.Prestige = keep.Prestige
	d.Company = keep.Company
	d.Equipment = keep.Equipment
	d.Entitlements = keep.Entitlements
	d.Settings = keep.Settings
	d.Stats = keep.Stats
	d.WorkerSeq = keep.WorkerSeq
	d.Machines.Seq = keep.MachineSeq
	-- Fahrzeuge bleiben (D-012), Ladung ist Material und wird zurückgesetzt; ohne Garage
	-- stehen sie eingelagert (kein Stellplatz)
	d.Vehicles = keep.Vehicles
	for _, record in d.Vehicles.Owned do
		record.Cargo = {}
		record.Bay = nil
	end
	-- Alte Produktion darf nach Prestige nichts mehr erzeugen
	d.LastValidTime = now
end

return PrestigeReset
