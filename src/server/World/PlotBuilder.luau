--!strict
-- Erzeugt die 6 Plots als PLATZHALTER-Geometrie aus LayoutConfig (Boden, Hallenfläche,
-- Zaun mit Zufahrt, Schild, Spawnpunkt, Straße zur Mitte). Wird ersetzt, sobald die echte
-- Map als Modell unter assets/ existiert (docs/19). Die Struktur (Attribute, Tags, Namen)
-- bleibt dabei gleich, damit PlotService nicht umgebaut werden muss.
--
-- Struktur je Plot:
--   Workspace.Plots.Plot_<id>   (Model, Tag "Plot", Attribute PlotId, OwnerUserId)
--     Floor, HallFloor, Fence_*, Sign (SurfaceGui), SpawnPoint, Road

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local LayoutConfig = require(Shared.Config.LayoutConfig)

local PlotBuilder = {}

local PLOT_TAG = "Plot"

local COLOR_GRASS = Color3.fromRGB(96, 140, 72)
local COLOR_CONCRETE = Color3.fromRGB(150, 150, 146)
local COLOR_FENCE = Color3.fromRGB(70, 66, 60)
local COLOR_ROAD = Color3.fromRGB(58, 60, 64)
local COLOR_SIGN = Color3.fromRGB(40, 44, 52)

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
	local position = center
		+ Vector3.new(math.cos(angle), 0, -math.sin(angle)) * LayoutConfig.PlotRingRadius
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

	-- Rückseite (+Z) und Seiten
	makePart("Fence_Back", Vector3.new(size.X, h, t), origin * CFrame.new(0, y, halfZ), COLOR_FENCE, Enum.Material.Metal, model)
	makePart("Fence_Left", Vector3.new(t, h, size.Y), origin * CFrame.new(halfX, y, 0), COLOR_FENCE, Enum.Material.Metal, model)
	makePart("Fence_Right", Vector3.new(t, h, size.Y), origin * CFrame.new(-halfX, y, 0), COLOR_FENCE, Enum.Material.Metal, model)

	-- Vorderseite (-Z) mit Zufahrtslücke in der Mitte
	local gap = LayoutConfig.EntranceWidth
	local segment = (size.X - gap) / 2
	local offset = gap / 2 + segment / 2
	makePart("Fence_FrontLeft", Vector3.new(segment, h, t), origin * CFrame.new(offset, y, -halfZ), COLOR_FENCE, Enum.Material.Metal, model)
	makePart("Fence_FrontRight", Vector3.new(segment, h, t), origin * CFrame.new(-offset, y, -halfZ), COLOR_FENCE, Enum.Material.Metal, model)
end

local function buildSign(model: Model, origin: CFrame, plotId: number): TextLabel
	local halfZ = LayoutConfig.PlotSize.Y / 2
	-- Schild vorne rechts neben der Zufahrt, Text zeigt Richtung Straße (-Z)
	local signX = -(LayoutConfig.EntranceWidth / 2 + 12)
	local sign = makePart(
		"Sign",
		Vector3.new(16, 6, 0.6),
		origin * CFrame.new(signX, 5, -halfZ - 3),
		COLOR_SIGN,
		Enum.Material.SmoothPlastic,
		model
	)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(240, 242, 245)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = `Plot {plotId}\nFrei`
	label.Parent = gui

	return label
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
		origin * CFrame.new(0, 0.55, -halfZ - length / 2),
		COLOR_ROAD,
		Enum.Material.Asphalt,
		model
	)
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
		origin * CFrame.new(hallOffset.X, 1.2, hallOffset.Y),
		COLOR_CONCRETE,
		Enum.Material.Concrete,
		model
	)

	buildFence(model, origin)
	buildSign(model, origin, plotId)
	buildRoad(model, origin)

	local spawnPoint = makePart(
		"SpawnPoint",
		Vector3.new(4, 1, 4),
		origin * CFrame.new(LayoutConfig.SpawnOffset),
		COLOR_CONCRETE,
		Enum.Material.SmoothPlastic,
		model
	)
	spawnPoint.Transparency = 1
	spawnPoint.CanCollide = false
	spawnPoint.CanQuery = false

	-- Plots sollen beim Streaming nicht teilweise entladen werden (Besitzschild, Spawn).
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

function PlotBuilder.setSignText(plot: Model, text: string)
	local sign = plot:FindFirstChild("Sign")
	local gui = sign and sign:FindFirstChild("SignGui")
	local label = gui and gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

return table.freeze(PlotBuilder)
