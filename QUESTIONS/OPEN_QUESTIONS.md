# Open Questions

Format und Workflow: `docs/17_QUESTIONS_AND_DECISION_WORKFLOW.md`. IDs fortlaufend (Q-001 …), nie wiederverwenden.

Stand: 2026-10-04

Q-001 bis Q-019 sind beantwortet (siehe `ANSWERED_QUESTIONS.md`, Entscheidungen D-002 bis D-023).

Offene Balancewerte (Level-Anforderungen ab Mine 03) sind als `TODO_BALANCE` markiert.

## Q-020 – Drill-Werte (Phase 5)

Quelle: docs/05 §30–31, §46; docs/10 §27–28, §46 (Werte nicht festgelegt).
Vorschlag (eingebaut als `TODO_BALANCE` in `Definitions/Drills.luau`):

| Drill | Preis | ab Level | Erz/Min | Output-Puffer |
|---|---|---|---|---|
| MK1 | $8.000 | 6 | 60 (5 Erz alle 5 s) | 300 |
| MK2 | $25.000 | 9 | 120 (10 Erz alle 5 s) | 600 |
| MK3 | $75.000 | 12 | 240 (20 Erz alle 5 s) | 1.200 |

Zum Vergleich: Mining-Worker $2.000 + $5/Min Lohn, 30 Erz/Min. Drills haben keinen Lohn.

Frage an Felix: Passen diese Werte, oder andere?

## Q-021 – Garage und Fahrzeugwerte (Phase 6)

Quelle: docs/07 §6–7, §14, §50 (Werte nicht festgelegt, außer Pickup-Kapazität 1.000).
Vorschlag (eingebaut als `TODO_BALANCE`):

| | Preis | ab Level | Kapazität | Top Speed |
|---|---|---|---|---|
| Garage (Bauschritt) | $10.000 | 7 | – | – |
| Utility Pickup | $6.000 | 7 | 1.000 | 55 |
| Utility Van | $20.000 | 10 | 2.500 | 52 |
| Box Truck | $60.000 | 14 | 6.000 | 46 |

Große Fahrzeuge sind langsamer und träger (docs/07 §14). Je Typ besitzt man ein Fahrzeug.

Frage an Felix: Passen diese Werte, oder andere?
