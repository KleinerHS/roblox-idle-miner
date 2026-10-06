--!strict
-- Förderbänder auf dem Client (docs/06 §24–27):
--   * Platz-Fenster über den Prompt am Pfosten: eingesetztes Band (Status, REMOVE) bzw.
--     verfügbare Bänder aus dem Inventar (INSTALL). Prüfen tut der Server.
--   * Animation: Läuft ein Band (Attribut "Running"), wandern Materialhaufen in der
--     Materialfarbe über die Gurtsegmente – rein lokal, keine Physik (docs/06 §27).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Conveyors = require(Shared.Definitions.Conveyors)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.ConveyorSlot
local CLOSE_DISTANCE = 16
-- Animation: Geschwindigkeit der Haufen (Studs/s), Abstand zwischen Haufen, Sichtweite
local BELT_SPEED = 4
local HEAP_SPACING = 3
local MAX_DISTANCE = 150

local ConveyorController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local title: TextLabel
local list: ScrollingFrame
local openedAt: Vector3? = nil
local currentSlot: string? = nil
local busy = false

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function close()
	gui.Enabled = false
	openedAt = nil
	currentSlot = nil
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

local function card(order: number): Frame
	return Create("Frame", {
		Size = UDim2.new(1, -8, 0, 80),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = list,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
	})
end

local function text(parent: Instance, value: string, y: number, size: number, color: Color3, bold: boolean?)
	Create("TextLabel", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(0.6, 0, 0, size + 4),
		BackgroundTransparency = 1,
		Font = if bold then UITheme.FontBold else UITheme.Font,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = value,
		Parent = parent,
	})
end

local function button(parent: Instance, label: string, color: Color3, onClick: () -> ())
	local b: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(0.34, 0, 0, 40),
		BackgroundColor3 = color,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = if color == UITheme.Colors.SurfaceRaised then UITheme.Colors.TextPrimary else Color3.fromRGB(20, 24, 28),
		Text = label,
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
	local slot = currentSlot
	if not snapshot or not slot then
		return
	end
	title.Text = string.format(TEXT.Title, Conveyors.SlotNames[slot] or slot)
	local installed: Types.ConveyorRecord? = nil
	for _, c in snapshot.Conveyors do
		if c.Slot == slot then
			installed = c
		end
	end
	if installed then
		local def = Conveyors.Get(installed.Type)
		local box = card(1)
		text(box, if def then def.DisplayName else installed.Type, 0, 20, UITheme.Colors.TextPrimary, true)
		if def then
			text(box, string.format(TEXT.PerMinute, NumberFormat.withSeparators(def.Throughput)), 28, 14, UITheme.Colors.TextSecondary)
		end
		local id = installed.Id
		button(box, TEXT.Remove, UITheme.Colors.SurfaceRaised, function()
			call("RemoveConveyor", id)
		end)
		return
	end
	local any = false
	for i, def in Conveyors.List do
		local available = 0
		for _, c in snapshot.Conveyors do
			if c.Type == def.Id and c.Slot == nil then
				available += 1
			end
		end
		if available > 0 then
			any = true
			local box = card(i)
			text(box, def.DisplayName, 0, 20, UITheme.Colors.TextPrimary, true)
			text(box, `{string.format(TEXT.PerMinute, NumberFormat.withSeparators(def.Throughput))} · {string.format(TEXT.Available, available)}`, 28, 14, UITheme.Colors.TextSecondary)
			local typeId = def.Id
			button(box, TEXT.Install, UITheme.Colors.Positive, function()
				call("PlaceConveyor", slot, typeId)
			end)
		end
	end
	if not any then
		local box = card(1)
		text(box, TEXT.Empty, 0, 17, UITheme.Colors.TextPrimary, true)
		Create("TextLabel", {
			Position = UDim2.fromOffset(0, 26),
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 14,
			TextWrapped = true,
			TextColor3 = UITheme.Colors.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = TEXT.NoConveyors,
			Parent = box,
		})
	end
end

local function open(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.Slot) ~= "string" then
		return
	end
	currentSlot = payload.Slot
	render()
	openedAt = rootPosition()
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "ConveyorSlot",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0.55, 0),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(480, 400) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	title = Create("TextLabel", {
		Size = UDim2.new(1, -48, 0, 30),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 20,
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

-- Animation: Haufen entlang der Gurtsegmente eines laufenden Bandes
type Belt = { part: BasePart, length: number }
type Anim = { model: Model, belts: { Belt }, total: number, heaps: { Part }, offset: number }
local anims: { [Model]: Anim } = {}

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	task.wait(0.2)
	local belts: { Belt } = {}
	local segments = model:GetAttribute("Segments")
	local total = 0
	for i = 1, if typeof(segments) == "number" then segments else 0 do
		local belt = model:WaitForChild(`Belt{i}`, 5)
		if belt and belt:IsA("BasePart") then
			table.insert(belts, { part = belt, length = belt.Size.Z })
			total += belt.Size.Z
		end
	end
	if #belts == 0 then
		return
	end
	local heaps = {}
	local count = math.floor(total / HEAP_SPACING)
	for i = 1, count do
		local heap = Instance.new("Part")
		heap.Name = "Heap"
		heap.Shape = Enum.PartType.Ball
		heap.Size = Vector3.new(1.4, 0.7, 1.2)
		heap.Material = Enum.Material.Slate
		heap.Anchored = true
		heap.CanCollide = false
		heap.CanQuery = false
		heap.CanTouch = false
		heap.CastShadow = false
		heap.Transparency = 1
		heap.Parent = model
		heaps[i] = heap
	end
	anims[model] = { model = model, belts = belts, total = total, heaps = heaps, offset = 0 }
end

local function untrack(model: Instance)
	local anim = model:IsA("Model") and anims[model]
	if anim then
		for _, heap in anim.heaps do
			heap:Destroy()
		end
		anims[model] = nil
	end
end

-- Position auf der Strecke (Abstand vom Start) → CFrame auf dem Gurt
local function pointAt(anim: Anim, distance: number): CFrame?
	local d = distance
	for _, belt in anim.belts do
		if d <= belt.length then
			local cf = belt.part.CFrame
			-- Gurt schaut in Laufrichtung (-Z): Start liegt bei +Länge/2
			return cf * CFrame.new(0, belt.part.Size.Y / 2 + 0.3, belt.length / 2 - d)
		end
		d -= belt.length
	end
	return nil
end

local function step(dt: number)
	local root = rootPosition()
	for model, anim in anims do
		local running = model:GetAttribute("Running") == true
		local near = root ~= nil and (anim.belts[1].part.Position - root).Magnitude < MAX_DISTANCE
		if not running or not near then
			for _, heap in anim.heaps do
				heap.Transparency = 1
			end
			continue
		end
		local color = model:GetAttribute("HeapColor")
		anim.offset = (anim.offset + BELT_SPEED * dt) % HEAP_SPACING
		for i, heap in anim.heaps do
			local cf = pointAt(anim, (i - 1) * HEAP_SPACING + anim.offset)
			if cf then
				heap.CFrame = cf
				heap.Transparency = 0
				if typeof(color) == "Color3" then
					heap.Color = color
				end
			else
				heap.Transparency = 1
			end
		end
	end
end

function ConveyorController.Init()
	build()
	Net.on("OpenConveyorSlot", open)
end

function ConveyorController.Start()
	CollectionService:GetInstanceAddedSignal("Conveyor"):Connect(function(model)
		task.spawn(track, model)
	end)
	CollectionService:GetInstanceRemovedSignal("Conveyor"):Connect(untrack)
	for _, model in CollectionService:GetTagged("Conveyor") do
		task.spawn(track, model)
	end
	RunService.RenderStepped:Connect(step)
end

return ConveyorController
