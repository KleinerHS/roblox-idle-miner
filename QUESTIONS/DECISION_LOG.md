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
**Decision:** Jeder Drill hat ein eigenes Level 1–10, das am Laptop (Employees, Slot-Karte des platzierten Drills) Stufe für Stufe gekauft wird. Die MK-Stufe ändert sich nur durch Kauf eines neuen Drills im Machine-Shop. Startwerte (`BalanceConfig.Drills`, TODO_BALANCE): +10 % Produktion je Level (Lv 10 = +90 %), Puffer wächst mit; Kosten Lv n → n+1 = Drill-Preis × 0,05 × 1,35^(n−1) (Felix 2026-10-18: „5%“ = Kostenanteil statt 20 %, damit ein voll aufgewerteter Drill etwa so viel kostet wie die nächste MK-Stufe; MK1 alle 9 Level ≈ $15.900 für 114 Erz/min, MK2 neu $25.000 für 120). Das zwischenzeitliche +5 % Produktion (45683f6) war ein Missverständnis und ist zurückgenommen. Das Level gehört zum Drill (bleibt beim Entfernen/Handeln erhalten).
**Affected systems:** DrillService, Drills, ProductionService, OfflineSimulation, TradeService, Laptop, DrillSlot-Fenster, Types

## D-044 – Mehr Drill-Stufen

**Source:** Felix, 2026-10-18 (Rückfrage „später mehr Drills“: „A“ = mehr Drill-Stufen; Upgrade am Laptop wie D-043)
**Decision:** Sechs neue Stufen (Level 18, 35, 58, 80, 90, 100) schließen die Lücken zwischen MK3–MK6 und reichen bis Level 100: insgesamt 12 Stufen. Preis ≈ 25.000 × Erzwert auf dem Level (Regel aus D-036), Leistung geometrisch zwischen den Nachbarn, Puffer = 5 Minuten Produktion (Startwerte). Die Anzeige-Nummer folgt der Reihenfolge (MK1–MK12); die IDs bleiben stabil (z. B. `drill_mk4` heißt jetzt „Drill MK5“). Am Laptop gibt es je Drill die Level 1–10 (D-043), keine MK-Stufen-Upgrades.
**Affected systems:** Drills, Machine-Shop, Laptop

## D-045 – Rare Drops und Mining Luck umgesetzt (Startwerte)

**Source:** Felix, 2026-10-18 („ja dann mach weiter“ auf den Vorschlag Rare Drops); Regeln aus docs/03 §7–8, docs/11 §18–21, D-006, D-007
**Decision:** Bei jedem erfolgreichen manuellen Hit würfelt der Server einen Rare Drop (nur Spieler, nie Worker/Drills/Offline). Ein Rare Event ist entweder „LUCKY DROP“ – der Hit bringt ×2 bis ×10 seiner Menge – oder „RARE DROP“ – genau 1 Erz aus den nächsten 1–4 Erzstufen (weiter = seltener). Der Drop darf die Rucksackkapazität einmalig überschreiten (D-006). Mining Luck: 10 Stufen, gekauft am Laptop in der App LUCK (Felix 2026-10-18: „Mining Luck in den Laptop verschieben“, vorher Equipment-Shop), je Stufe +15 % relative Chance. Startwerte (TODO_BALANCE): Grundchance 1 % je Hit, 15 % der Rare Events sind Rare Ore, Luck-Preis $5.000 × 3^(n−1), Luck-Stufe n ab Mining Level 5n. Luck bleibt bei Prestige erhalten (Equipment).
**Affected systems:** MiningService, RareDropLogic, BalanceConfig, ShopService, ShopController, MiningController, HudController, SoundController, Data (v11)

## D-046 – Verladeturm nie Engpass, Spätspiel-Preise teurer, keine neuen Fahrzeuge

**Source:** Felix, 2026-10-18 („Fahrzeuge brauchst du nicht erstellen, ich suche später welche raus, die du einfach einfügst; der Verladeturm soll nie ein Engpass sein, mach ihn deutlich schneller; die Preise sollen später sowieso sehr teuer sein“)
**Decision:** Der Verladeturm füllt jedes Fahrzeug in höchstens `Loading.FullLoadSeconds` (4 s; Rate = Kapazität / 4 s, mindestens 100/s aus D-029). Alle Kaufpreise mit Mindest-Level über 40 (Minen, Spitzhacken, Rucksäcke, Drills, Fahrzeuge, Elevator-Stufen) steigen zentral um × 1,15 je Level darüber (`ContentCurve.latePrice`, Level 100 ≈ × 4.400). Weil die Automation mit schnellem Laden deutlich mehr verkauft, wurde die XP-Kurve neu per Simulation eingestellt (Abschnitt bis L50: Exponent 6,9). Neue Fahrzeuge kommen später mit Felix' Modellen. Felix 2026-10-18: L100 (≈ 50 h) ist wichtiger als L50 – die Kurve bleibt so (L50 ≈ 15 h).
**Affected systems:** LoadingService, BalanceConfig (Loading, ContentCurve, Leveling), ContentCurve, Pickaxes, Backpacks, Drills, Vehicles, Upgrades, Mines

## D-047 – Großes Lager hinter der Halle zurückgestellt

**Source:** Felix, 2026-10-18 („großes Lager vergessen wir erst mal, darüber denke ich ganz am Ende noch mal nach“)
**Decision:** Das große Lager hinter der Halle wird vorerst nicht gebaut; Entscheidung ganz am Ende. Als Nächstes liefert Felix Fahrzeugmodelle in der Reihenfolge, wie sie preislich und kapazitätsmäßig aufsteigen sollen.
**Affected systems:** –

## D-048 – Neue Fahrzeugreihe aus Felix' Modellen, Lastzüge mit echten Anhängern

**Source:** Felix, 2026-10-18 (6 Creator-Store-Modelle in Preis-/Größenreihenfolge; „1.a ja dann müssen wir umbauen, plane bitte schon mal“; „die alten Autos komplett entfernen, im Autohaus sollen nur die kleinen Autos ausgestellt werden, später kommen noch mehr dazu, viele davon auch nur Spaß-Autos“)
**Decision:** Karosserien kommen aus `ServerStorage.Vendor.VehicleBodies` (vorbereitet mit `tools/PrepareVehicleBodies.luau`: ohne Skripte, Logos, Nummernschild-Bilder), gefahren wird weiter mit A-Chassis. IDs bleiben: `vehicle_pickup` = Pickup, `vehicle_van` = Cargo Van, `vehicle_boxtruck` = High-Roof Van, `vehicle_truck` = Box Truck, `vehicle_hauler` = Tipper Road Train (FH 540), neu `vehicle_roadtrain` = Grain Road Train (Scania). Die beiden Lastzüge bekommen echte Anhänger (Plan `PLANS/ROAD_TRAINS.md`) und sind bis dahin „Coming soon“. Im Autohaus stehen nur Pickup, Cargo Van und High-Roof Van. Geschlossene Aufbauten werden übers Dach beladen.
**Affected systems:** Vehicles, VehicleModelBuilder, VehicleShopBuilder, ShopService, ShopController, LoadingService, DevService

## D-049 – HallLayout deckungsgleich mit Plot 1, Studio-Inhalte automatisch sichern

**Source:** Felix, 2026-10-19 („die eine Halle ist falsch gedreht“; „sichere danach automatisch alles im repo“)
**Decision:** `Workspace.HallLayout` liegt jetzt genau auf Plot 1 (LayoutOrigin = Plot-1-CFrame), damit Studio-Ansicht, World Preview und Spiel übereinstimmen. Im Spiel ändert sich nichts (Kopie relativ zum LayoutOrigin). Neue Objekte gehören immer in einen Ordner im HallLayout, nie lose in den Workspace. Nach jeder Änderung an Studio-only-Inhalten (HallLayout, A-Chassis, VehicleBodies) werden sie ohne Rückfrage nach `assets/` exportiert, rückgeprüft und gepusht.
**Affected systems:** HallLayout, World Preview, assets/

## D-050 – Lastzüge: Verladespur am grünen Häuschen, ~60 % Tempo

**Source:** Felix, 2026-10-19 („mach die Verladezone dahin, wo die grüne Hütte vor der Tür ist“; 60 % Geschwindigkeit: „ja“)
**Decision:** Die Durchfahr-Verladespur der Lastzüge kommt an die Stelle des grünen Häuschens vor der Halle (genaues Objekt wird bei T3 bestätigt). Lastzüge fahren etwa 60 % so schnell wie die kleinen Fahrzeuge (TODO_BALANCE bei der Feinabstimmung).
**Affected systems:** Vehicles, Verladespur (T3), PLANS/ROAD_TRAINS.md

## D-051 – Keine Hintergrundmusik

**Source:** Felix, 2026-10-19 („entferne bitte die Musik aus dem Spiel“)
**Decision:** Hintergrundmusik aus (`AmbienceConfig.Music.Enabled = false`). Umgebungsgeräusche, Maschinen- und Ereignis-Sounds bleiben. Die Playlist bleibt in der Config, falls Musik später wieder gewünscht ist.
**Affected systems:** SoundController, AmbienceConfig

## D-052 – Durchfahr-Verladestraße mit einem Rüssel

**Source:** Felix, 2026-10-19 (Skizzen; „Verladestraße, durch die man mit den großen LKWs einfach durchfahren kann … den Verladeturm kannst du gerne komplett umbauen, außerdem muss es nur noch einen Verladerüssel geben“; Antworten: Richtung ja, Verkauf in der Stadt, neue Straßenkurve neben dem Grundstück, alter Turm wird aufbewahrt)
**Decision:** Einfahrt über eine neue Straße neben dem Grundstück (Abzweig von der Zufahrt, zwei weite Kurven) durch ein Zauntor und eine Öffnung in der linken Hallenwand, geradeaus unter dem einen Verladerüssel durch, Rechtskurve, Ausfahrt durch das Rolltor, weiter zum Verkauf in der Stadt. Der Turm steht hinter der Spur, ein Portal trägt den Rüssel über die Spur. Die zwei Stellplätze zum Ausparken liegen vor dem Rüssel mit Front in Fahrtrichtung. Ersetzt den Ort aus D-050 (grüne Hütte). Felix' Kopie des alten Turms liegt in `ServerStorage.Archive.OldLoadingTower`.
**Affected systems:** GarageTemplate, LoadingService, HallTemplates, PlotExterior, PlotBuilder, EnvironmentBuilder, LayoutConfig, HallLayout (Place)

## D-053 – Lastzug mit echten Anhängern (Scania)

**Source:** Felix, 2026-10-19 („weiter“ – Freigabe Lastzug-Schritt 1; 60 % Tempo: „ja“)
**Decision:** Der Grain Road Train (`vehicle_roadtrain`) besteht aus der Zugmaschine (A-Chassis) und drei eigenen Physik-Modellen (Auflieger, Dolly, zweiter Auflieger) mit frei drehenden Rädern und Kugelgelenk-Kupplungen (Knicken bis 75°, Kippen bis 12°). Lastzüge stehen nicht in der Halle, sondern auf der Zufahrt neben dem Grundstück (eigener Platz, höchstens einer). Beladen Anhänger für Anhänger: Jeder Auflieger trägt die Hälfte, der vordere wird zuerst voll. Tempo per A-Chassis-Limiter 60 km/h (TODO_BALANCE). Im Autohaus bleibt er „Coming soon“, bis Felix ihn gefahren hat.
**Affected systems:** TrailerBuilder, VehicleService, LoadingService, DevService, Vehicles, Place (VehicleBodies, AChassis.Tunes)

## D-054 – Rostiger Pickup als Startauto (500 $), verdunkelte Scheiben bei allen Fahrzeugen

**Source:** Felix, 2026-10-21 („das Auto … umbauen, es muss mehr ranzig und verrostet aussehen, es soll das Starterauto werden, das man für 500 $ im Shop bekommt, der Lack soll an manchen Stellen schon abplatzen; außerdem merk dir: alle Fahrzeuge sollen verdunkelte Scheiben haben“)
**Decision:** `vehicle_pickup` bleibt das erste Fahrzeug (Level 7 wie die Garage), kostet 500 $. Optik: verblasster cremeweißer Lack mit abgeplatzten Stellen (eigene kachelbare Textur `assets/textures/rusty_pickup_paint.png`, erzeugt mit `tools/gen_rusty_paint.py`, hochgeladen als `rbxassetid://81833308405600`, MaterialVariant `RustyPickupPaint` über Rojo in `MaterialService`); Stoßstangen, Felgen, Spiegel, Kühlergrill rostbraun. Alle Fahrzeugscheiben sind undurchsichtig dunkel (Attribut `Window = true` an den Scheibenteilen); der Scania bekam eine fehlende Frontscheibe. Gilt auch für alle künftigen Fahrzeuge.
**Affected systems:** Vehicles, Place (VehicleBodies), MaterialService, default.project.json

## D-055 – Jedes Fahrzeug nur einmal

**Source:** Felix, 2026-10-21 („man soll ein Auto nur einmal besitzen können“)
**Decision:** Jeder Fahrzeugtyp kann nur einmal besessen werden. Das Autohaus prüft das bereits serverseitig (`ShopService.buyVehicle`, Fehler ALREADY_DONE) und zeigt „Owned“; jetzt verweigern auch die Dev-Kommandos `GiveVehicle`/`GiveAllVehicles` doppelte Typen.
**Affected systems:** ShopService, DevService

## D-056 – Grüner Verkaufskreis statt Verkaufsgebäude

**Source:** Felix, 2026-10-21 („mach den Sell-Shop weg und mach einfach in der Mitte den Brunnen und die Bäume weg und einen großen grünen Kreis; wenn man da durchfährt, verkauft man automatisch, ohne dass ein Fenster aufgeht“)
**Decision:** Verkaufsgebäude, Tresen und Verkaufsfenster entfallen. In der Insel des Kreisverkehrs (Brunnen, Beete mit Bäumen, Bänke und Laternen entfernt, Insel flach und befahrbar) liegt ein grüner Kreis (Radius 36, `LayoutConfig.SellCircle`). Fährt man mit Ladung hindurch, wird die ganze Fahrzeugladung sofort verkauft; zu Fuß wird der Rucksack verkauft (damit Rucksack-Verkauf weiter möglich ist – Annahme, von Felix zu bestätigen). Rückmeldung nur als kurze Einblendung „SOLD +$… +… Mining XP“. Ersetzt den Fahrzeug-Verkauf mit Bestätigung (docs/07 §25/§31).
**Affected systems:** SellingService, SellingBuilder, SellController, EnvironmentBuilder, LayoutConfig, Remotes

## D-057 – Neue Gestaltung der Map-Mitte

**Source:** Felix, 2026-10-22 („überarbeite bitte die gesamte Mitte, sie muss viel schöner und einladender aussehen, außerdem ist nicht ein großer Parkplatz da; so ähnlich wie im Bild im Plan; die echte Mitte der Map soll immer noch der Sell-Button sein“)
**Decision:** Neuer Baustein `World/CenterBuilder.luau` nach CENTRAL_AREA_REFERENCE.png: Wiese statt grauer Pflasterfläche, Holzzaun am Platzrand, Pflaster-Promenade um den Kreisverkehr mit Blumenbeeten, Bänken und Laternen, Gehwege mit Laternen und Baumalleen entlang der Straßen, ein großer Parkplatz (3 gestaffelte Doppelreihen mit Baum-Inseln und Laternen, „P“-Schild) im freien Sektor zwischen den Straßen zu Plot 4 und 5, Parkplätze vor allen drei Shops, Park mit Teich (Sandufer, Steine, Schilf, Bänke), Garten mit Glas-Pavillon, Picknicktischen und Blumenbeeten, viele Bäume, Büsche, Blumen und Felsen. Die drei Shops stehen jetzt mittig zwischen den Straßen, parallel zu ihrem Sektor, mit Vorplatz und Parkplatz davor (`SectorAngle`, neue Offsets). Der grüne Verkaufskreis bleibt genau in der Map-Mitte. Alle Werte in `LayoutConfig.Center` (TODO_LAYOUT).
**Affected systems:** CenterBuilder, EnvironmentBuilder (alte Platzdeko entfernt), PlotService, LayoutConfig, Equipment-/Machine-/VehicleShopBuilder

## D-058 – LKW-Laden außerhalb der Mitte

**Source:** Felix, 2026-10-22 („wir brauchen einen LKW-Laden, der etwas außerhalb der Mitte ist; er soll genug Platz haben, um alle LKWs auszustellen, und noch 2 extra Plätze vielleicht“)
**Decision:** Neuer Shop „TRUCKS“ (`World/TruckShopBuilder.luau`, ShopId `truck`) hinter dem großen Parkplatz, außerhalb des Platzzauns (Sektor zwischen den Straßen zu Plot 4 und 5), Eingang zur Mitte, Zufahrt zum großen Parkplatz durch eine Lücke im Zaun. Halle 112 × 132 mit Glasfront, zwei offenen Toren, fünf Stellplätzen: Box Truck, Tipper Road Train und Grain Road Train mit allen Anhängern ausgestellt, zwei Plätze „Coming soon“. LKW (Definition `Dealer = "truck"`) werden nur noch dort verkauft; das Autohaus zeigt nur Pickup, Cargo Van und High-Roof Van.
**Affected systems:** TruckShopBuilder, ShopService, ShopController, Strings, Vehicles, LayoutConfig, EnvironmentBuilder, CenterBuilder

## D-059 – Größerer Kreisel, LKW-Laden näher an der Mitte

**Source:** Felix, 2026-10-25 („die Mitte sieht schon sehr gut aus; der LKW-Shop soll doch näher an der Mitte sein, so nah es geht ohne Kollision mit den Straßen; der Kreisel muss größer werden … auf die Breite des aktuellen Bürgersteiges, vielleicht sogar etwas mehr, damit man mit den großen LKWs den Kreisel fahren kann“)
**Decision:** Kreisel-Fahrbahn 40–86 statt 40–64 (46 statt 24 breit = alte Fahrbahn + Promenade + 4). Promenade 86–104, alles andere rückt mit nach außen (Shops +22 Studs). LKW-Laden steht jetzt im Sektor zwischen den Straßen zu Plot 4 und 5 so weit innen, wie die Halle zwischen die Straßen passt (Front bei r ≈ 151, ≈ 8 Studs Abstand zum Gehweg), mit kurzer Zufahrt direkt zur Promenade; die Halle ragt hinten über den Zaun. Dafür zog der große Parkplatz in den Sektor zwischen Plot 5 und 6 (die Hütte dort weiter nach außen), der Garten mit Pavillon liegt jetzt hinter dem Teich.
**Affected systems:** LayoutConfig (RoundaboutOuter, Center, TruckShop, Shop-Offsets, Cabins), CenterBuilder, TruckShopBuilder, EnvironmentBuilder

## D-060 – Pickaxe- und Drill-Shop größer und einladender

**Source:** Felix, 2026-10-22/25 („der Pickaxe- und Drill-Shop muss auch größer und einladender wirken … fang erst mal an, verbessern können wir immer noch“; „mach weiter“)
**Decision:** Equipment-Shop 64 × 22 × 44 (vorher 40 × 16 × 30), Machine-Shop 72 × 24 × 54 (vorher 52 × 18 × 40), beide etwas weiter außen, damit die Parkplätze davor Platz haben. Neuer Baustein `World/ShopDecor.luau` (gestreifte Markisen, beleuchtete Dachschilder in runder Schrift, Fahnen, Pflanzkübel, Podeste mit Spot). Equipment: große Schaufenster mit blau-weißen Markisen, Dachschild „PICKAXES“, Riesen-Spitzhacke auf dem Dach, Teppich und drei Podeste mit den besten Spitzhacken, Bank und Pflanzen vor der Tür, mehr Licht. Machine: breiteres Tor (28 × 16), Dachschild „DRILLS & MACHINES“, orange-schwarzes Vordach, Fassadenstrahler, Fahnen, Pflanzen und ein Drill auf beleuchtetem Podest vor dem Shop.
**Affected systems:** EquipmentShopBuilder, MachineShopBuilder, ShopDecor, LayoutConfig

## D-061 – Lastzüge fahren frei durch den Kreisel

**Source:** Felix, 2026-10-25 („… damit man mit den großen LKWs den Kreisel fahren kann“), Prüfung durch Claude nach D-059/D-060
**Decision:** Schleppkurven-Simulation (`tools/roundabout_sweep.py`, echte Achs- und Kupplungsmaße aus `assets/VehicleBodies.rbxm`, alle 6 Einfahrten, rechts/geradeaus/links, Fahrlinien r = 64/72/80) zeigte: Die Fahrbahn 40–86 reicht (innerste Anhängerkante r ≈ 45), aber beim Ein- und Ausfahren ziehen die Anhänger über Promenade und Gehweg und trafen Bänke, Blumenkästen und Laternen an jeder Einmündung. Deshalb:
- Promenade: statt Deko rundum je Sektor eine Sitzecke in der Sektormitte am äußeren Rand (2 Bänke mit Durchgang in der Mitte, 2 Laternen, 2 Blumenbeete auf der Wiese dahinter); im Sektor des LKW-Ladens keine, dort liegt die Zufahrt.
- Gehweg-Laternen erst ab r = 149 (Promenade + 45), Alleebäume ab r = 124 (Promenade + 20).
- Zufahrt zum LKW-Laden reicht jetzt bis an den Kreisverkehr (vorher endete sie 8 Studs vor der Promenade, eine Bank stand mitten in der Einfahrt); Deko bleibt aus dem Korridor.
- Dritte Holzhütte stand mit der Veranda 5 Studs auf der Straße zu Plot 2 → nach (-80, -178) verschoben.
Ergebnis mit den echten Teilen (`tools/topdown`): keine Berührung, knappster Abstand 1,5 Studs.
**Affected systems:** LayoutConfig (Center.RestSpot*, SidewalkLampStart, AlleyStart, Cabins), CenterBuilder, TruckShopBuilder, tools/roundabout_sweep.py, tools/topdown

## D-062 – Pickaxe-, Drill-Shop und Autohaus nochmals größer

**Source:** Felix, 2026-10-26 („mach den Pickaxe- und Drill-Shop und auch den normalen Autoladen etwas größer“)
**Decision:** Alle drei rund 25 % größer, Front bleibt an derselben Stelle (Parkplätze und Promenade unverändert), die Hallen wachsen nach hinten: Equipment-Shop 80 × 24 × 55 (vorher 64 × 22 × 44), Machine-Shop 90 × 26 × 68 (vorher 72 × 24 × 54), Autohaus 112 × 24 × 85 (vorher 90 × 22 × 68). Drehteller im Autohaus wachsen mit der Halle mit. Abstand zu den Straßen bleibt ≥ 22 Studs von der Straßenmitte, nichts überschneidet sich (Draufsicht-Prüfung).
**Affected systems:** LayoutConfig (EquipmentShop, MachineShop, VehicleShop), VehicleShopBuilder

## D-063 – Läden innen wie echte Geschäfte

**Source:** Felix, 2026-10-26 („versuch jetzt noch mal alle Läden von innen zu überarbeiten, orientier dich an echten Läden vom Innenaufbau und allem, und überarbeite die kleinen Details“)
**Decision:** Neuer Baukasten `World/ShopInterior.luau` (Gondelregale, Wandregale, Kassen mit Laufband, Schreibtische, Bürostühle, Sessel, Sofa, Kaffee-Ecke, Prospektständer, Hängeschilder, Poster, Uhr, Notausgang-Schild, Diebstahlsicherung, Körbe, Puppen, Helme, Schlüsselkasten, Fernseher, Lichtraster, Reifenstapel, Türen).
- **Pickaxe-Shop:** Eingang mit Diebstahlsicherung und Körben, zwei Kassen mit Warteschlange (Shop-Prompt an Kasse 1), Neuheiten-Podeste, drei Gangregale (Tools/Safety/Lights) mit Helmen, Rucksack-Abteilung mit Puppen und Tisch, große Spitzhacken-Wand mit Namensschildern und Spots, Probier-Fels, Personaltür, Poster, Uhr, Rasterdecke.
- **Drill-Shop:** Stufen 4–6 auf Podesten im Showroom, zwei Verkaufsplätze, Wartebereich mit Sesseln, Kaffee und TV, Ersatzteiltheke mit Regal, Servicebereich mit Hebebühne, Hallenstrahler-Raster.
- **Autohaus:** Empfang am Eingang, vier Verkaufsplätze (Sales/Financing), Übergabezone, Lounge mit Kaffee, TV, Sesseln und Kinderecke, Schlüsselkasten, Prospekte, Deckenlichter.
- **LKW-Laden:** Kundenzone hinten mit drei Verkaufsplätzen, Lounge, Ersatzteiltheke mit Regal, Reifenstapel und Poster an den Seiten. Die fünf Stellplätze, auch die zwei freien, bleiben frei.
- **Kleine Korrekturen:** Gangmarkierungen und freie Stellflächen im LKW-Laden enden vor der Kundenzone, Ausstellungs-Spitzhacken größer.
**Affected systems:** ShopInterior, EquipmentShopBuilder, MachineShopBuilder, VehicleShopBuilder, TruckShopBuilder

## D-064 – Shop-Parkplätze an die Straßen angebunden, große Lücken

**Source:** Felix, 2026-10-27 („die kleinen Parkplätze vor den Läden sind nicht an die Straße angebunden, die Deko davor muss weg und die Parkplätze minimal größer, sodass nach dem Bürgersteig direkt der Parkplatz anfängt; außerdem sind die Parklücken viel zu klein … angemessene Größe für die im Spiel fahrbaren Autos“)
**Decision:** Die Parkplätze vor den drei Shops reichen jetzt von Gehweg zu Gehweg (an beide Straßen angebunden) und von der Promenade bis zum Vorplatz des Shops. Bäume, Laternen-Inseln, Bänke und Beete auf und vor der Fläche sind entfernt. Pro Shop eine Reihe mit 6 Lücken à 12 × 24 Studs vor dem Shop, davor eine breite Fahrgasse quer zwischen den Straßen. Der große Parkplatz nutzt dieselbe Lückengröße (2 Doppelreihen). Maße in `LayoutConfig.Center` (StallWidth, StallDepth, LotAisle).
**Affected systems:** CenterBuilder, LayoutConfig

## D-065 – Parkplätze: Lücken 13 × 29, exakte Ränder, Einfahrten

**Source:** Nachprüfung von D-064 gegen Felix' Wunsch vom 2026-10-27 („angemessene Größe für die im Spiel fahrbaren Autos“, „nach dem Bürgersteig direkt der Parkplatz“, „an die Straße angebunden“)
**Decision:** Lücken 13 × 29 Studs statt 12 × 24, weil High-Roof Van (9,7 × 26,4) und Cargo Van (9,8 × 25,3) nicht in 24 Studs passten. Die Parkplatzränder liegen exakt an der Gehweg-Innenkante (rechtwinklige Dreiecke statt schräger Streifen, die unter Shop-Fronten, Fahnen und eine Laterne ragten); je Seite eine Einfahrt über den Gehweg auf Höhe der Fahrgasse. Großer Parkplatz neu als zwei Module (Fahrgasse mit Lücken beidseitig), damit er mit den tieferen Lücken in den Zaun passt; Hütten bleiben frei. Pylon des Autohauses und Schau-Drill des Drill-Shops stehen jetzt auf dem Vorplatz statt auf dem Parkplatz.
**Affected systems:** CenterBuilder, LayoutConfig, VehicleShopBuilder, MachineShopBuilder, tools/topdown (WedgePart in Draufsicht)

## D-066 – Map bleibt im Code, Vorschau automatisch

**Source:** Felix, 2026-10-27 („ist es dumm, die Map wirklich direkt in der Entwicklerumgebung zu bauen … ich finde es etwas nervig“; Vorschlag automatische Vorschau: „ja kannst du machen“)
**Decision:** Die Welt wird weiter per Code gebaut (6 gleiche Plots, schnelle Umbauten, Versionskontrolle); Hand-Deko geht über Layouts wie das HallLayout. Das Plugin „Idle Miner Preview“ baut die Vorschau jetzt automatisch: beim Öffnen von Studio und neu, sobald neuer Code in `ServerScriptService.World` oder `ReplicatedStorage.Shared` ankommt (1,5 s Ruhe abgewartet). Der Knopf „World Preview“ schaltet die automatische Vorschau an/aus; die Einstellung bleibt über Neustarts erhalten.
**Affected systems:** plugin/EditPreview.server.luau, README

## D-067 – Großer Parkplatz an die Straßen angebunden

**Source:** Felix, 2026-10-27 („ja überarbeite ihn auch“, auf die Frage, ob der große Parkplatz wie die Shop-Parkplätze an die Straße angebunden werden soll)
**Decision:** Jede Fahrgasse der beiden Module läuft als Zufahrt (12 Studs breit, gestrichelte Mittellinie) seitlich bis an die Gehwegkante beider Nachbarstraßen, mit Einfahrt über den Gehweg. Eine Seite entfällt nur, wenn eine Hütte im Weg stünde (derzeit keine). Parkplatz, Zufahrten und Einfahrten werden vor Promenade, Laternen, Zaun und Bäumen belegt; Gehweg-Laternen stehen nicht mehr auf Einfahrten.
**Affected systems:** CenterBuilder (`bigLotLayout`, `drivewaysAt`, `sidewalks`)

## D-068 – LKW-Laden: Tresen vorne, Spawn auf der Zufahrt, Zufahrt wie eine Straße

**Source:** Felix, 2026-10-27 („im Truck-Shop muss der Verkaufstresen und der Rest vor den LKWs stehen … nur einen Verkaufstresen; nach dem Kauf sollen die LKWs auf dem kleinen Weg vor dem Laden spawnen, dafür muss der Weg etwas länger werden; der Weg ist komisch an den Kreisel angebunden, mach es wie die anderen Straßen und rechts und links eine kleine Ausschwenkkurve an die Ausfahrt“)
**Decision:** Halle 22 Studs tiefer (154) mit Kundenzone vorne: ein Verkaufstresen mittig vor den Stellplätzen (Shop-Prompt), Lounge und Kaffee vorne; die hintere Kundenzone (3 Schreibtische, Ersatzteiltheke) entfällt. Laden weiter außen (Offset 175,3/211,7), Zufahrt dadurch ~118 Studs lang und 28 breit wie die anderen Straßen, gleiche Höhe und Markierungen, runde Ausrundungen (Radius 14) in den Kreisel, Ausschwenkkurven (Radius 8) am Vorplatz (neuer Baustein `World/RoadFillet.luau`). Ein gekaufter LKW bekommt sofort seinen Stellplatz und steht auf der Zufahrt, Front 4 Studs vor dem Kreisel (`VehicleService.SpawnPurchased`, `TruckShopBuilder.spawnCFrame`). Dev-Kommando `SpawnAtTruckShop`.
**Affected systems:** TruckShopBuilder, RoadFillet, VehicleService, ShopService, DevService, LayoutConfig, CenterBuilder
**Nachtrag 0.52.1 (Prüfung):** Vor dem Spawn wird geprüft, ob auf der Zufahrt schon ein Fahrzeug steht (`VehicleService.IsAreaFree`, `TruckShopBuilder.spawnArea`); dann bleibt der LKW in der Garage statt ineinander zu spawnen. Meldung nach dem Kauf passt jetzt (`TRUCK_PURCHASED`: steht vor dem LKW-Laden; sonst wie bisher Garage). Halle hält 8 Studs Abstand zu Bäumen (eine Kiefernkrone ragte 0,6 Studs durch die Seitenwand).
