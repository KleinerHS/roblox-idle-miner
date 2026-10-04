# Decision Log

IDs fortlaufend (D-001 …). Jede Entscheidung verweist auf ihre Quellfrage und die betroffenen Systeme.

## D-001 – Projektstruktur mit Rojo

**Source Question:** – (Setup)
**Decision:** Code liegt im GitHub-Repo `KleinerHS/roblox-idle-miner` und wird per Rojo nach Roblox Studio synchronisiert. Spezifikation unter `docs/`, Visual References unter `docs/references/`.
**Affected systems:** alle

## D-002 – Halle wird ab Bodenplatte aufgebaut

**Source Question:** Q-001
**Decision:** Beim Start ist nur die Bodenplatte mit Bodenmarkierungen des Endlayouts sichtbar. Außenwände und Dach sind frühe, eigene Tycoon-Bauschritte nach Büro und Elevator.
**Affected systems:** Tycoon, Plot, BuildSteps
**Spec updated:** `docs/04` §4

## D-003 – Startgeld $800, Elevator kostet $200

**Source Question:** Q-002
**Decision:** Neuer Spieler startet mit $800. Elevator ist der Bauschritt nach dem Büro ($0) und kostet $200.
**Affected systems:** Economy, Tycoon, Default Data
**Spec updated:** `docs/02` §4, `docs/12` §32

## D-004 – Worker erst nach Lager, Spieler kann Lager per Rucksack nutzen

**Source Question:** Q-003
**Decision:** Worker sind erst einstellbar, wenn das Lager gebaut ist. Spieler kann Rucksack im Lager abladen und Material aus dem Lager in den Rucksack nehmen, um es am Tresen zu verkaufen. Garage/erstes Fahrzeug werden so gebalanced, dass sie bald nach dem Lager kommen.
**Affected systems:** Worker, Storage, Selling, Progression, Build Plan (Phase 3/4)
**Spec updated:** `docs/06` §17a
