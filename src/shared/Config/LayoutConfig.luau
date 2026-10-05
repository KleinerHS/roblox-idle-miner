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
	-- Höhe der Hallenwände (Oberkante über dem Hallenboden). TODO_LAYOUT
	HallWallHeight = 34,
	-- Höhe der Rolltor-Öffnung (Platz für spätere LKW). TODO_LAYOUT
	DoorHeight = 20,

	-- Tycoon-Kaufbuttons je BuildStep (lokal X/Z, vor dem jeweiligen Bereich). TODO_LAYOUT
	BuildButtons = {
		build_office = Vector2.new(87, 33),
		build_elevator = Vector2.new(50, 37),
		build_walls = Vector2.new(15, -40),
		build_roof = Vector2.new(15, -40),
		build_storage = Vector2.new(-8, 25),
		build_garage = Vector2.new(66, -12),
	} :: { [string]: Vector2 },

	-- Garage im vorderen Hallenbereich (docs/07 §3, D-008, D-016), lokal zur Plotmitte.
	-- Fahrzeuge stehen mit der Front zum Rolltor (-Z). Der Verladeturm steht hinter und
	-- zwischen den beiden Stellplätzen und speist von oben in die Ladefläche. TODO_LAYOUT
	Garage = {
		-- Mitte der Stellplätze (X/Z) und Größe einer Stellfläche (Breite X, Länge Z)
		Bays = { Vector2.new(3, -32), Vector2.new(27, -32) },
		BaySize = Vector2.new(15, 30),
		-- Leuchtring zur Fahrzeugauswahl (docs/07 §4)
		Ring = Vector2.new(66, -30),
		RingRadius = 5,
		-- Verladeturm (D-008) mit Auslegern zu beiden Stellplätzen
		Tower = Vector2.new(15, -8),
		-- Höchstabstand Ladefläche ↔ Ausleger-Ende zum Beladen (Phase 6c)
		LoadDistance = 14,
	},
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
		-- Elevator-Podest mittig, nach hinten versetzt wie im Referenzbild (lokal X/Z)
		ElevatorCenter = Vector2.new(0, 14),
		-- Mining-Slots wie im Referenzbild: Platz 1 hinten links (+X = links im Bild),
		-- Platz 2 rechts an der Wand. Center = Mitte des Erzhaufens.
		Slots = {
			Vector2.new(31, 19),
			Vector2.new(-35, 0),
		},
	},

	-- Verkaufsgebäude in der Mitte (CENTRAL_AREA_REFERENCE.png: vorne an der Straße).
	-- Position relativ zu MapCenter (X/Z); Eingang zeigt nach +Z zur Straße Richtung Plot 5.
	-- TODO_LAYOUT bis zum Bau der zentralen Service-Area.
	SellingBuilding = {
		Offset = Vector2.new(0, 82),
		Size = Vector3.new(44, 16, 28),
	},
	-- Maximale Entfernung zum Verkaufstresen
	SellCounterDistance = 14,

	-- Equipment-Shop in der Mitte (CENTRAL_AREA_REFERENCE.png: links, blau).
	-- Position relativ zu MapCenter; Eingang zeigt zur Platzmitte. TODO_LAYOUT
	EquipmentShop = {
		Offset = Vector2.new(-88, -6),
		Size = Vector3.new(40, 16, 30),
	},
	-- Machine-Shop in der Mitte (CENTRAL_AREA_REFERENCE.png: hinten, orange). Liegt zwischen
	-- den Straßen zu Plot 2 und Plot 3; Rolltor zeigt zur Platzmitte. TODO_LAYOUT
	MachineShop = {
		Offset = Vector2.new(44, -80),
		Size = Vector3.new(52, 18, 40),
	},
	-- Fahrzeughaus in der Mitte (CENTRAL_AREA_REFERENCE.png: rechts, rot). Liegt zwischen den
	-- Straßen zu Plot 3 und Plot 4; Glasfront zeigt zur Platzmitte. TODO_LAYOUT
	VehicleShop = {
		Offset = Vector2.new(92, -4),
		Size = Vector3.new(56, 18, 42),
	},
	-- Maximale Entfernung zum Lager-Terminal
	StorageTerminalDistance = 14,
	-- Maximale Entfernung zum Shop-Tresen
	ShopCounterDistance = 14,

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
