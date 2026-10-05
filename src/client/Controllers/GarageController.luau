--!strict
-- Fahrzeugauswahl am Leuchtring der Garage (docs/07 §4, D-016): zeigt alle eigenen Fahrzeuge
-- mit Kapazität, Ladung und Stellplatz. DRIVE parkt aus bzw. setzt ans Steuer, PARK AWAY
-- parkt ein (Stellplatz frei, Ladung bleibt), RESET stellt ein Fahrzeug zurück auf den
-- Stellplatz. Alles prüft der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Vehicles = require(Shared.Definitions.Vehicles)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Garage
local CLOSE_DISTANCE = 14

local GarageController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local bayLabel: TextLabel
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

local function call(remote: string, id: string): boolean
	if busy then
		return false
	end
	busy = true
	local result = Net.invoke(remote, id)
	busy = false
	if not result.success then
		NotificationController.Show("Warning", result.code)
	end
	return result.success
end

local function cargoTotal(cargo: Types.ItemCounts): number
	local total = 0
	for _, amount in cargo do
		total += amount
	end
	return total
end

local function button(parent: Instance, text: string, color: Color3, order: number, onClick: () -> ())
	local b: TextButton = Create("TextButton", {
		Size = UDim2.fromOffset(104, 34),
		BackgroundColor3 = color,
		Font = UITheme.FontBold,
		TextSize = 14,
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
	local owned: { Types.VehicleRecord } = {}
	local used = 0
	for _, v in snapshot.Vehicles do
		table.insert(owned, v)
		if v.Bay then
			used += 1
		end
	end
	bayLabel.Text = string.format(TEXT.Bays, used, Vehicles.BayCount)
	table.sort(owned, function(a, b)
		local da, db = Vehicles.Get(a.Type), Vehicles.Get(b.Type)
		return (if da then da.Tier else 0) < (if db then db.Tier else 0)
	end)
	if #owned == 0 then
		Create("TextLabel", {
			Size = UDim2.new(1, -8, 0, 40),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 15,
			TextWrapped = true,
			TextColor3 = UITheme.Colors.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = TEXT.NoVehicles,
			Parent = list,
		})
		return
	end
	for i, v in owned do
		local def = Vehicles.Get(v.Type)
		local frame = Create("Frame", {
			Size = UDim2.new(1, -8, 0, 96),
			BackgroundColor3 = UITheme.Colors.Surface,
			LayoutOrder = i,
			Parent = list,
		}, {
			Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
			Create("UIStroke", { Color = if v.Bay then UITheme.Colors.Positive else UITheme.Colors.SurfaceRaised }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
		})
		Create("TextLabel", {
			Size = UDim2.new(0.55, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = UITheme.FontBold,
			TextSize = 19,
			TextColor3 = UITheme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = if def then def.DisplayName else v.Type,
			Parent = frame,
		})
		local capacity = if def then def.Capacity else 0
		Create("TextLabel", {
			Position = UDim2.fromOffset(0, 28),
			Size = UDim2.new(0.55, 0, 0, 40),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 14,
			TextColor3 = UITheme.Colors.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = `{string.format(TEXT.Cargo, NumberFormat.withSeparators(cargoTotal(v.Cargo)), NumberFormat.withSeparators(capacity))}\n{if v.Bay then string.format(TEXT.InBay, v.Bay) else TEXT.Stored}`,
			Parent = frame,
		})
		local actions = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0.44, 0, 1, 0),
			BackgroundTransparency = 1,
			Parent = frame,
		}, {
			Create("UIGridLayout", {
				CellSize = UDim2.fromOffset(104, 34),
				CellPadding = UDim2.fromOffset(6, 6),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		local id = v.Id
		button(actions, TEXT.Drive, UITheme.Colors.Positive, 1, function()
			if call("DriveVehicle", id) then
				close()
			end
		end)
		if v.Bay then
			button(actions, TEXT.Store, UITheme.Colors.SurfaceRaised, 2, function()
				call("StoreVehicle", id)
			end)
			button(actions, TEXT.Reset, UITheme.Colors.SurfaceRaised, 3, function()
				call("ResetVehicle", id)
			end)
		end
	end
end

local function open()
	render()
	openedAt = rootPosition()
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "Garage",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.7, 0),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(560, 520) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	Create("TextLabel", {
		Size = UDim2.new(1, -48, 0, 30),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 24,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.Title,
		Parent = panel,
	})
	bayLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, -48, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
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
	list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 1, -62),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UITheme.Colors.SurfaceRaised,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }) })

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

function GarageController.Init()
	build()
	Net.on("OpenGarage", open)
end

function GarageController.Start() end

return GarageController
