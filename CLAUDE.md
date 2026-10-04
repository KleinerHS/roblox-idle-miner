# Hinweise für Claude

- Spezifikation: `docs/00_READ_ME_FIRST.md` zuerst, dann `docs/01`–`docs/20`. Konfliktpriorität steht in 00, Abschnitt 5.
- Sprache für Antworten und Projektdokumente: Deutsch. Code-Bezeichner, IDs und Kommentare im Code dürfen Englisch/Deutsch sein, aber konsistent je Datei.
- Arbeitsregel (verbindlich): Nach jedem Hauptschritt STOPPEN, Checkpoint-Bericht mit Testanleitung für Roblox Studio liefern, `IMPLEMENTATION_STATUS.md` und ggf. `TESTING/` und `QUESTIONS/` pflegen. Weiter erst nach ausdrücklicher Freigabe.
- Status je System: IMPLEMENTED, TESTING_REQUIRED, USER_APPROVED, BUGGED, BLOCKED. USER_APPROVED nur nach Bestätigung des Nutzers.
- Bei gemeldetem Fehler: nur diesen Fehler behandeln, Ursache finden, nichts auf Verdacht ändern.
- Technik: Rojo (`default.project.json`), Luau mit `--!strict`, serverautoritativ, datengetrieben, stabile IDs (`ore_coal`, `pickaxe_basic` …), keine Monolith-Scripts.
- Balancewerte, die nicht festgelegt sind: `TODO_BALANCE` in zentraler Config, nicht raten.
