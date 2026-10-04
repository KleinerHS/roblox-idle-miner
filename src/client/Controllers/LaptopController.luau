--!strict
-- Firmen-Laptop (docs/09 §21–28): kurzer Kamera-Zoom auf den Laptop, dann eine saubere
-- Firmen-Oberfläche mit App-Leiste. Phase 4b: EMPLOYEES (Worker einstellen/entlassen,
-- Status, Lohn). DASHBOARD, STORAGE, ELEVATOR folgen in 4c, PRODUCTION/COMPANY später.
-- Kein Windows-Klon (docs/20). Einstellen/Entlassen prüft der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Mines = require(Shared.Definitions.Mines)
local Ores = require(Shared.Definitions.Ores)
local WorkerRoles = require(Shared.Definitions.WorkerRoles)
local CompanyIdentity = require(Shared.Definitions.CompanyIdentity)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local PlotController = require(script.Parent.PlotController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Laptop

local LaptopController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local content: Frame
local headerName: TextLabel
local navButtons: { [string]: TextButton } = {}
local currentApp = "EMPLOYEES"
local selectedMine = "mine_001"
local statuses: { [string]: string } = {}
local busy = false

local function accent(snapshot: Types.StateSnapshot?): Color3
	local color = snapshot and CompanyIdentity.ColorById[snapshot.Company.ColorId]
	return if color then color.Color else UITheme.Colors.DefaultAccent
end

local function clearContent()
	for _, child in content:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function label(text: string, size: number, color: Color3, order: number, bold: boolean?): TextLabel
	return Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, size + 6),
		BackgroundTransparency = 1,
		Font = if bold then UITheme.FontBold else UITheme.Font,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = text,
		LayoutOrder = order,
		Parent = content,
	})
end

local function call(remote: string, ...: any)
	if busy then
		return
	end
	busy = true
	local result = Net.invoke(remote, ...)
	busy = false
	if not result.success then
		NotificationController.Show("Warning", result.code)
	end
end

local function slotCard(order: number, title: string, worker: Types.WorkerRecord?, roleDef: WorkerRoles.RoleDefinition, slot: number, canHire: boolean, snapshot: Types.StateSnapshot)
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = content,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
	})
	Create("TextLabel", {
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.new(0.6, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = card,
	})
	local sub, subColor
	if worker then
		local status = statuses[worker.Id] or "Working"
		sub = `{roleDef.DisplayName} #{worker.Id:sub(2)} · {TEXT.Status[status] or status} · {string.format(TEXT.Wage, NumberFormat.cash(roleDef.WagePerMinute))}`
		subColor = if status == "Unpaid" then UITheme.Colors.Negative elseif status == "Waiting" then UITheme.Colors.Warning else UITheme.Colors.Positive
	else
		sub = `{TEXT.Empty} · {roleDef.DisplayName} · {string.format(TEXT.Wage, NumberFormat.cash(roleDef.WagePerMinute))}`
		subColor = UITheme.Colors.TextSecondary
	end
	Create("TextLabel", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(0.66, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = subColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = sub,
		Parent = card,
	})
	local text, color, enabled, onClick
	if worker then
		text, color, enabled = TEXT.Fire, UITheme.Colors.SurfaceRaised, true
		local id = worker.Id
		onClick = function()
			call("FireWorker", id)
		end
	else
		local affordable = snapshot.Cash >= roleDef.HireCost
		text = string.format(TEXT.Hire, NumberFormat.cash(roleDef.HireCost))
		color = if canHire and affordable then accent(snapshot) else UITheme.Colors.SurfaceRaised
		enabled = canHire
		local mineId, role = selectedMine, roleDef.Id
		onClick = function()
			call("HireWorker", mineId, role, slot)
		end
	end
	local button: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(130, 38),
		BackgroundColor3 = color,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = if color == UITheme.Colors.SurfaceRaised then UITheme.Colors.TextPrimary else Color3.fromRGB(20, 24, 28),
		AutoButtonColor = enabled,
		Text = text,
		Parent = card,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	if enabled then
		button.Activated:Connect(onClick)
	end
end

local function renderEmployees(snapshot: Types.StateSnapshot)
	label(TEXT.Employees, 24, UITheme.Colors.TextPrimary, 1, true)
	local storageBuilt = snapshot.Buildings.build_storage == true
	if not storageBuilt then
		label(TEXT.NeedStorage, 16, UITheme.Colors.Warning, 2)
	end

	-- Minen-Auswahl (nur freigeschaltete Minen)
	local tabs = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = content,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })
	local any = false
	for _, mine in Mines.List do
		if Mines.IsAccessible(mine, snapshot.MiningLevel) then
			any = true
			local active = mine.Id == selectedMine
			local tab: TextButton = Create("TextButton", {
				Size = UDim2.fromOffset(96, 34),
				BackgroundColor3 = if active then accent(snapshot) else UITheme.Colors.SurfaceRaised,
				Font = UITheme.FontBold,
				TextSize = 14,
				TextColor3 = if active then Color3.fromRGB(20, 24, 28) else UITheme.Colors.TextPrimary,
				Text = Mines.Label(mine),
				LayoutOrder = mine.Number,
				Parent = tabs,
			}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
			local id = mine.Id
			tab.Activated:Connect(function()
				selectedMine = id
				LaptopController.Render()
			end)
		end
	end
	if not any then
		label(TEXT.NoMines, 16, UITheme.Colors.TextSecondary, 4)
		return
	end

	local mine = Mines.Get(selectedMine)
	local ore = mine and Ores.Get(mine.OreId)
	local buffer = snapshot.MineBuffers[selectedMine] or 0
	local elevatorLoad = 0
	for _, amount in snapshot.ElevatorBuffer do
		elevatorLoad += amount
	end
	label(`{if ore then ore.DisplayName else ""} · {string.format(TEXT.Buffer, NumberFormat.withSeparators(buffer))} · {string.format(TEXT.Elevator, NumberFormat.withSeparators(elevatorLoad), NumberFormat.withSeparators(snapshot.ElevatorCapacity))}`, 14, UITheme.Colors.TextSecondary, 4)

	local order = 10
	for _, roleId in WorkerRoles.Order do
		local roleDef = WorkerRoles.Get(roleId) :: WorkerRoles.RoleDefinition
		for slot = 1, roleDef.Slots do
			local worker: Types.WorkerRecord? = nil
			for _, w in snapshot.Workers do
				if w.MineId == selectedMine and w.Role == roleId and w.Slot == slot then
					worker = w
				end
			end
			local title = string.format(if roleId == "Mining" then TEXT.MiningSlot else TEXT.TransportSlot, slot)
			slotCard(order, title, worker, roleDef, slot, storageBuilt, snapshot)
			order += 1
		end
	end
end

function LaptopController.Render()
	if not gui or not gui.Enabled then
		return
	end
	clearContent()
	local snapshot = StateController.Get()
	if not snapshot then
		return
	end
	local logo = CompanyIdentity.LogoById[snapshot.Company.LogoId]
	headerName.Text = `{if logo then logo.Glyph .. "  " else ""}{snapshot.Company.Name}`
	for app, button in navButtons do
		local active = app == currentApp
		button.BackgroundColor3 = if active then accent(snapshot) else UITheme.Colors.Surface
		button.TextColor3 = if active then Color3.fromRGB(20, 24, 28) else UITheme.Colors.TextPrimary
	end
	if currentApp == "EMPLOYEES" then
		renderEmployees(snapshot)
	else
		label(currentApp, 24, UITheme.Colors.TextPrimary, 1, true)
		label(TEXT.ComingSoon, 16, UITheme.Colors.TextSecondary, 2)
	end
end

-- Kurzer Kamera-Zoom auf den Laptop (docs/04 §7, docs/09 §21)
local function zoomTo(open: boolean)
	local camera = workspace.CurrentCamera
	if open then
		local plot = PlotController.GetPlotModel()
		local laptop = plot and plot:FindFirstChild("Laptop", true)
		local screen = laptop and laptop:FindFirstChild("Screen")
		if screen and screen:IsA("BasePart") then
			camera.CameraType = Enum.CameraType.Scriptable
			local target = CFrame.lookAt((screen.CFrame * CFrame.new(0, 0.6, -3.2)).Position, screen.Position)
			TweenService:Create(camera, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target }):Play()
		end
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function close()
	gui.Enabled = false
	zoomTo(false)
end

local function open()
	zoomTo(true)
	task.wait(0.35)
	gui.Enabled = true
	LaptopController.Render()
end

local function build()
	gui = Create("ScreenGui", {
		Name = "Laptop",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 35,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.8),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 16) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised, Thickness = 2 }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(860, 560) }),
	})
	-- Kopfzeile mit Firmenname
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = UITheme.Colors.Surface,
		Parent = panel,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 16) }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 12) }),
	})
	headerName = Create("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 20,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	local closeButton: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = UITheme.Colors.TextPrimary,
		Text = TEXT.Close,
		Parent = header,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	closeButton.Activated:Connect(close)

	-- App-Leiste links
	local nav = Create("Frame", {
		Position = UDim2.fromOffset(14, 66),
		Size = UDim2.new(0, 170, 1, -80),
		BackgroundTransparency = 1,
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
	for i, app in TEXT.Apps do
		local button: TextButton = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = UITheme.Colors.Surface,
			Font = UITheme.FontBold,
			TextSize = 14,
			TextColor3 = UITheme.Colors.TextPrimary,
			Text = app,
			LayoutOrder = i,
			Parent = nav,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		button.Activated:Connect(function()
			currentApp = app
			LaptopController.Render()
		end)
		navButtons[app] = button
	end

	content = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(198, 66),
		Size = UDim2.new(1, -212, 1, -80),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UITheme.Colors.SurfaceRaised,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
		Create("UIPadding", { PaddingRight = UDim.new(0, 8) }),
	})

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and gui.Enabled then
			close()
		end
	end)
	StateController.Changed:Connect(function()
		LaptopController.Render()
	end)
	player.CharacterAdded:Connect(function()
		if gui.Enabled then
			close()
		end
	end)
end

function LaptopController.Init()
	build()
	Net.on("OpenLaptop", function()
		task.spawn(open)
	end)
	Net.on("WorkerStatus", function(payload: any)
		if typeof(payload) == "table" then
			statuses = payload
			LaptopController.Render()
		end
	end)
end

function LaptopController.Start() end

return LaptopController
