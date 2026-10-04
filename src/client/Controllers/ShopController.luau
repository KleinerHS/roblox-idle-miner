--!strict
-- Equipment-Shop-Fenster (docs/10 §23, §57–61): Reiter PICKAXES / BACKPACKS, Karten mit
-- Name, Stats (mit Vergleich zum ausgerüsteten Item), Level-Anforderung, Preis und Status
-- LOCKED / AVAILABLE / OWNED / EQUIPPED. Kaufen und Ausrüsten entscheidet der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Pickaxes = require(Shared.Definitions.Pickaxes)
local Backpacks = require(Shared.Definitions.Backpacks)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Shop
local CLOSE_DISTANCE = 18

local ShopController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local list: ScrollingFrame
local tabButtons: { [string]: TextButton } = {}
local currentTab = "pickaxe"
local openedAt: Vector3? = nil
local busy = false

type Card = { Id: string, Name: string, Level: number, Price: number, Available: boolean, Stats: { { label: string, value: string, compare: string? } } }

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function close()
	gui.Enabled = false
	openedAt = nil
end

local function cardsFor(tab: string, snapshot: Types.StateSnapshot): { Card }
	local cards: { Card } = {}
	if tab == "pickaxe" then
		local current = Pickaxes.Get(snapshot.EquippedPickaxe)
		for _, def in Pickaxes.List do
			table.insert(cards, {
				Id = def.Id,
				Name = def.DisplayName,
				Level = def.RequiredLevel,
				Price = def.Price,
				Available = def.Available ~= false,
				Stats = {
					{ label = TEXT.Power, value = tostring(def.MiningPower), compare = if current and current.Id ~= def.Id then tostring(current.MiningPower) else nil },
					{ label = TEXT.Speed, value = string.format("%.2f/s", def.MiningSpeed), compare = if current and current.Id ~= def.Id then string.format("%.2f/s", current.MiningSpeed) else nil },
				},
			})
		end
	else
		local current = Backpacks.Get(snapshot.EquippedBackpack)
		for _, def in Backpacks.List do
			table.insert(cards, {
				Id = def.Id,
				Name = def.DisplayName,
				Level = def.RequiredLevel,
				Price = def.Price,
				Available = def.Available ~= false,
				Stats = {
					{ label = TEXT.Capacity, value = NumberFormat.withSeparators(def.Capacity), compare = if current and current.Id ~= def.Id then NumberFormat.withSeparators(current.Capacity) else nil },
				},
			})
		end
	end
	return cards
end

local function act(remote: string, itemId: string)
	if busy then
		return
	end
	busy = true
	local result = Net.invoke(remote, currentTab, itemId)
	busy = false
	if not result.success then
		local def = if currentTab == "pickaxe" then Pickaxes.Get(itemId) else Backpacks.Get(itemId)
		NotificationController.Show("Warning", result.code, { Level = def and def.RequiredLevel, Price = def and def.Price })
	end
end

local function render()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for name, button in tabButtons do
		local active = name == currentTab
		button.BackgroundColor3 = if active then UITheme.Colors.DefaultAccent else UITheme.Colors.SurfaceRaised
		button.TextColor3 = if active then Color3.fromRGB(24, 27, 33) else UITheme.Colors.TextPrimary
	end
	local snapshot = StateController.Get()
	if not snapshot then
		return
	end
	local owned = if currentTab == "pickaxe" then snapshot.OwnedPickaxes else snapshot.OwnedBackpacks
	local equipped = if currentTab == "pickaxe" then snapshot.EquippedPickaxe else snapshot.EquippedBackpack

	for index, card in cardsFor(currentTab, snapshot) do
		local isOwned = owned[card.Id] == true
		local isEquipped = equipped == card.Id
		local locked = not isOwned and snapshot.MiningLevel < card.Level

		local frame = Create("Frame", {
			Name = card.Id,
			Size = UDim2.new(1, -8, 0, 92),
			BackgroundColor3 = UITheme.Colors.Surface,
			LayoutOrder = index,
			Parent = list,
		}, {
			Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
			Create("UIStroke", { Color = if isEquipped then UITheme.Colors.Positive else UITheme.Colors.SurfaceRaised, Thickness = if isEquipped then 2 else 1 }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
		})
		Create("TextLabel", {
			Size = UDim2.new(0.6, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = UITheme.FontBold,
			TextSize = 20,
			TextColor3 = if locked then UITheme.Colors.TextSecondary else UITheme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = card.Name,
			Parent = frame,
		})
		local statLines = {}
		for _, stat in card.Stats do
			table.insert(statLines, if stat.compare then `{stat.label}: {stat.compare} → {stat.value}` else `{stat.label}: {stat.value}`)
		end
		Create("TextLabel", {
			Position = UDim2.fromOffset(0, 28),
			Size = UDim2.new(0.62, 0, 0, 40),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 15,
			TextColor3 = UITheme.Colors.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = table.concat(statLines, "\n"),
			Parent = frame,
		})

		-- Status / Aktion rechts
		local actionText, actionColor, enabled, remote
		if isEquipped then
			actionText, actionColor, enabled = TEXT.Equipped, UITheme.Colors.Positive, false
		elseif isOwned then
			actionText, actionColor, enabled, remote = TEXT.Equip, UITheme.Colors.DefaultAccent, true, "EquipItem"
		elseif not card.Available then
			actionText, actionColor, enabled = TEXT.ComingSoon, UITheme.Colors.SurfaceRaised, false
		elseif locked then
			actionText, actionColor, enabled = `{TEXT.Locked}\n{string.format(TEXT.RequiresLevel, card.Level)}`, UITheme.Colors.SurfaceRaised, false
		else
			local affordable = snapshot.Cash >= card.Price
			actionText = string.format(TEXT.Buy, NumberFormat.cash(card.Price))
			actionColor = if affordable then UITheme.Colors.Positive else UITheme.Colors.SurfaceRaised
			enabled, remote = true, "BuyItem"
		end
		local button: TextButton = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0.36, 0, 0, 46),
			BackgroundColor3 = actionColor,
			Font = UITheme.FontBold,
			TextSize = if locked then 13 else 16,
			TextWrapped = true,
			TextColor3 = if enabled and actionColor ~= UITheme.Colors.SurfaceRaised then Color3.fromRGB(20, 24, 28) else UITheme.Colors.TextPrimary,
			AutoButtonColor = enabled,
			Text = actionText,
			Parent = frame,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		if enabled and remote then
			local id = card.Id
			button.Activated:Connect(function()
				act(remote, id)
			end)
		end
	end
end

local function open(payload: any)
	if typeof(payload) ~= "table" or payload.ShopId ~= "equipment" then
		return
	end
	render()
	openedAt = rootPosition()
	gui.Enabled = true
end

local function build()
	gui = Create("ScreenGui", {
		Name = "EquipmentShop",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.74, 0),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(560, 580) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	Create("TextLabel", {
		Size = UDim2.new(1, -48, 0, 32),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 26,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.EquipmentTitle,
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

	local tabs = Create("Frame", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = panel,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })
	for order, def in { { "pickaxe", TEXT.Pickaxes }, { "backpack", TEXT.Backpacks } } do
		local name = def[1]
		local button: TextButton = Create("TextButton", {
			Size = UDim2.fromOffset(140, 36),
			Font = UITheme.FontBold,
			TextSize = 15,
			Text = def[2],
			LayoutOrder = order,
			Parent = tabs,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		button.Activated:Connect(function()
			currentTab = name
			render()
		end)
		tabButtons[name] = button
	end

	list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 92),
		Size = UDim2.new(1, 0, 1, -92),
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

function ShopController.Init()
	build()
	Net.on("OpenShop", open)
end

function ShopController.Start() end

return ShopController
