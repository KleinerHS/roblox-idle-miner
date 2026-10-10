--!strict
-- Fenster „WHILE YOU WERE AWAY“ nach dem Login (docs/14 §15, Phase 10). Zeigt nur die
-- Werte, die der Server per OfflineSummary bestätigt hat; das Material liegt bereits im
-- Lager bzw. in den Puffern. Reine Anzeige, keine Logik.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local GameConfig = require(Shared.Config.GameConfig)
local Materials = require(Shared.Definitions.Materials)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local Button = require(script.Parent.Parent.UI.Components.Button)

local TEXT = Strings.Offline

local OfflineController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local titleLabel: TextLabel
local list: Frame
local notes: TextLabel
local storageLabel: TextLabel
local storageFill: Frame

local function close()
	gui.Enabled = false
end

local function clearList()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function row(order: number, color: Color3, text: string, value: string)
	local frame = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = list,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = color,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
	})
	Create("TextLabel", {
		Position = UDim2.new(0, 34, 0, 0),
		Size = UDim2.new(0.62, -34, 1, 0),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 17,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		Parent = frame,
	})
	Create("TextLabel", {
		Position = UDim2.new(0.62, 0, 0, 0),
		Size = UDim2.new(0.38, -12, 1, 0),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 17,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = value,
		Parent = frame,
	})
end

-- Material-Zeilen in fester Reihenfolge (Stufe, dann ID)
local function materialRows(start: number, counts: { [string]: number }, label: string): number
	local entries = {}
	for id, n in counts do
		local mat = Materials.Get(id)
		if mat and n > 0 then
			table.insert(entries, { mat = mat, n = n })
		end
	end
	table.sort(entries, function(a, b)
		if a.mat.Tier ~= b.mat.Tier then
			return a.mat.Tier < b.mat.Tier
		end
		return a.mat.Id < b.mat.Id
	end)
	local order = start
	for _, entry in entries do
		row(order, entry.mat.Color, string.format(label, entry.mat.DisplayName), NumberFormat.withSeparators(entry.n))
		order += 1
	end
	return order
end

local function show(summary: any)
	if typeof(summary) ~= "table" or typeof(summary.Seconds) ~= "number" then
		return
	end
	local minutes = math.max(1, math.floor(summary.Seconds / 60 + 0.5))
	titleLabel.Text = string.format(TEXT.Title, minutes)
	clearList()
	local order = materialRows(1, summary.Mined or {}, TEXT.Mined)
	order = materialRows(order, summary.Smelted or {}, TEXT.Smelted)
	if (summary.WagesPaid or 0) > 0 then
		row(order, UITheme.Colors.Warning, TEXT.Wages, "−" .. NumberFormat.cash(summary.WagesPaid))
		order += 1
	end
	if order == 1 then
		row(order, UITheme.Colors.TextSecondary, TEXT.NothingProduced, "")
	end

	local lines = {}
	if summary.StorageFullAfter and summary.StorageFullAfter < summary.Seconds then
		table.insert(lines, string.format(TEXT.StorageFullAfter, math.max(1, math.floor(summary.StorageFullAfter / 60 + 0.5))))
	end
	if (summary.UnpaidMinutes or 0) > 0 then
		table.insert(lines, TEXT.Unpaid)
	end
	if summary.Seconds >= GameConfig.Offline.MaxSeconds then
		table.insert(lines, TEXT.Capped)
	end
	notes.Text = table.concat(lines, "\n")
	notes.Visible = #lines > 0

	local capacity = math.max(1, summary.StorageCapacity or 1)
	local fraction = math.clamp((summary.StorageUsed or 0) / capacity, 0, 1)
	storageLabel.Text = string.format(TEXT.Storage, math.floor(fraction * 100 + 0.5), NumberFormat.withSeparators(summary.StorageUsed or 0), NumberFormat.withSeparators(capacity))
	storageFill.Size = UDim2.fromScale(fraction, 1)
	storageFill.BackgroundColor3 = if fraction >= 1 then UITheme.Colors.Warning else UITheme.Colors.Positive
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "OfflineSummary",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 40,
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
		Create("UISizeConstraint", { MaxSize = Vector2.new(440, math.huge) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
	})
	titleLabel = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 24,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = panel,
	})
	Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 15,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.Subtitle,
		LayoutOrder = 2,
		Parent = panel,
	})
	list = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
	storageLabel = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 16,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 4,
		Parent = panel,
	})
	local bar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = 5,
		Parent = panel,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	storageFill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = UITheme.Colors.Positive,
		Parent = bar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	notes = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 15,
		TextColor3 = UITheme.Colors.Warning,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Visible = false,
		LayoutOrder = 6,
		Parent = panel,
	})
	local okButton = Button.new({ Text = TEXT.Continue, Size = UDim2.new(1, 0, 0, 48), Parent = panel })
	okButton.Instance.LayoutOrder = 7
	okButton:OnClick(close)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and gui.Enabled then
			close()
		end
	end)
end

function OfflineController.Init()
	build()
	Net.on("OfflineSummary", show)
end

function OfflineController.Start() end

return OfflineController
