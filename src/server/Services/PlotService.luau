--!strict
-- Plot-Zuweisung und Besitzprüfung (docs/04 §37, docs/15 §16).
-- Seit D-090 (Felix 2026-11-12): Neue Spieler claimen ihr Grundstück selbst über einen
-- Bodenknopf vor dem Grundstück an der Straße. Wer schon einmal geclaimt hat (Stats.PlotClaimed),
-- bekommt beim Join wie bisher automatisch den freien Plot mit der kleinsten ID. Beim Verlassen
-- wird der Plot freigegeben und sein Claim-Knopf erscheint wieder. Alle anderen Systeme fragen
-- Besitz nur über diesen Service ab.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Result = require(Shared.Util.Result)
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)

local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local EnvironmentBuilder = require(script.Parent.Parent.World.EnvironmentBuilder)
local CenterBuilder = require(script.Parent.Parent.World.CenterBuilder)
local HallLayout = require(script.Parent.Parent.World.HallLayout)
local RemoteService = require(script.Parent.RemoteService)
local DataService = require(script.Parent.DataService)

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

-- Claim-Knopf vor dem Grundstück an der Straße (D-090), nur solange der Plot frei ist
local CLAIM_COLOR = Color3.fromRGB(88, 196, 120)
local claimButtons: { [number]: BasePart } = {}
local lastClaimTouch: { [Player]: number } = {}
local claimPlot: (player: Player, plotId: number) -> ()

local function removeClaimButton(plotId: number)
	local button = claimButtons[plotId]
	if button then
		button:Destroy()
		claimButtons[plotId] = nil
	end
end

local function makeClaimButton(plotId: number)
	removeClaimButton(plotId)
	local pos = LayoutConfig.ClaimButton
	local size = LayoutConfig.ClaimButtonSize
	local button = Instance.new("Part")
	button.Name = "ClaimButton"
	button.Anchored = true
	button.CanCollide = false
	button.Size = size
	button.CFrame = PlotBuilder.getPlotCFrame(plotId) * CFrame.new(pos.X, LayoutConfig.GroundY + 1 + size.Y / 2, pos.Y)
	button.Material = Enum.Material.Neon
	button.Color = CLAIM_COLOR
	button.Transparency = 0.15
	button:SetAttribute("PlotId", plotId)
	CollectionService:AddTag(button, "ClaimButton")

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ClaimGui"
	billboard.Size = UDim2.fromOffset(220, 74)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.MaxDistance = 250
	billboard.LightInfluence = 0
	billboard.Parent = button
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	card.BackgroundTransparency = 0.15
	card.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0.5, 0)
	title.Position = UDim2.fromOffset(8, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(240, 242, 245)
	title.Text = "CLAIM PLOT"
	title.Parent = card
	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -16, 0.38, 0)
	sub.Position = UDim2.new(0, 8, 0.55, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextScaled = true
	sub.TextColor3 = CLAIM_COLOR
	sub.Text = `Plot {plotId} · FREE`
	sub.Parent = card

	button.Touched:Connect(function(hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		local toucher = character and Players:GetPlayerFromCharacter(character)
		if not toucher then
			-- auch mit dem eigenen Fahrzeug drüberfahren (Fahrzeug-Model trägt OwnerUserId)
			local node: Instance? = hit
			while node and node ~= workspace do
				local owner = node:GetAttribute("OwnerUserId")
				if node:IsA("Model") and node:GetAttribute("VehicleId") and typeof(owner) == "number" then
					toucher = Players:GetPlayerByUserId(owner)
					break
				end
				node = node.Parent
			end
		end
		if not toucher then
			return
		end
		local now = os.clock()
		if lastClaimTouch[toucher] and now - lastClaimTouch[toucher] < 1 then
			return
		end
		lastClaimTouch[toucher] = now
		claimPlot(toucher, plotId)
	end)
	button.Parent = plots[plotId]
	claimButtons[plotId] = button
end

local function notify(player: Player, kind: string, code: string, args: { [string]: any }?)
	RemoteService.FireClient("Notify", player, { Kind = kind, Code = code, Args = args })
end

local function assignTo(player: Player, plotId: number)
	ownerByPlot[plotId] = player
	plotByPlayer[player] = plotId
	removeClaimButton(plotId)
	local plot = plots[plotId]
	plot:SetAttribute("OwnerUserId", player.UserId)
	PlotBuilder.setSign(plot, "", `Plot {plotId}\n{player.DisplayName}`, nil)
	Log.debug(TAG, `{player.Name} → Plot {plotId}`)

	RemoteService.FireClient("PlotAssigned", player, plotId)
	PlotService.PlotAssigned:Fire(player, plotId)
end

-- Wiederkehrende Spieler (schon einmal geclaimt): freier Plot mit der kleinsten ID, Spawn im Büro
local function assign(player: Player)
	if plotByPlayer[player] then
		return
	end
	for plotId = 1, GameConfig.MaxPlots do
		if ownerByPlot[plotId] == nil then
			assignTo(player, plotId)
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

-- Claim über den Knopf: Spieler steht schon am Grundstück, kein Teleport. Der nächste Spawn ist im
-- Büro (Hütte vor dem Bett).
claimPlot = function(player: Player, plotId: number)
	if not DataService.IsLoaded(player) then
		return
	end
	if plotByPlayer[player] then
		if plotByPlayer[player] ~= plotId then
			notify(player, "Info", "ALREADY_HAS_PLOT")
		end
		return
	end
	if ownerByPlot[plotId] ~= nil then
		notify(player, "Warning", "PLOT_TAKEN")
		return
	end
	DataService.Mutate(player, function(d)
		d.Stats.PlotClaimed = true
	end)
	DataService.RequestSave(player)
	assignTo(player, plotId)
	notify(player, "Success", "PLOT_CLAIMED", { Plot = plotId })
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
	PlotBuilder.setSign(plot, "", `Plot {plotId}\nFree`, nil)
	PlotBuilder.setSpawn(plot, PlotBuilder.getDefaultSpawnCFrame(plotId))
	makeClaimButton(plotId)
	lastClaimTouch[player] = nil
	Log.debug(TAG, `Plot {plotId} freigegeben ({player.Name})`)
end

function PlotService.Init()
	-- von Hand angepasstes Hallen-Layout aus der Place-Datei übernehmen (vor dem Bau der Plots)
	HallLayout.init()
	local folder = PlotBuilder.buildAll()
	-- Umgebung (Wiese, Wald, Berge, Seen, Straßendetails, Platz) – reine Optik (Phase 13a)
	local oldEnvironment = workspace:FindFirstChild("Environment")
	if oldEnvironment then
		oldEnvironment:Destroy()
	end
	local environment = EnvironmentBuilder.build(workspace)
	-- Gestaltung der Map-Mitte (Promenade, Parkplätze, Park, Garten, Bäume; D-057)
	CenterBuilder.build(environment)
	-- Die Baseplate der Place-Datei liegt unter der Wiese; außerhalb davon soll sie nicht als graue
	-- Fläche auffallen (nur zur Laufzeit, die Place-Datei bleibt unverändert)
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Color3.fromRGB(70, 112, 56)
		baseplate.Material = Enum.Material.Grass
	end
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

-- Laufgeschwindigkeit aus GameConfig (Felix 2026-11-12)
local function applyWalkSpeed(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.WalkSpeed = GameConfig.Player.WalkSpeed
	end
end

function PlotService.Start()
	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(applyWalkSpeed, character)
			teleportToPlot(player, character)
		end)
		if player.Character then
			task.spawn(applyWalkSpeed, player.Character)
		end
		-- Wer schon einmal geclaimt hat, bekommt seinen Plot automatisch (D-090); sonst Claim-Knopf
		local data = DataService.Get(player)
		if data and data.Stats.PlotClaimed then
			assign(player)
		end
	end

	for plotId in plots do
		makeClaimButton(plotId)
	end
	DataService.ProfileLoaded:Connect(function(player, data)
		if data.Stats.PlotClaimed then
			assign(player)
		end
	end)
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
