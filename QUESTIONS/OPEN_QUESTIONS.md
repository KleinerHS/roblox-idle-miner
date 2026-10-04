# Open Questions

Format und Workflow: `docs/17_QUESTIONS_AND_DECISION_WORKFLOW.md`. IDs fortlaufend (Q-001 …), nie wiederverwenden.

Stand: 2026-10-04

Q-001 bis Q-018 sind beantwortet (siehe `ANSWERED_QUESTIONS.md`, Entscheidungen D-002 bis D-021).

Offene Balancewerte (Level-Anforderungen ab Mine 03) sind als `TODO_BALANCE` markiert.

## Q-019 – Upgrade-Stufen für Lager und Elevator (Phase 4c)

Quelle: docs/06 §15–17, §10–11; docs/09 §29–31 (Werte nicht festgelegt).
Vorschlag (eingebaut als `TODO_BALANCE` in `BalanceConfig`):

| Lager | Kapazität | Kosten | ab Level |
|---|---|---|---|
| Start | 1.000 | – | – |
| Stufe 1 | 2.500 | $3.000 | 5 |
| Stufe 2 | 5.000 | $8.000 | 6 |
| Stufe 3 | 10.000 | $20.000 | 8 |
| Stufe 4 | 25.000 | $50.000 | 10 |

| Elevator | Erz pro Fahrt (alle 10 s) | Kosten | ab Level |
|---|---|---|---|
| Start | 100 | – | – |
| Stufe 1 | 200 | $2.000 | 3 |
| Stufe 2 | 350 | $5.000 | 5 |
| Stufe 3 | 500 | $10.000 | 7 |
| Stufe 4 | 750 | $20.000 | 9 |
| Stufe 5 | 1.000 | $40.000 | 11 |

Frage an Felix: Passen diese Stufen, oder andere Werte? Weitere Stufen kommen später mit den höheren Minen.
