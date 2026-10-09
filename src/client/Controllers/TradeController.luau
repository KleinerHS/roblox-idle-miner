--!strict
-- Handel auf dem Client (docs/13 §5–12):
--   * Eigener "Trade"-Prompt am eigenen Charakter wird lokal ausgeblendet (T bei anderen).
--   * Eingehende Anfrage: kleines Fenster mit ACCEPT / DECLINE (läuft automatisch ab).
--   * Handelsfenster: YOUR OFFER | THEIR OFFER, darunter das eigene Lager (Materialien mit
--     Menge) und unplatzierte Drills zum Hinzufügen. LOCK OFFER → kurze Bestätigungsphase →
--     CONFIRM. Jede Änderung setzt Sperren zurück; alles prüft und tauscht der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Materials = require(Shared.Definitions.Materials)
local Drills = require(Shared.Definitions.Drills)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Trade

local TradeController = {}

local player = Players.LocalPlayer

-- Anfrage-Fenster
local requestGui: ScreenGui
local requestLabel: TextLabel
local currentRequest: string? = nil
local requestExpires = 0

-- Handelsfenster
local gui: ScreenGui
local partnerLabel: TextLabel
local statusLabel: TextLabel
local mineList: ScrollingFrame
local theirsList: ScrollingFrame
local stockList: ScrollingFrame
local lockButton: TextButton
local confirmButton: TextButton
local state: any = nil
local confirmReadyAt = 0
-- eigenes Angebot (lokale Kopie, wird komplett an den Server geschickt)
local myMaterials: { [string]: number } = {}
local myDrills: { [string]: boolean } = {}
local busy = false

local function call(remote: string, ...: any): boolean
	if busy then
		return false
	end
	busy = true
	local result = Net.invoke(remote, ...)
	busy = false
	if not result.success then
		NotificationController.Show("Warning", result.code)
	end
	return result.success
end

local function sendOffer()
	local drillIds = {}
	for id in myDrills do
		table.insert(drillIds, id)
	end
	call("TradeSetOffer", myMaterials, drillIds)
end

local function clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function row(parent: Instance, order: number, color: Color3?, label: string, buttonText: string?, onClick: (() -> ())?)
	local frame = Create("Frame", {
		Size = UDim2.new(1, -6, 0, 34),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 6) }),
	})
	if color then
		Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(10, 10),
			BackgroundColor3 = color,
			Parent = frame,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	Create("TextLabel", {
		Position = UDim2.fromOffset(if color then 16 else 0, 0),
		Size = UDim2.new(1, if buttonText then -96 else -16, 1, 0),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = label,
		Parent = frame,
	})
	if buttonText and onClick then
		local b: TextButton = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(84, 26),
			BackgroundColor3 = UITheme.Colors.SurfaceRaised,
			Font = UITheme.FontBold,
			TextSize = 12,
			TextColor3 = UITheme.Colors.TextPrimary,
			Text = buttonText,
			Parent = frame,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		b.Activated:Connect(onClick)
	end
	return frame
end

local function offerRows(list: ScrollingFrame, offer: any, mine: boolean)
	clear(list)
	local order = 0
	local ids = {}
	for id in offer.Materials do
		table.insert(ids, id)
	end
	Materials.SortIds(ids)
	for _, id in ids do
		order += 1
		local m = Materials.Get(id)
		local label = `{if m then m.DisplayName else id} ×{NumberFormat.withSeparators(offer.Materials[id])}`
		if mine then
			local materialId = id
			row(list, order, m and m.Color, label, TEXT.Remove, function()
				myMaterials[materialId] = nil
				sendOffer()
			end)
		else
			row(list, order, m and m.Color, label)
		end
	end
	for _, drill in offer.Drills do
		order += 1
		local def = Drills.Get(drill.Type)
		local label = `{if def then def.DisplayName else drill.Type}`
		if mine then
			local drillId = drill.Id
			row(list, order, nil, label, TEXT.Remove, function()
				myDrills[drillId] = nil
				sendOffer()
			end)
		else
			row(list, order, nil, label)
		end
	end
	if order == 0 then
		Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 13,
			TextColor3 = UITheme.Colors.TextSecondary,
			Text = TEXT.Nothing,
			Parent = list,
		})
	end
end

-- Eigenes Lager und unplatzierte Drills zum Hinzufügen (Menge per Eingabefeld)
local function stockRows()
	clear(stockList)
	local snapshot = StateController.Get()
	if not snapshot then
		return
	end
	local ids = {}
	for id, n in snapshot.StorageItems do
		if n > 0 then
			table.insert(ids, id)
		end
	end
	Materials.SortIds(ids)
	local order = 0
	for _, id in ids do
		order += 1
		local m = Materials.Get(id)
		local available = snapshot.StorageItems[id] - (myMaterials[id] or 0)
		local frame = row(stockList, order, m and m.Color, `{if m then m.DisplayName else id} ({NumberFormat.withSeparators(snapshot.StorageItems[id])})`)
		local nameLabel = frame:FindFirstChildOfClass("TextLabel")
		if nameLabel then
			nameLabel.Size = UDim2.new(1, -170, 1, 0)
		end
		local box: TextBox = Create("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -78, 0.5, 0),
			Size = UDim2.fromOffset(70, 26),
			BackgroundColor3 = UITheme.Colors.SurfaceRaised,
			Font = UITheme.Font,
			TextSize = 13,
			TextColor3 = UITheme.Colors.TextPrimary,
			PlaceholderText = tostring(math.max(0, available)),
			Text = "",
			ClearTextOnFocus = false,
			Parent = frame,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		local add: TextButton = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(70, 26),
			BackgroundColor3 = UITheme.Colors.Positive,
			Font = UITheme.FontBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(20, 24, 28),
			Text = TEXT.Add,
			Parent = frame,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		local materialId = id
		add.Activated:Connect(function()
			local amount = tonumber(box.Text) or available
			amount = math.clamp(math.floor(amount), 0, math.max(0, available))
			if amount > 0 then
				myMaterials[materialId] = (myMaterials[materialId] or 0) + amount
				sendOffer()
			end
		end)
	end
	for _, drill in snapshot.Drills do
		if drill.MineId == nil and not myDrills[drill.Id] then
			order += 1
			local def = Drills.Get(drill.Type)
			local drillId = drill.Id
			row(stockList, order, nil, `{if def then def.DisplayName else drill.Type}`, TEXT.Add, function()
				myDrills[drillId] = true
				sendOffer()
			end)
		end
	end
	if order == 0 then
		Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 13,
			TextColor3 = UITheme.Colors.TextSecondary,
			Text = TEXT.NoStock,
			Parent = stockList,
		})
	end
end

local function render()
	if not state then
		return
	end
	partnerLabel.Text = string.format(TEXT.With, state.PartnerName)
	offerRows(mineList, state.Mine, true)
	offerRows(theirsList, state.Theirs, false)
	stockRows()
	lockButton.Text = if state.MyLocked then TEXT.Unlock else TEXT.Lock
	lockButton.BackgroundColor3 = if state.MyLocked then UITheme.Colors.SurfaceRaised else UITheme.Colors.DefaultAccent
	local status
	if state.MyConfirmed and not state.TheirConfirmed then
		status = TEXT.WaitingConfirm
	elseif state.TheirConfirmed then
		status = TEXT.TheyConfirmed
	elseif state.MyLocked and state.TheirLocked then
		status = TEXT.BothLocked
	elseif state.TheirLocked then
		status = TEXT.TheyLocked
	elseif state.MyLocked then
		status = TEXT.WaitingLock
	else
		status = TEXT.Editing
	end
	statusLabel.Text = status
end

local function closeTrade()
	gui.Enabled = false
	state = nil
	table.clear(myMaterials)
	table.clear(myDrills)
end

local function panelColumn(parent: Instance, x: number, w: number, title: string): ScrollingFrame
	Create("TextLabel", {
		Position = UDim2.new(x, 0, 0, 70),
		Size = UDim2.new(w, -8, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = parent,
	})
	return Create("ScrollingFrame", {
		Position = UDim2.new(x, 0, 0, 94),
		Size = UDim2.new(w, -8, 0.42, -30),
		BackgroundColor3 = UITheme.Colors.Background,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }) })
end

local function build()
	local playerGui = player:WaitForChild("PlayerGui")
	-- Anfrage
	requestGui = Create("ScreenGui", { Name = "TradeRequest", ResetOnSpawn = false, Enabled = false, DisplayOrder = 40, Parent = playerGui })
	local req = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.fromOffset(360, 96),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = requestGui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Create("UIStroke", { Color = UITheme.Colors.DefaultAccent, Thickness = 2 }),
	})
	requestLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 30),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 17,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextWrapped = true,
		Text = "",
		Parent = req,
	})
	for i, def in { { TEXT.Accept, UITheme.Colors.Positive, true }, { TEXT.Decline, UITheme.Colors.SurfaceRaised, false } } do
		local b: TextButton = Create("TextButton", {
			Position = UDim2.new(if i == 1 then 0 else 0.5, if i == 1 then 14 else 6, 0, 50),
			Size = UDim2.new(0.5, -20, 0, 34),
			BackgroundColor3 = def[2],
			Font = UITheme.FontBold,
			TextSize = 15,
			TextColor3 = if i == 1 then Color3.fromRGB(20, 24, 28) else UITheme.Colors.TextPrimary,
			Text = def[1],
			Parent = req,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		local accept = def[3]
		b.Activated:Connect(function()
			local id = currentRequest
			requestGui.Enabled = false
			currentRequest = nil
			if id then
				call("TradeRespond", id, accept)
			end
		end)
	end

	-- Handelsfenster
	gui = Create("ScreenGui", { Name = "Trade", ResetOnSpawn = false, Enabled = false, DisplayOrder = 38, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.84),
		BackgroundColor3 = UITheme.Colors.Surface,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(760, 620) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	Create("TextLabel", {
		Size = UDim2.new(0.5, 0, 0, 28),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 22,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.Title,
		Parent = panel,
	})
	partnerLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(0.6, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})
	statusLabel = Create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 4),
		Size = UDim2.new(0.5, 0, 0, 40),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = UITheme.Colors.Warning,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	mineList = panelColumn(panel, 0, 0.5, TEXT.YourOffer)
	theirsList = panelColumn(panel, 0.5, 0.5, TEXT.TheirOffer)
	Create("TextLabel", {
		Position = UDim2.new(0, 0, 0.42, 72),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.YourStorage,
		Parent = panel,
	})
	stockList = Create("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0.42, 96),
		Size = UDim2.new(1, 0, 0.58, -160),
		BackgroundColor3 = UITheme.Colors.Background,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }) })
	local buttons = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		Parent = panel,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10) }) })
	local function bigButton(text: string, color: Color3, order: number): TextButton
		return Create("TextButton", {
			Size = UDim2.new(0.31, 0, 1, 0),
			BackgroundColor3 = color,
			Font = UITheme.FontBold,
			TextSize = 15,
			TextColor3 = if color == UITheme.Colors.SurfaceRaised then UITheme.Colors.TextPrimary else Color3.fromRGB(20, 24, 28),
			Text = text,
			LayoutOrder = order,
			Parent = buttons,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	end
	lockButton = bigButton(TEXT.Lock, UITheme.Colors.DefaultAccent, 1)
	confirmButton = bigButton(TEXT.Confirm, UITheme.Colors.Positive, 2)
	local cancelButton = bigButton(TEXT.Cancel, UITheme.Colors.SurfaceRaised, 3)
	lockButton.Activated:Connect(function()
		if state then
			call("TradeLock", not state.MyLocked)
		end
	end)
	confirmButton.Activated:Connect(function()
		if state and os.clock() >= confirmReadyAt then
			call("TradeConfirm")
		end
	end)
	cancelButton.Activated:Connect(function()
		call("TradeCancel")
	end)

	RunService.Heartbeat:Connect(function()
		if requestGui.Enabled and os.clock() > requestExpires then
			requestGui.Enabled = false
			currentRequest = nil
		end
		if gui.Enabled and state then
			local ready = state.MyLocked and state.TheirLocked and not state.MyConfirmed
			local wait = confirmReadyAt - os.clock()
			confirmButton.AutoButtonColor = ready and wait <= 0
			confirmButton.BackgroundColor3 = if ready and wait <= 0 then UITheme.Colors.Positive else UITheme.Colors.SurfaceRaised
			confirmButton.Text = if ready and wait > 0 then string.format(TEXT.ConfirmIn, math.ceil(wait)) elseif state.MyConfirmed then TEXT.Confirmed else TEXT.Confirm
		end
	end)
	StateController.Changed:Connect(function()
		if gui.Enabled then
			stockRows()
		end
	end)
end

-- Eigenen Trade-Prompt lokal ausblenden
local function hideOwnPrompt(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local prompt = root and root:WaitForChild("TradePrompt", 10)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = false
	end
end

function TradeController.Init()
	build()
	Net.on("TradeRequestReceived", function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		currentRequest = payload.RequestId
		requestExpires = os.clock() + (payload.Timeout or 15)
		requestLabel.Text = string.format(TEXT.Request, payload.FromName or "?")
		requestGui.Enabled = true
	end)
	Net.on("TradeUpdate", function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local opening = state == nil
		state = payload
		-- lokale Kopie des eigenen Angebots aus Serverstand übernehmen
		table.clear(myMaterials)
		for id, n in payload.Mine.Materials do
			myMaterials[id] = n
		end
		table.clear(myDrills)
		for _, d in payload.Mine.Drills do
			myDrills[d.Id] = true
		end
		confirmReadyAt = if payload.ConfirmIn then os.clock() + payload.ConfirmIn else math.huge
		gui.Enabled = true
		if opening then
			requestGui.Enabled = false
		end
		render()
	end)
	Net.on("TradeClosed", function(payload: any)
		local completed = typeof(payload) == "table" and payload.Reason == "Completed"
		closeTrade()
		NotificationController.Show(if completed then "Success" else "Info", if completed then "TRADE_DONE" else "TRADE_CANCELLED")
	end)
end

function TradeController.Start()
	player.CharacterAdded:Connect(function(character)
		task.spawn(hideOwnPrompt, character)
	end)
	if player.Character then
		task.spawn(hideOwnPrompt, player.Character)
	end
end

return TradeController
