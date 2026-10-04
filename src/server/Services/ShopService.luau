--!strict
-- Shops (docs/10 §21–23, §42–43, §71). Phase 3: Equipment-Shop mit Pickaxes und Backpacks.
-- Phase 5: Machine-Shop mit Drills. Drills sind mehrfach kaufbar und bekommen je Exemplar
-- eine Instanz-ID (docs/10 §38–39, §64); sie landen unplatziert im Inventar (docs/10 §30).
-- Preis, Level und Stats kommen ausschließlich aus den Definitionen; der Client schickt nur
-- Kategorie und Item-ID. Pickaxes/Backpacks werden einmal besessen und danach ausgerüstet
-- (docs/10 §62). Gekauftes wird direkt ausgerüstet.
-- Machine- und Vehicle-Shop hängen sich später als weitere Kategorien ein.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LayoutConfig = require(Shared.Config.LayoutConfig)
local Pickaxes = require(Shared.Definitions.Pickaxes)
local Backpacks = require(Shared.Definitions.Backpacks)
local Drills = require(Shared.Definitions.Drills)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Log = require(Shared.Util.Log)

local EquipmentShopBuilder = require(script.Parent.Parent.World.EquipmentShopBuilder)
local MachineShopBuilder = require(script.Parent.Parent.World.MachineShopBuilder)
local DataService = require(script.Parent.DataService)
local MiningService = require(script.Parent.MiningService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "ShopService"

local ShopService = {}

type ItemDef = { Id: string, DisplayName: string, RequiredLevel: number, Price: number, Available: boolean? }

-- Kategorie → Definitionen und Speicherorte im Profil
type Category = {
	shopId: string,
	get: (id: string) -> ItemDef?,
	owned: (data: Types.PlayerData) -> { [string]: boolean },
	equip: (data: Types.PlayerData, id: string) -> (),
	equipped: (data: Types.PlayerData) -> string,
}

local CATEGORIES: { [string]: Category } = {
	pickaxe = {
		shopId = "equipment",
		get = function(id)
			return Pickaxes.Get(id)
		end,
		owned = function(data)
			return data.Equipment.OwnedPickaxes
		end,
		equip = function(data, id)
			data.Equipment.EquippedPickaxe = id
		end,
		equipped = function(data)
			return data.Equipment.EquippedPickaxe
		end,
	},
	backpack = {
		shopId = "equipment",
		get = function(id)
			return Backpacks.Get(id)
		end,
		owned = function(data)
			return data.Equipment.OwnedBackpacks
		end,
		equip = function(data, id)
			data.Equipment.EquippedBackpack = id
		end,
		equipped = function(data)
			return data.Equipment.EquippedBackpack
		end,
	},
}

local counters: { [string]: BasePart } = {}

local function isNearShop(player: Player, shopId: string): boolean
	local counter = counters[shopId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (counter and root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - counter.Position).Magnitude <= LayoutConfig.ShopCounterDistance
end

local function afterEquip(player: Player, categoryName: string)
	if categoryName == "pickaxe" then
		MiningService.RefreshPickaxe(player)
	end
end

local function validate(player: Player, categoryName: unknown, itemId: unknown): (Category?, ItemDef?, Types.PlayerData?, string?)
	if typeof(categoryName) ~= "string" or typeof(itemId) ~= "string" then
		return nil, nil, nil, Result.Codes.INVALID_ARGUMENT
	end
	local category = CATEGORIES[categoryName]
	local item = category and category.get(itemId)
	if not category or not item then
		return nil, nil, nil, Result.Codes.INVALID_ARGUMENT
	end
	local data = DataService.Get(player)
	if not data then
		return nil, nil, nil, Result.Codes.DATA_NOT_LOADED
	end
	if not isNearShop(player, category.shopId) then
		return nil, nil, nil, Result.Codes.TOO_FAR
	end
	return category, item, data, nil
end

local function buy(player: Player, categoryName: unknown, itemId: unknown)
	local category, item, data, code = validate(player, categoryName, itemId)
	if code or not category or not item or not data then
		return Result.err(code or Result.Codes.INTERNAL_ERROR)
	end
	if category.owned(data)[item.Id] then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	if item.Available == false then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if data.MiningLevel < item.RequiredLevel then
		return Result.err(Result.Codes.LEVEL_TOO_LOW)
	end
	if data.Cash < item.Price then
		return Result.err(Result.Codes.NOT_ENOUGH_MONEY)
	end

	-- Prüfung und Änderung ohne Yield dazwischen → kein Doppelkauf durch Remote-Spam
	DataService.Mutate(player, function(d)
		d.Cash -= item.Price
		category.owned(d)[item.Id] = true
		category.equip(d, item.Id)
	end)
	afterEquip(player, categoryName :: string)
	DataService.RequestSave(player)
	Log.debug(TAG, `{player.Name} kauft {item.Id} für {item.Price}`)
	RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "ITEM_PURCHASED", Args = { Name = item.DisplayName } })
	return Result.ok(item.Id)
end

local function equip(player: Player, categoryName: unknown, itemId: unknown)
	local category, item, data, code = validate(player, categoryName, itemId)
	if code or not category or not item or not data then
		return Result.err(code or Result.Codes.INTERNAL_ERROR)
	end
	if not category.owned(data)[item.Id] then
		return Result.err(Result.Codes.NOT_OWNED)
	end
	if category.equipped(data) == item.Id then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	DataService.Mutate(player, function(d)
		category.equip(d, item.Id)
	end)
	afterEquip(player, categoryName :: string)
	return Result.ok(item.Id)
end

-- Drill kaufen (mehrfach möglich): (drillTypeId) -> Result<instanceId>
local function buyMachine(player: Player, drillTypeId: unknown)
	if typeof(drillTypeId) ~= "string" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local def = Drills.Get(drillTypeId)
	if not def then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not isNearShop(player, "machine") then
		return Result.err(Result.Codes.TOO_FAR)
	end
	if data.MiningLevel < def.RequiredLevel then
		return Result.err(Result.Codes.LEVEL_TOO_LOW)
	end
	if data.Cash < def.Price then
		return Result.err(Result.Codes.NOT_ENOUGH_MONEY)
	end

	-- Prüfung und Änderung ohne Yield dazwischen → kein Doppelkauf durch Remote-Spam
	local newId = ""
	DataService.Mutate(player, function(d)
		d.Cash -= def.Price
		d.Machines.Seq += 1
		newId = `d{d.Machines.Seq}`
		d.Machines.Drills[newId] = { Id = newId, Type = def.Id }
	end)
	DataService.RequestSave(player)
	Log.debug(TAG, `{player.Name} kauft {def.Id} ({newId}) für {def.Price}`)
	RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "DRILL_PURCHASED", Args = { Name = def.DisplayName } })
	return Result.ok(newId)
end

function ShopService.Init()
	local center = workspace:FindFirstChild("Center")
	if not center then
		center = Instance.new("Folder")
		center.Name = "Center"
		center.Parent = workspace
	end
	local shop = EquipmentShopBuilder.build(center :: Instance)
	counters.equipment = shop:FindFirstChild("CounterPromptPart") :: BasePart
	local machineShop = MachineShopBuilder.build(center :: Instance)
	counters.machine = machineShop:FindFirstChild("CounterPromptPart") :: BasePart

	RemoteService.OnInvoke("BuyItem", buy)
	RemoteService.OnInvoke("EquipItem", equip)
	RemoteService.OnInvoke("BuyMachine", buyMachine)
end

function ShopService.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		local shopId = prompt:GetAttribute("ShopId")
		if typeof(shopId) ~= "string" then
			return
		end
		if DataService.IsLoaded(player) and isNearShop(player, shopId) then
			RemoteService.FireClient("OpenShop", player, { ShopId = shopId })
		end
	end)
end

return ShopService
