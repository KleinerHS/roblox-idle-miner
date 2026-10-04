--!strict
-- Auswahl für die Firmenidentität (docs/04 §8–9). Erweiterbar: neue Einträge anhängen,
-- bestehende IDs nie ändern. Logo-Bilder (ImageId) folgen mit der Asset-Pipeline (Phase 2).

export type LogoDefinition = {
	Id: string,
	DisplayName: string,
	ImageId: string?,
}

export type ColorDefinition = {
	Id: string,
	DisplayName: string,
	Color: Color3,
}

local logos: { LogoDefinition } = {
	{ Id = "logo_pickaxe", DisplayName = "Spitzhacke" },
	{ Id = "logo_mountain", DisplayName = "Berg" },
	{ Id = "logo_gear", DisplayName = "Zahnrad" },
	{ Id = "logo_factory", DisplayName = "Fabrik" },
	{ Id = "logo_crystal", DisplayName = "Kristall" },
	{ Id = "logo_mining", DisplayName = "Mining-Symbol" },
}

-- Akzentfarben: bewusst gedeckt, damit sechs Plots nebeneinander harmonisch bleiben (docs/04 §29).
local colors: { ColorDefinition } = {
	{ Id = "color_orange", DisplayName = "Orange", Color = Color3.fromRGB(242, 140, 40) },
	{ Id = "color_yellow", DisplayName = "Gelb", Color = Color3.fromRGB(240, 196, 60) },
	{ Id = "color_red", DisplayName = "Rot", Color = Color3.fromRGB(214, 72, 64) },
	{ Id = "color_blue", DisplayName = "Blau", Color = Color3.fromRGB(64, 128, 220) },
	{ Id = "color_teal", DisplayName = "Petrol", Color = Color3.fromRGB(40, 170, 160) },
	{ Id = "color_green", DisplayName = "Grün", Color = Color3.fromRGB(88, 180, 90) },
	{ Id = "color_purple", DisplayName = "Lila", Color = Color3.fromRGB(150, 100, 210) },
	{ Id = "color_steel", DisplayName = "Stahlgrau", Color = Color3.fromRGB(140, 150, 165) },
}

local logoById: { [string]: LogoDefinition } = {}
for _, def in logos do
	assert(logoById[def.Id] == nil, `Doppelte Logo-ID {def.Id}`)
	logoById[def.Id] = table.freeze(def)
end

local colorById: { [string]: ColorDefinition } = {}
for _, def in colors do
	assert(colorById[def.Id] == nil, `Doppelte Farb-ID {def.Id}`)
	colorById[def.Id] = table.freeze(def)
end

local CompanyIdentity = {
	Logos = table.freeze(logos),
	Colors = table.freeze(colors),
	LogoById = table.freeze(logoById),
	ColorById = table.freeze(colorById),

	-- Firmenname: Länge in Zeichen. Textfilter erfolgt serverseitig (TextService).
	NameMinLength = 3,
	NameMaxLength = 24,
}

return table.freeze(CompanyIdentity)
