--!strict
-- Wegweiser für neue Spieler ohne Grundstück (Felix 2026-11-19, D-094):
--   * über jedem freien Grundstück steht groß „CLAIM“ (auch auf große Entfernung sichtbar)
--   * eine dezente gepunktete Linie mit Wellen-Animation führt erst zum eigenen Starterauto und,
--     sobald man drinsitzt, zum nächsten freien Grundstück (Claim-Knopf)
-- Alles nur lokal auf dem Client; verschwindet, sobald der Spieler ein Grundstück hat.
-- Positionen der freien Grundstücke kommen aus ReplicatedStorage.FreePlots (PlotService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlotController = require(script.Parent.PlotController)

local ClaimGuideController = {}

local player = Players.LocalPlayer

local DOT_SPACING = 5
local MAX_DOTS = 180
local DOT_SIZE = 0.5
local DOT_COLOR = Color3.fromRGB(255, 236, 160)
-- Ab dieser Nähe zum Auto führt die Linie direkt zum Grundstück
local NEAR_CAR = 10
local SIGN_HEIGHT = 45

local folder: Folder? = nil
local dots: { BasePart } = {}
local dotDistance: { number } = {}
local signs: { [Instance]: { frame: Frame, world: Vector3 } } = {}
local active = false
local lastPathUpdate = 0

local function getFolder(): Folder
	local f = folder
	if not f or not f.Parent then
		f = Instance.new("Folder")
		f.Name = "ClaimGuide"
		f.Parent = workspace
		folder = f
	end
	return f :: Folder
end

local function freePlots(): { Vector3Value }
	local list = {}
	local f = ReplicatedStorage:FindFirstChild("FreePlots")
	if f then
		for _, v in f:GetChildren() do
			if v:IsA("Vector3Value") then
				table.insert(list, v)
			end
		end
	end
	return list
end

-- Großes Schild über einem freien Grundstück: als Bildschirm-Anzeige, die jedes Bild auf die
-- Position über dem Grundstück gesetzt wird (BillboardGuis werden auf große Entfernung nicht gezeigt)
local function screenGui(): ScreenGui
	local pg = player:WaitForChild("PlayerGui")
	local g = pg:FindFirstChild("ClaimGuideGui")
	if not g then
		local sg = Instance.new("ScreenGui")
		sg.Name = "ClaimGuideGui"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
		sg.DisplayOrder = -1
		sg.Parent = pg
		g = sg
	end
	return g :: ScreenGui
end

local function addSign(marker: Vector3Value)
	if signs[marker] then
		return
	end
	local frame = Instance.new("Frame")
	frame.Name = "ClaimSign"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(240, 100)
	frame.Visible = false
	frame.Parent = screenGui()

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.68)
	title.Font = Enum.Font.GothamBlack
	title.Text = "CLAIM"
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(110, 230, 140)
	title.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(10, 30, 15)
	stroke.Parent = title

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0, 0.68)
	sub.Size = UDim2.fromScale(1, 0.3)
	sub.Font = Enum.Font.GothamBold
	local plotId = marker:GetAttribute("PlotId")
	sub.Text = if typeof(plotId) == "number" then `FREE PLOT {plotId}` else "FREE PLOT"
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(240, 242, 245)
	sub.Parent = frame
	local stroke2 = Instance.new("UIStroke")
	stroke2.Thickness = 2
	stroke2.Color = Color3.fromRGB(10, 30, 15)
	stroke2.Parent = sub

	signs[marker] = { frame = frame, world = marker.Value + Vector3.new(0, SIGN_HEIGHT, 0) }
end

local function removeSign(marker: Instance)
	local s = signs[marker]
	if s then
		s.frame:Destroy()
		signs[marker] = nil
	end
end

-- Schilder auf den Bildschirm setzen: nah größer, fern kleiner (aber immer lesbar)
local function placeSigns()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	for _, s in signs do
		local p, onScreen = cam:WorldToViewportPoint(s.world)
		if onScreen and p.Z > 0 then
			local scale = math.clamp(1.6 - p.Z / 1000, 0.6, 1.6)
			s.frame.Size = UDim2.fromOffset(240 * scale, 100 * scale)
			s.frame.Position = UDim2.fromOffset(p.X, p.Y)
			s.frame.Visible = true
		else
			s.frame.Visible = false
		end
	end
end

local function ownCar(): Model?
	local f = workspace:FindFirstChild("Vehicles")
	if not f then
		return nil
	end
	for _, m in f:GetChildren() do
		if m:IsA("Model") and m:GetAttribute("OwnerUserId") == player.UserId then
			return m
		end
	end
	return nil
end

local function seatedInVehicle(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	return seat ~= nil and seat:IsA("VehicleSeat")
end

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function nearestFree(from: Vector3): Vector3?
	local best, bestD = nil, math.huge
	for _, m in freePlots() do
		local d = (m.Value - from).Magnitude
		if d < bestD then
			best, bestD = m.Value, d
		end
	end
	return best
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function groundY(x: number, z: number, fallback: number): number
	local exclude: { Instance } = { getFolder() }
	if player.Character then
		table.insert(exclude, player.Character)
	end
	local vehicles = workspace:FindFirstChild("Vehicles")
	if vehicles then
		table.insert(exclude, vehicles)
	end
	rayParams.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(Vector3.new(x, fallback + 60, z), Vector3.new(0, -200, 0), rayParams)
	return if hit then hit.Position.Y else fallback
end

local function hideDots(from: number)
	for i = from, #dots do
		dots[i].Transparency = 1
	end
end

-- Punkte entlang der Strecke a → b neu setzen
local function layPath(a: Vector3, b: Vector3)
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local length = flat.Magnitude
	local dir = if length > 0 then flat / length else Vector3.zero
	local count = math.min(MAX_DOTS, math.floor(length / DOT_SPACING))
	for i = 1, count do
		local dot = dots[i]
		if not dot then
			dot = Instance.new("Part")
			dot.Name = "Dot"
			dot.Shape = Enum.PartType.Ball
			dot.Anchored = true
			dot.CanCollide = false
			dot.CanQuery = false
			dot.CanTouch = false
			dot.CastShadow = false
			dot.Material = Enum.Material.Neon
			dot.Color = DOT_COLOR
			dot.Size = Vector3.one * DOT_SIZE
			dot.Parent = getFolder()
			dots[i] = dot
		end
		local d = i * DOT_SPACING
		local x, z = a.X + dir.X * d, a.Z + dir.Z * d
		dot.Position = Vector3.new(x, groundY(x, z, a.Y - 3) + 0.6, z)
		dotDistance[i] = d
	end
	hideDots(count + 1)
	for i = count + 1, #dotDistance do
		dotDistance[i] = nil
	end
end

local function updatePath()
	local from = rootPosition()
	if not from then
		hideDots(1)
		return
	end
	local car = ownCar()
	local target: Vector3? = nil
	if car and not seatedInVehicle() and (car:GetPivot().Position - from).Magnitude > NEAR_CAR then
		target = car:GetPivot().Position
	else
		target = nearestFree(from)
	end
	if target then
		layPath(from, target)
	else
		hideDots(1)
	end
end

-- Welle: Punkte werden der Reihe nach größer/heller und laufen Richtung Ziel
local function animate()
	local t = os.clock()
	for i, d in dotDistance do
		local dot = dots[i]
		if dot then
			local wave = 0.5 + 0.5 * math.sin(t * 5 - d * 0.12)
			dot.Size = Vector3.one * (DOT_SIZE * (0.6 + 0.6 * wave))
			dot.Transparency = 0.55 - 0.4 * wave
		end
	end
end

local function setActive(on: boolean)
	if active == on then
		return
	end
	active = on
	if not on then
		for marker in signs do
			removeSign(marker)
		end
		hideDots(1)
		table.clear(dotDistance)
	else
		for _, m in freePlots() do
			addSign(m)
		end
	end
end

function ClaimGuideController.Init() end

function ClaimGuideController.Start()
	local f = ReplicatedStorage:WaitForChild("FreePlots", 30)
	if f then
		f.ChildAdded:Connect(function(child)
			if active and child:IsA("Vector3Value") then
				addSign(child)
			end
		end)
		f.ChildRemoved:Connect(removeSign)
	end
	PlotController.Assigned:Connect(function()
		setActive(false)
	end)
	setActive(PlotController.GetPlotId() == nil)
	RunService.Heartbeat:Connect(function()
		if not active then
			return
		end
		if PlotController.GetPlotId() ~= nil then
			setActive(false)
			return
		end
		local now = os.clock()
		if now - lastPathUpdate > 0.5 then
			lastPathUpdate = now
			updatePath()
		end
		animate()
		placeSigns()
	end)
end

return ClaimGuideController
