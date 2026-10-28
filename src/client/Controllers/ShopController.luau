--!strict
-- Shop-Fenster (docs/10 §23, §57–61). Equipment-Shop: Reiter PICKAXES / BACKPACKS, Karten mit
-- Name, Stats (mit Vergleich zum ausgerüsteten Item), Level-Anforderung, Preis und Status
-- LOCKED / AVAILABLE / OWNED / EQUIPPED. Machine-Shop: Reiter DRILLS, mehrfach kaufbar, mit
-- Inventaranzeige Owned / Placed / Available (docs/10 §38). Kaufen entscheidet der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Pickaxes = require(Shared.Definitions.Pickaxes)
local Backpacks = require(Shared.Definitions.Backpacks)
local Drills = require(Shared.Definitions.Drills)
local Conveyors = require(Shared.Definitions.Conveyors)
local Vehicles = require(Shared.Definitions.Vehicles)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local CategoryIcon = require(script.Parent.Parent.UI.Components.CategoryIcon)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Shop
local CLOSE_DISTANCE = 18

local ShopController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local list: ScrollingFrame
local title: TextLabel
local tabsFrame: Frame
local tabButtons: { [string]: TextButton } = {}
local currentShop = "equipment"
local currentTab = "pickaxe"

-- Reiter je Shop
local SHOP_TABS: { [string]: { { string } } } = {
	equipment = { { "pickaxe", TEXT.Pickaxes }, { "backpack", TEXT.Backpacks } },
	machine = { { "drill", TEXT.Drills }, { "conveyor", TEXT.Conveyors } },
	vehicle = { { "vehicle", TEXT.Vehicles } },
	truck = { { "truck", TEXT.Trucks } },
}

local TAB_ICONS: { [string]: string } = {
	pickaxe = "Pickaxe",
	backpack = "Backpack",
	drill = "Drill",
	conveyor = "Conveyor",
	vehicle = "Vehicle",
	truck = "Vehicle",
}

local SHOP_TITLES: { [string]: string } = {
	equipment = TEXT.EquipmentTitle,
	machine = TEXT.MachineTitle,
	vehicle = TEXT.VehicleTitle,
	truck = TEXT.TruckTitle,
}
local openedAt: Vector3? = nil
local busy = false

type Card = { Id: string, Name: string, Level: number, Price: number, Available: boolean, Stats: { { label: string, value: string, compare: string? } }, Multi: boolean? }

-- Inventar je Drill-Typ: gekauft, platziert (docs/10 §38)
local function drillCounts(snapshot: Types.StateSnapshot, typeId: string): (number, number)
	local owned, placed = 0, 0
	for _, drill in snapshot.Drills do
		if drill.Type == typeId then
			owned += 1
			if drill.MineId then
				placed += 1
			end
		end
	end
	return owned, placed
end

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
	elseif tab == "vehicle" or tab == "truck" then
		for _, def in Vehicles.List do
			-- Autohaus und LKW-Laden zeigen jeweils ihre Fahrzeuge (D-058)
			if (def.Dealer == "truck") ~= (tab == "truck") then
				continue
			end
			table.insert(cards, {
				Id = def.Id,
				Name = def.DisplayName,
				Level = def.RequiredLevel,
				Price = def.Price,
				Available = def.Available ~= false,
				Stats = {
					{ label = TEXT.Capacity, value = NumberFormat.withSeparators(def.Capacity) },
					{ label = TEXT.VehicleSpeed, value = tostring(def.MaxSpeed) },
				},
			})
		end
	elseif tab == "conveyor" then
		for _, def in Conveyors.List do
			local owned, placed = 0, 0
			for _, c in snapshot.Conveyors do
				if c.Type == def.Id then
					owned += 1
					if c.Slot then
						placed += 1
					end
				end
			end
			table.insert(cards, {
				Id = def.Id,
				Name = def.DisplayName,
				Level = def.RequiredLevel,
				Price = def.Price,
				Available = true,
				Multi = true,
				Stats = {
					{ label = TEXT.Throughput, value = string.format(TEXT.PerMinute, NumberFormat.withSeparators(def.Throughput)) },
					{ label = TEXT.Inventory, value = string.format(TEXT.InventoryValue, owned, placed, owned - placed) },
				},
			})
		end
	elseif tab == "drill" then
		for _, def in Drills.List do
			local owned, placed = drillCounts(snapshot, def.Id)
			table.insert(cards, {
				Id = def.Id,
				Name = def.DisplayName,
				Level = def.RequiredLevel,
				Price = def.Price,
				Available = true,
				Multi = true,
				Stats = {
					{ label = TEXT.Production, value = string.format(TEXT.PerMinute, NumberFormat.withSeparators(Drills.OrePerMinute(def))) },
					{ label = TEXT.Output, value = NumberFormat.withSeparators(def.OutputCapacity) },
					{ label = TEXT.Inventory, value = string.format(TEXT.InventoryValue, owned, placed, owned - placed) },
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
	local result = if remote == "BuyMachine" or remote == "BuyVehicle" then Net.invoke(remote, itemId) else Net.invoke(remote, currentTab, itemId)
	busy = false
	if not result.success then
		local def: any = if currentTab == "pickaxe" then Pickaxes.Get(itemId) elseif currentTab == "drill" then Drills.Get(itemId) elseif currentTab == "conveyor" then Conveyors.Get(itemId) elseif currentTab == "vehicle" or currentTab == "truck" then Vehicles.Get(itemId) else Backpacks.Get(itemId)
		NotificationController.Show("Warning", result.code, { Level = def and def.RequiredLevel, Price = def and def.Price })
	end
end

-- Status und Aktion einer Karte (Text, Farbe, aktiv, Remote) – Liste und Podium-Ansicht
local function actionFor(card: Card, snapshot: Types.StateSnapshot, isOwned: boolean, isEquipped: boolean, locked: boolean): (string, Color3, boolean, string?)
	local actionText, actionColor, enabled, remote
	if card.Multi then
		-- Mehrfach kaufbar (Drills): nur Level und Geld entscheiden
		if locked then
			actionText, actionColor, enabled = `{TEXT.Locked}\n{string.format(TEXT.RequiresLevel, card.Level)}`, UITheme.Colors.SurfaceRaised, false
		else
			local affordable = snapshot.Cash >= card.Price
			actionText = string.format(TEXT.Buy, NumberFormat.cash(card.Price))
			actionColor = if affordable then UITheme.Colors.Positive else UITheme.Colors.SurfaceRaised
			enabled, remote = true, "BuyMachine"
		end
	elseif currentTab == "vehicle" or currentTab == "truck" then
		-- Fahrzeuge: einmal kaufen, danach in der Garage am Ring ausparken
		if isOwned then
			actionText, actionColor, enabled = TEXT.Owned, UITheme.Colors.Positive, false
		elseif not card.Available then
			actionText, actionColor, enabled = TEXT.ComingSoon, UITheme.Colors.SurfaceRaised, false
		elseif locked then
			actionText, actionColor, enabled = `{TEXT.Locked}\n{string.format(TEXT.RequiresLevel, card.Level)}`, UITheme.Colors.SurfaceRaised, false
		else
			local affordable = snapshot.Cash >= card.Price
			actionText = string.format(TEXT.Buy, NumberFormat.cash(card.Price))
			actionColor = if affordable then UITheme.Colors.Positive else UITheme.Colors.SurfaceRaised
			enabled, remote = true, "BuyVehicle"
		end
	elseif isEquipped then
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
	return actionText, actionColor, enabled, remote
end

-- Besitz/Ausrüstung im aktuellen Reiter
local function ownership(snapshot: Types.StateSnapshot): ({ [string]: boolean }, string)
	local owned: { [string]: boolean } = if currentTab == "pickaxe" then snapshot.OwnedPickaxes elseif currentTab == "backpack" then snapshot.OwnedBackpacks else {}
	if currentTab == "vehicle" or currentTab == "truck" then
		owned = {}
		for _, vehicle in snapshot.Vehicles do
			owned[vehicle.Type] = true
		end
	end
	local equipped = if currentTab == "pickaxe" then snapshot.EquippedPickaxe elseif currentTab == "backpack" then snapshot.EquippedBackpack else ""
	return owned, equipped
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
	local owned: { [string]: boolean } = if currentTab == "pickaxe" then snapshot.OwnedPickaxes elseif currentTab == "backpack" then snapshot.OwnedBackpacks else {}
	if currentTab == "vehicle" or currentTab == "truck" then
		for _, vehicle in snapshot.Vehicles do
			owned[vehicle.Type] = true
		end
	end
	local equipped = if currentTab == "pickaxe" then snapshot.EquippedPickaxe elseif currentTab == "backpack" then snapshot.EquippedBackpack else ""

	for index, card in cardsFor(currentTab, snapshot) do
		local isOwned = owned[card.Id] == true
		local isEquipped = equipped == card.Id
		local locked = not isOwned and snapshot.MiningLevel < card.Level

		local frame = Create("Frame", {
			Name = card.Id,
			Size = UDim2.new(1, -8, 0, if card.Multi then 104 else 92),
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
			Size = UDim2.new(0.62, 0, 0, if card.Multi then 60 else 40),
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
		local actionText, actionColor, enabled, remote = actionFor(card, snapshot, isOwned, isEquipped, locked)
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

-- Reiter-Knöpfe für den aktuellen Shop neu aufbauen
local function buildTabs()
	for _, button in tabButtons do
		button:Destroy()
	end
	table.clear(tabButtons)
	for order, def in SHOP_TABS[currentShop] do
		local name = def[1]
		local button: TextButton = Create("TextButton", {
			Size = UDim2.fromOffset(150, 36),
			Font = UITheme.FontBold,
			TextSize = 15,
			Text = "      " .. def[2],
			LayoutOrder = order,
			Parent = tabsFrame,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		-- Kategorie-Icon im Reiter (docs/09 §61)
		local icon = CategoryIcon.create(TAB_ICONS[name] or "", 30)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 4, 0.5, 0)
		icon.Parent = button
		button.Activated:Connect(function()
			currentTab = name
			render()
		end)
		tabButtons[name] = button
	end
end

-- ---------------------------------------------------------------------------------------------
-- Podium-Ansicht (D-070, Felix 2026-10-27): Kamera aufs Podium im Shop, Item dreht sich darauf,
-- unten ein kleines Menü. Blättern mit A/Q (zurück) und D/E (weiter), Pfeile oder Knöpfe.

local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local SHOP_MODELS: { [string]: string } = { equipment = "EquipmentShop", machine = "MachineShop", vehicle = "VehicleShop" }

local scGui: ScreenGui
local scName: TextLabel
local scStats: TextLabel
local scInfo: TextLabel
local scCounter: TextLabel
local scAction: TextButton
local scTabs: Frame
local scTabButtons: { [string]: TextButton } = {}
local scActive = false
local scIndex = 1
local scModel: Model? = nil
local scSpot: BasePart? = nil
local scCamPart: BasePart? = nil
local scAngle = 0
local scRemote: string? = nil
local scCardId: string? = nil
local controls: any = nil

local function showcaseParts(shopId: string): (BasePart?, BasePart?)
	local center = workspace:FindFirstChild("Center")
	local shop = center and SHOP_MODELS[shopId] and center:FindFirstChild(SHOP_MODELS[shopId])
	if not shop then
		return nil, nil
	end
	local spot = shop:FindFirstChild("ShowcaseSpot", true)
	local cam = shop:FindFirstChild("ShowcaseCamera", true)
	if spot and cam and spot:IsA("BasePart") and cam:IsA("BasePart") then
		return spot, cam
	end
	return nil, nil
end

local function showcaseModel(card: Card)
	if scModel then
		scModel:Destroy()
		scModel = nil
	end
	local root = ReplicatedStorage:FindFirstChild("ShowcaseModels")
	local folder = root and root:FindFirstChild(currentTab)
	local template = folder and folder:FindFirstChild(card.Id)
	if template and template:IsA("Model") and scSpot then
		local m = template:Clone()
		m:PivotTo(scSpot.CFrame * CFrame.Angles(0, scAngle, 0))
		m.Parent = workspace.CurrentCamera
		scModel = m
		-- Drills sind sehr unterschiedlich groß (D-075): Kamera fährt je nach Größe näher heran
		local camPart = scCamPart
		local spot = scSpot :: BasePart
		if currentTab == "drill" and camPart then
			local _, size = m:GetBoundingBox()
			local far = (camPart.Position - spot.Position)
			local dist = math.clamp(math.max(size.X, size.Z) * 2, 9, far.Magnitude)
			local target = spot.Position + Vector3.new(0, size.Y * 0.45, 0)
			local pos = spot.Position + far.Unit * dist
			TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.lookAt(pos, target) }):Play()
		elseif camPart and currentShop == "machine" then
			-- Förderbänder: wieder die normale Ansicht
			TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = camPart.CFrame }):Play()
		end
	end
end

local function renderShowcase()
	if not scActive then
		return
	end
	for name, button in scTabButtons do
		local active = name == currentTab
		button.BackgroundColor3 = if active then UITheme.Colors.DefaultAccent else UITheme.Colors.SurfaceRaised
		button.TextColor3 = if active then Color3.fromRGB(24, 27, 33) else UITheme.Colors.TextPrimary
	end
	local snapshot = StateController.Get()
	if not snapshot then
		return
	end
	local cards = cardsFor(currentTab, snapshot)
	if #cards == 0 then
		return
	end
	scIndex = (scIndex - 1) % #cards + 1
	local card = cards[scIndex]
	local owned, equipped = ownership(snapshot)
	local isOwned = owned[card.Id] == true
	local isEquipped = equipped == card.Id
	local locked = not isOwned and snapshot.MiningLevel < card.Level
	local text, color, enabled, remote = actionFor(card, snapshot, isOwned, isEquipped, locked)
	scName.Text = card.Name
	local statLines = {}
	for _, stat in card.Stats do
		table.insert(statLines, if stat.compare then `{stat.label}: {stat.compare} → {stat.value}` else `{stat.label}: {stat.value}`)
	end
	scStats.Text = table.concat(statLines, "   ·   ")
	scInfo.Text = if locked then string.format(TEXT.RequiresLevel, card.Level) else ""
	scCounter.Text = `{scIndex} / {#cards}`
	scAction.Text = string.split(text, "\n")[1]
	scAction.BackgroundColor3 = color
	scAction.TextColor3 = if enabled and color ~= UITheme.Colors.SurfaceRaised then Color3.fromRGB(20, 24, 28) else UITheme.Colors.TextPrimary
	scAction.AutoButtonColor = enabled
	scRemote = if enabled then remote else nil
	if scCardId ~= card.Id then
		scCardId = card.Id
		showcaseModel(card)
	end
end

local function step(delta: number)
	scIndex += delta
	renderShowcase()
end

local function setTab(name: string)
	currentTab = name
	scIndex = 1
	scCardId = nil
	renderShowcase()
end

local function exitShowcase()
	if not scActive then
		return
	end
	scActive = false
	scGui.Enabled = false
	ContextActionService:UnbindAction("ShowcaseNext")
	ContextActionService:UnbindAction("ShowcasePrev")
	ContextActionService:UnbindAction("ShowcaseClose")
	ContextActionService:UnbindAction("ShowcaseBlock")
	if scModel then
		scModel:Destroy()
		scModel = nil
	end
	scCardId = nil
	pcall(function()
		ProximityPromptService.Enabled = true
	end)
	if controls then
		controls:Enable()
	end
	local character = player.Character
	if character then
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				d.LocalTransparencyModifier = 0
			end
		end
	end
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
end

local function enterShowcase(spot: BasePart, camPart: BasePart)
	scActive = true
	scSpot = spot
	scCamPart = camPart
	scCardId = nil
	-- mit dem nächsten Upgrade beginnen (eins nach dem ausgerüsteten), sonst vorne
	scIndex = 1
	local snapshot = StateController.Get()
	if snapshot then
		local _, equipped = ownership(snapshot)
		for i, card in cardsFor(currentTab, snapshot) do
			if card.Id == equipped then
				scIndex = i + 1
			end
		end
	end
	-- Reiter dieses Shops
	for _, b in scTabButtons do
		b:Destroy()
	end
	table.clear(scTabButtons)
	local tabs = SHOP_TABS[currentShop]
	scTabs.Visible = #tabs > 1
	for order, def in tabs do
		local name = def[1]
		local b: TextButton = Create("TextButton", {
			Size = UDim2.fromOffset(150, 34),
			Font = UITheme.FontBold,
			TextSize = 15,
			Text = def[2],
			LayoutOrder = order,
			Parent = scTabs,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		b.Activated:Connect(function()
			setTab(name)
		end)
		scTabButtons[name] = b
	end
	-- Steuerung aus, Prompts aus, Kamera zum Podium
	local playerScripts = player:FindFirstChild("PlayerScripts")
	local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
	local ok, module = pcall(function()
		return if playerModule then require(playerModule :: any) else nil
	end)
	controls = if ok and module then module:GetControls() else nil
	if controls then
		controls:Disable()
	end
	pcall(function()
		ProximityPromptService.Enabled = false
	end)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = camPart.CFrame }):Play()
	local priority = Enum.ContextActionPriority.High.Value + 100
	ContextActionService:BindActionAtPriority("ShowcaseNext", function(_, state)
		if state == Enum.UserInputState.Begin then
			step(1)
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.KeyCode.D, Enum.KeyCode.E, Enum.KeyCode.Right)
	ContextActionService:BindActionAtPriority("ShowcasePrev", function(_, state)
		if state == Enum.UserInputState.Begin then
			step(-1)
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.KeyCode.A, Enum.KeyCode.Q, Enum.KeyCode.Left)
	ContextActionService:BindActionAtPriority("ShowcaseClose", function(_, state)
		if state == Enum.UserInputState.Begin then
			exitShowcase()
		end
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.KeyCode.Backspace, Enum.KeyCode.X)
	-- übrige Bewegungstasten schlucken, damit die Figur stehen bleibt
	ContextActionService:BindActionAtPriority("ShowcaseBlock", function()
		return Enum.ContextActionResult.Sink
	end, false, priority, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Space)
	-- eigene Figur ausblenden, sie stünde sonst im Bild
	local character = player.Character
	if character then
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				d.LocalTransparencyModifier = 1
			end
		end
	end
	scGui.Enabled = true
	renderShowcase()
end

local function buildShowcase()
	scGui = Create("ScreenGui", {
		Name = "ShopShowcase",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 31,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Reiter oben
	scTabs = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(320, 34),
		BackgroundTransparency = 1,
		Parent = scGui,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }) })
	-- Schließen oben rechts
	local closeButton: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 130),
		Size = UDim2.fromOffset(130, 40),
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0.1,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = UITheme.Colors.TextPrimary,
		Text = "X   CLOSE",
		Parent = scGui,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }) })
	closeButton.Activated:Connect(exitShowcase)
	-- Leiste unten
	local bar = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.new(0.94, 0, 0, 128),
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0,
		Parent = scGui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 18) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised, Thickness = 1.5 }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(760, 128) }),
	})
	local function arrow(dir: number): TextButton
		local b: TextButton = Create("TextButton", {
			AnchorPoint = Vector2.new(if dir < 0 then 0 else 1, 0.5),
			Position = UDim2.new(if dir < 0 then 0 else 1, if dir < 0 then 14 else -14, 0.5, 0),
			Size = UDim2.fromOffset(74, 100),
			BackgroundColor3 = UITheme.Colors.SurfaceRaised,
			Font = UITheme.FontBold,
			TextSize = 38,
			TextColor3 = UITheme.Colors.TextPrimary,
			Text = if dir < 0 then "‹" else "›",
			Parent = bar,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 14) }) })
		Create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -6),
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 13,
			TextColor3 = UITheme.Colors.TextSecondary,
			Text = if dir < 0 then "A / Q" else "D / E",
			Parent = b,
		})
		b.Activated:Connect(function()
			step(dir)
		end)
		return b
	end
	arrow(-1)
	arrow(1)
	local info = Create("Frame", {
		Position = UDim2.fromOffset(104, 14),
		Size = UDim2.new(1, -208 - 230, 1, -28),
		BackgroundTransparency = 1,
		Parent = bar,
	})
	scName = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 28,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	scStats = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 17,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	scInfo = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(0.7, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 15,
		TextColor3 = UITheme.Colors.DefaultAccent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = info,
	})
	scCounter = Create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 66),
		Size = UDim2.new(0.3, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 15,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = info,
	})
	scAction = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -102, 0.5, 0),
		Size = UDim2.fromOffset(210, 72),
		Font = UITheme.FontBold,
		TextSize = 22,
		TextWrapped = true,
		Parent = bar,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 14) }) })
	scAction.Activated:Connect(function()
		if scRemote and scCardId then
			act(scRemote, scCardId)
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if scActive and scModel and scSpot then
			scAngle = (scAngle + dt * 0.7) % (math.pi * 2)
			scModel:PivotTo(scSpot.CFrame * CFrame.Angles(0, scAngle, 0))
		end
	end)
	StateController.Changed:Connect(function()
		if scActive then
			renderShowcase()
		end
	end)
	player.CharacterRemoving:Connect(exitShowcase)
end

local function open(payload: any)
	if typeof(payload) ~= "table" or SHOP_TABS[payload.ShopId] == nil then
		return
	end
	if scActive then
		return
	end
	if payload.ShopId ~= currentShop then
		currentShop = payload.ShopId
		currentTab = SHOP_TABS[currentShop][1][1]
		buildTabs()
	end
	-- Kasse kann einen Reiter vorgeben (Rucksack-Kasse im Pickaxe-Shop, D-074)
	if typeof(payload.Tab) == "string" then
		for _, t in SHOP_TABS[currentShop] do
			if t[1] == payload.Tab then
				currentTab = payload.Tab
			end
		end
	end
	-- Shops mit Podium öffnen die Podium-Ansicht statt der Liste (D-070)
	local spot, camPart = showcaseParts(currentShop)
	if spot and camPart then
		gui.Enabled = false
		enterShowcase(spot, camPart)
		return
	end
	title.Text = SHOP_TITLES[currentShop] or TEXT.EquipmentTitle
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
	title = Create("TextLabel", {
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

	tabsFrame = Create("Frame", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = panel,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }) })
	buildTabs()

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
	buildShowcase()
	Net.on("OpenShop", open)
	-- Zurücksetzen der Figur (Esc → Reset) während der Podium-Ansicht: Kamera und Steuerung
	-- sonst dauerhaft gesperrt
	player.CharacterAdded:Connect(function()
		exitShowcase()
	end)
end

function ShopController.Start() end

return ShopController
