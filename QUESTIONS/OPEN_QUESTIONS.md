# Open Questions

Format und Workflow: `docs/17_QUESTIONS_AND_DECISION_WORKFLOW.md`. IDs fortlaufend (Q-001 …), nie wiederverwenden.

Stand: 2026-10-04

Q-001 bis Q-012 sind beantwortet (siehe `ANSWERED_QUESTIONS.md`, Entscheidungen D-002 bis D-013).

Aktuell blockiert **keine** Frage die laufende Phase.

| ID | Thema | Priorität | Betrifft Phase |
|---|---|---|---|
| Q-013 | Stehen gekaufte Fahrzeuge geparkt in der Halle? | IMPORTANT_NON_BLOCKING | 6 |

---

## Q-013 – Stehen gekaufte Fahrzeuge geparkt in der Halle?

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Garage / Vehicles
**Date:** 2026-10-04

### Question
Zu D-008 („die Fahrzeuge stehen in der Halle und werden direkt beladen“): Stehen **alle** gekauften Fahrzeuge dauerhaft geparkt in der Garage (wie im Grundriss-Bild mit 4 Fahrzeugen), oder gibt es nur das aktive Fahrzeug, das am Spawn-Ring erscheint und zum Beladen unter den Verladeturm fährt?

### Why this matters
Bisher gilt laut `docs/04` §22 und `docs/07` §4: keine festen Parkplätze, nur das aktive Fahrzeug spawnt. Geparkte Fahrzeuge brauchen Stellplätze im Hallenlayout und kosten Performance (6 Plots × mehrere Fahrzeuge).

### Default bis zur Antwort
Nur das aktive Fahrzeug existiert in der Welt. Es wird am Spawn-Ring ausgeparkt und unter dem Verladeturm beladen.

### Safe work that can continue
Alles bis Phase 6. Der Platz unter dem Verladeturm wird beim Hallenlayout freigehalten.
