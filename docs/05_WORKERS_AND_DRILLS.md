# 05 – WORKERS AND DRILLS

## 1. Zweck dieses Dokuments

Dieses Dokument definiert Mitarbeiter, Mining-Slots, Transport-Slots, Drills, Arbeitsabläufe, Gehälter, Navigation und die Zusammenarbeit zwischen manueller und automatisierter Erzförderung.

Konkrete Preise, Produktionsraten und endgültige Gehaltswerte werden später in `11_ECONOMY_AND_BALANCE.md` festgelegt.

---

# 2. Grundidee

Mitarbeiter sind ein zentraler Teil des Übergangs vom einzelnen Miner zum Mining-Unternehmen.

Der Spieler soll früh Mitarbeiter einstellen können.

Mitarbeiter sind:

- sichtbare Arbeiter in der Welt
- keine Pets
- keine reinen Zahlen im Menü
- dauerhaft angestellte Firmenmitarbeiter
- mit laufenden Kosten verbunden

Drills bilden später die maschinelle Weiterentwicklung der Erzförderung.

---

# 3. Mitarbeiterrollen

Für die erste Version werden mindestens zwei Kernrollen benötigt:

## Mining Worker

Fördert Erz an einem festen Mining-Slot.

## Transport Worker

Transportiert gefördertes Material vom Abbaubereich zur vorgesehenen Übergabestelle bzw. zum Elevator.

Weitere spezialisierte Rollen können später ergänzt werden, ohne das Grundsystem neu aufzubauen.

---

# 4. Mitarbeiter-Aussehen

Alle normalen Mitarbeiter verwenden einen einheitlichen Mining-Worker-Stil.

Grundelemente:

- Arbeitskleidung
- Schutzhelm
- Arbeitsschuhe
- Handschuhe
- funktionale Bergbauoptik

Die Rollen dürfen sich durch kleine Details unterscheiden.

Beispiele:

- Mining Worker mit Spitzhacke
- Transport Worker mit Transportausrüstung

Die Figuren sollen zum hochwertigen stylized-Roblox-Look passen.

---

# 5. Mitarbeiter einstellen

Mitarbeiter werden über den Laptop verwaltet.

Der Spieler sieht dort die einzelnen Unternehmensbereiche und verfügbaren Arbeitsplätze.

Beispiel:

```text
EMPLOYEES

Mine 01
Mining Slot 1       [ HIRE ]
Mining Slot 2       [ HIRE ]
Transport Slot 1    [ HIRE ]
Transport Slot 2    [ HIRE ]
```

Ein Mitarbeiter kostet:

1. einen einmaligen Einstellungsbetrag
2. anschließend laufendes Gehalt

Die endgültigen Werte werden später gebalanced.

---

# 6. Gehaltssystem

Mitarbeiter erhalten **jede Minute** Gehalt.

Das Gehalt ist ein echter laufender Unternehmensaufwand.

Ziel:

Mehr Automatisierung soll leistungsfähig sein, aber laufende Kosten verursachen.

Die Gehaltsabrechnung muss serverseitig erfolgen.

---

# 7. Verhalten bei fehlendem Geld

Die konkrete Balance wird später getestet.

Als Grundregel soll ein Mitarbeiter bei fehlender Gehaltszahlung nicht sofort dauerhaft gelöscht werden.

Empfohlenes Verhalten:

- Gehalt kann nicht bezahlt werden
- Mitarbeiter pausiert
- Status wird im Laptop angezeigt
- Produktion/Transport dieses Mitarbeiters stoppt
- sobald wieder ausreichend Geld vorhanden ist, kann der Mitarbeiter reaktiviert werden

Claude soll die genaue Umsetzung konfigurierbar halten.

---

# 8. Feste Mining-Slots

Jede Mine besitzt genau:

**2 Mining-Slots**

Diese Positionen sind fest im Minenlayout definiert.

Die beiden Slots stehen grundsätzlich gerade in Richtung Elevator bzw. zentralem Transportweg.

Jeder Mining-Slot kann enthalten:

- nichts
- Mining Worker
- Drill

Nicht gleichzeitig Worker und Drill.

---

# 9. Feste Transport-Slots

Jede Mine besitzt zusätzlich:

**2 Transport-Slots**

Diese Slots sind für Transport Worker vorgesehen.

Damit sind maximal möglich:

- 2 Mining Worker
- 2 Transport Worker

also maximal:

**4 Worker pro Mine**

wenn beide Mining-Slots mit Workern statt Drills belegt sind.

---

# 10. Spieler und Mining-Slots

Der Spieler selbst darf weiterhin manuell minen.

Die zwei festen Mining-Slots definieren hauptsächlich die automatisierten Arbeitsplätze.

Das manuelle Mining des Spielers soll nicht versehentlich blockiert werden, nur weil beide automatisierten Slots belegt sind.

Der Minenschacht muss deshalb einen klaren Bereich besitzen, in dem der Spieler selbst weiterhin an der Erzader arbeiten kann.

---

# 11. Mining Worker – Arbeitsablauf

Ein Mining Worker:

1. bewegt sich zu seinem festen Arbeitsplatz
2. richtet sich zur Erzader aus
3. spielt Mining-Animation
4. erzeugt nach seinem Arbeitszyklus Erz
5. legt das produzierte Material in den zugehörigen Übergabe-/Pickup-Bereich
6. wiederholt den Vorgang, solange die Produktionskette Material aufnehmen kann

Der Worker zerstört die Wand nicht tatsächlich.

---

# 12. Mining-Worker-Animation

Die Animation soll klar lesbar, aber nicht übertrieben sein.

Ablauf:

- Spitzhacke anheben
- Schlag
- Kontakt mit Wand
- kleiner Staub-/Steineffekt
- kurzer Mining-Sound
- Rückkehr zur Ausgangsposition

Animation und tatsächlicher Produktionszeitpunkt müssen logisch zusammenpassen.

---

# 13. Transport Worker – Arbeitsablauf

Transport Worker bewegen Material zwischen dem Mining-Bereich und dem Elevator.

Grundablauf:

1. Material wird am Mining-/Drill-Ausgabepunkt verfügbar.
2. Transport Worker erkennt verfügbares Material.
3. Worker geht zum Pickup-Punkt.
4. Material wird aufgenommen.
5. Worker folgt seinem vorgesehenen Weg.
6. Worker erreicht den Elevator-/Übergabepunkt.
7. Material wird übergeben.
8. Worker kehrt zurück.

---

# 14. Materialdarstellung beim Transport

Material wird nicht als hunderte einzelne Erzobjekte transportiert.

Stattdessen werden Materialhaufen verwendet.

Ein Haufen repräsentiert:

**1 bis 100 Einheiten**

Die sichtbare Größe des Haufens bleibt grundsätzlich gleich.

Dadurch bleibt das System performant.

Die tatsächliche Menge wird intern gespeichert.

---

# 15. Worker-Transportdarstellung

Transport Worker sollen sichtbar Material transportieren.

Mögliche Darstellung:

- kleiner Erzbehälter
- Schubkarre
- Transportkiste
- geeignete Mining-Transportausrüstung

Die Darstellung muss zur Menge nicht physikalisch exakt skalieren.

Wichtig ist, dass der Spieler visuell erkennt:

> Dieser Mitarbeiter bringt gerade Material zum Elevator.

---

# 16. Feste Worker-Wege

Worker verwenden grundsätzlich definierte Wege.

Jeder Minenschacht besitzt vorbereitete Wegpunkte.

Beispiel:

```text
Mining Slot
    ↓
Pickup Point
    ↓
Path Point A
    ↓
Path Point B
    ↓
Elevator Dropoff
```

Das verhindert unnötig chaotische Navigation.

---

# 17. Alternativroute bei Blockade

Wenn ein vorgesehener Weg blockiert ist, darf ein Worker eine alternative Route suchen.

Priorität:

1. fester Standardweg
2. alternative Navigation bei Blockade
3. sichere Rückkehr auf den Standardweg

Worker dürfen nicht dauerhaft an kleinen Hindernissen hängen bleiben.

---

# 18. Keine Worker-Kollision

Worker sollen sich nicht gegenseitig blockieren.

Die Kollisionsgruppen müssen entsprechend eingerichtet werden.

Worker dürfen insbesondere nicht:

- andere Worker festhalten
- den Spieler einklemmen
- Fahrzeuge blockieren
- den Elevator blockieren

Visuell sollen sie trotzdem glaubwürdig auf dem Boden laufen.

---

# 19. Worker-Zustände

Jeder Worker besitzt einen klaren internen Zustand.

Empfohlene Zustände:

- Idle
- WalkingToWork
- Mining
- WaitingForMaterial
- WalkingToPickup
- Carrying
- WalkingToDropoff
- DroppingOff
- Blocked
- Paused
- Unpaid

Die genaue State Machine soll modular implementiert werden.

---

# 20. Worker-Status im Laptop

Der Spieler kann Mitarbeiter am Laptop verwalten.

Pro Worker sollen mindestens sichtbar sein:

- Rolle
- Arbeitsplatz
- Status
- Gehalt
- Aktiv/Inaktiv

Beispiel:

```text
MINE 04

Mining Slot 1
Worker #12
Status: Working
Salary: $... / min

Transport Slot 1
Worker #18
Status: Carrying Ore
Salary: $... / min
```

---

# 21. Arbeitsplatzbindung

Ein Worker ist einem konkreten Arbeitsplatz zugewiesen.

Beispiele:

- Mine 03 / Mining Slot 1
- Mine 03 / Transport Slot 2

Dadurch weiß das System jederzeit:

- wo der Worker hingehört
- welche Aufgabe er besitzt
- welche Produktion er beeinflusst

---

# 22. Mitarbeiter versetzen

Die Architektur soll es ermöglichen, einen Worker später auf einen anderen gültigen Arbeitsplatz zu versetzen.

Die genaue UI dafür wird später definiert.

Beim Versetzen muss verhindert werden, dass:

- zwei Worker denselben Slot besitzen
- ein Worker gleichzeitig in mehreren Minen arbeitet
- ungültige Slots verwendet werden

---

# 23. Mitarbeiter entlassen

Der Spieler soll einen Mitarbeiter über den Laptop entlassen können.

Beim Entlassen:

- Worker wird sauber aus dem Arbeitsplatz entfernt
- Slot wird frei
- laufendes Gehalt endet
- keine duplizierten Worker bleiben bestehen

Ob ein Teil des Einstellungsbetrags zurückgezahlt wird, wird später im Balancing festgelegt.

---

# 24. Drills

Drills sind automatisierte Mining-Maschinen.

Sie ersetzen einen Mining Worker auf einem Mining-Slot.

Ein Drill benötigt:

- gültigen Mining-Slot
- passende Freischaltung
- Besitz des Spielers

Der Drill produziert automatisch Erz.

---

# 25. Drill-Platzierung

Gekaufte Drills gelangen zunächst ins Inventar.

Wenn der Spieler einen Drill auswählt und sich in einer Mine befindet, werden gültige freie Mining-Slots angezeigt.

Der Spieler kann den Drill nur an diesen vorgesehenen Stellen platzieren.

Nach Auswahl:

- Drill wird automatisch korrekt positioniert
- Drill richtet sich zur Erzader aus
- Slot wird belegt
- Drill wird dem Spieler und der Mine zugeordnet

Kein freies Platzieren.

---

# 26. Drill statt Worker

Ein Mining-Slot kann nur einen der folgenden Zustände besitzen:

```text
EMPTY
WORKER
DRILL
```

Worker und Drill dürfen niemals gleichzeitig denselben Slot verwenden.

Wenn ein Worker auf dem Slot arbeitet, muss der Spieler ihn zunächst entfernen/versetzen, bevor dort ein Drill platziert werden kann.

---

# 27. Drill-Betrieb

Ein aktiver Drill:

1. prüft, ob die Produktionskette Material aufnehmen kann
2. startet seine Bohranimation
3. erzeugt nach definiertem Intervall Erz
4. legt Erz am zugehörigen Output-/Pickup-Punkt ab
5. Transport Worker übernehmen das Material
6. Zyklus wiederholt sich

Der Drill produziert keine Rare Drops.

---

# 28. Drill-Animation

Der Drill arbeitet nur sichtbar, wenn er tatsächlich produziert.

Animation:

- Bohrkopf bewegt/rotiert sich
- Maschine vibriert leicht
- Staub
- kleine Steinpartikel
- Mining-/Motorgeräusch

Die Wand wird nicht tatsächlich zerstört.

Wenn der Drill blockiert ist, stoppt die aktive Bohranimation.

---

# 29. Drill-Zustände

Empfohlene Zustände:

- Idle
- Starting
- Running
- OutputFull
- DownstreamBlocked
- Disabled

Visuelles Statusfeedback:

- Grün = arbeitet
- Orange = wartet
- Rot = blockiert

Die Anzeige soll dezent bleiben.

---

# 30. Drill-Produktion

Jeder Drill besitzt eigene Produktionswerte.

Beispielsweise:

- ProductionRate
- CycleTime
- OutputCapacity

Bessere Drills besitzen bessere Werte.

Es gibt keinen universellen Spielerstat `Machine Efficiency`, der alle Drills beliebig verstärkt.

Fortschritt erfolgt primär durch bessere Maschinen.

---

# 31. Drill-Output

Der Drill besitzt einen begrenzten lokalen Output-/Zwischenspeicher.

Dadurch kann er kurzfristig weiterarbeiten, wenn ein Transport Worker nicht sofort verfügbar ist.

Wenn der lokale Output voll ist:

- Drill stoppt
- Status wird Orange/Rot
- Produktion wird nicht weiter berechnet
- keine Ressourcen verschwinden

Die genaue Kapazität wird später gebalanced.

---

# 32. Transport Worker und Drills

Transport Worker behandeln Drill-Erz genauso wie Worker-Erz.

Ablauf:

```text
Drill
  ↓
Output
  ↓
Transport Worker
  ↓
Elevator
  ↓
Storage
```

Damit bleibt die Transportlogik unabhängig von der Art der Erzgewinnung.

---

# 33. Zwei parallele Mining-Linien

Da jede Mine zwei Mining-Slots besitzt, können zwei Produktionslinien parallel arbeiten.

Beispiele:

### Variante A

```text
Worker 1 ──┐
           ├─ Transport → Elevator
Worker 2 ──┘
```

### Variante B

```text
Drill 1 ───┐
           ├─ Transport → Elevator
Worker 2 ──┘
```

### Variante C

```text
Drill 1 ───┐
           ├─ Transport → Elevator
Drill 2 ───┘
```

---

# 34. Produktionsblockade

Die gesamte Kette muss echte Kapazitätsgrenzen respektieren.

Beispiel:

```text
Storage voll
↓
Elevator kann nicht entladen
↓
Transport kann Material nicht vollständig abgeben
↓
Mine-Output füllt sich
↓
Drill/Worker stoppt
```

Es darf keine unsichtbare unbegrenzte Produktion im Hintergrund stattfinden.

---

# 35. Elevator-Kapazität

Der Elevator besitzt eine begrenzte Transportkapazität.

Diese Kapazität kann später über den Laptop verbessert werden.

Wenn der Elevator voll ist, müssen Transport Worker warten bzw. ihre Materialübergabe entsprechend stoppen.

Die genaue Elevator-Logik wird mit Storage/Production abgestimmt.

---

# 36. Frühe Mitarbeiterprogression

Mitarbeiter sollen früh relevant werden.

Beispielhafter Ablauf:

```text
Spieler minet selbst
↓
erster Transport Worker
↓
erster Mining Worker
↓
zweiter Transport Worker
↓
zweiter Mining Worker
↓
erste Drills
```

Die exakte Kaufreihenfolge hängt vom späteren Balancing ab.

---

# 37. Warum Transport Worker früh kommen

Der Spieler soll früh merken, dass sein Unternehmen wächst.

Ein Transport Worker nimmt dem Spieler das ständige Hin- und Hertragen von Erz ab.

Dadurch entsteht ein klarer qualitativer Fortschritt:

> Der Spieler konzentriert sich auf Mining, während seine Firma bereits erste Logistik übernimmt.

---

# 38. Worker vs. Drill

Worker und Drills sollen unterschiedliche Rollen im Fortschritt besitzen.

## Worker

- früh verfügbar
- günstiger Einstieg
- laufendes Gehalt
- sichtbare menschliche Arbeitskraft
- geringere Produktion

## Drill

- später verfügbar
- höhere Anschaffungskosten
- kein Mitarbeiter auf diesem Mining-Slot notwendig
- höhere planbare Produktion
- kein Rare Drop

Die genaue Wirtschaft wird später gebalanced.

---

# 39. Manuelles Mining bleibt besonders

Auch wenn eine Mine vollständig automatisiert ist, soll der Spieler selbst weiter minen können.

Manuelles Mining besitzt einen entscheidenden Vorteil:

**Rare Drops**

Damit bleibt aktives Mining auch später interessant.

---

# 40. Keine Rare Drops für Automation

Diese Regel ist verbindlich:

- Mining Worker: keine Rare Drops
- Drill: keine Rare Drops
- Transport Worker: keine Rare Drops

Nur der Spieler selbst kann beim manuellen Mining Rare Drops erhalten.

---

# 41. Speicherung

Gespeichert werden müssen mindestens:

- angestellte Mitarbeiter
- Rolle
- Arbeitsplatz
- relevante Worker-Stufe, falls später vorhanden
- gekaufte Drills
- platzierte Drills
- Drill-Typ
- Mine
- Slot

Beim erneuten Beitritt muss das System die Belegung korrekt rekonstruieren.

---

# 42. Serverautorität

Der Server entscheidet über:

- Worker-Einstellung
- Gehaltszahlung
- Worker-Zuweisung
- Worker-Entlassung
- Drill-Besitz
- Drill-Platzierung
- Drill-Produktion
- Erzproduktion
- Slot-Belegung

Der Client darf diese Aktionen nur anfordern.

---

# 43. Performance

Worker und Drills müssen performant umgesetzt werden.

Zu vermeiden:

- permanentes Pathfinding jeden Frame
- ein Heartbeat-Loop pro Worker ohne Notwendigkeit
- physikalische Simulation hunderter Erzstücke
- unnötige Partikeleffekte außerhalb relevanter Distanz
- dauerhaft laufende Animationen bei blockierter Produktion

Empfohlen:

- State Machines
- feste Wegpunkte
- ereignisgesteuerte Logik
- serverseitige aggregierte Produktionsberechnung
- visuelle Simulation getrennt von wirtschaftlicher Berechnung

---

# 44. Offline-Produktion

Offline-Produktion muss nicht jeden Worker physisch simulieren.

Stattdessen kann beim erneuten Login anhand gespeicherter Daten berechnet werden:

- vergangene Offline-Zeit
- Worker-Produktion
- Drill-Produktion
- Transportkapazität
- Elevator-Kapazität
- Lagerkapazität
- Produktionsengpässe

Maximale Offline-Zeit zunächst:

**1 Stunde**

---

# 45. Erweiterbarkeit

Das System soll später zusätzliche Rollen ermöglichen.

Beispiele:

- Smelter Worker
- Warehouse Worker
- Mechanic
- Supervisor

Diese Rollen sind **noch nicht automatisch Teil der ersten Version**.

Die Architektur soll ihre spätere Ergänzung jedoch erlauben.

Claude darf sie nicht eigenständig als notwendige Kernrollen hinzufügen.

---

# 46. Noch offene Balancingwerte

Noch nicht final festgelegt:

- Einstellungsgebühr
- Gehalt pro Minute
- Worker-Produktionsrate
- Worker-Arbeitsgeschwindigkeit
- Worker-Transportkapazität
- Worker-Laufgeschwindigkeit
- Drill-Preise
- Drill-Produktionsraten
- Drill-Outputkapazitäten
- genaue Elevator-Kapazitäten
- Zeitpunkt einzelner Worker-/Drill-Freischaltungen

Alle Werte müssen zentral konfigurierbar sein.

---

# 47. Verbindliche Regeln

1. Mitarbeiter sind früh verfügbar.
2. Mitarbeiter sind sichtbare Arbeiter und keine Pets.
3. Worker kosten einmalig Geld und anschließend Gehalt pro Minute.
4. Jede Mine besitzt 2 Mining-Slots.
5. Jeder Mining-Slot enthält Worker ODER Drill.
6. Jede Mine besitzt 2 Transport-Slots.
7. Maximal 4 Worker pro Mine bei vollständiger Worker-Belegung.
8. Spieler kann weiterhin selbst minen.
9. Worker verwenden feste Arbeitsplätze.
10. Worker verwenden primär feste Wege.
11. Bei Blockaden dürfen alternative Wege verwendet werden.
12. Worker blockieren sich nicht gegenseitig.
13. Drills werden über das Inventar an festen Slots platziert.
14. Drills besitzen sichtbare Bohranimationen.
15. Drills zerstören die Wand nicht.
16. Drills produzieren keine Rare Drops.
17. Worker produzieren keine Rare Drops.
18. Nur manuelles Spieler-Mining kann Rare Drops erzeugen.
19. Material wird performant als Haufen repräsentiert.
20. Ein Haufen kann 1–100 Einheiten repräsentieren und bleibt visuell gleich groß.
21. Produktion stoppt bei vollen nachgelagerten Kapazitäten.
22. Elevator besitzt begrenzte, upgradebare Kapazität.
23. Mitarbeiterverwaltung erfolgt über den Laptop.
24. Wichtige Aktionen werden serverseitig validiert.
25. Offline-Produktion wird berechnet, nicht physisch simuliert.
