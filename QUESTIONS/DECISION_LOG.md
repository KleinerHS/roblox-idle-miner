# Decision Log

IDs fortlaufend (D-001 …). Jede Entscheidung verweist auf ihre Quellfrage und die betroffenen Systeme.

## D-001 – Projektstruktur mit Rojo

**Source Question:** – (Setup)
**Decision:** Code liegt im GitHub-Repo `KleinerHS/roblox-idle-miner` und wird per Rojo nach Roblox Studio synchronisiert. Spezifikation unter `docs/`, Visual References unter `docs/references/`.
**Affected systems:** alle

## D-002 – Halle wird ab Bodenplatte aufgebaut

**Source Question:** Q-001
**Decision:** Beim Start ist nur die Bodenplatte mit Bodenmarkierungen des Endlayouts sichtbar. Außenwände und Dach sind frühe, eigene Tycoon-Bauschritte nach Büro und Elevator.
**Affected systems:** Tycoon, Plot, BuildSteps
**Spec updated:** `docs/04` §4

## D-003 – Startgeld $800, Elevator kostet $200

**Source Question:** Q-002
**Decision:** Neuer Spieler startet mit $800. Elevator ist der Bauschritt nach dem Büro ($0) und kostet $200.
**Affected systems:** Economy, Tycoon, Default Data
**Spec updated:** `docs/02` §4, `docs/12` §32

## D-004 – Worker erst nach Lager, Spieler kann Lager per Rucksack nutzen

**Source Question:** Q-003
**Decision:** Worker sind erst einstellbar, wenn das Lager gebaut ist. Spieler kann Rucksack im Lager abladen und Material aus dem Lager in den Rucksack nehmen, um es am Tresen zu verkaufen. Garage/erstes Fahrzeug werden so gebalanced, dass sie bald nach dem Lager kommen.
**Affected systems:** Worker, Storage, Selling, Progression, Build Plan (Phase 3/4)
**Spec updated:** `docs/06` §17a

## D-005 – Spieler minet an denselben Slots wie Worker/Drills

**Source Question:** Q-004
**Decision:** Der Spieler kann an derselben Stelle minen wie Worker oder Drills, auch wenn beide Mining-Slots belegt sind. Kein dritter Spielerbereich. (Korrigiert durch Felix am 2026-10-04; die erste Fassung „Spieler kann dann nicht minen“ ist ungültig.)
**Affected systems:** Mining, Mine Shaft Layout, Worker, Drill
**Spec updated:** `docs/05` §10 (ersetzt die alte Regel „Spieler darf nicht blockiert werden“)

## D-006 – Rare Drops nach Slice A, einmaliges Überlaufen erlaubt

**Source Question:** Q-005
**Decision:** Rare Drops kommen nicht in Vertical Slice A. Bei fast vollem Rucksack darf ein Rare Drop die Kapazität einmalig überschreiten, nichts geht verloren.
**Affected systems:** Mining, Backpack, Rare Drops
**Bestätigt:** Felix, 2026-10-04 („ja passt“)
**Spec updated:** `docs/03` §7

## D-007 – Quellen für Mining Luck

**Source Question:** Q-006
**Decision:** Mining Luck kommt aus eigenen Luck-Upgrades/-Items und aus Robux-Boostern. Werte TODO_BALANCE.
**Affected systems:** Mining, Equipment, Monetarisierung
**Spec updated:** `docs/10` §17

## D-008 – Ladebereich mit Verladeturm in der Halle

**Source Question:** Q-007
**Decision:** Fahrzeuge stehen zum Beladen in der Halle. Ein kleiner Verladeturm speist das Material direkt in das Fahrzeug.
**Affected systems:** Factory Layout, Vehicles, Storage
**Spec updated:** `docs/04` §25, `docs/06` §38

## D-009 – Fahrzeugwechsel mit Ladung

**Source Question:** Q-008
**Decision:** Cargo gehört zur Fahrzeug-ID und bleibt gespeichert. Wechsel mit Ladung ist erlaubt, nichts geht verloren.
**Affected systems:** Vehicles, Data
**Spec updated:** `docs/07` §48

## D-010 – Lager-Optik

**Source Question:** Q-009
**Decision:** Regale mit allen Verschönerungsdetails wie in `FACTORY_MASTERPLAN_TOPDOWN.png`, dazu ein Silo mit Füllanzeige im Lagerbereich.
**Affected systems:** Storage Visuals, Factory Layout
**Spec updated:** `docs/04` §18

## D-011 – Smelter-Rezepte und Priorität, Legierungen später

**Source Question:** Q-010
**Decision:** Nur Metalle bekommen Schmelz-Rezepte; Coal, Edelsteine und Kristalle nur Rohverkauf. Wertvollstes Erz zuerst, im Laptop umstellbar. Legierungen kommen in einer späteren Version.
**Affected systems:** Smelter, Laptop Production
**Spec updated:** `docs/06` §29

## D-012 – Prestige: Pickaxe, Backpack, Fahrzeuge bleiben

**Source Question:** Q-011
**Decision:** Gekaufte Pickaxes, Backpacks und Fahrzeuge bleiben bei Prestige erhalten. Drills/Maschinen werden zurückgesetzt.
**Affected systems:** Prestige, Inventory, Definitions (`PersistenceClass = "Permanent"` für Pickaxes/Backpacks)
**Spec updated:** `docs/12` §54

## D-013 – Firmenidentität später gegen Robux änderbar

**Source Question:** Q-012
**Decision:** Name, Logo und Farbe sind später in der Company-App änderbar, gegen Robux. Ersteinrichtung kostenlos.
**Affected systems:** Company, Laptop, Monetarisierung
**Spec updated:** `docs/09` §25

## D-014 – Technische Grundsatzentscheidungen Phase 1

**Source Question:** – (Vorschläge aus dem Audit, von Felix mit „Weiter“ freigegeben)
**Decision:** ProfileStore (loleris/MadStudioRoblox, Apache-2.0, Commit `45c9847`) für Session Lock/Autosave/Shutdown-Save unter `src/server/Packages`. Zentrale Remote-Registry. Eigene UI-Komponenten ohne Framework. `StreamingEnabled` aktiv. Plot-Geometrie vorerst als Platzhalter aus `LayoutConfig` (TODO_LAYOUT).
**Affected systems:** Data, Remotes, UI, Map

## D-015 – Spieloberfläche auf Englisch

**Source Question:** Q-014
**Decision:** Alle Spielertexte sind Englisch. Sie stehen zentral in `src/client/UI/Strings.luau`. Projektdokumente bleiben Deutsch.
**Affected systems:** UI, Notifications, Schilder

## D-016 – Bis zu 2 Fahrzeuge gleichzeitig in der Halle

**Source Question:** Q-013
**Decision:** Bis zu 2 eigene Fahrzeuge können gleichzeitig in der Halle stehen (2 Stellplätze in der Garage). Alle weiteren gekauften Fahrzeuge werden über den Spawn-Ring aus- und eingeparkt. Ladung bleibt je Fahrzeug erhalten (D-009).
**Affected systems:** Garage, Vehicles, Factory Layout, Performance (max. 12 Fahrzeuge bei 6 Spielern)
**Spec updated:** `docs/04` §22, `docs/07` §4
## D-017 – Erste Ausrüstungsstufen, Minen kosten ab Mine 03 Geld

**Source Question:** Q-015
**Decision:** Iron Pickaxe kostet $1.000 (Level 2, Power 2, Speed 1,1 bleiben Platzhalter). Reinforced Backpack: Kapazität 1.000, Preis $1.000 (Level 2). Mine 02 wird ab Mining Level 3 ohne Geld freigeschaltet. Ab Mine 03 kosten Minen zusätzlich Geld: Mine 03 = $3.000, danach steigend (Werte offen, Q-016).
**Affected systems:** Equipment, Shop, Mines, Elevator-Menü, Economy
**Spec updated:** `docs/12` §22 (Minen ab 03 zusätzlich mit Geldpreis)
## D-018 – Minen ab 03: Level UND Geld; dritte Ausrüstungsstufe später

**Source Question:** Q-016
**Decision:** Ab Mine 03 braucht eine Mine ein Mindest-Level und zusätzlich einen Geldpreis (Mine 03 = $3.000, D-017). Level-Anforderungen und Preise ab Mine 04 sind TODO_BALANCE. Steel Pickaxe und Cargo Pack sind im Shop sichtbar, aber „Coming soon“ (nicht kaufbar), bis ihre Werte festgelegt sind.
**Affected systems:** Mines, Elevator-Menü, Shop, Balance
## D-019 – Werte dritte Ausrüstungsstufe und Minenpreis-Formel

**Source Question:** Q-016 (präzisierte Antwort)
**Decision:** Steel Pickaxe: 3 Erz/Schlag, 1,25 Schläge/s, $3.000, ab Level 4. Cargo Pack: 2.500 Kapazität, $3.500, ab Level 4. Beide sind kaufbar (nicht mehr „Coming soon“). Minen ab 03 brauchen Level UND Geld; Mine 03 = $3.000, jede weitere Mine +50 % (`BalanceConfig.MinePrice`). Level-Anforderungen ab Mine 03 bleiben TODO_BALANCE.
**Hinweis:** Mit +50 % pro Mine wächst der Preis bis Mine 100 auf ca. 4 × 10^20 $. Muss in der Balance-Phase gegen docs/03 §13 („keine absurden Zahlen“) geprüft werden.
**Affected systems:** Equipment, Shop, Mines, Balance
**Supersedes:** D-018 (Teil „Coming soon“)
## D-020 – Bauschritte Wände, Dach, Lager

**Source Question:** Q-017
**Decision:** Reihenfolge Büro → Elevator → Wände ($1.500, Level 3) → Dach ($2.500, Level 4) → Lager ($5.000, Level 5, 1.000 Kapazität).
**Affected systems:** Tycoon, Storage, Balance

## D-021 – Worker- und Elevator-Werte

**Source Question:** Q-018
**Decision:** Mining-Worker: Einstellung $2.000, Lohn $5/Min, 30 Erz/Min. Transport-Worker: $1.500, $4/Min, 50 Erz pro Gang (20 s). Slot-Puffer 200 Erz. Elevator: 100 Erz pro Fahrt alle 10 s. Entlassen ohne Rückerstattung.
**Affected systems:** Worker, Production, Elevator, Balance

## D-022 – Upgrade-Stufen Lager und Elevator

**Source Question:** Q-019
**Decision:** Lager 1.000 → 2.500 ($3.000, Lv 5) → 5.000 ($8.000, Lv 6) → 10.000 ($20.000, Lv 8) → 25.000 ($50.000, Lv 10). Elevator (Erz pro Fahrt, alle 10 s) 100 → 200 ($2.000, Lv 3) → 350 ($5.000, Lv 5) → 500 ($10.000, Lv 7) → 750 ($20.000, Lv 9) → 1.000 ($40.000, Lv 11). Kauf über die Laptop-Apps STORAGE/ELEVATOR. Weitere Stufen folgen mit den höheren Minen.
**Affected systems:** Storage, Elevator, Laptop, Balance

## D-023 – Edit-Vorschau der Welt per Studio-Plugin

**Source:** Frage von Felix (2026-10-04), warum die Welt ohne Serverstart nicht sichtbar ist; Option a) gewählt.
**Decision:** Die Welt bleibt codegebaut (keine gespeicherten Modelle in der Place-Datei). Ein lokales Studio-Plugin („Idle Miner Preview“) baut sie auf Knopfdruck im Bearbeitungsmodus mit denselben World-Buildern auf und entfernt sie wieder. Die Vorschau wird nie gespeichert und nie ins Spiel kopiert.
**Affected systems:** Werkzeuge (kein Spielsystem)

## D-024 – Schmelzer vor Förderbändern, Minenkauf vorgezogen

**Source:** Vorschlag Claude, bestätigt von Felix 2026-10-05 („D-024 ok“).
**Decision:** Förderbänder verbinden Lager und Schmelzer und hätten ohne Schmelzer keine Aufgabe; deshalb wird der Schmelzer (Phase 8) als 7a vor den Förderbändern (7b) gebaut. Der Minenkauf ab Mine 03 (eigentlich Phase 12) wird vorgezogen, weil Metalle erst ab Mine 03 vorkommen.
**Affected systems:** Build-Plan, Smelter, Mines

## D-025 – Verladeturm belädt automatisch aus dem Lager

**Source:** Felix, 2026-10-05
**Decision:** Der Turm speist direkt aus dem Lager (kein Zwischenspeicher, keine Loader-Worker). Automatisch alles Verkaufbare, wertvollstes zuerst. Manuelles Beladen entfällt komplett. Turm größer und höher.
**Affected systems:** Garage, Loading, Storage

## D-026 – Fahrphysik mit A-Chassis, Modelle später

**Source:** Felix, 2026-10-05 (Option C)
**Decision:** Fahrphysik über A-Chassis 1.7.2 (Creator Store, MPL-2.0). Die Karosserien bleiben vorerst unsere eigenen; bessere Modelle evtl. später (Kauf). Keine Modelle mit echten Markennamen.
**Affected systems:** Vehicles, Driving

## D-027 – Fahrzeughaus größer, modern mit Glaswänden

**Source:** Felix, 2026-10-05
**Decision:** Showroom deutlich größer, moderne Glasfassaden.
**Affected systems:** Vehicle Shop, Map

## D-028 – Minen 03–08, Metalle, Barren, Schmelzer

**Source Question:** Q-022
**Decision:** Mine 03 Lv 6, 04 Lv 8, 05 Lv 10, 06 Lv 12, 07 Lv 14, 08 Lv 16 (Preise nach D-019). Copper 2/2, Tin 3/3, Iron 5/4 (Geld/XP). Barren aus 2 Erz in 3 s: Copper Bar 6/5, Tin Bar 9/7, Iron Bar 14/10. Schmelzer $25.000 ab Level 10, Trichter 200, Ablage 100.
**Affected systems:** Mines, Ores, Smelter, Balance

## D-029 – Ladegeschwindigkeit Verladeturm

**Source Question:** Q-023
**Decision:** 100 Einheiten pro Sekunde.
**Affected systems:** Garage, Loading, Balance

## D-030 – Verladeturm: nur mit Fahrer, schmelzbares Erz bleibt für den Schmelzer

**Source:** Felix, 2026-10-06 („a und b“)
**Decision:** Der Turm belädt nur, wenn der Spieler im Fahrzeug sitzt (ein nur geparktes Fahrzeug leert das Lager nicht; Anzeige „GET IN TO LOAD“). Solange ein Schmelzer gebaut ist, lädt der Turm kein schmelzbares Erz – es bleibt im Lager für den Schmelzer.
**Affected systems:** Loading, Smelter

## D-031 – Werte für Drills, Fahrzeuge und Förderbänder

**Source Question:** Q-020, Q-021, Q-024 (Felix, 2026-10-10)
**Decision:** Drills wie vorgeschlagen, aber MK3 mit 500 Erz/Min (25 Erz alle 3 s) und Puffer 2.500, damit er wie MK1/MK2 5 Minuten Produktion fasst (Felix: Hinweis übernehmen). Garage und Fahrzeuge wie vorgeschlagen. Förderband MK1 $15.000 ab Level 12, 120/min; MK2 und MK3 entfallen, bis es Schmelzer-Upgrades gibt. Weicht bewusst von docs/00 §18 ab (erster Conveyor ~Level 35).
**Affected systems:** Drill, Garage, Vehicles, Conveyors, Balance

## D-032 – Verfahren der Offline-Produktion (technischer Vorschlag, Veto möglich)

**Source:** docs/14 §7–16, docs/06 §50 (Verfahren nicht festgelegt)
**Decision:** Abwesenheit in Abschnitte zu 10 s (eine Elevator-Fahrt) teilen, je Abschnitt dieselben Regeln wie online mit Raten × Dauer; höchstens 360 Abschnitte. Lohn wird offline jede Minute wie online gezahlt (unbezahlte Worker pausieren). Fenster erst ab 60 s Abwesenheit, kürzere Reconnects werden still nachgerechnet.
**Affected systems:** Offline, Production, Workers, Smelter, Conveyors
## D-033 – Prestige-Reset-Liste (aus docs/12 §53–64 und D-012, von Felix bestätigt 2026-10-10)

**Source:** docs/12 §53–64, D-012
**Decision:** Zurückgesetzt: Geld, Level/XP, alle Gebäude inkl. Hütte/Büro (docs/12 §62: Startprogression wieder anbieten), Minen, Lager inkl. Inhalt und Upgrade, Elevator-Upgrade, Worker, Drills, Förderbänder, Schmelzer, Produktionspuffer, Rucksack-Inhalt, Fahrzeugladungen. Erhalten: Prestige-Zähler/Bonus, Firmenidentität (docs/12 §60), Spitzhacken, Rucksäcke, Fahrzeuge (eingelagert bis zur neuen Garage), Robux-Käufe, Einstellungen, Statistik. Prestige nur am Laptop, nicht im Handel oder Fahrzeug, Bestätigung in 2 Schritten mit 3 s Wartezeit.
**Affected systems:** Prestige, Data, Buildings, Vehicles, Trade

## D-034 – Prestige-Bonus

**Source Question:** Q-025 (Felix, 2026-10-10)
**Decision:** Je Prestige +10 % Verkaufsgeld (XP unverändert) und +5 % Mining Speed, Speed-Bonus höchstens +50 %; additiv.
**Affected systems:** Prestige, Selling, Mining, Balance

## D-035 – Inhaltskurve als Startwert

**Source Question:** Q-026 (Felix, 2026-10-10)
**Decision:** Minen 09–100, Erze und Barren nutzen die Kurve aus BalanceConfig.ContentCurve als Startwert; Feinschliff in der Balance-Phase. D-019 (+50 % je Mine) gilt nur bis Mine 08.
**Affected systems:** Ores, Mines, Recipes, Balance

## D-036 – Ausrüstung, Drills MK4–MK6, Upgrades als Startwert; Fahrzeughaus max. 6 Fahrzeuge

**Source Question:** Q-027 (Felix, 2026-10-10)
**Decision:** Werte aus Phase 12b gelten als Startwert. Das Fahrzeughaus wird größer und stellt höchstens 6 Fahrzeuge aus. Fahrzeugmodelle dürfen vorläufig sein, Feinschliff ganz am Ende.
**Affected systems:** Equipment, Drills, Upgrades, Vehicle Shop

## D-037 – Lager aus Palettenboxen, Kisten-Kauf, Ofen-Lager

**Source:** Felix, 2026-10-10 und 2026-10-13
**Decision:** Jede Kiste fasst 1.000 einer Materialsorte. Das Firmenlager wächst über gekaufte Kisten (Laptop): 1. Kiste $100, 2. $500, 3. $1.000, danach jeweils × 1,5; Hochregale mit 4 Paletten übereinander, ~30 Regale (128 Plätze). Ersetzt die Lager-Upgrades (D-022/D-036). Der Ofen hat ein Eingangs- und ein Ausgangslager mit je 4 Hochregalen (16 Kisten) und je ein Förderband (Lager → Eingang, Ausgang → Lager). Ein großes Lager hinter der Halle folgt später.
**Affected systems:** Storage, Smelter, Conveyors, Offline, Trade, Laptop, Data (v9)

## D-038 – Hallen-Layout von Hand, schwebende Schrift statt Schilder

**Source:** Felix, 2026-10-13
**Decision:** Alle Objekte der Halle sind einzeln gruppiert. Die Place-Datei enthält `Workspace.HallLayout` (Ausbau von Plot 1); Felix verschiebt darin frei, der Server übernimmt das Layout für alle Plots. Funktionsteile behalten ihre Namen. Förderband-Strecken und Fahrzeug-Stellplätze bleiben in `LayoutConfig`. Info-Anzeigen sind schwebende, freundliche Schrift statt Schilder.
**Affected systems:** World-Builder, Plot, Building, Storage, Smelter, Garage

## D-039 – Hallen-Leben als reine Client-Optik

**Source:** Felix, 2026-10-13 („es soll nicht so leer und tot wirken“)
**Decision:** Bewegung (Stapler, Lüfter, Rundumleuchten, Ofentrommel, Schnecke, LEDs) und dekorative Arbeiter laufen nur auf dem Client über Tags (AmbientTags), ohne Spiellogik und nur in Kameranähe. Die Objekte stecken in den Gebäuden und sind wie alles andere im HallLayout verschiebbar (Laufwege = unsichtbare Punkte P1…Pn).
**Affected systems:** World-Builder, Client

## D-040 – Kein Lohn während der Offline-Zeit

**Source:** Felix, 2026-10-16
**Decision:** Während der Offline-Zeit (max. 1 h) wird kein Worker-Lohn abgezogen; alle Worker arbeiten weiter. Online gilt der Lohn unverändert (jede Minute). Ändert D-032 (dort: Lohn auch offline).
**Affected systems:** OfflineSimulation, Offline-Fenster (Lohnzeile entfällt, da 0)

## D-041 – Erz geht direkt in den Elevator, keine Transport-Worker

**Source:** Felix, 2026-10-18 (Antwort auf Q-030: „D – es soll einfach immer direkt in den Elevator gehen, auch wenn nur ein Minenarbeiter da ist“)
**Decision:** Mining-Worker und Drills liefern ihr Erz direkt in den Elevator (soweit dort Platz ist); der Slot-Puffer bleibt als Rückstau. Transport-Worker entfallen: keine Neueinstellung mehr; vorhandene werden bei der Migration v9 → v10 entlassen und die Einstellungskosten voll erstattet. Worker-Preise bleiben unverändert (Q-032).
**Affected systems:** ProductionService, OfflineSimulation, WorkerService, WorkerRoles, Laptop (Employees), Data (v10)

## D-042 – Steilere, abschnittsweise XP-Kurve; Zielzeiten

**Source:** Felix, 2026-10-18 (Q-029: L10 nach 1 h, L25 nach 5 h, L50 nach 20 h, L100 nach 50 h aktiver Spielzeit; Q-031: steilere XP-Kurve)
**Decision:** Die Level-Kurve wird abschnittsweise (docs/11 §40) und nach den Zielzeiten per Simulation eingestellt. Die Erz-XP hängen nicht mehr an der Level-Kurve, sondern an einer festen Bezugskurve (= bisherige Kurve 100 × L^1,5), damit sie unverändert bleiben und die steilere Kurve wirkt.
**Affected systems:** Leveling, BalanceConfig, ContentCurve

## D-043 – Drill-Level am Laptop (Level 1–10)

**Source:** Felix, 2026-10-18 („man soll am Laptop nicht die MK-Stufen upgraden können, sondern einen externen Upgrader für den Drill, z. B. Drill MK1 – Lv 1–10“; ersetzt die erste Umsetzung, bei der das Upgrade die MK-Stufe erhöht hat)
**Decision:** Jeder Drill hat ein eigenes Level 1–10, das am Laptop (Employees, Slot-Karte des platzierten Drills) Stufe für Stufe gekauft wird. Die MK-Stufe ändert sich nur durch Kauf eines neuen Drills im Machine-Shop. Startwerte (`BalanceConfig.Drills`, TODO_BALANCE): +5 % Produktion je Level (Lv 10 = +45 %, Felix 2026-10-18), Puffer wächst mit; Kosten Lv n → n+1 = Drill-Preis × 0,2 × 1,35^(n−1). Das Level gehört zum Drill (bleibt beim Entfernen/Handeln erhalten).
**Affected systems:** DrillService, Drills, ProductionService, OfflineSimulation, TradeService, Laptop, DrillSlot-Fenster, Types

## D-044 – Mehr Drill-Stufen

**Source:** Felix, 2026-10-18 (Rückfrage „später mehr Drills“: „A“ = mehr Drill-Stufen; Upgrade am Laptop wie D-043)
**Decision:** Sechs neue Stufen (Level 18, 35, 58, 80, 90, 100) schließen die Lücken zwischen MK3–MK6 und reichen bis Level 100: insgesamt 12 Stufen. Preis ≈ 25.000 × Erzwert auf dem Level (Regel aus D-036), Leistung geometrisch zwischen den Nachbarn, Puffer = 5 Minuten Produktion (Startwerte). Die Anzeige-Nummer folgt der Reihenfolge (MK1–MK12); die IDs bleiben stabil (z. B. `drill_mk4` heißt jetzt „Drill MK5“). Am Laptop gibt es je Drill die Level 1–10 (D-043), keine MK-Stufen-Upgrades.
**Affected systems:** Drills, Machine-Shop, Laptop
