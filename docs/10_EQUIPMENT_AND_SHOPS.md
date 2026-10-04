# 10 – EQUIPMENT AND SHOPS

## 1. Zweck dieses Dokuments

Dieses Dokument definiert persönliche Mining-Ausrüstung, kaufbare Produktionsgegenstände und die drei öffentlichen Shops.

Es behandelt insbesondere:

- Pickaxes
- Backpacks
- Drills
- Conveyors
- Equipment-Inventar
- Machine-Inventar
- Freischaltungen über Mining Level
- Equipment-Shop
- Machine-Shop
- Vehicle-Shop
- Kaufregeln
- Item-Datenstruktur
- visuelle Qualitätsregeln

Fahrzeugtechnik selbst wird in `07_VEHICLES_AND_SELLING.md` definiert.

Konkrete Preise, Levelanforderungen und finale Stat-Werte werden später im Balancing festgelegt.

---

# 2. Drei getrennte Shops

Die Bergbaustadt besitzt drei funktional getrennte Shops:

```text
EQUIPMENT SHOP
→ Pickaxes
→ Backpacks

MACHINE SHOP
→ Drills
→ Conveyors

VEHICLE SHOP
→ Cars
→ Trucks
```

Es gibt keinen allgemeinen Shop, der sämtliche Gegenstände verkauft.

Die klare Trennung hilft dem Spieler, die Welt schnell zu verstehen.

---

# 3. Kein allgemeiner Upgrade-Shop

Es gibt keinen separaten Upgrade-Shop.

Unternehmensupgrades wie:

- Storage Capacity
- Elevator Capacity
- Mitarbeiterverwaltung
- Firmenmanagement

werden über den Laptop durchgeführt.

Shops verkaufen dagegen physische Ausrüstung, Maschinen und Fahrzeuge.

---

# 4. Mining-Level als Freischaltungssystem

Das Mining Level schaltet neue kaufbare Gegenstände frei.

Ein Gegenstand kann beispielsweise besitzen:

```text
RequiredMiningLevel
Price
```

Der Spieler kann einen Gegenstand erst kaufen, wenn:

1. das benötigte Mining Level erreicht wurde
2. ausreichend Geld vorhanden ist

Die konkreten Level werden später festgelegt.

---

# 5. Mining Level ist keine direkte Kaufbelohnung

Ein Level-Up gibt nicht automatisch jede neue Ausrüstung kostenlos.

Das Level schaltet den Gegenstand zunächst frei.

Danach muss der Spieler ihn mit Geld kaufen, sofern nicht ausdrücklich anders definiert.

Grundprinzip:

```text
LEVEL → UNLOCK
MONEY → PURCHASE
```

---

# 6. Pickaxes

Pickaxes sind die persönliche Mining-Ausrüstung des Spielers.

Sie beeinflussen ausschließlich das manuelle Mining.

Wichtige Stats:

- Mining Power
- Mining Speed

Pickaxes beeinflussen nicht direkt:

- Drill-Produktion
- Worker-Produktion
- Conveyor-Speed
- Smelter-Speed

---

# 7. Mining Power

`Mining Power` bestimmt die grundlegende Erzmenge eines gültigen manuellen Mining-Hits.

Bessere Pickaxes erzeugen mehr Erz pro erfolgreichem Schlag.

Die genaue Formel wird später gebalanced.

---

# 8. Mining Speed

`Mining Speed` beeinflusst die Geschwindigkeit des manuellen Mining-Zyklus.

Bessere Pickaxes können:

- schneller schlagen
- kürzere Cooldowns besitzen

Die Animation muss zur tatsächlichen Mining-Geschwindigkeit passen.

---

# 9. Pickaxe-Animation

Jede Pickaxe verwendet eine sichtbare Mining-Animation.

Grundablauf:

1. Pickaxe anheben
2. Schlagbewegung
3. Kontakt mit Erzader
4. Mining-Effekt
5. Materialgutschrift nach Servervalidierung
6. Rückkehr

Die Animation darf nicht nur kosmetisch unabhängig von der tatsächlichen Hit-Logik laufen.

---

# 10. Pickaxe-Progression

Die Pickaxe-Progression soll sichtbar und spielerisch verständlich sein.

Frühe Beispiele könnten thematisch sein:

```text
Basic Pickaxe
Iron Pickaxe
Steel Pickaxe
Reinforced Pickaxe
Industrial Pickaxe
...
```

Dies sind nur Namensbeispiele.

Die finale Liste wird beim Content-/Balancing-Schritt festgelegt.

---

# 11. Keine unnötig riesige Pickaxe-Liste

Es muss nicht für jedes einzelne Mining Level eine neue Pickaxe existieren.

Neue Pickaxes sollen sich wie echte Upgrades anfühlen.

Zwischen Upgrades darf der Spieler einige Level mit derselben Ausrüstung spielen.

---

# 12. Pickaxe-Visuals

Pickaxes sollen mit höherer Stufe hochwertiger wirken.

Mögliche Progression:

- einfache Holz-/Metallkonstruktion
- stabilere Stahlwerkzeuge
- industrielle Werkzeuge
- hochwertige Late-Game-Designs
- bei sehr seltenen Stufen dezente Spezialeffekte

Keine übertriebene Neonwaffe schon im frühen Spiel.

---

# 13. Backpacks

Backpacks bestimmen, wie viel Material der Spieler persönlich tragen kann.

Der wichtigste Stat lautet:

**Ore Capacity**

Die Kapazität des Firmenlagers und des Fahrzeugs ist davon unabhängig.

---

# 14. Getrennte Kapazitäten

Diese Systeme dürfen nicht verwechselt werden:

```text
Backpack Capacity
→ persönliches Spielerinventar

Storage Capacity
→ Firmenlager

Vehicle Capacity
→ Fahrzeug

Machine Output Capacity
→ Maschine
```

Jeder Bereich besitzt seine eigene Kapazität.

---

# 15. Backpack-Progression

Frühe Backpacks sind klein.

Spätere Backpacks besitzen größere Kapazitäten.

Visuell sollen sie ebenfalls wachsen bzw. hochwertiger werden, ohne lächerlich groß zu werden.

Mögliche Stile:

- einfacher Mining-Rucksack
- verstärkter Rucksack
- Cargo Pack
- Industrial Pack

Finale Namen und Werte werden später festgelegt.

---

# 16. Rucksack voll

Wenn die persönliche Kapazität erreicht ist:

- weiteres manuelles Erz wird nicht einfach gelöscht
- Spieler erhält `BACKPACK FULL`
- Mining kann entsprechend blockiert werden, bis Platz geschaffen wurde

Rare-Drop-Verhalten bei fast vollem Rucksack muss später eindeutig festgelegt werden, damit kein wertvoller Drop verloren geht.

---

# 17. Mining Luck

Mining Luck ist ein persönlicher Spielerstat.

Er beeinflusst ausschließlich das manuelle Rare-Drop-System.

Mining Luck wird nicht automatisch durch jeden Backpack oder jede Pickaxe erhöht.

Quellen für Mining Luck werden später separat festgelegt.

---

# 18. Rare Drops und Equipment

Pickaxes bestimmen primär:

- Mining Power
- Mining Speed

Backpacks bestimmen:

- Ore Capacity

Rare Drops bleiben ein separates System.

Dadurch werden Equipment-Stats nicht unnötig miteinander vermischt.

---

# 19. Equipment-Inventar

Gekaufte persönliche Ausrüstung wird gespeichert.

Der Spieler kann in seiner Equipment-Ansicht sehen:

```text
PICKAXES
Owned / Equipped

BACKPACKS
Owned / Equipped
```

Pro Kategorie kann grundsätzlich nur ein Gegenstand gleichzeitig ausgerüstet sein.

---

# 20. Equipped State

Der Server speichert mindestens:

```text
EquippedPickaxe
EquippedBackpack
```

Der Client darf nicht selbst behaupten, eine nicht gekaufte Pickaxe ausgerüstet zu haben.

---

# 21. Equipment-Shop

Der Equipment-Shop verkauft:

- Pickaxes
- Backpacks

Die Gegenstände werden teilweise physisch im Laden präsentiert.

Beispiele:

- Pickaxes auf Wandhalterungen
- Backpacks auf Tischen oder Regalen

---

# 22. Equipment-Shop – Look

Gewünschter Stil:

- sauberer Mining-Fachhandel
- Holz + Metall
- moderne Displays
- warme Beleuchtung
- hochwertige Präsentation
- nicht überladen

Der Shop soll wie ein echter Ort wirken und nicht wie ein leeres Gebäude mit einem UI-Knopf.

---

# 23. Equipment-Shop – Interaktion

Der Spieler kann sich ausgestellte Gegenstände ansehen.

Beim Interagieren öffnet sich die entsprechende Shop-Ansicht.

Das UI zeigt:

- Name
- Vorschau
- Stats
- Mining-Level-Anforderung
- Preis
- Besitzstatus

---

# 24. Machine-Shop

Der Machine-Shop verkauft zunächst:

- Drills
- Conveyors

Später können weitere Produktionsmaschinen hinzukommen.

---

# 25. Machine-Shop – Ausstellung

Im Machine-Shop stehen einige Maschinen als physische Ausstellungsmodelle.

Beispiele:

- ein Drill
- ein Conveyor-Segment
- technische Komponenten

Nicht jede verfügbare Maschinenstufe muss physisch ausgestellt werden.

---

# 26. Machine-Shop – Look

Der Machine-Shop wirkt industrieller als der Equipment-Shop.

Mögliche Elemente:

- Metallträger
- Beton
- große Hallentore
- Werkstattlampen
- Werkzeugwände
- technische Displays
- Maschinenplattformen

Trotzdem bleibt alles clean und hochwertig.

---

# 27. Drills

Drills sind kaufbare Mining-Maschinen.

Ein Drill besitzt mindestens:

- Production Rate
- Cycle Time
- Output Capacity
- Required Mining Level
- Price

Drills erhalten keine Rare Drops.

---

# 28. Drill-Progression

Frühe Drills:

- klein
- relativ langsam
- günstig

Spätere Drills:

- größer
- hochwertiger
- produktiver
- größere lokale Output-Kapazität

Die Entwicklung soll visuell erkennbar sein.

---

# 29. Drill-Design

Ein Drill soll wie eine echte Mining-Maschine wirken.

Wichtige visuelle Elemente:

- Bohrkopf
- Motor-/Maschinenkörper
- Stand-/Bodenstruktur
- Output-Bereich
- bewegliche Teile
- Staub-/Steineffekt im Betrieb

Keine reine Box mit rotierendem Zylinder.

---

# 30. Drill-Kauf

Nach Kauf landet der Drill im Inventar.

Er erscheint nicht automatisch in irgendeiner Mine.

Der Spieler entscheidet später, in welcher Mine und auf welchem freien Mining-Slot er ihn platziert.

---

# 31. Drill-Platzierung

Ablauf:

```text
Inventory
↓
Select Drill
↓
Enter Mine
↓
Valid Mining Slots highlighted
↓
Select Slot
↓
Server validates
↓
Drill placed
```

Nur feste Mining-Slots sind gültig.

---

# 32. Drill entfernen

Ein platzierter Drill soll kontrolliert wieder entfernt werden können.

Danach:

- Slot wird frei
- Drill kehrt in das passende Inventarsystem zurück
- keine Produktionsmenge wird dupliziert
- lokaler Output wird sicher behandelt

Die genaue UX wird später definiert.

---

# 33. Drill austauschen

Wenn der Spieler einen besseren Drill auf einem belegten Slot verwenden möchte, muss der vorhandene Drill zunächst entfernt oder über eine definierte Replace-Funktion ersetzt werden.

Ein Replace-Vorgang muss atomar und duplikationssicher sein.

---

# 34. Conveyors

Conveyors automatisieren Materialtransport an vorgesehenen Stellen.

Sie werden später als Drills freigeschaltet.

Aktueller Zielbereich:

**ungefähr Mining Level 35**

Der genaue Unlock-Level wird später festgelegt.

---

# 35. Conveyor-Stats

Ein Conveyor besitzt mindestens:

- Throughput
- Required Mining Level
- Price

Falls mehrere Conveyor-Stufen existieren, können bessere Varianten höheren Durchsatz besitzen.

---

# 36. Conveyor-Kauf

Nach Kauf landet der Conveyor im Inventar.

Er wird nicht automatisch installiert.

Der Spieler muss ihn an einem vorgesehenen Conveyor-Slot platzieren.

---

# 37. Conveyor-Platzierung

Ablauf:

```text
Inventory
↓
Select Conveyor
↓
Valid Conveyor Slot highlighted
↓
Preview
↓
Confirm
↓
Server validation
↓
Installed
```

Kein freies Sandbox-Conveyor-System.

---

# 38. Maschineninventar

Drills und Conveyors gehören zu einem Maschinen-/Placement-Inventar.

Es muss mindestens unterscheiden:

```text
Owned
Placed
Available
```

Beispiel:

```text
Industrial Drill
Owned: 3
Placed: 2
Available: 1
```

---

# 39. Keine unklaren Item-Duplikate

Jeder physisch platzierbare Gegenstand benötigt eine eindeutige Besitzlogik.

Das System muss wissen:

- wie viele gekauft wurden
- wie viele platziert sind
- wo sie platziert sind
- wie viele verfügbar sind

---

# 40. Vehicle-Shop

Der Vehicle-Shop verkauft Fahrzeuge.

Die Fahrzeugmechanik wird in `07_VEHICLES_AND_SELLING.md` definiert.

Der Shop zeigt:

- Fahrzeugname
- 3D-Vorschau
- Kapazität
- Geschwindigkeit
- Levelanforderung
- Preis
- Besitzstatus

---

# 41. Vehicle-Shop – Look

Der Vehicle-Shop soll wie ein sauberer kleiner Nutzfahrzeughändler wirken.

Elemente:

- Glas
- Metall
- Showroom
- großes Tor
- einige ausgestellte Fahrzeuge
- Verkaufstresen
- hochwertige Beleuchtung

Keine Luxus-Supersportwagen-Atmosphäre.

---

# 42. Shop-Kaufregel

Jeder Kauf wird serverseitig geprüft.

Mindestens:

```text
Item exists?
Player level sufficient?
Enough money?
Already owned if unique?
Inventory/state valid?
```

Erst danach wird:

- Geld abgezogen
- Item gutgeschrieben
- Kauf bestätigt

---

# 43. Keine clientseitigen Preise

Der Client darf einen Preis anzeigen, aber nicht bestimmen.

Der Server verwendet die zentrale Itemdefinition als Wahrheit.

Ein manipulierter RemoteRequest mit:

```text
Price = 1
```

darf keine Wirkung haben.

---

# 44. Item-Konfiguration

Alle Items sollen zentral datengetrieben definiert werden.

Beispiel:

```lua
Pickaxes = {
    BasicPickaxe = {
        DisplayName = "Basic Pickaxe",
        RequiredLevel = 1,
        Price = 0,
        MiningPower = 1,
        MiningSpeed = 1,
    },
}
```

Dies sind Beispielwerte.

Keine Beispielzahl gilt automatisch als finale Balance.

---

# 45. Backpack-Konfiguration

Beispiel:

```lua
Backpacks = {
    StarterBackpack = {
        DisplayName = "Starter Backpack",
        RequiredLevel = 1,
        Price = 0,
        Capacity = 100,
    },
}
```

Auch hier sind Zahlen Platzhalter, sofern sie nicht in anderen Projektdokumenten ausdrücklich als verbindlich definiert wurden.

---

# 46. Drill-Konfiguration

Beispiel:

```lua
Drills = {
    DrillMK1 = {
        DisplayName = "Drill MK1",
        RequiredLevel = 0,
        Price = 0,
        ProductionRate = 0,
        CycleTime = 0,
        OutputCapacity = 0,
    },
}
```

Nullwerte bedeuten:

**noch nicht gebalanced**

Claude darf sie nicht als reale Gameplaywerte übernehmen.

---

# 47. Conveyor-Konfiguration

Beispiel:

```lua
Conveyors = {
    ConveyorMK1 = {
        DisplayName = "Conveyor MK1",
        RequiredLevel = 0,
        Price = 0,
        Throughput = 0,
    },
}
```

Auch diese Werte werden später ersetzt.

---

# 48. Item-IDs

Interne Item-IDs sollen stabil bleiben.

Display-Namen dürfen später geändert werden, ohne gespeicherte Spielerdaten zu zerstören.

Beispiel:

```text
Internal ID:
drill_mk1

Display Name:
Industrial Drill
```

Persistenz verwendet die interne ID.

---

# 49. Item-Kategorien

Empfohlene Kategorien:

```text
Pickaxe
Backpack
Drill
Conveyor
Vehicle
```

Spätere Kategorien können ergänzt werden.

---

# 50. Item-Rarität

Eine klassische farbcodierte Loot-Rarity ist für normale Shop-Ausrüstung zunächst nicht zwingend nötig.

Fortschritt wird hauptsächlich über:

- Mining Level
- Stats
- Preis
- visuelles Upgrade

kommuniziert.

Claude soll nicht ohne Grund ein Common/Rare/Epic/Legendary-System über sämtliche Shopgegenstände legen.

---

# 51. Robux-Gegenstände

Robux-Käufe bleiben bei Prestige/Rebirth erhalten.

Welche konkreten Robux-Produkte existieren, wird später separat definiert.

Normale Shop-Ausrüstung darf nicht automatisch als Robux-Produkt umgesetzt werden.

---

# 52. Prestige und normale Items

Beim Prestige werden normale Progressionsinhalte entsprechend dem späteren Prestige-Dokument zurückgesetzt.

Robux-Käufe bleiben erhalten.

Die Itemarchitektur muss deshalb unterscheiden können zwischen:

- normal erspieltem Besitz
- permanentem Robux-Entitlement

---

# 53. Shop-Preview

Items sollen möglichst hochwertig dargestellt werden.

Mögliche Methoden:

- ViewportFrame
- physische Ausstellung
- Icon

Wichtige Gegenstände wie Fahrzeuge und Drills profitieren von 3D-Previews.

---

# 54. Visual References

Später sollen für die Shops eigene Referenzen erstellt werden.

Mindestens:

```text
VISUAL_REFERENCES/12_EQUIPMENT_SHOP.png
VISUAL_REFERENCES/13_MACHINE_SHOP.png
VISUAL_REFERENCES/14_VEHICLE_SHOP.png
VISUAL_REFERENCES/19_SHOP_UI.png
```

Diese Referenzen bestimmen später die genaue visuelle Gestaltung.

---

# 55. Keine Asset-Wildmischung

Claude darf nicht wahllos Free-Model-Assets mit komplett unterschiedlichen Stilen kombinieren.

Alle verwendeten Assets müssen zum gemeinsamen Stil passen:

**stylized + clean + hochwertig + Mining/Industrial**

---

# 56. Externe Assets

Falls später Toolbox-/Creator-Store-Assets verwendet werden:

- Scripts in Modellen prüfen
- unnötige Scripts entfernen
- Assetstruktur kontrollieren
- Performance prüfen
- Lizenz/Nutzbarkeit beachten
- Stil anpassen

Keine unbekannten Free Models ungeprüft in das Spiel übernehmen.

---

# 57. Equipment-Stats im UI

Die UI soll nur relevante Stats anzeigen.

Pickaxe:

```text
Mining Power
Mining Speed
```

Backpack:

```text
Capacity
```

Drill:

```text
Production
Output Capacity
```

Conveyor:

```text
Throughput
```

Vehicle:

```text
Capacity
Speed
```

---

# 58. Vergleichsansicht

Wenn sinnvoll, darf das Shop-UI den aktuell ausgerüsteten Gegenstand mit dem ausgewählten Gegenstand vergleichen.

Beispiel:

```text
Mining Power
12 → 18

Mining Speed
1.0 → 1.2
```

Dadurch erkennt der Spieler sofort den Nutzen eines Upgrades.

---

# 59. Kauf nach Freischaltung

Wenn ein Item noch gesperrt ist, soll der Shop es trotzdem als zukünftiges Ziel zeigen können.

Beispiel:

```text
INDUSTRIAL DRILL

LOCKED
Requires Mining Level 20
```

So sieht der Spieler, worauf er hinarbeitet.

---

# 60. Keine Spoiler-Flut

Sehr weit entfernte Endgame-Items müssen nicht alle direkt sichtbar sein.

Shops dürfen Items abhängig von Progression sinnvoll gruppieren oder spätere Stufen teilweise verbergen.

Die genaue UX wird beim UI-Test festgelegt.

---

# 61. Besitzstatus

Shop-Karten unterscheiden klar:

```text
LOCKED
AVAILABLE
OWNED
EQUIPPED
```

Bei mehrfach kaufbaren Maschinen zusätzlich:

```text
OWNED: 3
AVAILABLE: 1
```

---

# 62. Mehrfach kaufbare Items

Pickaxes und Backpacks sind grundsätzlich sammel-/besitzbasierte Equipment-Gegenstände.

Drills und Conveyors können mehrfach gekauft werden.

Das System darf daher nicht für alle Itemtypen dieselbe `Owned = true/false`-Logik erzwingen.

---

# 63. Inventar und Trading

Später sollen Spieler untereinander unter anderem Drills und Erze handeln können.

Deshalb muss ein Drill als sauber definierter Besitzgegenstand existieren.

Trading selbst wird separat spezifiziert.

Conveyors oder andere Items werden nicht automatisch handelbar, nur weil Drills handelbar sind.

---

# 64. Item-Instanzen vs. Item-Typen

Die technische Architektur soll früh entscheiden, ob mehrfach vorhandene Maschinen individuelle Instanzen benötigen.

Für handelbare Drills ist langfristig eine eindeutige Item-Instanz-ID sinnvoll.

Beispiel:

```text
ItemType:
drill_mk3

InstanceId:
UUID
```

Dadurch können spätere Systeme wie Trading sicherer umgesetzt werden.

---

# 65. Keine unnötigen zufälligen Stats

Shop-Drills besitzen zunächst definierte feste Stats.

Nicht vorgesehen:

- zufällige Drill-Rolls
- zufällige Pickaxe-Qualität
- zufällige Backpack-Boni

Der Spieler soll beim Kauf wissen, was er bekommt.

---

# 66. Keine Lootboxen als Kernprogression

Die normale Equipment-Progression basiert auf:

```text
Level
→ Unlock
→ Geld verdienen
→ gezielt kaufen
```

Nicht auf zufälligen Lootboxen.

---

# 67. Shop-Audio

Jeder Shop darf leichte eigene Ambient-Details besitzen.

Equipment-Shop:
- ruhiger Laden
- leichte Werkstattatmosphäre

Machine-Shop:
- dezente Maschinen-/Werkstattgeräusche

Vehicle-Shop:
- saubere Showroom-/Garagenatmosphäre

Audio bleibt dezent.

---

# 68. Shop-Schilder

Die drei Shops müssen von außen eindeutig beschriftet sein:

```text
EQUIPMENT
MACHINES
VEHICLES
```

Spieler sollen nicht erst hineingehen müssen, um zu erkennen, welcher Shop was verkauft.

---

# 69. Shop-Performance

Physische Ausstellungsmodelle sind dekorativ.

Sie dürfen keine unnötigen komplexen Scripts besitzen.

ViewportFrames werden nur aktiviert/aktualisiert, wenn sie sichtbar bzw. benötigt werden.

---

# 70. Persistenz

Gespeichert werden mindestens:

```text
OwnedPickaxes
OwnedBackpacks
EquippedPickaxe
EquippedBackpack

OwnedDrills
PlacedDrills

OwnedConveyors
PlacedConveyors

OwnedVehicles
```

Die genaue Datenstruktur wird im technischen Architektur-Dokument finalisiert.

---

# 71. Anti-Exploit

Server muss mindestens verhindern:

- Kauf ohne ausreichendes Geld
- Kauf ohne erforderliches Level
- Ausrüsten nicht besessener Items
- Platzieren nicht besessener Maschinen
- mehrfaches Gutschreiben durch Remote-Spam
- negative Itemmengen
- Drill-Duplikation beim Entfernen
- Conveyor-Duplikation beim Entfernen
- manipulierte Item-IDs

---

# 72. Erweiterbarkeit

Das Shop-System soll später zusätzliche Kategorien ermöglichen.

Mögliche Beispiele:

- weitere Maschinen
- kosmetische Firmenobjekte
- spezielle Werkzeuge

Neue Kategorien dürfen ergänzt werden, ohne die drei bestehenden Shops komplett neu programmieren zu müssen.

---

# 73. Noch offene Content-/Balancefragen

Später festzulegen:

- vollständige Pickaxe-Liste
- vollständige Backpack-Liste
- vollständige Drill-Liste
- vollständige Conveyor-Liste
- vollständige Fahrzeugliste
- Preise
- Mining-Level-Anforderungen
- Mining Power
- Mining Speed
- Backpack Capacity
- Drill Production Rate
- Drill Cycle Time
- Drill Output Capacity
- Conveyor Throughput
- genaue visuelle Modelle
- Mining-Luck-Quellen

Diese Werte werden erst nach der Grundarchitektur und ersten spielbaren Tests finalisiert.

---

# 74. Verbindliche Regeln

1. Es gibt drei getrennte Shops: Equipment, Machines und Vehicles.
2. Equipment-Shop verkauft Pickaxes und Backpacks.
3. Machine-Shop verkauft Drills und Conveyors.
4. Vehicle-Shop verkauft Fahrzeuge.
5. Es gibt keinen allgemeinen Upgrade-Shop.
6. Firmenupgrades laufen hauptsächlich über den Laptop.
7. Mining Level schaltet neue Items frei.
8. Freischaltung bedeutet nicht automatisch kostenlosen Besitz.
9. Geld wird zum eigentlichen Kauf verwendet.
10. Pickaxes beeinflussen Mining Power und Mining Speed.
11. Pickaxes verbessern keine Maschinen.
12. Backpacks bestimmen persönliche Ore Capacity.
13. Firmenlager, Backpack und Fahrzeug besitzen getrennte Kapazitäten.
14. Drills besitzen feste definierte Produktionsstats.
15. Drills besitzen keine Rare Drops.
16. Drills können mehrfach gekauft werden.
17. Gekaufte Drills landen zunächst im Inventar.
18. Drills werden nur an festen Mining-Slots platziert.
19. Conveyors werden nur an festen Conveyor-Slots platziert.
20. Conveyor-Freischaltung liegt derzeit ungefähr bei Mining Level 35; finaler Wert bleibt offen.
21. Shopkäufe werden serverseitig validiert.
22. Preise stammen aus Serverkonfiguration, nicht vom Client.
23. Items besitzen stabile interne IDs.
24. Shop-Ausrüstung erhält keine unnötigen Zufallsstats.
25. Keine Lootboxen als Kernprogression.
26. Robux-Entitlements müssen getrennt von normalem Besitz gespeichert werden.
27. Robux-Käufe bleiben über Prestige hinweg erhalten.
28. Drills sollen technisch auf späteres Trading vorbereitet sein.
29. Shop-Assets müssen einem einheitlichen hochwertigen Stil folgen.
30. Finale Zahlen werden erst in der Balancing-Phase festgelegt.
