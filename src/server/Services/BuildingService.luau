--!strict
-- Tycoon-Baukette (docs/04 §10–14, §38): baut gekaufte Schritte auf dem Plot des Spielers
-- auf, zeigt immer nur den nächsten Kaufbutton und wickelt Käufe serverseitig ab.
-- Ein Kauf passiert durch Betreten des Buttons (klassischer Tycoon-Bodenbutton). Der Client
-- schickt dafür nichts; Besitz, Reihenfolge, Level und Geld prüft nur der Server.
--
-- Hängt die Firmeneinrichtung ab (CompanyService ruft danach Refresh auf).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local BuildSteps = require(Shared.Definitions.BuildSteps)
local CompanyIdentity = require(Shared.Definitions.CompanyIdentity)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Signal = require(Shared.Util.Signal)
local NumberFormat = require(Shared.Util.NumberFormat)
local Log = require(Shared.Util.Log)

local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local BuildTemplates = require(script.Parent.Parent.World.BuildTemplates)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "BuildingService"
local BUTTON_TAG = "TycoonButton"
local TOUCH_COOLDOWN = 1

local COLOR_BUTTON_READY = Color3.fromRGB(88, 196, 120)
local COLOR_BUTTON_BLOCKED = Color3.fromRGB(226, 92, 92)

local BuildingService = {
	-- (player, stepId, model) nachdem ein Gebäudemodell auf dem Plot erzeugt wurde
	ModelBuilt = Signal.new() :: Signal.Signal<Player, string, Model>,
}

type PlotState = {
	plot: Model,
	models: { [string]: Model },
	button: BasePart?,
	buttonStepId: string?,
}

local states: { [Player]: PlotState } = {}
local lastTouch: { [Player]: number } = {}

local function notify(player: Player, kind: string, code: string, args: { [string]: any }?)
	RemoteService.FireClient("Notify", player, { Kind = kind, Code = code, Args = args })
end

local function getFolder(plot: Model): Folder
	local folder = plot:FindFirstChild("Buildings")
	assert(folder and folder:IsA("Folder"), "Plot ohne Buildings-Ordner")
	return folder
end

local function plotCFrame(plot: Model): CFrame
	return PlotBuilder.getPlotCFrame(plot:GetAttribute("PlotId") :: number)
end

-- Prüft, ob der Spieler `step` jetzt kaufen darf. Gibt nil oder einen Fehlercode zurück.
local function checkPurchase(data: Types.PlayerData, step: BuildSteps.BuildStepDefinition): string?
	if data.Buildings[step.Id] then
		return Result.Codes.ALREADY_DONE
	end
	local nextStep = BuildSteps.GetNext(data.Buildings)
	if not nextStep or nextStep.Id ~= step.Id then
		return Result.Codes.NOT_AVAILABLE
	end
	if step.Requires and not data.Buildings[step.Requires] then
		return Result.Codes.NOT_AVAILABLE
	end
	if step.RequiresCompanySetup and not data.Company.Created then
		return Result.Codes.NOT_AVAILABLE
	end
	if data.MiningLevel < step.RequiredLevel then
		return Result.Codes.LEVEL_TOO_LOW
	end
	if data.Cash < step.Price then
		return Result.Codes.NOT_ENOUGH_MONEY
	end
	return nil
end

local function makeButtonLabel(button: BasePart, step: BuildSteps.BuildStepDefinition, data: Types.PlayerData)
	local gui = button:FindFirstChild("ButtonGui") :: BillboardGui?
	if not gui then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ButtonGui"
		billboard.Size = UDim2.fromOffset(220, 74)
		billboard.StudsOffset = Vector3.new(0, 4.5, 0)
		billboard.MaxDistance = 90
		billboard.LightInfluence = 0
		billboard.Parent = button

		local frame = Instance.new("Frame")
		frame.Name = "Card"
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
		frame.BackgroundTransparency = 0.15
		frame.Parent = billboard
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -16, 0.5, 0)
		title.Position = UDim2.fromOffset(8, 4)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(240, 242, 245)
		title.Parent = frame

		local sub = Instance.new("TextLabel")
		sub.Name = "Sub"
		sub.Size = UDim2.new(1, -16, 0.38, 0)
		sub.Position = UDim2.new(0, 8, 0.55, 0)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.GothamMedium
		sub.TextScaled = true
		sub.Parent = frame
		gui = billboard
	end
	local card = (gui :: BillboardGui):FindFirstChild("Card") :: Frame
	local title = card:FindFirstChild("Title") :: TextLabel
	local sub = card:FindFirstChild("Sub") :: TextLabel

	title.Text = `BUILD {string.upper(step.DisplayName)}`
	if data.MiningLevel < step.RequiredLevel then
		sub.Text = `Requires Mining Level {step.RequiredLevel}`
		sub.TextColor3 = COLOR_BUTTON_BLOCKED
		button.Color = COLOR_BUTTON_BLOCKED
	else
		sub.Text = if step.Price == 0 then "FREE" else `${NumberFormat.withSeparators(step.Price)}`
		sub.TextColor3 = if data.Cash >= step.Price then COLOR_BUTTON_READY else Color3.fromRGB(240, 180, 70)
		button.Color = COLOR_BUTTON_READY
	end
end

local tryPurchase: (player: Player, stepId: string) -> ()

local function createButton(state: PlotState, player: Player, step: BuildSteps.BuildStepDefinition): BasePart
	local position = LayoutConfig.BuildButtons[step.Id]
	assert(position, `Keine Button-Position für {step.Id} in LayoutConfig.BuildButtons`)
	local size = LayoutConfig.ButtonSize
	local button = Instance.new("Part")
	button.Name = "BuyButton"
	button.Anchored = true
	button.CanCollide = false
	button.Size = size
	button.CFrame = plotCFrame(state.plot) * CFrame.new(position.X, LayoutConfig.HallFloorTop + size.Y / 2, position.Y)
	button.Material = Enum.Material.Neon
	button.Color = COLOR_BUTTON_READY
	button.Transparency = 0.15
	button:SetAttribute("BuildStepId", step.Id)
	CollectionService:AddTag(button, BUTTON_TAG)

	button.Touched:Connect(function(hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		local toucher = character and Players:GetPlayerFromCharacter(character)
		if not toucher then
			return
		end
		local now = os.clock()
		if lastTouch[toucher] and now - lastTouch[toucher] < TOUCH_COOLDOWN then
			return
		end
		lastTouch[toucher] = now
		if toucher ~= player or not PlotService.IsOwnerOf(toucher, button) then
			notify(toucher, "Warning", Result.Codes.NOT_OWNER)
			return
		end
		local stepId = button:GetAttribute("BuildStepId")
		if typeof(stepId) == "string" then
			tryPurchase(toucher, stepId)
		end
	end)

	button.Parent = getFolder(state.plot)
	return button
end

local function updateButton(player: Player, state: PlotState, data: Types.PlayerData)
	local nextStep = BuildSteps.GetNext(data.Buildings)
	local visible = nextStep ~= nil and (not nextStep.RequiresCompanySetup or data.Company.Created)

	if not visible or (state.buttonStepId ~= (nextStep and nextStep.Id)) then
		if state.button then
			state.button:Destroy()
		end
		state.button = nil
		state.buttonStepId = nil
	end
	if visible and nextStep then
		if not state.button then
			state.button = createButton(state, player, nextStep)
			state.buttonStepId = nextStep.Id
		end
		makeButtonLabel(state.button :: BasePart, nextStep, data)
	end
end

local function updateSign(state: PlotState, player: Player, data: Types.PlayerData)
	local plotId = state.plot:GetAttribute("PlotId")
	if data.Company.Created then
		local logo = CompanyIdentity.LogoById[data.Company.LogoId]
		local color = CompanyIdentity.ColorById[data.Company.ColorId]
		PlotBuilder.setSign(state.plot, if logo then logo.Glyph else "", data.Company.Name, if color then color.Color else nil)
	else
		PlotBuilder.setSign(state.plot, "", `Plot {plotId}\n{player.DisplayName}`, nil)
	end
end

local function updateSpawn(state: PlotState)
	local office = state.models.build_office
	local anchor = office and office:FindFirstChild("SpawnAnchor")
	if anchor and anchor:IsA("BasePart") then
		PlotBuilder.setSpawn(state.plot, anchor.CFrame)
	else
		PlotBuilder.setSpawn(state.plot, PlotBuilder.getDefaultSpawnCFrame(state.plot:GetAttribute("PlotId") :: number))
	end
end

-- Baut fehlende Gebäude, aktualisiert Button, Schild und Spawn. Idempotent.
local function render(player: Player)
	local plot = PlotService.GetPlot(player)
	local data = DataService.Get(player)
	if not plot or not data then
		return
	end
	local state = states[player]
	if not state or state.plot ~= plot then
		state = { plot = plot, models = {}, button = nil, buttonStepId = nil }
		states[player] = state
	end
	local s = state :: PlotState

	for _, step in BuildSteps.List do
		if data.Buildings[step.Id] and not s.models[step.Id] then
			local model = BuildTemplates.build(step.Id, plotCFrame(plot))
			if model then
				model.Parent = getFolder(plot)
				s.models[step.Id] = model
				BuildingService.ModelBuilt:Fire(player, step.Id, model)
			end
		end
	end

	updateButton(player, s, data)
	updateSign(s, player, data)
	updateSpawn(s)
end

local function clear(player: Player)
	local state = states[player]
	states[player] = nil
	lastTouch[player] = nil
	if not state then
		return
	end
	for _, model in state.models do
		model:Destroy()
	end
	if state.button then
		state.button:Destroy()
	end
end

tryPurchase = function(player: Player, stepId: string)
	local data = DataService.Get(player)
	local step = BuildSteps.Get(stepId)
	if not data or not step then
		return
	end
	local code = checkPurchase(data, step)
	if code then
		if code ~= Result.Codes.ALREADY_DONE then
			notify(player, "Warning", code, { Level = step.RequiredLevel, Price = step.Price })
		end
		return
	end

	-- Prüfung oben und Änderung hier laufen ohne Yield dazwischen → atomar.
	local applied = DataService.Mutate(player, function(d)
		d.Cash -= step.Price
		d.Buildings[step.Id] = true
	end)
	if not applied then
		return
	end

	Log.debug(TAG, `{player.Name} kauft {step.Id} für {step.Price}`)
	render(player)
	DataService.RequestSave(player)
	notify(player, "Success", "BUILD_PURCHASED", { Name = step.DisplayName })
end

function BuildingService.Init() end

function BuildingService.Start()
	PlotService.PlotAssigned:Connect(function(player)
		render(player)
	end)
	DataService.ProfileLoaded:Connect(function(player)
		render(player)
	end)
	PlotService.PlotReleasing:Connect(function(player)
		clear(player)
	end)
	-- Geld/Level ändern die Button-Beschriftung (z. B. nach Verkauf in Schritt 2d).
	DataService.Changed:Connect(function(player)
		local state = states[player]
		local data = DataService.Get(player)
		if state and data then
			updateButton(player, state, data)
		end
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(render, player)
	end
end

-- Nach Änderungen außerhalb der Baukette (z. B. Firmeneinrichtung) neu aufbauen.
function BuildingService.Refresh(player: Player)
	render(player)
end

-- Alles abreißen und aus den aktuellen Daten neu aufbauen (z. B. nach Reset in Studio).
function BuildingService.Rebuild(player: Player)
	clear(player)
	render(player)
end

-- Plot-Modell eines gebauten Schritts (z. B. Elevator für Schritt 2b).
function BuildingService.GetModel(player: Player, stepId: string): Model?
	local state = states[player]
	return if state then state.models[stepId] else nil
end

return BuildingService
