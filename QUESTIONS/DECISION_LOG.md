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