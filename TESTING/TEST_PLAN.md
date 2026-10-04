# Test Plan

Testebenen und Pflichttests: `docs/18_TESTING_AND_QUALITY.md`.

## Setup

1. `rojo serve` startet ohne Fehler.
2. Studio verbindet sich über das Rojo-Plugin.
3. Play: Output zeigt `[Server][Bootstrap] … gestartet` und `[Client][Bootstrap] … gestartet`.

## Phase 1 – Project Skeleton

Voraussetzung für Speichertests: Place ist veröffentlicht, Game Settings → Security → „Enable Studio Access to API Services“ = an. Sonst zeigt der Output `DataStore nicht erreichbar (NoAccess) – Testmodus` und Daten werden nicht gespeichert.

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 1.1 | Start | Play | Output: `3 Services`, `2 Controller`, keine roten Fehler |
| 1.2 | DataStore | Play (veröffentlichter Place) | `DataStore verbunden – Spielstände werden gespeichert` |
| 1.3 | Plot-Zuweisung | Play | `→ Plot 1`, Spieler steht auf Plot 1, Schild „Plot 1 / Name“, übrige Schilder „Frei“ |
| 1.4 | Default-Profil | Play (neuer Spieler) | `geladen: v1, Cash 800, Level 1, Joins 1`, Client: `Cash $800 · Level 1 · XP 0/100` |
| 1.5 | Save/Rejoin | Play beenden, erneut Play | `Joins` ist um 1 höher (Wert wurde gespeichert und geladen) |
| 1.6 | Zwei Spieler | Test → Clients and Servers → 2 Spieler → Start | Spieler 1 → Plot 1, Spieler 2 → Plot 2, beide Schilder zeigen den richtigen Namen |
| 1.7 | Plot-Freigabe | Bei 2 Spielern ein Client-Fenster schließen | Server: `Plot 2 freigegeben`, Schild wieder „Frei“ |
| 1.8 | Rate-Limit / Müll-Eingaben | Client-Befehlszeile: `for i=1,7 do print(game.ReplicatedStorage.Remotes.GetState:InvokeServer("x").success) end` | 5× `true`, danach `false`, Server meldet `Rate-Limit`, keine Fehler |
| 1.9 | Server→Client-Remote vom Client | Client: `game.ReplicatedStorage.Remotes.StateSnapshot:FireServer({Cash=1e9})` | Keine Wirkung, kein Fehler |

## Phase 2a – Tycoon & Firmeneinrichtung

Ausgangszustand herstellen (nur in Studio): während Play in der **Server**-Befehlszeile
`game.ServerStorage.DevTools.ResetProgress:Invoke(game.Players:GetPlayers()[1])`

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 2a.1 | Startzustand | Play | Spawn neben grünem Button „BUILD OFFICE / FREE“ hinten links in der Halle, gelbe Bodenmarkierungen der Endhalle sichtbar |
| 2a.2 | Büro kaufen | Auf den Button laufen | Blechhütte erscheint sofort, Button verschwindet, Toast „Office built!“, Firmendialog öffnet sich |
| 2a.3 | Name zu kurz | 2 Zeichen eingeben → FOUND COMPANY | Rote Meldung „Company name must be 3–24 characters.“, Dialog bleibt offen |
| 2a.4 | Firma gründen | Name, Logo, Farbe wählen → FOUND COMPANY | Dialog schließt, Toast „… is open for business!“, Schild an der Einfahrt zeigt Logo + Name, Leiste in Firmenfarbe |
| 2a.5 | Elevator-Button | nach 2a.4 | Neuer Button „BUILD ELEVATOR / $200“ vor dem Elevator-Bereich |
| 2a.6 | Elevator kaufen | Auf den Button laufen | Käfig erscheint, Cash 800 → 600, kein weiterer Button |
| 2a.7 | Rejoin | Stop → Play | Hütte, Elevator, Schild wieder da, Spawn auf dem Bett in der Hütte, Dialog öffnet sich NICHT erneut |
| 2a.8 | Dialog nach Abbruch | Reset → Büro kaufen → Stop, ohne Firma zu gründen → Play | Dialog öffnet sich wieder, Elevator-Button fehlt bis zur Gründung |
| 2a.9 | Fremder Button (2 Spieler) | Spieler 2 läuft auf den Button von Spieler 1 | Toast „This is not your company.“, nichts wird gekauft |

## Phase 2b – Elevator & Mine Shaft 01

Voraussetzung: Büro, Firma und Elevator sind gebaut (2a).

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 2b.1 | Elevator öffnen | In den Käfig gehen, Taste **E** („Use Elevator“) | Fenster „SELECT MINE“: Mine 01 mit grünem GO, Mine 02–100 „LOCKED / Coming soon“ |
| 2b.2 | Fahrt nach unten | GO bei Mine 01 | Bild blendet ab mit „MINE SHAFT 01 / COAL“, kurzes Ruckeln, Ankunft im Käfig der Mine, oben mittig „MINE SHAFT 01 · COAL“ |
| 2b.3 | Mine ansehen | Käfig nach vorne durch das offene Tor über die Treppe verlassen, umsehen | Ein Raum, eine Ebene; Korb mittig hinten auf Podest; Abbauplatz 1 hinten links, Abbauplatz 2 rechts, jeweils offene Kohle-Erzwand mit schwerem Holzrahmen und freier Fläche davor; Wände mit Holzverbau und Laternen; dunkler Fels; keine Schienen/Loren/Förderbänder |
| 2b.3a | Tor (BUG-001) | Fahrt starten, danach Ankunft beobachten | Tor schließt bei Abfahrt, Warnleuchte auf dem Dach leuchtet; Tor am Ziel ist offen, man kann sofort rauslaufen |
| 2b.4 | Fenster schließen | E drücken, dann X oder Escape bzw. wegrennen | Fenster schließt sich |
| 2b.5 | Zurück nach oben | Im Minenkäfig E → SURFACE → GO | Ankunft im Elevator auf deinem Plot, Anzeige oben verschwindet |
| 2b.6 | Respawn in der Mine | In der Mine Reset (Esc → Reset Character) | Respawn im Bett der Hütte, keine Mine-Anzeige |
| 2b.7 | Fremder Elevator (2 Spieler) | Spieler 2 drückt E am Käfig von Spieler 1 | Meldung „This is not your company.“, kein Fenster |
## Phase 2c – Mining & Rucksack

Voraussetzung: Elevator gebaut (2a). Testwerkzeug (Server-Befehlszeile, nur Studio):
`game.ServerStorage.DevTools.FillBackpack:Invoke(game.Players:GetPlayers()[1], 95)`

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 2c.1 | Spitzhacke | Play, Taste **1** | Spitzhacke in der Hand |
| 2c.2 | Oberfläche | An der Oberfläche klicken | Meldung „You can only mine inside a mine.“, kein Erz |
| 2c.3 | Mining | Mine 01 → zur Erzwand mit Holzrahmen gehen → klicken | Schlag-Animation, Brocken spritzen, „+1 Coal“ über der Wand, Rucksack unten rechts zählt hoch |
| 2c.4 | Tempo | Schnell klicken | Höchstens ca. 1 Hit pro Sekunde zählt (Mining Speed der Starter-Spitzhacke) |
| 2c.5 | Zu weit weg | In der Raummitte klicken | „Move closer to the ore.“ |
| 2c.6 | Rucksack voll | Rucksack auf 95 füllen, 5× minen, weiter klicken | Bei 100/100 „BACKPACK FULL“ rot, Meldung „Backpack full! …“, kein weiteres Erz |
| 2c.7 | Speichern | Etwas Kohle minen → Stop → Play | Rucksack hat noch die gleiche Menge |
## Phase 2d – Verkauf, Cash & Mining Level (Abschluss Vertical Slice A)

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 2d.1 | HUD | Play | Geld oben rechts, unten mittig „MINING LEVEL n“ mit XP-Balken (in Firmenfarbe) |
| 2d.2 | Verkaufsgebäude | Vom Plot die Straße zur Mitte gehen | Grünes Gebäude „$ SELL“ vorne an der Mitte, Eingang zur Straße |
| 2d.3 | Tresen | Hineingehen, am Tresen **E** („Sell Ore“) | Fenster „SELL ORE“ mit Rucksackinhalt, Gesamtwert und Mining XP |
| 2d.4 | Verkaufen | SELL ALL | Fenster schließt, „SOLD +$… +… Mining XP“, Geld zählt hoch, XP-Balken wächst, Rucksack leer |
| 2d.5 | Level-Up | Genug verkaufen (Level 1 → 2 braucht 100 XP) | „LEVEL UP! Mining Level 2“ |
| 2d.6 | Leer | Mit leerem Rucksack SELL ALL | Button ausgegraut, Hinweis „Your backpack is empty…“ |
| 2d.7 | Kompletter Loop + Speichern | Join → Mine 01 → Kohle abbauen → Oberfläche → verkaufen → Stop → Play | Geld, Level, XP sind gespeichert |
| 2d.8 | Zwei Spieler | Test → Testsitzung beginnen → Server + 2 Clients | Plot 1 / Plot 2, eigene Schilder; Spieler 2 kann Büro-Button und Elevator von Spieler 1 nicht benutzen („This is not your company.“); Fenster schließen → Plot frei |
## Phase 3a – Equipment-Shop & Mine 02

Werte (Preise, Level, Stats) sind Platzhalter aus Q-015.

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 3a.1 | Shop-Gebäude | Zur Mitte gehen | Blaues Gebäude „⛏ EQUIPMENT“ links der Mitte, Eingang zum Platz; innen Spitzhacken an der Wand, Rucksäcke auf dem Tisch |
| 3a.2 | Shop öffnen | Am Tresen **E** („Shop“) | Fenster „EQUIPMENT“ mit Reitern PICKAXES / BACKPACKS |
| 3a.3 | Status | Karten ansehen | Starter = EQUIPPED; nächste Stufe BUY $… oder LOCKED „Requires Mining Level n“; Stats mit Vergleich „alt → neu“ |
| 3a.4 | Kaufen | Ab Level 2 mit genug Geld Iron Pickaxe kaufen | Geld sinkt, Meldung „… purchased and equipped!“, Karte EQUIPPED, neue Hacke in der Hand (hellerer Kopf) |
| 3a.5 | Ausrüsten | Starter Pickaxe → EQUIP | Wechsel zurück, Tool in der Hand wechselt |
| 3a.6 | Fehler | Zu wenig Geld / zu niedriges Level | Meldung „Not enough money…“ bzw. „Requires Mining Level …“, nichts passiert |
| 3a.7 | Rucksack | Reinforced Backpack kaufen | Rucksackanzeige zeigt „… / 200“ |
| 3a.8 | Mine 02 | Level 3 erreichen | „NEW MINE UNLOCKED – MINE 02 – COAL“; im Elevator ist Mine 02 mit GO wählbar |
| 3a.9 | Speichern | Stop → Play | Gekaufte und ausgerüstete Items bleiben |
## Phase 4a – Halle & Lager

Werte (Preise/Level der Bauschritte) sind Platzhalter aus Q-017. Testwerkzeuge (Server-Befehlszeile, nur Studio):
`game.ServerStorage.DevTools.SetLevel:Invoke(game.Players:GetPlayers()[1], 5)` und `SetCash` (siehe 3a).

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 4a.1 | Wände | Nach dem Elevator: Button „BUILD WALLS“ vorne in der Halle (ab Level 3, $1.500) | Außenwände mit Sockel, Fensterband und großem offenem Rolltor vorne erscheinen |
| 4a.2 | Dach | Button „BUILD ROOF“ (ab Level 4, $2.500) | Flachdach mit Oberlichtern und Hallenleuchten |
| 4a.3 | Lager | Button „BUILD STORAGE“ vor dem Lagerbereich (ab Level 5, $5.000) | Regale mit Kisten, Silo mit Anzeige „STORAGE 0 / 1,000“, Terminal |
| 4a.4 | Abladen | Kohle abbauen → Terminal **E** → DEPOSIT BACKPACK | Rucksack leer, Lager zeigt die Menge, Silo-Anzeige zählt hoch |
| 4a.5 | Entnehmen | Im Lagerfenster bei Coal TAKE | So viel wie in den Rucksack passt wandert zurück |
| 4a.6 | Lager voll | Mehr als 1.000 einlagern | Rest bleibt im Rucksack, „Storage is full!“, Silo-Balken rot |
| 4a.7 | Speichern/Migration | Stop → Play | Gebäude und Lagerbestand bleiben; alter Spielstand (v1) wird automatisch auf v2 gebracht |
| 4a.8 | Fremdes Lager (2 Spieler) | Spieler 2 drückt E am Terminal von Spieler 1 | „This is not your company.“ |
## Phase 4b – Worker & Laptop

Werte sind Platzhalter aus Q-018. Voraussetzung: Lager gebaut.

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 4b.1 | Laptop | In der Hütte am Laptop **E** („Use Laptop“) | Kamera zoomt kurz, Laptop-Fenster mit Firmenname, App-Leiste, EMPLOYEES aktiv |
| 4b.2 | Einstellen | MINE 01 → Mining Slot 1 → HIRE $2K | Geld −$2.000, Slot zeigt „Mining Worker #… · Working · $5 / min“ |
| 4b.3 | Transport | Transport Slot 1 → HIRE $1.5K | Status Working; „Elevator: x / 100“ steigt |
| 4b.4 | Produktion | Ein paar Minuten warten | Silo-Anzeige im Lager zählt hoch (ca. 30 Kohle/Min pro Mining-Worker) |
| 4b.5 | Figuren | Elevator → Mine 01 | Mining-Worker mit Helm hackt an der Wand, Transport-Worker läuft mit Kiste zur Elevator-Treppe |
| 4b.6 | Lohn | Eine Minute warten | Geld sinkt um den Lohn ($5 + $4) |
| 4b.7 | Unbezahlt | Mit SetCash Geld auf 0 setzen, eine Minute warten | Meldung „Not enough money for wages…“, Status „Unpaid“, Produktion stoppt; Geld geben → nach der nächsten Minute wieder „Working“ |
| 4b.8 | Lager voll | Lager füllen (oder warten) | Elevator-Anzeige bleibt voll, Worker zeigen „Waiting“, nichts verschwindet |
| 4b.9 | Entlassen | FIRE | Slot wieder leer, kein Lohn mehr, Figur verschwindet |
| 4b.10 | Speichern | Stop → Play | Worker, Puffer und Lagerbestand bleiben erhalten |

## Phase 4c – Laptop-Apps & Upgrades

Werte aus D-022. Voraussetzung: Lager gebaut.

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 4c.1 | Dashboard | Laptop öffnen | Startet auf DASHBOARD: Level/XP, Cash, Lager x / y mit Balken, Mitarbeiter (Active/Waiting/Unpaid), Produktion Erz/Min und Elevator-Füllstand |
| 4c.2 | Storage-App | STORAGE | Belegung mit Balken, Liste der Erze mit Menge, Upgrade-Karte „Upgrade 0 / 4 · Current 1,000 → Next 2,500 · Cost $3K · Requires Mining Level 5“ |
| 4c.3 | Lager-Upgrade | UPGRADE $3K (Level 5, genug Geld) | Geld −$3.000, Meldung „Storage upgraded to 2500!“, Silo-Anzeige im Lager zeigt / 2,500 |
| 4c.4 | Sperren | Nächste Stufe ohne Level 6 bzw. ohne Geld drücken | „Requires Mining Level 6.“ bzw. „Not enough money. You need $8000.“, nichts gekauft |
| 4c.5 | Elevator-App | ELEVATOR | Kapazität pro Fahrt, Takt 10 s, max. Erz/Min, Inhalt, Status, Upgrade-Karte |
| 4c.6 | Elevator-Upgrade | UPGRADE $2K | Kapazität 200, EMPLOYEES zeigt „Elevator: x / 200“ |
| 4c.7 | Max-Stufe | Mit DevTools Level/Geld hoch, alle Stufen kaufen | „MAX LEVEL · Fully upgraded.“ |
| 4c.8 | Speichern | Stop → Play | Gekaufte Kapazitäten bleiben erhalten |

## Phase 5a – Machine-Shop & Drills

Werte sind Vorschläge aus Q-020. Für den Kauf: `SetLevel(…, 6)` und `SetCash(…, 20000)`.

| # | Test | Schritte | Erwartet |
|---|---|---|---|
| 5a.1 | Gebäude | Zur Stadtmitte, hinten rechts | Oranger Machine-Shop mit Schild „MACHINES“, offenem Rolltor, Plattform mit zwei Drills, Werkzeugwand, Tresen |
| 5a.2 | Shop öffnen | Am Tresen **E** („Shop“) | Fenster „MACHINES“, Reiter DRILLS, drei Karten mit Produktion, Output-Puffer und Inventar |
| 5a.3 | Gesperrt | Unter Level 6 | MK1 zeigt „LOCKED · Requires Mining Level 6“ |
| 5a.4 | Kaufen | Level 6, genug Geld → BUY $8K | Geld −$8.000, Meldung „Drill MK1 purchased! Place it in a mine.“, Inventar „Owned 1 · Placed 0 · Available 1“ |
| 5a.5 | Mehrfach | Noch einmal kaufen | „Owned 2 … Available 2“ |
| 5a.6 | Zu wenig Geld | Ohne genug Geld kaufen | „Not enough money. You need $8000.“, nichts gekauft |
| 5a.7 | Speichern | Stop → Play | Drills bleiben im Inventar; alter Spielstand wird auf v4 gebracht |
| 5a.8 | Equipment-Shop | Equipment-Shop öffnen | Unverändert (Reiter PICKAXES/BACKPACKS) |