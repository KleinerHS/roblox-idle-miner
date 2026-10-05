--!strict
-- Verkauf am Tresen (docs/07 §21–31): Der Spieler verkauft seinen Rucksack im
-- Verkaufsgebäude. Der Server berechnet Geld (Menge × SellValue) und Mining XP
-- (Menge × XPValue) getrennt aus den Erzdefinitionen (docs/03 §11) – nie aus Client-Werten.
-- Mining XP gibt es nur hier (docs/00 §20).
-- Phase 6c: Verkauf aus dem Fahrzeug (docs/07 §23, §25, §30): Fährt der Spieler mit Ladung in die
-- Fahrzeug-Verkaufszone vor dem Gebäude, öffnet sich das Verkaufsfenster für die Ladung; verkauft
-- wird erst nach Bestätigung (SELL ALL).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Materials = require(Shared.Definitions.Materials)
local Result = require(Shared.Util.Result)
local Leveling = require(Shared.Util.Leveling)
local Log = require(Shared.Util.Log)

local SellingBuilder = require(script.Parent.Parent.World.SellingBuilder)
local DataService = require(script.Parent.DataService)
local VehicleService = require(script.Parent.VehicleService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "SellingService"

local SellingService = {}

local counterPart: BasePart
local sellZone: BasePart
-- Spieler, denen das Fahrzeug-Verkaufsfenster schon angeboten wurde (bis sie die Zone verlassen)
local offered: { [Player]: boolean } = {}

-- Steht das Fahrzeug (Chassis) in der Verkaufszone? Etwas Toleranz für größere Fahrzeuge.
local function inSellZone(model: Model): boolean
	local chassis = model.PrimaryPart
	if not chassis then
		return false
	end
	local p = sellZone.CFrame:PointToObjectSpace(chassis.Position)
	return math.abs(p.X) <= sellZone.Size.X / 2 + 3 and math.abs(p.Z) <= sellZone.Size.Z / 2 + 6 and math.abs(p.Y) <= 12
end

local function isNearCounter(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - counterPart.Position).Magnitude <= LayoutConfig.SellCounterDistance
end

-- vehicleId nil = Rucksack am Tresen; sonst Ladung des eigenen Fahrzeugs in der Verkaufszone
local function sellAll(player: Player, vehicleId: unknown)
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	local source: { [string]: number }
	if vehicleId == nil then
		if not isNearCounter(player) then
			return Result.err(Result.Codes.TOO_FAR)
		end
		source = data.Backpack
	else
		if typeof(vehicleId) ~= "string" then
			return Result.err(Result.Codes.INVALID_ARGUMENT)
		end
		local record = data.Vehicles.Owned[vehicleId :: string]
		if not record then
			return Result.err(Result.Codes.NOT_OWNED)
		end
		local model = VehicleService.GetModel(player, record.Id)
		if not model or not inSellZone(model) then
			return Result.err(Result.Codes.TOO_FAR)
		end
		source = record.Cargo
	end

	-- Werte ausschließlich aus den Definitionen; Erze ohne Balancewert bleiben im Rucksack
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
		return Result.err(Result.Codes.NOTHING_TO_SELL)
	end

	-- Prüfung oben und Änderung hier ohne Yield dazwischen → atomar, kein Doppelverkauf
	local levelsGained = 0
	DataService.Mutate(player, function(d)
		local target = if vehicleId == nil then d.Backpack else d.Vehicles.Owned[vehicleId :: string].Cargo
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
	if typeof(vehicleId) == "string" then
		VehicleService.RefreshCargo(player, vehicleId)
	end

	Log.debug(TAG, `{player.Name} verkauft für ${cash} und {xp} XP (Level {data.MiningLevel}, +{levelsGained})`)
	return Result.ok({ Cash = cash, XP = xp, Level = data.MiningLevel, LevelsGained = levelsGained })
end

function SellingService.Init()
	local existing = workspace:FindFirstChild("Center")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Center"
	local building = SellingBuilder.build(folder)
	counterPart = building:FindFirstChild("CounterPromptPart") :: BasePart
	sellZone = building:FindFirstChild("VehicleSellZone") :: BasePart
	folder.Parent = workspace

	RemoteService.OnInvoke("SellAll", sellAll)
end

function SellingService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if prompt:GetAttribute("SellCounter") ~= true then
			return
		end
		if DataService.IsLoaded(player) and isNearCounter(player) then
			RemoteService.FireClient("OpenSellMenu", player)
		end
	end)

	-- Einfahren in die Verkaufszone erkennen (docs/07 §25): Fenster einmal anbieten
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local vehicleId, model = VehicleService.GetDriven(player)
				local data = DataService.Get(player)
				local record = data and vehicleId and data.Vehicles.Owned[vehicleId]
				local inside = model ~= nil and inSellZone(model)
				if inside and record and next(record.Cargo) ~= nil then
					if not offered[player] then
						offered[player] = true
						RemoteService.FireClient("OpenSellMenu", player, { VehicleId = vehicleId })
					end
				elseif not inside then
					offered[player] = nil
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		offered[player] = nil
	end)
end

return SellingService
