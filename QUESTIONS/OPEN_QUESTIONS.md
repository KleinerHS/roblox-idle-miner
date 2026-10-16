# Open Questions

Format und Workflow: `docs/17_QUESTIONS_AND_DECISION_WORKFLOW.md`. IDs fortlaufend (Q-001 …), nie wiederverwenden.

Stand: 2026-10-10

Q-001 bis Q-019 sind beantwortet (siehe `ANSWERED_QUESTIONS.md`, Entscheidungen D-002 bis D-023).

Offene Balancewerte (Level-Anforderungen ab Mine 03) sind als `TODO_BALANCE` markiert.

Q-020, Q-021 und Q-024 sind beantwortet (D-031).

Q-025 ist beantwortet (D-034).

Q-026 ist beantwortet (D-035).

Q-027 ist beantwortet (D-036).

## Q-028 – Neue Fahrzeuge (Phase 12c)

Quelle: docs/07 §6 (mittlerer LKW, großer Mining-Truck; Werte offen). Vorschlag (eingebaut als `TODO_BALANCE`), Preis ≈ 20.000 × Erzwert auf dem Level:

| Fahrzeug | Level | Preis | Kapazität | Top Speed |
|---|---|---|---|---|
| Tipper Truck | 25 | $1M | 12.000 | 44 |
| Mining Hauler | 45 | $78M | 25.000 | 40 |

Hinweis: Der Verladeturm lädt 100 Einheiten/s (D-029) – ein voller Hauler braucht damit gut 4 Minuten.

Frage an Felix: Passen diese Werte als Startwert?

## Q-029 – Zielzeiten bis Level (Phase 14a)

Quelle: docs/11 §41 (Messpunkte vorhanden, Zeiten offen). Die Simulation (`BALANCE/14a_SIMULATION.md`) ergibt mit den aktuellen Werten bei aktivem Dauerspiel: L1→5 24 min, L5→10 44 min, L10→25 2 h, L25→50 1 h 40 min, L50→100 1 h 40 min – Level 100 nach ~6,5 h.

Frage an Felix: Wie lange soll ein Spieler (aktiv gespielt) ungefähr bis Level 10, 25, 50 und 100 brauchen? Vorschlag als Richtung: L10 nach ~1 h, L25 nach ~5 h, L50 nach ~15 h, L100 nach ~40 h.

## Q-030 – Transport-Engpass für Drills (Phase 14a)

Je Mine schaffen 2 Transport-Worker höchstens 5 Erz/s. Drill Mk3 liefert 8,3 Erz/s, Mk4–Mk6 bis 125 Erz/s – sie bringen dadurch nichts mehr.

Frage an Felix: Wie lösen? Vorschläge: (A) Transport-Worker tragen mehr bzw. laufen schneller, wenn sie aufgewertet werden (Upgrade-Stufen), (B) mehr Transport-Slots pro Mine, (C) Förderband im Schacht ersetzt den Transport ab einem bestimmten Level, (D) Drills liefern direkt in den Elevator.

## Q-031 – Späte Level gehen zu schnell (Phase 14a)

Ab Level ~60 dauert ein Level nur ~2 Minuten, weil Einnahmen exponentiell wachsen, der XP-Bedarf aber nur mit Level^1,5 (BalanceConfig.Leveling).

Frage an Felix: Soll ich die XP-Kurve steiler machen (z. B. Exponent 1,5 → 2,2) oder die Erz-XP langsamer steigen lassen (ContentCurve.XPDivisor)? Die genaue Zahl richte ich dann nach deinen Zielzeiten aus Q-029.

## Q-032 – Feste Preise im Spätspiel (Phase 14a)

Worker ($2.000/$1.500), Drill Mk1–Mk3, Lagerkisten und Elevator-Stufen 1–3 kosten immer gleich viel und amortisieren sich ab Level ~60 in unter 1 Minute.

Frage an Felix: Sollen Worker- und Drill-Preise mit der Mine steigen (z. B. Preis × Erzwert-Faktor der Mine), oder bleiben sie bewusst billig und die Herausforderung liegt bei Minen und Ausrüstung?
