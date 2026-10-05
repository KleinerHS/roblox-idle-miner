--!strict
-- Firmen-Laptop (docs/09 §21–28): kurzer Kamera-Zoom auf den Laptop, dann eine saubere
-- Firmen-Oberfläche mit App-Leiste. DASHBOARD (Überblick), EMPLOYEES (Worker einstellen/
-- entlassen, Drills an Mining-Slots), STORAGE und ELEVATOR (Bestand, Kapazität, Upgrades),
-- PRODUCTION (Drills mit Status, Inventar). COMPANY später.
-- Kein Windows-Klon (docs/20). Einstellen/Entlassen prüft der Server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Mines = require(Shared.Definitions.Mines)
local Materials = require(Shared.Definitions.Materials)
local WorkerRoles = require(Shared.Definitions.WorkerRoles)
local Drills = require(Shared.Definitions.Drills)
local SmelterLogic = require(Shared.Util.SmelterLogic)
local Upgrades = require(Shared.Definitions.Upgrades)
local BalanceConfig = require(Shared.Config.BalanceConfig)
local CompanyIdentity = require(Shared.Definitions.CompanyIdentity)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local PlotController = require(script.Parent.PlotController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Laptop

local LaptopController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local content: Frame
local headerName: TextLabel
local navButtons: { [string]: TextButton } = {}
local currentApp = "DASHBOARD"
local selectedMine = "mine_001"
local statuses: { [string]: string } = {}
local busy = false

local function accent(snapshot: Types.StateSnapshot?): Color3
	local color = snapshot and CompanyIdentity.ColorById[snapshot.Company.ColorId]
	return if color then color.Color else UITheme.Colors.DefaultAccent
end

local function clearContent()
	for _, child in content:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function label(text: string, size: number, color: Color3, order: number, bold: boolean?): TextLabel
	return Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, size + 6),
		BackgroundTransparency = 1,
		Font = if bold then UITheme.FontBold else UITheme.Font,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = text,
		LayoutOrder = order,
		Parent = content,
	})
end

-- args: Platzhalter für die Fehlermeldung (z. B. Price/Level)
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

local function slotCard(order: number, title: string, worker: Types.WorkerRecord?, roleDef: WorkerRoles.RoleDefinition, slot: number, canHire: boolean, snapshot: Types.StateSnapshot)
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = content,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
	})
	Create("TextLabel", {
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.new(0.6, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = card,
	})
	local sub, subColor
	if worker then
		local status = statuses[worker.Id] or "Working"
		sub = `{roleDef.DisplayName} #{worker.Id:sub(2)} · {TEXT.Status[status] or status} · {string.format(TEXT.Wage, NumberFormat.cash(roleDef.WagePerMinute))}`
		subColor = if status == "Unpaid" then UITheme.Colors.Negative elseif status == "Waiting" then UITheme.Colors.Warning else UITheme.Colors.Positive
	else
		sub = `{TEXT.Empty} · {roleDef.DisplayName} · {string.format(TEXT.Wage, NumberFormat.cash(roleDef.WagePerMinute))}`
		subColor = UITheme.Colors.TextSecondary
	end
	Create("TextLabel", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(0.66, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = subColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = sub,
		Parent = card,
	})
	local text, color, enabled, onClick
	if worker then
		text, color, enabled = TEXT.Fire, UITheme.Colors.SurfaceRaised, true
		local id = worker.Id
		onClick = function()
			call("FireWorker", nil, id)
		end
	else
		local affordable = snapshot.Cash >= roleDef.HireCost
		text = string.format(TEXT.Hire, NumberFormat.cash(roleDef.HireCost))
		color = if canHire and affordable then accent(snapshot) else UITheme.Colors.SurfaceRaised
		enabled = canHire
		local mineId, role = selectedMine, roleDef.Id
		onClick = function()
			call("HireWorker", { Price = roleDef.HireCost }, mineId, role, slot)
		end
	end
	local button: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(130, 38),
		BackgroundColor3 = color,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = if color == UITheme.Colors.SurfaceRaised then UITheme.Colors.TextPrimary else Color3.fromRGB(20, 24, 28),
		AutoButtonColor = enabled,
		Text = text,
		Parent = card,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	if enabled then
		button.Activated:Connect(onClick)
	end
end

-- Drill-Status als Text und Farbe (docs/05 §29: Grün arbeitet, Orange wartet)
local function drillStatus(id: string): (string, Color3)
	local status = statuses[id]
	if status == "Running" then
		return TEXT.DrillStatus.Running, UITheme.Colors.Positive
	elseif status == "OutputFull" then
		return TEXT.DrillStatus.OutputFull, UITheme.Colors.Warning
	end
	return TEXT.DrillStatus.Idle, UITheme.Colors.Warning
end

-- Karte für einen Mining-Slot mit Drill (Slot ist Worker ODER Drill, docs/05 §26)
local function drillSlotCard(order: number, title: string, drill: Types.DrillRecord)
	local def = Drills.Get(drill.Type)
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = content,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
	})
	Create("TextLabel", {
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.new(0.6, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = card,
	})
	local statusText, statusColor = drillStatus(drill.Id)
	local rate = if def then string.format(TEXT.DrillRate, NumberFormat.withSeparators(Drills.OrePerMinute(def))) else ""
	Create("TextLabel", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(0.66, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = statusColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = `{if def then def.DisplayName else drill.Type} · {statusText} · {rate}`,
		Parent = card,
	})
	local button: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(130, 38),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = UITheme.Colors.TextPrimary,
		Text = TEXT.RemoveDrill,
		Parent = card,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	local id = drill.Id
	button.Activated:Connect(function()
		call("RemoveDrill", nil, id)
	end)
end

local function renderEmployees(snapshot: Types.StateSnapshot)
	label(TEXT.Employees, 24, UITheme.Colors.TextPrimary, 1, true)
	local storageBuilt = snapshot.Buildings.build_storage == true
	if not storageBuilt then
		label(TEXT.NeedStorage, 16, UITheme.Colors.Warning, 2)
	end

	-- Minen-Auswahl (nur freigeschaltete Minen)
	local tabs = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = content,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })
	local any = false
	for _, mine in Mines.List do
		if Mines.IsAccessible(mine, snapshot.MiningLevel, snapshot.UnlockedMines) then
			any = true
			local active = mine.Id == selectedMine
			local tab: TextButton = Create("TextButton", {
				Size = UDim2.fromOffset(96, 34),
				BackgroundColor3 = if active then accent(snapshot) else UITheme.Colors.SurfaceRaised,
				Font = UITheme.FontBold,
				TextSize = 14,
				TextColor3 = if active then Color3.fromRGB(20, 24, 28) else UITheme.Colors.TextPrimary,
				Text = Mines.Label(mine),
				LayoutOrder = mine.Number,
				Parent = tabs,
			}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
			local id = mine.Id
			tab.Activated:Connect(function()
				selectedMine = id
				LaptopController.Render()
			end)
		end
	end
	if not any then
		label(TEXT.NoMines, 16, UITheme.Colors.TextSecondary, 4)
		return
	end

	local mine = Mines.Get(selectedMine)
	local ore = mine and Materials.Get(mine.OreId)
	local buffer = snapshot.MineBuffers[selectedMine] or 0
	local elevatorLoad = 0
	for _, amount in snapshot.ElevatorBuffer do
		elevatorLoad += amount
	end
	label(`{if ore then ore.DisplayName else ""} · {string.format(TEXT.Buffer, NumberFormat.withSeparators(buffer))} · {string.format(TEXT.Elevator, NumberFormat.withSeparators(elevatorLoad), NumberFormat.withSeparators(snapshot.ElevatorCapacity))}`, 14, UITheme.Colors.TextSecondary, 4)

	local order = 10
	for _, roleId in WorkerRoles.Order do
		local roleDef = WorkerRoles.Get(roleId) :: WorkerRoles.RoleDefinition
		for slot = 1, roleDef.Slots do
			local worker: Types.WorkerRecord? = nil
			for _, w in snapshot.Workers do
				if w.MineId == selectedMine and w.Role == roleId and w.Slot == slot then
					worker = w
				end
			end
			local title = string.format(if roleId == "Mining" then TEXT.MiningSlot else TEXT.TransportSlot, slot)
			local drill: Types.DrillRecord? = nil
			if roleId == "Mining" then
				for _, d in snapshot.Drills do
					if d.MineId == selectedMine and d.Slot == slot then
						drill = d
					end
				end
			end
			if drill then
				drillSlotCard(order, title, drill)
			else
				slotCard(order, title, worker, roleDef, slot, storageBuilt, snapshot)
			end
			order += 1
		end
	end
end

-- Karte im Inhaltsbereich (oder in einem Grid)
local function card(order: number, height: number, parent: Instance?): Frame
	return Create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = parent or content,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}),
	})
end

local function cardText(parent: Instance, text: string, y: number, size: number, color: Color3, bold: boolean?, xAlign: Enum.TextXAlignment?): TextLabel
	return Create("TextLabel", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, size + 4),
		BackgroundTransparency = 1,
		Font = if bold then UITheme.FontBold else UITheme.Font,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = xAlign or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Parent = parent,
	})
end

-- Füllbalken (0–1), z. B. Lagerauslastung
local function bar(parent: Instance, y: number, fraction: number, snapshot: Types.StateSnapshot)
	local f = math.clamp(fraction, 0, 1)
	local back = Create("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Parent = parent,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Create("Frame", {
		Size = UDim2.fromScale(f, 1),
		BackgroundColor3 = if f >= 1 then UITheme.Colors.Negative elseif f >= 0.85 then UITheme.Colors.Warning else accent(snapshot),
		Parent = back,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
end

local function sumItems(items: { [string]: number }): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

-- Anzahl Worker je Laufzeitstatus
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

-- Upgrade-Karte für Lager oder Elevator (docs/09 §30–31). Server prüft alles erneut.
local function upgradeCard(order: number, kind: Upgrades.UpgradeKind, capacity: number, snapshot: Types.StateSnapshot)
	local tier = Upgrades.Next(kind, capacity)
	local done, total = Upgrades.Progress(kind, capacity)
	local box = card(order, 120)
	cardText(box, string.format(TEXT.UpgradeLevel, done, total), 0, 14, UITheme.Colors.TextSecondary, true)
	if not tier then
		cardText(box, TEXT.MaxLevel, 26, 22, UITheme.Colors.Positive, true)
		cardText(box, TEXT.MaxLevelSub, 56, 15, UITheme.Colors.TextSecondary)
		return
	end
	cardText(box, `{TEXT.Current}: {NumberFormat.withSeparators(capacity)}   →   {TEXT.Next}: {NumberFormat.withSeparators(tier.Capacity)}`, 26, 18, UITheme.Colors.TextPrimary, true)
	local levelOk = snapshot.MiningLevel >= tier.RequiredLevel
	local affordable = snapshot.Cash >= tier.Cost
	cardText(box, `{TEXT.Cost}: {NumberFormat.cash(tier.Cost)}`, 54, 15, if affordable then UITheme.Colors.TextPrimary else UITheme.Colors.Negative)
	cardText(box, string.format(TEXT.RequiresLevel, tier.RequiredLevel), 76, 15, if levelOk then UITheme.Colors.TextSecondary else UITheme.Colors.Warning)
	local ready = levelOk and affordable
	local button: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(170, 40),
		BackgroundColor3 = if ready then accent(snapshot) else UITheme.Colors.SurfaceRaised,
		Font = UITheme.FontBold,
		TextSize = 15,
		TextColor3 = if ready then Color3.fromRGB(20, 24, 28) else UITheme.Colors.TextPrimary,
		Text = string.format(TEXT.UpgradeButton, NumberFormat.cash(tier.Cost)),
		Parent = box,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	button.Activated:Connect(function()
		call("BuyUpgrade", { Level = tier.RequiredLevel, Price = tier.Cost }, kind)
	end)
end

-- DASHBOARD: schneller Firmenüberblick, keine Tabelle (docs/09 §24)
local function renderDashboard(snapshot: Types.StateSnapshot)
	label(TEXT.Dashboard, 24, UITheme.Colors.TextPrimary, 1, true)
	local grid = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = content,
	}, {
		Create("UIGridLayout", {
			CellSize = UDim2.new(0.5, -5, 0, 96),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local function tile(order: number, title: string, value: string, sub: string?, subColor: Color3?): Frame
		local box = card(order, 96, grid)
		cardText(box, title, 0, 14, UITheme.Colors.TextSecondary, true)
		cardText(box, value, 22, 24, UITheme.Colors.TextPrimary, true)
		if sub then
			cardText(box, sub, 54, 14, subColor or UITheme.Colors.TextSecondary)
		end
		return box
	end

	tile(1, TEXT.MiningLevel, tostring(snapshot.MiningLevel), string.format(Strings.Hud.XP, NumberFormat.withSeparators(snapshot.MiningXP), NumberFormat.withSeparators(snapshot.MiningXPRequired)))
	tile(2, TEXT.Cash, NumberFormat.cash(snapshot.Cash))

	if snapshot.Buildings.build_storage then
		local used = sumItems(snapshot.StorageItems)
		local box = tile(3, TEXT.StorageCard, `{NumberFormat.withSeparators(used)} / {NumberFormat.withSeparators(snapshot.StorageCapacity)}`)
		bar(box, 58, used / math.max(1, snapshot.StorageCapacity), snapshot)
	else
		tile(3, TEXT.StorageCard, "–", TEXT.NotBuilt)
	end

	local total, working, waiting, unpaidCount = workerCounts(snapshot)
	if total == 0 then
		tile(4, TEXT.EmployeesCard, "0", TEXT.NoEmployees)
	else
		local parts = { string.format(TEXT.ActiveCount, working) }
		if waiting > 0 then
			table.insert(parts, string.format(TEXT.WaitingCount, waiting))
		end
		if unpaidCount > 0 then
			table.insert(parts, string.format(TEXT.UnpaidCount, unpaidCount))
		end
		tile(4, TEXT.EmployeesCard, tostring(total), table.concat(parts, " · "), if unpaidCount > 0 then UITheme.Colors.Negative elseif waiting > 0 then UITheme.Colors.Warning else UITheme.Colors.Positive)
	end

	-- Produktion: rechnerischer Abbau der bezahlten Mining-Worker und laufenden Drills,
	-- dazu der Elevator-Füllstand
	local rate = 0
	for _, worker in snapshot.Workers do
		if worker.Role == "Mining" and statuses[worker.Id] ~= "Unpaid" then
			rate += BalanceConfig.Workers.Mining.OrePerMinute
		end
	end
	for _, drill in snapshot.Drills do
		local def = Drills.Get(drill.Type)
		if def and drill.MineId and statuses[drill.Id] == "Running" then
			rate += Drills.OrePerMinute(def)
		end
	end
	local load = sumItems(snapshot.ElevatorBuffer)
	tile(5, TEXT.ProductionCard, string.format(TEXT.PerMinute, NumberFormat.withSeparators(rate)), string.format(TEXT.ElevatorLoad, NumberFormat.withSeparators(load), NumberFormat.withSeparators(snapshot.ElevatorCapacity)))
end

-- STORAGE: Bestand, Kapazität, Upgrade (docs/09 §29–30)
local function renderStorage(snapshot: Types.StateSnapshot)
	label(TEXT.StorageTitle, 24, UITheme.Colors.TextPrimary, 1, true)
	if not snapshot.Buildings.build_storage then
		label(TEXT.StorageNotBuilt, 16, UITheme.Colors.Warning, 2)
		return
	end
	local used = sumItems(snapshot.StorageItems)
	local head = card(2, 64)
	cardText(head, `{NumberFormat.withSeparators(used)} / {NumberFormat.withSeparators(snapshot.StorageCapacity)}`, 0, 22, UITheme.Colors.TextPrimary, true)
	bar(head, 32, used / math.max(1, snapshot.StorageCapacity), snapshot)

	local ids = {}
	for id, amount in snapshot.StorageItems do
		if amount > 0 then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local oa, ob = Materials.Get(a), Materials.Get(b)
		return (if oa then oa.Tier else 999) < (if ob then ob.Tier else 999)
	end)
	if #ids == 0 then
		label(TEXT.StorageEmpty, 15, UITheme.Colors.TextSecondary, 3)
	end
	for i, id in ids do
		local ore = Materials.Get(id)
		local row = card(2 + i, 40)
		cardText(row, if ore then ore.DisplayName else id, 0, 16, UITheme.Colors.TextPrimary)
		cardText(row, NumberFormat.withSeparators(snapshot.StorageItems[id]), 0, 16, UITheme.Colors.TextPrimary, true, Enum.TextXAlignment.Right)
	end
	upgradeCard(100, "storage", snapshot.StorageCapacity, snapshot)
end

-- ELEVATOR: Kapazität, Takt, Status, Upgrade (docs/09 §31)
local function renderElevator(snapshot: Types.StateSnapshot)
	label(TEXT.ElevatorTitle, 24, UITheme.Colors.TextPrimary, 1, true)
	if not snapshot.Buildings.build_elevator then
		label(TEXT.ElevatorNotBuilt, 16, UITheme.Colors.Warning, 2)
		return
	end
	local load = sumItems(snapshot.ElevatorBuffer)
	local storageFull = snapshot.Buildings.build_storage == true and sumItems(snapshot.StorageItems) >= snapshot.StorageCapacity
	local status = if load > 0 and storageFull then "StorageFull" elseif load > 0 then "Transporting" else "Idle"
	local statusColor = if status == "StorageFull" then UITheme.Colors.Negative elseif status == "Transporting" then UITheme.Colors.Positive else UITheme.Colors.TextSecondary

	local cycle = BalanceConfig.Elevator.CycleSeconds
	local head = card(2, 118)
	cardText(head, TEXT.Capacity, 0, 14, UITheme.Colors.TextSecondary, true)
	cardText(head, TEXT.ElevatorStatus[status], 0, 14, statusColor, true, Enum.TextXAlignment.Right)
	cardText(head, string.format(TEXT.PerTrip, NumberFormat.withSeparators(snapshot.ElevatorCapacity)), 22, 22, UITheme.Colors.TextPrimary, true)
	cardText(head, string.format(TEXT.TripEvery, cycle, NumberFormat.withSeparators(math.floor(snapshot.ElevatorCapacity * 60 / cycle))), 54, 15, UITheme.Colors.TextSecondary)
	cardText(head, string.format(TEXT.CurrentLoad, NumberFormat.withSeparators(load)), 76, 15, UITheme.Colors.TextSecondary)
	upgradeCard(3, "elevator", snapshot.ElevatorCapacity, snapshot)
end

-- PRODUCTION: platzierte Drills mit Status, verfügbare Drills im Inventar (docs/09 §32–33)
local function renderProduction(snapshot: Types.StateSnapshot)
	label(TEXT.ProductionTitle, 24, UITheme.Colors.TextPrimary, 1, true)
	-- Schmelzer (docs/09 §32, D-011): Status, Füllstände, Priorität
	local hasSmelter = snapshot.Buildings.build_smelter == true
	if hasSmelter then
		local state = snapshot.Smelter
		local status = SmelterLogic.Status(state)
		local box = card(2, 78)
		cardText(box, TEXT.SmelterCard, 0, 17, UITheme.Colors.TextPrimary, true)
		cardText(box, Strings.Smelter.Status[status] or status, 0, 14, if status == "Running" then UITheme.Colors.Positive elseif status == "OutputFull" then UITheme.Colors.Negative else UITheme.Colors.Warning, true, Enum.TextXAlignment.Right)
		local cfg = BalanceConfig.Smelter
		cardText(box, `{string.format(Strings.Smelter.Input, NumberFormat.withSeparators(SmelterLogic.Sum(state.Input)), NumberFormat.withSeparators(cfg.InputCapacity))} · {string.format(Strings.Smelter.Output, NumberFormat.withSeparators(SmelterLogic.Sum(state.Output)), NumberFormat.withSeparators(cfg.OutputCapacity))}`, 24, 14, UITheme.Colors.TextSecondary)
		local preferred = if state.Priority ~= "" then Materials.Get(state.Priority) else nil
		cardText(box, `{Strings.Smelter.Priority}: {if preferred then preferred.DisplayName else Strings.Smelter.Auto}`, 44, 14, UITheme.Colors.TextSecondary)
	end
	local placed: { Types.DrillRecord } = {}
	local available: { [string]: number } = {}
	for _, drill in snapshot.Drills do
		if drill.MineId then
			table.insert(placed, drill)
		else
			available[drill.Type] = (available[drill.Type] or 0) + 1
		end
	end
	if #placed == 0 and next(available) == nil then
		if not hasSmelter then
			label(TEXT.NoMachines, 16, UITheme.Colors.TextSecondary, 2)
		end
		return
	end
	table.sort(placed, function(a, b)
		local ma, mb = Mines.Get(a.MineId or ""), Mines.Get(b.MineId or "")
		local na, nb = if ma then ma.Number else 0, if mb then mb.Number else 0
		if na ~= nb then
			return na < nb
		end
		return (a.Slot or 0) < (b.Slot or 0)
	end)
	for i, drill in placed do
		local def = Drills.Get(drill.Type)
		local mine = Mines.Get(drill.MineId or "")
		local box = card(10 + i, 64)
		cardText(box, `{if def then def.DisplayName else drill.Type} – {if mine then Mines.Label(mine) else ""} · {string.format(TEXT.MiningSlot, drill.Slot or 0)}`, 0, 17, UITheme.Colors.TextPrimary, true)
		local statusText, statusColor = drillStatus(drill.Id)
		local rate = if def then string.format(TEXT.DrillRate, NumberFormat.withSeparators(Drills.OrePerMinute(def))) else ""
		cardText(box, `{statusText} · {rate}`, 24, 14, statusColor)
		local button: TextButton = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(120, 36),
			BackgroundColor3 = UITheme.Colors.SurfaceRaised,
			Font = UITheme.FontBold,
			TextSize = 14,
			TextColor3 = UITheme.Colors.TextPrimary,
			Text = TEXT.RemoveDrill,
			Parent = box,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		local id = drill.Id
		button.Activated:Connect(function()
			call("RemoveDrill", nil, id)
		end)
	end
	if next(available) ~= nil then
		label(TEXT.InventoryTitle, 16, UITheme.Colors.TextSecondary, 100, true)
		local order = 101
		for _, def in Drills.List do
			local count = available[def.Id]
			if count then
				local box = card(order, 52)
				cardText(box, string.format(TEXT.InventoryLine, def.DisplayName, count), 0, 16, UITheme.Colors.TextPrimary, true)
				cardText(box, TEXT.InventoryHint, 22, 13, UITheme.Colors.TextSecondary)
				order += 1
			end
		end
	end
end

function LaptopController.Render()
	if not gui or not gui.Enabled then
		return
	end
	clearContent()
	local snapshot = StateController.Get()
	if not snapshot then
		return
	end
	local logo = CompanyIdentity.LogoById[snapshot.Company.LogoId]
	headerName.Text = `{if logo then logo.Glyph .. "  " else ""}{snapshot.Company.Name}`
	for app, button in navButtons do
		local active = app == currentApp
		button.BackgroundColor3 = if active then accent(snapshot) else UITheme.Colors.Surface
		button.TextColor3 = if active then Color3.fromRGB(20, 24, 28) else UITheme.Colors.TextPrimary
	end
	if currentApp == "EMPLOYEES" then
		renderEmployees(snapshot)
	elseif currentApp == "DASHBOARD" then
		renderDashboard(snapshot)
	elseif currentApp == "STORAGE" then
		renderStorage(snapshot)
	elseif currentApp == "ELEVATOR" then
		renderElevator(snapshot)
	elseif currentApp == "PRODUCTION" then
		renderProduction(snapshot)
	else
		label(currentApp, 24, UITheme.Colors.TextPrimary, 1, true)
		label(TEXT.ComingSoon, 16, UITheme.Colors.TextSecondary, 2)
	end
end

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

local function close()
	gui.Enabled = false
	zoomTo(false)
end

local function open()
	zoomTo(true)
	task.wait(0.35)
	gui.Enabled = true
	LaptopController.Render()
end

local function build()
	gui = Create("ScreenGui", {
		Name = "Laptop",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 35,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.8),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 16) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised, Thickness = 2 }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(860, 560) }),
	})
	-- Kopfzeile mit Firmenname
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = UITheme.Colors.Surface,
		Parent = panel,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 16) }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 12) }),
	})
	headerName = Create("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 20,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	local closeButton: TextButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = UITheme.Colors.TextPrimary,
		Text = TEXT.Close,
		Parent = header,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	closeButton.Activated:Connect(close)

	-- App-Leiste links
	local nav = Create("Frame", {
		Position = UDim2.fromOffset(14, 66),
		Size = UDim2.new(0, 170, 1, -80),
		BackgroundTransparency = 1,
		Parent = panel,
	}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })
	for i, app in TEXT.Apps do
		local button: TextButton = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = UITheme.Colors.Surface,
			Font = UITheme.FontBold,
			TextSize = 14,
			TextColor3 = UITheme.Colors.TextPrimary,
			Text = app,
			LayoutOrder = i,
			Parent = nav,
		}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
		button.Activated:Connect(function()
			currentApp = app
			LaptopController.Render()
		end)
		navButtons[app] = button
	end

	content = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(198, 66),
		Size = UDim2.new(1, -212, 1, -80),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UITheme.Colors.SurfaceRaised,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
		Create("UIPadding", { PaddingRight = UDim.new(0, 8) }),
	})

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and gui.Enabled then
			close()
		end
	end)
	StateController.Changed:Connect(function()
		LaptopController.Render()
	end)
	player.CharacterAdded:Connect(function()
		if gui.Enabled then
			close()
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
