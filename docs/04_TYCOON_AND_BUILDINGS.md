# 04 – TYCOON AND BUILDINGS

## 1. Zweck dieses Dokuments

Dieses Dokument definiert das Grundstück, die Firmenhalle, die Gebäude, den baulichen Fortschritt und das Tycoon-Kaufsystem.

Es beschreibt, **wo und in welcher grundlegenden Reihenfolge** die Firma aufgebaut wird.

Maschinenfunktionen, Worker-Logik, Produktionswerte und Fahrzeugtechnik werden in separaten Dokumenten definiert.

---

# 2. Grundprinzip des Grundstücks

Jeder Spieler erhält ein eigenes Mining-Company-Grundstück.

Pro Server sind zunächst **6 Spielergrundstücke** vorgesehen.

Jedes Grundstück:

- besitzt dieselbe Grundgröße
- besitzt dieselbe funktionale Grundstruktur
- ist von Anfang an vollständig für das spätere Endgame eingeplant
- wird während des Spiels nicht vergrößert
- besitzt feste Gebäude- und Maschinenpositionen
- besitzt eine eigene Zufahrt zur zentralen Straße
- ist durch einen niedrigen Zaun erkennbar abgegrenzt

Die Grundstücke dürfen sich durch Firmenfarbe, Firmenname und Firmenlogo unterscheiden.

---

# 3. Kein freies Building-System

Das Spiel verwendet **kein vollständig freies Bausystem**.

Der Spieler kann Gebäude und Maschinen nicht beliebig auf dem Grundstück platzieren.

Stattdessen besitzt das Grundstück fest geplante Positionen.

Vorteile:

- kontrollierter Produktionsfluss
- bessere Performance
- zuverlässige Worker-Wege
- saubere Optik
- keine blockierten Produktionswege
- konsistente Multiplayer-Grundstücke
- einfachere Erweiterbarkeit

Claude darf daraus kein Sandbox-Building-System machen.

---

# 4. Große Fabrikhalle

Auf jedem Grundstück befindet sich von Anfang an eine **sehr große Fabrikhalle**.

Die äußere Grundfläche der Halle bleibt während der gesamten Progression gleich.

Die Halle muss bereits bei der Planung genug Platz für das spätere Endgame besitzen.

Am Anfang ist sie größtenteils leer.

> **Entscheidung D-002:** Beim Start ist nur die Bodenplatte mit Bodenmarkierungen des Endlayouts sichtbar. Außenwände und Dach sind frühe, eigene Bauschritte nach Büro und Elevator.

Der Fortschritt entsteht dadurch, dass der Spieler innerhalb dieser bestehenden Grundstruktur nach und nach:

- Gebäudeteile
- Innenwände
- Funktionsbereiche
- Lager
- Garage
- Produktionsbereiche
- Maschinen
- Förderbänder
- Ladebereich

freischaltet.

Die Halle wird später **nicht durch eine größere Halle ersetzt**.

---

# 5. Visuelles Ziel der Fabrik

Die Fabrik soll sich von einer fast leeren Halle zu einem funktionierenden Mining-Unternehmen entwickeln.

## Anfang

- große, weitgehend leere Halle
- kleine Blechhütte
- Elevator
- wenige nutzbare Bereiche
- kaum Maschinen

## Mittleres Spiel

- Lager
- Garage
- Mitarbeiter
- erste Maschinen
- definierte Produktionswege
- erste Fahrzeuge
- erste Verarbeitung

## Spätes Spiel

- vollständige Produktionslinien
- Förderbänder
- Schmelzer
- große Lagerkapazität
- Ladebereich
- mehrere Maschinen
- sichtbare Mitarbeiter
- große Fahrzeuge

Trotz Endgame-Ausbau muss die Fabrik ordentlich und übersichtlich bleiben.

---

# 6. Blechhütte / Firmenbüro

Die kleine Blechhütte ist das erste Firmengebäude.

Sie kostet:

**0 $**

Beim erstmaligen Aufbau der Hütte muss der Spieler seine Firma einrichten.

Er legt fest:

- Firmenname
- Firmenlogo
- Firmenfarbe

Die Blechhütte bleibt anschließend **dauerhaft bestehen**, auch im Endgame.

Sie wird nicht durch ein luxuriöses Büro ersetzt.

Das ist eine bewusste Designentscheidung:

> Der Spieler soll jederzeit sehen können, wo sein Unternehmen angefangen hat.

---

# 7. Inhalt der Blechhütte

Die Hütte ist bewusst klein und enthält nur das Wichtigste:

- Schreibtisch
- Laptop
- Stuhl
- Bett
- kleines Regal
- einfache Werkzeuge/Dekoration

Das Bett dient zunächst als:

**Spawnpunkt des Spielers.**

Der Laptop ist die zentrale Managementoberfläche des Unternehmens.

Beim Benutzen des Laptops soll die Kamera kurz sauber auf den Laptop zoomen.

---

# 8. Firmenidentität

Vor der Firma befindet sich ein kleines Firmenschild.

Darauf wird mindestens angezeigt:

- Firmenname
- ausgewähltes Firmenlogo

Die Firmenfarbe kann für dezente Akzente verwendet werden.

Sie soll insbesondere bei:

- Firmenschild
- Garage
- ausgewählten UI-Elementen
- Markierungen

auftauchen.

Die gesamte Fabrik darf nicht komplett in der Spielerfarbe eingefärbt werden.

---

# 9. Firmenlogo

Der Spieler wählt beim Firmenstart ein Logo aus einer vorbereiteten Auswahl.

Beispiele für mögliche Motive:

- Spitzhacke
- Berg
- Zahnrad
- Fabrik
- Kristall
- Mining-Symbol

Das System muss erweiterbar sein, damit später weitere Logos hinzugefügt werden können.

---

# 10. Tycoon-Kaufsystem

Der Ausbau der Firma erfolgt über klassische Roblox-Tycoon-Kaufbuttons am Boden.

Die Kaufbuttons müssen:

- sauber aussehen
- klar beschriftet sein
- Preis anzeigen
- bei Bedarf Levelanforderungen anzeigen
- nur für den Grundstückseigentümer nutzbar sein
- serverseitig validiert werden

---

# 11. Immer nur ein Haupt-Kaufbutton

Eine zentrale Designregel lautet:

> **Es soll grundsätzlich immer nur einen aktiven Haupt-Kaufbutton für den nächsten baulichen Fortschritt geben.**

Der Spieler soll nicht von 20 gleichzeitig sichtbaren Kaufbuttons erschlagen werden.

Nach einem erfolgreichen Kauf:

1. Geld wird serverseitig geprüft.
2. Geld wird abgezogen.
3. Bauteil erscheint.
4. alter Kaufbutton verschwindet.
5. nächster Kaufbutton wird aktiviert.

Dadurch bleibt der Ausbau klar geführt.

---

# 12. Einzelne Bauteile werden separat gekauft

Nicht jedes Gebäude erscheint mit einem einzigen Kauf.

Auch einzelne strukturelle Elemente dürfen Teil der Progression sein.

Beispiel:

**Buy Wall 1**
↓
**Buy Wall 2**
↓
**Buy Storage Section**
↓
**Buy Storage Silo**
↓
**Buy Garage Structure**
↓
**Buy Garage Door**

Dadurch entsteht sichtbar Schritt für Schritt eine Firma.

Die Anzahl der Einzelkäufe darf jedoch nicht künstlich aufgebläht werden.

Jeder Kauf soll einen sichtbaren Fortschritt erzeugen.

---

# 13. Sofortiges Bauen

Nach erfolgreichem Kauf erscheint das gekaufte Bauteil sofort.

Es ist keine lange Bauzeit notwendig.

Optional können kurze, saubere Effekte verwendet werden, beispielsweise:

- kurzes Einblenden
- leichte Aufbauanimation
- Partikeleffekt
- kurzer Sound

Der Spieler soll nicht mehrere Minuten auf ein gekauftes Gebäude warten.

---

# 14. Kaufabhängigkeiten

Jeder bauliche Kauf kann Voraussetzungen besitzen.

Mögliche Voraussetzungen:

- vorheriger Bauabschnitt gekauft
- bestimmtes Mining Level erreicht
- ausreichend Geld vorhanden
- vorheriges System freigeschaltet

Die Voraussetzungen müssen datengetrieben definiert werden.

Sie dürfen nicht über viele einzelne Scripts verstreut werden.

---

# 15. Grundlegende Gebäudereihenfolge

Die verbindliche grobe Reihenfolge lautet:

1. Blechhütte / Büro
2. grundlegende Firmenstruktur
3. Lager
4. Garage
5. weitere Produktionsbereiche
6. Schmelzer-Bereich
7. Förderband-/Automatisierungsbereiche
8. weitere Produktionsausbauten

Wichtig:

**Lager kommt vor Garage.**

**Garage kommt vor Schmelzer.**

Diese Reihenfolge darf nicht ohne Änderung der Projektdokumentation umgestellt werden.

---

# 16. Elevator / Minenzugang

Der Minen-Elevator befindet sich direkt auf dem Grundstück.

Er ist ein dauerhaftes Kernelement der Firma.

Optisch soll er wie ein klassischer Bergbau-Aufzug wirken:

- Metall-/Stahlkonstruktion
- Gitterkäfig
- Geländer
- Stahlträger
- Seil-/Aufzugselemente
- dezente Warnmarkierungen

Der Elevator dient funktional als Zugang zu den einzelnen Minenschächten.

---

# 17. Elevator als Teleport-System

Der Elevator muss nicht physisch durch ein riesiges Loch zu Mine 100 fahren.

Stattdessen darf er technisch als Teleport-/Instanzwechsel-System funktionieren.

Der Übergang soll jedoch glaubwürdig dargestellt werden.

Ablauf:

1. Spieler betritt Elevator.
2. Mine-Auswahl wird verwendet.
3. Gitter/Tür schließt.
4. kurzer Elevator-Sound.
5. kurze 1–2 Sekunden Übergangsanimation.
6. leichtes Kamerafeedback.
7. Spieler erscheint in der gewählten Mine.

Der Spieler kann jederzeit von einer Mine zurück zur Oberfläche.

---

# 18. Lagerbereich

Das Lager befindet sich innerhalb der großen Fabrikhalle.

Es ist kein separates riesiges Lagergebäude außerhalb der Halle.

Der Lagerbereich besteht aus einem klar abgegrenzten Teil der Halle.

Zentrales visuelles Element:

**großes Silo / Lagerbehälter**

Das Silo besitzt:

- sichtbare Füllstandsanzeige
- Förderbandanschlüsse
- industrielle Rohr-/Anschlusselemente
- klaren Zugang für die Produktionskette

Beispiel:

**STORAGE**  
**2,438 / 5,000**

---

# 19. Lagerausbau

Die äußere Grundposition des Lagers bleibt gleich.

Die Kapazität wird über den Laptop verbessert.

Dadurch muss nicht für jede Kapazitätsstufe ein neues Gebäude entstehen.

Visuelle Verbesserungen dürfen dennoch mit höheren Lagerstufen verbunden werden.

Beispiele:

- zusätzliche Behälter
- größere Rohrleitungen
- zusätzliche Anzeigen
- kleinere Erweiterungen am Silo

Die Grundfläche bleibt kontrolliert.

---

# 20. Garage

Die Garage befindet sich innerhalb der großen Fabrikhalle.

Sie wird **nach dem Lager** freigeschaltet.

Sie wird **vor dem Schmelzer** gebaut.

Die Garage besitzt:

- klar definierten Fahrzeugbereich
- großes automatisches Glas-Rolltor
- Fahrzeug-Auswahlbereich
- leuchtenden Spawn-Ring
- Firmenfarbakzente

Die Garage soll modern, clean und funktional aussehen.

---

# 21. Garagentor

Das Garagentor ist ein großes automatisches Rolltor mit Glasanteilen.

Es soll:

- automatisch öffnen, wenn ein gültiges Fahrzeug/Spieler sich nähert
- wieder schließen
- nicht unnötig schnell auf- und zufahren
- keine Fahrzeuge einklemmen
- funktional mit der Garage verbunden sein

Der Eingang der Garage liegt entsprechend der geplanten Grundstücksanordnung leicht rechts.

---

# 22. Fahrzeug-Spawnring

In der Garage befindet sich ein leuchtender Ring.

Der Spieler verwendet ihn zur Fahrzeugauswahl.

Nach der Auswahl:

- gewünschtes eigenes Fahrzeug wird gespawnt
- vorhandenes eigenes aktives Fahrzeug wird entsprechend den späteren Regeln behandelt
- Spieler sitzt direkt im Fahrzeug

Es gibt keine Reihe fester Parkplätze für jedes gekaufte Fahrzeug.

---

# 23. Schmelzer-Bereich

Der Schmelzer wird nach der Garage freigeschaltet.

Er erhält einen eigenen klar definierten Produktionsbereich.

Der Bereich muss bereits beim Grundlayout der Halle eingeplant werden.

Er benötigt Platz für:

- Schmelzmaschine
- Input
- Output
- Förderbandanschlüsse
- Worker-/Servicebereich
- visuelle Effekte
- sichere Laufwege

Der genaue Maschinenbetrieb wird in `06_STORAGE_AND_PRODUCTION.md` definiert.

---

# 24. Förderbandbereiche

Förderbänder werden nur an vorgesehenen Punkten platziert.

Beim Kauf bzw. Platzieren eines Förderbands soll der vorgesehene Bereich sichtbar markiert werden.

Beispiel:

**PLACE CONVEYOR HERE**

Der Spieler bestätigt die Platzierung.

Das Förderband wird automatisch:

- korrekt positioniert
- korrekt gedreht
- mit der vorgesehenen Produktionskette verbunden

Kein freies chaotisches Förderbandbauen.

---

# 25. Ladebereich

Die Halle besitzt einen fest eingeplanten Lade-/Verladebereich.

Dieser Bereich verbindet:

- Lager
- spätere Verarbeitung
- Fahrzeuge

Die Straße bzw. Fahrzeugführung muss so geplant sein, dass Fahrzeuge den Bereich problemlos erreichen und wieder verlassen können.

Der Ladebereich muss groß genug für spätere größere Fahrzeuge sein.

---

# 26. Produktionsfluss als Layoutregel

Das Fabriklayout muss den Produktionsfluss visuell unterstützen.

Grundprinzip:

**Elevator → Storage → Processing → Loading → Vehicle**

Die Gebäude und Maschinen dürfen nicht zufällig verteilt werden.

Ein neuer Spieler soll anhand der Anordnung möglichst intuitiv erkennen können, wie Material durch die Firma wandert.

---

# 27. Sichtbarer Fortschritt

Der Ausbau des Grundstücks ist ein zentraler visueller Fortschrittsindikator.

Andere Spieler sollen beim Vorbeifahren erkennen können, wie weit ein Unternehmen ungefähr entwickelt ist.

### Frühes Unternehmen

- leere Halle
- Blechhütte
- Elevator
- wenige Systeme

### Mittleres Unternehmen

- Lager
- Garage
- erste Maschinen
- Fahrzeuge
- Mitarbeiter

### Fortgeschrittenes Unternehmen

- Schmelzer
- Förderbänder
- umfangreiche Produktion
- große Fahrzeuge
- hohe Aktivität

### Endgame-Unternehmen

- vollständige Produktionsanlage
- große Lagerkapazität
- mehrere aktive Systeme
- organisierte Automatisierung

---

# 28. Gebäude-Stil

Der gemeinsame Gebäudestil lautet:

> **Moderne Firma mit klassischen Bergbau- und Industrieelementen.**

Materialien können unter anderem sein:

- Metall
- Beton
- Glas
- Holz
- Stahl
- industrielle Details

Die Gebäude dürfen leichte Gebrauchsspuren besitzen, sollen aber nicht heruntergekommen wirken.

Der Stil soll hochwertig, freundlich und clean bleiben.

---

# 29. Farbgestaltung

Die Firmengebäude verwenden überwiegend neutrale industrielle Farben.

Die individuelle Firmenfarbe wird nur als Akzent eingesetzt.

Beispiele:

- Leuchtstreifen
- UI-Flächen
- Garage
- Firmenschild
- kleine Markierungen

Dadurch bleiben sechs Grundstücke nebeneinander optisch harmonisch.

---

# 30. Türen

Automatische Türen werden dort verwendet, wo sie funktional sinnvoll sind.

Beispiele:

- Garage
- größere Produktionsbereiche
- Bereiche mit Fahrzeugdurchfahrt

Nicht jede kleine Tür benötigt eine automatische Animation.

Automatische Türen müssen zuverlässig funktionieren und dürfen keine Worker oder Fahrzeuge blockieren.

---

# 31. Laufwege

Bereits beim Bau der Halle müssen feste Laufwege eingeplant werden.

Es müssen ausreichend breite Wege existieren für:

- Spieler
- Worker
- Transport Worker
- Maschinenzugang
- Fahrzeuge

Produktionsmaschinen dürfen diese Hauptwege nicht blockieren.

---

# 32. Worker-Wege

Worker verwenden grundsätzlich kontrollierte Laufwege.

Die Gebäudeplanung muss diese Wege berücksichtigen.

Wenn ein vorgesehener Weg kurzfristig blockiert ist, soll die Navigation nach Möglichkeit einen alternativen Weg finden.

Die Architektur darf keine absichtlichen Engstellen erzeugen, an denen Worker regelmäßig hängen bleiben.

---

# 33. Fahrzeugwege

Fahrzeuge benötigen klare Verkehrswege.

Die Zufahrt des Grundstücks führt über eine gerade Straße zur zentralen Map.

Innerhalb des Grundstücks muss genug Platz vorhanden sein für:

- Einfahrt
- Garage
- Ladebereich
- Wenden
- Ausfahrt

Spätere größere Fahrzeuge müssen bereits bei der ursprünglichen Layoutplanung berücksichtigt werden.

---

# 34. Keine Fahrzeugkollision zwischen Spielern

Fahrzeuge unterschiedlicher Spieler sollen sich nicht gegenseitig blockieren können.

Die Gebäudestruktur muss deshalb nicht für absichtliches Spieler-Blocking ausgelegt werden.

Die konkrete Kollisionslogik wird im Fahrzeugdokument definiert.

---

# 35. Zaun

Das Grundstück erhält einen niedrigen Zaun.

Der Zaun soll:

- Grundstücksgrenze sichtbar machen
- nicht wie ein Gefängnis wirken
- Sicht auf die Firma ermöglichen
- zur Bergbau-/Industrieoptik passen

Die Firma soll von außen gut sichtbar bleiben.

---

# 36. Umgebung des Grundstücks

Auch innerhalb und direkt um die Grundstücke soll die Welt nicht steril wirken.

Mögliche Elemente:

- Grasflächen
- einzelne Bäume
- Steine
- kleine Geländedetails
- industrielle Randbereiche

Die Natur darf die funktionalen Firmenbereiche nicht blockieren.

---

# 37. Grundstückszuweisung

Beim Serverbeitritt wird einem Spieler ein verfügbares Grundstück zugewiesen.

Das System muss verhindern:

- zwei Besitzer desselben Grundstücks
- fremde Nutzung von Kaufbuttons
- fremde Nutzung von Managementsystemen
- fremde bauliche Veränderungen

Öffentliche/interaktive Bereiche werden separat definiert.

---

# 38. Persistenz des Tycoon-Fortschritts

Gekaufte Firmenbauteile müssen gespeichert werden.

Beim erneuten Beitritt:

- Spieler erhält ein verfügbares Grundstück
- gespeicherter Firmenfortschritt wird darauf rekonstruiert
- gekaufte Gebäudeteile erscheinen wieder
- Firmenname, Logo und Farbe werden geladen
- relevante Maschinen/Anlagen werden rekonstruiert

Das Grundstück selbst ist serverbezogen, der Firmenfortschritt gehört zum Spieler.

---

# 39. Datengetriebene Baukette

Die Kaufreihenfolge soll zentral definiert werden.

Beispielhafte Struktur:

```lua
BuildSteps = {
    {
        Id = "Office",
        Price = 0,
        Requires = nil,
    },
    {
        Id = "Wall01",
        Price = 100,
        Requires = "Office",
    },
    {
        Id = "StorageSection",
        Price = 1000,
        Requires = "Wall01",
    },
}
```

Die Zahlen sind nur Beispiele.

Claude soll keine Preise aus diesem Beispiel als finale Werte übernehmen.

---

# 40. Bauobjekte und Templates

Gebäude und Bauteile sollen möglichst als wiederverwendbare Templates organisiert werden.

Beispiele:

- WallSegment
- Office
- StorageSilo
- Garage
- GarageDoor
- SmelterArea
- ConveyorPoint
- LoadingArea
- Elevator

Dadurch kann dasselbe Layout zuverlässig auf allen 6 Grundstücken verwendet werden.

---

# 41. Plot-spezifische Referenzen

Scripts dürfen nicht davon ausgehen, dass nur `Plot1` existiert.

Alle Systeme müssen mit jedem der 6 Grundstücke funktionieren.

Referenzen müssen über:

- Plot-ID
- Owner
- Tags
- Attributes
- definierte Objektstrukturen

aufgelöst werden.

Keine unnötigen hart codierten Workspace-Pfade für einen einzelnen Spielerplot.

---

# 42. Keine zufällige Layoutgenerierung

Das Firmenlayout ist bewusst fest geplant.

Claude darf die Produktionsbereiche nicht pro Server zufällig verteilen.

Alle Grundstücke verwenden grundsätzlich dieselbe funktionale Anordnung.

Nur:

- Firmenfarbe
- Firmenname
- Firmenlogo
- Spielerfortschritt

unterscheiden die Unternehmen.

---

# 43. Performance

Die Halle soll hochwertig aussehen, darf aber nicht aus unnötig vielen Einzelteilen bestehen.

Zu vermeiden:

- tausende kleine dekorative Parts
- unnötig komplexe Kollisionen
- permanente Animationen ohne Sichtbarkeit/Nutzen
- extrem detaillierte Meshes ohne LOD-/Performanceplanung
- unnötige Physikobjekte

Dekoration soll mit kontrollierter Geometrie umgesetzt werden.

---

# 44. Erweiterbarkeit

Das Layout muss spätere Inhalte ermöglichen.

Beispielsweise:

- zusätzliche Maschinen
- neue Produktionsstufen
- weitere Lagerfunktionen
- zusätzliche Fahrzeugtypen
- spätere Level bis 1.000

Dafür sollen bei der Planung sinnvolle Erweiterungspunkte vorgesehen werden.

Die bestehende Halle soll jedoch nicht unnötig riesig oder leer wirken.

---

# 45. Was Claude nicht eigenständig ändern darf

Ohne Änderung der Projektdokumentation darf Claude nicht:

- das Grundstück frei vergrößern
- die große Halle durch mehrere zufällige Hallen ersetzen
- die Blechhütte entfernen
- das Büro im Endgame ersetzen
- das Lager hinter die Garage verschieben
- den Schmelzer vor die Garage setzen
- ein freies Building-System einführen
- mehrere gleichzeitig sichtbare Haupt-Kaufbuttons verteilen
- die Gebäude zufällig platzieren
- die Firmenstruktur pro Spieler unterschiedlich generieren
- den Elevator durch ein völlig anderes Minenzugangssystem ersetzen
- feste Produktionswege ohne Grund verändern

---

# 46. Noch offene Detailplanung

Folgende Punkte werden später anhand der finalen Map-Skizze bzw. Roblox-Studio-Umsetzung exakt festgelegt:

- Stud-Abmessungen des Grundstücks
- Stud-Abmessungen der Halle
- exakte Koordinaten der Gebäudebereiche
- exakte Straßenbreite
- exakte Garagengröße
- exakte Silo-Abmessungen
- genaue Anzahl einzelner Wand-Kaufschritte
- Preise der Bauabschnitte
- Mining-Level-Anforderungen einzelner Bauabschnitte
- konkrete 3D-Assets

Diese Werte dürfen zunächst als klar markierte Konfigurationen vorbereitet werden, aber nicht willkürlich als endgültiges Design festgeschrieben werden.

---

# 47. Verbindliche Zusammenfassung

Die wichtigsten Regeln dieses Dokuments:

1. 6 Grundstücke pro Server.
2. Alle Grundstücke besitzen dieselbe feste Grundgröße.
3. Große Fabrikhalle ist von Anfang an vorhanden.
4. Halle wird nicht später vergrößert.
5. Blechhütte bleibt dauerhaft bestehen.
6. Blechhütte ist Büro und enthält den Spawnpunkt.
7. Firmenname, Logo und Farbe werden beim Firmenstart gewählt.
8. Kleines Firmenschild steht vor der Firma.
9. Kein freies Building-System.
10. Gebäude und Maschinen besitzen feste Positionen.
11. Grundsätzlich nur ein aktiver Haupt-Kaufbutton.
12. Gebäudeteile können einzeln gekauft werden.
13. Gekaufte Teile erscheinen sofort.
14. Lager kommt vor Garage.
15. Garage kommt vor Schmelzer.
16. Elevator befindet sich direkt auf dem Grundstück.
17. Lager ist ein Bereich innerhalb der großen Halle.
18. Garage besitzt ein automatisches Glas-Rolltor.
19. Fahrzeugauswahl erfolgt über einen leuchtenden Ring.
20. Förderbänder besitzen feste Platzierungspunkte.
21. Ladebereich ist fest eingeplant.
22. Produktionsfluss bestimmt das Layout.
23. Hauptlaufwege bleiben frei.
24. Große Fahrzeuge werden bereits beim Grundlayout berücksichtigt.
25. Fortschritt muss von außen sichtbar sein.
26. Endgame-Fabrik bleibt clean und organisiert.
27. Tycoon-Fortschritt wird gespeichert.
28. Layout ist datengetrieben und auf alle 6 Plots übertragbar.
