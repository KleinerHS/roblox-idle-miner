--!strict
-- Fahrzeuge in der Garage (docs/07 §2–4, §12, §16–19, §38–40, D-009, D-016).
--   * Leuchtring in der Garage öffnet die Fahrzeugauswahl (nur Besitzer).
--   * DRIVE: Fahrzeug steht auf einem freien Stellplatz (max. 2 in der Halle) und der Spieler
--     sitzt direkt am Steuer. Steht es schon in der Halle, wird er nur hineingesetzt.
--   * STORE: Fahrzeug wird eingeparkt (Stellplatz frei). Ladung bleibt am Fahrzeug (D-009).
--   * RESET: steckengebliebenes Fahrzeug zurück auf seinen Stellplatz, Ladung unverändert.
--   * Nur der Besitzer kann fahren; Fahrzeuge kollidieren nicht mit anderen Fahrzeugen,
--     Spielern oder Worker-Figuren (docs/07 §16–17).
--   * Rolltor der Halle öffnet automatisch bei Annäherung (docs/07 §19).
-- Die Ladung ist reine Datenhaltung im Profil; das Modell ist nur Darstellung (docs/07 §44).

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Vehicles = require(Shared.Definitions.Vehicles)
local CompanyIdentity = require(Shared.Definitions.CompanyIdentity)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)

local VehicleModelBuilder = require(script.Parent.Parent.World.VehicleModelBuilder)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local BuildingService = require(script.Parent.BuildingService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "VehicleService"
local GARAGE_STEP = "build_garage"
local GROUP_VEHICLES = "Vehicles"
-- Abstand zum Ring für Auswahl-Aktionen (Schutz gegen Remote-Aufrufe von woanders)
local RING_DISTANCE = 16
-- Torautomatik: Abstände zur Tormitte, Prüfintervall, Offenhaltezeit
local DOOR_PLAYER_RANGE = 16
local DOOR_VEHICLE_RANGE = 36
local DOOR_CHECK_SECONDS = 0.35
local DOOR_HOLD_SECONDS = 3

local VehicleService = {
	-- (player, vehicleId) wenn ein Fahrzeug gespawnt oder entfernt wurde
	VehiclesChanged = Signal.new() :: Signal.Signal<Player>,
}

-- [player] = { [vehicleId] = Model }
local spawned: { [Player]: { [string]: Model } } = {}
local ringTouch: { [Player]: number } = {}

local function folder(): Folder
	local f = workspace:FindFirstChild("Vehicles")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Vehicles"
		f.Parent = workspace
	end
	return f :: Folder
end

local function garageModel(player: Player): Model?
	return BuildingService.GetModel(player, GARAGE_STEP)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function nearRing(player: Player): boolean
	local garage = garageModel(player)
	local ring = garage and garage:FindFirstChild("GarageRing")
	local root = rootOf(player)
	if not (ring and ring:IsA("BasePart") and root) then
		return false
	end
	return (root.Position - ring.Position).Magnitude <= RING_DISTANCE
end

local function freeBay(data: Types.PlayerData): number?
	local used: { [number]: boolean } = {}
	for _, v in data.Vehicles.Owned do
		if v.Bay then
			used[v.Bay] = true
		end
	end
	for bay = 1, Vehicles.BayCount do
		if not used[bay] then
			return bay
		end
	end
	return nil
end

local function cargoTotal(cargo: Types.ItemCounts): number
	local total = 0
	for _, amount in cargo do
		total += amount
	end
	return total
end

local function setGroup(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = GROUP_VEHICLES
		end
	end
end

-- Nur der Besitzer darf fahren (docs/07 §17)
local function guardSeat(model: Model, owner: Player)
	local seat = model:FindFirstChild("DriverSeat")
	if not (seat and seat:IsA("VehicleSeat")) then
		return
	end
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local humanoid = seat.Occupant
		if not humanoid then
			return
		end
		local player = Players:GetPlayerFromCharacter(humanoid.Parent)
		if player ~= owner then
			local weld = seat:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
			humanoid.Sit = false
			humanoid.Jump = true
			if player then
				RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = Result.Codes.NOT_OWNER })
			end
		end
	end)
end

local function despawn(player: Player, vehicleId: string)
	local list = spawned[player]
	local model = list and list[vehicleId]
	if not model then
		return
	end
	list[vehicleId] = nil
	local seat = model:FindFirstChild("DriverSeat")
	if seat and seat:IsA("VehicleSeat") and seat.Occupant then
		seat.Occupant.Sit = false
	end
	model:Destroy()
end

local function updateCargoVisual(player: Player, vehicleId: string)
	local data = DataService.Get(player)
	local record = data and data.Vehicles.Owned[vehicleId]
	local model = spawned[player] and spawned[player][vehicleId]
	local def = record and Vehicles.Get(record.Type)
	if record and model and def then
		VehicleModelBuilder.setCargoVisual(model, cargoTotal(record.Cargo) / def.Capacity)
		model:SetAttribute("Cargo", cargoTotal(record.Cargo))
	end
end

-- Fahrzeug auf seinem Stellplatz erscheinen lassen
local function spawnAtBay(player: Player, record: Types.VehicleRecord): Model?
	local def = Vehicles.Get(record.Type)
	local garage = garageModel(player)
	local bayPart = garage and record.Bay and garage:FindFirstChild(`BaySpawn{record.Bay}`)
	local data = DataService.Get(player)
	if not (def and bayPart and bayPart:IsA("BasePart") and data) then
		return nil
	end
	despawn(player, record.Id)
	local floorCF = bayPart.CFrame * CFrame.new(0, -bayPart.Size.Y / 2, 0)
	local model = VehicleModelBuilder.build(def, floorCF + Vector3.new(0, 0.15, 0), true)
	model.Name = `{player.Name}_{record.Id}`
	model:SetAttribute("VehicleId", record.Id)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Bay", record.Bay)
	model:SetAttribute("Capacity", def.Capacity)
	local color = CompanyIdentity.ColorById[data.Company.ColorId]
	VehicleModelBuilder.applyCompany(model, if color then color.Color else nil, data.Company.Name)
	setGroup(model)
	guardSeat(model, player)
	model.Parent = folder()
	-- Physik gehört dem Fahrer (flüssiges Fahren); der Server prüft alle Wirtschaftsaktionen
	local chassis = model.PrimaryPart
	if chassis then
		pcall(function()
			chassis:SetNetworkOwner(player)
		end)
	end
	spawned[player] = spawned[player] or {}
	spawned[player][record.Id] = model
	updateCargoVisual(player, record.Id)
	return model
end

local function seatPlayer(player: Player, model: Model)
	local seat = model:FindFirstChild("DriverSeat")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if seat and seat:IsA("VehicleSeat") and humanoid and humanoid.Health > 0 then
		if humanoid.SeatPart then
			humanoid.Sit = false
			task.wait()
		end
		seat:Sit(humanoid)
	end
end

local function checkGarage(player: Player): (Types.PlayerData?, string?)
	local data = DataService.Get(player)
	if not data then
		return nil, Result.Codes.DATA_NOT_LOADED
	end
	if not data.Buildings[GARAGE_STEP] then
		return nil, Result.Codes.GARAGE_REQUIRED
	end
	if not nearRing(player) then
		return nil, Result.Codes.TOO_FAR
	end
	return data, nil
end

-- DRIVE: ausparken (freier Stellplatz) bzw. einsteigen, wenn schon in der Halle
local function drive(player: Player, vehicleId: unknown)
	if typeof(vehicleId) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data, code = checkGarage(player)
	if not data then
		return Result.err(code or Result.Codes.INTERNAL_ERROR)
	end
	local record = data.Vehicles.Owned[vehicleId :: string]
	if not record then
		return Result.err(Result.Codes.NOT_OWNED)
	end
	if not record.Bay then
		local bay = freeBay(data)
		if not bay then
			return Result.err(Result.Codes.BAYS_FULL)
		end
		-- Stellplatz ohne Yield vergeben → kein doppeltes Ausparken durch Spam
		DataService.Mutate(player, function(d)
			d.Vehicles.Owned[vehicleId :: string].Bay = bay
		end)
		DataService.RequestSave(player)
	end
	local current = DataService.Get(player)
	local fresh = current and current.Vehicles.Owned[vehicleId :: string]
	if not fresh then
		return Result.err(Result.Codes.INTERNAL_ERROR)
	end
	local model = spawned[player] and spawned[player][fresh.Id]
	if not model or not model.Parent then
		model = spawnAtBay(player, fresh)
	end
	if not model then
		return Result.err(Result.Codes.INTERNAL_ERROR)
	end
	seatPlayer(player, model)
	Log.debug(TAG, `{player.Name} fährt {fresh.Type} ({fresh.Id}) von Stellplatz {fresh.Bay}`)
	VehicleService.VehiclesChanged:Fire(player)
	return Result.ok(fresh.Id)
end

-- STORE: einparken, Stellplatz wird frei, Ladung bleibt (D-009)
local function store(player: Player, vehicleId: unknown)
	if typeof(vehicleId) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data, code = checkGarage(player)
	if not data then
		return Result.err(code or Result.Codes.INTERNAL_ERROR)
	end
	local record = data.Vehicles.Owned[vehicleId :: string]
	if not record then
		return Result.err(Result.Codes.NOT_OWNED)
	end
	if not record.Bay then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	despawn(player, record.Id)
	DataService.Mutate(player, function(d)
		d.Vehicles.Owned[vehicleId :: string].Bay = nil
	end)
	DataService.RequestSave(player)
	VehicleService.VehiclesChanged:Fire(player)
	return Result.ok(record.Id)
end

-- RESET: zurück auf den Stellplatz (von überall, docs/07 §39). Ladung unverändert.
local function reset(player: Player, vehicleId: unknown)
	if typeof(vehicleId) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	local record = data.Vehicles.Owned[vehicleId :: string]
	if not record then
		return Result.err(Result.Codes.NOT_OWNED)
	end
	if not record.Bay then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	local drivenId = VehicleService.GetDriven(player)
	local model = spawnAtBay(player, record)
	if not model then
		return Result.err(Result.Codes.INTERNAL_ERROR)
	end
	-- Wer am Steuer saß, sitzt danach wieder am Steuer
	if drivenId == record.Id then
		task.defer(seatPlayer, player, model)
	end
	RemoteService.FireClient("Notify", player, { Kind = "Info", Code = "VEHICLE_RESET" })
	return Result.ok(record.Id)
end

-- Alle Fahrzeuge mit Stellplatz in die Halle stellen (nach Join / Garagenbau)
local function spawnParked(player: Player)
	local data = DataService.Get(player)
	if not data or not data.Buildings[GARAGE_STEP] then
		return
	end
	for _, record in data.Vehicles.Owned do
		if record.Bay and not (spawned[player] and spawned[player][record.Id]) then
			spawnAtBay(player, record)
		end
	end
end

local function clearAll(player: Player)
	for id in spawned[player] or {} do
		despawn(player, id)
	end
	spawned[player] = nil
end

-- Rolltor: hebt sich bei Annäherung, schließt nach kurzer Haltezeit (docs/07 §19)
type DoorState = { door: BasePart, closedCF: CFrame, openCF: CFrame, closedSize: Vector3, openSize: Vector3, open: boolean, lastNear: number }
local doors: { [Player]: DoorState } = {}

local function registerDoor(player: Player)
	local garage = garageModel(player)
	local door = garage and garage:FindFirstChild("GarageDoor")
	if not (door and door:IsA("BasePart")) then
		doors[player] = nil
		return
	end
	-- Offen: auf OpenHeight zusammengerollt, Oberkante bleibt am Rollkasten
	local openHeight = door:GetAttribute("OpenHeight")
	local h = if typeof(openHeight) == "number" then openHeight else 0.8
	local closedCF, closedSize = door.CFrame, door.Size
	doors[player] = {
		door = door,
		closedCF = closedCF,
		closedSize = closedSize,
		openCF = closedCF * CFrame.new(0, (closedSize.Y - h) / 2, 0),
		openSize = Vector3.new(closedSize.X, h, closedSize.Z),
		open = false,
		lastNear = 0,
	}
end

local function doorLoop()
	while true do
		task.wait(DOOR_CHECK_SECONDS)
		local now = os.clock()
		for player, state in doors do
			if not state.door.Parent then
				doors[player] = nil
				continue
			end
			-- Nähe im Torraum: seitlich innerhalb der Torbreite, davor oder dahinter in Reichweite
			local halfWidth = state.closedSize.X / 2 + 6
			local function within(position: Vector3, range: number): boolean
				local p = state.closedCF:PointToObjectSpace(position)
				return math.abs(p.X) <= halfWidth and math.abs(p.Z) <= range and math.abs(p.Y) <= state.closedSize.Y
			end
			local near = false
			for _, other in Players:GetPlayers() do
				local root = rootOf(other)
				if root and within(root.Position, DOOR_PLAYER_RANGE) then
					near = true
					break
				end
			end
			if not near then
				for _, model in spawned[player] or {} do
					-- nur gefahrene Fahrzeuge (geparkte im Stellplatz öffnen das Tor nicht)
					local chassis = model.PrimaryPart
					local seat = model:FindFirstChild("DriverSeat")
					local driven = seat and seat:IsA("VehicleSeat") and seat.Occupant ~= nil
					if chassis and driven and within(chassis.Position, DOOR_VEHICLE_RANGE) then
						near = true
						break
					end
				end
			end
			if near then
				state.lastNear = now
			end
			local shouldOpen = now - state.lastNear < DOOR_HOLD_SECONDS
			if shouldOpen ~= state.open then
				state.open = shouldOpen
				local goal = if shouldOpen then { CFrame = state.openCF, Size = state.openSize } else { CFrame = state.closedCF, Size = state.closedSize }
				TweenService:Create(state.door, TweenInfo.new(if shouldOpen then 1.1 else 1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), goal):Play()
				state.door.CanCollide = not shouldOpen
			end
		end
	end
end

function VehicleService.Init()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP_VEHICLES)
	end)
	for _, group in { "Players", "Workers", "Machines" } do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(group)
		end)
	end
	PhysicsService:CollisionGroupSetCollidable(GROUP_VEHICLES, GROUP_VEHICLES, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_VEHICLES, "Players", false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_VEHICLES, "Workers", false)

	RemoteService.OnInvoke("DriveVehicle", drive)
	RemoteService.OnInvoke("StoreVehicle", store)
	RemoteService.OnInvoke("ResetVehicle", reset)
end

function VehicleService.Start()
	-- Leuchtring: Betreten öffnet die Auswahl (nur eigener Ring)
	BuildingService.ModelBuilt:Connect(function(player, stepId, model)
		if stepId ~= GARAGE_STEP then
			return
		end
		local ring = model:FindFirstChild("GarageRing")
		if ring and ring:IsA("BasePart") then
			ring.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				local toucher = character and Players:GetPlayerFromCharacter(character)
				if toucher ~= player then
					return
				end
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.SeatPart then
					return -- im Fahrzeug kein Auswahlfenster
				end
				local now = os.clock()
				if ringTouch[player] and now - ringTouch[player] < 2 then
					return
				end
				ringTouch[player] = now
				RemoteService.FireClient("OpenGarage", player)
			end)
		end
		registerDoor(player)
		task.defer(spawnParked, player)
	end)

	DataService.ProfileLoaded:Connect(function(player)
		task.defer(spawnParked, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		clearAll(player)
		doors[player] = nil
		ringTouch[player] = nil
	end)
	task.spawn(doorLoop)
end

-- Gespawntes Modell eines Fahrzeugs (für Beladen/Verkauf in Phase 6c)
function VehicleService.GetModel(player: Player, vehicleId: string): Model?
	return spawned[player] and spawned[player][vehicleId]
end

-- Fahrzeug, in dem der Spieler gerade am Steuer sitzt (Daten-ID + Modell)
function VehicleService.GetDriven(player: Player): (string?, Model?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("OwnerUserId") == player.UserId then
		local id = model:GetAttribute("VehicleId")
		if typeof(id) == "string" then
			return id, model
		end
	end
	return nil, nil
end

function VehicleService.RefreshCargo(player: Player, vehicleId: string)
	updateCargoVisual(player, vehicleId)
end

return VehicleService
