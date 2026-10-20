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
local ServerStorage = game:GetService("ServerStorage")
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
local TrailerBuilder = require(script.Parent.Parent.World.TrailerBuilder)
local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
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
-- Anhänger der Lastzüge: [player] = { [vehicleId] = { Model } } (Phase 18c)
local trailers: { [Player]: { [string]: { Model } } } = {}
local ringTouch: { [Player]: number } = {}

-- Fahrersitz: A-Chassis heißt "DriveSeat", der eigene Fallback "DriverSeat"
local function seatOf(model: Model): VehicleSeat?
	local seat = model:FindFirstChild("DriveSeat") or model:FindFirstChild("DriverSeat")
	return if seat and seat:IsA("VehicleSeat") then seat else nil
end

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
	local ring = garage and garage:FindFirstChild("GarageRing", true)
	local root = rootOf(player)
	if not (ring and ring:IsA("BasePart") and root) then
		return false
	end
	return (root.Position - ring.Position).Magnitude <= RING_DISTANCE
end

-- Lastzüge stehen nicht in der Halle, sondern auf der Zufahrt zur Verladestraße: eigener Platz
-- (Nummer nach den Hallen-Stellplätzen), höchstens ein Lastzug gleichzeitig
local ROAD_TRAIN_SLOT = Vehicles.BayCount + 1

local function freeBay(data: Types.PlayerData, typeId: string?): number?
	local used: { [number]: boolean } = {}
	for _, v in data.Vehicles.Owned do
		if v.Bay then
			used[v.Bay] = true
		end
	end
	if typeId and TrailerBuilder.HasTrailers(typeId) then
		return if used[ROAD_TRAIN_SLOT] then nil else ROAD_TRAIN_SLOT
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
	local seat = seatOf(model)
	if not seat then
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
	local seat = seatOf(model)
	if seat and seat.Occupant then
		seat.Occupant.Sit = false
	end
	model:Destroy()
	local own = trailers[player]
	for _, t in (own and own[vehicleId]) or {} do
		t:Destroy()
	end
	if own then
		own[vehicleId] = nil
	end
end

-- Ladeflächen eines Fahrzeugs in Fahrtrichtung (Lastzug: je beladbarer Anhänger eine)
function VehicleService.GetCargoFills(player: Player, vehicleId: string): { BasePart }
	local fills: { BasePart } = {}
	local own = trailers[player]
	local list = own and own[vehicleId]
	if list and #list > 0 then
		for _, t in list do
			local f = t:FindFirstChild("CargoFill")
			if f and f:IsA("BasePart") then
				table.insert(fills, f)
			end
		end
		return fills
	end
	local model = spawned[player] and spawned[player][vehicleId]
	local f = model and model:FindFirstChild("CargoFill", true)
	if f and f:IsA("BasePart") then
		table.insert(fills, f)
	end
	return fills
end

local function updateCargoVisual(player: Player, vehicleId: string)
	local data = DataService.Get(player)
	local record = data and data.Vehicles.Owned[vehicleId]
	local model = spawned[player] and spawned[player][vehicleId]
	local def = record and Vehicles.Get(record.Type)
	if record and model and def then
		local fraction = cargoTotal(record.Cargo) / def.Capacity
		local own = trailers[player]
		local list = own and own[vehicleId]
		if list and #list > 0 then
			-- Lastzug: Anhänger werden der Reihe nach voll (vorderer zuerst)
			local fills = VehicleService.GetCargoFills(player, vehicleId)
			for k, f in fills do
				local share = math.clamp(fraction * #fills - (k - 1), 0, 1)
				-- Auflieger mit Plane (CargoHidden): Ladung bleibt unsichtbar
				f.Transparency = if share > 0 and not f:GetAttribute("CargoHidden") then 0 else 1
			end
		else
			VehicleModelBuilder.setCargoVisual(model, fraction)
		end
		model:SetAttribute("Cargo", cargoTotal(record.Cargo))
	end
end

-- Fahrzeug auf seinem Stellplatz erscheinen lassen
-- Frisch gebautes A-Chassis-Fahrzeug: erst einsteigen lassen, wenn A-Chassis es initialisiert hat
-- (legt Body["#Weight"] an) und es beim Spieler gestreamt ist. Sonst bekommt der Fahrer keine
-- Steuerung (Felix-Test 2026-10-20: Lastzug fuhr nach dem Ausparken nicht).
local function waitReady(player: Player, model: Model)
	local at = model:GetPivot().Position
	pcall(function()
		player:RequestStreamAroundAsync(at, 8)
	end)
	local body = model:FindFirstChild("Body")
	if model:FindFirstChild("A-Chassis Tune") and body then
		local t0 = os.clock()
		while model.Parent and not body:FindFirstChild("#Weight") and os.clock() - t0 < 4 do
			task.wait(0.1)
		end
	end
	task.wait(0.3)
end

-- Einsteigen mit F (Felix 2026-10-20), weiter unten definiert
local addEnterPrompt: (player: Player, model: Model, displayName: string) -> ()

local function spawnAtBay(player: Player, record: Types.VehicleRecord, override: CFrame?): Model?
	local def = Vehicles.Get(record.Type)
	local garage = garageModel(player)
	local data = DataService.Get(player)
	if not (def and garage and record.Bay and data) then
		return nil
	end
	-- Lastzüge passen auf keinen Stellplatz: sie stehen auf der Zufahrt zur Verladestraße neben
	-- dem Grundstück, Front Richtung Zauntor (D-052, PLANS/ROAD_TRAINS.md T4)
	local withTrailers = TrailerBuilder.HasTrailers(def.Id)
	local floorCF: CFrame
	if withTrailers then
		local plotId = PlotService.GetPlotId(player)
		if not plotId then
			return nil
		end
		local side = LayoutConfig.SideRoad
		floorCF = PlotBuilder.getPlotCFrame(plotId) * CFrame.new(side.OuterX, 1.05, LayoutConfig.Garage.Lane.Z - side.Radius - 20) * CFrame.Angles(0, math.pi, 0)
	else
		local bayPart = garage:FindFirstChild(`BaySpawn{record.Bay}`, true)
		if not (bayPart and bayPart:IsA("BasePart")) then
			return nil
		end
		floorCF = bayPart.CFrame * CFrame.new(0, -bayPart.Size.Y / 2, 0)
	end
	if override then
		floorCF = override
	end
	despawn(player, record.Id)
	-- Fahrphysik von A-Chassis (D-026); ohne Kit im Place eigener Fallback
	local vendor = ServerStorage:FindFirstChild("Vendor")
	local kit = vendor and vendor:FindFirstChild("AChassis")
	local model = if kit then VehicleModelBuilder.buildAChassis(def, floorCF + Vector3.new(0, 0.15, 0), kit) else nil
	if not model then
		warn("[Server][VehicleService] A-Chassis-Kit fehlt (ServerStorage.Vendor.AChassis) – eigener Fallback")
		model = VehicleModelBuilder.build(def, floorCF + Vector3.new(0, 0.15, 0), true)
	end
	model.Name = `{player.Name}_{record.Id}`
	model:SetAttribute("VehicleId", record.Id)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("Bay", record.Bay)
	model:SetAttribute("Capacity", def.Capacity)
	local color = CompanyIdentity.ColorById[data.Company.ColorId]
	VehicleModelBuilder.applyCompany(model, if color then color.Color else nil, data.Company.Name)
	setGroup(model)
	-- A-Chassis legt beim Start weitere Teile an: auch diese in die Fahrzeug-Gruppe
	model.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			d.CollisionGroup = GROUP_VEHICLES
		end
	end)
	guardSeat(model, player)
	addEnterPrompt(player, model, def.DisplayName)
	model.Parent = folder()
	-- Eigener Fallback: Physik gehört dem Fahrer. A-Chassis setzt den Besitzer selbst.
	if not model:FindFirstChild("A-Chassis Tune") then
		local chassis = model.PrimaryPart
		if chassis then
			pcall(function()
				chassis:SetNetworkOwner(player)
			end)
		end
	end
	spawned[player] = spawned[player] or {}
	spawned[player][record.Id] = model
	if withTrailers then
		local root = seatOf(model) or model.PrimaryPart
		if root then
			local rootAtBuild = root.CFrame
			local list = TrailerBuilder.build(def.Id, floorCF + Vector3.new(0, 0.15, 0), root, folder(), model.Name)
			for _, t in list do
				t:SetAttribute("VehicleId", record.Id)
				t:SetAttribute("OwnerUserId", player.UserId)
				setGroup(t)
			end
			-- Ankoppeln, sobald A-Chassis die Zugmaschine aufgebaut hat
			task.delay(1.2, function()
				if model.Parent and root.Parent then
					TrailerBuilder.release(list, root, rootAtBuild)
					local seat = seatOf(model)
					local occupant = seat and seat.Occupant
					local driver = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
					TrailerBuilder.setOwner(list, driver)
				end
			end)
			trailers[player] = trailers[player] or {}
			trailers[player][record.Id] = list
			-- Netzwerkbesitz der Anhänger folgt dem Fahrer (A-Chassis setzt ihn für die Zugmaschine)
			local seat = seatOf(model)
			if seat then
				seat:GetPropertyChangedSignal("Occupant"):Connect(function()
					local occupant = seat.Occupant
					local driver = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
					task.delay(0.5, function()
						TrailerBuilder.setOwner(list, driver)
					end)
				end)
			end
		end
	end
	updateCargoVisual(player, record.Id)
	return model
end

local function seatPlayer(player: Player, model: Model)
	local seat = seatOf(model)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if seat and humanoid and humanoid.Health > 0 then
		if humanoid.SeatPart then
			humanoid.Sit = false
			task.wait()
		end
		seat:Sit(humanoid)
	end
end

-- Einsteigen nur noch mit F über einen Hinweis am Fahrersitz (Felix 2026-10-20): Berühren des
-- Sitzes setzt niemanden mehr hinein; Ausparken an der Garage setzt den Fahrer weiterhin direkt
-- ans Steuer. Nur der Besitzer kann den Hinweis auslösen.
addEnterPrompt = function(player: Player, model: Model, displayName: string)
	local seat = seatOf(model)
	if not seat then
		return
	end
	seat.CanTouch = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnterPrompt"
	prompt.ActionText = "Drive"
	prompt.ObjectText = displayName
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(who)
		if who ~= player then
			RemoteService.FireClient("Notify", who, { Kind = "Warning", Code = Result.Codes.NOT_OWNER })
			return
		end
		seatPlayer(player, model)
	end)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		prompt.Enabled = seat.Occupant == nil
	end)
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
		local bay = freeBay(data, record.Type)
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
	local fresh_spawn = false
	if not model or not model.Parent then
		model = spawnAtBay(player, fresh)
		fresh_spawn = true
	end
	if not model then
		return Result.err(Result.Codes.INTERNAL_ERROR)
	end
	if fresh_spawn then
		-- Weit entfernte Fahrzeuge (Lastzug auf der Zufahrt) erst zum Spieler streamen, sonst
		-- sitzt er nur auf dem Server im Fahrzeug
		waitReady(player, model)
		if not model.Parent then
			return Result.err(Result.Codes.INTERNAL_ERROR)
		end
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
		task.spawn(function()
			waitReady(player, model)
			if model.Parent then
				seatPlayer(player, model)
			end
		end)
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
	trailers[player] = nil
end

-- Rolltore: heben sich bei Annäherung, schließen nach kurzer Haltezeit (docs/07 §19). Vorne das
-- Garagentor, seit Phase 18b/18c auch das Tor der Seiteneinfahrt (Hallenwände, Attribut RollerDoor)
type DoorState = { door: BasePart, closedCF: CFrame, openCF: CFrame, closedSize: Vector3, openSize: Vector3, open: boolean, lastNear: number }
local doors: { [Player]: { DoorState } } = {}

local function doorState(door: BasePart): DoorState
	-- Offen: auf OpenHeight zusammengerollt, Oberkante bleibt am Rollkasten
	local openHeight = door:GetAttribute("OpenHeight")
	local h = if typeof(openHeight) == "number" then openHeight else 0.8
	local closedCF, closedSize = door.CFrame, door.Size
	return {
		door = door,
		closedCF = closedCF,
		closedSize = closedSize,
		openCF = closedCF * CFrame.new(0, (closedSize.Y - h) / 2, 0),
		openSize = Vector3.new(closedSize.X, h, closedSize.Z),
		open = false,
		lastNear = 0,
	}
end

local function registerDoor(player: Player)
	local list: { DoorState } = {}
	local garage = garageModel(player)
	local door = garage and garage:FindFirstChild("GarageDoor", true)
	if door and door:IsA("BasePart") then
		table.insert(list, doorState(door))
	end
	local walls = BuildingService.GetModel(player, "build_walls")
	for _, d in (walls and walls:GetDescendants()) or {} do
		if d:IsA("BasePart") and d:GetAttribute("RollerDoor") == true then
			table.insert(list, doorState(d))
		end
	end
	doors[player] = if #list > 0 then list else nil
end

-- Teile eines gefahrenen Fahrzeugs, die ein Tor öffnen (Lastzug: auch alle Anhänger)
local function drivenParts(player: Player): { BasePart }
	local parts: { BasePart } = {}
	for id, model in spawned[player] or {} do
		local seat = seatOf(model)
		if seat and seat.Occupant and model.PrimaryPart then
			table.insert(parts, model.PrimaryPart)
			local own = trailers[player]
			for _, t in (own and own[id]) or {} do
				if t.PrimaryPart then
					table.insert(parts, t.PrimaryPart)
				end
			end
		end
	end
	return parts
end

local function doorLoop()
	while true do
		task.wait(DOOR_CHECK_SECONDS)
		local now = os.clock()
		for player, list in doors do
			local moving = drivenParts(player)
			for _, state in list do
				if not state.door.Parent then
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
					-- nur gefahrene Fahrzeuge (geparkte im Stellplatz öffnen das Tor nicht)
					for _, part in moving do
						if within(part.Position, DOOR_VEHICLE_RANGE) then
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
		if stepId == "build_walls" then
			registerDoor(player)
			return
		end
		if stepId ~= GARAGE_STEP then
			return
		end
		local ring = model:FindFirstChild("GarageRing", true)
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

-- Alle Fahrzeuge des Spielers aus der Welt nehmen (Prestige: Garage wird zurückgesetzt)
function VehicleService.ClearAll(player: Player)
	clearAll(player)
end

-- Gespawntes Modell eines Fahrzeugs (für Beladen/Verkauf in Phase 6c)
-- Nur für Tests (DevTools.PlaceVehicle): Fahrzeug mit Stellplatz an einer Boden-CFrame neu aufstellen
function VehicleService.SpawnAt(player: Player, vehicleId: string, floorCF: CFrame): Model?
	local data = DataService.Get(player)
	local record = data and data.Vehicles.Owned[vehicleId]
	if not (record and record.Bay) then
		return nil
	end
	return spawnAtBay(player, record, floorCF)
end

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
