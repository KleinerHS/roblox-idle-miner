--!strict
-- Schmelzer (docs/06 §28–37, D-011): verarbeitet Metallerz aus dem Einfülltrichter zu Barren.
--   * Takt 1 s für alle Spieler (kein Loop pro Maschine, docs/15 §11).
--   * Rezeptwahl über SmelterLogic (bevorzugtes Erz, sonst wertvollster Barren).
--   * Befüllen aus dem Lager und Abholen ins Lager am Terminal (bis die Förderbänder das
--     automatisch übernehmen, Phase 7b). Jeder Transfer ist eine einzige Profiländerung.
--   * Rohmaterial bleibt verkaufbar; der Schmelzer ist keine Pflicht (docs/06 §37).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Materials = require(Shared.Definitions.Materials)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local SmelterLogic = require(Shared.Util.SmelterLogic)
local NumberFormat = require(Shared.Util.NumberFormat)
local Log = require(Shared.Util.Log)

local SmelterTemplate = require(script.Parent.Parent.World.SmelterTemplate)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local BuildingService = require(script.Parent.BuildingService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "SmelterService"
local STEP = "build_smelter"
local TERMINAL_DISTANCE = 14

local SmelterService = {}

-- Laufzeit: Fortschritt des aktuellen Barrens je Spieler (Sekunden)
local progress: { [Player]: number } = {}
local lastVisual: { [Player]: string } = {}

local sum = SmelterLogic.Sum

local function smelterModel(player: Player): Model?
	return BuildingService.GetModel(player, STEP)
end

local function nearTerminal(player: Player): boolean
	local model = smelterModel(player)
	local terminal = model and model:FindFirstChild("SmelterTerminalPart")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (terminal and terminal:IsA("BasePart") and root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - terminal.Position).Magnitude <= TERMINAL_DISTANCE
end

local function updateVisual(player: Player)
	local data = DataService.Get(player)
	local model = smelterModel(player)
	if not (data and model) then
		return
	end
	local state = data.Smelter
	local status = SmelterLogic.Status(state)
	local cfg = BalanceConfig.Smelter
	local inputText = `IN  {NumberFormat.withSeparators(sum(state.Input))} / {NumberFormat.withSeparators(cfg.InputCapacity)}`
	local outputText = `OUT {NumberFormat.withSeparators(sum(state.Output))} / {NumberFormat.withSeparators(cfg.OutputCapacity)}`
	local key = `{status}|{inputText}|{outputText}`
	if lastVisual[player] == key then
		return
	end
	lastVisual[player] = key
	SmelterTemplate.setStatus(model, status, inputText, outputText, sum(state.Output) / cfg.OutputCapacity)
end

local function tickPlayer(player: Player)
	local data = DataService.Get(player)
	if not data or not data.Buildings[STEP] then
		return
	end
	local recipe = if SmelterLogic.Status(data.Smelter) == "Running" then SmelterLogic.PickRecipe(data.Smelter) else nil
	if not recipe then
		progress[player] = 0
		updateVisual(player)
		return
	end
	local t = (progress[player] or 0) + 1
	if t >= recipe.Seconds then
		t = 0
		local oreId, barId, need = recipe.OreId, recipe.BarId, recipe.OrePerBar
		DataService.MutateQuiet(player, function(d)
			local input = d.Smelter.Input
			if (input[oreId] or 0) < need then
				return
			end
			input[oreId] -= need
			if input[oreId] <= 0 then
				input[oreId] = nil
			end
			d.Smelter.Output[barId] = (d.Smelter.Output[barId] or 0) + 1
		end)
	end
	progress[player] = t
	updateVisual(player)
end

-- Erz aus dem Lager in den Trichter: oreId nil = alle schmelzbaren Erze (wertvollste zuerst)
local function feed(player: Player, oreId: unknown, amount: unknown)
	if oreId ~= nil and (typeof(oreId) ~= "string" or not SmelterLogic.IsSmeltable(oreId :: string)) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	if amount ~= nil and (typeof(amount) ~= "number" or amount ~= amount or amount < 1 or amount % 1 ~= 0 or amount > 1e9) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not data.Buildings[STEP] then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if not nearTerminal(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	local free = BalanceConfig.Smelter.InputCapacity - sum(data.Smelter.Input)
	if free <= 0 then
		return Result.err(Result.Codes.SMELTER_FULL)
	end
	local ids: { string } = {}
	if oreId then
		table.insert(ids, oreId :: string)
	else
		for id, n in data.Storage.Items do
			if n > 0 and SmelterLogic.IsSmeltable(id) then
				table.insert(ids, id)
			end
		end
		Materials.SortIds(ids)
		-- wertvollste zuerst
		local reversed = {}
		for i = #ids, 1, -1 do
			table.insert(reversed, ids[i])
		end
		ids = reversed
	end
	local plan: { [string]: number } = {}
	local total = 0
	local limit = if amount then math.min(free, amount :: number) else free
	for _, id in ids do
		local take = math.min(data.Storage.Items[id] or 0, limit - total)
		if take > 0 then
			plan[id] = take
			total += take
		end
	end
	if total <= 0 then
		return Result.err(Result.Codes.NOTHING_TO_LOAD)
	end
	DataService.Mutate(player, function(d)
		for id, n in plan do
			d.Storage.Items[id] -= n
			if d.Storage.Items[id] <= 0 then
				d.Storage.Items[id] = nil
			end
			d.Smelter.Input[id] = (d.Smelter.Input[id] or 0) + n
		end
	end)
	DataService.RequestSave(player)
	updateVisual(player)
	return Result.ok({ Moved = total })
end

-- Fertige Barren ins Lager (so weit Platz ist)
local function collect(player: Player)
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not data.Buildings[STEP] then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if not nearTerminal(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end
	local free = data.Storage.Capacity - sum(data.Storage.Items)
	if free <= 0 then
		return Result.err(Result.Codes.STORAGE_FULL)
	end
	local ids = {}
	for id, n in data.Smelter.Output do
		if n > 0 then
			table.insert(ids, id)
		end
	end
	Materials.SortIds(ids)
	local plan: { [string]: number } = {}
	local total = 0
	for _, id in ids do
		local take = math.min(data.Smelter.Output[id], free - total)
		if take > 0 then
			plan[id] = take
			total += take
		end
	end
	if total <= 0 then
		return Result.err(Result.Codes.NOTHING_TO_SELL)
	end
	DataService.Mutate(player, function(d)
		for id, n in plan do
			d.Smelter.Output[id] -= n
			if d.Smelter.Output[id] <= 0 then
				d.Smelter.Output[id] = nil
			end
			d.Storage.Items[id] = (d.Storage.Items[id] or 0) + n
		end
	end)
	DataService.RequestSave(player)
	updateVisual(player)
	Log.debug(TAG, `{player.Name} holt {total} Barren ab`)
	return Result.ok({ Moved = total })
end

-- Bevorzugtes Erz setzen ("" = automatisch wertvollstes zuerst, D-011). Auch vom Laptop.
local function setPriority(player: Player, oreId: unknown)
	if typeof(oreId) ~= "string" or (oreId ~= "" and not SmelterLogic.IsSmeltable(oreId :: string)) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	DataService.Mutate(player, function(d)
		d.Smelter.Priority = oreId :: string
	end)
	return Result.ok(oreId)
end

function SmelterService.Init()
	RemoteService.OnInvoke("SmelterFeed", feed)
	RemoteService.OnInvoke("SmelterCollect", collect)
	RemoteService.OnInvoke("SmelterPriority", setPriority)
end

function SmelterService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if prompt:GetAttribute("SmelterTerminal") ~= true then
			return
		end
		if not PlotService.IsOwnerOf(player, prompt) then
			RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = Result.Codes.NOT_OWNER })
			return
		end
		if DataService.IsLoaded(player) then
			RemoteService.FireClient("OpenSmelter", player)
		end
	end)
	BuildingService.ModelBuilt:Connect(function(player, stepId)
		if stepId == STEP then
			lastVisual[player] = nil
			updateVisual(player)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(tickPlayer, player)
				if not ok then
					warn(`[Server][SmelterService] Tick-Fehler {player.Name}: {err}`)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		progress[player] = nil
		lastVisual[player] = nil
	end)
end

-- Für Förderbänder (Phase 7b): freie Trichtermenge und Barren in der Ablage
function SmelterService.InputFree(data: Types.PlayerData): number
	return BalanceConfig.Smelter.InputCapacity - sum(data.Smelter.Input)
end

function SmelterService.RefreshVisual(player: Player)
	updateVisual(player)
end

return SmelterService
