--!strict
-- Verkauf (docs/07 §21–31, D-056): großer grüner Verkaufskreis in der Platzmitte. Fährt der
-- Spieler mit Ladung hindurch, wird die Fahrzeugladung sofort verkauft; läuft er zu Fuß hinein,
-- der Rucksack. Kein Fenster, keine Bestätigung (Felix 2026-10-21).
-- Der Server berechnet Geld (Menge × SellValue) und Mining XP (Menge × XPValue) aus den
-- Erzdefinitionen (docs/03 §11) – nie aus Client-Werten. Mining XP gibt es nur hier (docs/00 §20).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Materials = require(Shared.Definitions.Materials)
local Leveling = require(Shared.Util.Leveling)
local PrestigeLogic = require(Shared.Util.PrestigeLogic)
local Log = require(Shared.Util.Log)

local SellingBuilder = require(script.Parent.Parent.World.SellingBuilder)
local DataService = require(script.Parent.DataService)
local VehicleService = require(script.Parent.VehicleService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "SellingService"
local CHECK_INTERVAL = 0.25
-- Höhe über/unter dem Kreis, in der noch verkauft wird
local MAX_HEIGHT = 20

local SellingService = {}

local zone: BasePart
local radius = 0

local function inCircle(position: Vector3): boolean
	local d = position - zone.Position
	return Vector2.new(d.X, d.Z).Magnitude <= radius and math.abs(d.Y) <= MAX_HEIGHT
end

-- vehicleId nil = Rucksack, sonst Ladung des Fahrzeugs. Gibt Geld/XP zurück oder nil.
local function sellAll(player: Player, vehicleId: string?): { Cash: number, XP: number }?
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local source: { [string]: number }
	if vehicleId == nil then
		source = data.Backpack
	else
		local record = data.Vehicles.Owned[vehicleId]
		if not record then
			return nil
		end
		source = record.Cargo
	end

	-- Werte ausschließlich aus den Definitionen; Erze ohne Balancewert bleiben liegen
	local cash, xp = 0, 0
	local sold: { [string]: number } = {}
	for oreId, amount in source do
		local ore = Materials.Get(oreId)
		if ore and ore.SellValue and ore.XPValue and amount > 0 then
			cash += amount * ore.SellValue
			xp += amount * ore.XPValue
			sold[oreId] = amount
		end
	end
	if next(sold) == nil then
		return nil
	end
	-- Prestige-Bonus nur aufs Geld (docs/12 §57), XP unverändert
	cash = math.floor(cash * PrestigeLogic.MoneyMultiplier(data.Prestige.Count))

	-- Prüfung oben und Änderung hier ohne Yield dazwischen → atomar, kein Doppelverkauf
	local levelsGained = 0
	DataService.Mutate(player, function(d)
		local target = if vehicleId == nil then d.Backpack else d.Vehicles.Owned[vehicleId].Cargo
		for oreId in sold do
			target[oreId] = nil
		end
		d.Cash += cash
		local level, levelXP, gained = Leveling.addXP(d.MiningLevel, d.MiningXP, xp)
		d.MiningLevel = level
		d.MiningXP = levelXP
		levelsGained = gained
	end)
	DataService.RequestSave(player)
	if vehicleId then
		VehicleService.RefreshCargo(player, vehicleId)
	end
	Log.debug(TAG, `{player.Name} verkauft ({vehicleId or "Rucksack"}) für ${cash} und {xp} XP (Level {data.MiningLevel}, +{levelsGained})`)
	return { Cash = cash, XP = xp }
end

local function check(player: Player)
	if not DataService.IsLoaded(player) then
		return
	end
	local vehicleId, model = VehicleService.GetDriven(player)
	if vehicleId and model then
		local seat = model:FindFirstChild("DriveSeat", true)
		local pos = if seat and seat:IsA("BasePart") then seat.Position else model:GetPivot().Position
		if inCircle(pos) then
			local result = sellAll(player, vehicleId)
			if result then
				RemoteService.FireClient("Sold", player, result)
			end
		end
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and inCircle(root.Position) then
		local result = sellAll(player, nil)
		if result then
			RemoteService.FireClient("Sold", player, result)
		end
	end
end

function SellingService.Init()
	local existing = workspace:FindFirstChild("Center")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Center"
	local circle = SellingBuilder.build(folder)
	zone = circle:FindFirstChild("Zone") :: BasePart
	radius = zone:GetAttribute("Radius") :: number
	folder.Parent = workspace
end

function SellingService.Start()
	task.spawn(function()
		while true do
			task.wait(CHECK_INTERVAL)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(check, player)
				if not ok then
					Log.warn(TAG, `Verkauf fehlgeschlagen ({player.Name}): {err}`)
				end
			end
		end
	end)
end

return SellingService
