--!strict
-- Start vor dem Autohaus (Felix 2026-11-12, D-090): Neue Spieler ohne Grundstück spawnen auf dem
-- Parkplatz vor dem Autohaus vor ihrem kostenlosen Starterauto (Pickup). Damit fahren sie zu einem
-- freien Grundstück und claimen es am Knopf an der Straße (PlotService). Wer schon einmal geclaimt
-- hat, bekommt seinen Plot beim Join automatisch und spawnt im Büro; dann tut dieser Service nichts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local VehicleService = require(script.Parent.VehicleService)
local RemoteService = require(script.Parent.RemoteService)

local StarterService = {}

-- Parkplatz vor dem Autohaus = dritter Shop-Parkplatz (Equipment, Machine, Vehicle; CenterBuilder)
local LOT_NAME = "ShopLot3"
-- Abstand der Spielfigur vor der Fahrzeugmitte (Richtung Autohaus), Blick zum Auto
local STAND_AHEAD = LayoutConfig.Center.StallDepth / 2 + 3

local reserved: { [Player]: number } = {}
local hinted: { [Player]: boolean } = {}

local function lot(): Instance?
	for _, d in workspace:GetDescendants() do
		if d.Name == LOT_NAME and d.Parent and d.Parent.Name == "Parking" then
			return d
		end
	end
	return nil
end

-- Startplatz des Spielers (freie Lücke mit der kleinsten Nummer)
local function spotFor(player: Player): BasePart?
	local parking = lot()
	if not parking then
		return nil
	end
	local index = reserved[player]
	if not index then
		local used: { [number]: boolean } = {}
		for _, i in reserved do
			used[i] = true
		end
		local i = 1
		while used[i] do
			i += 1
		end
		index = i
	end
	local spot = parking:FindFirstChild(`StallSpot{index}`) or parking:FindFirstChild("StallSpot1")
	if spot and spot:IsA("BasePart") then
		reserved[player] = index
		return spot
	end
	return nil
end

local function standCFrame(spot: BasePart): CFrame
	local pos = (spot.CFrame * CFrame.new(0, 3, -STAND_AHEAD)).Position
	return CFrame.lookAt(pos, Vector3.new(spot.Position.X, pos.Y, spot.Position.Z))
end

local function placeCharacter(player: Player, character: Model)
	if PlotService.GetPlotId(player) then
		return
	end
	local spot = spotFor(player)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not (spot and root) or character.Parent == nil or PlotService.GetPlotId(player) then
		return
	end
	-- Einen Frame warten, damit Roblox die Standard-Spawnposition nicht danach erneut setzt
	task.wait()
	character:PivotTo(standCFrame(spot))
end

-- Starterauto auf den Startplatz stellen (falls es noch nirgends steht) und Spieler davor
local function start(player: Player)
	if PlotService.GetPlotId(player) or not DataService.IsLoaded(player) then
		return
	end
	local vehicleId = VehicleService.EnsureStarter(player)
	local spot = spotFor(player)
	if vehicleId and spot and not VehicleService.GetModel(player, vehicleId) then
		VehicleService.SpawnAt(player, vehicleId, spot.CFrame)
	end
	if player.Character then
		task.spawn(placeCharacter, player, player.Character)
	end
	if not hinted[player] then
		hinted[player] = true
		task.delay(2, function()
			if player.Parent == Players and not PlotService.GetPlotId(player) then
				RemoteService.FireClient("Notify", player, { Kind = "Info", Code = "CLAIM_HINT" })
			end
		end)
	end
end

function StarterService.Init() end

function StarterService.Start()
	DataService.ProfileLoaded:Connect(function(player)
		task.defer(start, player)
	end)
	PlotService.PlotAssigned:Connect(function(player)
		reserved[player] = nil
	end)
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			placeCharacter(player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
		task.spawn(start, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		reserved[player] = nil
		hinted[player] = nil
	end)
end

return StarterService
