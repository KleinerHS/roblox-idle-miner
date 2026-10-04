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
