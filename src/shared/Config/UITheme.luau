--!strict
-- Zentrale UI-Farben und Schriften (docs/09). Firmenfarbe wird nur als Akzent genutzt
-- und zur Laufzeit aus CompanyColors gesetzt. Erste UI-Komponenten folgen in Phase 2.

local UITheme = {
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,

	Colors = {
		Background = Color3.fromRGB(24, 27, 33),
		Surface = Color3.fromRGB(36, 40, 48),
		SurfaceRaised = Color3.fromRGB(48, 53, 63),
		TextPrimary = Color3.fromRGB(240, 242, 245),
		TextSecondary = Color3.fromRGB(165, 172, 184),
		Positive = Color3.fromRGB(88, 196, 120),
		Negative = Color3.fromRGB(226, 92, 92),
		Warning = Color3.fromRGB(240, 180, 70),
		DefaultAccent = Color3.fromRGB(242, 166, 46),
	},

	CornerRadius = UDim.new(0, 10),
	Padding = 12,

	-- Bedien-Feedback und Animationen (Phase 13e, docs/09 §58/§59)
	Motion = {
		Hover = 0.1, -- Sekunden
		HoverLighten = 0.1, -- Anteil Weiß beim Hover
		PressScale = 0.96,
		Press = 0.06,
		OpenScaleFrom = 0.94,
		Open = 0.18,
	},

	-- Responsive Skalierung aller eigenen ScreenGuis (docs/09 §5): Bezugshöhe 1000 px
	Scale = {
		ReferenceHeight = 1000,
		Min = 0.8,
		Max = 1.15,
	},
}

return table.freeze(UITheme)
