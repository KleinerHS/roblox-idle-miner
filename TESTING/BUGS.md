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

## BUG-005 – Von Felix platzierte Objekte stehen im Spiel an falscher Stelle

**Severity:** Medium
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.40.0
**Gemeldet:** Felix, 2026-10-18 (Screenshots: 3 Hochregale mitten im Ofen, Geländer schwebt in der Luft)
**Ursache:** 15 Objekte lagen lose im Workspace statt im `HallLayout`. Im Spiel wird nur das HallLayout auf den jeweiligen Plot kopiert (anderer Ort, gedreht); lose Objekte bleiben an der Edit-Position stehen.
**Fix (nur in der Place, kein Code):** Objekte ins HallLayout gehängt, Position unverändert:
- Ofen: `OutputStore.ExtraRack1–3` (Fächer zu `Bay*` umbenannt → reine Deko, keine Kisten), `ZoneFences.ExtraFence1–3`, `Bollards.Bollard4`, `Gantry.DeckRailExtra`
- Lager: `PackingArea.LaneCones2`, `PackingArea.Bollard1–2`
- Garage: `FeedPipeRun1–3` (Rohr-Aufhänger)
Nicht verschoben: eine Rohr-Aufhänger-Gruppe weit außerhalb der Halle (Workspace.Model, Rückfrage an Felix).
**Play-Test 2026-10-19:** alle 12 Objekte auf Plot 1 an der richtigen Stelle (Hochregale in der Lücke, Geländer an der Plattform, hohe Zäune zwischen Lager und Ofen).
**Regression geprüft:** Kopie auf gedrehten Plot im Edit nachgerechnet (Lage zu Nachbarobjekten exakt), Ausgangslager hat weiter genau 16 Kisten-Plätze.
**Likely system:** HallLayout

## BUG-006 – World Preview zeigt die Halle doppelt und verdreht

**Severity:** Low (nur Studio-Vorschau, nicht im Spiel)
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.40.0
**Gemeldet:** Felix, 2026-10-19
**Ursache:** Das HallLayout liegt gerade zum Raster gedreht (LayoutOrigin bei -688/-431, 90°), Plot 1 der Vorschau aber an der echten Plot-Stelle (-727/-420, um 30° anders gedreht). Boden, Markierungen und Hallenboden von Plot 1 überlagerten sich verdreht mit der Halle aus dem Layout.
**Fix:** Das Vorschau-Plugin setzt Plot 1 an die Lage des HallLayouts (`plugin/EditPreview.server.luau`, `layoutDelta`). Im Spiel ändert sich nichts. Plugin neu gebaut; die offene Vorschau habe ich direkt korrigiert.
**Einschränkung:** In der Vorschau ist die Zufahrtsstraße von Plot 1 dadurch leicht gegen die Hauptstraße verdreht (nur Vorschau).
**Likely system:** Studio-Plugin World Preview

## BUG-007 – Räder der Lastzug-Zugmaschinen eiern, Lastzüge sehr langsam

**Severity:** Medium
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.43.0
**Gemeldet:** Felix, 2026-10-20 (Screenshot FH 540)
**Ursache:** (1) Die A-Chassis-Räder wurden an symmetrische Achspositionen aus der Vorlage gesetzt (eine Spurweite, eine Höhe), die Radoptik der Felix-Modelle sitzt aber unsymmetrisch und teils höher/tiefer – die Optik drehte um eine versetzte Achse. (2) Motor-Drehmoment der Lastzug-Abstimmungen (von der alten Hauler-Abstimmung übernommen) zu schwach für Zugmaschine plus drei Anhängerteile.
**Fix:** Jedes Rad sitzt jetzt an X/Z seiner Radoptik, die Optik wird exakt auf die Radmitte geschoben (`VehicleModelBuilder.buildAChassis`); Drehmoment der Tunes `vehicle_hauler` und `vehicle_roadtrain` verdreifacht (Peak 2850, Idle 2070, Redline 1300 – TODO_BALANCE).
**Regression geprüft:** Abstand Radoptik ↔ Radmitte im Spiel bei allen vier Rädern 0; FH 540 beschleunigt in 5 s auf 37 Studs/s (vorher ca. 6). Gilt auch für Pickup, Vans, Box Truck (gleicher Code) – dort war die Optik bereits mittig.
**Likely system:** Fahrzeuge (Optik/Fahrphysik)

## BUG-008 – Lastzug-Zugmaschine federt komplett ein und driftet in Kurven

**Severity:** Medium
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.43.1
**Gemeldet:** Felix, 2026-10-20 („nicht alle Räder liegen auf … muss nicht komplett realistisch sein, nur gut zu fahren“)
**Ursache:** Schwere Auflieger (Dichte 1.2) lasteten über die Sattelkupplung auf der Zugmaschine; dazu 14 t Fahrzeuggewicht bei weicher Hauler-Federung und Hinterachslenkung → Federung auf Anschlag, Räder ohne Bodenkontakt, Drift.
**Fix:** Anhänger leicht (Grundkörper 0,3, Reifen 0,5; `TrailerBuilder`); Tunes `vehicle_hauler`/`vehicle_roadtrain`: Gewicht 8 t, Federn 45/50, Dämpfer 9/10, Schwerpunkt 0,05, keine Hinterachslenkung (Place).
**Regression geprüft:** FH 540 im Play: im Stand alle vier Räder auf Bodenhöhe, Sitz waagerecht; Geradeausfahrt bis 54 Studs/s ohne Schlupf, Räder bleiben am Boden, Sitzhöhe konstant (kein Durchfedern). Bei voller Geschwindigkeit in die Kurve rutscht er noch (dann vorher abbremsen).
**Likely system:** Fahrzeuge (Fahrphysik)
**Nachbesserung 2026-10-20 (Felix: „die Front federt immer noch viel zu viel ein, Physik bitte sehr sehr einfach“):** Federung der Lastzug-Zugmaschinen komplett aus (`Tune.SuspensionEnabled = false`, starre Achsen), Gewichtsverteilung 50/50, Lenkwinkel nimmt mit dem Tempo ab (`SteerDecay` 60 km/h, `MinSteer` 30 %). Getestet: Kabine bleibt beim Anfahren, Bremsen und in Kurven waagerecht (Nicken/Rollen < 0,02), alle Räder am Boden. Bei Höchsttempo lenkt er bewusst nur noch wenig – vor Kurven abbremsen.

## BUG-009 – Lastzug-Zugmaschine „laggy“, Fahrphysik zu kompliziert

**Severity:** Medium
**Status:** Zurückgenommen (Felix 2026-10-20: eigene Physik ohne Lenkeinschlag, Radrotation und Motorsound – zurück zu A-Chassis, mit Werten lösen; siehe BUG-011)
**Build:** 0.43.3
**Gemeldet:** Felix, 2026-10-20 („die ganze Zugmaschine ist laggy, mach es sehr einfach“)
**Ursache:** A-Chassis (Federung, Reifenphysik, Netzwerkbesitz beim Fahrer) plus physikalische Anhänger: viele gekoppelte Teile, Ruckeln und Wegrutschen.
**Fix:** Eigenes, sehr einfaches Fahrsystem nur für die Lastzug-Zugmaschinen (`VehicleModelBuilder.buildSimple`, `SimpleDriveService`): ein Grundkörper gleitet auf vier reibungsfreien Kugeln, Tempo und Richtung werden direkt gesetzt (W/S, A/D aus dem Sitz), Lenkwinkel 40° im Stand, 14° bei Höchsttempo, Server rechnet alles (kein Netzwerkbesitz beim Spieler). Anhänger bleiben physikalisch angekoppelt. Kleine Fahrzeuge fahren weiter mit A-Chassis.
**Regression geprüft:** FH 540 im Play: bleibt immer waagerecht, fährt geradeaus durch Zauntor und Seitenöffnung bis unter den Rüssel („Move forward“-Hinweis erscheint), Testfahrt mit Server-Autopilot (12 Studs/s) durch die Rechtskurve, durchs Rolltor und über den Vorplatz bis zur Straße: alle Anhänger folgen, nichts hängt fest; Rückwärtsfahren geht. Einschränkung: Räder der Zugmaschine drehen sich nicht mit (nur Optik).
**Likely system:** Fahrzeuge (Fahrphysik)

## BUG-010 – FH 540: Hinterräder in der Luft, Front „eingefedert“, Auflieger vorne zu hoch

**Severity:** Medium
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.44.0
**Gemeldet:** Felix, 2026-10-20 (Screenshot)
**Ursache:** Das Creator-Store-Modell des FH 540 steht um 4,4° geneigt. Die Vorlagen wurden in einem waagerechten Rahmen erzeugt, dessen Bodenhöhe aus den unsichtbaren Radteilen kam (die waagerecht sind), während die sichtbaren Räder schräg lagen → Zugmaschine optisch vorne tief/hinten hoch. Beim Geraderichten der Anhänger wurde außerdem um die schräge Modellachse gedreht → Kupplung und Anhängerräder in falscher Höhe, Auflieger mit der Nase nach oben.
**Fix:** Quelle vor dem Vorbereiten waagerecht gestellt (Neigung aus den sichtbaren Rädern der Zugmaschine), Anhänger nur um die senkrechte Achse gerade gedreht; `PrepareVehicleBodies`/`PrepareTrailers` nehmen jetzt die Mitte der sichtbaren Radoptik. Vorlagen `vehicle_hauler` und `vehicle_hauler_Trailers` neu erzeugt.
**Regression geprüft:** Im Play: alle Räder der Zugmaschine auf dem Boden (Abstand −0,08…+0,02), Zugmaschine und alle drei Anhänger waagerecht (Neigung < 0,006); Bild verschickt. Scania unverändert (Neigung dort nur 0,5°).
**Likely system:** Fahrzeuge (Vorlagen)

## BUG-011 – Lastzüge wieder mit A-Chassis, nur über Werte einfach gemacht

**Severity:** Medium
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.44.1
**Gemeldet:** Felix, 2026-10-20 („geh lieber wieder zur alten Physik zurück und fix es da mit Werten“)
**Fix:** Eigenes Fahrsystem (SimpleDriveService, buildSimple) entfernt, Lastzüge fahren wieder mit A-Chassis (Lenkeinschlag, drehende Räder, Motorsound). Werte der Tunes `vehicle_hauler`/`vehicle_roadtrain`: Federung aus (`SuspensionEnabled = false`), 8 t, Gewicht 50/50, Drehmoment ×3, Tempo-Limit 60 km/h, Lenkwinkel nimmt ab 120 km/h-Skala bis auf 45 % ab. Zusammen mit den waagerecht neu erzeugten FH-Vorlagen (BUG-010) stehen alle Räder am Boden.
**Regression geprüft:** FH 540 im Play mit A-Chassis: alle vier Räder auf Bodenhöhe, Kabine beim Anfahren, Fahren und in der Kurve waagerecht (Nicken/Rollen < 0,011), Kurvenfahrt bei 30 Studs/s ohne Rutschen (Schlupf ≤ 3°), Rückwärtsfahren geht.
**Likely system:** Fahrzeuge (Fahrphysik)

## BUG-012 – Lastzug: mittlere Räder der Zugmaschine stehen still, Lenkung rutscht

**Severity:** Medium
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.44.2
**Gemeldet:** Felix, 2026-10-21 („nur die vordersten und hintersten Reifen bewegen sich, er lenkt nicht richtig, er rutscht mehr rum“)
**Ursache:** A-Chassis kennt nur vier Räder; die Radoptik der mittleren Achsen war Teil der starren Karosserie. Hinterradantrieb mit verdreifachtem Drehmoment schob die schwere Kombination über die Vorderräder (Untersteuern, durchdrehende Hinterräder).
**Fix:** Radoptik der mittleren Achsen in den Vorlagen als `WheelExtra{i}` abgetrennt (Place); nach dem Start von A-Chassis bekommt jede eine Nabe an einem Motor-Scharnier am Fahrersitz, `VehicleModelBuilder.updateExtraWheels` dreht sie so schnell wie das echte Rad (10×/s) und lenkt Achsen vor der Mitte mit 60 % des Vorderrad-Einschlags mit (FH 540 hat zwei Lenkachsen). Tunes der Lastzüge: Allradantrieb (50:50), Gewicht 55 % vorne.
**Regression geprüft:** FH 540 im Play: mittlere Räder drehen mit (z. B. echtes Rad −20, Zusatzrad −23 rad/s), zweite Vorderachse lenkt mit (FL −17°, Zusatzachse −10°); Kurve bei ~27 Studs/s mit Gierrate 0,5 rad/s und Schlupf 3–12° statt Wegrutschen.
**Likely system:** Fahrzeuge (Fahrphysik/Optik)

## BUG-013 – Lastzug: Lenkeinschlag zu gering, Bremsen reagieren kaum

**Severity:** Medium
**Status:** Fixed (USER_APPROVED, Felix 2026-10-21)
**Build:** 0.44.4
**Gemeldet:** Felix, 2026-10-21 („der Lenkeinschlag ist zu gering und die Bremsen reagieren gefühlt gar nicht“)
**Ursache:** Tunes der Lastzüge mit kleinem Lenkwinkel und starkem Abbau bei Tempo; Bremskraft für 8 t zu niedrig; die Anhänger rollten völlig frei und schoben die Zugmaschine beim Bremsen weiter.
**Fix:** Tunes `vehicle_hauler`/`vehicle_roadtrain`: SteerInner 50, SteerOuter 45, SteerDecay 200, MinSteer 70; BrakeForce 12000, BrakeAccel 0.4, EBrakeForce 2500, PBrakeForce 6000 (Place, gesichert in `assets/AChassis.rbxm`). Anhängerräder hängen jetzt an Motor-Scharnieren ohne Kraft (frei rollend); beim Bremsen (S gegen die Fahrtrichtung) oder ohne Fahrer hält `TrailerBuilder.setBrake` sie fest.
**Regression geprüft:** FH 540 im Play: von 37 Studs/s auf 0 in ~0,7 s (~13 Studs), Anhängerbremse greift nur beim Bremsen, danach normales Rückwärtsfahren; Wendekreis bei ~15 Studs/s etwa 30–40 Studs; keine Fehler in der Konsole.
**Likely system:** Fahrzeuge (Fahrphysik)

## BUG-014 – High-Roof Van wackelt, Kühlergrill fehlt, Lichter schwarz

**Severity:** Medium
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.46.1
**Gemeldet:** Felix, 2026-10-21 („der High-Roof Van wackelt die ganze Zeit hin und her … außerdem fehlt der Kühlergrill“)
**Ursache:** (1) Tune `vehicle_boxtruck` hatte mit 5,2 t dieselbe Federung/Dämpfung wie der 2,4-t-Cargo-Van → nach jedem Stoß schaukelte er lange seitlich (±1,5°, auch im Stand). (2) Im Modell war die Kühlergrill-Öffnung leer (Blick in den Motorraum). (3) Beim Abdunkeln der Scheiben (D-054) wurden Scheinwerfer-/Rücklichtgläser mit erfasst und schwarz.
**Fix:** Federung vorne/hinten 42/46, Dämpfung 22,5/25 (im Stoßtest schwingt er nach ~0,8 s aus statt ~2 s, höhere Werte wurden instabil). Neuer Kühlergrill (`Body.Grille`, dunkler Rahmen mit Chromstreben). Lichtgläser wieder wie im Original. Dazu auf Felix' Wunsch: Scheiben des Ladebereichs überlackiert (Attribut `PaintedOver`), Markenlogo an der Hecktür entfernt (D-026).
**Regression geprüft:** Geradeausfahrt bis 32 Studs/s ohne Schaukeln (Rollwinkel < 0,5°), Bremsen ruhig; Vorlage per Export/Rücktest gesichert.
**Likely system:** Fahrzeuge (A-Chassis-Tune, Place-Vorlage)

## BUG-015 – Straßen in der Mitte flackern, Spalt im Kreisel

**Severity:** Low
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.51.5
**Gemeldet:** Felix, 2026-10-27 („in der Mitte buggen noch ein paar Straßen übereinander, und im Kreis um die Mitte ist noch ein Spalt in der Straße“)
**Ursache:** (1) Der Kreisel bestand aus 64 Stücken, die sich auf exakt gleicher Höhe überlappten (256 Überlappungen) → Flackern. (2) Speichen lagen nur 0,01 über dem Kreisel. (3) Runde Insel und eckige Kreisel-Stücke schlossen nicht dicht → feiner Spalt am Inselrand; ebenso Promenade aus überlappenden Stücken. (4) Parkplatz-Flächen, Zufahrten, Gehwege, Rasenscheibe und Promenade lagen teils auf gleicher Höhe übereinander.
**Fix:** Kreisel samt Insel ist eine einzige runde Fläche; Promenade sind zwei runde Flächen (Kante, Pflaster) und reicht unter den Kreisel. Feste Höhenstufen (Abstand ≥ 0,01): Wiese = Platzfläche selbst (keine zweite Rasenscheibe), Promenadenkante +0.015, Gehweg +0.03, Pflaster +0.04, Vorfeld +0.05, Kreisel/Parkplatz +0.06, Zufahrten +0.07, Speichen +0.09, Markierungen darüber. Mittellinie der Speichen beginnt hinter dem Zebrastreifen.
**Regression geprüft:** Play: Prüfskript findet keine gleich hohen Überlappungen mehr bei Straßen/Belägen (nur noch weiße Linien untereinander), Strahltest über die ganze Kreisel- und Promenadenfläche ohne Lücke; Ansicht schräg auf den Kreisel ohne Nähte.
**Likely system:** Umgebung (EnvironmentBuilder, CenterBuilder, PlotBuilder)

## BUG-016 – Speichen komisch am Kreisel, Lücke am Platzrand, Gras und eckige Kante am Shop-Parkplatz

**Severity:** Low
**Status:** Fixed (TESTING_REQUIRED)
**Build:** 0.51.7
**Gemeldet:** Felix, 2026-10-27 (3 Screenshots: Straße soll durchgehend in den Kreisel übergehen; Lücke mit Zebrastreifen am Platzrand; Gras und eckige Rundung zwischen Shop-Parkplatz und Promenade, bei allen Läden)
**Ursache:** (1) Speichen endeten als gerades Rechteck im Kreisel, dessen äußere Ecke über die Promenade ragte; keine Ausrundung, Randlinien liefen bis in den Kreisel. (2) Speiche und Gehweg begannen auf dem Platzkreis, die gerade Zufahrt endete ~3 Studs davor → Graslücke; dazu ein Zebrastreifen. (3) Das Vorfeld bestand aus 4-Stud-Streifen (eckige Kante) und war auf 16 Studs begrenzt, daher blieb ein Grasdreieck.
**Fix:** (1) Runde Ausrundungen (Radius 14) zwischen jeder Fahrbahnkante und dem Kreisel, Speiche endet so, dass beide Ecken im Kreisel liegen, Randlinien enden am Beginn der Ausrundung, Mittellinie am Kreisel. (2) Speiche und Gehweg beginnen genau am geraden Ende der Zufahrt (1 bzw. 0,5 Stud Überlappung), Zebrastreifen entfernt. (3) Vorfeld exakt bis zum Promenadenkreis aus Rechtecken und Dreiecken (1,5°-Schritte, keine Begrenzung), Keile entlang der Gehwegkanten.
**Regression geprüft:** Play: Einmündungen rund, keine Pflasterspitzen über der Fahrbahn; Platzrand nahtlos ohne Zebrastreifen; Vorfeld vor Pickaxe- und Drill-Shop rund und ohne Gras; keine Fehler in der Konsole.
**Likely system:** Umgebung (EnvironmentBuilder, CenterBuilder)
