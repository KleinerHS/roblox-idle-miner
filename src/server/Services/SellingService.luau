--!strict
-- Verkauf am Tresen (docs/07 §21–31): Der Spieler verkauft seinen Rucksack im
-- Verkaufsgebäude. Der Server berechnet Geld (Menge × SellValue) und Mining XP
-- (Menge × XPValue) getrennt aus den Erzdefinitionen (docs/03 §11) – nie aus Client-Werten.
-- Mining XP gibt es nur hier (docs/00 §20). Fahrzeugverkauf folgt in Phase 6.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Ores = require(Shared.Definitions.Ores)
local Result = require(Shared.Util.Result)
local Leveling = require(Shared.Util.Leveling)
local Log = require(Shared.Util.Log)

local SellingBuilder = require(script.Parent.Parent.World.SellingBuilder)
local DataService = require(script.Parent.DataService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "SellingService"

local SellingService = {}

local counterPart: BasePart

local function isNearCounter(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - counterPart.Position).Magnitude <= LayoutConfig.SellCounterDistance
end

local function sellAll(player: Player)
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not isNearCounter(player) then
		return Result.err(Result.Codes.TOO_FAR)
	end

	-- Werte ausschließlich aus den Definitionen; Erze ohne Balancewert bleiben im Rucksack
	local cash, xp = 0, 0
	local sold: { [string]: number } = {}
	for oreId, amount in data.Backpack do
		local ore = Ores.Get(oreId)
		if ore and ore.SellValue and ore.XPValue and amount > 0 then
			cash += amount * ore.SellValue
			xp += amount * ore.XPValue
			sold[oreId] = amount
		end
	end
	if next(sold) == nil then
		return Result.err(Result.Codes.NOTHING_TO_SELL)
	end

	-- Prüfung oben und Änderung hier ohne Yield dazwischen → atomar, kein Doppelverkauf
	local levelsGained = 0
	DataService.Mutate(player, function(d)
		for oreId in sold do
			d.Backpack[oreId] = nil
		end
		d.Cash += cash
		local level, levelXP, gained = Leveling.addXP(d.MiningLevel, d.MiningXP, xp)
		d.MiningLevel = level
		d.MiningXP = levelXP
		levelsGained = gained
	end)
	DataService.RequestSave(player)

	Log.debug(TAG, `{player.Name} verkauft für ${cash} und {xp} XP (Level {data.MiningLevel}, +{levelsGained})`)
	return Result.ok({ Cash = cash, XP = xp, Level = data.MiningLevel, LevelsGained = levelsGained })
end

function SellingService.Init()
	local existing = workspace:FindFirstChild("Center")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Center"
	local building = SellingBuilder.build(folder)
	counterPart = building:FindFirstChild("CounterPromptPart") :: BasePart
	folder.Parent = workspace

	RemoteService.OnInvoke("SellAll", sellAll)
end

function SellingService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if prompt:GetAttribute("SellCounter") ~= true then
			return
		end
		if DataService.IsLoaded(player) and isNearCounter(player) then
			RemoteService.FireClient("OpenSellMenu", player)
		end
	end)
end

return SellingService
