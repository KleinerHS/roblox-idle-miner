--!strict
-- Studio-Plugin "Idle Miner Preview": baut die Spielwelt im Bearbeitungsmodus auf und entfernt
-- sie wieder. Nutzt dieselben World-Builder wie der Server (src/server/World), damit die
-- Vorschau immer dem Code entspricht. Kein Spielcode: wird nur als lokales Plugin gebaut
-- (plugin.project.json) und nie ins Spiel gespeichert.
--
-- Die Vorschau liegt in Workspace.EditPreview mit Archivable = false:
--   - wird nicht in die Place-Datei gespeichert,
--   - wird beim Play nicht mitkopiert (der Server baut die echte Welt selbst).
--
-- Frische Module bei jedem Aufbau: require() cached pro ModuleScript-Instanz. Deshalb
-- werden World und Shared geklont und die Klone required. Weil die Builder Shared über
-- ReplicatedStorage:WaitForChild("Shared") finden, wird der Shared-Klon für die Dauer des
-- (yield-freien) Aufbaus kurz an die Stelle des Originals gesetzt und danach zurückgetauscht.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local PREVIEW_NAME = "EditPreview"
-- Plot, der in der Vorschau voll ausgebaut gezeigt wird (alle anderen leer)
local SHOWCASE_PLOT = 1

-- Plugin läuft auch im Play-Modus mit; dort nichts anzeigen
if RunService:IsRunning() then
	return
end

local toolbar = plugin:CreateToolbar("Idle Miner")
local button = toolbar:CreateButton(
	"IdleMinerWorldPreview",
	"Baut die Spielwelt im Bearbeitungsmodus auf bzw. entfernt sie wieder",
	"",
	"World Preview"
)
button.ClickableWhenViewportHidden = true

local function existing(): Instance?
	return workspace:FindFirstChild(PREVIEW_NAME)
end

-- Archivable = false auf allen Teilen: nichts davon landet in der Place-Datei
local function makeNonArchivable(root: Instance)
	root.Archivable = false
	for _, child in root:GetDescendants() do
		child.Archivable = false
	end
end

local function build(folder: Folder, world: Instance, shared: Instance)
	local GameConfig = require(shared:FindFirstChild("Config"):FindFirstChild("GameConfig") :: ModuleScript) :: any
	local BuildSteps = require(shared:FindFirstChild("Definitions"):FindFirstChild("BuildSteps") :: ModuleScript) :: any
	local Mines = require(shared:FindFirstChild("Definitions"):FindFirstChild("Mines") :: ModuleScript) :: any
	local PlotBuilder = require(world:FindFirstChild("PlotBuilder") :: ModuleScript) :: any
	local BuildTemplates = require(world:FindFirstChild("BuildTemplates") :: ModuleScript) :: any
	local MineShaftBuilder = require(world:FindFirstChild("MineShaftBuilder") :: ModuleScript) :: any
	local SellingBuilder = require(world:FindFirstChild("SellingBuilder") :: ModuleScript) :: any
	local EquipmentShopBuilder = require(world:FindFirstChild("EquipmentShopBuilder") :: ModuleScript) :: any
	local MachineShopBuilder = require(world:FindFirstChild("MachineShopBuilder") :: ModuleScript) :: any

	-- Plots (wie PlotService), Plot 1 mit allen Bauschritten (wie BuildingService)
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = folder
	for plotId = 1, GameConfig.MaxPlots do
		local plot = PlotBuilder.build(plots, plotId)
		if plotId == SHOWCASE_PLOT then
			PlotBuilder.setSign(plot, "⛏", `Plot {plotId}\nPreview Mining Co.`, nil)
			local buildings = plot:FindFirstChild("Buildings") or plot
			for _, step in BuildSteps.List do
				local model = BuildTemplates.build(step.Id, PlotBuilder.getPlotCFrame(plotId))
				if model then
					model.Parent = buildings
				end
			end
		else
			PlotBuilder.setSign(plot, "", `Plot {plotId}\nFree`, nil)
		end
	end
	PlotBuilder.buildCenterPlaceholder(plots)

	-- Stadtmitte (wie SellingService/ShopService: Verkauf, Equipment, Machines)
	local center = Instance.new("Folder")
	center.Name = "Center"
	center.Parent = folder
	SellingBuilder.build(center)
	EquipmentShopBuilder.build(center)
	MachineShopBuilder.build(center)

	-- Minenräume unter den Plots (wie ElevatorService), mit Mine 01 eingerichtet
	local shafts = Instance.new("Folder")
	shafts.Name = "MineShafts"
	shafts.Parent = folder
	local first = Mines.GetByNumber(1)
	for plotId = 1, GameConfig.MaxPlots do
		local room = MineShaftBuilder.build(shafts, plotId, PlotBuilder.getPlotCFrame(plotId))
		if first then
			MineShaftBuilder.configure(room, first)
		end
	end
end

local function create()
	local world = ServerScriptService:FindFirstChild("World")
	local original = ReplicatedStorage:FindFirstChild("Shared")
	if not (world and original) then
		warn("[Idle Miner Preview] ServerScriptService.World oder ReplicatedStorage.Shared fehlt – ist Rojo verbunden?")
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = PREVIEW_NAME

	-- Klone für frische Module (siehe Kopfkommentar)
	local sharedClone = original:Clone()
	local worldClone = world:Clone()
	local holder = Instance.new("Folder")
	holder.Name = "PreviewModules"
	worldClone.Parent = holder

	local recording = ChangeHistoryService:TryBeginRecording("Idle Miner World Preview")

	-- Tausch ohne Yield dazwischen; Original wird in jedem Fall zurückgesetzt
	original.Parent = nil
	sharedClone.Parent = ReplicatedStorage
	local ok, err = pcall(build, folder, worldClone, sharedClone)
	sharedClone:Destroy()
	original.Parent = ReplicatedStorage
	holder:Destroy()

	if ok then
		makeNonArchivable(folder)
		folder.Parent = workspace
		print("[Idle Miner Preview] Welt aufgebaut (Workspace.EditPreview, wird nicht gespeichert)")
	else
		folder:Destroy()
		warn(`[Idle Miner Preview] Aufbau fehlgeschlagen: {err}`)
	end

	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end
end

local function remove()
	local folder = existing()
	if folder then
		folder:Destroy()
		print("[Idle Miner Preview] Welt entfernt")
	end
end

local function refreshButton()
	button:SetActive(existing() ~= nil)
end

button.Click:Connect(function()
	if existing() then
		remove()
	else
		create()
	end
	refreshButton()
end)

workspace.ChildAdded:Connect(refreshButton)
workspace.ChildRemoved:Connect(refreshButton)
refreshButton()
