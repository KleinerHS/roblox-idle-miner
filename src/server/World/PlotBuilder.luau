--!strict
-- Erzeugt die 6 Plots als PLATZHALTER-Geometrie aus LayoutConfig (Boden, Hallen-Bodenplatte
-- mit Bereichsmarkierungen, Zaun mit Zufahrt, Firmenschild, Spawnpunkt, Straße zur Mitte).
-- Wird ersetzt, sobald die echte Map als Modell unter assets/ existiert (docs/19). Die Struktur
-- (Attribute, Tags, Namen) bleibt dabei gleich, damit die Services nicht umgebaut werden müssen.
--
-- Struktur je Plot:
--   Workspace.Plots.Plot_<id>   (Model, Tag "Plot", Attribute PlotId, OwnerUserId)
--     Floor, HallFloor, Markings (Folder), Fence_*, Sign, SignAccent, SpawnPoint, Road,
--     Buildings (Folder, von BuildingService befüllt)

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local LayoutConfig = require(Shared.Config.LayoutConfig)

local PlotBuilder = {}

local PLOT_TAG = "Plot"

local COLOR_GRASS = Color3.fromRGB(96, 140, 72)
local COLOR_CONCRETE = Color3.fromRGB(150, 150, 146)
local COLOR_MARKING = Color3.fromRGB(232, 184, 52)
local COLOR_FENCE = Color3.fromRGB(70, 66, 60)
local COLOR_ROAD = Color3.fromRGB(58, 60, 64)
local COLOR_SIGN = Color3.fromRGB(40, 44, 52)
local COLOR_SIGN_ACCENT_NEUTRAL = Color3.fromRGB(110, 116, 128)

local MARKING_WIDTH = 0.8

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanTouch = false
	part.Parent = parent
	return part
end

-- CFrame der Plotmitte auf Bodenhöhe, -Z zeigt zur Map-Mitte.
function PlotBuilder.getPlotCFrame(plotId: number): CFrame
	local angle = math.rad(LayoutConfig.PlotAngles[plotId])
	local center = LayoutConfig.MapCenter
	local position = center + Vector3.new(math.cos(angle), 0, -math.sin(angle)) * LayoutConfig.PlotRingRadius
	position = Vector3.new(position.X, LayoutConfig.GroundY, position.Z)
	return CFrame.lookAt(position, Vector3.new(center.X, LayoutConfig.GroundY, center.Z))
end

local function buildFence(model: Model, origin: CFrame)
	local size = LayoutConfig.PlotSize
	local h = LayoutConfig.FenceHeight
	local t = LayoutConfig.FenceThickness
	local halfX = size.X / 2
	local halfZ = size.Y / 2
	local y = 1 + h / 2

	makePart("Fence_Back", Vector3.new(size.X, h, t), origin * CFrame.new(0, y, halfZ), COLOR_FENCE, Enum.Material.Metal, model)
	makePart("Fence_Left", Vector3.new(t, h, size.Y), origin * CFrame.new(halfX, y, 0), COLOR_FENCE, Enum.Material.Metal, model)
	makePart("Fence_Right", Vector3.new(t, h, size.Y), origin * CFrame.new(-halfX, y, 0), COLOR_FENCE, Enum.Material.Metal, model)

	-- Vorderseite (-Z) mit Zufahrtslücke vor dem Rolltor
	local gapCenter = LayoutConfig.DoorCenterX
	local gapHalf = LayoutConfig.EntranceWidth / 2
	local leftStart, leftEnd = gapCenter + gapHalf, halfX
	local rightStart, rightEnd = -halfX, gapCenter - gapHalf
	makePart(
		"Fence_FrontLeft",
		Vector3.new(leftEnd - leftStart, h, t),
		origin * CFrame.new((leftStart + leftEnd) / 2, y, -halfZ),
		COLOR_FENCE,
		Enum.Material.Metal,
		model
	)
	makePart(
		"Fence_FrontRight",
		Vector3.new(rightEnd - rightStart, h, t),
		origin * CFrame.new((rightStart + rightEnd) / 2, y, -halfZ),
		COLOR_FENCE,
		Enum.Material.Metal,
		model
	)
end

local function buildSign(model: Model, origin: CFrame, plotId: number)
	local halfZ = LayoutConfig.PlotSize.Y / 2
	-- Firmenschild vorne rechts neben der Zufahrt (docs/04 §8), Schrift zeigt zur Straße (-Z)
	local signX = LayoutConfig.DoorCenterX - (LayoutConfig.EntranceWidth / 2 + 14)
	local signCFrame = origin * CFrame.new(signX, 5.5, -halfZ - 3)
	local sign = makePart("Sign", Vector3.new(18, 7, 0.6), signCFrame, COLOR_SIGN, Enum.Material.SmoothPlastic, model)
	makePart("SignPost", Vector3.new(0.8, 3, 0.8), origin * CFrame.new(signX, 1.5, -halfZ - 3), COLOR_FENCE, Enum.Material.Metal, model)
	makePart(
		"SignAccent",
		Vector3.new(18, 0.6, 0.7),
		signCFrame * CFrame.new(0, -3.5, 0),
		COLOR_SIGN_ACCENT_NEUTRAL,
		Enum.Material.SmoothPlastic,
		model
	)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = sign

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.06, 0)
	padding.PaddingBottom = UDim.new(0.06, 0)
	padding.Parent = gui

	local logo = Instance.new("TextLabel")
	logo.Name = "Logo"
	logo.Size = UDim2.fromScale(0.28, 1)
	logo.BackgroundTransparency = 1
	logo.TextScaled = true
	logo.Font = Enum.Font.GothamBold
	logo.TextColor3 = Color3.fromRGB(240, 242, 245)
	logo.Text = ""
	logo.Parent = gui

	local name = Instance.new("TextLabel")
	name.Name = "CompanyName"
	name.Position = UDim2.fromScale(0.3, 0)
	name.Size = UDim2.fromScale(0.7, 1)
	name.BackgroundTransparency = 1
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = Color3.fromRGB(240, 242, 245)
	name.Text = `Plot {plotId}\nFree`
	name.Parent = gui
end

local function buildMarkings(model: Model, origin: CFrame)
	local folder = Instance.new("Folder")
	folder.Name = "Markings"
	folder.Parent = model
	local y = LayoutConfig.HallFloorTop + 0.05
	for zoneName, zone in LayoutConfig.HallZones do
		local c, s = zone.Center, zone.Size
		local w = MARKING_WIDTH
		local parts = {
			{ Vector3.new(s.X, 0.1, w), Vector3.new(c.X, y, c.Y + s.Y / 2) },
			{ Vector3.new(s.X, 0.1, w), Vector3.new(c.X, y, c.Y - s.Y / 2) },
			{ Vector3.new(w, 0.1, s.Y), Vector3.new(c.X + s.X / 2, y, c.Y) },
			{ Vector3.new(w, 0.1, s.Y), Vector3.new(c.X - s.X / 2, y, c.Y) },
		}
		for index, entry in parts do
			local part = makePart(`{zoneName}_{index}`, entry[1], origin * CFrame.new(entry[2]), COLOR_MARKING, Enum.Material.SmoothPlastic, folder)
			part.CanCollide = false
			part.CanQuery = false
		end
	end
end

local function buildRoad(model: Model, origin: CFrame)
	-- Gerade Zufahrt vom Plot-Eingang bis zum Rand der Platzhalter-Mitte (docs/04 §33)
	local halfZ = LayoutConfig.PlotSize.Y / 2
	local length = LayoutConfig.PlotRingRadius - halfZ - LayoutConfig.CenterPlazaRadius
	if length <= 0 then
		return
	end
	makePart(
		"Road",
		Vector3.new(LayoutConfig.RoadWidth, 1, length),
		origin * CFrame.new(LayoutConfig.DoorCenterX, 0.55, -halfZ - length / 2),
		COLOR_ROAD,
		Enum.Material.Asphalt,
		model
	)
end

function PlotBuilder.getDefaultSpawnCFrame(plotId: number): CFrame
	return PlotBuilder.getPlotCFrame(plotId) * CFrame.new(LayoutConfig.SpawnOffset)
end

function PlotBuilder.build(parent: Instance, plotId: number): Model
	local origin = PlotBuilder.getPlotCFrame(plotId)
	local size = LayoutConfig.PlotSize

	local model = Instance.new("Model")
	model.Name = `Plot_{plotId}`
	model:SetAttribute("PlotId", plotId)
	model:SetAttribute("OwnerUserId", 0)

	local floor = makePart("Floor", Vector3.new(size.X, 1, size.Y), origin * CFrame.new(0, 0.5, 0), COLOR_GRASS, Enum.Material.Grass, model)
	model.PrimaryPart = floor

	local hall = LayoutConfig.HallSize
	local hallOffset = LayoutConfig.HallOffset
	makePart(
		"HallFloor",
		Vector3.new(hall.X, 0.4, hall.Y),
		origin * CFrame.new(hallOffset.X, LayoutConfig.HallFloorTop - 0.2, hallOffset.Y),
		COLOR_CONCRETE,
		Enum.Material.Concrete,
		model
	)

	buildMarkings(model, origin)
	buildFence(model, origin)
	buildSign(model, origin, plotId)
	buildRoad(model, origin)

	local spawnPoint = makePart(
		"SpawnPoint",
		Vector3.new(4, 1, 4),
		PlotBuilder.getDefaultSpawnCFrame(plotId),
		COLOR_CONCRETE,
		Enum.Material.SmoothPlastic,
		model
	)
	spawnPoint.Transparency = 1
	spawnPoint.CanCollide = false
	spawnPoint.CanQuery = false

	local buildings = Instance.new("Folder")
	buildings.Name = "Buildings"
	buildings.Parent = model

	-- Plots sollen beim Streaming nicht teilweise entladen werden (Schild, Buttons, Spawn).
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	CollectionService:AddTag(model, PLOT_TAG)
	model.Parent = parent
	return model
end

-- Platzhalter-Mitte (rund), bis die zentrale Service-Area gebaut wird.
function PlotBuilder.buildCenterPlaceholder(parent: Instance)
	local center = LayoutConfig.MapCenter
	local diameter = LayoutConfig.CenterPlazaRadius * 2
	local plaza = Instance.new("Part")
	plaza.Name = "CenterPlaceholder"
	plaza.Shape = Enum.PartType.Cylinder
	plaza.Anchored = true
	plaza.CanTouch = false
	plaza.Size = Vector3.new(1, diameter, diameter)
	plaza.CFrame = CFrame.new(center.X, LayoutConfig.GroundY + 0.5, center.Z) * CFrame.Angles(0, 0, math.rad(90))
	plaza.Color = COLOR_ROAD
	plaza.Material = Enum.Material.Asphalt
	plaza.Parent = parent
end

function PlotBuilder.buildAll(): Folder
	local existing = workspace:FindFirstChild("Plots")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	for plotId = 1, GameConfig.MaxPlots do
		PlotBuilder.build(folder, plotId)
	end
	PlotBuilder.buildCenterPlaceholder(folder)
	folder.Parent = workspace
	return folder
end

-- Firmenschild setzen. `name` muss bereits durch den Roblox-Textfilter gelaufen sein.
function PlotBuilder.setSign(plot: Model, logoGlyph: string, name: string, accent: Color3?)
	local sign = plot:FindFirstChild("Sign")
	local gui = sign and sign:FindFirstChild("SignGui")
	if gui then
		local logo = gui:FindFirstChild("Logo")
		local label = gui:FindFirstChild("CompanyName")
		if logo and logo:IsA("TextLabel") then
			logo.Text = logoGlyph
		end
		if label and label:IsA("TextLabel") then
			label.Text = name
		end
	end
	local accentPart = plot:FindFirstChild("SignAccent")
	if accentPart and accentPart:IsA("BasePart") then
		accentPart.Color = accent or COLOR_SIGN_ACCENT_NEUTRAL
		accentPart.Material = if accent then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

function PlotBuilder.setSpawn(plot: Model, cframe: CFrame)
	local spawnPoint = plot:FindFirstChild("SpawnPoint")
	if spawnPoint and spawnPoint:IsA("BasePart") then
		spawnPoint.CFrame = cframe
	end
end

return table.freeze(PlotBuilder)
