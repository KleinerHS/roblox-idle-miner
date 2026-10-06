--!strict
-- Automatisches Beladen am Verladeturm (docs/07 §9–12, D-008, D-009, D-025).
-- Steht ein eigenes Fahrzeug still unter einer Schurre, speist der Turm direkt aus dem
-- Firmenlager in die Ladefläche: alles Verkaufbare, wertvollstes Material zuerst, bis das
-- Fahrzeug voll ist. Keine Bedienung nötig (D-025: manuelles Beladen entfällt).
-- D-030 (Felix): Geladen wird nur, wenn der Spieler im Fahrzeug sitzt (ein nur geparktes
-- Fahrzeug leert das Lager nicht), und solange ein Schmelzer gebaut ist, bleibt schmelzbares
-- Erz im Lager für den Schmelzer.
-- Jeder Transfer ist eine einzige Profiländerung (Lager − n / Fahrzeug + n), ohne Yield
-- dazwischen → keine Duplikation (docs/07 §11). Die Ladung gehört zur Fahrzeug-ID.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Materials = require(Shared.Definitions.Materials)
local Vehicles = require(Shared.Definitions.Vehicles)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)
local SmelterLogic = require(Shared.Util.SmelterLogic)

local GarageTemplate = require(script.Parent.Parent.World.GarageTemplate)
local DataService = require(script.Parent.DataService)
local BuildingService = require(script.Parent.BuildingService)
local VehicleService = require(script.Parent.VehicleService)
local RemoteService = require(script.Parent.RemoteService)

local TICK_SECONDS = 0.5
-- Fahrzeug gilt als "steht", wenn es langsamer ist als das (studs/s)
local STANDSTILL_SPEED = 2

local LoadingService = {}

type BayState = { state: string, vehicleId: string?, extended: boolean }
-- [player][bay] = letzter Zustand (für Anzeige/Schurre/Meldung nur bei Änderung)
local bayStates: { [Player]: { [number]: BayState } } = {}

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

-- Verkaufbare Materialien im Lager, wertvollstes zuerst (D-025); mit Schmelzer ohne
-- schmelzbares Erz (D-030)
local function loadOrder(storage: Types.ItemCounts, keepSmeltable: boolean): { string }
	local ids = {}
	for id, amount in storage do
		local material = Materials.Get(id)
		if amount > 0 and material and material.SellValue and not (keepSmeltable and SmelterLogic.IsSmeltable(id)) then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local ma, mb = Materials.Get(a), Materials.Get(b)
		local va, vb = (ma and ma.SellValue or 0) :: number, (mb and mb.SellValue or 0) :: number
		if va ~= vb then
			return va > vb
		end
		return a < b
	end)
	return ids
end

-- Eigenes Fahrzeug, das still unter der Schurre dieses Stellplatzes steht
local function vehicleUnder(player: Player, data: Types.PlayerData, point: BasePart): (string?, Model?)
	for id in data.Vehicles.Owned do
		local model = VehicleService.GetModel(player, id)
		local chassis = model and model.PrimaryPart
		if model and chassis then
			local bed = model:FindFirstChild("CargoFill", true)
			local ref = if bed and bed:IsA("BasePart") then bed.Position else chassis.Position
			local flat = Vector3.new(point.Position.X - ref.X, 0, point.Position.Z - ref.Z)
			if flat.Magnitude <= LayoutConfig.Garage.LoadDistance and chassis.AssemblyLinearVelocity.Magnitude < STANDSTILL_SPEED then
				return id, model
			end
		end
	end
	return nil, nil
end

local function setChute(garage: Model, bay: number, bottomY: number?)
	for part, goal in GarageTemplate.chuteGoals(garage, bay, bottomY) do
		TweenService:Create(part, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), goal):Play()
	end
end

-- Ein Takt für einen Stellplatz; gibt den neuen Zustand zurück
local function tickBay(player: Player, data: Types.PlayerData, garage: Model, bay: number): BayState
	local point = garage:FindFirstChild(`LoadPoint{bay}`)
	if not (point and point:IsA("BasePart")) then
		return { state = "Idle", vehicleId = nil, extended = false }
	end
	local vehicleId, model = vehicleUnder(player, data, point)
	local record = vehicleId and data.Vehicles.Owned[vehicleId]
	local def = record and Vehicles.Get(record.Type)
	if not (vehicleId and model and record and def) then
		return { state = "Idle", vehicleId = nil, extended = false }
	end
	local free = def.Capacity - sum(record.Cargo)
	if free <= 0 then
		return { state = "Full", vehicleId = vehicleId, extended = false }
	end
	-- Nur beladen, wenn der Spieler am Steuer sitzt (D-030)
	if VehicleService.GetDriven(player) ~= vehicleId then
		return { state = "Parked", vehicleId = vehicleId, extended = false }
	end
	local budget = math.min(free, math.floor(BalanceConfig.Loading.UnitsPerSecond * TICK_SECONDS))
	local plan: { [string]: number } = {}
	local total = 0
	for _, id in loadOrder(data.Storage.Items, data.Buildings.build_smelter == true) do
		local take = math.min(data.Storage.Items[id], budget - total)
		if take > 0 then
			plan[id] = take
			total += take
		end
		if total >= budget then
			break
		end
	end
	if total <= 0 then
		return { state = "NoStock", vehicleId = vehicleId, extended = false }
	end
	local id = vehicleId
	DataService.MutateQuiet(player, function(d)
		local cargo = d.Vehicles.Owned[id].Cargo
		for material, n in plan do
			d.Storage.Items[material] -= n
			if d.Storage.Items[material] <= 0 then
				d.Storage.Items[material] = nil
			end
			cargo[material] = (cargo[material] or 0) + n
		end
	end)
	VehicleService.RefreshCargo(player, id)
	return { state = "Loading", vehicleId = vehicleId, extended = true }
end

local function tickPlayer(player: Player)
	local data = DataService.Get(player)
	local garage = BuildingService.GetModel(player, "build_garage")
	if not (data and garage and data.Buildings.build_storage) then
		return
	end
	local states = bayStates[player] or {}
	bayStates[player] = states
	for bay = 1, Vehicles.BayCount do
		local new = tickBay(player, data, garage, bay)
		local old = states[bay]
		-- Anzeige
		local record = new.vehicleId and data.Vehicles.Owned[new.vehicleId]
		local def = record and Vehicles.Get(record.Type)
		local title = if def then `BAY {bay} · {string.upper(def.DisplayName)}` else `BAY {bay}`
		local value = "READY"
		if record and def then
			local fill = `{NumberFormat.withSeparators(sum(record.Cargo))} / {NumberFormat.withSeparators(def.Capacity)}`
			value = if new.state == "Full" then `FULL · {fill}`
				elseif new.state == "NoStock" then "STORAGE EMPTY"
				elseif new.state == "Parked" then `GET IN TO LOAD · {fill}`
				else fill
		end
		GarageTemplate.setBayState(garage, bay, new.state, title, value)
		-- Schurre nur bei Zustandswechsel bewegen
		if not old or old.extended ~= new.extended or old.vehicleId ~= new.vehicleId then
			local bottomY: number? = nil
			if new.extended and new.vehicleId then
				local model = VehicleService.GetModel(player, new.vehicleId)
				if model then
					local cf, size = model:GetBoundingBox()
					bottomY = cf.Position.Y + size.Y / 2
				end
			end
			setChute(garage, bay, bottomY)
		end
		-- Meldung, wenn ein Fahrzeug voll geworden ist
		if new.state == "Full" and old and old.state == "Loading" and old.vehicleId == new.vehicleId then
			RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "VEHICLE_LOADED" })
		end
		states[bay] = new
	end
end

function LoadingService.Init() end

function LoadingService.Start()
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(tickPlayer, player)
				if not ok then
					warn(`[Server][LoadingService] Tick-Fehler {player.Name}: {err}`)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		bayStates[player] = nil
	end)
	-- Neu gebaute Garage: Anzeige/Schurren neu aufbauen
	BuildingService.ModelBuilt:Connect(function(player, stepId)
		if stepId == "build_garage" then
			bayStates[player] = nil
		end
	end)
end

return LoadingService
