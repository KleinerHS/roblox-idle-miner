--!strict
-- Plot-Zuweisung und Besitzprüfung (docs/04 §37, docs/15 §16).
-- Jeder Spieler bekommt beim Join den freien Plot mit der kleinsten ID, beim Verlassen
-- wird er freigegeben. Alle anderen Systeme fragen Besitz nur über diesen Service ab.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Result = require(Shared.Util.Result)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)

local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "PlotService"

local PlotService = {
	-- (player, plotId)
	PlotAssigned = Signal.new() :: Signal.Signal<Player, number>,
	-- (player, plotId) – vor dem Freigeben
	PlotReleasing = Signal.new() :: Signal.Signal<Player, number>,
}

local plots: { [number]: Model } = {}
local ownerByPlot: { [number]: Player } = {}
local plotByPlayer: { [Player]: number } = {}

local function teleportToPlot(player: Player, character: Model)
	local plotId = plotByPlayer[player]
	if not plotId then
		return
	end
	local spawnPoint = plots[plotId]:FindFirstChild("SpawnPoint")
	if not (spawnPoint and spawnPoint:IsA("BasePart")) then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or character.Parent == nil then
		return
	end
	-- Einen Frame warten, damit Roblox die Standard-Spawnposition nicht danach erneut setzt.
	task.wait()
	character:PivotTo(spawnPoint.CFrame + Vector3.new(0, 3, 0))
end

local function assign(player: Player)
	if plotByPlayer[player] then
		return
	end
	for plotId = 1, GameConfig.MaxPlots do
		if ownerByPlot[plotId] == nil then
			ownerByPlot[plotId] = player
			plotByPlayer[player] = plotId
			local plot = plots[plotId]
			plot:SetAttribute("OwnerUserId", player.UserId)
			PlotBuilder.setSignText(plot, `Plot {plotId}\n{player.DisplayName}`)
			Log.debug(TAG, `{player.Name} → Plot {plotId}`)

			RemoteService.FireClient("PlotAssigned", player, plotId)
			PlotService.PlotAssigned:Fire(player, plotId)

			if player.Character then
				task.spawn(teleportToPlot, player, player.Character)
			end
			return
		end
	end

	-- Sollte bei MaxPlayers = 6 nie passieren.
	Log.warn(TAG, `Kein freier Plot für {player.Name}`)
	player:Kick("Der Server ist voll. Bitte einem anderen Server beitreten.")
end

local function release(player: Player)
	local plotId = plotByPlayer[player]
	if not plotId then
		return
	end
	PlotService.PlotReleasing:Fire(player, plotId)
	plotByPlayer[player] = nil
	ownerByPlot[plotId] = nil
	local plot = plots[plotId]
	plot:SetAttribute("OwnerUserId", 0)
	PlotBuilder.setSignText(plot, `Plot {plotId}\nFrei`)
	Log.debug(TAG, `Plot {plotId} freigegeben ({player.Name})`)
end

function PlotService.Init()
	local folder = PlotBuilder.buildAll()
	for _, child in folder:GetChildren() do
		local plotId = child:GetAttribute("PlotId")
		if child:IsA("Model") and typeof(plotId) == "number" then
			plots[plotId] = child
		end
	end

	RemoteService.OnInvoke("GetMyPlot", function(player: Player)
		local plotId = plotByPlayer[player]
		if not plotId then
			return Result.err(Result.Codes.NO_PLOT)
		end
		return Result.ok(plotId)
	end)
end

function PlotService.Start()
	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			teleportToPlot(player, character)
		end)
		assign(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

function PlotService.GetPlotId(player: Player): number?
	return plotByPlayer[player]
end

function PlotService.GetPlot(player: Player): Model?
	local plotId = plotByPlayer[player]
	return if plotId then plots[plotId] else nil
end

function PlotService.GetOwner(plotId: number): Player?
	return ownerByPlot[plotId]
end

-- Besitzprüfung für beliebige Instanzen innerhalb eines Plots (Buttons, Laptop, Slots …).
function PlotService.IsOwnerOf(player: Player, instance: Instance): boolean
	local plotId = plotByPlayer[player]
	if not plotId then
		return false
	end
	local plot = plots[plotId]
	return instance == plot or instance:IsDescendantOf(plot)
end

return PlotService
