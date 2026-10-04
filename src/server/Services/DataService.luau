--!strict
-- Laden/Speichern der Spielerprofile (docs/14). Nutzt ProfileStore für Session Lock,
-- Autosave und Shutdown-Save. Kein anderer Service greift direkt auf DataStores zu.
--
-- Zugriff für andere Services:
--   DataService.Get(player)            → PlayerData? (nur lesen)
--   DataService.Mutate(player, fn)     → einzige Stelle für Änderungen, sendet danach Snapshot
--   DataService.ProfileLoaded          → Signal(player, data)
--
-- Sicherheitsregeln:
--   * Kann ein Profil nicht geladen werden, wird der Spieler gekickt. Es wird NIE ein
--     leeres Default-Profil über ein bestehendes geschrieben (docs/14 §19).
--   * Profil einer neueren DataVersion → Kick, damit ein alter Server nichts zerstört.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Backpacks = require(Shared.Definitions.Backpacks)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Signal = require(Shared.Util.Signal)
local Leveling = require(Shared.Util.Leveling)
local Log = require(Shared.Util.Log)

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
local DataSchema = require(script.Parent.Parent.Data.DataSchema)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "DataService"

local DataService = {
	-- (player, data) nachdem das Profil geladen, migriert und aktiv ist
	ProfileLoaded = Signal.new() :: Signal.Signal<Player, Types.PlayerData>,
	-- (player) nach jeder Mutate-Änderung (gebündelt pro Frame)
	Changed = Signal.new() :: Signal.Signal<Player>,
}

type Profile = {
	Data: Types.PlayerData,
	AddUserId: (self: Profile, userId: number) -> (),
	Reconcile: (self: Profile) -> (),
	EndSession: (self: Profile) -> (),
	IsActive: (self: Profile) -> boolean,
	OnSessionEnd: { Connect: (self: any, () -> ()) -> any },
	OnSave: { Connect: (self: any, () -> ()) -> any },
}

local store = (ProfileStore :: any).New(GameConfig.Data.StoreName, DataSchema.getTemplate())
local profiles: { [Player]: Profile } = {}
local snapshotQueued: { [Player]: boolean } = {}

local function buildSnapshot(data: Types.PlayerData): Types.StateSnapshot
	local backpack = Backpacks.Get(data.Equipment.EquippedBackpack)
	return {
		Cash = data.Cash,
		MiningLevel = data.MiningLevel,
		MiningXP = data.MiningXP,
		MiningXPRequired = Leveling.xpRequired(data.MiningLevel),
		Company = table.clone(data.Company),
		EquippedPickaxe = data.Equipment.EquippedPickaxe,
		EquippedBackpack = data.Equipment.EquippedBackpack,
		OwnedPickaxes = table.clone(data.Equipment.OwnedPickaxes),
		OwnedBackpacks = table.clone(data.Equipment.OwnedBackpacks),
		Backpack = table.clone(data.Backpack),
		BackpackCapacity = if backpack then backpack.Capacity else 0,
		StorageCapacity = data.Storage.Capacity,
		StorageItems = table.clone(data.Storage.Items),
		Workers = table.clone(data.Workers),
		Drills = table.clone(data.Machines.Drills),
		MineBuffers = table.clone(data.Production.MineBuffers),
		ElevatorBuffer = table.clone(data.Production.ElevatorBuffer),
		ElevatorCapacity = data.Production.ElevatorCapacity,
		Buildings = table.clone(data.Buildings),
		PrestigeCount = data.Prestige.Count,
	}
end

local function sendSnapshot(player: Player)
	local profile = profiles[player]
	if profile and player.Parent == Players then
		RemoteService.FireClient("StateSnapshot", player, buildSnapshot(profile.Data))
	end
end

-- Mehrere Änderungen im selben Frame ergeben nur einen Snapshot (kein Remote-Spam).
local function queueSnapshot(player: Player)
	if snapshotQueued[player] then
		return
	end
	snapshotQueued[player] = true
	task.defer(function()
		snapshotQueued[player] = nil
		sendSnapshot(player)
		if profiles[player] then
			DataService.Changed:Fire(player)
		end
	end)
end

local function onProfileReady(player: Player, profile: Profile)
	local data = profile.Data
	local now = os.time()
	if data.Stats.FirstJoinTime == 0 then
		data.Stats.FirstJoinTime = now
	end
	data.Stats.JoinCount += 1
	-- LastValidTime wird für die Offline-Berechnung (Phase 10) vor dem Überschreiben ausgewertet.
	data.LastValidTime = now

	profile.OnSave:Connect(function()
		profile.Data.LastValidTime = os.time()
	end)

	Log.debug(
		TAG,
		`{player.Name} geladen: v{data.DataVersion}, Cash {data.Cash}, Level {data.MiningLevel}, Joins {data.Stats.JoinCount}`
	)
	DataService.ProfileLoaded:Fire(player, data)
	sendSnapshot(player)
end

local function loadProfile(player: Player)
	local profile = store:StartSessionAsync(`{GameConfig.Data.KeyPrefix}{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	}) :: Profile?

	if profile == nil then
		-- Laden fehlgeschlagen oder Spieler schon weg: nichts überschreiben.
		if player.Parent == Players then
			Log.warn(TAG, `Profil von {player.Name} konnte nicht geladen werden`)
			player:Kick("Deine Spieldaten konnten nicht geladen werden. Bitte erneut beitreten.")
		end
		return
	end

	-- Migration vor Reconcile, damit Migrationen die alte Struktur sehen.
	local migrated, reason = DataSchema.migrate(profile.Data :: any)
	if not migrated then
		Log.warn(TAG, `Profil von {player.Name} nicht nutzbar: {reason}`)
		profile:EndSession()
		player:Kick("Deine Spieldaten stammen aus einer neueren Spielversion. Bitte einem anderen Server beitreten.")
		return
	end

	profile:AddUserId(player.UserId) -- DSGVO-Zuordnung
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		snapshotQueued[player] = nil
		if player.Parent == Players then
			player:Kick("Deine Sitzung wurde auf einem anderen Server geöffnet. Bitte erneut beitreten.")
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	onProfileReady(player, profile)
end

function DataService.Init()
	RemoteService.OnInvoke("GetState", function(player: Player)
		local profile = profiles[player]
		if not profile then
			return Result.err(Result.Codes.DATA_NOT_LOADED)
		end
		return Result.ok(buildSnapshot(profile.Data))
	end)
end

function DataService.Start()
	Players.PlayerAdded:Connect(loadProfile)
	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profile:EndSession()
		end
	end)
	-- Shutdown-Save übernimmt ProfileStore selbst (BindToClose).

	task.spawn(function()
		local api = ProfileStore :: any
		while api.DataStoreState == "NotReady" do
			task.wait(0.5)
		end
		if api.DataStoreState == "Access" then
			Log.info(TAG, "DataStore verbunden – Spielstände werden gespeichert")
		else
			Log.warn(
				TAG,
				`DataStore nicht erreichbar ({api.DataStoreState}) – Testmodus, Daten werden NICHT gespeichert. In Studio: Place veröffentlichen und "Enable Studio Access to API Services" aktivieren.`
			)
		end
	end)
end

-- Nur lesen. Änderungen ausschließlich über Mutate.
function DataService.Get(player: Player): Types.PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

function DataService.IsLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

-- Sofort speichern nach wichtigen Zustandswechseln (Kauf, Firmengründung, docs/14 §5).
-- Gegen Save-Spam: höchstens alle SAVE_COOLDOWN Sekunden, sonst übernimmt der Autosave.
local SAVE_COOLDOWN = 20
local lastSave: { [Player]: number } = {}

function DataService.RequestSave(player: Player)
	local profile = profiles[player] :: any
	if not profile or not profile:IsActive() then
		return
	end
	local now = os.clock()
	if lastSave[player] and now - lastSave[player] < SAVE_COOLDOWN then
		return
	end
	lastSave[player] = now
	profile:Save()
end

Players.PlayerRemoving:Connect(function(player)
	lastSave[player] = nil
end)

-- Führt eine Änderung am Profil aus und sendet danach einen Snapshot an den Client.
-- `mutator` darf nicht yielden, damit Prüfung und Änderung atomar bleiben.
function DataService.Mutate(player: Player, mutator: (data: Types.PlayerData) -> ()): boolean
	local profile = profiles[player]
	if not profile or not profile:IsActive() then
		return false
	end
	mutator(profile.Data)
	queueSnapshot(player)
	return true
end

-- Für häufige Hintergrund-Änderungen (Produktion jede Sekunde): ändert sofort, schickt den
-- Snapshot aber gebündelt höchstens alle QUIET_SNAPSHOT_SECONDS (kein Remote-Spam).
local QUIET_SNAPSHOT_SECONDS = 2
local quietDirty: { [Player]: boolean } = {}

function DataService.MutateQuiet(player: Player, mutator: (data: Types.PlayerData) -> ()): boolean
	local profile = profiles[player]
	if not profile or not profile:IsActive() then
		return false
	end
	mutator(profile.Data)
	quietDirty[player] = true
	return true
end

task.spawn(function()
	while true do
		task.wait(QUIET_SNAPSHOT_SECONDS)
		for player in quietDirty do
			quietDirty[player] = nil
			if profiles[player] then
				queueSnapshot(player)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	quietDirty[player] = nil
end)

return DataService
