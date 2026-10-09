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
