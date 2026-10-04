# 06 – STORAGE AND PRODUCTION

## 1. Zweck dieses Dokuments

Dieses Dokument definiert die Materiallogistik an der Oberfläche:

**Mine → Elevator → Lager → Verarbeitung → Ladebereich → Fahrzeug**

Es beschreibt insbesondere:

- Elevator-Kapazität
- allgemeines Lager
- Materialbestände
- Zwischenpuffer
- Materialhaufen
- Förderbänder
- Schmelzer
- Produktionsblockaden
- Produktionsstatus
- Offline-Produktion
- technische Grundregeln

Konkrete Preise, Produktionszeiten und endgültige Kapazitätswerte werden später in `11_ECONOMY_AND_BALANCE.md` festgelegt.

---

# 2. Grundprinzip der Produktion

Die Produktionskette soll für den Spieler sichtbar und logisch nachvollziehbar sein.

Material darf nicht einfach unsichtbar von einer Mine in Geld umgewandelt werden.

Der grundlegende Weg lautet:

```text
MINE
  ↓
Mining Worker / Drill / Spieler
  ↓
Transport Worker
  ↓
ELEVATOR
  ↓
STORAGE
  ↓
CONVEYOR / PROCESSING
  ↓
SMELTER
  ↓
FINISHED MATERIAL
  ↓
LOADING AREA
  ↓
VEHICLE
  ↓
SELLING
```

Nicht jeder Teil dieser Kette ist von Anfang an verfügbar.

Die Produktionskette wächst mit dem Unternehmen.

---

# 3. Materialsystem

Jede Ressource besitzt eine eindeutige Material-ID.

Beispiele:

```text
Coal
Copper
Tin
Iron
IronBar
Silver
...
```

Materialien dürfen nicht nur anhand sichtbarer Modelle erkannt werden.

Die wirtschaftlichen Bestände werden serverseitig als Daten gespeichert.

Die sichtbaren Erzobjekte sind eine Darstellung dieser Daten.

---

# 4. Rohstoffe und verarbeitete Materialien

Das System unterscheidet mindestens:

## Raw Materials

Direkt aus Minen gewonnene Rohstoffe.

Beispiele:

- Coal
- Copper
- Iron
- Silver

## Processed Materials

Durch Produktionsmaschinen verarbeitete Ressourcen.

Beispiel:

```text
Iron Ore → Iron Bar
```

Verarbeitete Materialien besitzen einen höheren Verkaufswert als ihre Ausgangsmaterialien.

Sowohl Rohstoffe als auch verarbeitete Materialien können verkauft werden.

---

# 5. Materialhaufen

Material wird in der Spielwelt nicht als tausende einzelne Erzstücke dargestellt.

Stattdessen werden Materialhaufen verwendet.

Ein Materialhaufen repräsentiert:

**1 bis 100 Einheiten eines Materials.**

Beispiele:

```text
Coal Pile
Amount = 1
```

und

```text
Coal Pile
Amount = 100
```

dürfen visuell grundsätzlich dieselbe Größe besitzen.

Die tatsächliche Menge wird intern gespeichert.

---

# 6. Warum Materialhaufen verwendet werden

Dieses System verhindert:

- tausende physikalische Erzobjekte
- unnötige Serverlast
- unnötige Netzwerkübertragung
- chaotische Förderbänder
- physikalische Glitches
- schlechte Performance

Die Darstellung soll trotzdem vermitteln, dass echtes Material durch die Firma transportiert wird.

---

# 7. Materialhaufen – Darstellung

Ein Materialhaufen soll das jeweilige Erz visuell eindeutig darstellen.

Beispielsweise:

- Coal = dunkle Kohlebrocken
- Copper = kupferfarbene Brocken
- Iron = passende Eisen-/Erzoptik
- Crystal-Erze = passende Kristallstruktur

Der Spieler muss erkennen können, welches Material gerade transportiert wird.

Nicht ausschließlich Farbe verwenden, wenn Form/Material zusätzliche Lesbarkeit schaffen kann.

---

# 8. Haufenbildung

Wenn Material transportiert werden muss, kann das System verfügbare Mengen zu Haufen zusammenfassen.

Beispiel:

```text
Storage Transfer:
243 Coal

Visualisierung:
100 Coal
100 Coal
43 Coal
```

Es müssen jedoch nicht zwingend drei gleichzeitig physisch simulierte Objekte entstehen.

Die Visualisierung darf intelligent aggregiert werden.

Wirtschaftliche Genauigkeit hat Vorrang vor physikalischer Simulation.

---

# 9. Elevator als Verbindung zwischen Mine und Oberfläche

Der Elevator verbindet die unterirdischen Minen mit dem Oberflächenunternehmen.

Transport Worker liefern Material an den Elevator.

Der Elevator besitzt eine begrenzte Kapazität.

Beispielhafte interne Werte:

```text
CurrentLoad
MaximumCapacity
QueuedMaterial
```

Die konkreten Kapazitätswerte werden später gebalanced.

---

# 10. Elevator-Kapazität

Die Elevator-Kapazität kann über den Laptop verbessert werden.

Die Kapazität bestimmt, wie viel Material gleichzeitig zwischen Mine und Oberfläche transportiert werden kann.

Der Elevator darf nicht als unendlicher Teleport für Produktionsmaterial funktionieren.

---

# 11. Elevator-Upgrade

Elevator-Upgrades werden im Laptop unter dem vorgesehenen Upgrade-Bereich verwaltet.

Mögliche Verbesserungen:

- höhere Kapazität
- später eventuell schnellere Transportzyklen

Die genaue Upgrade-Kurve wird später festgelegt.

Der Spieler soll den Unterschied zwischen einem frühen und einem fortgeschrittenen Elevator spüren.

---

# 12. Elevator und mehrere Minen

Da der Spieler viele Minen besitzen kann, muss das System Material aus mehreren Minen verarbeiten können.

Die Architektur darf nicht davon ausgehen, dass nur eine Mine gleichzeitig produziert.

Material aus unterschiedlichen Minen kann in eine gemeinsame Oberflächenlogistik überführt werden.

Die wirtschaftliche Berechnung muss deterministisch und performant bleiben.

---

# 13. Allgemeines Lager

Das Unternehmen besitzt **ein großes allgemeines Lager**.

Es gibt nicht für jede Erzart ein eigenes Hauptsilo.

Das Lager speichert:

- alle Rohstoffe
- alle unterstützten verarbeiteten Materialien

Der Bestand bleibt intern nach Material getrennt.

Beispiel:

```text
Storage
Coal:       420
Copper:     170
Iron:       90
IronBar:    35

Total:      715 / 1000
```

---

# 14. Anfangskapazität

Das Lager startet mit:

**1.000 Einheiten Gesamtkapazität.**

Diese Kapazität gilt über alle Materialien zusammen.

Beispiel:

```text
Coal: 600
Copper: 300
Iron: 100

Total = 1000 / 1000
```

Das Lager ist dann voll.

---

# 15. Lager-Upgrades

Die Lagerkapazität wird über die **Storage-App auf dem Laptop** verbessert.

Der Spieler baut nicht für jede Kapazitätsstufe ein komplett neues Lager.

Das bestehende Lager bleibt am selben Ort.

Upgrades können dennoch visuelle Veränderungen verursachen.

Beispiele:

- zusätzliche Silo-Segmente
- zusätzliche Rohrleitungen
- größere Displays
- zusätzliche kleine Tanks/Container

---

# 16. Lageranzeige

Am großen Silo befindet sich eine sichtbare Füllstandsanzeige.

Beispiel:

```text
STORAGE

2,438 / 5,000
```

Die Anzeige soll aus normaler Spielentfernung gut lesbar sein.

Sie darf zusätzlich einen visuellen Füllbalken besitzen.

---

# 17. Lagerbestand im Laptop

Im Laptop kann der Spieler detailliert sehen:

- Gesamtkapazität
- belegter Speicher
- freie Kapazität
- Bestand jeder Ressource

Beispiel:

```text
STORAGE
Capacity: 2,438 / 5,000

Coal       1,200
Copper       620
Iron         418
Iron Bar     200
```

---

# 17a. Spieler und Lager (Entscheidung D-004)

- Worker können erst eingestellt werden, wenn das Lager gebaut ist (keine Worker für eine leere Transportkette).
- Der Spieler kann seinen Rucksack im Lager abladen.
- Der Spieler kann Material aus dem Lager in seinen Rucksack nehmen und am Tresen verkaufen (Rucksackkapazität begrenzt die Menge).
- Garage und erstes Fahrzeug werden so gebalanced, dass sie bald nach dem Lager kommen.

---

# 18. Produktionsstopp bei vollem Lager

Wenn das Lager voll ist, darf kein Material einfach verschwinden.

Die vorgelagerte Produktionskette läuft nur weiter, solange Zwischenpuffer Platz besitzen.

Danach entsteht ein Rückstau.

Beispiel:

```text
STORAGE FULL
↓
Elevator kann nicht entladen
↓
Elevator-Puffer wird voll
↓
Transport Worker können nicht vollständig abgeben
↓
Mine-Output wird voll
↓
Drill / Worker stoppt
```

Das ist eine verbindliche Regel.

---

# 19. Keine versteckte Vernichtung

Material darf bei einem Produktionsstau nicht gelöscht werden, nur damit Maschinen weiterlaufen können.

Wenn kein Speicherplatz vorhanden ist:

**Produktion stoppt.**

Ausnahmen dürfen nur bewusst definierte Spielmechaniken sein.

---

# 20. Zwischenpuffer

Wichtige Produktionsschritte dürfen kleine lokale Zwischenpuffer besitzen.

Beispiele:

- Drill Output
- Mining Worker Output
- Elevator Input
- Elevator Output
- Smelter Input
- Smelter Output
- Loading Area

Diese Puffer verhindern, dass die gesamte Fabrik bei jeder kleinen Verzögerung sofort stoppt.

Sie sind jedoch begrenzt.

---

# 21. Produktionsregel für Zwischenpuffer

Jeder Produktionsschritt folgt grundsätzlich:

```text
Kann Output aufgenommen werden?
        ↓
       JA
        ↓
Produktion durchführen
        ↓
Output speichern
```

Wenn:

```text
Output voll
```

dann:

```text
Produktion pausieren
```

---

# 22. Förderbänder

Förderbänder werden später in der Progression freigeschaltet.

Aktuelle Zielgröße:

**ungefähr Mining Level 35**

Der endgültige Unlock-Level wird beim Balancing festgelegt.

Förderbänder automatisieren Materialbewegungen zwischen Oberflächenbereichen.

---

# 23. Feste Förderbandplätze

Förderbänder werden nicht frei wie in einem Sandbox-Bauspiel platziert.

Es gibt feste Anschlusspunkte.

Beispiel:

```text
Storage Output
      ↓
[CONVEYOR SLOT]
      ↓
Smelter Input
```

Der Spieler erhält den Conveyor ins Inventar und kann ihn am vorgesehenen Platz installieren.

---

# 24. Förderband-Platzierung

Wenn ein Conveyor ausgewählt ist:

- gültige Position wird hervorgehoben
- Spieler bestätigt
- Förderband wird automatisch ausgerichtet
- Anschlüsse werden automatisch gesetzt
- System prüft Besitz und Unlock

Die Platzierung muss serverseitig validiert werden.

---

# 25. Förderbandbetrieb

Ein Förderband läuft nur sichtbar, wenn es Material transportiert.

Wenn kein Material bewegt wird:

- Band steht
- unnötige Animationen stoppen

Wenn Material transportiert wird:

- Band bewegt sich
- Materialhaufen werden sichtbar transportiert
- passende Geräusche werden abgespielt

---

# 26. Förderbandkapazität

Förderbänder besitzen eine begrenzte Transportleistung.

Ein Förderband darf nicht automatisch jede beliebige Produktionsmenge bewältigen.

Spätere/bessere Conveyor-Systeme können höhere Transportkapazitäten besitzen.

Die konkreten Werte werden später definiert.

---

# 27. Förderband und Performance

Die sichtbaren Materialhaufen auf Förderbändern sind Visualisierungen.

Die wirtschaftliche Materialbewegung muss nicht vollständig über Roblox-Physik erfolgen.

Empfohlen:

- serverseitige Bestandsberechnung
- kontrollierte visuelle Haufen
- Tween-/Pfad-basierte Bewegung
- kein freies physikalisches Herumrollen

---

# 28. Schmelzer

Der Schmelzer ist eine automatische Verarbeitungsmaschine.

Er wird in der Firmenprogression **nach der Garage** freigeschaltet.

Der Schmelzer besitzt:

- Input
- Verarbeitungsbereich
- Output
- lokale Kapazitäten
- sichtbaren Betriebsstatus

---

# 29. Automatische Rezeptwahl

Der Spieler muss nicht bei jedem Produktionszyklus ein Rezept auswählen.

Der Schmelzer wählt automatisch ein gültiges Rezept anhand des verfügbaren Inputs.

Beispiel:

```text
Iron Ore available
↓
Iron Bar recipe selected automatically
↓
Processing
↓
Iron Bar output
```

---

# 30. Rezeptsystem

Rezepte sollen datengetrieben definiert werden.

Beispiel:

```lua
Recipes = {
    IronBar = {
        Input = {
            Iron = 1,
        },
        Output = {
            IronBar = 1,
        },
        ProcessingTime = 5,
    },
}
```

Alle Zahlen sind Beispiele und keine finalen Balancewerte.

---

# 31. Mehrere mögliche Rohstoffe

Wenn später mehrere verarbeitbare Rohstoffe gleichzeitig im Lager liegen, muss die Rezeptpriorität eindeutig sein.

Sie darf nicht zufällig zwischen Materialien springen.

Die genaue Prioritätslogik wird später festgelegt.

Mögliche Lösung:

- vom Spieler definierte Produktionspriorität
- feste Queue
- automatische faire Reihenfolge

Bis diese Entscheidung getroffen ist, muss die Architektur mehrere Materialien unterstützen.

---

# 32. Schmelzer-Animation

Der Schmelzer zeigt nur während tatsächlicher Produktion aktive Effekte.

Mögliche Effekte:

- Glühen
- Feuer
- Funken
- dezenter Rauch
- Maschinenbewegung
- Schmelzgeräusch

Wenn keine Produktion läuft:

- aktive Effekte reduzieren/stoppen
- Maschinenstatus zeigt Idle

---

# 33. Schmelzer-Status

Mögliche Zustände:

```text
IDLE
RUNNING
WAITING_FOR_INPUT
OUTPUT_FULL
DOWNSTREAM_BLOCKED
DISABLED
```

Visuelles Feedback:

- Grün = arbeitet
- Orange = wartet
- Rot = blockiert

---

# 34. Schmelzer-Input

Der Schmelzer besitzt einen begrenzten Input-Puffer.

Material kann aus dem Lager über das vorgesehene Transportsystem eingespeist werden.

Der Input-Puffer verhindert, dass der gesamte Lagerbestand gleichzeitig physisch in der Maschine dargestellt werden muss.

---

# 35. Schmelzer-Output

Verarbeitetes Material wird in einem begrenzten Output-Puffer gespeichert.

Von dort kann es:

- zurück ins allgemeine Lager
- zum Ladebereich
- über spätere Förderbänder weitertransportiert

werden.

Die genaue Routing-Logik wird bei der finalen Produktionsarchitektur festgelegt.

---

# 36. Wertsteigerung durch Verarbeitung

Verarbeitetes Material muss mehr wert sein als das dafür verbrauchte Rohmaterial.

Beispielprinzip:

```text
Wert(Output) > Wert(Input)
```

Die Differenz belohnt:

- Investition in Produktionsmaschinen
- zusätzliche Logistik
- Wartezeit
- Produktionsmanagement

Die konkrete Gewinnspanne wird später gebalanced.

---

# 37. Rohmaterial bleibt verkaufbar

Der Spieler darf jederzeit entscheiden, Rohmaterial direkt zu verkaufen.

Der Schmelzer ist keine Pflicht, um Materialien verkaufen zu können.

Dadurch bleibt die frühe und aktive Spielweise sinnvoll.

---

# 38. Ladebereich

Der Ladebereich ist die Schnittstelle zwischen Fabrik und Fahrzeug.

Er besitzt einen festen Platz innerhalb der Halle.

Der Spieler fährt mit einem Fahrzeug in den vorgesehenen Bereich.

Daraufhin kann die Fahrzeugbeladung geöffnet werden.

---

# 39. Materialauswahl beim Beladen

Der Spieler entscheidet, welche Materialien in das Fahrzeug geladen werden.

Beispiel:

```text
LOAD VEHICLE

Vehicle Capacity:
340 / 1000

Coal        1,200     [ LOAD ]
Copper        620     [ LOAD ]
Iron Bar      200     [ LOAD ]
```

Die endgültige UI wird in `09_UI_AND_LAPTOP.md` definiert.

---

# 40. Fahrzeugkapazität

Fahrzeuge besitzen ein eigenes Inventar.

Das Fahrzeuglager ist getrennt vom Firmenlager.

Beispiel:

```text
Company Storage
5,000 Capacity

Vehicle
1,000 Capacity
```

Material muss tatsächlich aus dem Firmenbestand entfernt und dem Fahrzeugbestand hinzugefügt werden.

---

# 41. Atomare Transfers

Materialtransfers müssen serverseitig sicher durchgeführt werden.

Beispiel:

```text
Storage: -100 Coal
Vehicle: +100 Coal
```

Diese beiden Änderungen müssen als zusammengehöriger Vorgang behandelt werden.

Es darf nicht möglich sein, durch Abbruch, Lag oder Remote-Spam Material zu duplizieren.

---

# 42. Materialrouting

Das Produktionssystem soll später verschiedene gültige Wege unterstützen.

Beispiele:

### Direkter Verkauf

```text
Mine → Storage → Vehicle → Sell
```

### Verarbeitung

```text
Mine → Storage → Smelter → Storage/Loading → Vehicle → Sell
```

### Spätere Automation

```text
Mine → Elevator → Storage → Conveyor → Smelter → Conveyor → Loading → Vehicle
```

---

# 43. Produktionsstatus

Der Spieler soll erkennen können, warum eine Maschine nicht arbeitet.

Beispiele:

```text
RUNNING
NO INPUT
OUTPUT FULL
STORAGE FULL
WAITING FOR TRANSPORT
```

Diese Information kann:

- direkt an der Maschine
- über kleine Statusanzeigen
- im Laptop

sichtbar sein.

---

# 44. Laptop – Production

Der Laptop erhält einen Production-Bereich.

Dort kann der Spieler später mindestens sehen:

- aktive Produktionsmaschinen
- Status
- Input
- Output
- Produktionsrate
- Blockaden

Beispiel:

```text
SMELTER 01

Status: OUTPUT FULL
Input: 120 Iron
Output: 100 Iron Bars
```

---

# 45. Laptop – Storage

Die Storage-App zeigt:

- Gesamtkapazität
- belegten Speicher
- freien Speicher
- Materialien
- Lager-Upgrades

Dort wird auch die Lagerkapazität verbessert.

---

# 46. Produktionskapazität

`Production Capacity` ist kein universeller Spielerstat.

Kapazitäten gehören jeweils zur Maschine oder zum System.

Beispiele:

- Elevator Capacity
- Storage Capacity
- Drill Output Capacity
- Smelter Input Capacity
- Smelter Output Capacity
- Conveyor Throughput
- Vehicle Capacity

Dadurch bleibt die Produktionskette nachvollziehbar.

---

# 47. Machine Efficiency

Es gibt keinen allgemeinen `Machine Efficiency`-Stat, der sämtliche Maschinen global verbessert.

Bessere Leistung entsteht primär durch:

- bessere Maschinen
- bessere Drills
- bessere Conveyor-Systeme
- größere Kapazitäten
- bessere Logistik

---

# 48. Offline-Produktion

Die Produktionskette läuft offline weiter.

Maximale Offline-Zeit zunächst:

**1 Stunde**

Beim Login wird berechnet, wie viel Produktion in dieser Zeit realistisch möglich gewesen wäre.

Dabei müssen berücksichtigt werden:

- Mining-Produktion
- Worker-Produktion
- Drill-Produktion
- Transportleistung
- Elevator-Kapazität
- Lagerkapazität
- Smelter-Kapazität
- Inputbestände
- Outputkapazitäten
- Produktionsblockaden

---

# 49. Keine naive Offline-Formel

Nicht erlaubt:

```text
OfflineTime × maximale Produktion = Belohnung
```

wenn dadurch Kapazitäten ignoriert werden.

Beispiel:

Wenn das Lager nach 12 Minuten voll gewesen wäre, darf die Offline-Produktion nicht trotzdem für 60 Minuten weiterlaufen.

---

# 50. Offline-Simulation

Die Offline-Berechnung soll effizient erfolgen.

Es müssen keine einzelnen Sekunden simuliert werden.

Stattdessen soll mathematisch bzw. ereignisbasiert berechnet werden:

- welcher Produktionsschritt zuerst voll wird
- wann ein Engpass entsteht
- welche Menge bis dahin produziert werden kann

Das genaue Verfahren wird in `16_TECHNICAL_ARCHITECTURE.md` festgelegt.

---

# 51. Speichern von Produktionsdaten

Gespeichert werden müssen mindestens:

- Lagerkapazität
- Lagerbestand pro Material
- Elevator-Upgrades
- Produktionsmaschinen
- Maschinenzustand soweit erforderlich
- Conveyor-Besitz/Platzierung
- Smelter-Freischaltung
- relevante Maschinen-Upgrades
- Zeitpunkt des letzten Logouts

Kurzlebige visuelle Objekte wie einzelne sichtbare Erz-Haufen müssen nicht persistent gespeichert werden, wenn sie aus den wirtschaftlichen Daten rekonstruiert werden können.

---

# 52. Serverautorität

Der Server kontrolliert:

- Materialbestände
- Lagertransfers
- Elevatortransfers
- Produktionsrezepte
- Schmelzvorgänge
- Conveyor-Transfers
- Fahrzeugbeladung
- Kapazitätsprüfungen

Der Client darf keine Materialmenge selbst festlegen.

---

# 53. Ereignisgesteuerte Architektur

Das Produktionssystem soll möglichst ereignisgesteuert arbeiten.

Beispiele:

```text
MaterialAdded
StorageFull
StorageSpaceAvailable
MachineOutputReady
MachineBlocked
VehicleEnteredLoadingZone
```

Zu vermeiden sind unnötige permanente Schleifen für jedes einzelne Objekt.

---

# 54. Wirtschaftliche Simulation vs. Visualisierung

Eine wichtige technische Regel:

> Die wirtschaftliche Produktion und ihre visuelle Darstellung sind getrennte Systeme.

Der Server besitzt die Wahrheit über:

- Mengen
- Zeiten
- Kapazitäten
- Transfers

Der Client bzw. die Visualisierung zeigt:

- Haufen
- Förderbandbewegung
- Maschinenanimationen
- Effekte

Ein visuelles Objekt darf niemals allein die wirtschaftliche Wahrheit darstellen.

---

# 55. Fehler- und Duplikationsschutz

Besonders kritisch sind Übergänge zwischen:

- Mine → Elevator
- Elevator → Storage
- Storage → Smelter
- Smelter → Storage/Loading
- Storage → Vehicle
- Vehicle → Selling

Jeder Transfer muss verhindern:

- doppelte Gutschrift
- verlorene Ressourcen durch normalen Lag
- negative Bestände
- Überfüllung
- manipulierte Clientwerte

---

# 56. Erweiterbarkeit

Das Produktionssystem muss später zusätzliche Maschinen erlauben.

Mögliche spätere Beispiele:

- Crusher
- Washer
- Refinery
- Advanced Smelter
- Sorter
- Packaging

Diese Systeme sind noch nicht Bestandteil der ersten Kernversion.

Die Architektur soll jedoch nicht ausschließlich auf genau einen Smelter fest verdrahtet sein.

---

# 57. Noch offene Balancingwerte

Später festzulegen:

- Elevator-Basiskapazität
- Elevator-Upgrade-Stufen
- Elevator-Zykluszeit
- Lager-Upgrade-Stufen
- Conveyor-Durchsatz
- Conveyor-Stufen
- Smelter-Inputkapazität
- Smelter-Outputkapazität
- Verarbeitungszeiten
- Rezepte
- Wertsteigerung durch Verarbeitung
- genaue Loading-Geschwindigkeit
- Produktionskosten möglicher späterer Maschinen

Diese Werte müssen zentral konfigurierbar bleiben.

---

# 58. Verbindliche Regeln

1. Es gibt ein gemeinsames Hauptlager.
2. Anfangskapazität des Lagers beträgt 1.000 Einheiten.
3. Lagerkapazität gilt über alle Materialien zusammen.
4. Bestände bleiben intern pro Material getrennt.
5. Lager wird über die Laptop-Storage-App verbessert.
6. Das Silo besitzt eine sichtbare Füllstandsanzeige.
7. Elevator besitzt begrenzte und upgradebare Kapazität.
8. Materialhaufen repräsentieren 1–100 Einheiten.
9. Materialhaufen bleiben grundsätzlich gleich groß.
10. Keine tausenden physikalischen Erzobjekte.
11. Förderbänder werden ungefähr ab Level 35 verfügbar; exakter Wert bleibt offen.
12. Förderbänder besitzen feste Platzierungspunkte.
13. Förderbänder laufen visuell nur beim Transport.
14. Schmelzer kommt nach der Garage.
15. Schmelzer wählt Rezepte grundsätzlich automatisch.
16. Verarbeitetes Material ist wertvoller als sein Rohmaterial.
17. Rohmaterial bleibt direkt verkaufbar.
18. Fahrzeug besitzt ein eigenes Inventar.
19. Spieler entscheidet beim Laden, welche Materialien ins Fahrzeug kommen.
20. Materialtransfers werden serverseitig und duplikationssicher ausgeführt.
21. Jeder Produktionsschritt besitzt reale Kapazitätsgrenzen.
22. Volle nachgelagerte Systeme verursachen Rückstau.
23. Material wird bei Rückstau nicht einfach gelöscht.
24. Produktion stoppt, wenn kein gültiger Speicherplatz mehr vorhanden ist.
25. Offline-Produktion läuft maximal 1 Stunde.
26. Offline-Produktion respektiert sämtliche Kapazitätsgrenzen.
27. Wirtschaftliche Simulation und Visualisierung sind getrennt.
28. Produktionswerte bleiben datengetrieben und leicht anpassbar.
