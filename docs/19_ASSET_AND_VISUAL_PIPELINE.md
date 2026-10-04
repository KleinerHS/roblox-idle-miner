# 19 – ASSET AND VISUAL PIPELINE

## 1. Ziel

Grafik soll konsistent wirken und nicht wie eine zufällige Sammlung von Roblox-Free-Models.

Stil:

**stylized Roblox + hochwertig + clean + Mining/Industrial**

---

## 2. Visual References

Alle wichtigen Referenzbilder liegen in:

```text
VISUAL_REFERENCES
```

Claude soll Referenzen anhand ihrer Dateinamen zuordnen.

---

## 3. Referenzkategorien

Benötigt bzw. geplant:

```text
MAP / WORLD
PLOT / FACTORY
OFFICE
MINE SHAFT
ELEVATOR
STORAGE
GARAGE
SMELTER
EQUIPMENT SHOP
MACHINE SHOP
VEHICLE SHOP
SELLING STATION
HUD
LAPTOP UI
MINE SELECT UI
SHOP UI
VEHICLES
DRILLS
WORKERS
```

---

## 4. Map-Stil

Umgebung:

- kleine Bergbaustadt
- Natur
- Grasstruktur
- Bäume
- einzelne Steine
- Berge rund um die Map
- echte Straßen
- 6 Firmenplots

Nicht:
- leere Baseplate
- sterile rechteckige Betonwüste

---

## 5. Mine-Stil

Mine Shafts:

- kleiner kompakter Schachtbereich
- behauene/organische Felswände
- sichtbare Erzader in passender Farbe/Materialoptik
- zwei Holzstützkonstruktionen
- zwei Mining Slots gegenüber/nahe Elevator-Achse
- Industrial Lighting
- keine simple graue Rechteckbox

Felsfarbe:
- bis ungefähr Mine 30 eher grau
- danach zunehmend dunkler grau

---

## 6. Erzader

Ader ist unendlich.

Sie wird optisch nicht dauerhaft zerstört.

Mining:
- Hit Animation
- kleine Steinpartikel
- ggf. Staub
- sichtbare passende Erzfarbe

Seltenere Erze dürfen gelegentlich markantere Formen besitzen.

---

## 7. Elevator

Optik:

- klassischer Bergbau-Gitterkäfig
- Metall
- sichtbare Mechanikdetails
- glaubwürdige alte/industrielle Form
- hochwertig stilisiert

Technisch darf er teleportieren.

---

## 8. Factory

Die Endstruktur ist eine große Industriehalle.

Sie muss von Anfang an geplant sein.

Die kleine Blechhütte bleibt darin als ursprüngliches Büro erhalten.

Die Halle wächst über Tycoon-Kaufbuttons, aber Layout und Endzustand sind fest.

---

## 9. Haupteinfahrt

Auf dem Plot leicht rechts:

- großes automatisches Glas-/Rolltor
- direkte Straßenanbindung
- Platz für spätere größere Fahrzeuge/LKW

---

## 10. Storage

Ein klar erkennbarer Lagerbereich innerhalb der Halle.

Großes Silo:
- außen sichtbare Füllstandsanzeige
- Conveyor-Anschlüsse
- industrieller Aufbau

Das logische Lager ist ein gemeinsamer Gesamtbestand, auch wenn die Visualisierung einzelne Materialinformationen zeigt.

---

## 11. Garage

Garage kommt nach Storage.

- eigener Hallenbereich
- sauberer Fahrzeugspawn
- leuchtender Ring für Ausparken/Spawn
- breite Ausfahrt
- Firmenfarbakzente im UI

---

## 12. Smelter

Nach Garage.

- klarer Produktionsbereich
- Input/Output
- sichtbare industrielle Maschine
- Hitze-/Glüheffekt nur wenn aktiv
- dezenter Rauch/Partikel
- nicht permanent übertriebene Effekte

---

## 13. Shops

### Equipment
Holz + Metall, Tische/Regale, Pickaxes und Backpacks sichtbar.

### Machines
Industriehalle/Werkstatt, einige Maschinen als Ausstellung.

### Vehicles
cleaner Nutzfahrzeug-Showroom mit Glas, Metall, Verkaufstresen.

---

## 14. Vehicles

Fahrzeuge:
- echte saubere Nutzfahrzeugformen
- stylized, aber glaubwürdig
- keine Cartoon-Spielzeugautos
- nicht zu viele Neonflächen
- spätere LKW größer und industrieller

---

## 15. Workers

Alle Worker:
- einheitlicher Stil
- Mining-Worker-Outfit
- direkt am Arbeitsplatz
- Rollen durch Animation/Werkzeug verständlich

Keine unnötigen Stadt-NPCs.

---

## 16. UI

UI-Referenzen definieren:
- Informationshierarchie
- Layout
- Card-Stil
- Icons
- Abstände
- Akzente

Nicht blind Pixel kopieren, wenn Roblox-Responsive-UI Anpassung benötigt.

---

## 17. Asset-Quellen

Bei externen Assets:
- Scripts prüfen/entfernen
- Mesh-/Texture-Qualität prüfen
- Stil prüfen
- Performance prüfen
- Nutzbarkeit/Lizenz beachten

Unbekannte Free Models niemals ungeprüft übernehmen.

---

## 18. Placeholder Assets

Während der technischen Phase sind saubere Placeholder erlaubt.

Sie müssen:
- eindeutig benannt
- leicht ersetzbar
- funktional dimensioniert
sein.

Kein technisches System soll von einem finalen Mesh abhängig sein.

---

## 19. Asset Registry

Empfohlen:

```text
ASSETS/
├── README.md
└── ASSET_REGISTRY.md
```

Registry enthält:
- interne Asset-ID
- Zweck
- Quelle
- Status: Placeholder / Final
- benötigte Anpassungen

---

## 20. Verbindliche Regeln

1. Einheitlicher visueller Stil.
2. Referenzbilder haben hohe Priorität für Gestaltung.
3. Keine zufällige Free-Model-Mischung.
4. Mine ist organischer Fels, keine Rechteckbox.
5. Erzader wird nicht dauerhaft abgebaut.
6. Zwei Holzstützen pro Mine.
7. Elevator ist ein Mining-Gitterkäfig.
8. Große Halle ist fest vorgeplant.
9. Büro/Blechhütte bleibt sichtbar.
10. Storage vor Garage, Garage vor Smelter.
11. Fahrzeuge sind glaubwürdige Nutzfahrzeuge.
12. Keine unnötigen Stadt-NPCs.
13. Placeholder und finale Assets strikt unterscheidbar.
