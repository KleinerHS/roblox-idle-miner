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
