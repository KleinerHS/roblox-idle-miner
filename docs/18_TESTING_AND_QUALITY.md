# 18 – TESTING AND QUALITY

## 1. Ziel

Jede Entwicklungsphase muss überprüfbar sein. Claude Code soll nicht nur Code erzeugen, sondern für jedes System konkrete Tests definieren.

---

## 2. Testebenen

```text
UNIT / LOGIC TEST
→ einzelne Berechnung

SYSTEM TEST
→ komplettes Feature

INTEGRATION TEST
→ mehrere Systeme zusammen

MULTIPLAYER TEST
→ Besitz/Server/Trades

SAVE TEST
→ Rejoin/Shutdown/Migration

EXPLOIT TEST
→ manipulierte Requests
```

---

## 3. Core Loop Test

Pflichtpfad:

```text
Join
→ Plot
→ Blechhütte
→ Elevator
→ Mine
→ Mine Ore
→ Backpack
→ Surface
→ Sell
→ Cash
→ XP
→ Save
→ Rejoin
```

Jeder Schritt muss funktionieren, bevor größere Systeme darauf aufgebaut werden.

---

## 4. Mining Tests

Prüfen:

- gültige Ader
- ungültige Distanz
- Mining Cooldown
- Pickaxe Stats
- Backpack Full
- Rare Drop nur manuell
- 1–10x und Rare Ore nicht gleichzeitig
- keine clientseitig manipulierbare Erzmenge

---

## 5. Worker Tests

Prüfen:

- HireCost
- Wage
- Worker ODER Drill pro Mining Slot
- max. vorgesehene Workerzahl
- Transportweg
- Blockade
- alternatives Pathing
- Storage Full
- Unpaid
- Rejoin

---

## 6. Drill Tests

Prüfen:

- Kauf
- Inventar
- Placement
- fremder Slot
- belegter Slot
- Produktion
- Output Full
- Ausbau
- Rejoin
- kein Dupe durch schnelles Place/Remove

---

## 7. Storage Tests

Prüfen:

- Startkapazität 1000
- mehrere Erzarten
- Gesamtlimit
- Upgrade
- Full-State
- Produktion stoppt erst, wenn alle relevanten Zwischenstufen blockiert sind
- Save/Rejoin

---

## 8. Vehicle Tests

Prüfen:

- Kauf
- Garage
- Spawnring
- direkter Seat-Spawn
- 1000 Startkapazität
- Loading
- Full
- Fahrt
- Sell
- kein Verkauf fremden Cargos
- keine Fahrzeugkollision zwischen Spielern

---

## 9. Smelter Tests

Prüfen:

- Input
- automatisches Rezept
- Produktionszeit
- Output
- Output Full
- Wert > Rohinput
- Animation/VFX nur im Betrieb

---

## 10. Trade Tests

Pflichtfälle:

- normaler Trade
- Angebotsänderung nach Lock
- Disconnect
- Drill bereits platziert
- zu wenig Erz beim Commit
- Remote Spam
- gleichzeitiger zweiter Trade
- Dupe-Versuch
- XP bleibt unverändert

---

## 11. Prestige Tests

Prüfen:

- unter Level 100 gesperrt
- Level 100 verfügbar
- klare Vorschau
- Cancel
- Confirm
- Resetliste
- permanente Boni
- Robux bleibt
- Offline Timestamp
- keine Itemduplikation
- Save/Rejoin

---

## 12. Offline Tests

Testzeiten:

```text
0 min
5 min
59 min
60 min
120 min
```

120 Minuten dürfen nur maximal 60 Minuten Produktion ergeben.

Zusätzlich:
- Storage fast voll
- Output bereits voll
- Worker unpaid
- Smelter blocked
- mehrere Produktionsketten

---

## 13. Multiplayer Ownership

Mit mindestens zwei Testspielern:

- fremder Laptop
- fremder Tycoon Button
- fremder Drill Slot
- fremdes Storage
- fremdes Fahrzeug
- fremdes Cargo
- fremde Mine/Produktion

Alles muss geschützt sein.

---

## 14. Performance Test

Mindestens simulieren:

```text
6 Spieler
mehrere Worker je Plot
mehrere Drills
mehrere Fahrzeuge
volle Fabrikbereiche
Partikel/VFX
```

Beobachten:
- Server frame time
- Client FPS
- Memory
- Network
- Pathfinding
- Physics

---

## 15. Testdateien

Claude soll im Projekt anlegen:

```text
TESTING
├── TEST_PLAN.md
├── REGRESSION_CHECKLIST.md
└── BUGS.md
```

---

## 16. Bugformat

```md
## BUG-001 – Drill duplicates on rapid removal

**Severity:** Critical
**Status:** Open
**Build:** ...
**Steps:**
1. ...
2. ...

**Expected:** ...
**Actual:** ...
**Likely system:** Inventory / Placement
```

---

## 17. Regression

Nach Änderungen an Economy, Inventory, Save, Trading oder Prestige werden relevante alte Tests erneut ausgeführt.

---

## 18. Definition of Done

Feature ist nicht fertig, nur weil es sichtbar funktioniert.

Fertig bedeutet:

- normaler Pfad funktioniert
- Fehlpfade behandelt
- Servervalidierung vorhanden
- Save/Rejoin funktioniert
- Multiplayer Ownership geprüft
- keine bekannte Duplikation
- UI zeigt korrekten Zustand
- relevante Regressionstests bestanden

---

## 19. Verbindliche Regeln

1. Tests gehören zu jeder Build-Phase.
2. Save/Rejoin wird früh getestet.
3. Multiplayerrechte werden nicht bis zum Ende verschoben.
4. Trading und Prestige erhalten Exploit-/Dupe-Tests.
5. Offline-Cap wird explizit getestet.
6. Bugs werden dokumentiert statt vergessen.
7. Kritische Bugs blockieren die nächste abhängige Phase.
