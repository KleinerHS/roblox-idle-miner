--!strict
-- Prestige (docs/12 §50–64, D-012, D-033). Ab Mining Level 100, nur am eigenen Laptop, nie
-- automatisch. Setzt die Firmenprogression auf den Startzustand und behält Identität,
-- permanente Ausrüstung, Fahrzeuge, Robux-Käufe und den Prestige-Zähler.
--
-- Zurückgesetzt: Geld, Level/XP, Gebäude (inkl. Hütte/Büro), Minen, Lager inkl. Inhalt und
-- Upgrade, Elevator-Upgrade, Worker, Drills, Förderbänder, Schmelzer, Produktionspuffer,
-- Rucksack-Inhalt, Fahrzeugladungen (Fahrzeuge bleiben, werden eingelagert).
-- Erhalten: Prestige-Zähler, Firma (Name/Logo/Farbe), Spitzhacken, Rucksäcke, Fahrzeuge,
-- Robux-Käufe (Entitlements), Einstellungen, Statistik.
--
-- Duplikationsschutz (docs/12 §63): kein Prestige während eines Handels oder im Fahrzeug;
-- Prüfung und Reset laufen ohne Yield in einem Mutate; danach sofort Save und neuer
-- Offline-Zeitstempel (docs/12 §64, docs/14 §17).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Result = require(Shared.Util.Result)
local PrestigeLogic = require(Shared.Util.PrestigeLogic)
local Log = require(Shared.Util.Log)

local PrestigeReset = require(script.Parent.Parent.Util.PrestigeReset)
local DataService = require(script.Parent.DataService)
local BuildingService = require(script.Parent.BuildingService)
local WorkerService = require(script.Parent.WorkerService)
local VehicleService = require(script.Parent.VehicleService)
local TradeService = require(script.Parent.TradeService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "PrestigeService"

local PrestigeService = {}

local busy: { [Player]: boolean } = {}

local function prestige(player: Player)
	if busy[player] then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not PrestigeLogic.IsAvailable(data.MiningLevel) then
		return Result.err(Result.Codes.LEVEL_TOO_LOW)
	end
	if not WorkerService.IsNearLaptop(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	if TradeService.IsTrading(player) then
		return Result.err(Result.Codes.TRADE_BUSY)
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.SeatPart then
		return Result.err(Result.Codes.IN_VEHICLE)
	end

	busy[player] = true
	local count = 0
	local applied = DataService.Mutate(player, function(d)
		PrestigeReset.apply(d, os.time())
		count = d.Prestige.Count
	end)
	if not applied then
		busy[player] = nil
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	DataService.RequestSave(player)
	Log.info(TAG, `{player.Name} Prestige {count}`)

	-- Welt auf Startzustand: Fahrzeuge weg, Gebäude neu, Worker-Figuren weg, Spieler an den Start
	VehicleService.ClearAll(player)
	BuildingService.Rebuild(player)
	WorkerService.WorkersChanged:Fire(player)
	task.delay(1.5, function()
		busy[player] = nil
		if player.Parent == Players then
			player:LoadCharacter()
			RemoteService.FireClient("Notify", player, { Kind = "Special", Code = "PRESTIGE_DONE", Args = { Count = count } })
		end
	end)
	return Result.ok({ Count = count })
end

function PrestigeService.Init()
	RemoteService.OnInvoke("Prestige", prestige)
end

function PrestigeService.Start()
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return PrestigeService
