# 07 – VEHICLES AND SELLING

## 1. Zweck dieses Dokuments

Dieses Dokument definiert Fahrzeuge, Garage, Fahrzeuginventare, Beladung, Fahrverhalten und den Verkauf von Materialien.

Fahrzeuge sind kein rein kosmetisches System. Sie bilden einen aktiven Teil der Firmenlogistik:

**Firmenlager → Fahrzeug → Verkaufsgebäude → Geld + Mining XP**

Der Spieler fährt seine Fahrzeuge immer selbst. Auch im Endgame gibt es zunächst keine NPC-Fahrer und keinen automatischen Verkauf.

---

# 2. Grundprinzip

Sobald die Garage und das erste Fahrzeug freigeschaltet wurden, kann der Spieler Materialien aus seiner Firma zur Verkaufsstelle transportieren.

Ablauf:

1. Fahrzeug in der Garage auswählen.
2. Fahrzeug spawnt.
3. Spieler sitzt direkt auf dem Fahrersitz.
4. Spieler fährt zum Ladebereich.
5. Materialien werden aus dem Firmenlager ins Fahrzeug geladen.
6. Spieler fährt über die Straße zur Verkaufsstelle.
7. Spieler verkauft die Ladung.
8. Geld und Mining XP werden serverseitig gutgeschrieben.
9. Spieler fährt zurück zur Firma.

Dieser Loop bleibt auch im späteren Spiel relevant.

---

# 3. Garage

Die Garage befindet sich innerhalb der großen Fabrikhalle.

Sie wird nach dem grundlegenden Lagersystem und vor dem Schmelzer freigeschaltet.

Die Garage besitzt:

- großes automatisches Glas-Rolltor
- festen Fahrzeug-Spawn-Bereich
- leuchtenden Auswahlring
- saubere industrielle Gestaltung
- dezente Akzente in der Firmenfarbe

---

# 4. Fahrzeugauswahl

Der Spieler betritt den leuchtenden Ring in der Garage.

Daraufhin öffnet sich die Fahrzeugauswahl.

Dort werden nur Fahrzeuge angezeigt, die der Spieler tatsächlich besitzt bzw. kaufen kann.

Nach Auswahl eines eigenen Fahrzeugs:

1. vorhandenes aktives Fahrzeug wird sauber behandelt/despawnt
2. ausgewähltes Fahrzeug erscheint am vorgesehenen Spawnpunkt
3. Spieler wird direkt auf den Fahrersitz gesetzt

> **Entscheidung D-016 (ersetzt die frühere Regel „keine Sammlung“):** Bis zu **2 Fahrzeuge** eines Spielers können gleichzeitig in der Halle stehen (geparkt bzw. ausgeparkt). Alle weiteren gekauften Fahrzeuge sind eingelagert und werden über den Spawn-Ring ausgeparkt; dabei muss eines der beiden stehenden Fahrzeuge eingeparkt werden. Ladung bleibt je Fahrzeug erhalten (D-009).

---

# 5. Fahrzeugshop

Fahrzeuge werden in einem eigenen Fahrzeugladen in der zentralen Bergbaustadt gekauft.

Im Shop können einige Fahrzeuge sichtbar ausgestellt sein.

Da später viele Fahrzeuge existieren können, erfolgt der eigentliche Kauf über ein sauberes Verkaufs-UI.

Der Shop darf nicht davon abhängig sein, jedes kaufbare Fahrzeug gleichzeitig physisch auszustellen.

---

# 6. Fahrzeugprogression

Fahrzeuge sollen relativ früh in der Gesamtprogression beginnen.

Das erste Fahrzeug ist ein kleiner, sauberer Firmenwagen bzw. Utility-Transporter.

Spätere Stufen entwickeln sich in Richtung:

- Pickup
- Van / Utility Van
- kleiner Transport-LKW
- mittlerer LKW
- großer Mining-/Cargo-Truck

Die Fahrzeuge sollen wie echte, hochwertige, stilisierte Fahrzeuge wirken und nicht wie übertriebene Fantasy-Autos.

---

# 7. Fahrzeugkapazität

Jedes Fahrzeug besitzt ein eigenes Inventar.

Das erste Fahrzeug startet nach aktuellem Design mit:

**1.000 Einheiten Kapazität**

Spätere Fahrzeuge besitzen größere Kapazitäten.

Die genaue Progressionskurve wird später gebalanced.

Beispiel:

```text
Starter Vehicle
Capacity: 1,000

Vehicle 2
Capacity: higher

Vehicle 3
Capacity: higher
```

Keine finalen Werte aus Platzhalterbeispielen ableiten.

---

# 8. Mehrere Materialien im Fahrzeug

Ein Fahrzeug kann mehrere Materialarten gleichzeitig transportieren.

Beispiel:

```text
Vehicle Inventory

Coal        400
Copper      250
Iron Bar    150

Total:
800 / 1000
```

Die Gesamtsumme aller Materialien darf die Fahrzeugkapazität nicht überschreiten.

---

# 9. Beladung

Der Spieler fährt in den vorgesehenen Ladebereich seiner Fabrik.

Dort kann er auswählen, welche Materialien aus dem Firmenlager in das Fahrzeug geladen werden.

Das System zeigt:

- Material
- verfügbaren Lagerbestand
- Fahrzeugbestand
- verbleibende Fahrzeugkapazität

---

# 10. Beladungs-UI

Beispiel:

```text
LOAD VEHICLE

Capacity
340 / 1000

Coal
Storage: 1,240
[ LOAD ]

Copper
Storage: 620
[ LOAD ]

Iron Bar
Storage: 180
[ LOAD ]
```

Die finale Gestaltung wird in `09_UI_AND_LAPTOP.md` festgelegt.

---

# 11. Sichere Materialtransfers

Beladung ist ein serverautoritärer Transfer.

Beispiel:

```text
Company Storage: -100 Coal
Vehicle Inventory: +100 Coal
```

Beide Änderungen müssen als zusammengehörige Aktion behandelt werden.

Nicht zulässig:

- Client bestimmt beliebige Mengen
- Beladung über Fahrzeugkapazität
- Beladung von nicht vorhandenen Materialien
- Duplikation durch Spam
- Duplikation durch Fahrzeug-Despawn
- Duplikation durch Verlassen des Servers

---

# 12. Fahrzeug-Inventar beim Despawn

Material darf nicht verschwinden oder dupliziert werden, wenn ein Fahrzeug despawnt.

Die wirtschaftliche Ladung gehört zum gespeicherten Fahrzeug-/Spielerdatensatz und nicht ausschließlich zu sichtbaren Parts im Workspace.

Die endgültige Regel für absichtliches Wechseln eines beladenen Fahrzeugs soll sicher und verständlich sein.

Empfohlene Grundregel:

- beladenes Fahrzeug kann nicht stillschweigend durch ein anderes ersetzt werden
- UI warnt den Spieler
- Ladung bleibt sicher erhalten bzw. muss vorher entladen werden

---

# 13. Fahrverhalten

Fahrzeuge sollen sich relativ realistisch und kontrolliert fahren.

Ziel:

- nicht schwammig
- nicht arcadeartig überempfindlich
- nachvollziehbare Beschleunigung
- nachvollziehbares Bremsen
- stabile Kurven
- ausreichend Bodenhaftung
- keine unnötigen Überschläge

Das Fahrgefühl soll zugänglich bleiben und keine Hardcore-Fahrsimulation werden.

---

# 14. Geschwindigkeit

Fahrzeuge dürfen sich in Geschwindigkeit unterscheiden.

Kapazität ist jedoch der wichtigste Progressionswert.

Spätere große LKWs sollen nicht automatisch viel schneller sein als kleine Fahrzeuge.

Große Fahrzeuge dürfen:

- langsamer beschleunigen
- schwerer wirken
- größeren Wendekreis besitzen
- dafür deutlich mehr Material transportieren

---

# 15. Fahrzeugkamera

Die normale freie Roblox-Kamera bleibt erhalten.

Das Fahrzeug darf sinnvolle Kameraunterstützung verwenden, soll den Spieler aber nicht in eine starre Spezialkamera zwingen.

---

# 16. Fahrzeugkollisionen

Spielerfahrzeuge sollen sich **nicht gegenseitig physisch blockieren**.

Zwischen Fahrzeugen verschiedener Spieler wird keine störende Kollision verwendet.

Ziel:

- kein Trolling durch Straßenblockaden
- kein absichtliches Einklemmen
- keine Fahrzeugstaus durch andere Spieler

Fahrzeuge müssen weiterhin sinnvoll mit Straße und Umgebung interagieren.

---

# 17. Spieler und fremde Fahrzeuge

Andere Spieler dürfen ein fremdes Firmenfahrzeug nicht einfach übernehmen.

Besitz und Fahrberechtigung müssen serverseitig geprüft werden.

Handelbare Fahrzeugrechte sind zunächst nicht vorgesehen.

---

# 18. Garage – Spawn-Sicherheit

Beim Spawnen eines Fahrzeugs muss geprüft werden:

- Fahrzeug gehört dem Spieler
- Fahrzeug ist freigeschaltet
- Spawnposition ist gültig
- kein zweites aktives Fahrzeug wird dupliziert

Das System darf nicht durch Remote-Spam mehrere identische Fahrzeuge erzeugen.

---

# 19. Automatisches Garagentor

Das Glas-Rolltor öffnet automatisch, wenn das eigene Fahrzeug oder der Spieler sich dem vorgesehenen Bereich nähert.

Es muss:

- rechtzeitig öffnen
- ausreichend lange offen bleiben
- Fahrzeuge nicht einklemmen
- danach sauber schließen

Die Türlogik darf nicht auf permanentem unnötigem Frame-Polling basieren.

---

# 20. Straßen

Jedes Grundstück besitzt eine direkte Zufahrt zur zentralen Straße.

Die Hauptstraße verbindet:

- Spielergrundstücke
- Bergbaustadt
- Fahrzeugshop
- Equipment-Shop
- Maschinen-/Drill-Shop
- Verkaufsgebäude

Die Straße muss am Verkaufsgebäude direkt vorbeiführen.

---

# 21. Verkauf

Material wird nicht automatisch aus dem Firmenlager verkauft.

Der Spieler muss seine Ware tatsächlich zur Verkaufsstelle bringen.

Das bleibt auch im Endgame so.

Es gibt zunächst:

- keine NPC-Fahrer
- keinen automatischen LKW-Verkauf
- keinen passiven Sofortverkauf aus dem Lager

---

# 22. Verkaufsgebäude

Die zentrale Verkaufsstelle ist ein richtiges Gebäude in der Bergbaustadt.

Sie besitzt:

- Straßenanbindung
- Fahrzeug-Verkaufszone
- Eingang für Spieler
- Verkaufstresen im Inneren
- saubere Mining-/Industrieoptik

---

# 23. Zwei Verkaufswege

Der Spieler kann auf zwei Arten verkaufen.

## Variante A – aus dem Fahrzeug

Der Spieler fährt mit dem Fahrzeug in die vorgesehene Verkaufszone.

Dort kann die Fahrzeugladung verkauft werden.

## Variante B – im Gebäude

Der Spieler kann das Gebäude betreten und am Verkaufstresen Materialien verkaufen.

Dies unterstützt insbesondere frühes Gameplay ohne Fahrzeug.

---

# 24. Frühes Verkaufen ohne Fahrzeug

Vor Freischaltung der Garage transportiert der Spieler Material über seinen Rucksack bzw. die frühen vorgesehenen Systeme.

Er geht zur Verkaufsstelle und verkauft am Tresen.

Dadurch ist der Verkauf von der ersten Spielminute an möglich.

---

# 25. Verkauf aus dem Fahrzeug

Beim Einfahren in die Verkaufszone erkennt das System:

- Besitzer
- Fahrzeug
- Ladung
- verkaufbare Materialien

Der Spieler bestätigt den Verkauf.

Material wird nicht automatisch ohne Bestätigung gelöscht.

---

# 26. Verkaufsberechnung

Beim Verkauf berechnet der Server:

```text
Materialmenge
×
aktueller Materialwert
=
Geld
```

Zusätzlich erhält der Spieler Mining XP.

Wichtig:

**Geldwert und XP-Wert sind getrennte Daten.**

Ein Erz kann viel XP geben, ohne dass XP direkt aus dem Verkaufspreis berechnet wird.

---

# 27. Mining XP

Mining XP wird ausschließlich beim Verkauf vergeben.

Nicht beim:

- Abbauen
- Transportieren
- Lagern
- Schmelzen
- Beladen

Erst der erfolgreiche Verkauf erzeugt XP.

---

# 28. Verkauf verarbeiteter Materialien

Verarbeitete Materialien können ebenfalls verkauft werden.

Sie besitzen grundsätzlich einen höheren wirtschaftlichen Wert als ihre Rohmaterialien.

Die XP-Werte können unabhängig davon konfiguriert werden.

---

# 29. Verkaufsanimation

Der Verkauf erhält eine kurze, cleane Rückmeldung.

Beispiel:

```text
SOLD

+ $12,450
+ 820 Mining XP
```

Zusätzlich:

- kurzer Sound
- kleine UI-Animation
- XP-Bar bewegt sich
- Geldanzeige aktualisiert sich

Keine unnötig lange Animation.

---

# 30. Fahrzeug wird nach Verkauf leer

Nach erfolgreichem vollständigem Verkauf werden die verkauften Materialien aus dem Fahrzeugbestand entfernt.

Beispiel:

```text
Before:
Coal 400
Copper 250

Sell All

After:
Empty
0 / 1000
```

Teilverkauf kann später unterstützt werden.

---

# 31. Sell All

Für eine angenehme Bedienung soll eine klare Option existieren:

**SELL ALL**

Damit verkauft der Spieler alle aktuell verkaufbaren Materialien im gewählten Inventar/Fahrzeug.

Bei wertvollen oder später besonderen Gegenständen kann das System künftig Ausnahmen unterstützen.

---

# 32. Kein dynamischer Markt in Version 1

In der ersten Version besitzt jedes Erz einen festen Basispreis.

Es gibt zunächst keinen steigenden und fallenden Rohstoffmarkt.

Das System soll jedoch so datengetrieben gebaut werden, dass später ein dynamischer Markt ergänzt werden kann.

Später denkbar:

- Marktpreise steigen/fallen
- Spieler lagert Material
- Verkauf zum günstigen Zeitpunkt

Diese Mechanik ist ausdrücklich **nicht Teil der ersten Kernversion**.

---

# 33. Fahrzeugshop – UI

Der Fahrzeugshop zeigt für jedes Fahrzeug mindestens:

- Name
- Vorschau
- Preis
- Kapazität
- Geschwindigkeit
- erforderliches Mining Level
- Besitzstatus

Beispiel:

```text
UTILITY PICKUP

Capacity: 1,000
Speed: 72
Required Level: ...
Price: $...

[ BUY ]
```

Die Zahlen sind Beispiele.

---

# 34. Fahrzeugvorschau

Fahrzeuge sollen im Shop hochwertig dargestellt werden.

Mögliche Umsetzung:

- ViewportFrame
- rotierbare Vorschau
- saubere Beleuchtung
- wenige physische Showroom-Fahrzeuge als Dekoration

Nicht jedes Fahrzeug muss physisch im Laden stehen.

---

# 35. Fahrzeugstil

Fahrzeuge sollen:

- clean
- hochwertig
- leicht stilisiert
- glaubwürdig
- zur Roblox-Welt passend

sein.

Zu vermeiden:

- extreme Cartoon-Proportionen
- unnötige Neon-Überladung
- futuristische Supersportwagen ohne Bezug zum Mining-Unternehmen

Die Fahrzeugprogression soll wie ein wachsender Firmenfuhrpark wirken.

---

# 36. Firmenfarbe an Fahrzeugen

Die Firmenfarbe darf dezent auf Fahrzeugen erscheinen.

Beispiele:

- kleiner Seitenstreifen
- Firmenlogo
- Türbeschriftung
- kleine Akzentfläche

Das komplette Fahrzeug soll nicht zwingend in einer grellen Firmenfarbe lackiert werden.

---

# 37. Firmenname auf Fahrzeugen

Spätere Fahrzeuge können den Firmennamen oder das Firmenlogo tragen.

Beispiel:

```text
FELIX MINING CO.
```

Die Darstellung muss gegen ungeeignete benutzerdefinierte Texte abgesichert werden und Roblox-Textfilterregeln beachten.

---

# 38. Fahrzeugzustände

Ein Fahrzeug besitzt mindestens:

```text
Stored
Spawning
Active
Loading
Driving
Selling
Despawned
```

Wirtschaftliche Aktionen müssen nur in gültigen Zuständen erlaubt sein.

---

# 39. Respawn / Reset

Wenn ein Fahrzeug feststeckt, soll der Spieler es kontrolliert zurücksetzen können.

Ein Reset darf:

- Ladung nicht duplizieren
- Ladung nicht grundlos löschen
- kein zweites Fahrzeug erzeugen

Das Fahrzeug kann beispielsweise sicher zur Garage zurückgesetzt werden.

---

# 40. Verlassen des Servers

Wenn der Spieler den Server verlässt:

- Fahrzeugzustand wird sauber verarbeitet
- Fahrzeugbestand/Ladung bleibt gespeichert
- sichtbares Fahrzeug wird entfernt
- kein Material wird doppelt gutgeschrieben

Beim nächsten Beitritt kann der gespeicherte Zustand sicher rekonstruiert werden.

---

# 41. Handel

Spieler sollen später untereinander handeln können.

Geplant sind insbesondere:

- Erze
- Drills

Das Fahrzeugverkaufs- und Inventarsystem darf deshalb nicht so gebaut werden, dass Material ausschließlich als lokale Fahrzeugobjekte existiert.

Das eigentliche Trading-System wird separat spezifiziert.

---

# 42. Keine NPC-Fahrer

Diese Regel ist verbindlich:

**Der Spieler fährt seine Verkaufsfahrzeuge selbst.**

Auch im Endgame wird der Verkaufsweg nicht vollständig durch NPC-Fahrer ersetzt.

Das aktive Fahren ist ein bewusstes Gameplay-Element.

---

# 43. Kein Fahrzeug-Autopilot

In der ersten Kernversion gibt es keinen Autopilot zur Verkaufsstelle.

Fahrzeuge werden manuell gesteuert.

Spätere Komfortsysteme dürfen nur nach bewusster Designänderung ergänzt werden.

---

# 44. Performance

Fahrzeuge müssen performant umgesetzt werden.

Zu vermeiden:

- unnötig komplexe Physikmodelle
- hunderte bewegliche Einzelteile
- permanente Serverberechnung unwichtiger visueller Details
- physische Erzobjekte als Fahrzeugladung

Die Ladung wird datenbasiert gespeichert.

Eine sichtbare Ladung kann bei Bedarf kosmetisch dargestellt werden.

---

# 45. Serverautorität

Der Server kontrolliert mindestens:

- Fahrzeugbesitz
- Kauf
- Spawn-Berechtigung
- Fahrzeugladung
- Kapazität
- Materialtransfer
- Verkauf
- Geldbelohnung
- XP-Belohnung

Der Client steuert primär:

- Eingabe
- Kamera
- UI-Anfragen
- lokale visuelle Rückmeldung

---

# 46. Anti-Exploit-Regeln

Der Server muss verhindern:

- Verkauf nicht vorhandener Erze
- Verkauf fremder Fahrzeugladung
- negative Materialmengen
- Beladung über Kapazität
- Kauf ohne Geld
- Kauf ohne Levelanforderung
- mehrfaches Spawnen desselben Fahrzeugs
- mehrfaches Auslösen derselben Verkaufstransaktion
- manipulierte Verkaufspreise vom Client

---

# 47. Datenstruktur

Beispielhafte Fahrzeugdefinition:

```lua
VehicleDefinitions = {
    StarterUtility = {
        DisplayName = "Utility Pickup",
        Capacity = 1000,
        MaxSpeed = 0, -- später balancen
        Price = 0, -- später balancen
        RequiredLevel = 0, -- später balancen
    },
}
```

Die Nullwerte sind Platzhalter.

Claude darf daraus keine finalen Werte ableiten.

---

# 48. Fahrzeugdaten des Spielers

Gespeichert werden mindestens:

```text
OwnedVehicles
SelectedVehicle
VehicleCargo
```

Je nach finaler Architektur kann Cargo an das aktive Fahrzeugmodell oder an die jeweilige Fahrzeug-ID gebunden werden.

> **Entscheidung D-009:** Cargo gehört zur jeweiligen Fahrzeug-ID und bleibt dort gespeichert. Ein Fahrzeugwechsel ist auch mit Ladung erlaubt; das alte Fahrzeug despawnt mit seiner Ladung, nichts geht verloren.

---

# 49. Spätere Erweiterbarkeit

Das System soll später ermöglichen:

- mehr Fahrzeuge
- größere LKWs
- weitere Fahrzeugklassen
- kosmetische Varianten
- dynamische Marktpreise
- zusätzliche Verkaufsorte
- besondere Transportaufträge

Diese Systeme sind noch nicht Teil der ersten Kernversion.

---

# 50. Noch offene Balancingwerte

Später festzulegen:

- Fahrzeugpreise
- Mining-Level-Anforderungen
- Kapazitäten nach dem Starterfahrzeug
- Maximalgeschwindigkeiten
- Beschleunigung
- Bremskraft
- Wendekreise
- Ladegeschwindigkeit
- konkrete XP-Werte
- Verkaufswerte
- genaue Anzahl der Fahrzeuge zum Release

Alle Werte müssen zentral konfigurierbar bleiben.

---

# 51. Verbindliche Regeln

1. Garage kommt nach dem Lager und vor dem Schmelzer.
2. Fahrzeuge sind ein echtes Logistiksystem und nicht nur kosmetisch.
3. Fahrzeugauswahl erfolgt über den leuchtenden Ring in der Garage.
4. Nach Fahrzeugauswahl spawnt der Spieler direkt im Fahrzeug.
5. Erstes Fahrzeug besitzt aktuell 1.000 Kapazität.
6. Spätere Fahrzeuge besitzen höhere Kapazitäten.
7. Fahrzeug kann mehrere Materialien gleichzeitig enthalten.
8. Fahrzeug besitzt ein eigenes Inventar.
9. Spieler entscheidet, welche Materialien geladen werden.
10. Spieler fährt immer selbst.
11. Keine NPC-Fahrer.
12. Kein Autopilot in Version 1.
13. Fahrzeuge sollen kontrolliert und relativ realistisch fahren.
14. Große Fahrzeuge müssen nicht schneller als kleine Fahrzeuge sein.
15. Fahrzeuge verschiedener Spieler blockieren sich nicht gegenseitig.
16. Fremde Spieler können Fahrzeuge nicht einfach übernehmen.
17. Straße führt direkt am Verkaufsgebäude vorbei.
18. Verkauf ist im Gebäude und aus dem Fahrzeug möglich.
19. Frühe Spieler können ohne Fahrzeug am Tresen verkaufen.
20. Material wird nicht automatisch aus dem Firmenlager verkauft.
21. Mining XP gibt es ausschließlich beim Verkauf.
22. Geldwert und XP-Wert bleiben getrennt.
23. Rohstoffe und verarbeitete Materialien sind verkaufbar.
24. `SELL ALL` soll unterstützt werden.
25. Verkauf erzeugt kurze, cleane UI-Rückmeldung.
26. Feste Erzpreise in Version 1.
27. Dynamischer Rohstoffmarkt wird nur für später vorbereitet.
28. Fahrzeugladung wird datenbasiert und serverseitig gespeichert.
29. Fahrzeugreset darf keine Ladung duplizieren oder löschen.
30. Alle wirtschaftlich relevanten Fahrzeugaktionen werden serverseitig validiert.
