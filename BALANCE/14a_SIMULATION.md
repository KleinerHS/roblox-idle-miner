# Phase 14a – Balance-Simulation (Stand 2026-10-17)

Werkzeug: `tools/BalanceSim.luau` (läuft in Studio, nutzt die echten Spieldaten aus `ReplicatedStorage.Shared`).
Es wurden keine Spielwerte geändert. Dieser Bericht ist die Grundlage für deine Entscheidungen (Q-029 bis Q-032).

## Modell

- Ein Spieler spielt **aktiv ohne Pause** von Level 1 bis 100.
- Er kauft immer das Angebot mit der besten Kombination aus Wartezeit und Amortisation (Preis ÷ zusätzlicher Gewinn pro Minute, docs/11 §23). Voraussetzungen (Gebäude, Fahrzeug, Lagerkiste) kauft er mit.
- Manuell: Er baut in der besten freien Mine ab. Pro Rucksackfüllung kommen **40 s** Verkaufsweg dazu (Laufen, Förderkorb, Tresen) – Annahme.
- Automation: Worker/Drill → 2 Transport-Worker → Elevator → Lager → Fahrzeug. Eine Fahrzeugfahrt dauert **60 s** plus Beladen (100/s) – Annahme.
- Nicht simuliert: Schmelzer, Förderbänder, Prestige, Rare Drops, Handel, Offline-Zeit.

## Ergebnis: Zeit bis Level (aktive Spielzeit)

| Level | Zeit gesamt | Abschnitt |
|---|---|---|
| 5 | 0 h 24 min | L1→5: 24 min |
| 10 | 1 h 08 min | L5→10: 44 min |
| 25 | 3 h 06 min | L10→25: 1 h 58 min |
| 50 | 4 h 46 min | L25→50: 1 h 40 min |
| 100 | **6 h 24 min** | L50→100: 1 h 38 min |

Am Ende verdient der Spieler etwa **$3,7 Mio. pro Minute** (je etwa zur Hälfte manuell und automatisch) und bekommt ~52.600 XP pro Minute.

## Befunde

1. **Level 100 in gut 6 Stunden aktiver Spielzeit.** Für ein Spiel, das langfristig motivieren soll, ist das sehr schnell (docs/11 §41: Zielzeiten noch offen → Q-029).
2. **Späte Level gehen schneller als mittlere.** L50→100 dauert so lange wie L25→50. Grund: Einnahmen und XP wachsen mit jeder Mine um ×1,35–1,6, der XP-Bedarf nur mit Level^1,5. Ab etwa Level 60 kostet ein Level nur noch ~2 Minuten.
3. **Transport ist der Flaschenhals der Automation.** 2 Transport-Worker schaffen höchstens 2 × 50 Erz / 20 s = **5 Erz/s pro Mine**. Ein Drill Mk3 liefert schon 8,3 Erz/s, Mk4–Mk6 (bis 125 Erz/s) bringen deshalb **gar nichts mehr** und wurden nie gekauft (→ Q-030).
4. **Feste Preise werden spät zu billig.** Worker ($2.000/$1.500), Drill Mk1–Mk3, Lagerkisten und die ersten Elevator-Stufen amortisieren sich ab Level ~60 in unter 1 Minute. Teure Spätinhalte (Drill Mk4–Mk6, Elevator 2.500+, Hauler, Lagerkisten > 24) werden nie gebraucht.
5. **Manuelles Abbauen bleibt bis zum Ende gleich stark wie die ganze Automation.** Das passt zum Grundsatz „aktives Spielen lohnt sich immer“ (docs/03 §16), aber die Automation könnte mehr Gewicht bekommen.
6. **Frühphase (Level 1–10) wirkt gesund:** erste Käufe nach 4–20 Minuten, Amortisation 20–40 Minuten.

## Kaufreihenfolge (Auszug)

- 0:04 Iron Pickaxe · 0:21 Reinforced Backpack · 0:46 Mine 03 · 0:59 Steel Pickaxe
- 3:03 erste Automation (Drill Mk2 in Mine 07) mit Lager, Garage und Pickup
- 4:30 Van · 4:59 Box Truck · danach je neuer Mine sofort 2 Worker → 2 Drills Mk1 → Mk2/Mk3
- Elevator nur bis Stufe 3 (500), Fahrzeug nur bis Box Truck

Vollständiges Protokoll: `tools/BalanceSim.luau` in Studio ausführen.
