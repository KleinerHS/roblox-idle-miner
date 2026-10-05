--!strict
-- Schmelzer-Fenster am Terminal (docs/06 §29–35, D-011): Status, aktuelles Rezept, Füllstand
-- von Trichter und Barrenablage; je schmelzbarem Erz im Lager FEED / FEED ALL und PREFER
-- (Priorität), dazu AUTO und COLLECT BARS. Mengen und Grenzen prüft der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Materials = require(Shared.Definitions.Materials)
local SmelterLogic = require(Shared.Util.SmelterLogic)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Smelter
local CLOSE_DISTANCE = 16
local FEED_STEP = 50

local SmelterController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local statusLabel: TextLabel
local recipeLabel: TextLabel
local inputLabel: TextLabel
local outputLabel: TextLabel
local list: ScrollingFrame
local openedAt: Vector3? = nil
local busy = false

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function close()
	gui.Enabled = false
	openedAt = nil
end

local function call(remote: string, successCode: string?, ...: any)
	if busy then
		return
	end
	busy = true
	local result = Net.invoke(remote, ...)
	busy = false
	if result.success then
		if successCode and typeof(result.value) == "table" then
			NotificationController.Show("Success", successCode, { Amount = NumberFormat.withSeparators(result.value.Moved) })
		end
	else
		NotificationController.Show("Warning", result.code)
	end
end

local function smallButton(parent: Instance, text: string, color: Color3, order: number, width: number, onClick: () -> ())
	local b: TextButton = Create("TextButton", {
		Size = UDim2.fromOffset(width, 30),
		BackgroundColor3 = color,
		Font = UITheme.FontBold,
		TextSize = 12,
		TextColor3 = if color == UITheme.Colors.SurfaceRaised then UITheme.Colors.TextPrimary else Color3.fromRGB(20, 24, 28),
		Text = text,
		LayoutOrder = order,
		Parent = parent,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	b.Activated:Connect(onClick)
end

local function render()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local snapshot = StateController.Get()
	if not snapshot then
		return
	end
	local state = snapshot.Smelter
	local cfg = BalanceConfig.Smelter
	local status = SmelterLogic.Status(state)
	statusLabel.Text = TEXT.Status[status] or status
	statusLabel.TextColor3 = if status == "Running" then UITheme.Colors.Positive elseif status == "OutputFull" then UITheme.Colors.Negative else UITheme.Colors.Warning
	local recipe = SmelterLogic.PickRecipe(state)
	local ore = recipe and Materials.Get(recipe.OreId)
	local bar = recipe and Materials.Get(recipe.BarId)
	recipeLabel.Text = if ore and bar then string.format(TEXT.Recipe, ore.DisplayName, bar.DisplayName) else ""
	inputLabel.Text = string.format(TEXT.Input, NumberFormat.withSeparators(SmelterLogic.Sum(state.Input)), NumberFormat.withSeparators(cfg.InputCapacity))
	outputLabel.Text = string.format(TEXT.Output, NumberFormat.withSeparators(SmelterLogic.Sum(state.Output)), NumberFormat.withSeparators(cfg.OutputCapacity))

	-- Priorität: AUTO
	local autoRow = Create("Frame", { Size = UDim2.new(1, -8, 0, 34), BackgroundTransparency = 1, LayoutOrder = 0, Parent = list }, {
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	Create("TextLabel", {
		Size = UDim2.fromOffset(70, 30),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.Priority,
		LayoutOrder = 1,
		Parent = autoRow,
	})
	smallButton(autoRow, TEXT.Auto, if state.Priority == "" then UITheme.Colors.Positive else UITheme.Colors.SurfaceRaised, 2, 180, function()
		call("SmelterPriority", nil, "")
	end)

	-- Schmelzbare Erze aus Lager und Trichter
	local ids: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, items in { snapshot.StorageItems, state.Input } do
		for id, amount in items do
			if amount > 0 and not seen[id] and SmelterLogic.IsSmeltable(id) then
				seen[id] = true
				table.insert(ids, id)
			end
		end
	end
	Materials.SortIds(ids)
	if #ids == 0 then
		Create("TextLabel", {
			Size = UDim2.new(1, -8, 0, 40),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 14,
			TextWrapped = true,
			TextColor3 = UITheme.Colors.TextSecondary,
			Text = TEXT.NoOre,
			LayoutOrder = 1,
			Parent = list,
		})
	end
	for i, id in ids do
		local material = Materials.Get(id)
		local frame = Create("Frame", {
			Size = UDim2.new(1, -8, 0, 56),
			BackgroundColor3 = UITheme.Colors.Surface,
			LayoutOrder = i,
			Parent = list,
		}, {
			Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }),
		})
		Create("TextLabel", {
			Position = UDim2.fromOffset(0, 8),
			Size = UDim2.new(0.42, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = UITheme.FontBold,
			TextSize = 16,
			TextColor3 = UITheme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = if material then material.DisplayName else id,
			Parent = frame,
		})
		Create("TextLabel", {
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(0.42, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 13,
			TextColor3 = UITheme.Colors.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.format(TEXT.StorageAmount, NumberFormat.withSeparators(snapshot.StorageItems[id] or 0)),
			Parent = frame,
		})
		local actions = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0.58, 0, 0, 30),
			BackgroundTransparency = 1,
			Parent = frame,
		}, {
			Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
		})
		local oreId = id
		smallButton(actions, `{TEXT.Feed} {FEED_STEP}`, UITheme.Colors.SurfaceRaised, 1, 72, function()
			call("SmelterFeed", "SMELTER_FED", oreId, FEED_STEP)
		end)
		smallButton(actions, TEXT.FeedAll, UITheme.Colors.Positive, 2, 72, function()
			call("SmelterFeed", "SMELTER_FED", oreId)
		end)
		local preferred = state.Priority == oreId
		smallButton(actions, if preferred then TEXT.Preferred else TEXT.Prefer, if preferred then UITheme.Colors.DefaultAccent else UITheme.Colors.SurfaceRaised, 3, 80, function()
			call("SmelterPriority", nil, oreId)
		end)
	end
end

local function open()
	render()
	openedAt = rootPosition()
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "Smelter",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.76, 0),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(560, 580) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	Create("TextLabel", {
		Size = UDim2.new(0.5, 0, 0, 30),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 24,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.Title,
		Parent = panel,
	})
	statusLabel = Create("TextLabel", {
		Position = UDim2.new(0.4, 0, 0, 6),
		Size = UDim2.new(0.6, -44, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		Parent = panel,
	})
	local closeButton: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = UITheme.Colors.TextPrimary,
		Text = TEXT.Close,
		Parent = panel,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	closeButton.Activated:Connect(close)
	recipeLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		Parent = panel,
	})
	inputLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(0.5, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})
	outputLabel = Create("TextLabel", {
		Position = UDim2.new(0.5, 0, 0, 60),
		Size = UDim2.new(0.5, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 90),
		Size = UDim2.new(1, 0, 1, -140),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UITheme.Colors.SurfaceRaised,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
	local collect: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = UITheme.Colors.Positive,
		Font = UITheme.FontBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(20, 24, 28),
		Text = TEXT.Collect,
		Parent = panel,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	collect.Activated:Connect(function()
		call("SmelterCollect", "SMELTER_COLLECTED")
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and gui.Enabled then
			close()
		end
	end)
	RunService.Heartbeat:Connect(function()
		if gui.Enabled and openedAt then
			local pos = rootPosition()
			if not pos or (pos - openedAt).Magnitude > CLOSE_DISTANCE then
				close()
			end
		end
	end)
	StateController.Changed:Connect(function()
		if gui.Enabled then
			render()
		end
	end)
end

function SmelterController.Init()
	build()
	Net.on("OpenSmelter", open)
end

function SmelterController.Start() end

return SmelterController
