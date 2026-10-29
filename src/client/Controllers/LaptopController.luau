--!strict
-- Firmen-Laptop „Mine OS“ (D-079, Oberfläche V4 aus Felix' Paket Laptop_Overlay_MineOS_V4):
-- dunkles Graphit-Design, Apps nur über die Taskleiste, immer maximiert über der Taskleiste,
-- Taskleiste bleibt beim App-Wechsel sichtbar, Minimieren/Schließen führt zum leeren Desktop,
-- das X in der Taskleiste schließt den ganzen Laptop.
--
-- Die Oberfläche (UI/MineOS_Laptop.rbxmx) ist reine Optik ohne Scripts. Dieser Controller
-- verbindet sie mit den echten Spielsystemen (Werte aus dem Snapshot, Aktionen über die
-- vorhandenen Remotes; der Server prüft alles erneut). Beispielwerte und Beispiel-Upgrades
-- aus dem Paket, für die es kein Spielsystem gibt, werden ersetzt oder ausgeblendet.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mines = require(Shared.Definitions.Mines)
local Materials = require(Shared.Definitions.Materials)
local WorkerRoles = require(Shared.Definitions.WorkerRoles)
local Drills = require(Shared.Definitions.Drills)
local SmelterLogic = require(Shared.Util.SmelterLogic)
local Upgrades = require(Shared.Definitions.Upgrades)
local BalanceConfig = require(Shared.Config.BalanceConfig)
local RareDropLogic = require(Shared.Util.RareDropLogic)
local CompanyIdentity = require(Shared.Definitions.CompanyIdentity)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)
local PrestigeLogic = require(Shared.Util.PrestigeLogic)
local CrateLogic = require(Shared.Util.CrateLogic)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local PlotController = require(script.Parent.PlotController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Laptop

local LaptopController = {}

local player = Players.LocalPlayer

-- Farben aus THEME.json des Pakets
local C = {
	ink = Color3.fromRGB(23, 27, 34),
	surface = Color3.fromRGB(30, 35, 44),
	panel = Color3.fromRGB(36, 42, 52),
	panel2 = Color3.fromRGB(44, 51, 62),
	line = Color3.fromRGB(58, 66, 79),
	text = Color3.fromRGB(238, 240, 244),
	muted = Color3.fromRGB(164, 173, 186),
	faint = Color3.fromRGB(120, 131, 145),
	accent = Color3.fromRGB(154, 184, 231),
	primary = Color3.fromRGB(72, 120, 201),
	amber = Color3.fromRGB(211, 176, 120),
	red = Color3.fromRGB(205, 140, 140),
	green = Color3.fromRGB(140, 196, 150),
}

local APPS = { "Overview", "Employees", "Storage", "Elevator", "Production", "Luck", "Company", "Prestige", "Settings" }

local gui: ScreenGui? = nil
local root: Frame? = nil
local currentApp: string? = nil
local selectedMine = "mine_001"
local selectedDrill = 1
local statuses: { [string]: string } = {}
local busy = false
-- Prestige-Bestätigung: Startzeit (3 Sekunden Wartezeit, nie mit einem einzelnen Klick)
local CONFIRM_SECONDS = 3
local confirmStartedAt: number? = nil
-- Aktion je Button (wird bei jedem Render neu gesetzt; nil = gesperrt)
local handlers: { [GuiButton]: (() -> ())? } = {}
local hooked: { [GuiButton]: boolean } = {}
-- dynamisch erzeugte Bereiche (Mitarbeiter-Liste, Erzliste)
local dynamic: { [string]: ScrollingFrame } = {}

-- ---------------------------------------------------------------------------------------------
-- Hilfen

local function find(path: string): any
	local node: Instance? = root
	for name in string.gmatch(path, "[^/]+") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local function setText(path: string, text: string, color: Color3?)
	local l = find(path)
	if l and (l:IsA("TextLabel") or l:IsA("TextButton")) then
		l.Text = text
		if color then
			l.TextColor3 = color
		end
	end
end

local function setVisible(path: string, visible: boolean)
	local g = find(path)
	if g and g:IsA("GuiObject") then
		g.Visible = visible
	end
end

local function setFill(path: string, fraction: number, color: Color3?)
	local f = find(path)
	if f and f:IsA("Frame") then
		f.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		if color then
			f.BackgroundColor3 = color
		end
	end
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

-- Button binden: Aktion (oder nil = gesperrt), Text, Stil
local function bind(button: any, text: string?, action: (() -> ())?, primary: boolean?)
	if not (button and button:IsA("GuiButton")) then
		return
	end
	local b = button :: GuiButton
	handlers[b] = action
	if not hooked[b] then
		hooked[b] = true
		b.Activated:Connect(function()
			local h = handlers[b]
			if h then
				h()
			end
		end)
	end
	if text and b:IsA("TextButton") then
		b.Text = text
	end
	local enabled = action ~= nil
	b.AutoButtonColor = enabled
	b.Active = enabled
	if b:IsA("TextButton") then
		b.BackgroundColor3 = if not enabled then C.panel2 elseif primary == false then C.panel2 else C.primary
		b.TextColor3 = if enabled then C.text else C.faint
	end
end

-- Schalter (TextButton mit „Thumb“): Zustand anzeigen und Aktion binden
local function toggle(path: string, on: boolean, action: (() -> ())?)
	local t = find(path)
	if not t then
		return
	end
	bind(t, nil, action)
	t.BackgroundColor3 = if on then C.primary else C.panel2
	local thumb = t:FindFirstChild("Thumb")
	if thumb and thumb:IsA("Frame") then
		thumb.Position = UDim2.new(if on then 0.522 else 0.07, 0, thumb.Position.Y.Scale, 0)
	end
end

local function sumItems(items: { [string]: number }): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

local function workerCounts(snapshot: Types.StateSnapshot): (number, number, number, number)
	local total, working, waiting, unpaidCount = 0, 0, 0, 0
	for _, worker in snapshot.Workers do
		total += 1
		local status = statuses[worker.Id] or "Working"
		if status == "Unpaid" then
			unpaidCount += 1
		elseif status == "Waiting" then
			waiting += 1
		else
			working += 1
		end
	end
	return total, working, waiting, unpaidCount
end

-- rechnerischer Abbau pro Minute (bezahlte Mining-Worker + laufende Drills)
local function productionRate(snapshot: Types.StateSnapshot): number
	local rate = 0
	for _, worker in snapshot.Workers do
		if worker.Role == "Mining" and statuses[worker.Id] ~= "Unpaid" then
			rate += BalanceConfig.Workers.Mining.OrePerMinute
		end
	end
	for _, drill in snapshot.Drills do
		local def = Drills.Get(drill.Type)
		if def and drill.MineId and statuses[drill.Id] == "Running" then
			rate += Drills.OrePerMinute(def, Drills.LevelOf(drill))
		end
	end
	return rate
end

local function storageFull(snapshot: Types.StateSnapshot): boolean
	return snapshot.Buildings.build_storage == true and CrateLogic.isFull(snapshot.StorageItems, snapshot.StorageCrates)
end

local function pct(x: number): string
	local v = x * 100
	if v >= 10 then
		return string.format("%.0f%%", v)
	elseif v >= 1 then
		return string.format("%.1f%%", v)
	end
	return string.format("%.2f%%", v)
end

-- Skalierung für dynamische Inhalte (Gestaltung 1280 breit)
local function px(n: number): number
	local r = root
	-- nicht unter 60 %: auf kleinen Bildschirmen sonst unleserlich (Test 2026-10-29)
	local s = if r then math.clamp(r.AbsoluteSize.X / 1280, 0.6, 1) else 1
	return math.floor(n * s + 0.5)
end

-- Scrollbereich an Stelle der Beispiel-Inhalte (graphitfarbene Karten untereinander)
local function dynamicArea(app: string, position: UDim2, size: UDim2): ScrollingFrame
	local area = dynamic[app]
	if area and area.Parent then
		for _, child in area:GetChildren() do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		return area
	end
	local new: ScrollingFrame = Create("ScrollingFrame", {
		Name = "Dynamic",
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.line,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = find(`Windows/{app}/Content`),
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
	})
	dynamic[app] = new
	return new
end

local function dynLabel(parent: Instance, text: string, size: number, color: Color3, order: number, bold: boolean?): TextLabel
	return Create("TextLabel", {
		Size = UDim2.new(1, -8, 0, px(size + 8)),
		BackgroundTransparency = 1,
		Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham,
		TextSize = px(size),
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = text,
		LayoutOrder = order,
		Parent = parent,
	})
end

local function dynButton(parent: Instance, text: string, action: (() -> ())?, primary: boolean?, anchorRight: number?): TextButton
	local b: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -px(anchorRight or 14), 0.5, 0),
		Size = UDim2.fromOffset(px(150), px(34)),
		Font = Enum.Font.Gotham,
		TextScaled = true,
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Create("UITextSizeConstraint", { MaxTextSize = px(14), MinTextSize = 7 }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
	})
	bind(b, text, action, primary)
	return b
end

local function dynCard(parent: Instance, order: number, height: number): Frame
	return Create("Frame", {
		Size = UDim2.new(1, -8, 0, px(height)),
		BackgroundColor3 = C.panel,
		LayoutOrder = order,
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Create("UIStroke", { Color = C.line, Thickness = 1 }),
	})
end

local function cardLine(parent: Instance, text: string, y: number, size: number, color: Color3, bold: boolean?, width: number?): TextLabel
	return Create("TextLabel", {
		Position = UDim2.fromOffset(px(16), px(y)),
		Size = UDim2.new(width or 0.55, 0, 0, px(size + 6)),
		BackgroundTransparency = 1,
		Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham,
		TextSize = px(size),
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Parent = parent,
	})
end

-- ---------------------------------------------------------------------------------------------
-- Apps

local function renderOverview(snapshot: Types.StateSnapshot)
	local base = "Windows/Overview/Content"
	setText(`{base}/MiningLevel/Value`, tostring(snapshot.MiningLevel))
	setText(`{base}/MiningLevel/Hint`, string.format("%s / %s XP", NumberFormat.withSeparators(snapshot.MiningXP), NumberFormat.withSeparators(snapshot.MiningXPRequired)))
	setText(`{base}/Cash/Value`, NumberFormat.cash(snapshot.Cash))
	local nextCrate = CrateLogic.price(snapshot.StorageCrates + 1)
	setText(`{base}/Cash/Hint`, if snapshot.Cash >= nextCrate then "Ready for your next upgrade" else "Keep mining and selling")

	local full = storageFull(snapshot)
	if snapshot.Buildings.build_storage then
		local used = sumItems(snapshot.StorageItems)
		setText(`{base}/Storage/Value`, `{NumberFormat.withSeparators(used)} / {NumberFormat.withSeparators(snapshot.StorageCapacity)}`, if full then C.amber else C.text)
		setText(`{base}/Storage/Hint`, if full then "Storage full" else string.format("%s crates in use", tostring(CrateLogic.used(snapshot.StorageItems))))
	else
		setText(`{base}/Storage/Value`, "–", C.text)
		setText(`{base}/Storage/Hint`, "Not built yet")
	end

	local total, working, waiting, unpaidCount = workerCounts(snapshot)
	setText(`{base}/Employees/Value`, tostring(total))
	local parts = { `{working} active`, `{waiting} waiting` }
	if unpaidCount > 0 then
		table.insert(parts, `{unpaidCount} unpaid`)
	end
	setText(`{base}/Employees/Hint`, if total == 0 then "No employees yet" else table.concat(parts, "  /  "), if unpaidCount > 0 then C.red else nil)

	local rate = productionRate(snapshot)
	setText(`{base}/Production/Value`, string.format("%s ore / min", NumberFormat.withSeparators(rate)))
	setText(`{base}/Production/Hint`, if full then "Waiting for free storage" elseif rate > 0 then "Running" else "No active miners or drills")

	local load = sumItems(snapshot.ElevatorBuffer)
	if snapshot.Buildings.build_elevator then
		setText(`{base}/Elevator/Value`, `{NumberFormat.withSeparators(load)} / {NumberFormat.withSeparators(snapshot.ElevatorCapacity)}`)
		setText(`{base}/Elevator/Hint`, if load > 0 and full then "Waiting for storage" elseif load > 0 then "Transporting" else "Idle")
	else
		setText(`{base}/Elevator/Value`, "–")
		setText(`{base}/Elevator/Hint`, "Not built yet")
	end

	-- Hinweisbalken: wichtigster Zustand
	local title, desc, color
	if not snapshot.Buildings.build_storage then
		title, desc, color = "Build your storage", "Build the storage in your hall to start collecting ore.", C.amber
	elseif full then
		title, desc, color = "Storage is full", "Buy more crates to keep your operation moving.", C.amber
	elseif unpaidCount > 0 then
		title, desc, color = "Employees are unpaid", "Keep enough cash so your crew keeps working.", C.red
	else
		title, desc, color = "Everything is running", "Your operation is working normally.", C.green
	end
	setText(`{base}/CapacityNotice/Title`, title)
	setText(`{base}/CapacityNotice/Description`, desc)
	local accent = find(`{base}/CapacityNotice/Accent`)
	if accent then
		accent.BackgroundColor3 = color
	end
end

local function renderEmployees(snapshot: Types.StateSnapshot)
	setVisible("Windows/Employees/Content/Roster", false)
	setVisible("Windows/Employees/Content/HirePanel", false)
	setText("Windows/Employees/Content/Description", "Hire workers for your mining and transport slots.")
	local area = dynamicArea("Employees", UDim2.fromScale(0, 0.25), UDim2.fromScale(1, 0.75))
	local storageBuilt = snapshot.Buildings.build_storage == true
	local order = 1
	if not storageBuilt then
		dynLabel(area, TEXT.NeedStorage, 15, C.amber, order)
		order += 1
	end
	-- Minen-Auswahl
	local tabs = Create("Frame", {
		Size = UDim2.new(1, -8, 0, px(34)),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = area,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, px(8)), SortOrder = Enum.SortOrder.LayoutOrder }) })
	order += 1
	local any = false
	for _, mine in Mines.List do
		if Mines.IsAccessible(mine, snapshot.MiningLevel, snapshot.UnlockedMines) then
			any = true
			local active = mine.Id == selectedMine
			local tab: TextButton = Create("TextButton", {
				Size = UDim2.fromOffset(px(96), px(32)),
				Font = Enum.Font.Gotham,
				TextSize = px(14),
				LayoutOrder = mine.Number,
				Parent = tabs,
			}, { Create("UICorner", { CornerRadius = UDim.new(0, 5) }) })
			local id = mine.Id
			bind(tab, Mines.Label(mine), function()
				selectedMine = id
				LaptopController.Render()
			end, active)
		end
	end
	if not any then
		dynLabel(area, TEXT.NoMines, 15, C.muted, order)
		return
	end
	local mine = Mines.Get(selectedMine)
	local ore = mine and Materials.Get(mine.OreId)
	local buffer = snapshot.MineBuffers[selectedMine] or 0
	local total, working, waiting, unpaidCount = workerCounts(snapshot)
	dynLabel(area, `{if ore then ore.DisplayName else ""} · {string.format(TEXT.Buffer, NumberFormat.withSeparators(buffer))} · Crew {total} ({working} active, {waiting} waiting{if unpaidCount > 0 then `, {unpaidCount} unpaid` else ""})`, 14, C.muted, order)
	order += 1

	for _, roleId in WorkerRoles.Order do
		local roleDef = WorkerRoles.Get(roleId) :: WorkerRoles.RoleDefinition
		for slot = 1, roleDef.Slots do
			local worker: Types.WorkerRecord? = nil
			for _, w in snapshot.Workers do
				if w.MineId == selectedMine and w.Role == roleId and w.Slot == slot then
					worker = w
				end
			end
			local drill: Types.DrillRecord? = nil
			if roleId == "Mining" then
				for _, d in snapshot.Drills do
					if d.MineId == selectedMine and d.Slot == slot then
						drill = d
					end
				end
			end
			local title = string.format(if roleId == "Mining" then TEXT.MiningSlot else TEXT.TransportSlot, slot)
			local box = dynCard(area, order, 62)
			order += 1
			cardLine(box, title, 9, 16, C.text, true)
			local d = drill
			if d then
				-- Slot mit Drill: entfernen (Upgrade in der Production-App)
				local def = Drills.Get(d.Type)
				local level = Drills.LevelOf(d)
				local st = statuses[d.Id]
				local stText = if st == "Running" then TEXT.DrillStatus.Running elseif st == "OutputFull" then TEXT.DrillStatus.OutputFull else TEXT.DrillStatus.Idle
				cardLine(box, `{if def then def.DisplayName else d.Type} · Lv {level} · {stText}`, 34, 13, if st == "Running" then C.green else C.amber, false, 0.6)
				local id = d.Id
				dynButton(box, "Remove drill", function()
					call("RemoveDrill", nil, id)
				end, false)
			elseif worker then
				local status = statuses[worker.Id] or "Working"
				cardLine(box, `{roleDef.DisplayName} #{worker.Id:sub(2)} · {TEXT.Status[status] or status} · {string.format(TEXT.Wage, NumberFormat.cash(roleDef.WagePerMinute))}`, 34, 13, if status == "Unpaid" then C.red elseif status == "Waiting" then C.amber else C.green, false, 0.6)
				local id = worker.Id
				dynButton(box, "Fire", function()
					call("FireWorker", nil, id)
				end, false)
			else
				cardLine(box, `{TEXT.Empty} · {roleDef.DisplayName} · {string.format(TEXT.Wage, NumberFormat.cash(roleDef.WagePerMinute))}`, 34, 13, C.muted, false, 0.6)
				local mineId, role = selectedMine, roleDef.Id
				local canHire = storageBuilt and snapshot.Cash >= roleDef.HireCost
				dynButton(box, `Hire  ·  {NumberFormat.cash(roleDef.HireCost)}`, if canHire
					then function()
						call("HireWorker", { Price = roleDef.HireCost }, mineId, role, slot)
					end
					else nil, true)
			end
		end
	end
end

local function renderStorage(snapshot: Types.StateSnapshot)
	local base = "Windows/Storage/Content"
	local built = snapshot.Buildings.build_storage == true
	local used = sumItems(snapshot.StorageItems)
	local full = storageFull(snapshot)
	setText(`{base}/Description`, "Monitor stored ore and add crates to grow your capacity.")
	if built then
		setText(`{base}/CapacitySummary/Value`, `{NumberFormat.withSeparators(used)} / {NumberFormat.withSeparators(snapshot.StorageCapacity)}`)
		setText(`{base}/CapacitySummary/State`, if full then "FULL" else "OK", if full then C.amber else C.green)
		setFill(`{base}/CapacitySummary/StorageCapacity/Fill`, used / math.max(1, snapshot.StorageCapacity), if full then C.amber else C.primary)
	else
		setText(`{base}/CapacitySummary/Value`, "Not built yet")
		setText(`{base}/CapacitySummary/State`, "", C.muted)
		setFill(`{base}/CapacitySummary/StorageCapacity/Fill`, 0)
	end

	-- Kapazität wächst über Paletten-Kisten (D-037): nächste Kiste kaufen
	local cfg = BalanceConfig.Storage
	local crates = snapshot.StorageCrates
	setText(`{base}/CapacityUpgrade/Title`, "Storage crates")
	setVisible(`{base}/CapacityUpgrade/Arrow`, true)
	setVisible(`{base}/CapacityUpgrade/Next`, true)
	local upgrade = find(`{base}/CapacityUpgrade/Upgrade`)
	if crates >= cfg.MaxCrates then
		setText(`{base}/CapacityUpgrade/Subtitle`, TEXT.CratesMax)
		setText(`{base}/CapacityUpgrade/Current`, NumberFormat.withSeparators(crates * cfg.CrateSize))
		setVisible(`{base}/CapacityUpgrade/Arrow`, false)
		setVisible(`{base}/CapacityUpgrade/Next`, false)
		bind(upgrade, "Maximum reached", nil)
	else
		local price = CrateLogic.price(crates + 1)
		setText(`{base}/CapacityUpgrade/Subtitle`, string.format("%d / %d crates · each holds %s of one material", crates, cfg.MaxCrates, NumberFormat.withSeparators(cfg.CrateSize)))
		setText(`{base}/CapacityUpgrade/Current`, NumberFormat.withSeparators(crates * cfg.CrateSize))
		setText(`{base}/CapacityUpgrade/Next`, NumberFormat.withSeparators((crates + 1) * cfg.CrateSize))
		bind(upgrade, `Buy crate  ·  {NumberFormat.cash(price)}`, if built and snapshot.Cash >= price
			then function()
				call("BuyStorageCrate", { Price = price })
			end
			else nil)
	end

	-- statt „Transfer rate“ (kein Spielsystem): Liste der gelagerten Materialien
	local card = find(`{base}/TransferUpgrade`)
	if card then
		setText(`{base}/TransferUpgrade/Title`, "Stored materials")
		setText(`{base}/TransferUpgrade/Subtitle`, string.format("%d crates in use", CrateLogic.used(snapshot.StorageItems)))
		for _, n in { "Current", "Arrow", "Next", "Upgrade" } do
			setVisible(`{base}/TransferUpgrade/{n}`, false)
		end
		local list = card:FindFirstChild("Materials") :: ScrollingFrame?
		if not list then
			list = Create("ScrollingFrame", {
				Name = "Materials",
				Position = UDim2.fromScale(0.041, 0.4),
				Size = UDim2.fromScale(0.918, 0.55),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = C.line,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				Parent = card,
			}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }) })
		end
		local l = list :: ScrollingFrame
		for _, child in l:GetChildren() do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		local ids = {}
		for id, amount in snapshot.StorageItems do
			if amount > 0 then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			return snapshot.StorageItems[a] > snapshot.StorageItems[b]
		end)
		if #ids == 0 then
			dynLabel(l, if built then TEXT.StorageEmpty else TEXT.StorageNotBuilt, 14, C.muted, 1)
		end
		for i, id in ids do
			local mat = Materials.Get(id)
			local row = Create("Frame", { Size = UDim2.new(1, -6, 0, px(22)), BackgroundTransparency = 1, LayoutOrder = i, Parent = l })
			Create("TextLabel", {
				Size = UDim2.fromScale(0.65, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextSize = px(14),
				TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = if mat then mat.DisplayName else id,
				Parent = row,
			})
			Create("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.35, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = px(14),
				TextColor3 = C.accent,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = NumberFormat.withSeparators(snapshot.StorageItems[id]),
				Parent = row,
			})
		end
	end
end

local function renderElevator(snapshot: Types.StateSnapshot)
	local base = "Windows/Elevator/Content"
	local built = snapshot.Buildings.build_elevator == true
	local load = sumItems(snapshot.ElevatorBuffer)
	local full = storageFull(snapshot)
	setText(`{base}/Description`, "Manage elevator capacity and see how much ore reaches the surface.")
	setText(`{base}/Status/LocationLabel`, "STATUS")
	if built then
		local status = if load > 0 and full then "StorageFull" elseif load > 0 then "Transporting" else "Idle"
		setText(`{base}/Status/Position`, TEXT.ElevatorStatus[status], if status == "StorageFull" then C.amber elseif status == "Transporting" then C.green else C.text)
		setText(`{base}/Status/Load`, `{NumberFormat.withSeparators(load)} / {NumberFormat.withSeparators(snapshot.ElevatorCapacity)} ore`)
	else
		setText(`{base}/Status/Position`, "Not built yet", C.muted)
		setText(`{base}/Status/Load`, "")
	end

	-- Kapazität: echte Upgrade-Stufen (Upgrades „elevator“)
	local tier = Upgrades.Next("elevator", snapshot.ElevatorCapacity)
	setText(`{base}/CapacityUpgrade/Current`, NumberFormat.withSeparators(snapshot.ElevatorCapacity))
	local upgrade = find(`{base}/CapacityUpgrade/Upgrade`)
	if not tier then
		setText(`{base}/CapacityUpgrade/Subtitle`, TEXT.MaxLevelSub)
		setVisible(`{base}/CapacityUpgrade/Arrow`, false)
		setVisible(`{base}/CapacityUpgrade/Next`, false)
		bind(upgrade, "Maximum reached", nil)
	else
		local t = tier
		local levelOk = snapshot.MiningLevel >= t.RequiredLevel
		setText(`{base}/CapacityUpgrade/Subtitle`, if levelOk then "Carry more ore on every trip." else string.format("Requires mining level %d", t.RequiredLevel), if levelOk then nil else C.amber)
		setVisible(`{base}/CapacityUpgrade/Arrow`, true)
		setVisible(`{base}/CapacityUpgrade/Next`, true)
		setText(`{base}/CapacityUpgrade/Next`, NumberFormat.withSeparators(t.Capacity))
		bind(upgrade, `Upgrade  ·  {NumberFormat.cash(t.Cost)}`, if built and levelOk and snapshot.Cash >= t.Cost
			then function()
				call("BuyUpgrade", { Level = t.RequiredLevel, Price = t.Cost }, "elevator")
			end
			else nil)
	end

	-- statt „Transport speed“ (kein Spielsystem): Durchsatz
	local cycle = BalanceConfig.Elevator.CycleSeconds
	setText(`{base}/SpeedUpgrade/Title`, "Throughput")
	setText(`{base}/SpeedUpgrade/Subtitle`, string.format("One trip every %d s.", cycle))
	setText(`{base}/SpeedUpgrade/Current`, string.format("%s ore / min", NumberFormat.withSeparators(math.floor(snapshot.ElevatorCapacity * 60 / cycle))))
	setVisible(`{base}/SpeedUpgrade/Arrow`, false)
	setVisible(`{base}/SpeedUpgrade/Next`, false)
	setVisible(`{base}/SpeedUpgrade/Upgrade`, false)
	-- „Automatic transport“ gibt es nicht (der Elevator fährt immer automatisch)
	setVisible(`{base}/AutomaticLabel`, false)
	setVisible(`{base}/AutomaticTransport`, false)
end

local function renderProduction(snapshot: Types.StateSnapshot)
	local base = "Windows/Production/Content"
	local full = storageFull(snapshot)
	local rate = productionRate(snapshot)
	setText(`{base}/Output/OutputValue`, string.format("%s ore / min", NumberFormat.withSeparators(rate)))
	setText(`{base}/Output/Status`, if full then "STORAGE FULL" elseif rate > 0 then "RUNNING" else "IDLE", if full then C.amber elseif rate > 0 then C.green else C.muted)
	-- Schmelzer (D-011) in der Kopfzeile
	if snapshot.Buildings.build_smelter then
		local status = SmelterLogic.Status(snapshot.Smelter)
		setText(`{base}/Output/OutputLabel`, `TOTAL OUTPUT  ·  SMELTER {string.upper(Strings.Smelter.Status[status] or status)}`)
	else
		setText(`{base}/Output/OutputLabel`, "TOTAL OUTPUT")
	end

	local placed: { Types.DrillRecord } = {}
	local inventory = 0
	for _, drill in snapshot.Drills do
		if drill.MineId then
			table.insert(placed, drill)
		else
			inventory += 1
		end
	end
	table.sort(placed, function(a, b)
		local ma, mb = Mines.Get(a.MineId or ""), Mines.Get(b.MineId or "")
		local na, nb = if ma then ma.Number else 0, if mb then mb.Number else 0
		if na ~= nb then
			return na < nb
		end
		return (a.Slot or 0) < (b.Slot or 0)
	end)
	local machine = find(`{base}/SelectedMachine`)
	local remove = machine and machine:FindFirstChild("RemoveMachine")
	if machine and not remove then
		remove = Create("TextButton", {
			Name = "RemoveMachine",
			Position = UDim2.fromScale(0.037, 0.789),
			Size = UDim2.fromScale(0.3, 0.116),
			Font = Enum.Font.Gotham,
			TextScaled = true,
			Parent = machine,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
			Create("UITextSizeConstraint", { MaxTextSize = 14 }),
		})
	end
	if #placed == 0 then
		selectedDrill = 1
		setText(`{base}/SelectedMachine/Machine`, "No machine placed")
		setText(`{base}/SelectedMachine/Level`, if inventory > 0 then string.format("%d IN INVENTORY", inventory) else "")
		setText(`{base}/SelectedMachine/State`, if inventory > 0 then "Ready to place" else "No drills yet", C.muted)
		setText(`{base}/SelectedMachine/Reason`, if inventory > 0 then TEXT.InventoryHint else TEXT.NoMachines)
		bind(find(`{base}/SelectedMachine/ManageMachine`), "Next machine", nil, false)
		bind(remove, "Remove", nil, false)
		setText(`{base}/OutputUpgrade/Current`, "–")
		bind(find(`{base}/OutputUpgrade/UpgradeProduction`), "Upgrade", nil)
		return
	end
	selectedDrill = math.clamp(selectedDrill, 1, #placed)
	local drill = placed[selectedDrill]
	local def = Drills.Get(drill.Type)
	local mine = Mines.Get(drill.MineId or "")
	local level = Drills.LevelOf(drill)
	local st = statuses[drill.Id]
	setText(`{base}/SelectedMachine/Machine`, `{if def then def.DisplayName else drill.Type}  ·  {if mine then Mines.Label(mine) else ""} slot {drill.Slot or 0}`)
	setText(`{base}/SelectedMachine/Level`, string.format("LEVEL %02d / %02d%s", level, Drills.MaxLevel, if inventory > 0 then `  ·  {inventory} IN INVENTORY` else ""))
	setText(`{base}/SelectedMachine/State`, if st == "Running" then "Running" elseif st == "OutputFull" then "Paused" else "Idle", if st == "Running" then C.green else C.amber)
	setText(`{base}/SelectedMachine/Reason`, if st == "Running" then (if def then string.format(TEXT.DrillRate, NumberFormat.withSeparators(Drills.OrePerMinute(def, level))) else "") elseif st == "OutputFull" then "Output full – needs transport" else "Waiting to start")
	bind(find(`{base}/SelectedMachine/ManageMachine`), `Next machine  ({selectedDrill}/{#placed})`, if #placed > 1
		then function()
			selectedDrill = selectedDrill % #placed + 1
			LaptopController.Render()
		end
		else nil, false)
	local id = drill.Id
	bind(remove, "Remove", function()
		call("RemoveDrill", nil, id)
	end, false)
	-- Drill-Level 1–10 (D-043)
	local upgradeButton = find(`{base}/OutputUpgrade/UpgradeProduction`)
	setText(`{base}/OutputUpgrade/Title`, "Drill level")
	local cost = if def then Drills.LevelUpCost(def, level) else nil
	if def and cost then
		local c = cost
		setText(`{base}/OutputUpgrade/Current`, `{NumberFormat.withSeparators(Drills.OrePerMinute(def, level))} > {NumberFormat.withSeparators(Drills.OrePerMinute(def, level + 1))}`)
		bind(upgradeButton, `Upgrade  ·  {NumberFormat.cash(c)}`, if snapshot.Cash >= c
			then function()
				call("UpgradeDrill", { Price = NumberFormat.cash(c) }, id)
			end
			else nil)
	else
		setText(`{base}/OutputUpgrade/Current`, if def then NumberFormat.withSeparators(Drills.OrePerMinute(def, level)) else "–")
		bind(upgradeButton, "Maximum level", nil)
	end
end

local function renderLuck(snapshot: Types.StateSnapshot)
	local base = "Windows/Luck/Content"
	local level = snapshot.LuckLevel or 0
	local max = BalanceConfig.Luck.MaxLevel
	local chance = RareDropLogic.Chance(level)
	setText(`{base}/Description`, TEXT.LuckHint)
	setText(`{base}/LuckMultiplier/Multiplier`, pct(chance))
	setText(`{base}/LuckMultiplier/MultiplierLabel`, string.format("RARE FIND CHANCE  ·  LEVEL %d / %d", level, max))
	local price, requiredLevel = RareDropLogic.NextLuck(level)
	local button = find(`{base}/LuckMultiplier/UpgradeLuck`)
	if not price or not requiredLevel then
		setText(`{base}/LuckMultiplier/Next`, TEXT.LuckMax)
		bind(button, "Maximum reached", nil)
	else
		local p, r = price, requiredLevel
		local levelOk = snapshot.MiningLevel >= r
		setText(`{base}/LuckMultiplier/Next`, if levelOk then `Next level  ·  {pct(RareDropLogic.Chance(level + 1))}` else string.format("Requires mining level %d", r), if levelOk then nil else C.amber)
		bind(button, `Upgrade  ·  {NumberFormat.cash(p)}`, if levelOk and snapshot.Cash >= p
			then function()
				call("BuyLuck", { Level = r, Price = NumberFormat.cash(p) })
			end
			else nil)
	end
	-- Fundprofil je Hit nach den echten Regeln (BalanceConfig.RareDrops): normaler Hit, Bonus ×2–×3,
	-- Bonus ×4–×10, seltenes Erz
	local rd = BalanceConfig.RareDrops
	local weights = rd.MultiplierWeights
	local totalW, lowW = 0, 0
	for i, w in weights do
		totalW += w
		if i <= 2 then
			lowW += w
		end
	end
	local multShare = chance * (1 - rd.OreShare)
	local rows = {
		{ "Common", "Normal hit", 1 - chance },
		{ "Uncommon", "Bonus ×2–×3", multShare * lowW / totalW },
		{ "Rare", "Bonus ×4–×10", multShare * (totalW - lowW) / totalW },
		{ "Epic", "Rare ore", chance * rd.OreShare },
	}
	setText(`{base}/RarityOverview/Title`, "Find profile per hit")
	for _, row in rows do
		setText(`{base}/RarityOverview/{row[1]}Label`, row[2])
		setText(`{base}/RarityOverview/{row[1]}Value`, pct(row[3]))
		setFill(`{base}/RarityOverview/{row[1]}Chance/Fill`, math.max(row[3], if row[3] > 0 then 0.01 else 0))
	end
	-- Benachrichtigungs-Schalter: kein Spielsystem
	setVisible(`{base}/RarityOverview/NotificationsLabel`, false)
	setVisible(`{base}/RarityOverview/RareFindNotifications`, false)
end

local function renderCompany(snapshot: Types.StateSnapshot)
	local base = "Windows/Company/Content"
	local logo = CompanyIdentity.LogoById[snapshot.Company.LogoId]
	local color = CompanyIdentity.ColorById[snapshot.Company.ColorId]
	setText(`{base}/CompanyProfile/CompanyName`, `{if logo then logo.Glyph .. "  " else ""}{snapshot.Company.Name}`)
	setText(`{base}/CompanyProfile/Owner`, `Owner  /  {player.DisplayName}`)
	setText(`{base}/Description`, "Your company identity.")
	-- statt Beispiel-Upgrades (kein Spielsystem): Farbe und Logo
	setText(`{base}/LogisticsUpgrade/Title`, TEXT.CompanyColor)
	setText(`{base}/LogisticsUpgrade/Subtitle`, "Your company's accent color.")
	setText(`{base}/LogisticsUpgrade/Current`, if color then color.DisplayName else "–", if color then color.Color else nil)
	setText(`{base}/WorkforceUpgrade/Title`, "Company logo")
	setText(`{base}/WorkforceUpgrade/Subtitle`, "Your company's logo.")
	setText(`{base}/WorkforceUpgrade/Current`, if logo then `{logo.Glyph}  {logo.DisplayName}` else "–")
	for _, cardName in { "LogisticsUpgrade", "WorkforceUpgrade" } do
		setVisible(`{base}/{cardName}/Arrow`, false)
		setVisible(`{base}/{cardName}/Next`, false)
		setVisible(`{base}/{cardName}/Upgrade`, false)
	end
	setText(`{base}/CompanyHint`, TEXT.CompanyChangeHint)
end

local function bonusText(count: number): string
	local money = math.floor((PrestigeLogic.MoneyMultiplier(count) - 1) * 100 + 0.5)
	local speed = math.floor((PrestigeLogic.SpeedMultiplier(count) - 1) * 100 + 0.5)
	return string.format("+%d%% money · +%d%% speed", money, speed)
end

local function renderPrestige(snapshot: Types.StateSnapshot)
	local base = "Windows/Prestige/Content"
	local count = snapshot.PrestigeCount
	local required = BalanceConfig.Prestige.RequiredLevel
	local available = PrestigeLogic.IsAvailable(snapshot.MiningLevel)
	setText(`{base}/PrestigeSummary/CurrentLevel`, tostring(count))
	setText(`{base}/PrestigeSummary/RewardLabel`, "BONUS AFTER NEXT PRESTIGE")
	setText(`{base}/PrestigeSummary/Reward`, bonusText(count + 1))
	setFill(`{base}/PrestigeSummary/PrestigeRequirement/Fill`, snapshot.MiningLevel / required, if available then C.green else C.primary)
	setText(`{base}/PrestigeSummary/Requirement`, string.format("Mining level %d / %d required", snapshot.MiningLevel, required), if available then C.green else nil)
	setText(`{base}/PrestigeReview/Description`, if count > 0 then `Current bonus: {bonusText(count)}` else "Review what resets and what you keep.")
	bind(find(`{base}/PrestigeReview/ReviewPrestige`), if available then "Review prestige" else string.format("Level %d required", required), if available
		then function()
			confirmStartedAt = os.clock()
			LaptopController.Render()
		end
		else nil)

	-- Bestätigungsdialog (deckt die Taskleiste nicht ab)
	local dialog = find("PrestigeConfirmation")
	if dialog then
		dialog.Visible = confirmStartedAt ~= nil and currentApp == "Prestige"
		if dialog.Visible then
			setText("PrestigeConfirmation/Description", `Resets: cash, level, buildings, workers, drills, all ore. You keep: prestige bonuses, company, pickaxes, backpacks, vehicles, Robux purchases. You gain: {bonusText(count + 1)}. This cannot be undone.`)
			bind(find("PrestigeConfirmation/Cancel"), "Cancel", function()
				confirmStartedAt = nil
				LaptopController.Render()
			end, false)
			local remaining = math.ceil(CONFIRM_SECONDS - (os.clock() - (confirmStartedAt :: number)))
			if remaining > 0 then
				bind(find("PrestigeConfirmation/Confirm"), `Confirm prestige ({remaining})`, nil)
				task.delay(1, LaptopController.Render)
			else
				bind(find("PrestigeConfirmation/Confirm"), "Confirm prestige", function()
					confirmStartedAt = nil
					call("Prestige", { Level = required })
					LaptopController.Render()
				end)
				local confirm = find("PrestigeConfirmation/Confirm")
				if confirm then
					confirm.BackgroundColor3 = Color3.fromRGB(176, 84, 84)
				end
			end
		end
	end
end

local function renderSettings(snapshot: Types.StateSnapshot)
	local base = "Windows/Settings/Content/Preferences"
	-- echte Einstellung: Handelsanfragen (docs/13 §12); weitere Schalter haben kein Spielsystem
	setText(`{base}/Title0`, TEXT.TradeRequests)
	setText(`{base}/Description0`, "Allow other players to send you trade offers")
	local enabled = snapshot.Settings.TradeRequests
	toggle(`{base}/Toggle_soundEnabled`, enabled, function()
		call("SetTradeRequests", nil, not enabled)
	end)
	for _, n in { "Title1", "Description1", "Toggle_notificationsEnabled", "Divider1", "Title2", "Description2", "Toggle_rareFindNotifications", "Divider2" } do
		setVisible(`{base}/{n}`, false)
	end
	-- nur das dunkle Design (Felix: dunkles Design beibehalten)
	bind(find(`{base}/Theme`), "Dark", nil, false)
end

local RENDER: { [string]: (Types.StateSnapshot) -> () } = {
	Overview = renderOverview,
	Employees = renderEmployees,
	Storage = renderStorage,
	Elevator = renderElevator,
	Production = renderProduction,
	Luck = renderLuck,
	Company = renderCompany,
	Prestige = renderPrestige,
	Settings = renderSettings,
}

-- Taskleiste: Kontostand, Firma, Uhr, aktive App
local function renderTaskbar(snapshot: Types.StateSnapshot)
	setText("Taskbar/WalletValue", NumberFormat.cash(snapshot.Cash))
	setText("Taskbar/CompanyName", snapshot.Company.Name)
	setText("Taskbar/Clock", os.date("%H:%M") :: string)
	setText("Taskbar/Date", string.upper(os.date("%d %b") :: string))
	for _, app in APPS do
		local indicator = find(`Taskbar/Pinned_{app}/ActiveIndicator`)
		if indicator then
			indicator.Visible = app == currentApp
		end
	end
end

function LaptopController.Render()
	local g = gui
	if not g or not g.Enabled then
		return
	end
	local snapshot = StateController.Get()
	if not snapshot then
		return
	end
	renderTaskbar(snapshot)
	-- genau eine App sichtbar (maximiert über der Taskleiste), sonst der leere Desktop
	for _, app in APPS do
		setVisible(`Windows/{app}`, app == currentApp)
	end
	setVisible("Header", currentApp == nil)
	local dialog = find("PrestigeConfirmation")
	if dialog and currentApp ~= "Prestige" then
		dialog.Visible = false
	end
	local app = currentApp
	if app then
		local render = RENDER[app]
		if render then
			render(snapshot)
		end
	end
end

local function openApp(app: string?)
	if currentApp ~= app then
		confirmStartedAt = nil
	end
	currentApp = app
	LaptopController.Render()
end

-- ---------------------------------------------------------------------------------------------
-- Öffnen / Schließen

-- Kurzer Kamera-Zoom auf den Laptop (docs/04 §7, docs/09 §21)
local function zoomTo(open: boolean)
	local camera = workspace.CurrentCamera
	if open then
		local plot = PlotController.GetPlotModel()
		local laptop = plot and plot:FindFirstChild("Laptop", true)
		local screen = laptop and laptop:FindFirstChild("Screen")
		if screen and screen:IsA("BasePart") then
			camera.CameraType = Enum.CameraType.Scriptable
			local target = CFrame.lookAt((screen.CFrame * CFrame.new(0, 0.6, -3.2)).Position, screen.Position)
			TweenService:Create(camera, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target }):Play()
		end
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end

-- Die Roblox-Werkzeugleiste (Hotbar) liegt über allen Spiel-Oberflächen und verdeckte die
-- Taskleiste mittig (Company-Knopf nicht klickbar): solange der Laptop offen ist, ausblenden
local function setHotbar(visible: boolean)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, visible)
	end)
end

local function close()
	local g = gui
	if not g then
		return
	end
	confirmStartedAt = nil
	currentApp = nil
	g.Enabled = false
	setHotbar(true)
	zoomTo(false)
end

local function open()
	local g = gui
	if not g then
		return
	end
	zoomTo(true)
	task.wait(0.35)
	-- Start immer auf dem leeren Desktop mit Taskleiste
	currentApp = nil
	setHotbar(false)
	g.Enabled = true
	LaptopController.Render()
end

local function build()
	local template = script.Parent.Parent:WaitForChild("UI"):WaitForChild("MineOS_Laptop") :: ScreenGui
	local g = template:Clone()
	g.Name = "Laptop"
	g.Enabled = false
	g.ResetOnSpawn = false
	g.DisplayOrder = 35
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
	root = g:WaitForChild("MineOS") :: Frame

	-- Kleine Bildschirme (Größentest 2026-10-29): Texte mit fester Schriftgröße liefen über. Alle
	-- Texte skalieren mit (Obergrenze = Originalgröße, mindestens 7 px).
	for _, d in g:GetDescendants() do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local c = d:FindFirstChildOfClass("UITextSizeConstraint")
			if not c then
				local nc = Instance.new("UITextSizeConstraint")
				nc.MaxTextSize = math.max(1, math.floor(d.TextSize))
				nc.Parent = d
				c = nc
			elseif not d.TextScaled then
				c.MaxTextSize = math.max(c.MinTextSize, math.floor(d.TextSize))
			end
			c.MinTextSize = math.min(7, c.MaxTextSize)
			d.TextScaled = true
		end
	end
	-- Auf niedrigen Bildschirmen (Handy quer) die ganze Höhe nutzen; Seitenverhältnis bleibt 1,6
	local canvas = root :: Frame
	local defaultSize = canvas.Size
	local function fitCanvas()
		local vp = workspace.CurrentCamera.ViewportSize
		canvas.Size = if vp.Y < 500 then UDim2.fromScale(1, 1) else defaultSize
	end
	fitCanvas()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitCanvas)

	-- alle App-Fenster und der Dialog starten verborgen
	for _, app in APPS do
		setVisible(`Windows/{app}`, false)
	end
	setVisible("PrestigeConfirmation", false)

	-- Taskleiste: Apps öffnen, Einstellungen, Laptop schließen
	for _, app in APPS do
		local launcher = if app == "Settings" then find("Taskbar/Settings") else find(`Taskbar/Pinned_{app}`)
		if launcher and launcher:IsA("GuiButton") then
			launcher.Activated:Connect(function()
				openApp(app)
			end)
		end
		-- Minimieren und Schließen führen zum leeren Desktop
		for _, n in { "Minimize", "Close" } do
			local b = find(`Windows/{app}/Titlebar/{n}`)
			if b and b:IsA("GuiButton") then
				b.Activated:Connect(function()
					openApp(nil)
				end)
			end
		end
	end
	local closeLaptop = find("Taskbar/CloseLaptop")
	if closeLaptop and closeLaptop:IsA("GuiButton") then
		closeLaptop.Activated:Connect(close)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and g.Enabled then
			close()
		end
	end)
	StateController.Changed:Connect(function()
		LaptopController.Render()
	end)
	-- dynamische Inhalte bei Größenänderung neu aufbauen
	local r = root :: Frame
	r:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		LaptopController.Render()
	end)
	player.CharacterAdded:Connect(function()
		if g.Enabled then
			close()
		end
	end)
	-- Uhr in der Taskleiste
	task.spawn(function()
		while true do
			task.wait(15)
			if g.Enabled then
				setText("Taskbar/Clock", os.date("%H:%M") :: string)
			end
		end
	end)
end

function LaptopController.Init()
	build()
	Net.on("OpenLaptop", function()
		task.spawn(open)
	end)
	Net.on("WorkerStatus", function(payload: any)
		if typeof(payload) == "table" then
			statuses = payload
			LaptopController.Render()
		end
	end)
end

function LaptopController.Start() end

return LaptopController
