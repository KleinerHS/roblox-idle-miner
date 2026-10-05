--!strict
-- Ladefenster am Verladeturm (docs/07 §9–10): Kapazität des Fahrzeugs, je Material der
-- Lagerbestand und die Menge im Fahrzeug, dazu LOAD 100 / LOAD ALL je Material sowie
-- LOAD EVERYTHING und UNLOAD ALL. Mengen und Grenzen prüft der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Materials = require(Shared.Definitions.Materials)
local Vehicles = require(Shared.Definitions.Vehicles)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Loading
local CLOSE_DISTANCE = 20

local LoadingController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local nameLabel: TextLabel
local capacityLabel: TextLabel
local capacityFill: Frame
local list: ScrollingFrame
local openedAt: Vector3? = nil
local vehicleId: string? = nil
local busy = false

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function close()
	gui.Enabled = false
	openedAt = nil
	vehicleId = nil
end

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

local function call(remote: string, ...: any)
	if busy or not vehicleId then
		return
	end
	busy = true
	local result = Net.invoke(remote, vehicleId, ...)
	busy = false
	if result.success then
		NotificationController.Show("Success", if remote == "LoadVehicle" then "CARGO_LOADED" else "CARGO_UNLOADED", { Amount = NumberFormat.withSeparators(result.value.Moved) })
	else
		NotificationController.Show("Warning", result.code)
	end
end

local function smallButton(parent: Instance, text: string, color: Color3, order: number, onClick: () -> ())
	local b: TextButton = Create("TextButton", {
		Size = UDim2.fromOffset(92, 30),
		BackgroundColor3 = color,
		Font = UITheme.FontBold,
		TextSize = 13,
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
	local vehicle = snapshot and vehicleId and snapshot.Vehicles[vehicleId]
	if not snapshot or not vehicle then
		return
	end
	local def = Vehicles.Get(vehicle.Type)
	local capacity = if def then def.Capacity else 0
	local used = sum(vehicle.Cargo)
	nameLabel.Text = `{TEXT.Title} · {if def then def.DisplayName else vehicle.Type}`
	capacityLabel.Text = string.format(TEXT.Capacity, NumberFormat.withSeparators(used), NumberFormat.withSeparators(capacity))
	local fraction = math.clamp(used / math.max(1, capacity), 0, 1)
	capacityFill.Size = UDim2.fromScale(fraction, 1)
	capacityFill.BackgroundColor3 = if fraction >= 1 then UITheme.Colors.Negative else UITheme.Colors.DefaultAccent

	-- Alle Materialien aus Lager und Fahrzeug
	local ids: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, items in { snapshot.StorageItems, vehicle.Cargo } do
		for id, amount in items do
			if amount > 0 and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
	end
	table.sort(ids, function(a, b)
		local oa, ob = Materials.Get(a), Materials.Get(b)
		return (if oa then oa.Tier else 999) < (if ob then ob.Tier else 999)
	end)
	if #ids == 0 then
		Create("TextLabel", {
			Size = UDim2.new(1, -8, 0, 30),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 15,
			TextColor3 = UITheme.Colors.TextSecondary,
			Text = TEXT.Empty,
			Parent = list,
		})
	end
	for i, id in ids do
		local ore = Materials.Get(id)
		local frame = Create("Frame", {
			Size = UDim2.new(1, -8, 0, 56),
			BackgroundColor3 = UITheme.Colors.Surface,
			LayoutOrder = i,
			Parent = list,
		}, {
			Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }),
			Create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(12, 12),
				BackgroundColor3 = if ore then ore.Color else UITheme.Colors.TextSecondary,
			}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
		})
		Create("TextLabel", {
			Position = UDim2.fromOffset(20, 8),
			Size = UDim2.new(0.5, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = UITheme.FontBold,
			TextSize = 16,
			TextColor3 = UITheme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = if ore then ore.DisplayName else id,
			Parent = frame,
		})
		Create("TextLabel", {
			Position = UDim2.fromOffset(20, 30),
			Size = UDim2.new(0.55, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 13,
			TextColor3 = UITheme.Colors.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.format(TEXT.Row, NumberFormat.withSeparators(snapshot.StorageItems[id] or 0), NumberFormat.withSeparators(vehicle.Cargo[id] or 0)),
			Parent = frame,
		})
		local actions = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0.42, 0, 0, 30),
			BackgroundTransparency = 1,
			Parent = frame,
		}, {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			}),
		})
		local oreId = id
		smallButton(actions, TEXT.Load100, UITheme.Colors.SurfaceRaised, 1, function()
			call("LoadVehicle", oreId, 100)
		end)
		smallButton(actions, TEXT.LoadAll, UITheme.Colors.Positive, 2, function()
			call("LoadVehicle", oreId)
		end)
	end
end

local function open(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.VehicleId) ~= "string" then
		return
	end
	vehicleId = payload.VehicleId
	render()
	openedAt = rootPosition()
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "Loading",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.72, 0),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(540, 540) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	nameLabel = Create("TextLabel", {
		Size = UDim2.new(1, -48, 0, 28),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 22,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
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
	capacityLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 16,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})
	local bar = Create("Frame", {
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Parent = panel,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	capacityFill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = UITheme.Colors.DefaultAccent,
		Parent = bar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 1, -130),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UITheme.Colors.SurfaceRaised,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
	local footer = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = panel,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),
	})
	for order, def in { { TEXT.LoadEverything, UITheme.Colors.Positive, "LoadVehicle" }, { TEXT.UnloadAll, UITheme.Colors.SurfaceRaised, "UnloadVehicle" } } do
		local b: TextButton = Create("TextButton", {
			Size = UDim2.new(0.48, 0, 1, 0),
			BackgroundColor3 = def[2],
			Font = UITheme.FontBold,
			TextSize = 15,
			TextColor3 = if def[2] == UITheme.Colors.SurfaceRaised then UITheme.Colors.TextPrimary else Color3.fromRGB(20, 24, 28),
			Text = def[1],
			LayoutOrder = order,
			Parent = footer,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		local remote = def[3]
		b.Activated:Connect(function()
			call(remote)
		end)
	end

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

function LoadingController.Init()
	build()
	Net.on("OpenLoading", open)
end

function LoadingController.Start() end

return LoadingController
