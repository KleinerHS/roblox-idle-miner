--!strict
-- Förderbänder (docs/06 §22–27, docs/10 §34–38, D-024). Zwei feste Plätze, sobald der
-- Schmelzer steht:
--   StorageToSmelter – schmelzbares Erz vom Lager in den Trichter (bevorzugtes Erz zuerst,
--                      sonst wertvollstes; nur so viel, wie in den Trichter passt)
--   SmelterToStorage – fertige Barren aus der Ablage ins Lager (so weit Platz ist)
-- Durchsatz je Band aus der Definition (Einheiten/Minute). Ein Band läuft sichtbar nur, wenn
-- es tatsächlich Material bewegt (docs/06 §25). Jeder Transfer ist eine einzige
-- Profiländerung, ohne Yield dazwischen.
-- Einsetzen/Entfernen am Pfosten des Platzes ("PLACE CONVEYOR HERE"); entfernt = Inventar.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Conveyors = require(Shared.Definitions.Conveyors)
local Materials = require(Shared.Definitions.Materials)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local SmelterLogic = require(Shared.Util.SmelterLogic)
local Log = require(Shared.Util.Log)

local ConveyorBuilder = require(script.Parent.Parent.World.ConveyorBuilder)
local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local BuildingService = require(script.Parent.BuildingService)
local RemoteService = require(script.Parent.RemoteService)
local SmelterService = require(script.Parent.SmelterService)

local TAG = "ConveyorService"
local STEP = "build_smelter"
local POST_DISTANCE = 14

local ConveyorService = {}

-- Laufzeit: Bruchteile je Band (Durchsatz < 1/s), sichtbare Modelle je Spieler/Platz
local accumulators: { [Player]: { [string]: number } } = {}
local visuals: { [Player]: { [string]: Model } } = {}

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, n in items do
		total += n
	end
	return total
end

local function conveyorAt(data: Types.PlayerData, slot: string): Types.ConveyorRecord?
	for _, c in data.Machines.Conveyors do
		if c.Slot == slot then
			return c
		end
	end
	return nil
end

local function slotWorldPoints(player: Player, slot: string): ({ Vector3 }?, number)
	local plotId = PlotService.GetPlotId(player)
	local path = LayoutConfig.ConveyorPaths[slot]
	if not (plotId and path) then
		return nil, 0
	end
	local plotCF = PlotBuilder.getPlotCFrame(plotId)
	local floorY = (plotCF * CFrame.new(0, LayoutConfig.HallFloorTop, 0)).Position.Y
	local points = {}
	for _, p in path do
		table.insert(points, (plotCF * CFrame.new(p.X, LayoutConfig.HallFloorTop + p.Y, p.Z)).Position)
	end
	return points, floorY
end

-- Pfosten mit Schild und Prompt am Startpunkt eines Platzes
local function buildPost(parent: Instance, slot: string, start: Vector3, floorY: number, nextPoint: Vector3)
	local side = CFrame.lookAt(Vector3.new(start.X, floorY, start.Z), Vector3.new(nextPoint.X, floorY, nextPoint.Z)) * CFrame.new(if slot == "SmelterToStorage" then -2.6 else 2.6, 0, 0)
	local post = Instance.new("Part")
	post.Name = `ConveyorPost_{slot}`
	post.Anchored = true
	post.CanTouch = false
	post.Size = Vector3.new(0.4, 3.6, 0.4)
	post.CFrame = side * CFrame.new(0, 1.8, 0)
	post.Color = Color3.fromRGB(42, 44, 48)
	post.Material = Enum.Material.Metal
	post.Parent = parent
	local sign = Instance.new("Part")
	sign.Name = `ConveyorSign_{slot}`
	sign.Anchored = true
	sign.CanTouch = false
	sign.CanCollide = false
	sign.Size = Vector3.new(2, 1.1, 0.15)
	sign.CFrame = side * CFrame.new(0, 3.9, 0)
	sign.Color = Color3.fromRGB(236, 182, 40)
	sign.Material = Enum.Material.SmoothPlastic
	sign.Parent = parent
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ConveyorPrompt"
	prompt.ActionText = "Conveyor"
	prompt.ObjectText = Conveyors.SlotNames[slot]
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("ConveyorSlot", slot)
	prompt.Parent = sign
end

-- Modelle (Vorschau bzw. eingesetztes Band) für alle Plätze neu aufbauen
local function refreshVisuals(player: Player)
	local data = DataService.Get(player)
	local smelter = BuildingService.GetModel(player, STEP)
	for _, model in visuals[player] or {} do
		model:Destroy()
	end
	visuals[player] = {}
	if not (data and smelter) then
		return
	end
	local folder = smelter:FindFirstChild("Conveyors")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Conveyors"
		folder.Parent = smelter
	end
	for _, slot in Conveyors.Slots do
		local points, floorY = slotWorldPoints(player, slot)
		if points then
			local record = conveyorAt(data, slot)
			local def = record and Conveyors.Get(record.Type)
			local model = ConveyorBuilder.build(points, floorY, def)
			model.Name = `Conveyor_{slot}`
			model:SetAttribute("Slot", slot)
			buildPost(model, slot, points[1], floorY, points[2])
			model.Parent = folder
			visuals[player][slot] = model
		end
	end
end

local function nearPost(player: Player, slot: string): boolean
	local model = visuals[player] and visuals[player][slot]
	local sign = model and model:FindFirstChild(`ConveyorSign_{slot}`)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (sign and sign:IsA("BasePart") and root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - sign.Position).Magnitude <= POST_DISTANCE
end

local function place(player: Player, slot: unknown, typeId: unknown)
	if typeof(slot) ~= "string" or not Conveyors.IsSlot(slot :: string) or typeof(typeId) ~= "string" or not Conveyors.Get(typeId :: string) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not data.Buildings[STEP] then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if not nearPost(player, slot :: string) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	if conveyorAt(data, slot :: string) then
		return Result.err(Result.Codes.SLOT_TAKEN)
	end
	-- freies Exemplar mit der kleinsten Nummer
	local chosen: Types.ConveyorRecord? = nil
	local best = math.huge
	for _, c in data.Machines.Conveyors do
		if c.Type == typeId and c.Slot == nil then
			local n = tonumber(c.Id:sub(2)) or 0
			if n < best then
				chosen, best = c, n
			end
		end
	end
	if not chosen then
		return Result.err(Result.Codes.NOT_OWNED)
	end
	local id = chosen.Id
	DataService.Mutate(player, function(d)
		d.Machines.Conveyors[id].Slot = slot :: string
	end)
	DataService.RequestSave(player)
	refreshVisuals(player)
	local def = Conveyors.Get(typeId :: string)
	RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "CONVEYOR_PLACED", Args = { Name = if def then def.DisplayName else typeId } })
	Log.debug(TAG, `{player.Name} setzt {typeId} ({id}) auf {slot}`)
	return Result.ok(id)
end

local function remove(player: Player, conveyorId: unknown)
	if typeof(conveyorId) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	local record = data.Machines.Conveyors[conveyorId :: string]
	if not record then
		return Result.err(Result.Codes.NOT_OWNED)
	end
	if not record.Slot then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	if not nearPost(player, record.Slot) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	DataService.Mutate(player, function(d)
		d.Machines.Conveyors[conveyorId :: string].Slot = nil
	end)
	DataService.RequestSave(player)
	refreshVisuals(player)
	return Result.ok(conveyorId)
end

-- Ein Takt: Material bewegen, Bänder sichtbar an/aus
local function tickPlayer(player: Player)
	local data = DataService.Get(player)
	if not data or not data.Buildings[STEP] then
		return
	end
	local acc = accumulators[player] or {}
	accumulators[player] = acc
	for _, slot in Conveyors.Slots do
		local record = conveyorAt(data, slot)
		local def = record and Conveyors.Get(record.Type)
		local model = visuals[player] and visuals[player][slot]
		if not (record and def) then
			continue
		end
		local a = (acc[slot] or 0) + def.Throughput / 60
		local budget = math.floor(a)
		local moved = 0
		local color: Color3? = nil
		if slot == "StorageToSmelter" then
			local free = math.min(budget, SmelterService.InputFree(data))
			-- bevorzugtes Erz zuerst, sonst wertvollstes (D-011)
			local ids = {}
			for id, n in data.Storage.Items do
				if n > 0 and SmelterLogic.IsSmeltable(id) then
					table.insert(ids, id)
				end
			end
			table.sort(ids, function(x, y)
				if x == data.Smelter.Priority then
					return true
				elseif y == data.Smelter.Priority then
					return false
				end
				local mx, my = Materials.Get(x), Materials.Get(y)
				return ((mx and mx.SellValue or 0) :: number) > ((my and my.SellValue or 0) :: number)
			end)
			local plan: { [string]: number } = {}
			for _, id in ids do
				local take = math.min(data.Storage.Items[id], free - moved)
				if take > 0 then
					plan[id] = take
					moved += take
					color = color or (Materials.Get(id) and (Materials.Get(id) :: any).Color)
				end
			end
			if moved > 0 then
				DataService.MutateQuiet(player, function(d)
					for id, n in plan do
						d.Storage.Items[id] -= n
						if d.Storage.Items[id] <= 0 then
							d.Storage.Items[id] = nil
						end
						d.Smelter.Input[id] = (d.Smelter.Input[id] or 0) + n
					end
				end)
			end
		else
			local free = math.min(budget, data.Storage.Capacity - sum(data.Storage.Items))
			local plan: { [string]: number } = {}
			for id, n in data.Smelter.Output do
				local take = math.min(n, free - moved)
				if take > 0 then
					plan[id] = take
					moved += take
					color = color or (Materials.Get(id) and (Materials.Get(id) :: any).Color)
				end
			end
			if moved > 0 then
				DataService.MutateQuiet(player, function(d)
					for id, n in plan do
						d.Smelter.Output[id] -= n
						if d.Smelter.Output[id] <= 0 then
							d.Smelter.Output[id] = nil
						end
						d.Storage.Items[id] = (d.Storage.Items[id] or 0) + n
					end
				end)
			end
		end
		-- Bruchteil behalten; ungenutztes Budget verfällt (kein "Vorproduzieren")
		acc[slot] = math.min(a - moved, 1)
		if model then
			ConveyorBuilder.setRunning(model, moved > 0, color)
		end
		if moved > 0 then
			SmelterService.RefreshVisual(player)
		end
	end
end

function ConveyorService.Init()
	RemoteService.OnInvoke("PlaceConveyor", place)
	RemoteService.OnInvoke("RemoveConveyor", remove)
end

function ConveyorService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		local slot = prompt:GetAttribute("ConveyorSlot")
		if typeof(slot) ~= "string" then
			return
		end
		if not PlotService.IsOwnerOf(player, prompt) then
			RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = Result.Codes.NOT_OWNER })
			return
		end
		if DataService.IsLoaded(player) then
			RemoteService.FireClient("OpenConveyorSlot", player, { Slot = slot })
		end
	end)
	BuildingService.ModelBuilt:Connect(function(player, stepId)
		if stepId == STEP then
			task.defer(refreshVisuals, player)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(tickPlayer, player)
				if not ok then
					warn(`[Server][ConveyorService] Tick-Fehler {player.Name}: {err}`)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		accumulators[player] = nil
		visuals[player] = nil
	end)
end

return ConveyorService
