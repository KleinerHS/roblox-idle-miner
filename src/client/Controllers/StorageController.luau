--!strict
-- Lagerfenster am Terminal (docs/06 §16–17, D-004): Füllstand, Bestand je Material,
-- "DEPOSIT BACKPACK" lädt den Rucksack ab, "TAKE" nimmt so viel wie in den Rucksack passt.
-- Mengen bestimmt der Server; das Fenster zeigt nur den bestätigten Zustand.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Materials = require(Shared.Definitions.Materials)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local Button = require(script.Parent.Parent.UI.Components.Button)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Storage
local CLOSE_DISTANCE = 18

local StorageController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local capacityLabel: TextLabel
local capacityFill: Frame
local list: Frame
local emptyLabel: TextLabel
local depositButton: Button.Button
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

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

local function call(remote: string, ...: any)
	if busy then
		return
	end
	busy = true
	local result = Net.invoke(remote, ...)
	busy = false
	if result.success then
		NotificationController.Show("Success", "STORAGE_MOVED", { Amount = result.value.Moved })
	else
		NotificationController.Show("Warning", result.code)
	end
end

local function render()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local snapshot = StateController.Get()
	if not snapshot then
		return
	end
	local used = sum(snapshot.StorageItems)
	local capacity = math.max(snapshot.StorageCapacity, 1)
	capacityLabel.Text = `{NumberFormat.withSeparators(used)} / {NumberFormat.withSeparators(snapshot.StorageCapacity)}`
	capacityFill.Size = UDim2.fromScale(math.clamp(used / capacity, 0, 1), 1)
	capacityFill.BackgroundColor3 = if used >= capacity then UITheme.Colors.Negative else UITheme.Colors.DefaultAccent

	local entries = {}
	for oreId, amount in snapshot.StorageItems do
		local ore = Materials.Get(oreId)
		if ore and amount > 0 then
			table.insert(entries, { ore = ore, amount = amount })
		end
	end
	table.sort(entries, function(a, b)
		return a.ore.Tier < b.ore.Tier
	end)
	emptyLabel.Visible = #entries == 0

	for i, entry in entries do
		local frame = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = UITheme.Colors.Surface,
			LayoutOrder = i,
			Parent = list,
		}, {
			Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
			Create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 12, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = entry.ore.Color,
			}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
			Create("TextLabel", {
				Position = UDim2.fromOffset(36, 0),
				Size = UDim2.new(0.4, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = UITheme.FontBold,
				TextSize = 17,
				TextColor3 = UITheme.Colors.TextPrimary,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = entry.ore.DisplayName,
			}),
			Create("TextLabel", {
				Position = UDim2.fromScale(0.42, 0),
				Size = UDim2.new(0.25, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = UITheme.Font,
				TextSize = 17,
				TextColor3 = UITheme.Colors.TextSecondary,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = NumberFormat.withSeparators(entry.amount),
			}),
		})
		local take: TextButton = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(110, 32),
			BackgroundColor3 = UITheme.Colors.SurfaceRaised,
			Font = UITheme.FontBold,
			TextSize = 14,
			TextColor3 = UITheme.Colors.TextPrimary,
			Text = TEXT.Take,
			Parent = frame,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		local id, amount = entry.ore.Id, entry.amount
		take.Activated:Connect(function()
			call("StorageWithdraw", id, amount)
		end)
	end

	local carried = sum(snapshot.Backpack)
	depositButton:SetText(string.format(TEXT.Deposit, NumberFormat.withSeparators(carried)))
	depositButton:SetEnabled(carried > 0)
end

local function open()
	render()
	openedAt = rootPosition()
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "StorageMenu",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(480, math.huge) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
	})
	local header = Create("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 1, Parent = panel })
	Create("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 26,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.Title,
		Parent = header,
	})
	local closeButton: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = UITheme.Colors.TextPrimary,
		Text = "X",
		Parent = header,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	closeButton.Activated:Connect(close)

	local capRow = Create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = 2, Parent = panel })
	capacityLabel = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 20,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = capRow,
	})
	local bar = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Parent = capRow,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	capacityFill = Create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UITheme.Colors.DefaultAccent, Parent = bar }, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	list = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
	emptyLabel = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 16,
		TextColor3 = UITheme.Colors.TextSecondary,
		Text = TEXT.Empty,
		LayoutOrder = 4,
		Parent = panel,
	})
	depositButton = Button.new({ Text = "", Size = UDim2.new(1, 0, 0, 50), Parent = panel })
	depositButton.Instance.LayoutOrder = 5
	depositButton:OnClick(function()
		call("StorageDeposit")
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

function StorageController.Init()
	build()
	Net.on("OpenStorage", open)
end

function StorageController.Start() end

return StorageController
