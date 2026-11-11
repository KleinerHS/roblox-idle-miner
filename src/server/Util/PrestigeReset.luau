--!strict
-- Prestige-Reset als reine Funktion auf dem Profil (docs/12 §53–64, D-012, D-033), damit
-- PrestigeService ihn atomar in DataService.Mutate ausführt und er ohne Spieler testbar ist.
-- Seit D-088 (Felix' Balancing-Entwurf 2026-11-11): nur Spitzhacken und Rucksäcke bleiben;
-- Fahrzeuge, Mining Luck und Offline-Upgrades werden zurückgesetzt.

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
		-- IDs laufen weiter, damit keine alte Instanz-ID erneut vergeben wird
		WorkerSeq = d.WorkerSeq,
		MachineSeq = d.Machines.Seq,
		VehicleSeq = d.Vehicles.Seq,
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
	-- Fahrzeuge werden zurückgesetzt (D-088, ersetzt D-012), Vorlage = kein Fahrzeug
	d.Vehicles.Seq = keep.VehicleSeq
	-- Mining Luck zurück auf 0 (D-088); Spitzhacken und Rucksäcke bleiben
	d.Equipment.LuckLevel = 0
	-- Alte Produktion darf nach Prestige nichts mehr erzeugen
	d.LastValidTime = now
end

return PrestigeReset
