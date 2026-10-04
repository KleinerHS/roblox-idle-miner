--!strict
-- Räumliche Maße der Map, abgeleitet aus docs/references/MAP_MASTERPLAN_TOPDOWN.png und
-- FACTORY_MASTERPLAN_TOPDOWN.png. Alle Werte sind TODO_LAYOUT: vorläufig, werden beim
-- Map-Bau in Studio final festgelegt. Nur hier ändern, nirgends sonst Koordinaten hardcoden.
--
-- Plot-Koordinatensystem (lokal, relativ zur Plotmitte auf Bodenhöhe):
--   -Z zeigt zur Map-Mitte (Vorderseite, Rolltor, Straße), +Z ist die Rückwand der Halle.
--   Aus Sicht des Grundrissbilds (Tor unten) ist "links im Bild" = +X lokal.

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
	-- Oberkante der Hallen-Bodenplatte (lokal Y)
	HallFloorTop = 1.4,

	-- Funktionsbereiche der Endhalle als Bodenmarkierung (D-002), Mittelpunkt X/Z und Größe
	-- X/Z, lokal zur Plotmitte. Nach FACTORY_MASTERPLAN_TOPDOWN.png. TODO_LAYOUT
	HallZones = {
		Office = { Center = Vector2.new(87, 63), Size = Vector2.new(36, 44) },
		Elevator = { Center = Vector2.new(50, 60), Size = Vector2.new(30, 30) },
		Storage = { Center = Vector2.new(-8, 55), Size = Vector2.new(66, 50) },
		Smelter = { Center = Vector2.new(-75, 25), Size = Vector2.new(58, 116) },
		Garage = { Center = Vector2.new(37, -24), Size = Vector2.new(100, 54) },
	} :: { [string]: { Center: Vector2, Size: Vector2 } },

	-- Rolltor in der Vorderwand (X-Mitte und Breite). Zufahrt und Straße fluchten damit.
	DoorCenterX = 15,
	DoorWidth = 60,

	-- Tycoon-Kaufbuttons je BuildStep (lokal X/Z, vor dem jeweiligen Bereich). TODO_LAYOUT
	BuildButtons = {
		build_office = Vector2.new(87, 33),
		build_elevator = Vector2.new(50, 37),
	} :: { [string]: Vector2 },
	ButtonSize = Vector3.new(7, 0.4, 7),

	-- Spawnpunkt solange das Büro nicht gebaut ist: neben dem Büro-Kaufbutton.
	-- Danach liegt der Spawn auf dem Bett in der Hütte (docs/04 §7). TODO_LAYOUT
	SpawnOffset = Vector3.new(87, 4, 24),

	-- Mine Shaft (00 §13, MINE_SHAFT_REFERENCE.png): ein Raum pro Plot, unter dem Plot.
	-- Der Raum wird beim Elevator-Wechsel auf die gewählte Mine umkonfiguriert (D-014).
	MineShaft = {
		-- Höhe des Raumbodens unter der Plot-Bodenhöhe (oberhalb FallenPartsDestroyHeight -500)
		DepthBelowPlot = 260,
		-- Innenmaß X (Breite), Z (Tiefe), Höhe. TODO_LAYOUT
		Size = Vector3.new(96, 22, 72),
		-- Elevator-Podest in der Raummitte, leicht nach hinten versetzt (lokal X/Z)
		ElevatorCenter = Vector2.new(0, 8),
		-- Mining-Slots an gegenüberliegenden Wänden (Slot 1 = +X = links im Bild)
		Slots = {
			Vector2.new(36, 4),
			Vector2.new(-36, 4),
		},
	},

	-- Elevator: maximale Entfernung zum Käfig, um ihn zu benutzen
	ElevatorUseDistance = 16,

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
