--!strict
-- Slot-Fenster in der Mine (docs/05 §25, docs/10 §31–32): öffnet sich über den Prompt
-- "Manage Slot" an einem Mining-Slot. Zeigt je nach Belegung:
--   Worker → Hinweis (erst im Laptop entlassen)
--   Drill  → Typ, Status, Leistung, REMOVE (zurück ins Inventar)
--   leer   → verfügbare Drills aus dem Inventar mit PLACE
-- Platzieren/Entfernen entscheidet der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Mines = require(Shared.Definitions.Mines)
local Drills = require(Shared.Definitions.Drills)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.DrillSlot
local CLOSE_DISTANCE = 16

local DrillSlotController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local title: TextLabel
local list: ScrollingFrame
local openedAt: Vector3? = nil
local current: { MineId: string, Slot: number }? = nil
local busy = false

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function close()
	gui.Enabled = false
	openedAt = nil
	current = nil
end

local function call(remote: string, args: { [string]: any }?, ...: any)
	if busy then
		return
	end
	busy = true
	local result = Net.invoke(remote, ...)
	busy = false
	if not result.success then
		NotificationController.Show("Warning", result.code, args)
	end
end

local function textLabel(parent: Instance, text: string, y: number, size: number, color: Color3, bold: boolean?): TextLabel
	return Create("TextLabel", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(0.62, 0, 0, size + 4),
		BackgroundTransparency = 1,
		Font = if bold then UITheme.FontBold else UITheme.Font,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Parent = parent,
	})
end

local function card(order: number, height: number): Frame
	return Create("Frame", {
		Size = UDim2.new(1, -8, 0, height),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = list,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
	})
end

local function actionButton(parent: Instance, text: string, color: Color3, onClick: () -> ())
	local button: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(0.34, 0, 0, 40),
		BackgroundColor3 = color,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = if color == UITheme.Colors.SurfaceRaised then UITheme.Colors.TextPrimary else Color3.fromRGB(20, 24, 28),
		Text = text,
		Parent = parent,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	button.Activated:Connect(onClick)
end

local function statusText(status: string?): (string, Color3)
	if status == "Running" then
		return TEXT.Status.Running, UITheme.Colors.Positive
	elseif status == "OutputFull" then
		return TEXT.Status.OutputFull, UITheme.Colors.Warning
	end
	return TEXT.Status.Idle, UITheme.Colors.Warning
end

local function render()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local snapshot = StateController.Get()
	local slotInfo = current
	if not snapshot or not slotInfo then
		return
	end
	local mine = Mines.Get(slotInfo.MineId)
	title.Text = string.format(TEXT.Title, if mine then Mines.Label(mine) else "", slotInfo.Slot)

	-- Belegung des Slots
	local worker: Types.WorkerRecord? = nil
	for _, w in snapshot.Workers do
		if w.MineId == slotInfo.MineId and w.Role == "Mining" and w.Slot == slotInfo.Slot then
			worker = w
		end
	end
	local placed: Types.DrillRecord? = nil
	for _, d in snapshot.Drills do
		if d.MineId == slotInfo.MineId and d.Slot == slotInfo.Slot then
			placed = d
		end
	end

	if worker then
		local box = card(1, 70)
		textLabel(box, TEXT.WorkerHere, 0, 17, UITheme.Colors.TextPrimary, true)
		local hint = textLabel(box, TEXT.WorkerHint, 26, 14, UITheme.Colors.TextSecondary)
		hint.Size = UDim2.new(1, 0, 0, 30)
		hint.TextWrapped = true
		return
	end

	if placed then
		local def = Drills.Get(placed.Type)
		local box = card(1, 92)
		textLabel(box, if def then def.DisplayName else placed.Type, 0, 20, UITheme.Colors.TextPrimary, true)
		local text, color = statusText(StateController.GetStatus(placed.Id))
		textLabel(box, text, 28, 15, color, true)
		if def then
			textLabel(box, string.format(TEXT.PerMinute, NumberFormat.withSeparators(Drills.OrePerMinute(def))), 50, 14, UITheme.Colors.TextSecondary)
		end
		local id = placed.Id
		actionButton(box, TEXT.Remove, UITheme.Colors.SurfaceRaised, function()
			call("RemoveDrill", nil, id)
		end)
		return
	end

	-- Leerer Slot: verfügbare Drills je Typ
	local any = false
	for i, def in Drills.List do
		local available = 0
		for _, d in snapshot.Drills do
			if d.Type == def.Id and d.MineId == nil then
				available += 1
			end
		end
		if available > 0 then
			any = true
			local box = card(i, 92)
			textLabel(box, def.DisplayName, 0, 20, UITheme.Colors.TextPrimary, true)
			textLabel(box, string.format(TEXT.PerMinute, NumberFormat.withSeparators(Drills.OrePerMinute(def))), 28, 14, UITheme.Colors.TextSecondary)
			textLabel(box, string.format(TEXT.Available, available), 48, 14, UITheme.Colors.TextSecondary)
			local mineId, slot, typeId = slotInfo.MineId, slotInfo.Slot, def.Id
			actionButton(box, TEXT.Place, UITheme.Colors.Positive, function()
				call("PlaceDrill", nil, mineId, slot, typeId)
			end)
		end
	end
	if not any then
		local box = card(1, 70)
		textLabel(box, TEXT.EmptySlot, 0, 17, UITheme.Colors.TextPrimary, true)
		local hint = textLabel(box, TEXT.NoDrills, 26, 14, UITheme.Colors.TextSecondary)
		hint.Size = UDim2.new(1, 0, 0, 30)
		hint.TextWrapped = true
	end
end

local function open(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.MineId) ~= "string" or typeof(payload.Slot) ~= "number" then
		return
	end
	current = { MineId = payload.MineId, Slot = payload.Slot }
	render()
	openedAt = rootPosition()
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "DrillSlot",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0.6, 0),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(480, 420) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	title = Create("TextLabel", {
		Size = UDim2.new(1, -48, 0, 30),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 22,
		TextColor3 = UITheme.Colors.TextPrimary,
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
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -44),
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
	StateController.StatusChanged:Connect(function()
		if gui.Enabled then
			render()
		end
	end)
end

function DrillSlotController.Init()
	build()
	Net.on("OpenSlotMenu", open)
end

function DrillSlotController.Start() end

return DrillSlotController
