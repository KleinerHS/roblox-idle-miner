# Implementation Status

Statuswerte: `IMPLEMENTED` · `TESTING_REQUIRED` · `USER_APPROVED` · `BUGGED` · `BLOCKED` · `NOT_STARTED`

## Phasen

| Phase | Inhalt | Status |
|---|---|---|
| Setup | GitHub-Repo, Rojo-Projekt, Doku-Ordner | USER_APPROVED |
| 0 | Dokumentations-Audit | USER_APPROVED (Freigabe „weiter“, 2026-10-04) |
| 1 | Project Skeleton | USER_APPROVED (Felix „passt“, 2026-10-04; Zwei-Spieler-Test wird in Phase 2 nachgeholt) |
| 2 | Vertical Slice A | TESTING_REQUIRED (2a USER_APPROVED, 2b USER_APPROVED, 2c USER_APPROVED, 2d TESTING_REQUIRED) |
| 3 | Vertical Slice B (Equipment, Mine 02) | NOT_STARTED |
| 4 | Storage + Worker (Worker erst nach Lager, D-004) | NOT_STARTED |
| 5 | Drill | NOT_STARTED |
| 6 | Garage & Vehicles | NOT_STARTED |
| 7 | Conveyors | NOT_STARTED |
| 8 | Smelter | NOT_STARTED |
| 9 | Multiplayer Hardening / Trading | NOT_STARTED |
| 10 | Offline Production | NOT_STARTED |
| 11 | Prestige | NOT_STARTED |
| 12 | Content Expansion | NOT_STARTED |
| 13 | Visual Polish | NOT_STARTED |
| 14 | Balance | NOT_STARTED |

## Setup – Details

- Rojo-Projekt `default.project.json` mit `src/shared`, `src/server`, `src/client`
- Sync-Check: `Bootstrap.server.luau` und `Bootstrap.client.luau` geben Version aus `Shared/Version` aus
- Spezifikation 00–20 und Visual References in `docs/`
- `QUESTIONS/` und `TESTING/` angelegt
- Test 2026-10-04 durch Felix in Studio (lokaler Place, Rokit 1.2.0, Rojo 7.4.4): Sync ok, Play-Output `[Server] … gestartet` und `[Client] … gestartet`, keine Fehler → USER_APPROVED

## Phase 1 – Project Skeleton – Details

Stand: 2026-10-04 · Version 0.1.0

| System | Dateien | Status |
|---|---|---|
| Zentrale Configs | `src/shared/Config/` GameConfig, BalanceConfig (TODO_BALANCE), LayoutConfig (TODO_LAYOUT), UITheme | TESTING_REQUIRED |
| Definitionen | `src/shared/Definitions/` Ores (50), Mines (100), Pickaxes, Backpacks, BuildSteps, CompanyIdentity | TESTING_REQUIRED |
| Shared Utils | `src/shared/Util/` Result, Signal, NumberFormat, Log, Leveling · `src/shared/Types.luau` | TESTING_REQUIRED |
| Remote Registry | `src/shared/Remotes.luau`, `src/server/Services/RemoteService.luau`, `src/server/Util/` RateLimiter, Validate | TESTING_REQUIRED |
| Service Bootstrap | `src/server/Bootstrap.server.luau` (Init → Start, feste Reihenfolge) | TESTING_REQUIRED |
| Controller Bootstrap | `src/client/Bootstrap.client.luau`, `src/client/Net.luau`, Controllers State/Plot | TESTING_REQUIRED |
| Data Schema v1 + DataService | `src/server/Data/DataSchema.luau`, `src/server/Services/DataService.luau`, ProfileStore (`src/server/Packages`) | TESTING_REQUIRED (Speichern erst nach Veröffentlichung testbar) |
| Plot Ownership | `src/server/Services/PlotService.luau`, `src/server/World/PlotBuilder.luau` (Platzhalter-Geometrie) | TESTING_REQUIRED |
| StreamingEnabled | `default.project.json` (Workspace) | TESTING_REQUIRED |

Selbsttest per Studio-MCP (2026-10-04, unveröffentlichter Place, DataStore im Testmodus):
- Server startet 3 Services ohne Fehler, Client 2 Controller.
- Join → Plot 1, Schild „Plot 1 / Name“, Spawn am Plot-Spawnpunkt, Plots 2–6 „Frei“.
- Profil v1 geladen: Cash 800, Level 1, XP 0/100, Starter-Rucksack 100.
- 50 Erze, 100 Minen (mine_045 = Ruby, mine_100 = Diamond), Leveling und Zahlenformat korrekt.
- Exploit-Test: GetState mit Müll-Argumenten → keine Wirkung; 7× in Folge → ab dem 6. `RATE_LIMITED`; Client-Aufrufe auf ServerToClient-Remotes werden ignoriert.
- Speichertest 2026-10-04 im veröffentlichten Place „10042026_2“ (placeId 74322463877243, API-Zugriff an): `DataStore verbunden`, 1. Play `Joins 1`, 2. Play `Joins 2` → Speichern und Laden funktionieren.
- Noch nicht getestet: zwei Spieler (Test 1.6, 1.7) → wird in Schritt 2d nachgeholt.

## Phase 2 – Vertical Slice A – Details

Phase 2 ist in Hauptschritte geteilt, nach jedem wird gestoppt: 2a Tycoon & Firma · 2b Elevator & Mine 01 · 2c Mining & Rucksack · 2d Verkauf, Cash/XP, Level-HUD, Save/Rejoin, Zwei-Spieler-Test.

### 2a – Tycoon & Firmeneinrichtung (Version 0.2.0) – USER_APPROVED

| System | Dateien | Status |
|---|---|---|
| Tycoon-Baukette (nur nächster Button, Kauf per Betreten, serverseitige Prüfung) | `src/server/Services/BuildingService.luau`, `src/shared/Definitions/BuildSteps.luau` | TESTING_REQUIRED |
| Blechhütte (Schreibtisch, Laptop, Stuhl, Bett = Spawn, Regal, Lampe) – Platzhalter | `src/server/World/BuildTemplates.luau` | TESTING_REQUIRED |
| Elevator-Käfig – nur Modell, Funktion folgt in 2b | `src/server/World/BuildTemplates.luau` | TESTING_REQUIRED |
| Firmeneinrichtung (Name mit Textfilter, Logo, Farbe) | `src/server/Services/CompanyService.luau`, `src/client/Controllers/CompanySetupController.luau` | TESTING_REQUIRED |
| Firmenschild mit Logo, Name, Akzentfarbe | `src/server/World/PlotBuilder.luau` | TESTING_REQUIRED |
| Bodenmarkierungen der Endhalle (D-002) | `src/server/World/PlotBuilder.luau`, `LayoutConfig.HallZones` | TESTING_REQUIRED |
| Meldungen (Toasts, ohne Popup-Flut) | `src/client/Controllers/NotificationController.luau`, `src/client/UI/Strings.luau` | TESTING_REQUIRED |
| UI-Grundbausteine | `src/client/UI/Create.luau`, `src/client/UI/Components/Button.luau` | TESTING_REQUIRED |
| Studio-Reset des Testspielstands | `src/server/Services/DevService.luau` (nur in Studio aktiv) | TESTING_REQUIRED |

Selbsttest per Studio-MCP (2026-10-04, Place „10042026_2“, DataStore aktiv):
- Button „BUILD OFFICE / FREE“ → Betreten → Hütte erscheint, Button weg, Firmendialog öffnet sich.
- Ungültige Eingaben abgelehnt: Name zu kurz und Steuerzeichen (`NAME_INVALID`), falsche Logo-ID oder Zahl statt Text (`INVALID_ARGUMENT`), Spam (`RATE_LIMITED`).
- Gültiger Name „  Deep   Rock Mining “ → gespeichert als „Deep Rock Mining“, Schild zeigt ⛏ + Name + Akzentfarbe, Dialog schließt.
- Danach Button „BUILD ELEVATOR / $200“ → Kauf → Cash 800 → 600, Elevator-Käfig erscheint, kein weiterer Button.
- Rejoin: Büro, Elevator, Schild, Cash 600 wiederhergestellt, Spawn auf dem Bett.
- Reset per `ServerStorage.DevTools.ResetProgress` → Ausgangszustand (Cash 800, nur Büro-Button).
- Test durch Felix 2026-10-04: Büro → Firma „Fullucks“ → Elevator ($800 → $600) → Rejoin, alles da, Spawn im Bett → USER_APPROVED.

### 2b – Elevator & Mine Shaft 01 (Version 0.3.0) – USER_APPROVED

| System | Dateien | Status |
|---|---|---|
| Elevator-Navigation (Prompt am Käfig, Besitz-, Nähe- und Level-Prüfung, Teleport) | `src/server/Services/ElevatorService.luau` | TESTING_REQUIRED |
| Minenauswahl (Liste aller 100 Minen, GO / LOCKED, Oberfläche) | `src/client/Controllers/ElevatorController.luau` | TESTING_REQUIRED |
| Übergang (Abblenden mit Shaft-Titel, leichtes Kamera-Ruckeln) | `src/client/Controllers/ElevatorController.luau` | TESTING_REQUIRED |
| Shaft-Anzeige oben mittig in der Mine | `src/client/Controllers/ElevatorController.luau` | TESTING_REQUIRED |
| Mine-Shaft-Raum je Plot (Podest mit Treppe, Käfig, 2 Erzadern mit Holzstützen, Lampen, Kisten, Fässer) – Platzhalter | `src/server/World/MineShaftBuilder.luau`, `LayoutConfig.MineShaft` | TESTING_REQUIRED |
| Umkonfiguration je Mine (Erzfarbe, Felsfarbe ab Mine 30 dunkler, Schild) | `MineShaftBuilder.configure`, `Ores.Color`, `Mines.RockColor` | TESTING_REQUIRED |
| Mine-Atmosphäre (lokal kein Oberflächen-Dunst) | `src/client/Controllers/ElevatorController.luau` | TESTING_REQUIRED |

Selbsttest per Studio-MCP (2026-10-04):
- Prompt „Use Elevator“ am eigenen Käfig öffnet „SELECT MINE“: Mine 01 GO, Mine 02–100 „LOCKED · Coming soon“ (Level-Anforderungen sind TODO_BALANCE).
- Fahrt in Mine 01: Abblenden, Ankunft im Käfig, Anzeige „MINE SHAFT 01 · COAL“.
- Abgelehnt: gesperrte Mine (`NOT_AVAILABLE`), unbekannte ID oder Zahl (`INVALID_ARGUMENT`), Ziel = aktueller Ort (`ALREADY_DONE`), Fahrtwunsch weit weg vom Käfig (`NOT_AVAILABLE`).
- Rückfahrt zur Oberfläche: Anzeige verschwindet, Dunst wieder normal.
- Tod in der Mine → Respawn im Bett, Ort = Oberfläche.

Rückmeldung Felix (2026-10-04) und Überarbeitung:
- Abbauplätze nicht wie im Referenzbild angeordnet → jetzt Platz 1 hinten links, Platz 2 rechts an der Wand, jeweils großer Erzhaufen vor einer offenen Erzwand; Korb mittig hinten (`LayoutConfig.MineShaft`).
- BUG-001: Käfig in der Mine nicht verlassbar → behoben (siehe `TESTING/BUGS.md`).
- Elevator zu billig → neuer gemeinsamer Förderkorb für Oberfläche und Mine: I-Träger-Rahmen, Gitterstäbe, Schiebegitter-Tor, Förderturm mit Seilrad und Kreuzverband, Bedienpult mit Leuchttastern, Warnleuchte (leuchtet während der Fahrt), Innenlampe (`src/server/World/ElevatorCageBuilder.luau`). Oben auf Schachtrahmen mit Rampe, unten auf Podest mit Treppe und Geländer.
- Holzbalken ohne Sinn → Türstockausbau an Rück- und Seitenwänden (Stempel, Kappe, Kopfbänder, Bretterverschalung, Laternen), an den Abbauplätzen schwerer Stützrahmen über der offenen Erzwand; dunkles, unterschiedlich getöntes Grubenholz. Fels dunkler.
- Zweite Rückmeldung Felix (2026-10-04): „Die zwei Haufen vor den Abbauplätzen müssen weg, damit Platz ist für die Miner, sonst alles gut.“ → Erzhaufen und Kiste/Spitzhacke davor entfernt, Fläche vor der Erzwand ist frei; Abbauzone liegt jetzt direkt vor der Erzwand (16 × 12).
- Status 2b: USER_APPROVED (Freigabe „sonst alles gut“, Haufen-Änderung von mir per Studio-Test geprüft).

### 2c – Mining & Rucksack (Version 0.4.0) – USER_APPROVED

| System | Dateien | Status |
|---|---|---|
| Starter-Spitzhacke als Tool (Platzhalter aus Parts, keine Scripts im Tool) | `src/server/World/ToolBuilder.luau`, Vergabe in `MiningService` | TESTING_REQUIRED |
| Servervalidiertes Mining: Ort = Mine, Spitzhacke in der Hand, eigener Slot, Abstand ≤ 7, Cooldown nach Mining Speed, Rucksackkapazität; Menge = Mining Power; Erz = Erz der Mine | `src/server/Services/MiningService.luau`, `GameConfig.Mining` | TESTING_REQUIRED |
| Rare-Drop-Einhängepunkt (`rollRareDrop`, liefert noch nichts, D-006) | `MiningService` | TESTING_REQUIRED |
| Client: Klick → zur Erzwand drehen → Schlag-Animation → Hit-Anfrage → bei Bestätigung Brocken-Effekt, „+1 Coal“, leichtes Kamera-Ruckeln | `src/client/Controllers/MiningController.luau` | TESTING_REQUIRED |
| Rucksackanzeige unten rechts (in der Mine oder mit Inhalt), „BACKPACK FULL“ rot | `src/client/Controllers/BackpackHudController.luau` | TESTING_REQUIRED |
| Studio-Testwerkzeug Rucksack füllen | `DevService` → `ServerStorage.DevTools.FillBackpack` | TESTING_REQUIRED |

Selbsttest per Studio-MCP (2026-10-04):
- Spitzhacke liegt nach Join im Inventar (Hotbar 1).
- An der Oberfläche: `NOT_IN_MINE`; ohne Spitzhacke in der Hand: `NO_PICKAXE`.
- In Mine 01 vor der Erzwand: +1 Coal pro Hit, Rucksack zählt hoch (Anzeige z. B. „12 / 100“).
- Zweiter Hit sofort danach: `COOLDOWN`; anderer Slot zu weit weg: `TOO_FAR`; Slot 7, Text, 1.5: `INVALID_ARGUMENT`.
- Rucksack auf 99 gefüllt → ein Hit → 100/100 → nächster Hit `BACKPACK_FULL`, Anzeige „BACKPACK FULL“ rot.
- Rucksack danach wieder auf 0 gesetzt.
- Test durch Felix 2026-10-04: alles getestet, funktioniert → USER_APPROVED.

### 2d – Verkauf, Cash & Mining Level (Version 0.5.0)

| System | Dateien | Status |
|---|---|---|
| Verkaufsgebäude in der Mitte (Holz/Glas, grünes „$ SELL“-Schild, Vordach, Tresen, „ORE BUYER“-Tafel, markierte Fahrzeug-Verkaufszone ohne Funktion) – Platzhalter | `src/server/World/SellingBuilder.luau`, `LayoutConfig.SellingBuilding` | TESTING_REQUIRED |
| Verkauf am Tresen: Prompt „Sell Ore“ → Fenster mit Rucksackinhalt, Schätzwert und XP → SELL ALL; Server prüft Nähe, rechnet Geld (Menge × SellValue) und XP (Menge × XPValue) getrennt, atomar, Erze ohne Balancewert bleiben | `src/server/Services/SellingService.luau`, `src/client/Controllers/SellController.luau` | TESTING_REQUIRED |
| Mining XP nur beim Verkauf, Level-Ups über `Leveling.addXP` (kein Maximallevel) | `SellingService`, `src/shared/Util/Leveling.luau` | TESTING_REQUIRED |
| HUD: Geld oben rechts (zählt flüssig hoch), Mining Level + XP-Balken unten mittig über der Hotbar (Firmenfarbe als Akzent), „SOLD“- und „LEVEL UP!“-Meldung | `src/client/Controllers/HudController.luau` | TESTING_REQUIRED |
| Speichern nach Verkauf (RequestSave) | `SellingService` | TESTING_REQUIRED |

Selbsttest per Studio-MCP (2026-10-04):
- Verkaufsgebäude steht vorne in der Mitte an der Straße Richtung Plot 5, Eingang zur Straße.
- Leerer Rucksack: `NOTHING_TO_SELL`; zu weit vom Tresen: `TOO_FAR`.
- 99 Coal verkauft → +$99, +99 XP, HUD $600 → $699, „99 / 100 XP“; zweiter Verkauf `NOTHING_TO_SELL`.
- 5 Coal verkauft → Level 2, 4 / 282 XP, „LEVEL UP!“-Meldung, XP-Balken in Firmenfarbe.
- Noch offen: Zwei-Spieler-Test (1.6, 1.7, 2a.9, 2b.7) – kann nur Felix starten.

---

# Documentation Audit

Stand: 2026-10-04

## Documents Read

Alle 21 Dateien vollständig gelesen: `docs/00_READ_ME_FIRST.md` bis `docs/20_MASTER_INSTRUCTIONS_FOR_CLAUDE.md`.

Hinweis: Mehrere Dokumente verweisen auf Dateinamen, die es nicht gibt (z. B. `08_PLAYER_EQUIPMENT.md`, `16_TECHNICAL_ARCHITECTURE.md`, `17_SECURITY_AND_ANTI_EXPLOIT.md`, `18_PERFORMANCE.md`, `VISUAL_REFERENCES/01_MAP_TOPDOWN.png`). Das sind Überbleibsel einer älteren Gliederung. Inhaltlich entsprechen sie `10`, `15`, `15`/`18`, `15`/`18` und den PNGs in `docs/references/`.

## Visual References Inspected

| Datei | Inhalt | Wichtigste Erkenntnisse |
|---|---|---|
| `MAP_MASTERPLAN_TOPDOWN.png` | 4-Panel: Map, Plot-Grundriss, Stadtmitte, Mine Shaft | 6 Plots ringförmig um die Mitte, jeder mit eigener Straße; Seen/Teiche zwischen den Plots; Berge rundum. Mine-Panel ist eine **ältere Fassung mit Förderband** (verworfen laut `00` §13). |
| `FACTORY_MASTERPLAN_TOPDOWN.png` | Hallen-Grundriss | Büro oben links (in der Halle), Elevator oben links-mittig, Lager oben mittig, Schmelze rechts, Garage unten mittig, großes Glas-Rolltor unten mittig zur Straße. Kein Ladebereich markiert. Regale statt Silo im Lager, zwei Silos außen rechts. |
| `CENTRAL_AREA_REFERENCE.png` | Stadtmitte | Equipment (blau, links), Machine (orange, hinten), Vehicle (rot, rechts), Verkauf (grün, vorne direkt an der Straße mit Fahrzeug-Parkzone). Brunnenplatz in der Mitte, Wasserturm, Windrad, 2–3 Dekohäuser. |
| `MINE_SHAFT_REFERENCE.png` | Mine Shaft | Ein Raum, eine Ebene. Elevator-Käfig mittig auf Podest mit Treppe. Zwei Erzhaufen an gegenüberliegenden Wänden („Mining Platz 1/2“). Holzverbau, Lampen, Kisten, Fässer. Keine Schienen, kein Förderband. |

## Confirmed Core Rules

- 6 Plots pro Server, gleiche Größe, festes Layout, kein freies Bauen.
- Blechhütte $0, bleibt dauerhaft als Büro **innerhalb** der Halle, enthält Laptop und Bett (Spawn).
- Firmenname (Textfilter), Logo (Auswahl), Farbe (nur Akzent) bei der Ersteinrichtung.
- Tycoon: immer nur der nächste Haupt-Kaufbutton, Bauteil erscheint sofort, Kette datengetrieben.
- Reihenfolge: Büro → Elevator/frühe Infrastruktur → Lager → Garage → Schmelzer → weitere Automatisierung.
- 100 Minen, 50 Erze, je 2 Minen pro Erz, Coal (01–02) bis Diamond (99–100). Coal = Coal überall.
- Mine Shaft: ein kompakter Raum, Elevator mittig, 2 Mining-Slots, keine Schienen/Loren/Förderbänder.
- Erzadern unendlich, Wand wird nie zerstört.
- Pro Mining-Slot Worker ODER Drill. Plus 2 Transport-Slots, max. 4 Worker pro Mine.
- Worker früh, HireCost + Gehalt pro Minute, unbezahlt → pausiert.
- Drills nur an festen Slots, Inventar zuerst, keine Rare Drops.
- Rare Drops nur manuell, entweder Mengenmultiplikator (1–10×) oder 1 Erz aus bis zu 4 Stufen höher, nie beides. Rare Ore schaltet nichts frei.
- XP nur beim Verkauf, SellValue und MiningXP getrennt. Kein XP durch Trade.
- Ein Lager, 1.000 Startkapazität über alle Materialien, Upgrade im Laptop.
- Elevator hat begrenzte, upgradebare Materialkapazität. Elevator darf technisch teleportieren.
- Erstes Fahrzeug 1.000 Kapazität, Spieler fährt immer selbst, kein Auto-Verkauf, keine Kollision zwischen Spielerfahrzeugen.
- Conveyors ca. ab Level 35, nur feste Slots.
- Schmelzer wählt Rezept automatisch, Output wertvoller als Input, Rohverkauf bleibt sinnvoll.
- Drei getrennte Shops, kein Upgrade-Shop. Level schaltet frei, Geld kauft.
- Mining Level unten mittig, Level 100 = Prestige, Architektur bis 1000+.
- Offline max. 1 h, nur Material, respektiert alle Kapazitäten, Serverzeit maßgeblich.
- Serverautorität für alles Wirtschaftliche; Session Lock, DataVersion, Migration, Autosave.
- Keine Pets, keine Zusatzwährungen, keine Lootboxen, kein dynamischer Markt in V1.

## Contradictions Resolved by 00_READ_ME_FIRST

| Widerspruch | Ältere Quelle | Auflösung (Quelle) |
|---|---|---|
| Welt als „kleine Bergbaustadt“ mit Dekohäusern | `01` §10–11, `08` | Kompakte Service-Mitte, keine Stadt, nur wenige Dekogebäude (`00` §6, §11) |
| Shop-Name „Drill/Conveyor Shop“ | `01`, `08` | Heißt **Machine Shop** (`00` §11) |
| Erzwert verdoppelt sich je Stufe | `01` §16, `03` §12 | Kein `2^n`, kontrolliertes Wachstum (`00` §22, `11` §3) |
| Rare Drop „zusätzlich 1–10×“ | `03` §7 | Ergebnis ist **entweder** Menge 1–10× **oder** Rare Ore (`00` §21, `11` §18) |
| Mine-Panel in `MAP_MASTERPLAN` mit Förderband | Bild | Verworfen, `MINE_SHAFT_REFERENCE.png` gilt (`00` §13) |
| „Mining Platz 2 (z. B. Eisen)“ im Mine-Bild | Bild | Beschriftung ist nur Beispiel. Eine Mine = ein Erz (`03` §2, `00` §22) |
| Garage im Bild mit 4 geparkten Fahrzeugen | Bild | Keine festen Parkplätze, nur das aktive Fahrzeug spawnt (`01` §29, `07` §4) |
| Garagentor „leicht rechts“ | `04` §21, `19` §9 | Bild zeigt Tor unten mittig; räumliche Komposition folgt dem Bild (`00` §5) |
| Vertical Slice inkl. Worker/Storage | `12` §75 | Erster Slice ist kleiner (`00` §32, `16` Phase 2) |
| Laptop-Bereiche „Overview/Upgrades/Vehicles/Prestige“ | `01` §32 | Dashboard/Employees/Storage/Elevator/Production/Company (`09` §23, `20`) |
| Dateiverweise auf nicht vorhandene Dokumente | `01` §57, `06`, `08`, `09`, `10` | Siehe Hinweis unter „Documents Read“ |

## Remaining Open Blocking Questions

Keine. Phase 1 kann ohne Antworten starten.

## Remaining Open Non-Blocking Questions

Details mit Defaults in `QUESTIONS/OPEN_QUESTIONS.md`:

Beantwortet am 2026-10-04: Q-001 → D-002, Q-002 → D-003 (Startgeld $800, Elevator $200), Q-003 → D-004.

Beantwortet am 2026-10-04: Q-004 bis Q-012 → D-005 bis D-013.

Noch offen:

Beantwortet am 2026-10-04: Q-013 → D-016, Q-014 → D-015. Keine offenen Fragen.

## Proposed Technical Decisions (Veto möglich)

Diese Punkte sind reine Technik, keine Designregeln. Ich setze sie so um, außer Felix widerspricht:

1. **Mine-Instanzierung:** Nicht 100 Minen × 6 Spieler im Workspace. Jeder Plot bekommt einen eigenen, unsichtbar getrennten Mine-Shaft-Bereich unter der Map. Beim Elevator-Wechsel wird dieser Raum auf die gewählte Mine umkonfiguriert (Erzart, Felsfarbe, Slots, Worker/Drills). Produktion aller Minen läuft rein serverseitig als Daten weiter, auch wenn niemand im Raum ist.
2. **Speichern:** ProfileStore (loleris, MIT) für Session Lock, Autosave und Shutdown-Save. Wird als einzelne Datei ins Repo übernommen (`src/server/Packages`), keine zusätzliche Paketverwaltung nötig.
3. **Kartenmaßstab:** Plot-, Hallen- und Straßenmaße werden in Phase 1 als zentrale Layout-Config aus den Masterplänen abgeleitet (Straßen breit genug für spätere LKW). Werte sind als `TODO_LAYOUT` markiert und änderbar.
4. **UI:** Eigene schlanke Komponenten-Module in Luau (Button, Card, ProgressBar, Notification, Modal) ohne externes UI-Framework, zentrale `UITheme`-Config.
5. **Remotes:** Eine zentrale Registry (`Shared/Remotes`) erzeugt alle RemoteEvents/Functions serverseitig; Server prüft Typen, Besitz und Rate-Limit pro Remote.
6. **StreamingEnabled:** ab Phase 1 aktiv, damit Streaming-Probleme früh auffallen.

## Proposed First Build Phase

**Phase 1 – Project Skeleton** (`16` §4), ohne Gameplay-Content:

- Ordnerstruktur nach `15` §5
- Service-Bootstrap (Server) und Controller-Bootstrap (Client) mit definierter Startreihenfolge
- Zentrale Remote-Registry mit Validierungs-Helfern
- Data Schema v1 + DataService (Laden, Speichern, Session Lock, DataVersion, Default-Profil)
- Zentrale Configs und erste Definitionen mit `TODO_BALANCE`: alle 50 Erze mit stabilen IDs, Mine 01–100 abgeleitet, Starter Pickaxe, Starter Backpack, Baukette-Grundgerüst
- Hilfsmodule: Result-Codes, Number-Formatting
- Plot Ownership: 6 Plots, Zuweisung beim Join, Freigabe beim Leave, Besitzprüfung

Testbar in Studio danach: Join mit 1–2 Testspielern → jeder bekommt einen Plot, Daten werden geladen/gespeichert, Rejoin behält einen Testwert, kein Fehler im Output.

## Planned Files / Systems

```text
src/shared/
├── Config/         GameConfig, BalanceConfig (TODO_BALANCE), LayoutConfig (TODO_LAYOUT), UITheme
├── Definitions/    Ores, Mines, Pickaxes, Backpacks, BuildSteps, Logos
├── Types/          gemeinsame Luau-Typen (PlayerData, Results, Definitions)
├── Util/           NumberFormat, Result, Signal
└── Remotes         zentrale Remote-Namen und -Signaturen

src/server/
├── Bootstrap.server.luau
├── Packages/       ProfileStore
└── Services/
    ├── DataService       (Phase 1)
    ├── PlotService       (Phase 1)
    ├── RemoteService     (Phase 1)
    ├── EconomyService    (Phase 2)
    ├── BuildingService   (Phase 2)
    ├── CompanyService    (Phase 2: Name/Logo/Farbe, Textfilter)
    ├── ElevatorService   (Phase 2)
    ├── MiningService     (Phase 2)
    ├── InventoryService  (Phase 2)
    ├── SellingService    (Phase 2)
    ├── WorkerService, ProductionService, StorageService (Phase 3–4)
    └── VehicleService, TradingService, PrestigeService, OfflineService (später)

src/client/
├── Bootstrap.client.luau
├── Controllers/    HUD, Mining, Elevator, Tycoon, Company, Selling, Notification
└── UI/Components/  Button, Card, ProgressBar, Notification, Modal

assets/             Platzhalter-Modelle (Plot, Hütte, Elevator, Mine Shaft, Stadt)
ASSETS/ASSET_REGISTRY.md  (ab Phase 2, `19` §19)
```

## Feature-Matrix

| System | Quelle | Phase | Status |
|---|---|---|---|
| Plot-Zuweisung / Ownership | 04, 15 | 1 | TESTING_REQUIRED |
| Datenspeicherung / Session Lock | 14 | 1 | TESTING_REQUIRED |
| Tycoon-Baukette | 04 | 2 | USER_APPROVED |
| Blechhütte + Firmenidentität | 04, 09 | 2 | USER_APPROVED |
| Elevator + Mine-Auswahl | 04, 09, 12 | 2 | USER_APPROVED |
| Mine Shaft 01 | 00 §13, 03 | 2 | USER_APPROVED |
| Manuelles Mining | 03, 10 | 2 | USER_APPROVED |
| Backpack | 10 | 2 | USER_APPROVED |
| Verkauf am Tresen | 07 | 2 | TESTING_REQUIRED |
| Cash, XP, Mining Level, HUD | 09, 11 | 2 | TESTING_REQUIRED |
| Equipment-Shop | 10 | 3 | NOT_STARTED |
| Worker (Mining/Transport) + Laptop Employees | 05, 09 | 3 | NOT_STARTED |
| Storage + Laptop Storage | 06 | 4 | NOT_STARTED |
| Elevator-Kapazität + Laptop Elevator | 05, 06 | 4 | NOT_STARTED |
| Machine-Shop + Drills | 05, 10 | 5 | NOT_STARTED |
| Garage, Vehicle-Shop, Fahrzeuge, Laden, Verkauf aus Fahrzeug | 07 | 6 | NOT_STARTED |
| Conveyors | 06, 10 | 7 | NOT_STARTED |
| Smelter | 06 | 8 | NOT_STARTED |
| Trading | 13 | 9 | NOT_STARTED |
| Offline-Produktion | 14 | 10 | NOT_STARTED |
| Prestige | 12 | 11 | NOT_STARTED |
| Rare Drops / Mining Luck | 03, 11 | nach Slice A (Q-005) | NOT_STARTED |
