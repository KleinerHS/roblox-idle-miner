--!strict
-- Alle Erzarten (docs/03 §2). IDs sind stabil und werden gespeichert: nie umbenennen.
-- DisplayName darf sich ändern. Reihenfolge = Tier. Jede Erzart belegt zwei Minen.
-- Werte (SellValue/XPValue) kommen aus BalanceConfig.OreValues.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)

export type OreDefinition = {
	Id: string,
	DisplayName: string,
	Tier: number,
	MineStart: number,
	MineEnd: number,
	-- nil = noch nicht gebalanced (TODO_BALANCE), dann nicht verkaufbar
	SellValue: number?,
	XPValue: number?,
}

local ORE_LIST: { { Id: string, DisplayName: string } } = {
	{ Id = "ore_coal", DisplayName = "Coal" },
	{ Id = "ore_copper", DisplayName = "Copper" },
	{ Id = "ore_tin", DisplayName = "Tin" },
	{ Id = "ore_iron", DisplayName = "Iron" },
	{ Id = "ore_lead", DisplayName = "Lead" },
	{ Id = "ore_zinc", DisplayName = "Zinc" },
	{ Id = "ore_silver", DisplayName = "Silver" },
	{ Id = "ore_nickel", DisplayName = "Nickel" },
	{ Id = "ore_cobalt", DisplayName = "Cobalt" },
	{ Id = "ore_chromium", DisplayName = "Chromium" },
	{ Id = "ore_manganese", DisplayName = "Manganese" },
	{ Id = "ore_aluminum", DisplayName = "Aluminum" },
	{ Id = "ore_titanium", DisplayName = "Titanium" },
	{ Id = "ore_tungsten", DisplayName = "Tungsten" },
	{ Id = "ore_platinum", DisplayName = "Platinum" },
	{ Id = "ore_palladium", DisplayName = "Palladium" },
	{ Id = "ore_osmium", DisplayName = "Osmium" },
	{ Id = "ore_iridium", DisplayName = "Iridium" },
	{ Id = "ore_rhodium", DisplayName = "Rhodium" },
	{ Id = "ore_uranium", DisplayName = "Uranium" },
	{ Id = "ore_mythril", DisplayName = "Mythril" },
	{ Id = "ore_obsidian", DisplayName = "Obsidian" },
	{ Id = "ore_ruby", DisplayName = "Ruby" },
	{ Id = "ore_sapphire", DisplayName = "Sapphire" },
	{ Id = "ore_emerald", DisplayName = "Emerald" },
	{ Id = "ore_amethyst", DisplayName = "Amethyst" },
	{ Id = "ore_topaz", DisplayName = "Topaz" },
	{ Id = "ore_aquamarine", DisplayName = "Aquamarine" },
	{ Id = "ore_opal", DisplayName = "Opal" },
	{ Id = "ore_black_opal", DisplayName = "Black Opal" },
	{ Id = "ore_jade", DisplayName = "Jade" },
	{ Id = "ore_amber", DisplayName = "Amber" },
	{ Id = "ore_meteorite", DisplayName = "Meteorite Ore" },
	{ Id = "ore_star_metal", DisplayName = "Star Metal" },
	{ Id = "ore_luminous_crystal", DisplayName = "Luminous Crystal" },
	{ Id = "ore_dragonstone", DisplayName = "Dragonstone" },
	{ Id = "ore_netherium", DisplayName = "Netherium" },
	{ Id = "ore_celestial_metal", DisplayName = "Celestial Metal" },
	{ Id = "ore_astralium", DisplayName = "Astralium" },
	{ Id = "ore_aetherium", DisplayName = "Aetherium" },
	{ Id = "ore_void", DisplayName = "Void Ore" },
	{ Id = "ore_darksteel", DisplayName = "Darksteel" },
	{ Id = "ore_sun_crystal", DisplayName = "Sun Crystal" },
	{ Id = "ore_moon_crystal", DisplayName = "Moon Crystal" },
	{ Id = "ore_galaxium", DisplayName = "Galaxium" },
	{ Id = "ore_cosmium", DisplayName = "Cosmium" },
	{ Id = "ore_quantium", DisplayName = "Quantium" },
	{ Id = "ore_singularium", DisplayName = "Singularium" },
	{ Id = "ore_primal_crystal", DisplayName = "Primal Crystal" },
	{ Id = "ore_diamond", DisplayName = "Diamond" },
}

local MINES_PER_ORE = 2

local list: { OreDefinition } = {}
local byId: { [string]: OreDefinition } = {}

for tier, entry in ORE_LIST do
	local values = BalanceConfig.OreValues[entry.Id]
	local ore: OreDefinition = table.freeze({
		Id = entry.Id,
		DisplayName = entry.DisplayName,
		Tier = tier,
		MineStart = (tier - 1) * MINES_PER_ORE + 1,
		MineEnd = tier * MINES_PER_ORE,
		SellValue = if values then values.SellValue else nil,
		XPValue = if values then values.XPValue else nil,
	})
	assert(byId[ore.Id] == nil, `Doppelte Erz-ID {ore.Id}`)
	table.insert(list, ore)
	byId[ore.Id] = ore
end

local Ores = {
	MinesPerOre = MINES_PER_ORE,
	List = table.freeze(list),
	ById = table.freeze(byId),
}

function Ores.Get(id: string): OreDefinition?
	return byId[id]
end

function Ores.GetByTier(tier: number): OreDefinition?
	return list[tier]
end

return table.freeze(Ores)
