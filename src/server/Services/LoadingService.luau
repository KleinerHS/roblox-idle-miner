--!strict
-- Automatisches Beladen am Verladeturm (docs/07 §9–12, D-008, D-009, D-025).
-- Seit Phase 18b (D-052) gibt es einen Verladerüssel über der Durchfahr-Verladestraße.
-- Steht ein eigenes Fahrzeug still unter dem Rüssel, speist der Turm direkt aus dem
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
-- Ladefläche muss so genau unter dem Rüssel stehen (studs, längs / quer), sonst Hinweis
local ALIGN_ALONG = 2.5
local ALIGN_SIDE = 2
-- Rüssel endet so weit über der Ladung bzw. der leeren Ladefläche
local SPOUT_CLEARANCE = 0.6
-- Fahrzeug gilt als "steht", wenn es langsamer ist als das (studs/s)
local STANDSTILL_SPEED = 2

local LoadingService = {}

type BayState = { state: string, vehicleId: string?, extended: boolean, hint: string?, bottomY: number? }
-- [player][Rüssel] = letzter Zustand (für Anzeige/Schurre/Meldung nur bei Änderung)
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
	local point = garage:FindFirstChild(`LoadPoint{bay}`, true)
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
	-- Ladefläche mittig unter dem Rüssel? Sonst Hinweis zum Rangieren (Felix 2026-10-13)
	local bed = model:FindFirstChild("CargoFill", true)
	if bed and bed:IsA("BasePart") then
		local d = Vector3.new(point.Position.X - bed.Position.X, 0, point.Position.Z - bed.Position.Z)
		local forward = Vector3.new(bed.CFrame.LookVector.X, 0, bed.CFrame.LookVector.Z).Unit
		local right = Vector3.new(-forward.Z, 0, forward.X)
		local along, side = d:Dot(forward), d:Dot(right)
		if math.abs(along) > ALIGN_ALONG or math.abs(side) > ALIGN_SIDE then
			local hint = if math.abs(along) > ALIGN_ALONG then (if along > 0 then "Move forward" else "Move back") else "Center under the chute"
			return { state = "Align", vehicleId = vehicleId, extended = false, hint = hint }
		end
	end
	-- Nur beladen, wenn der Spieler am Steuer sitzt (D-030)
	if VehicleService.GetDriven(player) ~= vehicleId then
		return { state = "Parked", vehicleId = vehicleId, extended = false }
	end
	-- Jedes Fahrzeug in höchstens FullLoadSeconds voll (D-046)
	local rate = math.max(BalanceConfig.Loading.UnitsPerSecond, def.Capacity / BalanceConfig.Loading.FullLoadSeconds)
	local budget = math.min(free, math.floor(rate * TICK_SECONDS))
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
	-- Rüssel bis kurz über die Ladung (bzw. die leere Ladefläche), wächst mit der Ladung mit
	local bottomY: number? = nil
	local fill = model:FindFirstChild("CargoFill", true)
	if fill and fill:IsA("BasePart") then
		local surface = fill.Position.Y - fill.Size.Y / 2
		-- Geschlossener Aufbau (CargoHidden): Rüssel stoppt über dem Dach (Oberkante CargoFill)
		local top = if fill.Transparency < 1 or fill:GetAttribute("CargoHidden") then fill.Position.Y + fill.Size.Y / 2 else surface
		bottomY = top + SPOUT_CLEARANCE
	end
	return { state = "Loading", vehicleId = vehicleId, extended = true, bottomY = bottomY }
end

local function tickPlayer(player: Player)
	local data = DataService.Get(player)
	local garage = BuildingService.GetModel(player, "build_garage")
	if not (data and garage and data.Buildings.build_storage) then
		return
	end
	local states = bayStates[player] or {}
	bayStates[player] = states
	for bay = 1, LayoutConfig.Garage.ChuteCount do
		local new = tickBay(player, data, garage, bay)
		local old = states[bay]
		-- Anzeige
		local record = new.vehicleId and data.Vehicles.Owned[new.vehicleId]
		local def = record and Vehicles.Get(record.Type)
		-- freundliche, schwebende Schrift (Felix 2026-10-13): normale Groß-/Kleinschreibung
		local title = if def then `Loading · {def.DisplayName}` else "Loading"
		local value = "Ready"
		if record and def then
			local fill = `{NumberFormat.withSeparators(sum(record.Cargo))} / {NumberFormat.withSeparators(def.Capacity)}`
			value = if new.state == "Full" then `Full · {fill}`
				elseif new.state == "NoStock" then "Storage is empty"
				elseif new.state == "Parked" then `Hop in to load · {fill}`
				elseif new.state == "Align" then new.hint or "Center under the chute"
				else fill
		end
		GarageTemplate.setBayState(garage, bay, new.state, title, value)
		-- Rüssel nur bei Zustandswechsel oder spürbar höherer Ladung bewegen
		local moved = not old or old.extended ~= new.extended or old.vehicleId ~= new.vehicleId
		if not moved and new.extended and old and old.bottomY and new.bottomY then
			moved = math.abs(old.bottomY - new.bottomY) > 0.3
		end
		if moved then
			setChute(garage, bay, if new.extended then new.bottomY else nil)
		else
			new.bottomY = old and old.bottomY or new.bottomY
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
