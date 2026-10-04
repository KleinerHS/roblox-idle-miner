# Open Questions

Format und Workflow: `docs/17_QUESTIONS_AND_DECISION_WORKFLOW.md`. IDs fortlaufend (Q-001 …), nie wiederverwenden.

Stand: 2026-10-04

Stand nach Felix' Antwort vom 2026-10-04: Q-001 bis Q-003 beantwortet (siehe `ANSWERED_QUESTIONS.md`).

Aktuell blockiert **keine** Frage Phase 1 (Project Skeleton). Für jede Frage ist ein **Default** angegeben, mit dem gebaut wird, bis eine Antwort vorliegt. Alle Defaults liegen in zentraler Config und sind ohne Umbau änderbar.

| ID | Thema | Priorität | Betrifft Phase |
|---|---|---|---|
| Q-004 | Platz für manuelles Mining neben belegten Slots | IMPORTANT_NON_BLOCKING | 2, 3 |
| Q-005 | Rare Drops: Zeitpunkt und voller Rucksack | IMPORTANT_NON_BLOCKING | 2+ |
| Q-006 | Quellen für Mining Luck | POLISH | später |
| Q-007 | Position des Ladebereichs | IMPORTANT_NON_BLOCKING | 6 |
| Q-008 | Fahrzeugwechsel mit Ladung | IMPORTANT_NON_BLOCKING | 6 |
| Q-009 | Lager-Optik: Regale oder Silo | POLISH | 4 |
| Q-010 | Smelter: Rezepte für Nicht-Metalle, Priorität | IMPORTANT_NON_BLOCKING | 8 |
| Q-011 | Prestige: normale Ausrüstung behalten oder zurücksetzen | IMPORTANT_NON_BLOCKING | 11 |
| Q-012 | Firmenidentität nachträglich ändern | POLISH | später |

---



## Q-004 – Platz für manuelles Mining neben belegten Slots

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Mine Shaft / Mining
**Date:** 2026-10-04

### Question
Wo minet der Spieler, wenn beide Mining-Slots mit Worker/Drill belegt sind?

### Why this matters
`05` §10 verlangt einen eigenen Bereich für den Spieler. `MINE_SHAFT_REFERENCE.png` zeigt nur die zwei Mining-Plätze. Das Minenlayout entsteht schon in Slice A.

### Default bis zur Antwort
Jeder der beiden Erzbereiche ist breit genug: Worker/Drill belegt einen festen Punkt am Rand, der Spieler kann an der restlichen Fläche desselben Erzbereichs minen. Kein dritter Bereich.

### Safe work that can continue
Alles. Wird beim Mine-Layout in Phase 2 berücksichtigt.

---

## Q-005 – Rare Drops: Zeitpunkt und voller Rucksack

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Mining / Rare Drops
**Date:** 2026-10-04

### Question
1. Sollen Rare Drops schon in Vertical Slice A enthalten sein?
2. Was passiert bei einem Rare Drop, wenn der Rucksack fast voll ist (`10` §16 verlangt eine eindeutige Regel)?

### Default bis zur Antwort
1. Nicht in Slice A (`00` §32 und `16` Phase 2 nennen sie nicht). Der Mining-Code bekommt aber schon die Stelle, an der der Rare-Wurf später eingehängt wird.
2. Ein Rare Drop darf die Rucksackkapazität einmalig überschreiten (kein Verlust). Danach greift `BACKPACK FULL` normal.

---

## Q-006 – Quellen für Mining Luck

**Status:** OPEN
**Priority:** POLISH
**System:** Mining / Equipment
**Date:** 2026-10-04

### Question
Woher bekommt der Spieler Mining Luck? `10` §17: nicht automatisch über Pickaxe/Backpack, Quellen „später separat“.

### Default bis zur Antwort
Fester Basiswert in der Config (`TODO_BALANCE`). Später möglich: Prestige-Bonus.

---

## Q-007 – Position des Ladebereichs

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Factory Layout / Vehicles
**Date:** 2026-10-04

### Question
Wo genau liegt der Ladebereich? `04` §25 verlangt einen festen Ladebereich, `FACTORY_MASTERPLAN_TOPDOWN.png` markiert keinen.

### Default bis zur Antwort
Fahrspur vor dem Lager (zwischen Lager und Garage-Fläche), erreichbar durch das große Rolltor.

### Safe work that can continue
Alles bis Phase 6. Die Fläche wird beim Hallen-Layout freigehalten.

---

## Q-008 – Fahrzeugwechsel mit Ladung

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Vehicles
**Date:** 2026-10-04

### Question
`07` §48 verlangt eine Festlegung vor der Implementierung: Was passiert mit Cargo, wenn der Spieler ein anderes Fahrzeug ausparkt?

### Default bis zur Antwort
Cargo gehört zur jeweiligen Fahrzeug-ID und bleibt dort gespeichert. Wechsel ist erlaubt, das alte Fahrzeug despawnt mit seiner Ladung, nichts geht verloren.

---

## Q-009 – Lager-Optik: Regale oder Silo

**Status:** OPEN
**Priority:** POLISH
**System:** Storage Visuals
**Date:** 2026-10-04

### Question
Text (`04` §18, `06` §16) verlangt ein großes Silo mit Füllanzeige in der Halle. `FACTORY_MASTERPLAN_TOPDOWN.png` zeigt im Lager Regale mit Kisten und zwei Silos außen an der rechten Wand.

### Default bis zur Antwort
Regalbereich laut Bild plus ein Silo mit gut lesbarer Füllanzeige innerhalb des Lagerbereichs.

---

## Q-010 – Smelter: Rezepte für Nicht-Metalle, Priorität

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Smelter
**Date:** 2026-10-04

### Question
1. Was passiert mit Erzen, die sich nicht sinnvoll schmelzen lassen (Coal, Edelsteine, Kristalle)? Kein Rezept, oder eigene Verarbeitung?
2. Welche Reihenfolge gilt bei mehreren verarbeitbaren Erzen im Lager (`06` §31)?

### Default bis zur Antwort
Nur Metalle bekommen Rezepte. Priorität: wertvollstes Erz zuerst, umschaltbar im Laptop.

---

## Q-011 – Prestige: normale Ausrüstung behalten oder zurücksetzen

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Prestige / Inventory
**Date:** 2026-10-04

### Question
Welche normal mit Cash gekauften Pickaxes, Backpacks, Drills und Fahrzeuge werden beim Prestige zurückgesetzt, welche bleiben?

### Why this matters
Die Reset-Logik muss wissen, welche Itemklassen permanent sind.

### Current project information
- Robux-Käufe und Prestige-Boni bleiben.
- Normale Firmenprogression wird zurückgesetzt.
- Ausrüstung ist ausdrücklich offen (`00` §27, `12` §54, `20`).

### Safe work that can continue
Item-Besitz bekommt ab Phase 1 ein Feld `PersistenceClass` (`Progression` / `Permanent` / `RobuxEntitlement`).

### Do not decide automatically
Wird erst bei Phase 11 benötigt. Nicht selbst entscheiden.

---

## Q-012 – Firmenidentität nachträglich ändern

**Status:** OPEN
**Priority:** POLISH
**System:** Company
**Date:** 2026-10-04

### Question
Kann der Spieler Name, Logo und Farbe später im Laptop ändern, und wenn ja, kostenlos oder gegen Cash (`09` §25)?

### Default bis zur Antwort
In Slice A nur Ersteinrichtung. Änderung kommt später mit der Company-App.
