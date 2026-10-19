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
	-- Felix (2026-10-10): Map doppelt so groß
	PlotRingRadius = 840,

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
	-- Phase 13b (Felix 2026-10-10/13): Halle wie FACTORY_MASTERPLAN_TOPDOWN.png, nach erstem
	-- Entwurf (480 × 250) wieder kleiner; Plot mit Vorplatz, Seitenhöfen und Hinterhof wie im Bild.
	PlotSize = Vector2.new(390, 290),

	-- Hallen-Grundfläche innerhalb des Plots. Groß relativ zum Plot (docs/00 §8). TODO_LAYOUT
	HallSize = Vector2.new(300, 200),
	-- Versatz der Hallenmitte von der Plotmitte (lokal, X/Z). Vorne bleibt Platz für Zufahrt.
	HallOffset = Vector2.new(0, 18),
	-- Oberkante der Hallen-Bodenplatte (lokal Y)
	HallFloorTop = 1.4,

	-- Funktionsbereiche der Endhalle als Bodenmarkierung (D-002), Mittelpunkt X/Z und Größe
	-- X/Z, lokal zur Plotmitte. Nach FACTORY_MASTERPLAN_TOPDOWN.png. TODO_LAYOUT
	HallZones = {
		-- Anordnung wie im Referenzbild (Bild links = +X): hinten Hütte/Elevator kompakt neben dem
		-- Lager, Lager in der Mitte, Schmelze rechts über die ganze Tiefe, Garage vorne
		Office = { Center = Vector2.new(127, 92), Size = Vector2.new(42, 48) },
		Elevator = { Center = Vector2.new(127, 40), Size = Vector2.new(42, 54) },
		Storage = { Center = Vector2.new(30, 62), Size = Vector2.new(150, 110) },
		Smelter = { Center = Vector2.new(-98, 18), Size = Vector2.new(102, 198) },
		Garage = { Center = Vector2.new(51, -38), Size = Vector2.new(196, 86) },
	} :: { [string]: { Center: Vector2, Size: Vector2 } },

	-- Rolltor in der Vorderwand (X-Mitte und Breite). Zufahrt und Straße fluchten damit.
	DoorCenterX = 40,
	DoorWidth = 100,
	-- Höhe der Hallenwände (Oberkante über dem Hallenboden). TODO_LAYOUT
	HallWallHeight = 36,
	-- Höhe der Rolltor-Öffnung (Platz für spätere LKW). TODO_LAYOUT
	DoorHeight = 26,

	-- Tycoon-Kaufbuttons je BuildStep (lokal X/Z, vor dem jeweiligen Bereich). TODO_LAYOUT
	BuildButtons = {
		build_office = Vector2.new(127, 62),
		build_elevator = Vector2.new(127, 6),
		build_walls = Vector2.new(40, -30),
		build_roof = Vector2.new(40, -30),
		build_storage = Vector2.new(30, -2),
		build_garage = Vector2.new(95, -30),
		build_smelter = Vector2.new(-75, -60),
	} :: { [string]: Vector2 },

	-- Feste Förderband-Strecken (docs/06 §23, D-024), lokal zur Plotmitte: X, Höhe über dem
	-- Hallenboden, Z. Erster Punkt = Förderband-Platz ("PLACE CONVEYOR HERE"). TODO_LAYOUT
	ConveyorPaths = {
		-- Phase 13b (Felix): je ein Band – Lager → Eingangslager des Ofens, Ausgangslager → Lager.
		StorageToSmelter = { Vector3.new(-40, 1.2, 96), Vector3.new(-58, 1.2, 96) },
		SmelterToStorage = { Vector3.new(-96, 1.2, -32), Vector3.new(-45, 1.2, -32), Vector3.new(-45, 1.2, 4) },
	} :: { [string]: { Vector3 } },

	-- Garage im vorderen Hallenbereich (docs/07 §3, D-008, D-016), lokal zur Plotmitte.
	-- Phase 18b (Felix 2026-10-19, D-052): Durchfahr-Verladestraße. Einfahrt durch eine Öffnung in
	-- der linken Hallenwand (+X), geradeaus unter dem einen Verladerüssel durch, Rechtskurve und
	-- Ausfahrt durch das Rolltor. Stellplätze (Ausparken) liegen vor dem Rüssel an der Vorderwand,
	-- Fahrzeuge stehen mit der Front in Fahrtrichtung (-X). TODO_LAYOUT
	Garage = {
		-- Mitte der Stellplätze (X/Z), Größe einer Stellfläche (Breite, Länge) und Drehung (Grad;
		-- 90 = Front zeigt nach -X, in Fahrtrichtung der Verladestraße)
		Bays = { Vector2.new(127, -62), Vector2.new(127, -74.5) },
		BaySize = Vector2.new(12.5, 30),
		BayYaw = 90,
		-- Leuchtring zur Fahrzeugauswahl (docs/07 §4)
		Ring = Vector2.new(136, -12),
		RingRadius = 5,
		-- Verladeturm (D-008) hinter der Spur, Portal über die Spur bis zum Rüssel
		Tower = Vector2.new(80, -16),
		-- Der eine Verladerüssel (Mitte über der Spur)
		Chute = Vector2.new(80, -41),
		ChuteCount = 1,
		-- Länge des Zuführrohrs vom Turm nach hinten bis zum Lager
		TowerFeedLength = 19,
		-- Höchstabstand Ladefläche ↔ Rüssel zum Beladen (Phase 6c)
		LoadDistance = 14,
		-- Verladestraße: Mittellinie Z, Breite, Beginn der Rechtskurve (X), Kurvenradius
		Lane = { Z = -41, Width = 24, TurnX = 50, TurnRadius = 32 },
		-- Öffnung in der linken Hallenwand (Z von/bis, Höhe über dem Hallenboden)
		SideOpening = { Z1 = -59, Z2 = -24, Height = 26 },
		-- Tor im linken Zaun (Z von/bis); vorne weit offen, weil die Anhänger in der Kurve vor dem
		-- Tor nach innen ziehen (Fahrtest Phase 18c)
		Gate = { Z1 = -110, Z2 = -20 },
	},
	-- Zufahrt zur Verladestraße außen am Grundstück (D-052): zweigt von der Zufahrtsstraße ab,
	-- läuft links am Zaun entlang und biegt zum Tor ein. JunctionZ = Abzweig an der Zufahrt,
	-- OuterX = Mittellinie des Stücks neben dem Zaun, Radius der beiden Kurven. TODO_LAYOUT
	SideRoad = {
		JunctionZ = -230,
		OuterX = 262,
		Radius = 46,
	},
	ButtonSize = Vector3.new(7, 0.4, 7),

	-- Spawnpunkt solange das Büro nicht gebaut ist: neben dem Büro-Kaufbutton.
	-- Danach liegt der Spawn auf dem Bett in der Hütte (docs/04 §7). TODO_LAYOUT
	SpawnOffset = Vector3.new(110, 4, 62),

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
		-- Sektor zwischen den Straßen zu Plot 4 und Plot 5, Eingang zum Kreisverkehr
		Offset = Vector2.new(75, 130),
		Size = Vector3.new(44, 16, 28),
	},
	-- Maximale Entfernung zum Verkaufstresen
	SellCounterDistance = 14,

	-- Equipment-Shop in der Mitte (CENTRAL_AREA_REFERENCE.png: links, blau).
	-- Position relativ zu MapCenter; Eingang zeigt zur Platzmitte. TODO_LAYOUT
	EquipmentShop = {
		Offset = Vector2.new(-150, 0),
		Size = Vector3.new(40, 16, 30),
	},
	-- Machine-Shop in der Mitte (CENTRAL_AREA_REFERENCE.png: hinten, orange). Liegt zwischen
	-- den Straßen zu Plot 2 und Plot 3; Rolltor zeigt zur Platzmitte. TODO_LAYOUT
	MachineShop = {
		Offset = Vector2.new(80, -139),
		Size = Vector3.new(52, 18, 40),
	},
	-- Fahrzeughaus in der Mitte (CENTRAL_AREA_REFERENCE.png: rechts, rot). Liegt zwischen den
	-- Straßen zu Plot 3 und Plot 4; Glasfront zeigt zur Platzmitte. TODO_LAYOUT
	VehicleShop = {
		Offset = Vector2.new(185, 0),
		-- Großer Glas-Showroom (D-027): Breite, Höhe, Tiefe. Phase 12c: Platz für 6 Fahrzeuge
		-- in zwei Reihen (Felix); bleibt innerhalb des Platzes (CenterPlazaRadius) und frei
		-- vom Machine-Shop.
		Size = Vector3.new(90, 22, 68),
		-- Höchstzahl ausgestellter Fahrzeuge (zwei Reihen à drei)
		DisplaySlots = 6,
	},
	-- Maximale Entfernung zum Lager-Terminal
	StorageTerminalDistance = 14,
	-- Maximale Entfernung zum Shop-Tresen
	ShopCounterDistance = 14,

	-- Elevator: maximale Entfernung zum Käfig, um ihn zu benutzen
	ElevatorUseDistance = 16,

	-- Umgebung (Phase 13a, docs/19 §4): Wiese, Seen zwischen den Plots, Bergkette, Wald, Felsen.
	-- Rein optisch; Zahlen sind Gestaltungswerte (TODO_LAYOUT), keine Balance.
	Environment = {
		Seed = 42,
		-- Wiese als Kacheln (Teilgröße max. 2048): Kachelgröße und Anzahl je Richtung
		GroundTile = 2040,
		GroundTiles = 2,
		-- Seen in den Lücken zwischen den Plots (Winkel wie PlotAngles)
		LakeAngles = { 0, 120, 240 },
		LakeRadius = 860,
		LakeSize = 80,
		-- Bergkette als Ring um die Map
		MountainCount = 52,
		MountainInner = 1480,
		MountainOuter = 1720,
		MountainMinHeight = 240,
		MountainMaxHeight = 420,
		-- Wald bis zu diesem Radius, Felsen bis zur Bergkette
		TreeCount = 1000,
		ForestOuter = 1400,
		RockCount = 220,
		-- Wahrzeichen wie im Referenzbild (X/Z): Wasserturm hinter dem Machine-Shop,
		-- Windrad hinter dem Fahrzeughaus; Holzhütten in den freien Sektoren
		WaterTower = Vector2.new(120, -210),
		Windmill = Vector2.new(255, 60),
		Cabins = { Vector2.new(-75, -150), Vector2.new(-80, 140), Vector2.new(-60, -175) },
		-- Freiflächen um die Wahrzeichen (Radius)
		LandmarkClearance = 24,
	},

	-- Zaun
	FenceHeight = 3,
	FenceThickness = 1,
	-- Breite der Zufahrtslücke im vorderen Zaun.
	EntranceWidth = 110,

	-- Platzhalter-Zentrum und Straßen (nur zur Orientierung, bis die Map gebaut wird).
	-- Platz in der Mitte mit Kreisverkehr, Speichen und Shops dazwischen (MAP_MASTERPLAN)
	CenterPlazaRadius = 280,
	-- Kreisverkehr um den Brunnen: Innen-/Außenradius der Fahrbahn
	RoundaboutInner = 40,
	RoundaboutOuter = 64,
	RoadWidth = 28,
}

return table.freeze(LayoutConfig)
