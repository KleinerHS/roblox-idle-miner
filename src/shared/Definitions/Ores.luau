--!strict
-- Alle Erzarten (docs/03 §2). IDs sind stabil und werden gespeichert: nie umbenennen.
-- DisplayName darf sich ändern. Reihenfolge = Tier. Jede Erzart belegt zwei Minen.
-- Werte (SellValue/XPValue) kommen aus BalanceConfig.OreValues.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)

export type OreDefinition = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	Tier: number,
	MineStart: number,
	MineEnd: number,
	-- nil = noch nicht gebalanced (TODO_BALANCE), dann nicht verkaufbar
	SellValue: number?,
	XPValue: number?,
}

-- Color: Farbe der Erzader im Mine Shaft (nur Optik).
local ORE_LIST: { { Id: string, DisplayName: string, Color: Color3 } } = {
	{ Id = "ore_coal", DisplayName = "Coal", Color = Color3.fromRGB(35, 35, 38) },
	{ Id = "ore_copper", DisplayName = "Copper", Color = Color3.fromRGB(184, 115, 51) },
	{ Id = "ore_tin", DisplayName = "Tin", Color = Color3.fromRGB(200, 200, 195) },
	{ Id = "ore_iron", DisplayName = "Iron", Color = Color3.fromRGB(160, 110, 90) },
	{ Id = "ore_lead", DisplayName = "Lead", Color = Color3.fromRGB(105, 110, 120) },
	{ Id = "ore_zinc", DisplayName = "Zinc", Color = Color3.fromRGB(170, 180, 185) },
	{ Id = "ore_silver", DisplayName = "Silver", Color = Color3.fromRGB(205, 210, 215) },
	{ Id = "ore_nickel", DisplayName = "Nickel", Color = Color3.fromRGB(150, 155, 140) },
	{ Id = "ore_cobalt", DisplayName = "Cobalt", Color = Color3.fromRGB(60, 90, 170) },
	{ Id = "ore_chromium", DisplayName = "Chromium", Color = Color3.fromRGB(190, 195, 205) },
	{ Id = "ore_manganese", DisplayName = "Manganese", Color = Color3.fromRGB(140, 120, 150) },
	{ Id = "ore_aluminum", DisplayName = "Aluminum", Color = Color3.fromRGB(215, 220, 225) },
	{ Id = "ore_titanium", DisplayName = "Titanium", Color = Color3.fromRGB(150, 160, 175) },
	{ Id = "ore_tungsten", DisplayName = "Tungsten", Color = Color3.fromRGB(90, 95, 100) },
	{ Id = "ore_platinum", DisplayName = "Platinum", Color = Color3.fromRGB(225, 228, 230) },
	{ Id = "ore_palladium", DisplayName = "Palladium", Color = Color3.fromRGB(205, 200, 190) },
	{ Id = "ore_osmium", DisplayName = "Osmium", Color = Color3.fromRGB(90, 120, 150) },
	{ Id = "ore_iridium", DisplayName = "Iridium", Color = Color3.fromRGB(210, 215, 235) },
	{ Id = "ore_rhodium", DisplayName = "Rhodium", Color = Color3.fromRGB(230, 225, 215) },
	{ Id = "ore_uranium", DisplayName = "Uranium", Color = Color3.fromRGB(120, 220, 80) },
	{ Id = "ore_mythril", DisplayName = "Mythril", Color = Color3.fromRGB(120, 200, 230) },
	{ Id = "ore_obsidian", DisplayName = "Obsidian", Color = Color3.fromRGB(30, 25, 40) },
	{ Id = "ore_ruby", DisplayName = "Ruby", Color = Color3.fromRGB(200, 30, 60) },
	{ Id = "ore_sapphire", DisplayName = "Sapphire", Color = Color3.fromRGB(40, 80, 200) },
	{ Id = "ore_emerald", DisplayName = "Emerald", Color = Color3.fromRGB(30, 170, 90) },
	{ Id = "ore_amethyst", DisplayName = "Amethyst", Color = Color3.fromRGB(150, 80, 200) },
	{ Id = "ore_topaz", DisplayName = "Topaz", Color = Color3.fromRGB(240, 180, 60) },
	{ Id = "ore_aquamarine", DisplayName = "Aquamarine", Color = Color3.fromRGB(100, 210, 210) },
	{ Id = "ore_opal", DisplayName = "Opal", Color = Color3.fromRGB(220, 230, 240) },
	{ Id = "ore_black_opal", DisplayName = "Black Opal", Color = Color3.fromRGB(40, 40, 70) },
	{ Id = "ore_jade", DisplayName = "Jade", Color = Color3.fromRGB(80, 170, 120) },
	{ Id = "ore_amber", DisplayName = "Amber", Color = Color3.fromRGB(230, 150, 40) },
	{ Id = "ore_meteorite", DisplayName = "Meteorite Ore", Color = Color3.fromRGB(100, 80, 70) },
	{ Id = "ore_star_metal", DisplayName = "Star Metal", Color = Color3.fromRGB(240, 230, 170) },
	{ Id = "ore_luminous_crystal", DisplayName = "Luminous Crystal", Color = Color3.fromRGB(170, 255, 240) },
	{ Id = "ore_dragonstone", DisplayName = "Dragonstone", Color = Color3.fromRGB(200, 60, 30) },
	{ Id = "ore_netherium", DisplayName = "Netherium", Color = Color3.fromRGB(120, 20, 40) },
	{ Id = "ore_celestial_metal", DisplayName = "Celestial Metal", Color = Color3.fromRGB(180, 200, 255) },
	{ Id = "ore_astralium", DisplayName = "Astralium", Color = Color3.fromRGB(140, 120, 255) },
	{ Id = "ore_aetherium", DisplayName = "Aetherium", Color = Color3.fromRGB(200, 170, 255) },
	{ Id = "ore_void", DisplayName = "Void Ore", Color = Color3.fromRGB(20, 10, 40) },
	{ Id = "ore_darksteel", DisplayName = "Darksteel", Color = Color3.fromRGB(50, 55, 65) },
	{ Id = "ore_sun_crystal", DisplayName = "Sun Crystal", Color = Color3.fromRGB(255, 210, 80) },
	{ Id = "ore_moon_crystal", DisplayName = "Moon Crystal", Color = Color3.fromRGB(200, 220, 255) },
	{ Id = "ore_galaxium", DisplayName = "Galaxium", Color = Color3.fromRGB(90, 60, 180) },
	{ Id = "ore_cosmium", DisplayName = "Cosmium", Color = Color3.fromRGB(60, 40, 140) },
	{ Id = "ore_quantium", DisplayName = "Quantium", Color = Color3.fromRGB(0, 220, 255) },
	{ Id = "ore_singularium", DisplayName = "Singularium", Color = Color3.fromRGB(15, 15, 15) },
	{ Id = "ore_primal_crystal", DisplayName = "Primal Crystal", Color = Color3.fromRGB(255, 120, 200) },
	{ Id = "ore_diamond", DisplayName = "Diamond", Color = Color3.fromRGB(200, 240, 255) },
}

local MINES_PER_ORE = 2

local list: { OreDefinition } = {}
local byId: { [string]: OreDefinition } = {}

for tier, entry in ORE_LIST do
	local values = BalanceConfig.OreValues[entry.Id]
	local ore: OreDefinition = table.freeze({
		Id = entry.Id,
		DisplayName = entry.DisplayName,
		Color = entry.Color,
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
