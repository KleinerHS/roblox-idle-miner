# Answered Questions

## Q-001 – Hallenhülle beim Start

**Status:** ANSWERED
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Tycoon / Plot
**Date:** 2026-10-04

### Question
Steht die große Halle (Außenwände, Dach) schon beim ersten Betreten leer auf dem Plot, oder baut der Spieler auch die Außenhülle Stück für Stück über Tycoon-Buttons?

### Why this matters
Bestimmt, was der Spieler in Vertical Slice A auf seinem Plot sieht, und wie viele Bauschritte die Baukette hat.

### Current project information
- `01` §7/§13 und `04` §4/§47.3: Halle ist von Anfang an vorhanden, nur innen leer.
- `00` §9, `12` §30, `19` §8: Halle wird über Tycoon-Käufe aufgebaut („Boden → Wandabschnitt → Hallenteil“), Endlayout ist fest.
- `00` hat Vorrang, ist hier aber nicht eindeutig.

### Default bis zur Antwort
Fundament/Bodenplatte mit Bodenmarkierungen des Endlayouts ist ab Start sichtbar. Außenwände und Dach sind frühe, eigene Bauschritte nach Büro und Elevator.

### Safe work that can continue
Baukette ist datengetrieben (`BuildSteps`). Die Antwort ändert nur Daten, nicht Code.

### Do not decide automatically
Endgültige Startoptik nicht ohne Bestätigung festschreiben.


### Answer (Felix, 2026-10-04)
Default bestätigt: Start nur mit Bodenplatte und Bodenmarkierungen, Wände/Dach als frühe Bauschritte.

**Decision:** D-002

---

## Q-002 – Elevator-Kosten vor dem ersten Verdienst

**Status:** ANSWERED
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Tycoon / Elevator
**Date:** 2026-10-04

### Question
Ist der Elevator ein eigener kostenloser Bauschritt direkt nach dem Büro, oder gehört er automatisch zum Büro dazu?

### Why this matters
Laut `12` §32 ist der Elevator der zweite Bauschritt. Ohne Elevator kann der Spieler nicht minen, ohne Minen kein Geld. Kostet der Elevator Geld und ist das Startgeld $0, hängt der Spieler fest.

### Default bis zur Antwort
Eigener Tycoon-Button „Build Elevator – $0“ direkt nach dem Büro.

### Safe work that can continue
Alles. Nur Preis/Reihenfolge in der Baukette.


### Answer (Felix, 2026-10-04)
Elevator ist ein eigener Bauschritt und kostet **$200**. Startgeld ist **$800**.

**Decision:** D-003

---

## Q-003 – Materialfluss Worker → Storage → Verkauf vor der Garage

**Status:** ANSWERED
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Worker / Storage / Selling
**Date:** 2026-10-04

### Question
Drei zusammenhängende Lücken:
1. **Vor dem Storage:** Wohin liefern Transport Worker ihr Erz, wenn noch kein Lager gebaut ist? (`16` plant Worker in Phase 3, Storage erst in Phase 4.)
2. **Zwischen Storage und Garage:** Wie wird Material aus dem Lager verkauft, bevor es ein Fahrzeug gibt? Laut `06`/`07` verlässt Material das Lager nur über Fahrzeugbeladung, und es gibt keinen automatischen Verkauf.
3. **Rucksack ins Lager:** Darf der Spieler sein manuell abgebautes Erz im Lager abladen?

### Why this matters
Ohne Lösung füllt sich das Lager in der Phase vor der Garage, ohne dass der Spieler es zu Geld machen kann. Das wäre ein toter Abschnitt im Early Game.

### Current project information
- `02` §16 (Stufe B) und `12` §75 nennen Worker und Lager zusammen.
- `07` §21: kein passiver Verkauf aus dem Lager.

### Default bis zur Antwort
- Worker werden erst einstellbar, wenn das Lager gebaut ist (Lager-Bauschritt kommt vor dem Worker-Unlock).
- Der Spieler kann am Lager Material in seinen Rucksack entnehmen und am Tresen verkaufen (Rucksackkapazität begrenzt das).
- Der Spieler kann seinen Rucksack im Lager abladen.
- Garage und erstes Fahrzeug werden so gebalanced, dass sie bald nach dem Lager kommen.

### Safe work that can continue
Phase 1 und 2 vollständig. Wird vor Phase 3 benötigt.


### Answer (Felix, 2026-10-04)
Default bestätigt: Worker erst nach gebautem Lager („Worker können nicht für eine leere Transportkette gekauft werden“). Rucksack ins Lager abladen und aus dem Lager in den Rucksack nehmen ist erlaubt. Garage folgt bald nach dem Lager.

**Decision:** D-004

---

## Q-004 – Platz für manuelles Mining neben belegten Slots

**Status:** ANSWERED
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

### Answer (Felix, 2026-10-04)
Spieler kann **nicht** minen, wenn beide Slots belegt sind. Kein dritter Bereich.

**Decision:** D-005

---

## Q-005 – Rare Drops: Zeitpunkt und voller Rucksack

**Status:** ANSWERED
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Mining / Rare Drops
**Date:** 2026-10-04

### Question
1. Sollen Rare Drops schon in Vertical Slice A enthalten sein?
2. Was passiert bei einem Rare Drop, wenn der Rucksack fast voll ist (`10` §16 verlangt eine eindeutige Regel)?

### Default bis zur Antwort
1. Nicht in Slice A (`00` §32 und `16` Phase 2 nennen sie nicht). Der Mining-Code bekommt aber schon die Stelle, an der der Rare-Wurf später eingehängt wird.
2. Ein Rare Drop darf die Rucksackkapazität einmalig überschreiten (kein Verlust). Danach greift `BACKPACK FULL` normal.

### Answer (Felix, 2026-10-04)
„5.a“: als Default A für beide Teile übernommen: Rare Drops erst nach Slice A; bei fast vollem Rucksack darf ein Rare Drop einmalig überlaufen.

**Decision:** D-006

---

## Q-006 – Quellen für Mining Luck

**Status:** ANSWERED
**Priority:** POLISH
**System:** Mining / Equipment
**Date:** 2026-10-04

### Question
Woher bekommt der Spieler Mining Luck? `10` §17: nicht automatisch über Pickaxe/Backpack, Quellen „später separat“.

### Default bis zur Antwort
Fester Basiswert in der Config (`TODO_BALANCE`). Später möglich: Prestige-Bonus.

### Answer (Felix, 2026-10-04)
B und C: eigene Luck-Upgrades/-Items und Robux-Booster.

**Decision:** D-007

---

## Q-007 – Position des Ladebereichs

**Status:** ANSWERED
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Factory Layout / Vehicles
**Date:** 2026-10-04

### Question
Wo genau liegt der Ladebereich? `04` §25 verlangt einen festen Ladebereich, `FACTORY_MASTERPLAN_TOPDOWN.png` markiert keinen.

### Default bis zur Antwort
Fahrspur vor dem Lager (zwischen Lager und Garage-Fläche), erreichbar durch das große Rolltor.

### Safe work that can continue
Alles bis Phase 6. Die Fläche wird beim Hallen-Layout freigehalten.

### Answer (Felix, 2026-10-04)
Die Fahrzeuge stehen in der Halle und werden direkt über einen kleinen Turm beladen, der das Material in die Autos speist.

**Decision:** D-008

---

## Q-008 – Fahrzeugwechsel mit Ladung

**Status:** ANSWERED
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Vehicles
**Date:** 2026-10-04

### Question
`07` §48 verlangt eine Festlegung vor der Implementierung: Was passiert mit Cargo, wenn der Spieler ein anderes Fahrzeug ausparkt?

### Default bis zur Antwort
Cargo gehört zur jeweiligen Fahrzeug-ID und bleibt dort gespeichert. Wechsel ist erlaubt, das alte Fahrzeug despawnt mit seiner Ladung, nichts geht verloren.

### Answer (Felix, 2026-10-04)
A: Wechsel erlaubt, Ladung bleibt im alten Fahrzeug gespeichert.

**Decision:** D-009

---

## Q-009 – Lager-Optik: Regale oder Silo

**Status:** ANSWERED
**Priority:** POLISH
**System:** Storage Visuals
**Date:** 2026-10-04

### Question
Text (`04` §18, `06` §16) verlangt ein großes Silo mit Füllanzeige in der Halle. `FACTORY_MASTERPLAN_TOPDOWN.png` zeigt im Lager Regale mit Kisten und zwei Silos außen an der rechten Wand.

### Default bis zur Antwort
Regalbereich laut Bild plus ein Silo mit gut lesbarer Füllanzeige innerhalb des Lagerbereichs.

### Answer (Felix, 2026-10-04)
A, „auch mit allen Verschönerungsdetails wie im Bild“.

**Decision:** D-010

---

## Q-010 – Smelter: Rezepte für Nicht-Metalle, Priorität

**Status:** ANSWERED
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Smelter
**Date:** 2026-10-04

### Question
1. Was passiert mit Erzen, die sich nicht sinnvoll schmelzen lassen (Coal, Edelsteine, Kristalle)? Kein Rezept, oder eigene Verarbeitung?
2. Welche Reihenfolge gilt bei mehreren verarbeitbaren Erzen im Lager (`06` §31)?

### Default bis zur Antwort
Nur Metalle bekommen Rezepte. Priorität: wertvollstes Erz zuerst, umschaltbar im Laptop.

### Answer (Felix, 2026-10-04)
A (nur Metalle, wertvollstes zuerst). Zusatz: In späteren Versionen sollen Legierungen möglich sein.

**Decision:** D-011

---

## Q-011 – Prestige: normale Ausrüstung behalten oder zurücksetzen

**Status:** ANSWERED
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

### Answer (Felix, 2026-10-04)
Pickaxe, Backpack und Fahrzeuge bleiben.

**Decision:** D-012

---

## Q-012 – Firmenidentität nachträglich ändern

**Status:** ANSWERED
**Priority:** POLISH
**System:** Company
**Date:** 2026-10-04

### Question
Kann der Spieler Name, Logo und Farbe später im Laptop ändern, und wenn ja, kostenlos oder gegen Cash (`09` §25)?

### Default bis zur Antwort
In Slice A nur Ersteinrichtung. Änderung kommt später mit der Company-App.

### Answer (Felix, 2026-10-04)
A, aber gegen Robux.

**Decision:** D-013

---
