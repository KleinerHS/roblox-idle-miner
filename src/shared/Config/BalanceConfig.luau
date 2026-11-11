--!strict
-- Zentrale Balancewerte. Keine Balancezahlen in anderen Scripts.
-- Seit dem Neubalancing vom 2026-11-11 (D-087) stammen alle Werte aus Felix' Balancing-Datei
-- (BALANCING/Balancing_Neuentwurf_2026-11-11.xlsx, Rechenmodell tools/balancing_20261109/).
-- Status aller neuen Werte: TESTING_REQUIRED (im Studio-Spiel noch zu prüfen).

local BalanceConfig = {
	-- Startgeld eines neuen Spielers.
	StartCash = 80, -- D-087 (vorher 800, D-003)

	-- XP-Bedarf je Level (D-087): Table[L] = XP von Level L auf L + 1, Level 1–120 einzeln aus dem
	-- Rechenmodell. Ab Level 121 wächst der letzte Wert je Level um AfterTableGrowth (1 = gleich bleibend).
	-- Der Bedarf wird im Spiel ausschließlich hier gelesen (Util/Leveling).
	Leveling = {
		Table = {
			45, 270, 674, 674, 966, 966, 1686, 1686, 2096, 4977,
			6998, 7478, 8771, 8771, 10110, 11555, 13122, 13858, 15549, 17472,
			19438, 19438, 22459, 24931, 33382, 33382, 36381, 41083, 44537, 47002,
			50754, 53706, 63474, 63474, 71113, 74654, 79763, 86315, 91944, 98926,
			109623, 109623, 124078, 124078, 144802, 144802, 152886, 166066, 180979, 253629,
			266871, 266871, 309562, 309562, 356961, 356961, 380918, 414658, 433728, 696659,
			719460, 722242, 812408, 812408, 909213, 910105, 935956, 1020738, 1048267, 1048267,
			1189337, 1189337, 1202129, 1202129, 2071130, 2071130, 2086867, 2086867, 2347601, 2347601,
			2357940, 2357940, 2637642, 2637642, 2640572, 2640572, 2935704, 2935704, 2935704, 6466939,
			6724602, 6724602, 6936522, 6936522, 7205696, 7205696, 7425170, 7425170, 7647031, 7647031,
			7647031, 7647031, 7647031, 7647031, 7647031, 7647031, 7647031, 7647031, 7647031, 7647031,
			7647031, 7647031, 7647031, 7647031, 7647031, 7647031, 7647031, 7647031, 7647031, 7647031,
		},
		AfterTableGrowth = 1, -- TODO_BALANCE: Fortsetzung nach Level 120 (Modell endet bei 120)
	},

	-- Verkaufswert und Mining-XP je Erz (D-087). Werte mit Nachkommastellen: Der Verkaufserlös wird
	-- je Verkauf abgerundet, XP bleiben genau.
	OreValues = {
		ore_coal = { SellValue = 2, XPValue = 1 },
		ore_copper = { SellValue = 2.4, XPValue = 1.71 },
		ore_tin = { SellValue = 2.88, XPValue = 2.45 },
		ore_iron = { SellValue = 3.46, XPValue = 3.21 },
		ore_lead = { SellValue = 4.15, XPValue = 3.99 },
		ore_zinc = { SellValue = 4.98, XPValue = 4.8 },
		ore_silver = { SellValue = 5.97, XPValue = 5.63 },
		ore_nickel = { SellValue = 7.17, XPValue = 6.49 },
		ore_cobalt = { SellValue = 8.6, XPValue = 7.37 },
		ore_chromium = { SellValue = 10.32, XPValue = 8.27 },
		ore_manganese = { SellValue = 12.38, XPValue = 9.2 },
		ore_aluminum = { SellValue = 14.86, XPValue = 10.15 },
		ore_titanium = { SellValue = 17.83, XPValue = 11.13 },
		ore_tungsten = { SellValue = 21.4, XPValue = 12.13 },
		ore_platinum = { SellValue = 25.68, XPValue = 13.15 },
		ore_palladium = { SellValue = 30.81, XPValue = 14.2 },
		ore_osmium = { SellValue = 36.98, XPValue = 15.27 },
		ore_iridium = { SellValue = 44.37, XPValue = 16.37 },
		ore_rhodium = { SellValue = 53.25, XPValue = 17.49 },
		ore_uranium = { SellValue = 63.9, XPValue = 18.63 },
		ore_mythril = { SellValue = 76.68, XPValue = 19.8 },
		ore_obsidian = { SellValue = 92.01, XPValue = 20.99 },
		ore_ruby = { SellValue = 110.41, XPValue = 22.21 },
		ore_sapphire = { SellValue = 132.49, XPValue = 23.45 },
		ore_emerald = { SellValue = 158.99, XPValue = 24.71 },
		ore_amethyst = { SellValue = 190.79, XPValue = 26 },
		ore_topaz = { SellValue = 228.95, XPValue = 27.31 },
		ore_aquamarine = { SellValue = 274.74, XPValue = 28.65 },
		ore_opal = { SellValue = 329.69, XPValue = 30.01 },
		ore_black_opal = { SellValue = 395.63, XPValue = 31.39 },
		ore_jade = { SellValue = 474.75, XPValue = 32.8 },
		ore_amber = { SellValue = 569.7, XPValue = 34.23 },
		ore_meteorite = { SellValue = 683.64, XPValue = 35.69 },
		ore_star_metal = { SellValue = 820.37, XPValue = 37.17 },
		ore_luminous_crystal = { SellValue = 984.45, XPValue = 38.67 },
		ore_dragonstone = { SellValue = 1181.34, XPValue = 40.2 },
		ore_netherium = { SellValue = 1417.6, XPValue = 41.75 },
		ore_celestial_metal = { SellValue = 1701.12, XPValue = 43.33 },
		ore_astralium = { SellValue = 2041.35, XPValue = 44.93 },
		ore_aetherium = { SellValue = 2449.62, XPValue = 46.55 },
		ore_void = { SellValue = 2939.54, XPValue = 48.2 },
		ore_darksteel = { SellValue = 3527.45, XPValue = 49.87 },
		ore_sun_crystal = { SellValue = 4232.94, XPValue = 51.57 },
		ore_moon_crystal = { SellValue = 5079.53, XPValue = 53.29 },
		ore_galaxium = { SellValue = 6095.44, XPValue = 55.03 },
		ore_cosmium = { SellValue = 7314.52, XPValue = 56.8 },
		ore_quantium = { SellValue = 8777.43, XPValue = 58.59 },
		ore_singularium = { SellValue = 10532.91, XPValue = 60.41 },
		ore_primal_crystal = { SellValue = 12639.5, XPValue = 62.25 },
		ore_diamond = { SellValue = 15167.4, XPValue = 64.11 },
	} :: { [string]: { SellValue: number, XPValue: number } },

	-- Barren aus dem Schmelzer (D-087), aus 2 Erzen.
	BarValues = {
		bar_copper = { SellValue = 6.72, XPValue = 3.76 },
		bar_tin = { SellValue = 8.06, XPValue = 5.39 },
		bar_iron = { SellValue = 9.69, XPValue = 7.06 },
		bar_lead = { SellValue = 11.62, XPValue = 8.78 },
		bar_zinc = { SellValue = 13.94, XPValue = 10.56 },
		bar_silver = { SellValue = 16.72, XPValue = 12.39 },
		bar_nickel = { SellValue = 20.08, XPValue = 14.28 },
		bar_cobalt = { SellValue = 24.08, XPValue = 16.21 },
		bar_chromium = { SellValue = 28.9, XPValue = 18.19 },
		bar_manganese = { SellValue = 34.66, XPValue = 20.24 },
		bar_aluminum = { SellValue = 41.61, XPValue = 22.33 },
		bar_titanium = { SellValue = 49.92, XPValue = 24.49 },
		bar_tungsten = { SellValue = 59.92, XPValue = 26.69 },
		bar_platinum = { SellValue = 71.9, XPValue = 28.93 },
		bar_palladium = { SellValue = 86.27, XPValue = 31.24 },
		bar_osmium = { SellValue = 103.54, XPValue = 33.59 },
		bar_iridium = { SellValue = 124.24, XPValue = 36.01 },
		bar_rhodium = { SellValue = 149.1, XPValue = 38.48 },
		bar_mythril = { SellValue = 214.7, XPValue = 43.56 },
		bar_star_metal = { SellValue = 2297.04, XPValue = 81.77 },
		bar_celestial_metal = { SellValue = 4763.14, XPValue = 95.33 },
		bar_astralium = { SellValue = 5715.78, XPValue = 98.85 },
	} :: { [string]: { SellValue: number, XPValue: number } },

	-- Verladeturm (D-025): Einheiten pro Sekunde vom Lager ins Fahrzeug. bestätigt (D-029).
	Loading = {
		UnitsPerSecond = 100, -- Felix (D-029), Mindestrate, bestätigt D-087
		-- jedes Fahrzeug ist nach höchstens so vielen Sekunden voll (D-046)
		FullLoadSeconds = 4, -- D-087
	},

	-- Schmelzer (docs/06 §28–35).
	Smelter = {
		OrePerBar = 2, -- D-087
		-- 0,04 s je Barren = 1.500 Barren pro Minute (D-087); der Server verarbeitet gebündelt
		SecondsPerBar = 0.04, -- D-087 (vorher 3)
		-- Eingangs- und Ausgangslager des Ofens: je 4 Hochregale × 4 Paletten (Felix D-037)
		InputCrates = 16, -- Felix (D-037)
		OutputCrates = 16, -- Felix (D-037)
	},

	-- Minen 001–100 (D-087): Mindest-Level und Kaufpreis je Mine einzeln. Minen ab Preis > 0
	-- werden zusätzlich gekauft (der Reihe nach, D-017/D-019).
	MineUnlocks = {
		mine_001 = { RequiredLevel = 1, Price = 0 }, mine_002 = { RequiredLevel = 2, Price = 0 },
		mine_003 = { RequiredLevel = 3, Price = 58 }, mine_004 = { RequiredLevel = 4, Price = 61 },
		mine_005 = { RequiredLevel = 5, Price = 78 }, mine_006 = { RequiredLevel = 6, Price = 82 },
		mine_007 = { RequiredLevel = 7, Price = 100 }, mine_008 = { RequiredLevel = 8, Price = 110 },
		mine_009 = { RequiredLevel = 9, Price = 140 }, mine_010 = { RequiredLevel = 10, Price = 140 },
		mine_011 = { RequiredLevel = 11, Price = 180 }, mine_012 = { RequiredLevel = 12, Price = 180 },
		mine_013 = { RequiredLevel = 13, Price = 230 }, mine_014 = { RequiredLevel = 14, Price = 240 },
		mine_015 = { RequiredLevel = 15, Price = 290 }, mine_016 = { RequiredLevel = 16, Price = 300 },
		mine_017 = { RequiredLevel = 17, Price = 380 }, mine_018 = { RequiredLevel = 18, Price = 390 },
		mine_019 = { RequiredLevel = 19, Price = 480 }, mine_020 = { RequiredLevel = 20, Price = 2500 },
		mine_021 = { RequiredLevel = 21, Price = 4100 }, mine_022 = { RequiredLevel = 22, Price = 6300 },
		mine_023 = { RequiredLevel = 23, Price = 8000 }, mine_024 = { RequiredLevel = 24, Price = 12000 },
		mine_025 = { RequiredLevel = 25, Price = 24000 }, mine_026 = { RequiredLevel = 26, Price = 24000 },
		mine_027 = { RequiredLevel = 27, Price = 28000 }, mine_028 = { RequiredLevel = 28, Price = 38000 },
		mine_029 = { RequiredLevel = 29, Price = 48000 }, mine_030 = { RequiredLevel = 30, Price = 64000 },
		mine_031 = { RequiredLevel = 31, Price = 69000 }, mine_032 = { RequiredLevel = 32, Price = 83000 },
		mine_033 = { RequiredLevel = 33, Price = 87000 }, mine_034 = { RequiredLevel = 34, Price = 110000 },
		mine_035 = { RequiredLevel = 35, Price = 110000 }, mine_036 = { RequiredLevel = 36, Price = 150000 },
		mine_037 = { RequiredLevel = 37, Price = 160000 }, mine_038 = { RequiredLevel = 38, Price = 190000 },
		mine_039 = { RequiredLevel = 39, Price = 200000 }, mine_040 = { RequiredLevel = 40, Price = 190000 },
		mine_041 = { RequiredLevel = 41, Price = 210000 }, mine_042 = { RequiredLevel = 42, Price = 330000 },
		mine_043 = { RequiredLevel = 43, Price = 330000 }, mine_044 = { RequiredLevel = 44, Price = 340000 },
		mine_045 = { RequiredLevel = 45, Price = 340000 }, mine_046 = { RequiredLevel = 46, Price = 450000 },
		mine_047 = { RequiredLevel = 47, Price = 450000 }, mine_048 = { RequiredLevel = 48, Price = 540000 },
		mine_049 = { RequiredLevel = 49, Price = 590000 }, mine_050 = { RequiredLevel = 50, Price = 1100000 },
		mine_051 = { RequiredLevel = 51, Price = 1100000 }, mine_052 = { RequiredLevel = 52, Price = 1300000 },
		mine_053 = { RequiredLevel = 53, Price = 1300000 }, mine_054 = { RequiredLevel = 54, Price = 1700000 },
		mine_055 = { RequiredLevel = 55, Price = 1700000 }, mine_056 = { RequiredLevel = 56, Price = 2300000 },
		mine_057 = { RequiredLevel = 57, Price = 2300000 }, mine_058 = { RequiredLevel = 58, Price = 2800000 },
		mine_059 = { RequiredLevel = 59, Price = 3100000 }, mine_060 = { RequiredLevel = 60, Price = 5400000 },
		mine_061 = { RequiredLevel = 61, Price = 5900000 }, mine_062 = { RequiredLevel = 62, Price = 7000000 },
		mine_063 = { RequiredLevel = 63, Price = 7000000 }, mine_064 = { RequiredLevel = 64, Price = 9200000 },
		mine_065 = { RequiredLevel = 65, Price = 9100000 }, mine_066 = { RequiredLevel = 66, Price = 12000000 },
		mine_067 = { RequiredLevel = 67, Price = 12000000 }, mine_068 = { RequiredLevel = 68, Price = 19000000 },
		mine_069 = { RequiredLevel = 69, Price = 21000000 }, mine_070 = { RequiredLevel = 70, Price = 18000000 },
		mine_071 = { RequiredLevel = 71, Price = 19000000 }, mine_072 = { RequiredLevel = 72, Price = 24000000 },
		mine_073 = { RequiredLevel = 73, Price = 23000000 }, mine_074 = { RequiredLevel = 74, Price = 28000000 },
		mine_075 = { RequiredLevel = 75, Price = 41000000 }, mine_076 = { RequiredLevel = 76, Price = 73000000 },
		mine_077 = { RequiredLevel = 77, Price = 72000000 }, mine_078 = { RequiredLevel = 78, Price = 82000000 },
		mine_079 = { RequiredLevel = 79, Price = 89000000 }, mine_080 = { RequiredLevel = 80, Price = 80000000 },
		mine_081 = { RequiredLevel = 81, Price = 79000000 }, mine_082 = { RequiredLevel = 82, Price = 100000000 },
		mine_083 = { RequiredLevel = 83, Price = 100000000 }, mine_084 = { RequiredLevel = 84, Price = 130000000 },
		mine_085 = { RequiredLevel = 85, Price = 130000000 }, mine_086 = { RequiredLevel = 86, Price = 150000000 },
		mine_087 = { RequiredLevel = 87, Price = 150000000 }, mine_088 = { RequiredLevel = 88, Price = 190000000 },
		mine_089 = { RequiredLevel = 89, Price = 190000000 }, mine_090 = { RequiredLevel = 90, Price = 600000000 },
		mine_091 = { RequiredLevel = 91, Price = 660000000 }, mine_092 = { RequiredLevel = 92, Price = 770000000 },
		mine_093 = { RequiredLevel = 93, Price = 770000000 }, mine_094 = { RequiredLevel = 94, Price = 980000000 },
		mine_095 = { RequiredLevel = 95, Price = 980000000 }, mine_096 = { RequiredLevel = 96, Price = 1200000000 },
		mine_097 = { RequiredLevel = 97, Price = 1200000000 }, mine_098 = { RequiredLevel = 98, Price = 1400000000 },
		mine_099 = { RequiredLevel = 99, Price = 1400000000 }, mine_100 = { RequiredLevel = 100, Price = 1900000000 },
	} :: { [string]: { RequiredLevel: number, Price: number? } },

	-- Firmenlager aus Palettenboxen (Phase 13b-2, Felix D-037): jede Kiste fasst CrateSize einer
	-- Materialsorte; Kisten werden am Laptop gekauft.
	Storage = {
		CrateSize = 1000, -- Felix (D-037)
		MaxCrates = 192, -- Felix (2026-10-13)
		StartCrates = 0, -- Felix (D-037)
		-- Preis jeder einzelnen Kiste 1–192 (D-087). Darüber hinaus × CrateGrowth.
		CratePrices = {
			60, 190, 390, 630, 930, 1300, 1600, 2100, 2500, 3000, 3500, 4100,
			4700, 5300, 6000, 6700, 7400, 8200, 9000, 9800, 11000, 11000, 12000, 13000,
			14000, 15000, 16000, 17000, 18000, 19000, 21000, 22000, 23000, 24000, 25000, 27000,
			28000, 29000, 30000, 32000, 33000, 34000, 36000, 37000, 39000, 40000, 42000, 43000,
			45000, 46000, 48000, 50000, 51000, 53000, 55000, 56000, 58000, 60000, 61000, 63000,
			65000, 67000, 69000, 71000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000,
			88000, 90000, 92000, 95000, 97000, 99000, 100000, 100000, 110000, 110000, 110000, 110000,
			110000, 120000, 120000, 120000, 120000, 130000, 130000, 130000, 130000, 140000, 140000, 140000,
			140000, 150000, 150000, 150000, 150000, 160000, 160000, 160000, 160000, 170000, 170000, 170000,
			170000, 180000, 180000, 180000, 190000, 190000, 190000, 190000, 200000, 200000, 200000, 210000,
			210000, 210000, 210000, 220000, 220000, 220000, 230000, 230000, 230000, 240000, 240000, 240000,
			240000, 250000, 250000, 250000, 260000, 260000, 260000, 270000, 270000, 270000, 280000, 280000,
			280000, 290000, 290000, 290000, 300000, 300000, 300000, 310000, 310000, 310000, 320000, 320000,
			320000, 330000, 330000, 340000, 340000, 340000, 350000, 350000, 350000, 360000, 360000, 360000,
			370000, 370000, 380000, 380000, 380000, 390000, 390000, 390000, 400000, 400000, 410000, 410000,
			410000, 420000, 420000, 420000, 430000, 430000, 440000, 440000, 440000, 450000, 450000, 460000,
		},
		CrateGrowth = 1, -- D-087 (alle Kisten stehen einzeln in CratePrices)
		-- keine Kapazitätsstufen mehr (Lager wächst über Kisten)
		Upgrades = {} :: { { Capacity: number, Cost: number, RequiredLevel: number } },
	},

	-- Worker (docs/05 §5–9).
	Workers = {
		Mining = {
			HireCost = 180, -- D-087 (vorher 2.000)
			WagePerMinute = 1, -- D-087 (vorher 5)
			OrePerMinute = 25, -- D-087 (vorher 30)
		},
		-- Transport-Worker gibt es seit D-041 nicht mehr (nur noch für die Migration alter Profile)
		Transport = {
			HireCost = 1500, -- Felix (D-021)
			WagePerMinute = 4, -- Felix (D-021)
			CarryAmount = 50, -- Felix (D-021)
			TripSeconds = 20, -- Felix (D-021)
		},
		-- Puffer je belegtem Mining-Slot (Erz wartet auf Abholung, docs/06 §20)
		SlotBuffer = 150, -- D-087 (vorher 200)
		-- Abstand der Lohnabrechnung (docs/05 §6: jede Minute)
		PayrollSeconds = 60,
		-- Rückerstattung beim Entlassen (Anteil der Einstellungskosten)
		FireRefund = 0, -- Felix (D-021)
	},

	-- Rare Drops beim manuellen Mining (docs/03 §7–8, docs/11 §18–21, D-006). Nur Spieler, nie
	-- Worker/Drills/Offline. Ein Rare Event ist ENTWEDER Mengen-Multiplikator ODER ein Rare Ore.
	-- D-087: Mengenbonus 1 % je Hit, nächstes Erz 0,15 % je Hit (= 1 % × 15 %), wie bisher.
	RareDrops = {
		BaseChance = 0.01, -- bestätigt D-087
		OreShare = 0.15, -- bestätigt D-087 (ergibt 0,15 % je Hit für ein besseres Erz)
		-- Gewichte für den Multiplikator ×2 … ×10 (höher = häufiger)
		MultiplierWeights = { 30, 22, 15, 10, 8, 6, 4, 3, 2 }, -- TODO_BALANCE (×2 … ×10)
		-- Gewichte für 1 … 4 Erzstufen weiter (je weiter, desto seltener, docs/11 §19)
		TierWeights = { 8, 4, 2, 1 }, -- TODO_BALANCE
		RareOreAmount = 1, -- docs/03 §7: genau ein seltenes Erz
	},

	-- Mining Luck (docs/10 §17, D-007): erhöht nur die Rare-Drop-Chance: Chance × (1 + Level × Bonus).
	-- D-087: Preis und Mindest-Level je Stufe einzeln.
	Luck = {
		MaxLevel = 10, -- D-087
		ChanceBonusPerLevel = 0.1, -- D-087 (Lv 10 = doppelte Chance)
		Prices = { 1306, 6878, 24119, 71486, 224830, 580718, 1639662, 7943318, 46708151, 266754413 }, -- D-087
		RequiredLevels = { 5, 12, 20, 28, 36, 44, 52, 62, 74, 86 }, -- D-087
	},

	-- Drill-Level am Laptop (D-043): jeder Drill hat eigene Upgrade-Level 1…MaxLevel.
	--   Produktion × (1 + (Level − 1) × ProductionBonusPerLevel), Puffer wächst mit
	--   Kosten Level n → n+1 = Drill-Preis × UpgradeCostShare × UpgradeCostGrowth^(n − 1)
	Drills = {
		MaxLevel = 10, -- Felix (D-043)
		ProductionBonusPerLevel = 0.04, -- D-087 (Lv 10 = +36 %)
		UpgradeCostShare = 0.03, -- D-087
		UpgradeCostGrowth = 1.18, -- D-087
	},

	-- Elevator-Materialtransport (docs/06 §9–11).
	Elevator = {
		StartCapacity = 60, -- D-087 Erz pro Fahrt (vorher 100)
		CycleSeconds = 10, -- Felix (D-021) eine Fahrt alle n Sekunden
		-- Kapazitätsstufen über die Elevator-App im Laptop (D-087)
		Upgrades = {
		{ Capacity = 100, Cost = 200, RequiredLevel = 5 },
		{ Capacity = 160, Cost = 540, RequiredLevel = 10 },
		{ Capacity = 240, Cost = 1600, RequiredLevel = 18 },
		{ Capacity = 350, Cost = 12000, RequiredLevel = 26 },
		{ Capacity = 500, Cost = 77000, RequiredLevel = 35 },
		{ Capacity = 700, Cost = 260000, RequiredLevel = 45 },
		{ Capacity = 900, Cost = 1100000, RequiredLevel = 55 },
		{ Capacity = 1200, Cost = 6000000, RequiredLevel = 65 },
		{ Capacity = 1600, Cost = 25000000, RequiredLevel = 75 },
		{ Capacity = 2200, Cost = 130000000, RequiredLevel = 85 },
		},
	},

	-- Prestige (docs/12 §50–64). Ab Level 100. Bonus additiv je Prestige.
	Prestige = {
		RequiredLevel = 100,
		-- Verkaufserlös (Geld, nicht XP) +n je Prestige: Faktor = 1 + n * Count
		MoneyBonusPerPrestige = 0.05, -- D-087 (vorher 0,10)
		-- Mining Speed (Hits pro Sekunde) +n je Prestige, gedeckelt
		SpeedBonusPerPrestige = 0, -- D-087 (vorher 0,05)
		SpeedBonusMax = 0, -- D-087 (vorher 0,50)
	},

	-- Kurven für Inhalte ohne festen Einzelwert (Phase 12, ContentCurve.luau). Seit D-087 haben alle
	-- Erze, Barren und Minen feste Werte; die Kurven sind nur noch Rückfall für neue Einträge.
	ContentCurve = {
		OreValueGrowthEarly = 1.2, -- D-087
		EarlyUntilTier = 50, -- D-087
		OreValueGrowthLate = 1.2, -- D-087
		XPDivisor = 2000,
		XPReferenceBase = 100,
		XPReferenceExponent = 1.5,
		BarValueFactor = 1.4, -- D-087
		BarXPFactor = 1.1, -- D-087
		LevelAnchorMine = 8,
		LevelAnchorLevel = 16,
		LastMine = 100,
		LastMineLevel = 100,
		MinePriceOreMultiple = 4500,
		-- Spätspiel-Aufschlag (D-046) seit D-087 aus: alle Preise sind schon Endpreise
		LatePriceStartLevel = 40,
		LatePriceGrowth = 1, -- D-087 (vorher 1,15)
		SecondMinePriceFactor = 1.25,
	},

	-- Minenpreis-Formel (nur noch Rückfall für Minen ohne Preis in MineUnlocks)
	MinePrice = {
		FirstPaidMine = 3,
		BasePrice = 3000,
		Growth = 1.5,
		LastFormulaMine = 8,
	},
}

return table.freeze(BalanceConfig)
