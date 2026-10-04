# 08 – MAP AND WORLD

## 1. Zweck dieses Dokuments

Dieses Dokument definiert die Oberwelt des Spiels.

Die Welt soll wie eine kleine, freundliche Bergbaustadt wirken, die von Natur und Bergen umgeben ist. Sie verbindet die sechs Spielergrundstücke mit den öffentlichen Shops und dem Verkaufsgebäude.

Dieses Dokument definiert vor allem:

- Gesamtstruktur der Map
- 6 Spielerplots
- zentrale Bergbaustadt
- Straßenführung
- Equipment-Shop
- Drill-/Conveyor-Shop
- Fahrzeugshop
- Verkaufsgebäude
- Dekogebäude
- Natur
- Berge
- visuelle Orientierung
- Performance-Regeln

Exakte Stud-Maße und finale Koordinaten werden später anhand einer technischen Top-Down-Grafik festgelegt.

---

# 2. Grundidee der Oberwelt

Die Oberwelt soll keine riesige leere Tycoon-Fläche sein.

Sie soll sich wie ein kleiner zusammenhängender Ort anfühlen:

```text
6 PLAYER COMPANIES
        ↓
ROAD NETWORK
        ↓
SMALL MINING TOWN
        ↓
SHOPS + SELLING
```

Die Umgebung wird vollständig von Bergen eingerahmt.

Dadurch besitzt die Map eine natürliche visuelle Grenze.

---

# 3. Spieleranzahl

Ein Server besitzt zunächst:

**6 Spielergrundstücke**

Jeder Spieler erhält ein eigenes Grundstück für seine Mining Company.

Die sechs Grundstücke besitzen:

- gleiche Größe
- gleiches funktionales Layout
- gleiche Ausbauoptionen
- eigene Firmenidentität

---

# 4. Grundstücksanordnung

Die Grundstücke sollen sinnvoll um den zentralen Bereich verteilt werden.

Sie dürfen nicht wie sechs zufällige Rechtecke auf einer leeren Baseplate wirken.

Ziel:

- kurze Wege zur Stadt
- übersichtliche Orientierung
- genug Abstand zwischen Firmen
- Sicht auf andere Unternehmen
- funktionierende Straßenanbindung

Die finale Position wird in `01_MAP_TOPDOWN.png` verbindlich dargestellt.

---

# 5. Zentrale Bergbaustadt

In der Mitte der Map befindet sich eine kleine Bergbaustadt.

Sie ist kein großer urbaner Stadtkern.

Sie besteht hauptsächlich aus:

- Equipment-Shop
- Drill-/Conveyor-Shop
- Fahrzeugshop
- Verkaufsgebäude
- 2–3 kleinen Dekogebäuden
- Straßen
- Gehwegen
- Naturdetails

Die Stadt soll kompakt und leicht verständlich bleiben.

---

# 6. Keine unnötigen NPCs

Die Oberwelt benötigt zunächst keine herumlaufenden NPC-Bewohner.

Shops funktionieren über:

- Ausstellungsobjekte
- Verkaufstresen
- Interaktionspunkte
- UI

Dadurch bleibt die Welt sauber und performant.

---

# 7. Hauptstraße

Von jedem Grundstück führt eine klare Straße in Richtung des zentralen Bereichs.

Die Straßen sollen echte befahrbare Straßen sein.

Sie müssen breit genug für spätere große LKWs sein.

Zu vermeiden:

- extrem enge Kurven
- unnötige Serpentinen
- kleine Hindernisse mitten auf der Fahrbahn
- Straßen, die nur für das Starterfahrzeug funktionieren

---

# 8. Straßenstruktur

Die Grundidee lautet:

```text
PLAYER PLOT
    │
    │ gerade Zufahrt
    │
    ▼
CENTRAL ROAD / TOWN
```

Innerhalb der Stadt werden Shops und Verkaufsgebäude sauber miteinander verbunden.

Die Straßenführung soll einfach lesbar sein.

---

# 9. Verkaufsgebäude an der Straße

Das Verkaufsgebäude muss direkt an einer Hauptstraße liegen.

Der Spieler soll mit seinem Fahrzeug problemlos:

1. von seiner Firma losfahren
2. die Verkaufsstelle erreichen
3. in die Verkaufszone fahren
4. verkaufen
5. wieder zurück auf die Straße fahren

können.

Das Gebäude darf nicht in einer engen Fußgängerzone versteckt werden.

---

# 10. Verkaufsgebäude

Die Verkaufsstelle ist eines der wichtigsten öffentlichen Gebäude.

Sie besitzt:

- sichtbaren Haupteingang
- Verkaufstresen innen
- Fahrzeug-Verkaufszone außen
- direkte Straßenanbindung
- ausreichend Platz für große Fahrzeuge
- klare Beschilderung

Der Spieler kann dort:

- zu Fuß verkaufen
- aus seinem Fahrzeug verkaufen

---

# 11. Equipment-Shop

Der Equipment-Shop verkauft mindestens:

- Pickaxes
- Backpacks

Im Laden sollen verschiedene Ausrüstungsgegenstände sichtbar auf:

- Tischen
- Wandhalterungen
- Regalen

präsentiert werden.

Der Shop soll dadurch physisch verständlich wirken.

---

# 12. Equipment-Shop – Kaufprinzip

Die sichtbaren Gegenstände dürfen direkt interaktiv wirken.

Bei vielen Gegenständen kann zusätzlich ein sauberes Shop-UI verwendet werden.

Der Spieler soll sofort verstehen:

> Hier kaufe ich persönliche Mining-Ausrüstung.

---

# 13. Drill-/Conveyor-Shop

Der Maschinen-Shop verkauft mindestens:

- Drills
- Conveyors

Später können weitere Produktionsmaschinen ergänzt werden.

Im Shop stehen einige Maschinen als Ausstellungsstücke.

Da langfristig viele Maschinen existieren können, erfolgt der eigentliche Kauf hauptsächlich über ein Verkaufs-UI.

---

# 14. Maschinen-Shop – Optik

Der Shop soll etwas industrieller wirken als der Equipment-Shop.

Mögliche Elemente:

- große Hallentore
- Metallregale
- Drill-Ausstellungsmodell
- Conveyor-Segment
- Werkstattdetails
- technische Beschilderung

Trotzdem bleibt die Gestaltung clean.

---

# 15. Fahrzeugshop

Der Fahrzeugshop ist ein eigenes Gebäude.

Er besitzt:

- Showroom
- Verkaufstresen bzw. Kaufbereich
- einige ausgestellte Fahrzeuge
- Fahrzeug-UI
- ausreichend große Glasflächen/Tore
- direkte Straßenanbindung

Der Spieler soll schon von außen erkennen, dass dort Fahrzeuge verkauft werden.

---

# 16. Fahrzeugshop – Ausstellung

Nicht jedes Fahrzeug muss physisch im Shop stehen.

Einige wichtige Fahrzeuge können ausgestellt werden.

Weitere Fahrzeuge werden über UI mit einer hochwertigen 3D-Vorschau dargestellt.

Das verhindert, dass der Shop mit dutzenden Fahrzeugen überfüllt wird.

---

# 17. Drei Hauptshops

Die Stadt besitzt damit drei klar getrennte Hauptshops:

```text
EQUIPMENT SHOP
Pickaxes + Backpacks

MACHINE SHOP
Drills + Conveyors

VEHICLE SHOP
Cars + Trucks
```

Diese Bereiche dürfen nicht zu einem einzigen großen Universal-Shop zusammengelegt werden.

---

# 18. Keine separate Upgrade-Shop-Filiale

Es gibt keinen allgemeinen Upgrade-Shop in der Stadt.

Firmenupgrades werden hauptsächlich über den Laptop im eigenen Büro verwaltet.

Beispiele:

- Storage Capacity
- Elevator Capacity
- Employee Management
- Unternehmensfortschritt

Dadurch besitzt der Laptop eine klare Funktion.

---

# 19. Dekogebäude

Zusätzlich zu den funktionalen Gebäuden besitzt die Stadt:

**2–3 kleine Gebäude ohne Gameplay-Funktion.**

Sie dienen dazu, die Stadt glaubwürdiger wirken zu lassen.

Mögliche Beispiele:

- kleines Wohnhaus
- alte Werkstatt
- Verwaltungsgebäude
- kleines Lagerhaus

Sie dürfen keine falschen Gameplay-Erwartungen erzeugen.

---

# 20. Beschilderung

Alle wichtigen Gebäude erhalten klare Schilder.

Beispiele:

```text
EQUIPMENT
MACHINES
VEHICLES
SELLING
```

Die Beschriftung soll:

- aus Fahrzeugdistanz lesbar sein
- clean aussehen
- zum Mining-Thema passen

---

# 21. Orientierung

Der Spieler soll sich ohne Minimap grundsätzlich zurechtfinden können.

Dafür werden genutzt:

- klare Straßen
- unterschiedliche Gebäudesilhouetten
- große Schilder
- sichtbare Landmarken
- Berge
- eigene Firmenfarbe am Plot

Eine Minimap kann später ergänzt werden, ist aber nicht Voraussetzung für verständliches Leveldesign.

---

# 22. Natur

Die Umgebung soll freundlich und nicht steril wirken.

Verwendet werden können:

- Gras
- Bäume
- Büsche
- kleine Felsen
- größere Steine
- leichte Bodenunterschiede

Die Map darf nicht nur aus Beton und grauen Flächen bestehen.

---

# 23. Boden

Außerhalb von:

- Straßen
- Fabrikflächen
- Gehwegen
- Stadtflächen

soll der Boden überwiegend natürliche Gras-/Erdstruktur besitzen.

Die Texturen sollen stilisiert und hochwertig sein.

---

# 24. Berge als Map-Grenze

Die gesamte Map wird von Bergen umgeben.

Die Berge erfüllen mehrere Aufgaben:

1. natürliche Weltbegrenzung
2. Mining-Thema verstärken
3. Horizont interessanter machen
4. Außenbereiche der Map verdecken

Sie sollen nicht wie eine perfekte kreisförmige Mauer aussehen.

---

# 25. Berggestaltung

Die Berge sollen unterschiedliche:

- Höhen
- Formen
- Neigungen
- Felsflächen
- Vegetation

besitzen.

Die Silhouette soll organisch wirken.

Einige Bereiche dürfen dichter bewaldet sein.

---

# 26. Unsichtbare Weltgrenze

Zusätzlich zu den Bergen darf eine unsichtbare technische Grenze existieren.

Spieler und Fahrzeuge sollen nicht einfach aus der Map fahren können.

Diese Grenze soll so positioniert sein, dass sie im normalen Gameplay nicht auffällt.

---

# 27. Bäume

Bäume sollen vor allem:

- an Kartenrändern
- zwischen Stadt und Bergen
- neben Straßen
- in freien Grünflächen

stehen.

Sie dürfen:

- Straßen nicht blockieren
- Fahrzeugausfahrten nicht verdecken
- wichtige Shops nicht verstecken
- Worker-Wege auf Spielerplots nicht beeinflussen

---

# 28. Steine und Geländedetails

Kleine Felsen und Steine können die Naturbereiche auflockern.

Sie dürfen nicht zufällig mitten auf Fahrwegen platziert werden.

Dekoration folgt dem Leveldesign und nicht umgekehrt.

---

# 29. Grundstücksumgebung

Auch Spielergrundstücke sollen nicht vollständig von nacktem Beton umgeben sein.

Zwischen industriellen Flächen können existieren:

- kleine Grasstreifen
- einzelne Bäume
- Steine
- natürliche Übergänge

Der eigentliche Produktionsbereich bleibt jedoch sauber und funktional.

---

# 30. Grundstückszaun

Jedes Grundstück erhält einen niedrigen Zaun.

Er zeigt die Firmenfläche an, ohne die Sicht zu blockieren.

Möglicher Stil:

- Metall
- Stahl
- industrielle Pfosten

Keine hohen blickdichten Mauern.

---

# 31. Grundstückszufahrt

Die Grundstückszufahrt besitzt kein unnötiges Hindernis.

Die Straße führt klar in das Grundstück.

Das große automatische Glas-Rolltor der Garage liegt innerhalb der Firmenstruktur und ist nicht das äußere Grundstückstor.

---

# 32. Firmenbeschilderung

Vor jedem Grundstück befindet sich ein kleines Firmenschild.

Es zeigt:

- Firmenname
- Logo

Die Firmenfarbe wird als Akzent verwendet.

Das Schild hilft Spielern, verschiedene Firmen schnell zu unterscheiden.

---

# 33. Unterschiedliche Spielerfarben

Jeder Spieler kann seine eigene Firmenfarbe wählen.

Die Map selbst bleibt farblich neutral genug, damit diese Akzentfarben sichtbar sind.

Firmenfarben sollen nicht die komplette Welt einfärben.

---

# 34. Spawn

Der eigentliche persönliche Spawnpunkt befindet sich in der Blechhütte des Spielergrundstücks.

Beim erstmaligen Start wird der Spieler entsprechend in den Firmenstart geführt.

Ein allgemeiner zentraler Spawn ist nicht das dauerhafte Heimatgebiet des Spielers.

---

# 35. Neue Spieler

Ein neuer Spieler soll schnell verstehen:

1. Das ist mein Grundstück.
2. Dort ist meine Firma.
3. Dort ist mein Elevator.
4. Die Straße führt in die Stadt.
5. In der Stadt befinden sich Shops und Verkauf.

Die Welt muss diese Informationen bereits durch ihr Layout vermitteln.

---

# 36. Sichtweite

Wichtige Gebäude dürfen schon aus mittlerer Entfernung erkennbar sein.

Beispielsweise:

- Vehicle-Shop durch Showroom/Tor
- Selling durch großes Schild
- Machine-Shop durch Industrieoptik
- eigene Fabrikhalle durch Größe

Dadurch entsteht natürliche Orientierung.

---

# 37. Tag/Nacht

Die erste Version muss nicht zwingend einen komplexen Tag-/Nacht-Zyklus besitzen.

Die Beleuchtung soll zunächst so gewählt werden, dass:

- Erze gut lesbar sind
- Straßen gut sichtbar sind
- Gebäude freundlich wirken
- UI und Welt nicht zu dunkel werden

Ein späterer Tag-/Nacht-Zyklus darf vorbereitet werden.

---

# 38. Beleuchtungsstil

Gewünschter Stil:

**stylized Roblox + hochwertig + clean**

Die Beleuchtung soll:

- angenehm
- leicht warm
- nicht übermäßig gesättigt
- nicht extrem realistisch
- nicht billig-cartoonhaft

wirken.

---

# 39. Öffentliche Gebäude – Stil

Die Stadt darf einen leicht traditionellen Mining-Town-Charakter besitzen.

Mögliche Materialien:

- Holz
- Metall
- Ziegel
- Beton
- Glas

Die Shops sollen moderner und gepflegter wirken als eine verlassene Westernstadt.

---

# 40. Spielerfabrik vs. Stadt

Die Spielerfabrik darf moderner und industrieller wirken als die kleine Stadt.

Dadurch entsteht ein visueller Kontrast:

```text
MINING TOWN
klein + freundlich + traditionell

PLAYER COMPANY
modern + industriell + wachsend
```

---

# 41. Keine riesige leere Mitte

Die Stadtmitte darf nicht aus einer riesigen ungenutzten Asphaltfläche bestehen.

Straßen, Gebäude, Grünflächen und kleine Details sollen den Bereich kompakt strukturieren.

Gleichzeitig muss genug Platz für Fahrzeuge bleiben.

---

# 42. Große Fahrzeuge

Die komplette Oberwelt muss von Anfang an für spätere große LKWs geplant werden.

Das betrifft:

- Straßenbreite
- Kurvenradius
- Verkaufszone
- Shopzufahrten
- Grundstückszufahrten
- Kreuzungen

Die Welt darf nicht später wegen größerer Fahrzeuge komplett umgebaut werden müssen.

---

# 43. Verkehrsfluss

Da maximal sechs Spieler gleichzeitig fahren können, braucht das Spiel kein komplexes Verkehrssystem.

Es gibt:

- keine Ampelpflicht
- keinen NPC-Verkehr
- keine Verkehrs-NPCs

Straßen sollen hauptsächlich der verständlichen Verbindung der Orte dienen.

---

# 44. Fahrzeugkollisionen

Fahrzeuge verschiedener Spieler blockieren sich nicht gegenseitig.

Die Straßen müssen trotzdem visuell ausreichend breit und glaubwürdig sein.

---

# 45. Shop-Interaktion

Alle Shops verwenden ein konsistentes Interaktionsprinzip.

Beispielsweise:

1. Spieler nähert sich Verkaufsbereich.
2. Interaktionshinweis erscheint.
3. Shop-UI öffnet sich.
4. Gegenstand wird betrachtet.
5. Server prüft Kauf.
6. Gegenstand wird dem Spieler gutgeschrieben.

Die genaue UI wird in `09_UI_AND_LAPTOP.md` festgelegt.

---

# 46. Keine übermäßigen Interaktionssymbole

Die Stadt soll nicht überall mit schwebenden Icons vollgestellt sein.

Interaktionshinweise erscheinen nur in sinnvoller Nähe.

Wichtige Orte werden primär durch:

- Gebäude
- Schilder
- Auslagen

kommuniziert.

---

# 47. Audio der Welt

Die Oberwelt darf dezente Ambient-Geräusche besitzen.

Beispiele:

- Wind
- Vögel
- entfernte Industrie
- leichte Stadtatmosphäre

In Firmenbereichen können Maschinenklänge hinzukommen.

Audio darf nicht permanent laut oder überladen sein.

---

# 48. Map-Performance

Die Map soll visuell hochwertig, aber Roblox-tauglich bleiben.

Zu vermeiden:

- extrem dichte Wälder aus tausenden Parts
- unnötig hochauflösende Meshes überall
- permanente Partikeleffekte
- unnötige Physikobjekte
- Interiors für komplett unzugängliche Dekogebäude

---

# 49. Streaming

Die Architektur soll mit Roblox `StreamingEnabled` kompatibel sein.

Besonders bei:

- Minen
- Spielerplots
- Stadt
- Bergen

dürfen Scripts nicht voraussetzen, dass jedes visuelle Objekt der gesamten Welt jederzeit clientseitig geladen ist.

---

# 50. Map-Ordnerstruktur

Empfohlene grobe Workspace-Struktur:

```text
Workspace
└── World
    ├── PlayerPlots
    │   ├── Plot01
    │   ├── Plot02
    │   ├── Plot03
    │   ├── Plot04
    │   ├── Plot05
    │   └── Plot06
    │
    ├── Town
    │   ├── EquipmentShop
    │   ├── MachineShop
    │   ├── VehicleShop
    │   ├── SellingBuilding
    │   └── DecorationBuildings
    │
    ├── Roads
    ├── Nature
    ├── Mountains
    └── WorldBounds
```

Dies ist eine Architekturvorgabe, keine Pflicht für exakt dieselben Objektnamen, falls die spätere technische Struktur einen besseren konsistenten Aufbau erfordert.

---

# 51. Technische Top-Down-Referenz

Für die endgültige Umsetzung soll später folgende Datei erstellt werden:

```text
VISUAL_REFERENCES/01_MAP_TOPDOWN.png
```

Diese Grafik wird die verbindliche räumliche Referenz für die Oberwelt.

Sie soll mindestens markieren:

- alle 6 Plots
- Stadt
- Equipment-Shop
- Machine-Shop
- Vehicle-Shop
- Selling Building
- Dekogebäude
- Hauptstraßen
- Grundstückszufahrten
- Berggrenze

---

# 52. Plot-Referenz

Zusätzlich wird später erstellt:

```text
VISUAL_REFERENCES/02_PLAYER_PLOT_TOPDOWN.png
```

Diese Grafik definiert das einzelne Spielergrundstück genauer.

Das Map-Dokument darf deshalb keine willkürlichen exakten Koordinaten erfinden, bevor diese Referenz finalisiert wurde.

---

# 53. Concept-Referenz

Die bereits erstellte allgemeine Konzeptgrafik wird gespeichert als:

```text
VISUAL_REFERENCES/00_VISUAL_OVERVIEW_CONCEPT.png
```

Sie ist:

**INSPIRATION / CONCEPT ONLY**

Sie ist keine pixelgenaue oder maßstabsgetreue Bauanweisung.

Wenn spätere technische Top-Down-Grafiken davon abweichen, haben die technischen Grafiken Vorrang.

---

# 54. Priorität von Referenzen

Für Claude gilt später folgende Reihenfolge:

```text
1. technische Projektdokumentation
2. finale technische Layoutgrafiken
3. finale spezialisierte Concept-Art
4. 00_VISUAL_OVERVIEW_CONCEPT.png
```

Eine allgemeine Concept-Grafik darf keine fest dokumentierte Gameplay-Regel überschreiben.

---

# 55. Keine eigenmächtigen Layoutänderungen

Claude darf ohne dokumentierte Änderung nicht:

- Anzahl der Plots ändern
- alle Shops zusammenlegen
- Selling Building entfernen
- Verkaufsstelle weit von der Straße wegsetzen
- zusätzliche Pflichtshops erfinden
- Stadt durch eine riesige Metropole ersetzen
- Berge als Mapgrenze entfernen
- Straßen durch reine Teleporter ersetzen
- NPC-Verkehr hinzufügen
- Grundstücke zufällig generieren
- Spielerfirmen unterschiedlich groß machen

---

# 56. Erweiterbarkeit

Die Map soll später zusätzliche Inhalte aufnehmen können.

Mögliche spätere Erweiterungen:

- weiterer Shop
- Event-Bereich
- Trading-Bereich
- zusätzlicher Verkaufsort
- neue Bergregion
- besondere Endgame-Zone

Dafür können kontrollierte freie Flächen vorgesehen werden.

Die Startmap darf deshalb trotzdem nicht unfertig oder leer wirken.

---

# 57. Noch offene Werte

Später anhand der Top-Down-Planung festzulegen:

- gesamte Map-Größe in Studs
- Plot-Größe
- Plot-Abstände
- Straßenbreite
- Kreuzungsgrößen
- Stadtgröße
- genaue Shopgrößen
- Verkaufszone
- Bergpositionen
- exakte Spawnpositionen
- finale Beleuchtung
- genaue Vegetationsdichte

Diese Werte dürfen nicht willkürlich als endgültig festgeschrieben werden.

---

# 58. Verbindliche Regeln

1. Server besitzt 6 Spielerplots.
2. Alle Plots besitzen dieselbe Größe und funktionale Struktur.
3. In der Mitte befindet sich eine kleine Bergbaustadt.
4. Stadt besitzt drei getrennte Shops: Equipment, Machines und Vehicles.
5. Equipment-Shop verkauft Pickaxes und Backpacks.
6. Machine-Shop verkauft Drills und Conveyors.
7. Vehicle-Shop verkauft Fahrzeuge.
8. Es gibt keinen separaten allgemeinen Upgrade-Shop.
9. Firmenupgrades werden hauptsächlich am Laptop verwaltet.
10. Selling Building ist ein separates öffentliches Gebäude.
11. Selling Building liegt direkt an einer befahrbaren Hauptstraße.
12. Verkauf ist zu Fuß und aus Fahrzeugen möglich.
13. Stadt besitzt zusätzlich 2–3 Dekogebäude.
14. Keine unnötigen Stadt-NPCs.
15. Jeder Plot besitzt eine klare Straßenverbindung zur Stadt.
16. Straßen werden für spätere große LKWs ausgelegt.
17. Umgebung besitzt Gras, Bäume, Felsen und natürliche Details.
18. Die gesamte Map wird optisch von Bergen umgeben.
19. Berge bilden eine natürliche Weltgrenze.
20. Grundstücke besitzen niedrige Zäune.
21. Eigene Firmenfarbe wird nur als Akzent eingesetzt.
22. Spieler spawnt langfristig in seiner Blechhütte.
23. Wichtige Gebäude müssen visuell klar unterscheidbar sein.
24. Welt bleibt clean und leicht verständlich.
25. Keine riesigen ungenutzten Flächen.
26. Keine unnötig komplexe Verkehrssimulation.
27. Fahrzeuge anderer Spieler blockieren sich nicht.
28. Map muss mit StreamingEnabled kompatibel geplant werden.
29. `00_VISUAL_OVERVIEW_CONCEPT.png` ist nur eine Konzeptreferenz.
30. `01_MAP_TOPDOWN.png` wird später die verbindliche räumliche Map-Referenz.
