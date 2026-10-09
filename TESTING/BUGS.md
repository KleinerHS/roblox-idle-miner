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

## BUG-002 – Bohrkopf dreht sich um die falsche Achse

**Severity:** Medium
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.16.0
**Gemeldet:** Felix, 2026-10-10 (Screenshot)
**Expected:** Bohrkopf dreht sich um die eigene Längsachse.
**Actual:** Zähne kreisen versetzt um eine falsche Achse.
**Ursache:** Das Bit-Modell hatte den Zylinder `BitCore` als PrimaryPart. Roblox-Zylinder liegen entlang ihrer X-Achse; der Client dreht um die Z-Achse des Pivots → falsche Achse.
**Fix:** PrimaryPart entfernt, `WorldPivot` = Bohrachse (LookVector zur Wand).
**Regression geprüft:** Pivot liegt bei MK1–MK3 auf der Achse, Drehung verschiebt kein Teil radial.
**Likely system:** Drill (Optik)

## BUG-003 – Namensschild des Drills ragt in die Lüftungsgitter

**Severity:** Low
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.16.0
**Gemeldet:** Felix, 2026-10-10 (Screenshot)
**Ursache:** Schriftzug als SurfaceGui auf der Gehäuseseite, auf der auch die Lüftungslamellen saßen.
**Fix:** Lamellen nur noch auf einer Seite und tiefer, eigene Namensschilder (Teile mit Schrift) außen; Tank nach außen versetzt.
**Regression geprüft:** Überschneidungsprüfung aller Drill-Teile.
**Likely system:** Drill (Optik)

## BUG-004 – Werkbank im Machine-Shop ragt in eine Stütze

**Severity:** Low
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.16.0
**Gemeldet:** Felix, 2026-10-10
**Ursache:** Lochwand und Werkbank lagen mittig auf z = 4 und reichten über die Wandstütze bei z = 0.
**Fix:** Werkstatt komplett neu zwischen den Stützen (z 3–16).
**Regression geprüft:** Überschneidungsprüfung des ganzen Machine-Shops.
**Likely system:** Machine-Shop (Optik)
