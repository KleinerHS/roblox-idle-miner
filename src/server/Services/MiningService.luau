--!strict
-- Manuelles Mining (docs/03 §4–6, docs/15 §10). Der Client meldet nur "Hit an Slot n";
-- der Server prüft Ort, Slot, Entfernung, Cooldown, Spitzhacke und Rucksackkapazität und
-- berechnet die Erzmenge selbst. Erz kommt immer aus der Mine, in der der Spieler steht.
--
-- Rare Drops kommen nach Vertical Slice A (D-006). Die Stelle zum Einhängen ist rollRareDrop.
-- Mining gibt keine XP (XP nur beim Verkauf, docs/00 §20).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Mines = require(Shared.Definitions.Mines)
local Pickaxes = require(Shared.Definitions.Pickaxes)
local Backpacks = require(Shared.Definitions.Backpacks)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Log = require(Shared.Util.Log)
local PrestigeLogic = require(Shared.Util.PrestigeLogic)
local RareDropLogic = require(Shared.Util.RareDropLogic)
local Ores = require(Shared.Definitions.Ores)
local BalanceConfig = require(Shared.Config.BalanceConfig)

local ToolBuilder = require(script.Parent.Parent.World.ToolBuilder)
local DataService = require(script.Parent.DataService)
local ElevatorService = require(script.Parent.ElevatorService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "MiningService"

local MiningService = {}

local lastHit: { [Player]: number } = {}

local function backpackTotal(data: Types.PlayerData): number
	local total = 0
	for _, amount in data.Backpack do
		total += amount
	end
	return total
end

local function backpackCapacity(data: Types.PlayerData): number
	local def = Backpacks.Get(data.Equipment.EquippedBackpack)
	return if def then def.Capacity else 0
end

-- Abstand eines Punktes zu einer (gedrehten) Box
local function distanceToBox(point: Vector3, box: BasePart): number
	local localPoint = box.CFrame:PointToObjectSpace(point)
	local half = box.Size / 2
	local clamped = Vector3.new(
		math.clamp(localPoint.X, -half.X, half.X),
		math.clamp(localPoint.Y, -half.Y, half.Y),
		math.clamp(localPoint.Z, -half.Z, half.Z)
	)
	return (localPoint - clamped).Magnitude
end

local rng = Random.new()

-- Rare Drop eines erfolgreichen manuellen Hits (docs/03 §7, docs/11 §18–21). Gibt das zusätzliche
-- Erz und die Anzeige-Daten zurück oder nil. Nur hier – Worker/Drills/Offline haben keine Rare Drops.
type RareDrop = { Kind: string, OreId: string, Amount: number, Multiplier: number? }
local function rollRareDrop(data: Types.PlayerData, mine: Mines.MineDefinition, power: number): RareDrop?
	local ore = Ores.Get(mine.OreId)
	if not ore then
		return nil
	end
	local maxOffset = #Ores.List - ore.Tier
	local roll = RareDropLogic.Roll(rng, data.Equipment.LuckLevel or 0, maxOffset)
	if not roll then
		return nil
	end
	if roll.Kind == "Ore" then
		local rare = Ores.GetByTier(ore.Tier + (roll :: any).TierOffset)
		if rare then
			return { Kind = "Ore", OreId = rare.Id, Amount = BalanceConfig.RareDrops.RareOreAmount }
		end
		return nil
	end
	local multiplier = (roll :: any).Multiplier :: number
	-- Zusatz so, dass der Hit insgesamt das Multiplikator-Fache bringt
	return { Kind = "Amount", OreId = ore.Id, Amount = power * (multiplier - 1), Multiplier = multiplier }
end

-- Gibt dem Spieler seine ausgerüstete Spitzhacke als Tool (genau eine).
local function givePickaxe(player: Player)
	local data = DataService.Get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	local def = Pickaxes.Get(data.Equipment.EquippedPickaxe)
	if not def then
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	for _, container in { backpack :: Instance, character :: Instance } do
		for _, child in container:GetChildren() do
			if child:IsA("Tool") and child.Name == ToolBuilder.PickaxeToolName then
				if child:GetAttribute("PickaxeId") == def.Id then
					return
				end
				child:Destroy()
			end
		end
	end
	ToolBuilder.buildPickaxe(def).Parent = backpack
end

local function hit(player: Player, slotIndex: unknown)
	if typeof(slotIndex) ~= "number" or slotIndex % 1 ~= 0 or slotIndex < 1 or slotIndex > 8 then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end

	-- Ort: Spieler muss in einer Mine sein, Erz kommt von dieser Mine (nie vom Client)
	local mine = Mines.Get(ElevatorService.GetLocation(player))
	if not mine then
		return Result.err(Result.Codes.NOT_IN_MINE)
	end

	-- Spitzhacke muss ausgerüstet (in der Hand) sein
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local pickaxe = Pickaxes.Get(data.Equipment.EquippedPickaxe)
	if not tool or tool.Name ~= ToolBuilder.PickaxeToolName or not pickaxe or tool:GetAttribute("PickaxeId") ~= pickaxe.Id then
		return Result.err(Result.Codes.NO_PICKAXE)
	end

	-- Slot muss im eigenen Mine-Shaft-Raum liegen und nah genug sein
	local room = ElevatorService.GetRoom(player)
	local zone = room and room:FindFirstChild(`MiningSlot{slotIndex}`, true)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (zone and zone:IsA("BasePart") and root and root:IsA("BasePart")) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	if distanceToBox(root.Position, zone) > GameConfig.Mining.ReachStuds then
		return Result.err(Result.Codes.TOO_FAR)
	end

	-- Cooldown nach Mining Speed (Hits pro Sekunde), inkl. Prestige-Bonus
	local now = os.clock()
	local speed = pickaxe.MiningSpeed * PrestigeLogic.SpeedMultiplier(data.Prestige.Count)
	local minInterval = (1 / speed) * GameConfig.Mining.CooldownTolerance
	if lastHit[player] and now - lastHit[player] < minInterval then
		return Result.err(Result.Codes.COOLDOWN)
	end

	-- Rucksackkapazität
	local capacity = backpackCapacity(data)
	local free = capacity - backpackTotal(data)
	if free <= 0 then
		return Result.err(Result.Codes.BACKPACK_FULL)
	end
	lastHit[player] = now

	local amount = math.min(pickaxe.MiningPower, free)
	-- Rare Drop darf die Kapazität einmalig überschreiten, nichts geht verloren (D-006)
	local rare = rollRareDrop(data, mine, pickaxe.MiningPower)
	DataService.Mutate(player, function(d)
		d.Backpack[mine.OreId] = (d.Backpack[mine.OreId] or 0) + amount
		if rare then
			d.Backpack[rare.OreId] = (d.Backpack[rare.OreId] or 0) + rare.Amount
		end
	end)

	local total = backpackTotal(data)
	Log.debug(TAG, `{player.Name} +{amount} {mine.OreId} ({total}/{capacity})`)
	if rare then
		Log.info(TAG, `{player.Name} Rare Drop: {rare.Kind} +{rare.Amount} {rare.OreId}`)
	end
	return Result.ok({ OreId = mine.OreId, Amount = amount, Total = total, Capacity = capacity, Rare = rare })
end

-- Nach Wechsel der ausgerüsteten Spitzhacke (ShopService) das Tool tauschen.
function MiningService.RefreshPickaxe(player: Player)
	givePickaxe(player)
end

function MiningService.Init()
	RemoteService.OnInvoke("MineHit", hit)
end

function MiningService.Start()
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			-- Nach dem Respawn ist das Backpack neu; einen Frame warten, bis es steht
			task.defer(givePickaxe, player)
		end)
		if player.Character then
			task.spawn(givePickaxe, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	-- Profil kann nach dem ersten Spawn fertig laden
	DataService.ProfileLoaded:Connect(function(player)
		givePickaxe(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastHit[player] = nil
	end)
end

return MiningService
