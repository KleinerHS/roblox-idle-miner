--!strict
-- Elevator auf Client-Seite: Minenauswahl (docs/09 §34–35), Übergangsanimation
-- (docs/04 §17) und Shaft-Anzeige in der Mine (docs/12 §25).
-- Der Client wünscht nur ein Ziel; Prüfung und Teleport macht ElevatorService.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Mines = require(Shared.Definitions.Mines)
local Ores = require(Shared.Definitions.Ores)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local NotificationController = require(script.Parent.NotificationController)

local TEXT = Strings.Elevator
local SURFACE = "surface"
local ROW_HEIGHT = 64
-- Menü schließt, wenn man sich so weit vom Öffnungsort entfernt
local CLOSE_DISTANCE = 20
-- Muss zu ElevatorService.TRANSITION_IN_SECONDS passen
local FADE_IN = 0.6
local FADE_OUT = 0.6

local ElevatorController = {}

local player = Players.LocalPlayer
local location = SURFACE

local menuGui: ScreenGui
local list: ScrollingFrame
type Row = { frame: Frame, go: TextButton, status: TextLabel }
local rows: { [string]: Row } = {}
local openedAt: Vector3? = nil
local requesting = false

local transitionGui: ScreenGui
local blackout: Frame
local transitionTitle: TextLabel
local transitionSub: TextLabel
local locationLabel: TextLabel
local waitingForArrival = false

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function closeMenu()
	menuGui.Enabled = false
	openedAt = nil
end

local function makeRow(id: string, order: number, color: Color3, title: string, subtitle: string): Row
	local frame: Frame = Create("Frame", {
		Name = id,
		Size = UDim2.new(1, -8, 0, ROW_HEIGHT),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = order,
		Parent = list,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("Frame", {
			Name = "Dot",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = color,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }), Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.7 }) }),
		Create("TextLabel", {
			Name = "Title",
			Position = UDim2.fromOffset(44, 10),
			Size = UDim2.new(0.55, -44, 0, 24),
			BackgroundTransparency = 1,
			Font = UITheme.FontBold,
			TextSize = 20,
			TextColor3 = UITheme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = title,
		}),
		Create("TextLabel", {
			Name = "Subtitle",
			Position = UDim2.fromOffset(44, 34),
			Size = UDim2.new(0.55, -44, 0, 18),
			BackgroundTransparency = 1,
			Font = UITheme.Font,
			TextSize = 15,
			TextColor3 = UITheme.Colors.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = subtitle,
		}),
	})
	local status: TextLabel = Create("TextLabel", {
		Name = "Status",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0.45, -14, 0, 36),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame,
	})
	local go: TextButton = Create("TextButton", {
		Name = "Go",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(84, 38),
		BackgroundColor3 = UITheme.Colors.Positive,
		Font = UITheme.FontBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(20, 24, 28),
		Text = TEXT.Go,
		AutoButtonColor = true,
		Parent = frame,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })

	go.Activated:Connect(function()
		if requesting then
			return
		end
		requesting = true
		closeMenu()
		local result = Net.invoke("RequestTravel", id)
		requesting = false
		if not result.success then
			local mine = Mines.Get(id)
			NotificationController.Show("Warning", result.code, { Level = mine and mine.RequiredLevel })
		end
	end)

	local row = { frame = frame, go = go, status = status }
	rows[id] = row
	return row
end

local function refreshRows()
	local snapshot = StateController.Get()
	local level = if snapshot then snapshot.MiningLevel else 1

	local surfaceRow = rows[SURFACE]
	surfaceRow.frame.Visible = location ~= SURFACE

	for _, mine in Mines.List do
		local row = rows[mine.Id]
		local here = location == mine.Id
		local accessible = Mines.IsAccessible(mine, level)
		row.go.Visible = accessible and not here
		row.status.Visible = not row.go.Visible
		if here then
			row.status.Text = TEXT.Here
			row.status.TextColor3 = UITheme.Colors.Positive
		elseif not accessible then
			row.status.Text = if mine.RequiredLevel
				then `{TEXT.Locked}\n{string.format(TEXT.RequiresLevel, mine.RequiredLevel)}`
				else `{TEXT.Locked}\n{TEXT.ComingSoon}`
			row.status.TextColor3 = UITheme.Colors.TextSecondary
		end
	end
end

local function openMenu(payload: any)
	if typeof(payload) == "table" and typeof(payload.Location) == "string" then
		location = payload.Location
	end
	refreshRows()
	openedAt = rootPosition()
	menuGui.Enabled = true
	-- Aktuelle Mine bzw. Mine 01 in Sichtweite scrollen
	local currentMine = Mines.Get(location)
	local index = if currentMine then currentMine.Number else 1
	list.CanvasPosition = Vector2.new(0, math.max(0, (index - 2) * (ROW_HEIGHT + 8)))
end

local function buildMenu()
	menuGui = Create("ScreenGui", {
		Name = "ElevatorMenu",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0.72, 0),
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = menuGui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(440, 560) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	Create("TextLabel", {
		Size = UDim2.new(1, -48, 0, 32),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 26,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = TEXT.Title,
		Parent = panel,
	})
	local close: TextButton = Create("TextButton", {
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
	close.Activated:Connect(closeMenu)

	list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 1, -46),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = UITheme.Colors.SurfaceRaised,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
	})

	makeRow(SURFACE, 0, UITheme.Colors.DefaultAccent, TEXT.Surface, TEXT.SurfaceSub)
	for _, mine in Mines.List do
		local ore = Ores.Get(mine.OreId)
		makeRow(mine.Id, mine.Number, if ore then ore.Color else Color3.new(0.5, 0.5, 0.5), Mines.Label(mine), if ore then ore.DisplayName else "")
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and menuGui.Enabled then
			closeMenu()
		end
	end)
	RunService.Heartbeat:Connect(function()
		if menuGui.Enabled and openedAt then
			local pos = rootPosition()
			if not pos or (pos - openedAt).Magnitude > CLOSE_DISTANCE then
				closeMenu()
			end
		end
	end)
end

local function buildTransition()
	transitionGui = Create("ScreenGui", {
		Name = "ElevatorTransition",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	blackout = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 8, 10),
		BackgroundTransparency = 1,
		Parent = transitionGui,
	})
	transitionTitle = Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.47),
		Size = UDim2.new(0.8, 0, 0, 56),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 48,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextTransparency = 1,
		Parent = blackout,
	})
	transitionSub = Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.47, 34),
		Size = UDim2.new(0.8, 0, 0, 28),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 22,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextTransparency = 1,
		Parent = blackout,
	})

	-- Shaft-Anzeige oben mittig, nur in Minen sichtbar
	local hud = Create("ScreenGui", {
		Name = "LocationHud",
		ResetOnSpawn = false,
		DisplayOrder = 10,
		Parent = player:WaitForChild("PlayerGui"),
	})
	locationLabel = Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0.2,
		Font = UITheme.FontBold,
		TextSize = 20,
		TextColor3 = UITheme.Colors.TextPrimary,
		Visible = false,
		Parent = hud,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
end

local function tween(instance: Instance, seconds: number, goal: { [string]: any }): Tween
	local t = TweenService:Create(instance, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), goal)
	t:Play()
	return t
end

-- Leichtes Kamera-Ruckeln während der Fahrt
local function shakeCamera(seconds: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local h = humanoid :: Humanoid
	local ends = os.clock() + seconds
	task.spawn(function()
		while os.clock() < ends and h.Parent do
			h.CameraOffset = Vector3.new(math.random(-10, 10) / 100, math.random(-10, 10) / 100, 0)
			task.wait(0.03)
		end
		h.CameraOffset = Vector3.zero
	end)
end

local function playTransition(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	transitionTitle.Text = tostring(payload.Title or "")
	transitionSub.Text = tostring(payload.Subtitle or "")
	transitionGui.Enabled = true
	waitingForArrival = true
	shakeCamera(FADE_IN)
	tween(blackout, FADE_IN, { BackgroundTransparency = 0 })
	tween(transitionTitle, FADE_IN, { TextTransparency = 0 })
	tween(transitionSub, FADE_IN, { TextTransparency = 0 })

	-- Falls die Ankunft ausbleibt (Fehler), nach kurzer Zeit wieder aufblenden
	task.delay(4, function()
		if waitingForArrival then
			waitingForArrival = false
			tween(blackout, FADE_OUT, { BackgroundTransparency = 1 })
			tween(transitionTitle, FADE_OUT, { TextTransparency = 1 })
			tween(transitionSub, FADE_OUT, { TextTransparency = 1 })
		end
	end)
end

-- Unter Tage keinen Oberflächen-Dunst und kein Himmelslicht (nur lokal für diesen Spieler).
local surfaceLighting: { [string]: any }? = nil
local function applyAmbience(inMine: boolean)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if inMine then
		if not surfaceLighting then
			surfaceLighting = {
				Ambient = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
				Density = if atmosphere then atmosphere.Density else nil,
				Haze = if atmosphere then atmosphere.Haze else nil,
			}
		end
		Lighting.Ambient = Color3.fromRGB(70, 66, 62)
		Lighting.OutdoorAmbient = Color3.fromRGB(60, 58, 56)
		if atmosphere then
			atmosphere.Density = 0
			atmosphere.Haze = 0
		end
	elseif surfaceLighting then
		local saved = surfaceLighting :: { [string]: any }
		Lighting.Ambient = saved.Ambient
		Lighting.OutdoorAmbient = saved.OutdoorAmbient
		if atmosphere and saved.Density ~= nil then
			atmosphere.Density = saved.Density
			atmosphere.Haze = saved.Haze
		end
		surfaceLighting = nil
	end
end

local function onLocation(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.Location) ~= "string" then
		return
	end
	location = payload.Location
	local mine = Mines.Get(location)
	applyAmbience(mine ~= nil)
	if mine then
		local ore = Ores.Get(mine.OreId)
		locationLabel.Text = string.format("MINE SHAFT %02d  ·  %s", mine.Number, if ore then string.upper(ore.DisplayName) else "")
		locationLabel.Visible = true
	else
		locationLabel.Visible = false
	end
	closeMenu()

	if waitingForArrival then
		waitingForArrival = false
		task.delay(0.3, function()
			tween(transitionTitle, FADE_OUT, { TextTransparency = 1 })
			tween(transitionSub, FADE_OUT, { TextTransparency = 1 })
			local t = tween(blackout, FADE_OUT, { BackgroundTransparency = 1 })
			t.Completed:Wait()
			if not waitingForArrival then
				transitionGui.Enabled = false
			end
		end)
	end
end

function ElevatorController.Init()
	buildMenu()
	buildTransition()
	Net.on("OpenElevatorMenu", openMenu)
	Net.on("ElevatorTransition", playTransition)
	Net.on("LocationChanged", onLocation)
end

function ElevatorController.Start() end

-- Aktueller Ort ("surface" oder Mine-ID), z. B. für Mining-Controller in Schritt 2c.
function ElevatorController.GetLocation(): string
	return location
end

return ElevatorController
