--!strict
-- Elevator als Navigation zwischen Oberfläche und Minen (docs/04 §16–17, docs/12 §22–25).
-- Technisch ein Teleport mit kurzer Übergangsanimation. Jeder Plot hat einen eigenen
-- Mine-Shaft-Raum, der beim Wechsel auf die gewählte Mine umgestellt wird (D-014).
--
-- Ablauf: ProximityPrompt am Käfig → Server prüft Besitz → Client zeigt Minenauswahl →
-- RequestTravel(Ziel) → Server prüft Besitz, Nähe, Elevator gebaut, Mine freigeschaltet →
-- Übergang → Teleport → LocationChanged.
--
-- Der Ort eines Spielers ("surface" oder Mine-ID) ist Sitzungszustand und wird nicht
-- gespeichert: Nach Join oder Respawn ist man immer an der Oberfläche.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Mines = require(Shared.Definitions.Mines)
local Ores = require(Shared.Definitions.Ores)
local Result = require(Shared.Util.Result)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)

local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local MineShaftBuilder = require(script.Parent.Parent.World.MineShaftBuilder)
local ElevatorCageBuilder = require(script.Parent.Parent.World.ElevatorCageBuilder)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local BuildingService = require(script.Parent.BuildingService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "ElevatorService"
local SURFACE = "surface"
-- Zeit bis der Bildschirm schwarz ist, bevor teleportiert wird (muss zur Client-Animation passen)
local TRANSITION_IN_SECONDS = 0.7

local ElevatorService = {
	-- (player, location) nach jedem Ortswechsel
	LocationChanged = Signal.new() :: Signal.Signal<Player, string>,
}

local rooms: { [number]: Model } = {}
local locations: { [Player]: string } = {}
local traveling: { [Player]: boolean } = {}

local function notify(player: Player, kind: string, code: string, args: { [string]: any }?)
	RemoteService.FireClient("Notify", player, { Kind = kind, Code = code, Args = args })
end

local function setLocation(player: Player, location: string)
	locations[player] = location
	RemoteService.FireClient("LocationChanged", player, { Location = location })
	ElevatorService.LocationChanged:Fire(player, location)
end

local function findPart(container: Instance?, name: string): BasePart?
	local found = container and container:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

-- Käfig, an dem der Spieler gerade steht (abhängig vom aktuellen Ort).
local function currentElevatorPart(player: Player): BasePart?
	local location = locations[player] or SURFACE
	if location == SURFACE then
		return findPart(BuildingService.GetModel(player, "build_elevator"), "ElevatorPromptPart")
	end
	local plotId = PlotService.GetPlotId(player)
	return if plotId then findPart(rooms[plotId], "ElevatorPromptPart") else nil
end

local function isNearElevator(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local elevatorPart = currentElevatorPart(player)
	if not (root and root:IsA("BasePart") and elevatorPart) then
		return false
	end
	return (root.Position - elevatorPart.Position).Magnitude <= LayoutConfig.ElevatorUseDistance
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local kind = prompt:GetAttribute("ElevatorKind")
	if kind == nil then
		return
	end
	if kind == "Surface" then
		if not PlotService.IsOwnerOf(player, prompt) then
			notify(player, "Warning", Result.Codes.NOT_OWNER)
			return
		end
	elseif kind == "Mine" then
		if prompt:GetAttribute("PlotId") ~= PlotService.GetPlotId(player) then
			notify(player, "Warning", Result.Codes.NOT_OWNER)
			return
		end
	else
		return
	end
	RemoteService.FireClient("OpenElevatorMenu", player, { Location = locations[player] or SURFACE })
end

local function travel(player: Player, destination: unknown)
	if typeof(destination) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local mine = if destination == SURFACE then nil else Mines.Get(destination)
	if destination ~= SURFACE and not mine then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end

	local data = DataService.Get(player)
	local plotId = PlotService.GetPlotId(player)
	if not data or not plotId then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not data.Buildings.build_elevator then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if traveling[player] then
		return Result.err(Result.Codes.RATE_LIMITED)
	end
	if destination == (locations[player] or SURFACE) then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	if not isNearElevator(player) then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if mine and not Mines.IsAccessible(mine, data.MiningLevel) then
		return Result.err(if mine.RequiredLevel then Result.Codes.LEVEL_TOO_LOW else Result.Codes.NOT_AVAILABLE)
	end

	local target: BasePart?
	local title, subtitle
	if mine then
		local ore = Ores.Get(mine.OreId)
		title = string.format("MINE SHAFT %02d", mine.Number)
		subtitle = if ore then string.upper(ore.DisplayName) else ""
	else
		title = "SURFACE"
		subtitle = ""
	end

	-- Abfahrt: Tor schließt, Warnleuchte an, Bildschirm blendet ab
	local departure = currentElevatorPart(player)
	local departureCage = departure and departure:FindFirstAncestor("Cage")
	traveling[player] = true
	if departureCage then
		ElevatorCageBuilder.setGate(departureCage, false, true)
		ElevatorCageBuilder.setBeacon(departureCage, true)
	end
	RemoteService.FireClient("ElevatorTransition", player, { Title = title, Subtitle = subtitle })
	task.wait(TRANSITION_IN_SECONDS)

	if mine then
		local room = rooms[plotId]
		MineShaftBuilder.configure(room, mine)
		target = findPart(room, "ArrivalPoint")
	else
		target = findPart(BuildingService.GetModel(player, "build_elevator"), "ArrivalPoint")
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not target or not character or not humanoid or humanoid.Health <= 0 or player.Parent ~= Players then
		traveling[player] = nil
		if departureCage then
			ElevatorCageBuilder.setBeacon(departureCage, false)
			ElevatorCageBuilder.setGate(departureCage, true, true)
		end
		return Result.err(Result.Codes.INTERNAL_ERROR)
	end

	pcall(function()
		player:RequestStreamAroundAsync((target :: BasePart).Position, 3)
	end)
	character:PivotTo((target :: BasePart).CFrame)
	setLocation(player, destination)
	traveling[player] = nil

	-- Ankunft: Tor des Zielkorbs ist offen; Abfahrtskorb wieder öffnen, Leuchte aus
	local arrivalCage = (target :: BasePart):FindFirstAncestor("Cage")
	if arrivalCage then
		ElevatorCageBuilder.setGate(arrivalCage, true, true)
	end
	if departureCage then
		local cage = departureCage
		task.delay(0.5, function()
			ElevatorCageBuilder.setBeacon(cage, false)
			ElevatorCageBuilder.setGate(cage, true, true)
		end)
	end
	Log.debug(TAG, `{player.Name} → {destination}`)
	return Result.ok(destination)
end

function ElevatorService.Init()
	local existing = workspace:FindFirstChild("MineShafts")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "MineShafts"
	for plotId = 1, GameConfig.MaxPlots do
		local room = MineShaftBuilder.build(folder, plotId, PlotBuilder.getPlotCFrame(plotId))
		local first = Mines.GetByNumber(1)
		if first then
			MineShaftBuilder.configure(room, first)
		end
		rooms[plotId] = room
	end
	folder.Parent = workspace

	RemoteService.OnInvoke("RequestTravel", travel)
end

function ElevatorService.Start()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

	local function onPlayer(player: Player)
		locations[player] = SURFACE
		player.CharacterAdded:Connect(function()
			-- Nach Respawn steht man im Büro (PlotService), also an der Oberfläche.
			traveling[player] = nil
			setLocation(player, SURFACE)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		locations[player] = nil
		traveling[player] = nil
	end)
end

function ElevatorService.GetLocation(player: Player): string
	return locations[player] or SURFACE
end

-- Mine-Shaft-Raum des eigenen Plots (für MiningService in Schritt 2c).
function ElevatorService.GetRoom(player: Player): Model?
	local plotId = PlotService.GetPlotId(player)
	return if plotId then rooms[plotId] else nil
end

return ElevatorService
