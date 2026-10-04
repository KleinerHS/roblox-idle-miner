--!strict
-- Räumliche Maße der Map, abgeleitet aus docs/references/MAP_MASTERPLAN_TOPDOWN.png und
-- FACTORY_MASTERPLAN_TOPDOWN.png. Alle Werte sind TODO_LAYOUT: vorläufig, werden beim
-- Map-Bau in Studio final festgelegt. Nur hier ändern, nirgends sonst Koordinaten hardcoden.
--
-- Plot-Koordinatensystem (lokal): -Z zeigt zur Map-Mitte (Vorderseite, Rolltor, Straße),
-- +Z ist die Rückwand der Halle. Aus Sicht des Grundrissbilds (Tor unten) ist
-- "links im Bild" = +X lokal.

local LayoutConfig = {
	-- Mittelpunkt der Map (zentrale Service-Mitte mit Shops und Verkauf).
	MapCenter = Vector3.new(0, 0, 0),

	-- Höhe der Oberkante des Bodens, auf dem Plots liegen.
	GroundY = 0,

	-- Radius der Plot-Mittelpunkte um die Map-Mitte. TODO_LAYOUT
	PlotRingRadius = 420,

	-- Winkel je Plot in Grad (0° = +X, 90° = Richtung -Z = "oben" im Masterplan).
	-- Anordnung wie im Masterplan: 2 oben, 1 oben links, 3 oben rechts,
	-- 6 links, 4 rechts, 5 unten.
	PlotAngles = {
		[1] = 150,
		[2] = 90,
		[3] = 30,
		[4] = -30,
		[5] = -90,
		[6] = 210,
	} :: { [number]: number },

	-- Grundstücksgröße (X = Breite entlang der Straße, Z = Tiefe). TODO_LAYOUT
	PlotSize = Vector2.new(260, 200),

	-- Hallen-Grundfläche innerhalb des Plots. Groß relativ zum Plot (docs/00 §8). TODO_LAYOUT
	HallSize = Vector2.new(210, 140),
	-- Versatz der Hallenmitte von der Plotmitte (lokal, X/Z). Vorne bleibt Platz für Zufahrt.
	HallOffset = Vector2.new(0, 15),

	-- Spawnpunkt bis zum Bau des Büros: Position des späteren Büros (oben links im
	-- Grundriss = hinten, +X). Lokal relativ zur Plotmitte. TODO_LAYOUT
	SpawnOffset = Vector3.new(80, 4, 55),

	-- Zaun
	FenceHeight = 3,
	FenceThickness = 1,
	-- Breite der Zufahrtslücke im vorderen Zaun.
	EntranceWidth = 40,

	-- Platzhalter-Zentrum und Straßen (nur zur Orientierung, bis die Map gebaut wird).
	CenterPlazaRadius = 140,
	RoadWidth = 28,
}

return table.freeze(LayoutConfig)
