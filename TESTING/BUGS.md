# Bugs

Format: `docs/18_TESTING_AND_QUALITY.md`, Abschnitt 16. IDs fortlaufend (BUG-001 …).

## BUG-001 – Minen-Käfig lässt sich nicht verlassen

**Severity:** High
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.3.0 (Phase 2b)
**Gemeldet:** Felix, 2026-10-04
**Steps:**
1. Mit dem Elevator in Mine 01 fahren.
2. Aus dem Käfig nach vorne laufen.

**Expected:** Spieler läuft über die Treppe in den Raum.
**Actual:** Spieler bleibt an der Käfig-Vorderseite hängen.
**Ursache:** Im Minen-Käfig waren drei gelb-schwarze Querstreben (`Stripe1–3`) quer über die Vorderseite gebaut, die unterste auf Kopfhöhe. Sie blockierten den Ausgang.
**Fix:** Neuer gemeinsamer Förderkorb (`src/server/World/ElevatorCageBuilder.luau`) mit Schiebegitter-Tor statt fester Streben. Tor ist im Ruhezustand offen, schließt bei Abfahrt und öffnet bei Ankunft (`ElevatorService`).
**Regression geprüft:** Rein- und Rauslaufen in beiden Körben (Oberfläche und Mine), Fahrt in beide Richtungen, Tor öffnet nach der Fahrt wieder.
**Likely system:** Mine Shaft / Elevator
