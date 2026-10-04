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
| 2b.3 | Mine ansehen | Käfig nach vorne durch das offene Tor über die Treppe verlassen, umsehen | Ein Raum, eine Ebene; Korb mittig hinten auf Podest; Abbauplatz 1 hinten links, Abbauplatz 2 rechts, jeweils Kohlehaufen vor offener Erzwand mit schwerem Holzrahmen; Wände mit Holzverbau und Laternen; dunkler Fels; keine Schienen/Loren/Förderbänder |
| 2b.3a | Tor (BUG-001) | Fahrt starten, danach Ankunft beobachten | Tor schließt bei Abfahrt, Warnleuchte auf dem Dach leuchtet; Tor am Ziel ist offen, man kann sofort rauslaufen |
| 2b.4 | Fenster schließen | E drücken, dann X oder Escape bzw. wegrennen | Fenster schließt sich |
| 2b.5 | Zurück nach oben | Im Minenkäfig E → SURFACE → GO | Ankunft im Elevator auf deinem Plot, Anzeige oben verschwindet |
| 2b.6 | Respawn in der Mine | In der Mine Reset (Esc → Reset Character) | Respawn im Bett der Hütte, keine Mine-Anzeige |
| 2b.7 | Fremder Elevator (2 Spieler) | Spieler 2 drückt E am Käfig von Spieler 1 | Meldung „This is not your company.“, kein Fenster |