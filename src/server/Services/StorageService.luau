--!strict
-- Firmenlager (docs/06 §13–19, D-004): ein gemeinsamer Bestand über alle Materialien mit
-- Gesamtkapazität. Phase 4a: Spieler lädt den Rucksack am Lager-Terminal ab oder nimmt
-- Material in den Rucksack (zum Verkaufen am Tresen). Worker-Transport folgt in 4b.
-- Es geht nie Material verloren: Was nicht passt, bleibt im Rucksack bzw. im Lager.
--
-- Für andere Services (Worker/Elevator in 4b):
--   StorageService.GetFree(player), StorageService.Add(player, oreId, amount) → tatsächlich hinzugefügt

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Ores = require(Shared.Definitions.Ores)
local Backpacks = require(Shared.Definitions.Backpacks)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local NumberFormat = require(Shared.Util.NumberFormat)
local Log = require(Shared.Util.Log)

local HallTemplates = require(script.Parent.Parent.World.HallTemplates)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local BuildingService = require(script.Parent.BuildingService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "StorageService"
local STORAGE_STEP = "build_storage"

local StorageService = {}

local function sum(items: Types.ItemCounts): number
	local total = 0
	for _, amount in items do
		total += amount
	end
	return total
end

local function backpackFree(data: Types.PlayerData): number
	local def = Backpacks.Get(data.Equipment.EquippedBackpack)
	return math.max(0, (if def then def.Capacity else 0) - sum(data.Backpack))
end

local function storageFree(data: Types.PlayerData): number
	return math.max(0, data.Storage.Capacity - sum(data.Storage.Items))
end

-- Erze in fester Reihenfolge (Tier), damit Teilmengen deterministisch verschoben werden
local function sortedOreIds(items: Types.ItemCounts): { string }
	local ids = {}
	for id, amount in items do
		if amount > 0 then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local oa, ob = Ores.Get(a), Ores.Get(b)
		return (if oa then oa.Tier else 999) < (if ob then ob.Tier else 999)
	end)
	return ids
end

local function updateDisplay(player: Player)
	local data = DataService.Get(player)
	local model = BuildingService.GetModel(player, STORAGE_STEP)
	if data and model then
		local used = sum(data.Storage.Items)
		HallTemplates.setStorageDisplay(model, used, data.Storage.Capacity, `{NumberFormat.withSeparators(used)} / {NumberFormat.withSeparators(data.Storage.Capacity)}`)
	end
end

local function isNearTerminal(player: Player): boolean
	local model = BuildingService.GetModel(player, STORAGE_STEP)
	local terminal = model and model:FindFirstChild("StorageTerminalPart")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (terminal and terminal:IsA("BasePart") and root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - terminal.Position).Magnitude <= LayoutConfig.StorageTerminalDistance
end

local function checkAccess(player: Player): (Types.PlayerData?, string?)
	local data = DataService.Get(player)
	if not data then
		return nil, Result.Codes.DATA_NOT_LOADED
	end
	if not data.Buildings[STORAGE_STEP] then
		return nil, Result.Codes.NOT_AVAILABLE
	end
	if not isNearTerminal(player) then
		return nil, Result.Codes.TOO_FAR
	end
	return data, nil
end

-- Rucksack so weit wie möglich ins Lager abladen
local function deposit(player: Player)
	local data, code = checkAccess(player)
	if not data then
		return Result.err(code or Result.Codes.INTERNAL_ERROR)
	end
	if sum(data.Backpack) <= 0 then
		return Result.err(Result.Codes.NOTHING_TO_SELL)
	end
	local free = storageFree(data)
	if free <= 0 then
		return Result.err(Result.Codes.STORAGE_FULL)
	end

	local moved = 0
	DataService.Mutate(player, function(d)
		for _, oreId in sortedOreIds(d.Backpack) do
			local take = math.min(d.Backpack[oreId], free - moved)
			if take <= 0 then
				break
			end
			d.Backpack[oreId] -= take
			if d.Backpack[oreId] <= 0 then
				d.Backpack[oreId] = nil
			end
			d.Storage.Items[oreId] = (d.Storage.Items[oreId] or 0) + take
			moved += take
		end
	end)
	Log.debug(TAG, `{player.Name} lädt {moved} ins Lager`)
	return Result.ok({ Moved = moved, Full = storageFree(data) <= 0 })
end

-- Material aus dem Lager in den Rucksack (für den Verkauf am Tresen, D-004)
local function withdraw(player: Player, oreId: unknown, amount: unknown)
	if typeof(oreId) ~= "string" or not Ores.Get(oreId) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	if typeof(amount) ~= "number" or amount ~= amount or amount < 1 or amount % 1 ~= 0 or amount > 1e9 then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data, code = checkAccess(player)
	if not data then
		return Result.err(code or Result.Codes.INTERNAL_ERROR)
	end
	local stored = data.Storage.Items[oreId :: string] or 0
	if stored <= 0 then
		return Result.err(Result.Codes.NOTHING_TO_SELL)
	end
	local free = backpackFree(data)
	if free <= 0 then
		return Result.err(Result.Codes.BACKPACK_FULL)
	end
	local take = math.min(stored, free, amount :: number)
	DataService.Mutate(player, function(d)
		local id = oreId :: string
		d.Storage.Items[id] -= take
		if d.Storage.Items[id] <= 0 then
			d.Storage.Items[id] = nil
		end
		d.Backpack[id] = (d.Backpack[id] or 0) + take
	end)
	return Result.ok({ Moved = take })
end

function StorageService.Init()
	RemoteService.OnInvoke("StorageDeposit", deposit)
	RemoteService.OnInvoke("StorageWithdraw", withdraw)
end

function StorageService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if prompt:GetAttribute("StorageTerminal") ~= true then
			return
		end
		if not PlotService.IsOwnerOf(player, prompt) then
			RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = Result.Codes.NOT_OWNER })
			return
		end
		if DataService.IsLoaded(player) then
			RemoteService.FireClient("OpenStorage", player)
		end
	end)
	DataService.Changed:Connect(updateDisplay)
	BuildingService.ModelBuilt:Connect(function(player, stepId)
		if stepId == STORAGE_STEP then
			updateDisplay(player)
		end
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(updateDisplay, player)
	end
end

-- Freie Lagerkapazität (für Worker/Elevator in 4b)
function StorageService.GetFree(player: Player): number
	local data = DataService.Get(player)
	return if data and data.Buildings[STORAGE_STEP] then storageFree(data) else 0
end

-- Fügt bis zur Kapazität hinzu und gibt die tatsächlich aufgenommene Menge zurück.
-- Rest bleibt beim Aufrufer (keine Vernichtung, docs/06 §19).
function StorageService.Add(player: Player, oreId: string, amount: number): number
	local data = DataService.Get(player)
	if not data or not data.Buildings[STORAGE_STEP] or amount <= 0 then
		return 0
	end
	local take = math.min(amount, storageFree(data))
	if take <= 0 then
		return 0
	end
	DataService.Mutate(player, function(d)
		d.Storage.Items[oreId] = (d.Storage.Items[oreId] or 0) + take
	end)
	return take
end

return StorageService
