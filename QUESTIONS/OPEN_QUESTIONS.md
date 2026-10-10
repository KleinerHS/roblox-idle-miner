# Open Questions

Format und Workflow: `docs/17_QUESTIONS_AND_DECISION_WORKFLOW.md`. IDs fortlaufend (Q-001 …), nie wiederverwenden.

Stand: 2026-10-10

Q-001 bis Q-019 sind beantwortet (siehe `ANSWERED_QUESTIONS.md`, Entscheidungen D-002 bis D-023).

Offene Balancewerte (Level-Anforderungen ab Mine 03) sind als `TODO_BALANCE` markiert.

Q-020, Q-021 und Q-024 sind beantwortet (D-031).

Q-025 ist beantwortet (D-034).

## Q-026 – Werte für Minen 09–100, Erze und Barren (Phase 12a)

Quelle: docs/03 §12–13 (ungefähr Verdopplung, aber keine absurden Zahlen), docs/02 §30 (Mine 100 und Level 100 als Endziel). Formel nicht festgelegt.
Vorschlag (eingebaut als Kurve mit `TODO_BALANCE` in `BalanceConfig.ContentCurve`):

- Erzwert: ab Lead × 1,6 je Erz bis Platinum, danach × 1,35 (gerundet auf 2 Stellen)
- Erz-XP: wächst langsam mit der Level-Kurve (Diamond 50 XP)
- Barren: 2 Erz × 1,4 Wert, × 1,25 XP
- Minen-Level: gleichmäßig von Mine 08 (Level 16) bis Mine 100 (Level 100)
- Minenpreis ab Mine 09: Erzwert × 4.500, zweite Mine derselben Erzart × 1,25 (Mine 03–08 bleibt D-019)

| Erz | Wert | XP | Minen | Level | Preis |
|---|---|---|---|---|---|
| Lead | 8 | 5 | 09/10 | 17/18 | $36K / $45K |
| Chromium | 84 | 10 | 19/20 | 26/27 | $380K / $470K |
| Platinum | 880 | 15 | 29/30 | 35/36 | $4M / $5M |
| Emerald | 18K | 25 | 49/50 | 53/54 | $81M / $100M |
| Luminous Crystal | 360K | 35 | 69/70 | 72/73 | $1,6B / $2B |
| Diamond | 32M | 50 | 99/100 | 99/100 | $140B / $180B |

Frage an Felix: Passt diese Richtung als Startwert für die Balance-Phase, oder andere Kurve?
