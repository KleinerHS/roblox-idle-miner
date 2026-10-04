# Regression Checklist

Nach Änderungen an Economy, Inventory, Save, Trading oder Prestige die betroffenen Punkte erneut prüfen.

- [x] Rojo-Sync: Server- und Client-Bootstrap starten ohne Fehler (bestanden 2026-10-04)
- [x] Phase 1: Server startet alle Services, Client alle Controller, keine Fehler (Test 1.1, bestanden 2026-10-04)
- [ ] Phase 1: Plot-Zuweisung und -Freigabe mit 2 Spielern (Test 1.6, 1.7)
- [x] Phase 1: Save/Rejoin erhöht JoinCount, kein Datenverlust (Test 1.5, bestanden 2026-10-04)
- [x] Phase 1: Remote-Rate-Limit und ignorierte Client-Aufrufe (Test 1.8, 1.9, bestanden 2026-10-04)
- [x] Phase 2a: Büro → Firma → Elevator, Cash-Abzug korrekt, Rejoin baut alles wieder auf (Test 2a.1–2a.7, Felix 2026-10-04)
- [ ] Phase 2a: Fremde Tycoon-Buttons ohne Wirkung (Test 2a.9)
- [x] Phase 2b: Elevator → Mine 01 → zurück, gesperrte Minen abgelehnt, Respawn an der Oberfläche (Test 2b.1–2b.6, Felix 2026-10-04)
- [ ] Phase 2b: Fremder Elevator nicht benutzbar (Test 2b.7)
- [ ] Phase 2c: Mining nur in der Mine, mit Spitzhacke, nah genug, mit Cooldown; Rucksack voll stoppt (Test 2c.1–2c.6)
- [ ] Phase 2c: Rucksackinhalt bleibt nach Rejoin erhalten (Test 2c.7)
