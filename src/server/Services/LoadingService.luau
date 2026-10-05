--!strict
-- Beladen am Verladeturm (docs/07 §9–12, D-008, D-009): Fahrzeug steht unter einer Schurre,
-- der Spieler wählt, welches Material aus dem Firmenlager ins Fahrzeug geht. Entladen zurück
-- ins Lager ist ebenfalls möglich. Jeder Transfer ist eine einzige Änderung im Profil
-- (Lager − n, Fahrzeug + n), ohne Yield dazwischen → keine Duplikation (docs/07 §11).
-- Die Ladung gehört zur Fahrzeug-ID und bleibt beim Einparken/Verlassen erhalten.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Ores = require(Shared.Definitions.Ores)
local Vehicles = require(Shared.Definitions.Vehicles)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Log = require(Shared.Util.Log)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local BuildingService = require(script.Parent.BuildingService)
local VehicleService = require(script.Parent.VehicleService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "LoadingService"

local LoadingService = {}

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

-- Erze in fester Reihenfolge (Tier)
local function sortedIds(items: Types.ItemCounts): { string }
	local ids = {}
	for id, amount in items do
		if amount > 0 then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local oa, ob = Ores.Get(a), Ores.Get(b)
		return (if oa then oa.Tier else 999) < (if ob then ob.Tier else 999)
	end)
	return ids
end

-- Ladefläche des Fahrzeugs (CargoFill) bzw. Chassis als Bezugspunkt
local function bedPosition(model: Model): Vector3?
	local bed = model:FindFirstChild("CargoFill")
	if bed and bed:IsA("BasePart") then
		return bed.Position
	end
	return if model.PrimaryPart then model.PrimaryPart.Position else nil
end

-- Steht das Fahrzeug unter einer Schurre der eigenen Garage?
local function isUnderTower(player: Player, model: Model): boolean
	local garage = BuildingService.GetModel(player, "build_garage")
	local bed = bedPosition(model)
	if not (garage and bed) then
		return false
	end
	for bay = 1, Vehicles.BayCount do
		local point = garage:FindFirstChild(`LoadPoint{bay}`)
		if point and point:IsA("BasePart") then
			local flat = Vector3.new(point.Position.X - bed.X, 0, point.Position.Z - bed.Z)
			if flat.Magnitude <= LayoutConfig.Garage.LoadDistance then
				return true
			end
		end
	end
	return false
end

local function check(player: Player, vehicleId: unknown): (Types.PlayerData?, Types.VehicleRecord?, string?)
	if typeof(vehicleId) ~= "string" then
		return nil, nil, Result.Codes.INVALID_ARGUMENT
	end
	local data = DataService.Get(player)
	if not data then
		return nil, nil, Result.Codes.DATA_NOT_LOADED
	end
	local record = data.Vehicles.Owned[vehicleId :: string]
	if not record then
		return nil, nil, Result.Codes.NOT_OWNED
	end
	if not data.Buildings.build_storage or not data.Buildings.build_garage then
		return nil, nil, Result.Codes.GARAGE_REQUIRED
	end
	local model = VehicleService.GetModel(player, record.Id)
	if not model or not isUnderTower(player, model) then
		return nil, nil, Result.Codes.NO_VEHICLE
	end
	return data, record, nil
end

-- Laden: oreId nil = alles (nach Tier) bis zur Kapazität; amount nil = so viel wie möglich
local function load(player: Player, vehicleId: unknown, oreId: unknown, amount: unknown)
	if oreId ~= nil and (typeof(oreId) ~= "string" or not Ores.Get(oreId :: string)) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	if amount ~= nil and (typeof(amount) ~= "number" or amount ~= amount or amount < 1 or amount % 1 ~= 0 or amount > 1e9) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data, record, code = check(player, vehicleId)
	if not data or not record then
		return Result.err(code or Result.Codes.INTERNAL_ERROR)
	end
	local def = Vehicles.Get(record.Type)
	local free = (if def then def.Capacity else 0) - sum(record.Cargo)
	if free <= 0 then
		return Result.err(Result.Codes.VEHICLE_FULL)
	end
	local ids = if oreId then { oreId :: string } else sortedIds(data.Storage.Items)
	local plan: { [string]: number } = {}
	local total = 0
	for _, id in ids do
		local stock = data.Storage.Items[id] or 0
		local take = math.min(stock, free - total, if amount then (amount :: number) - total else math.huge)
		if take > 0 then
			plan[id] = take
			total += take
		end
		if total >= free then
			break
		end
	end
	if total <= 0 then
		return Result.err(Result.Codes.NOTHING_TO_LOAD)
	end
	local id = record.Id
	DataService.Mutate(player, function(d)
		local cargo = d.Vehicles.Owned[id].Cargo
		for ore, n in plan do
			d.Storage.Items[ore] -= n
			if d.Storage.Items[ore] <= 0 then
				d.Storage.Items[ore] = nil
			end
			cargo[ore] = (cargo[ore] or 0) + n
		end
	end)
	DataService.RequestSave(player)
	VehicleService.RefreshCargo(player, id)
	Log.debug(TAG, `{player.Name} lädt {total} in {id}`)
	return Result.ok({ Moved = total })
end

-- Entladen: alles (oder ein Erz) zurück ins Lager, so weit Platz ist
local function unload(player: Player, vehicleId: unknown, oreId: unknown)
	if oreId ~= nil and (typeof(oreId) ~= "string" or not Ores.Get(oreId :: string)) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data, record, code = check(player, vehicleId)
	if not data or not record then
		return Result.err(code or Result.Codes.INTERNAL_ERROR)
	end
	local free = data.Storage.Capacity - sum(data.Storage.Items)
	if free <= 0 then
		return Result.err(Result.Codes.STORAGE_FULL)
	end
	local ids = if oreId then { oreId :: string } else sortedIds(record.Cargo)
	local plan: { [string]: number } = {}
	local total = 0
	for _, id in ids do
		local take = math.min(record.Cargo[id] or 0, free - total)
		if take > 0 then
			plan[id] = take
			total += take
		end
	end
	if total <= 0 then
		return Result.err(Result.Codes.NOTHING_TO_SELL)
	end
	local id = record.Id
	DataService.Mutate(player, function(d)
		local cargo = d.Vehicles.Owned[id].Cargo
		for ore, n in plan do
			cargo[ore] -= n
			if cargo[ore] <= 0 then
				cargo[ore] = nil
			end
			d.Storage.Items[ore] = (d.Storage.Items[ore] or 0) + n
		end
	end)
	DataService.RequestSave(player)
	VehicleService.RefreshCargo(player, id)
	return Result.ok({ Moved = total })
end

function LoadingService.Init()
	RemoteService.OnInvoke("LoadVehicle", load)
	RemoteService.OnInvoke("UnloadVehicle", unload)
end

function LoadingService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if prompt:GetAttribute("LoadingTower") ~= true then
			return
		end
		if not PlotService.IsOwnerOf(player, prompt) then
			RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = Result.Codes.NOT_OWNER })
			return
		end
		local data = DataService.Get(player)
		if not data then
			return
		end
		-- Eigenes Fahrzeug unter einer Schurre suchen (gefahrenes zuerst)
		local drivenId = VehicleService.GetDriven(player)
		local candidates: { string } = {}
		if drivenId then
			table.insert(candidates, drivenId)
		end
		for id in data.Vehicles.Owned do
			if id ~= drivenId then
				table.insert(candidates, id)
			end
		end
		for _, id in candidates do
			local model = VehicleService.GetModel(player, id)
			if model and isUnderTower(player, model) then
				RemoteService.FireClient("OpenLoading", player, { VehicleId = id })
				return
			end
		end
		RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = Result.Codes.NO_VEHICLE })
	end)
end

return LoadingService
