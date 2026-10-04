# 01 – Game Design

## 1. Zweck dieses Dokuments

Dieses Dokument definiert die grundlegende Spielidee, die Kern-Spielschleife und die übergeordneten Designprinzipien des Roblox-Spiels.

Es ist eine verbindliche Designgrundlage für die spätere Entwicklung. Detaillierte Balancing-Werte, konkrete Preise, XP-Kurven, technische Implementierungen und einzelne Asset-Spezifikationen werden in separaten Dokumenten festgelegt.

Wenn spätere technische Entscheidungen diesem Dokument widersprechen, muss zuerst geprüft werden, ob die Designanforderung weiterhin erfüllt wird. Funktionalität darf nicht auf Kosten des grundlegenden Spielerlebnisses verändert werden.

---

# 2. Arbeitstitel

**Mining Company Tycoon**

Der endgültige Name des Spiels ist noch nicht festgelegt.

Der Arbeitstitel beschreibt das zentrale Spielprinzip: Der Spieler entwickelt ein kleines Bergbauunternehmen von einem einzelnen Miner zu einem weitgehend automatisierten Mining-Unternehmen.

---

# 3. Grundidee

Der Spieler startet als einzelner Bergarbeiter.

Zu Beginn besitzt er nur:

- eine Spitzhacke
- einen kleinen Rucksack
- ein kleines Firmenbüro
- keinen Mitarbeiter
- keine Maschine
- kein Fahrzeug
- keine automatisierte Produktion

Der Spieler muss zunächst selbst in einer Mine Erz abbauen, das Erz zur Oberfläche bringen, verkaufen und mit dem verdienten Geld bessere Ausrüstung kaufen.

Mit zunehmendem Fortschritt entwickelt sich daraus ein echtes Bergbauunternehmen.

Der Spieler:

1. baut selbst Erz ab
2. verbessert Spitzhacke und Rucksack
3. schaltet neue Minen frei
4. stellt Mitarbeiter ein
5. ersetzt manuelle Arbeit teilweise durch Bohrer
6. baut Lager- und Produktionsanlagen auf
7. verwendet Förderbänder
8. verarbeitet Rohstoffe
9. kauft Fahrzeuge
10. transportiert Waren
11. verkauft die fertigen Produkte
12. erweitert und automatisiert das Unternehmen
13. erreicht höhere Mining-Level
14. kann später Prestige/Rebirth durchführen

Das zentrale Gefühl soll sein:

> **Aus einem einzelnen Arbeiter wird Schritt für Schritt ein großes, sichtbares und funktionierendes Bergbauunternehmen.**

---

# 4. Abgrenzung zu einem klassischen Clicker

Das Spiel darf nicht wie ein einfacher Clicker wirken.

Der Spieler soll nicht hauptsächlich:

- einen Button anklicken
- auf eine Zahl warten
- automatisch Geld bekommen
- lediglich Werte erhöhen

Stattdessen soll die Entwicklung des Unternehmens **sichtbar und physisch in der Welt stattfinden**.

Der Spieler soll Maschinen, Mitarbeiter, Förderbänder, Lager, Schmelzanlagen und Fahrzeuge tatsächlich sehen.

Die Produktionskette soll nachvollziehbar sein:

**Mine → Transport → Aufzug → Lager → Förderband → Verarbeitung → Lager/Loading → Fahrzeug → Verkauf**

Die Automatisierung ist damit nicht nur eine Zahl in einem Menü, sondern ein sichtbarer Bestandteil der Spielwelt.

---

# 5. Kern-Spielschleife

Die grundlegende Spielschleife besteht aus:

## Frühphase

**Minen → Rucksack füllen → Oberfläche → verkaufen → Geld verdienen → Ausrüstung verbessern**

## Mittlere Phase

**Minen → Mitarbeiter/Bohrer → Aufzug → Lager → Produktion → Fahrzeug → verkaufen → Unternehmen ausbauen**

## Späte Phase

**Mehrere Minen → mehrere Produktionsketten → Mitarbeiter → Bohrer → Förderbänder → Lager → Verarbeitung → Fahrzeuge → Verkauf → weitere Automatisierung**

Der Spieler bleibt dabei immer aktiv im Unternehmen.

Auch im Endgame soll der Spieler nicht nur zuschauen. Besonders das Fahren der eigenen Fahrzeuge und das Management des Unternehmens bleiben aktive Bestandteile.

---

# 6. Rolle des Spielers

Der Spieler ist gleichzeitig:

- Eigentümer des Unternehmens
- Geschäftsführer
- Miner
- Fahrer
- Manager

Zu Beginn übernimmt der Spieler fast alle Aufgaben selbst.

Mit dem Fortschritt kann er immer mehr Aufgaben automatisieren.

Wichtig:

Automatisierung soll den Spieler nicht vollständig ersetzen.

Der Spieler soll auch im Endgame noch einen Grund haben:

- selbst zu minen
- neue Minen zu besuchen
- Fahrzeuge zu fahren
- seine Firma zu verwalten
- neue Anlagen freizuschalten
- seine Produktionsabläufe zu optimieren

---

# 7. Das Bergbauunternehmen

Jeder Spieler besitzt ein eigenes Unternehmen und ein eigenes Grundstück.

Das Grundstück hat von Anfang an eine feste Größe.

Das Grundstück wächst nicht beliebig mit dem Fortschritt.

Stattdessen entwickelt sich die vorhandene Fläche innerhalb einer großen Fabrikhalle weiter.

Die Halle ist bereits früh vorhanden, aber am Anfang weitgehend leer.

Der Spieler baut sie schrittweise aus.

Dadurch entsteht ein sichtbarer Unternehmensfortschritt:

**Anfang:**
- kleine Blechhütte
- Aufzug
- große, fast leere Halle
- minimale Infrastruktur

**Fortgeschritten:**
- Lager
- Garage
- Maschinen
- Mitarbeiter
- Förderbänder
- Schmelzer
- Ladebereich
- Fahrzeuge

**Endgame:**
- vollständig eingerichtete Industrieanlage
- mehrere Produktionssysteme
- große Lagerkapazität
- mehrere Fahrzeuge
- weitgehend automatisierte Produktionskette

Die äußere Halle bleibt dabei grundsätzlich dieselbe.

---

# 8. Die Blechhütte

Die Firma beginnt mit einer sehr kleinen Blechhütte innerhalb der Fabrikhalle.

Die Hütte kostet **0 $**.

Sie dient als erstes Firmenbüro und bleibt dauerhaft bestehen.

Die Hütte soll bewusst klein und einfach wirken.

Sie enthält unter anderem:

- einen Schreibtisch
- einen Laptop
- einen Stuhl
- ein Bett
- ein kleines Regal
- einfache Werkzeuge bzw. Dekoration

Das Bett dient zunächst als Spawnpunkt.

Die Hütte darf auch im Endgame nicht entfernt oder durch ein luxuriöses Büro ersetzt werden.

Sie soll dauerhaft an den Anfang des Unternehmens erinnern.

---

# 9. Unternehmensname, Logo und Firmenfarbe

Beim erstmaligen Aufbau der Firma legt der Spieler fest:

- Unternehmensname
- Firmenlogo
- Firmenfarbe

Der Unternehmensname wird sichtbar:

- auf einem Firmenschild
- im Laptop
- in relevanten Unternehmensmenüs

Die Firmenfarbe wird hauptsächlich für:

- Unternehmensmarkierungen
- Grundstückselemente
- Garage/UI-Akzente
- ausgewählte Firmenanzeigen

verwendet.

Die Firmenfarbe wird nicht auf den Roblox-Charakter aufgetragen.

Die genaue Auswahl und Verwaltung der Farben und Logos wird in einem späteren UI-/Technikdokument definiert.

---

# 10. Welt

Die Spielwelt ist eine kleine Bergbaustadt.

Sie soll nicht wie eine leere Fläche wirken.

Die Stadt ist von Bergen umgeben.

Die Umgebung enthält:

- Gras
- Bäume
- Steine
- natürliche Geländeveränderungen
- Berge
- Straßen
- Gebäude
- kleine dekorative Häuser

Die Welt bleibt übersichtlich und funktional.

Es sollen keine unnötigen Gebäude oder Systeme hinzugefügt werden, nur um die Karte größer erscheinen zu lassen.

---

# 11. Zentrale Stadt

In der Mitte der Karte befindet sich ein zentraler Bereich.

Auf jedem Server befinden sich:

**6 Spieler-Grundstücke.**

Die Grundstücke sind um den zentralen Bereich angeordnet.

Die Straßen verbinden die Grundstücke mit der Stadt.

Die wichtigsten Gebäude befinden sich im zentralen Bereich:

- Verkaufsgebäude
- Equipment Shop
- Drill/Conveyor Shop
- Vehicle Shop
- einige dekorative Häuser

Die Stadt soll wie eine kleine funktionierende Bergbaustadt wirken.

---

# 12. Grundstücke

Jeder Spieler erhält genau ein Grundstück.

Das Grundstück besitzt:

- feste Größe
- niedrige Umzäunung
- große Fabrikhalle
- Firmenbüro
- Garage
- Lagerbereich
- Produktionsbereich
- Aufzug/Minenzugang
- spätere Maschinen und Infrastruktur

Die Grundstruktur wird nicht ständig neu aufgebaut.

Stattdessen kauft der Spieler einzelne Bauabschnitte.

Das System orientiert sich an klassischen Roblox-Tycoon-Systemen:

- Kaufbuttons befinden sich an definierten Stellen.
- Immer nur ein Hauptkauf ist gleichzeitig verfügbar.
- Nach dem Kauf erscheint das neue Bauteil sofort.
- Danach wird der nächste sinnvolle Kauf freigeschaltet.

Die Bauentwicklung soll kontrolliert und übersichtlich bleiben.

---

# 13. Große Fabrikhalle

Die Fabrikhalle ist bereits zu Beginn vorhanden.

Sie ist groß genug, um die spätere Entwicklung des Unternehmens aufzunehmen.

Sie wird nicht durch immer größere Gebäude ersetzt.

Stattdessen wird sie schrittweise eingerichtet.

Die Halle soll auch im Endgame:

- sauber
- organisiert
- übersichtlich
- logisch aufgebaut

bleiben.

Es darf keine chaotische Ansammlung von Maschinen und Förderbändern entstehen.

---

# 14. Mining

Mining ist der wichtigste aktive Teil des Spiels.

Der Spieler besitzt eine Spitzhacke und kann selbst Erz abbauen.

Das Mining soll:

- direkt steuerbar
- animiert
- verständlich
- befriedigend
- performant

sein.

Beim Mining entstehen unter anderem:

- Spitzhackenanimation
- Treffergeräusch
- kleine Steinsplitter
- Staub
- Erz-Drop
- Floating-Text für erhaltenes Erz

Die Erzadern sind unendlich.

Die Mine wird durch das Mining des Spielers nicht dauerhaft zerstört.

Der Spieler baut also aus einer dauerhaft verfügbaren Erzader ab.

---

# 15. Minen

Es gibt insgesamt zunächst **100 Minenschächte**.

Die Minen sind separate, kleine Bergbaubereiche.

Sie sollen nicht wie riesige Höhlen wirken.

Eine typische Mine enthält:

- einen kleinen Schacht
- eine Felswand
- Erzvorkommen
- zwei Abbauplätze
- zwei Holzstützkonstruktionen
- einen Zugang zum Minenaufzug

Die Felsen sollen handgemeißelt und unregelmäßig wirken.

Keine großen rechteckigen grauen Minecraft-Blöcke.

Die Mine soll stylisiert, aber glaubwürdig wie ein Bergwerk aussehen.

---

# 16. Erzprogression

Die Minen werden nach und nach freigeschaltet.

Die aktuelle Grundidee ist:

- Mine 01–02: Kohle
- Mine 03–04: Kupfer
- Mine 05–06: nächstes Erz
- danach weitere Erze
- Diamant ist aktuell das letzte geplante Erz der ursprünglichen Progression

Die genaue vollständige Erzliste und Mine-zu-Erz-Zuordnung wird in `03_MINING_AND_ORES.md` festgelegt.

Jedes nachfolgende Erz soll grundsätzlich einen deutlich höheren Ertrag besitzen.

Als Designgrundlage gilt:

**Jedes nächste Erz erhält ungefähr den doppelten Basiswert bzw. Ertrag des vorherigen Erzes.**

Die konkreten Werte werden erst beim Balancing festgelegt.

---

# 17. Erzadern

Die Erzadern sind dauerhaft verfügbar.

Die Felswand wird nicht tatsächlich zerstört.

Erzvorkommen werden visuell als unterschiedliche Ablagerungen bzw. Vorkommen innerhalb der Felswand dargestellt.

Die verschiedenen Erze müssen anhand ihrer Darstellung klar unterscheidbar sein.

Seltene Erze dürfen auch in einer Mine erscheinen, in der normalerweise ein anderes Erz gefördert wird.

Die Wahrscheinlichkeit dafür ist sehr gering und hängt unter anderem von Mining Luck ab.

---

# 18. Seltene Drops

Seltene Drops sind ausschließlich mit dem **manuellen Mining des Spielers** verbunden.

Worker und Drills erhalten keine Rare-Drop-Mechanik.

Bei einem manuellen Mining-Ereignis passiert grundsätzlich eines von zwei Dingen:

### Normaler Drop

Der Spieler erhält eine Menge des aktuellen Erzes.

Die Menge kann durch einen normalen Drop-Multiplikator erhöht werden.

### Seltener Drop

Statt des normalen Drops erhält der Spieler ein seltenes Erz.

Dabei kann ein Erz aus den nächsten vier besseren Erzstufen erscheinen.

Normaler Drop und Rare Drop werden nicht miteinander kombiniert.

Beispiel:

Nicht:

`+8 Coal + Rare Copper`

sondern entweder:

`+8 Coal`

oder:

`RARE DROP! +1 Copper`

Rare Drops sollen deutlich sichtbar dargestellt werden.

---

# 19. Mining Level

Der Spieler besitzt genau ein übergeordnetes **Mining Level**.

Es gibt kein separates Company Level.

Das Mining Level wird dauerhaft unten in der Mitte angezeigt.

Die Anzeige enthält:

- Level
- XP-Balken
- aktuellen Fortschritt

Beim Level-Up erscheint kurz eine sichtbare Level-Up-Animation bzw. Meldung.

---

# 20. XP-System

XP wird ausschließlich durch **Verkaufen** verdient.

Das bedeutet:

Mining selbst gibt nicht direkt XP.

Der Ablauf lautet:

**Erz abbauen → transportieren → verkaufen → Mining XP erhalten**

Seltenere Erze geben mehr XP.

Der Erzpreis und die XP-Belohnung sind voneinander unabhängig.

Ein Erz muss also nicht automatisch mehr XP geben, nur weil es mehr Geld wert ist.

Die genaue XP-Kurve wird in einem separaten Balancing-Dokument festgelegt.

---

# 21. Automatisierung

Automatisierung ist ein zentraler Bestandteil des Spiels.

Sie entwickelt sich schrittweise.

Ein möglicher Entwicklungsweg:

**Manueller Miner**
→ **Worker**
→ **Drill**
→ **Transport**
→ **Lager**
→ **Förderband**
→ **Schmelzer**
→ **Loading**
→ **Fahrzeug**
→ **Verkauf**

Die Automatisierung soll niemals nur als UI-Zahl existieren.

Die Maschinen und Mitarbeiter sollen sichtbar in der Welt arbeiten.

---

# 22. Mitarbeiter

Mitarbeiter sind echte Firmenangestellte.

Sie sind keine Haustiere und kein Pet-System.

Ein Mitarbeiter wird einmalig eingestellt und erhält anschließend ein laufendes Gehalt.

Mitarbeiter sind sichtbar und arbeiten an ihrem Arbeitsplatz.

Es gibt grundsätzlich:

- Mining Worker
- Transport Worker

Weitere Mitarbeiterarten können später hinzukommen.

Jede Mine besitzt:

- 2 feste Mining-Slots
- bis zu 2 Transport-Slots

Dadurch sind maximal 4 Mitarbeiter pro Mine möglich.

Ein Mining-Slot kann entweder durch:

- einen Worker

oder:

- einen Drill

besetzt werden.

Worker und Drill können denselben Mining-Slot nicht gleichzeitig nutzen.

---

# 23. Drills

Drills sind Maschinen zur automatisierten Erzförderung.

Ein Drill wird gekauft und anschließend an einem vorgesehenen Mining-Slot platziert.

Der Drill produziert automatisch Erz pro Sekunde.

Während des Betriebs:

- bewegt sich der Bohrkopf
- entstehen Staub und kleine Steinsplitter
- ist ein Arbeitsgeräusch hörbar
- zeigt der Drill einen Betriebsstatus

Die Felswand wird dabei nicht tatsächlich zerstört.

Bessere Drills besitzen bessere Produktionswerte.

Die Maschineneffizienz wird nicht separat als Spielerstatistik verbessert.

Stattdessen sind höherwertige Maschinen grundsätzlich effizienter.

---

# 24. Materialfluss

Der sichtbare Materialfluss ist ein Kernelement des Spiels.

Material soll nach Möglichkeit physisch nachvollziehbar durch die Produktionskette wandern:

**Mine**
→ **Aufzug**
→ **Lager**
→ **Förderband**
→ **Schmelzer**
→ **Ladebereich**
→ **Fahrzeug**
→ **Verkauf**

Für die Performance werden keine tausenden einzelnen Erzobjekte benötigt.

Stattdessen werden sichtbare Materialmengen als kompakte Materialhaufen bzw. Materialeinheiten dargestellt.

Eine sichtbare Einheit kann intern eine größere Menge repräsentieren.

---

# 25. Lager

Es gibt ein großes allgemeines Lager.

Es gibt nicht für jede Erzart ein eigenes separates Hauptlager.

Das Lager enthält sämtliche Rohstoffe und Produktionsmaterialien.

Die Anfangskapazität beträgt:

**1.000 Einheiten.**

Die Kapazität kann später über den Laptop verbessert werden.

Das Lager besitzt ein sichtbares Silo bzw. eine entsprechende Lageranlage.

Der Füllstand soll auch physisch sichtbar sein.

Beispiel:

`2.438 / 5.000`

Wenn ein nachgelagerter Produktionsschritt voll ist, entsteht ein Rückstau.

Das System soll logisch funktionieren:

**Wenn ein nachgelagerter Schritt keinen Platz mehr hat, kann der vorherige Schritt irgendwann ebenfalls nicht mehr weiterproduzieren.**

Es soll keine unendliche Materialproduktion trotz voller Lager stattfinden.

---

# 26. Förderbänder

Förderbänder werden im späteren Fortschritt freigeschaltet.

Die aktuelle Zielgröße für die Freischaltung liegt ungefähr bei Mining Level 35.

Der exakte Wert wird später festgelegt.

Förderbänder werden an vordefinierten Platzierungspunkten installiert.

Sie sollen nicht beliebig über die gesamte Fläche frei gebaut werden können.

Nach der Platzierung richten sie sich automatisch korrekt aus.

Sie bewegen Material tatsächlich.

Wenn kein Material transportiert wird, stehen sie still.

Wenn Material transportiert wird, läuft die Animation.

---

# 27. Verarbeitung / Schmelzer

Der Schmelzer verarbeitet Rohstoffe automatisch.

Der Spieler muss nicht für jeden Produktionszyklus ein Rezept auswählen.

Beispiele:

**Iron Ore → Iron Bar**

Verarbeitete Materialien besitzen einen höheren Verkaufswert als das ursprüngliche Rohmaterial.

Sowohl Rohmaterial als auch verarbeitete Materialien können verkauft werden.

Der Schmelzer arbeitet nur, wenn:

- Rohmaterial vorhanden ist
- genügend Produktionskapazität vorhanden ist
- der nächste Produktionsschritt Material aufnehmen kann

Während des Betriebs:

- Feuer/Glühen
- Rauch
- Geräusche
- sichtbarer Output

Wenn er nicht arbeitet, soll die Produktionsanimation stoppen.

---

# 28. Fahrzeuge

Fahrzeuge sind ein wichtiger Bestandteil der mittleren und späteren Progression.

Der Spieler kauft Fahrzeuge im Vehicle Shop.

Das erste Fahrzeug besitzt ungefähr:

**1.000 Kapazität.**

Weitere Fahrzeuge werden größer und leistungsfähiger.

Die genauen Fahrzeugstufen werden später definiert.

Fahrzeuge sollen:

- funktional
- sauber modelliert
- glaubwürdig
- nicht übermäßig kompliziert

sein.

Der Spieler fährt die Fahrzeuge selbst.

Auch im Endgame bleibt der Spieler der Fahrer.

---

# 29. Fahrzeuggarage

Innerhalb der Firmenhalle befindet sich eine Garage.

Die Garage kommt in der Unternehmensentwicklung **vor dem Schmelzer**.

An der Garage befindet sich ein großes gläsernes automatisches Rolltor.

Im Inneren befindet sich ein leuchtender Ring.

Der Spieler betritt den Ring und öffnet die Fahrzeugauswahl.

Nach Auswahl eines eigenen Fahrzeugs:

- erscheint das Fahrzeug am vorgesehenen Spawnpunkt
- der Spieler sitzt direkt im Fahrzeug

Es gibt keine festen Parkplatz-Slots für jedes Fahrzeug.

Die Fahrzeugauswahl erfolgt über die Garage.

---

# 30. Fahrzeugbeladung

Fahrzeuge können mehrere Materialarten gleichzeitig transportieren.

Die Gesamtmenge ist durch die Fahrzeugkapazität begrenzt.

Beispiel:

`340 / 1.000`

Wenn das Fahrzeug in den Ladebereich fährt, öffnet sich automatisch eine Ladeoberfläche.

Der Spieler entscheidet, welche Materialien geladen werden.

Die konkrete technische Umsetzung wird später festgelegt.

---

# 31. Verkauf

Der Verkauf findet in der zentralen Verkaufszone statt.

Der Spieler kann:

- mit dem Fahrzeug verkaufen
- oder das Verkaufsgebäude betreten und am Verkaufsschalter verkaufen

Die Straße führt direkt am Verkaufsgebäude vorbei.

Beim Fahrzeugverkauf erscheint eine kompakte Bestätigungsoberfläche.

Beispiel:

**Sell Cargo — $18,450**

`[ SELL ]`

Der Verkauf gewährt:

- Geld
- Mining XP

Die XP richtet sich nach dem Material und ist nicht einfach an den Geldwert gekoppelt.

Es gibt keinen automatischen Verkauf direkt aus der Mine.

---

# 32. Laptop / Firmenverwaltung

Der Laptop befindet sich dauerhaft in der kleinen Blechhütte.

Beim Benutzen wird die Kamera kurz zum Laptop bewegt und anschließend die Management-Oberfläche geöffnet.

Der Laptop ist die zentrale Verwaltungsoberfläche des Unternehmens.

Geplante Bereiche:

- Overview
- Upgrades
- Storage
- Employees
- Production
- Vehicles
- Prestige

Die genaue Struktur wird in `09_UI_AND_LAPTOP.md` festgelegt.

---

# 33. Upgrades

Es gibt keinen separaten klassischen Upgrade Shop.

Levelbasierte Upgrades und Freischaltungen werden über den Laptop verwaltet.

Das Mining Level schaltet nach und nach neue Systeme frei.

Beispiele können sein:

- neue Minen
- bessere Ausrüstung
- neue Maschinen
- Förderbänder
- Fahrzeuge
- Produktionssysteme

Die konkreten Levelanforderungen werden später festgelegt.

---

# 34. Prestige / Rebirth

Bei **Mining Level 100** wird zunächst Prestige/Rebirth verfügbar.

Prestige setzt Teile des normalen Fortschritts zurück.

Dafür erhält der Spieler dauerhafte Vorteile, beispielsweise:

- permanente Multiplikatoren
- langfristige Fortschrittsboni

Prestige soll einen Neustart mit verbessertem langfristigem Fortschritt ermöglichen.

Mining Level 100 ist kein endgültiges Level-Limit.

Das System soll später auf deutlich höhere Levelbereiche erweitert werden können, beispielsweise bis Level 1.000.

Die genaue Reset-Liste und Bonusformel wird später festgelegt.

---

# 35. Multiplayer

Das Spiel ist multiplayerfähig.

Auf einem Server befinden sich mehrere Spieler mit eigenen Unternehmen.

Die aktuelle Zielgröße beträgt:

**6 Spieler-Grundstücke pro Server.**

Spieler können sich gegenseitig sehen.

Die Unternehmen sind voneinander getrennt.

Der eigentliche Fortschritt ist überwiegend individuell.

Es gibt keine zwingende Kooperation, um Fortschritt zu erzielen.

---

# 36. Trading

Spieler können grundsätzlich untereinander handeln.

Geplant sind insbesondere:

- Erze
- Drills

Das Trading-System muss serverseitig validiert sein.

Es darf keine Möglichkeit geben, durch Trading:

- Gegenstände zu duplizieren
- Geld zu duplizieren
- Inventare zu manipulieren
- Serverwerte vom Client aus zu fälschen

Die genaue Trade-Oberfläche und das Handelssystem werden separat spezifiziert.

---

# 37. Shops

Es gibt drei zentrale Shops.

## Equipment Shop

Verkauft:

- Spitzhacken
- Rucksäcke

Die Gegenstände werden physisch im Shop präsentiert.

Spitzhacken und Rucksäcke können über eine klassische Roblox-Shopoberfläche gekauft werden.

---

## Drill / Conveyor Shop

Verkauft:

- Drills
- Förderband-Systeme

Ein Teil der Maschinen wird sichtbar im Shop präsentiert.

Die eigentliche Auswahl erfolgt über eine übersichtliche UI.

---

## Vehicle Shop

Der Vehicle Shop zeigt echte Fahrzeugmodelle.

Der Kauf erfolgt über eine Shop-Oberfläche am Verkaufstresen.

Die Fahrzeuganzeige enthält unter anderem:

- Modell
- Kapazität
- Geschwindigkeit
- Preis
- Kaufmöglichkeit

---

# 38. Ausrüstung

Die beiden wichtigsten frühen Ausrüstungsarten sind:

## Spitzhacke

Beeinflusst:

- Mining Power
- Mining Speed

## Rucksack

Beeinflusst:

- Ore Capacity

Die genauen Werte und Ausrüstungsstufen werden in `08_PLAYER_EQUIPMENT.md` definiert.

---

# 39. Benutzeroberfläche

Die UI soll sich an hochwertigen klassischen Roblox-Spielen orientieren.

Sie soll:

- sauber
- übersichtlich
- modern
- leicht verständlich
- performant
- nicht überladen

sein.

Keine experimentelle oder unnötig komplizierte UI.

Grundlegende HUD-Positionen:

### Oben rechts
Geld

### Unten links
Rucksack / Kapazität

Beispiel:

`100 / 100 FULL`

### Unten Mitte
Mining Level + XP-Balken

Wichtige Ereignisse wie Level-Ups und Rare Drops dürfen kurzzeitig stärker hervorgehoben werden.

---

# 40. Seltene Drops – UI

Ein Rare Drop muss klar erkennbar sein.

Beispiel:

**RARE DROP! +1 Copper**

Mögliche Effekte:

- Glow
- Partikel
- Sound
- größere Floating-Anzeige

Der Effekt soll auffällig genug sein, aber nicht die gesamte Benutzeroberfläche blockieren.

---

# 41. Inventar

Das Inventar zeigt die bekannten Rohstoffe und Materialien in einer übersichtlichen Liste.

Jedes Material erhält ein eigenes Icon.

Auch noch nicht freigeschaltete Materialien können angezeigt werden, wenn dies für die Orientierung sinnvoll ist.

Gesperrte Materialien werden klar als gesperrt dargestellt.

Die UI soll nicht ausschließlich auf Farbcodes angewiesen sein.

---

# 42. Mine-Auswahl

Die Mine-Auswahl erfolgt über den Minenaufzug.

Der Spieler kann eine übersichtliche Liste der Minen öffnen.

Darstellung:

- Mine 01
- Mine 02
- Mine 03
- usw.

Die Auswahl zeigt unter anderem:

- Minennummer
- Erz
- freigeschaltet/gesperrt
- erforderliches Level
- erforderliches Geld

Die Auswahl soll sauber und schnell bedienbar sein.

Eine Anzeige der tatsächlichen Tiefe ist nicht erforderlich.

Die Minen werden über ihre Schachtnummer identifiziert.

---

# 43. Spielerfarbe und UI-Farben

Die Firmen-/Spielerfarbe kann in ausgewählten UI- und Unternehmensbereichen verwendet werden.

Zusätzlich gibt es eine feste semantische Farblogik:

- Grün = verfügbar / kaufen / erfolgreich
- Rot = Fehler / nicht genug Geld
- Gelb/Orange = Mining / Industrie / wichtige Aktion
- Blau = Information
- Grau = deaktiviert

Die genaue Farbpalette wird später in der UI-Spezifikation definiert.

---

# 44. Audio

Der Audiostil soll sauber, angenehm und spielerisch sein.

Keine übertrieben realistischen oder unangenehm lauten Industriegeräusche.

Geplant sind:

- entspannte Hintergrundmusik
- Mining-Sounds
- Maschinen-Sounds
- Elevator-Sounds
- Conveyor-Sounds
- Vehicle-Sounds
- Shop-/UI-Sounds
- Rare-Drop-Sound
- Level-Up-Sound

Maschinengeräusche sollen räumlich wirken.

Beispielsweise:

- beim Schmelzer hört man den Schmelzer
- beim Aufzug hört man den Aufzug
- im Büro ist es vergleichsweise ruhig

---

# 45. Visuelles Feedback

Maschinen besitzen sichtbare Betriebszustände.

Grundsätzlich:

- Grün = arbeitet
- Orange = wartet
- Rot = blockiert

Maschinen sollen nicht dauerhaft animieren, wenn sie nichts tun.

Das betrifft insbesondere:

- Drills
- Förderbänder
- Schmelzer
- andere Produktionsmaschinen

Dadurch wird der Produktionszustand auch ohne UI verständlich.

---

# 46. Zeit und Weltzustand

Die Welt ist grundsätzlich tagsüber.

Es soll keine komplexe Tag-/Nachtmechanik benötigt werden.

Die Beleuchtung soll:

- hell
- freundlich
- hochwertig
- atmosphärisch

sein.

Die Minen dürfen etwas dunkler wirken, müssen aber jederzeit gut spielbar bleiben.

---

# 47. Online- und Offline-Produktion

Das Unternehmen soll auch weiterarbeiten können, wenn der Spieler nicht aktiv im Spiel ist.

Für die erste Version gilt:

**Offline-Produktion maximal 1 Stunde.**

Dabei sollen Produktionssysteme nur so weit laufen, wie vorhandene Lager- und Produktionskapazitäten dies erlauben.

Es darf keine unendliche Offline-Produktion ohne Kapazitätsgrenzen geben.

Die genaue Berechnung wird später technisch spezifiziert.

---

# 48. Monetarisierung

Monetarisierung erfolgt ausschließlich über **Robux**.

Es sollen keine zusätzlichen Echtgeldwährungen eingeführt werden.

Die Monetarisierung soll nicht das gesamte Spiel zu Pay-to-Win machen.

Mögliche spätere Bereiche:

- VIP
- kosmetische Inhalte
- zusätzliche Komfortfunktionen
- optionale temporäre Boosts
- besondere Effekte

Die konkreten Produkte werden erst nach Fertigstellung der Kernsysteme definiert.

Pets und Egg-Systeme gehören ausdrücklich nicht zum Spiel.

---

# 49. Performance als Designanforderung

Performance muss bereits beim Design berücksichtigt werden.

Das Spiel soll nicht durch:

- tausende einzelne Erzobjekte
- unnötige Partikel
- unnötige permanente Loops
- unnötige NPC-Bewegungen
- unkontrollierte RemoteEvents
- übermäßig viele Parts

belastet werden.

Die sichtbare Welt darf hochwertig aussehen, muss aber technisch effizient aufgebaut sein.

Die detaillierte technische Performance-Spezifikation wird in `18_PERFORMANCE.md` definiert.

---

# 50. Sicherheitsprinzip

Alle wichtigen Spielwerte müssen serverautoritativ sein.

Der Client darf nicht selbst bestimmen:

- wie viel Erz er erhält
- wie viel Geld er bekommt
- wie viel XP er erhält
- ob ein Mining-Hit gültig ist
- ob ein Gegenstand gekauft wurde
- welche Items er besitzt
- ob ein Fahrzeug ihm gehört
- ob ein Trade gültig ist

Der Client darf Aktionen anfordern.

Der Server entscheidet, ob die Aktion gültig ist.

Die vollständige Sicherheitsarchitektur wird in `17_SECURITY_AND_ANTI_EXPLOIT.md` definiert.

---

# 51. Technisches Grundprinzip

Das Spiel soll modular aufgebaut werden.

Keine riesigen Monolith-Skripte.

Systeme sollen voneinander getrennt und möglichst wiederverwendbar sein.

Besonders wichtig:

- Mining
- Inventory
- Equipment
- Mines
- Workers
- Drills
- Storage
- Production
- Vehicles
- Selling
- Economy
- Player Data
- UI
- Trading
- Prestige

sollen klar getrennte Verantwortlichkeiten besitzen.

Balancing-Werte müssen möglichst datengetrieben und leicht veränderbar sein.

---

# 52. Entwicklungsprinzip

Das Spiel wird nicht als ein einziger großer Schritt gebaut.

Die Entwicklung erfolgt schrittweise.

Jede Phase muss:

1. implementiert
2. getestet
3. auf Fehler geprüft
4. auf Performance geprüft
5. auf Exploit-Sicherheit geprüft

werden, bevor die nächste große Phase beginnt.

Claude darf keine unfertigen Dummy-Systeme als fertige Features behandeln.

Keine versteckten TODOs anstelle funktionierender Kernsysteme.

Keine Fake-Buttons ohne tatsächliche Funktion.

---

# 53. Qualitätsziel

Das Spiel soll sich wie ein vollständig geplantes, hochwertiges Roblox-Spiel anfühlen.

Wichtige Qualitätsmerkmale:

- klare Progression
- verständliche Systeme
- sichtbarer Unternehmensfortschritt
- saubere UI
- gute Animationen
- sinnvolle Sounds
- funktionierende Produktionsketten
- stabile Daten
- serverseitige Sicherheit
- gute Performance
- klare visuelle Hierarchie
- keine unnötige Komplexität

---

# 54. Das langfristige Spielerlebnis

Das wichtigste langfristige Ziel ist die Entwicklung des eigenen Unternehmens.

Der Spieler soll den Unterschied zwischen Start und Endgame deutlich sehen.

### Start

Ein einzelner Miner mit:

- Spitzhacke
- kleinem Rucksack
- kleiner Blechhütte
- leerer Fabrikhalle

### Fortschritt

Der Spieler besitzt:

- bessere Ausrüstung
- neue Minen
- Mitarbeiter
- Drills
- Lager
- Förderbänder
- Schmelzer
- Fahrzeuge

### Endgame

Der Spieler besitzt:

- ein vollständig eingerichtetes Bergbauunternehmen
- mehrere automatisierte Minen
- große Produktionskapazitäten
- mehrere Fahrzeuge
- fortgeschrittene Produktionsketten
- hohe Mining-Level
- Prestige-Fortschritt

Trotz der Automatisierung bleibt der Spieler selbst Teil des Unternehmens.

---

# 55. Wichtigste Designprinzipien

Die folgenden Prinzipien sind für die gesamte Entwicklung verbindlich:

1. **Der Spieler startet klein.**
2. **Der Fortschritt soll sichtbar sein.**
3. **Automatisierung soll physisch in der Welt sichtbar sein.**
4. **Das Spiel soll kein einfacher Clicker sein.**
5. **Der Spieler soll auch im Endgame aktiv bleiben.**
6. **Die Produktionskette muss logisch nachvollziehbar sein.**
7. **Die Fabrikhalle bleibt grundsätzlich dieselbe und wird schrittweise eingerichtet.**
8. **Die kleine Blechhütte bleibt dauerhaft erhalten.**
9. **Das Grundstück hat eine feste Größe.**
10. **Die Minen sind unendlich und werden nicht dauerhaft zerstört.**
11. **Worker und Drills teilen sich feste Mining-Slots.**
12. **Es gibt keine Pets.**
13. **Es gibt keinen separaten Upgrade Shop.**
14. **Das Mining Level steuert die Progression.**
15. **XP gibt es durch Verkauf.**
16. **Rare Drops entstehen nur beim manuellen Mining.**
17. **Rohstoffe und verarbeitete Materialien können verkauft werden.**
18. **Der Spieler fährt seine Fahrzeuge selbst.**
19. **Die Welt soll sauber und organisiert bleiben.**
20. **Serverautorität hat Vorrang bei allen wichtigen Spielwerten.**
21. **Performance muss von Anfang an berücksichtigt werden.**
22. **Balancing muss datengetrieben und leicht veränderbar sein.**
23. **Keine unnötigen Systeme oder Features nur wegen zusätzlicher Komplexität.**
24. **Die Entwicklung erfolgt kontrolliert in einzelnen Phasen.**
25. **Das Spiel soll eigenständig wirken und nicht als bloße Kopie eines bestehenden Spiels erscheinen.**

---

# 56. Verhältnis zu bestehenden Spielen

Das Spiel darf sich bei allgemeinen Genre-Konzepten wie:

- Mining
- Tycoon
- Progression
- Automatisierung
- Prestige
- Produktionsketten

orientieren.

Es soll jedoch **keine direkte Kopie eines bestehenden Spiels** werden.

Insbesondere sollen nicht einfach:

- Namen
- Assets
- konkrete UI
- konkrete Karten
- konkrete Systeme
- konkrete Designs
- konkrete Inhalte

eines bestehenden Spiels übernommen werden.

Die grundlegende Inspiration darf erkennbar aus dem Mining-/Tycoon-Genre stammen, aber das Spiel muss eine eigene Identität besitzen.

---

# 57. Dokumentenstruktur

Dieses Dokument definiert die grundlegende Spielidee.

Folgende Bereiche werden in separaten Dokumenten genauer spezifiziert:

- `02_GAMEPLAY_PROGRESSION.md`
- `03_MINING_AND_ORES.md`
- `04_TYCOON_AND_BUILDINGS.md`
- `05_WORKERS_AND_DRILLS.md`
- `06_STORAGE_AND_PRODUCTION.md`
- `07_VEHICLES_AND_SELLING.md`
- `08_PLAYER_EQUIPMENT.md`
- `09_UI_AND_LAPTOP.md`
- `10_MAP_AND_WORLD.md`
- `11_ECONOMY_AND_BALANCE.md`
- `12_PRESTIGE_AND_ENDGAME.md`
- `13_TRADING.md`
- `14_MONETIZATION.md`
- `15_AUDIO_VFX_ANIMATION.md`
- `16_TECHNICAL_ARCHITECTURE.md`
- `17_SECURITY_AND_ANTI_EXPLOIT.md`
- `18_PERFORMANCE.md`

Diese Dokumente sollen gemeinsam die vollständige technische und spielerische Spezifikation bilden.

---

# 58. Verbindlichkeit

Dieses Dokument ist eine **Designgrundlage**, keine vollständige technische Implementierungsanweisung.

Wenn konkrete Werte oder technische Details noch nicht entschieden wurden, darf Claude diese nicht einfach dauerhaft festlegen.

Stattdessen müssen solche Werte:

- in einer zentralen Konfiguration liegen
- leicht geändert werden können
- später durch Balancing angepasst werden können

Unklare Designentscheidungen dürfen nicht durch zufällige Annahmen festgeschrieben werden, wenn sie das Spielerlebnis wesentlich verändern würden.
