--!strict
-- Verkaufsfenster am Tresen (docs/09 §47–49, docs/07 §31): zeigt den Rucksack mit
-- geschätztem Wert und XP, "SELL ALL" verkauft. Die Schätzung ist nur Anzeige; Geld und
-- XP berechnet der Server beim Verkauf.
-- Phase 6c: Dasselbe Fenster verkauft die Ladung eines Fahrzeugs, wenn der Server es mit
-- { VehicleId } öffnet (Einfahren in die Fahrzeug-Verkaufszone, docs/07 §25).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Materials = require(Shared.Definitions.Materials)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local Button = require(script.Parent.Parent.UI.Components.Button)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)
local HudController = require(script.Parent.HudController)

local TEXT = Strings.Sell
local CLOSE_DISTANCE = 16

local SellController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local list: Frame
local emptyLabel: TextLabel
local totalLabel: TextLabel
local sellButton: Button.Button
local openedAt: Vector3? = nil
local selling = false
local titleLabel: TextLabel
-- nil = Rucksack am Tresen, sonst Fahrzeug-ID
local vehicleId: string? = nil

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function close()
	gui.Enabled = false
	openedAt = nil
end

local function row(order: number, color: Color3, name: string, amount: string, value: string, dim: boolean)
	local frame = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = list,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = color,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
	})
	local function label(text: string, x: number, w: number, align: Enum.TextXAlignment, bold: boolean)
		Create("TextLabel", {
			Position = UDim2.new(x, 0, 0, 0),
			Size = UDim2.new(w, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = if bold then UITheme.FontBold else UITheme.Font,
			TextSize = 17,
			TextColor3 = if dim then UITheme.Colors.TextSecondary else UITheme.Colors.TextPrimary,
			TextXAlignment = align,
			Text = text,
			Parent = frame,
		})
	end
	label(name, 0.1, 0.4, Enum.TextXAlignment.Left, true)
	label(amount, 0.48, 0.2, Enum.TextXAlignment.Right, false)
	label(value, 0.68, 0.29, Enum.TextXAlignment.Right, true)
end

local function refresh()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local snapshot = StateController.Get()
	local cash, xp, count = 0, 0, 0
	if snapshot then
		local entries = {}
		local source = snapshot.Backpack
		if vehicleId then
			local vehicle = snapshot.Vehicles[vehicleId]
			source = if vehicle then vehicle.Cargo else {}
		end
		for oreId, amount in source do
			local ore = Materials.Get(oreId)
			if ore and amount > 0 then
				table.insert(entries, { ore = ore, amount = amount })
			end
		end
		table.sort(entries, function(a, b)
			return a.ore.Tier < b.ore.Tier
		end)
		for i, entry in entries do
			local ore = entry.ore
			if ore.SellValue and ore.XPValue then
				local value = entry.amount * ore.SellValue
				cash += value
				xp += entry.amount * ore.XPValue
				count += entry.amount
				row(i, ore.Color, ore.DisplayName, `× {NumberFormat.withSeparators(entry.amount)}`, NumberFormat.cash(value), false)
			else
				row(i, ore.Color, ore.DisplayName, `× {NumberFormat.withSeparators(entry.amount)}`, TEXT.NotSellable, true)
			end
		end
	end
	emptyLabel.Visible = count == 0
	totalLabel.Text = `{TEXT.Total}  {NumberFormat.cash(cash)}   ·   +{NumberFormat.withSeparators(xp)} Mining XP`
	sellButton:SetEnabled(count > 0 and not selling)
end

local function open(payload: any)
	vehicleId = if typeof(payload) == "table" and typeof(payload.VehicleId) == "string" then payload.VehicleId else nil
	titleLabel.Text = if vehicleId then TEXT.VehicleTitle else TEXT.Title
	emptyLabel.Text = if vehicleId then TEXT.VehicleEmpty else TEXT.Empty
	refresh()
	openedAt = rootPosition()
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "SellMenu",
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
		Create("UISizeConstraint", { MaxSize = Vector2.new(460, math.huge) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
	})
	local header = Create("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 1, Parent = panel })
	titleLabel = Create("TextLabel", {
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
		Text = TEXT.Close,
		Parent = header,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	closeButton.Activated:Connect(close)

	list = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
	emptyLabel = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 17,
		TextColor3 = UITheme.Colors.TextSecondary,
		Text = TEXT.Empty,
		TextWrapped = true,
		LayoutOrder = 3,
		Parent = panel,
	})
	totalLabel = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = UITheme.Colors.Positive,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 4,
		Parent = panel,
	})
	sellButton = Button.new({ Text = TEXT.SellAll, Size = UDim2.new(1, 0, 0, 52), Parent = panel })
	sellButton.Instance.LayoutOrder = 5
	sellButton:SetAccent(UITheme.Colors.Positive)
	sellButton:OnClick(function()
		if selling then
			return
		end
		selling = true
		sellButton:SetEnabled(false)
		sellButton:SetText(TEXT.Pending)
		local result = if vehicleId then Net.invoke("SellAll", vehicleId) else Net.invoke("SellAll")
		selling = false
		sellButton:SetText(TEXT.SellAll)
		if result.success then
			close()
			HudController.ShowSold(result.value.Cash, result.value.XP)
		else
			NotificationController.Show("Warning", result.code)
			refresh()
		end
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
		if gui.Enabled and not selling then
			refresh()
		end
	end)
end

function SellController.Init()
	build()
	Net.on("OpenSellMenu", open)
end

function SellController.Start() end

return SellController
