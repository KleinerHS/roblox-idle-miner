# 09 – UI AND LAPTOP

## 1. Zweck dieses Dokuments

Dieses Dokument definiert die grundlegende Benutzeroberfläche des Spiels.

Ziel ist eine einheitliche UI-Sprache für:

- Main HUD
- Mining Level
- Geld
- Rucksack / Inventar
- Mining-Feedback
- Rare Drops
- Laptop
- Mitarbeiterverwaltung
- Storage
- Elevator-Upgrades
- Produktion
- Mine-Auswahl
- Shops
- Garage / Fahrzeuge
- Loading / Selling
- Benachrichtigungen

Die UI soll wie ein hochwertiges modernes Roblox-Spiel wirken: **clean, verständlich, angenehm und leicht „gamer“-orientiert**, ohne mit Neon, Animationen oder Fenstern überladen zu sein.

---

# 2. Design-Grundsatz

Die UI muss Informationen priorisieren.

Nicht alles wird permanent angezeigt.

Es gibt drei Ebenen:

## Ebene A – dauerhaftes HUD

Nur Informationen, die während fast jeder Spielsituation wichtig sind.

## Ebene B – kleine Kontextfenster

Erscheinen nur bei relevanten Aktionen.

## Ebene C – vollständige Menüs

Laptop, Shops, Garage, Mine-Auswahl usw.

Dadurch bleibt der Bildschirm beim normalen Spielen frei.

---

# 3. Visueller Stil

Gewünschter Stil:

**modern Roblox + clean gamer UI + Mining/Industrial accents**

Eigenschaften:

- klare Formen
- leicht abgerundete Ecken
- hochwertige Icons
- gute Abstände
- klare Typografie
- dezente Schatten
- dezente Verläufe nur wo sinnvoll
- kurze Animationen
- angenehme, nicht aggressive Farben

Nicht gewünscht:

- riesige Neonflächen
- übermäßig viele Outlines
- blinkende Buttons überall
- billige Simulator-UI
- zehn Währungen gleichzeitig im HUD
- permanent aufspringende Popups

---

# 4. Firmenfarbe in der UI

Die Firmenfarbe des Spielers darf als Akzent verwendet werden.

Beispiele:

- aktive Tabs
- kleine Linien
- Progress-Balken
- ausgewählte Elemente
- Garage-UI-Akzente

Die Firmenfarbe darf nicht die komplette UI unlesbar machen.

Hintergründe bleiben überwiegend neutral.

---

# 5. Responsive UI

Die UI muss mit Roblox `UIScale`, Constraints und responsiven Layouts gebaut werden.

Sie darf nicht ausschließlich für eine einzelne Desktop-Auflösung entwickelt werden.

Unterstützt werden sollen mindestens:

- Desktop
- Laptop
- übliche Bildschirmauflösungen
- spätere mobile Anpassung

Desktop ist für die erste Umsetzung die primäre Referenz.

---

# 6. Safe Areas

Wichtige UI-Elemente dürfen nicht:

- Roblox-Core-UI überdecken
- außerhalb des sichtbaren Bereichs liegen
- bei anderen Seitenverhältnissen abgeschnitten werden

Layouts sollen mit:

- UIListLayout
- UIPadding
- UIAspectRatioConstraint
- UISizeConstraint

und vergleichbaren Roblox-UI-Werkzeugen sauber aufgebaut werden.

---

# 7. Main HUD

Das Main HUD bleibt bewusst klein.

Permanent sichtbar sind mindestens:

- Geld
- Mining Level
- Mining-XP-Fortschritt
- Rucksack-/Inventarstatus, wenn relevant

Der Spieler soll beim normalen Herumlaufen nicht von Menüs verdeckt werden.

---

# 8. Mining Level – Position

Das Mining Level wird dauerhaft **unten in der Mitte** angezeigt.

Dies ist eine verbindliche Designentscheidung.

Beispiel:

```text
                MINING LEVEL 18
          ███████████░░░░░  64%
```

Es soll direkt sichtbar sein, ohne dominant zu wirken.

---

# 9. Mining-XP-Anzeige

Unter oder innerhalb der Levelanzeige befindet sich eine XP-Bar.

Sie zeigt:

- aktuelles Mining Level
- Fortschritt zum nächsten Level

Optional beim Hover / Zusatzfenster:

```text
Mining Level 18
8,420 / 12,000 XP
```

XP wird erst beim Verkauf gutgeschrieben.

---

# 10. Level-Up

Beim Level-Up erhält der Spieler eine kurze, saubere Animation.

Beispiel:

```text
LEVEL UP!

Mining Level 19
```

Zusätzlich können neue Freischaltungen angezeigt werden:

```text
UNLOCKED
New Pickaxe
```

oder:

```text
UNLOCKED
Mine 10
```

Die Animation soll kurz bleiben.

---

# 11. Geldanzeige

Geld wird dauerhaft gut sichtbar angezeigt.

Die genaue Position wird später im HUD-Mockup festgelegt.

Darstellung:

```text
$ 12,450
```

Große Zahlen werden später kompakt formatiert:

```text
$12.4K
$3.25M
$1.08B
```

Beim Hover oder in Detailansichten kann der exakte Wert sichtbar sein.

---

# 12. Zahlenformatierung

Das Spiel benötigt eine zentrale Number-Formatting-Funktion.

Sie wird überall verwendet:

- HUD
- Shops
- Storage
- Fahrzeuge
- Laptop
- Selling

Dadurch werden Werte überall gleich dargestellt.

Die endgültigen Suffixe werden mit dem Economy-System festgelegt.

---

# 13. Rucksackanzeige

Während der Spieler selbst Erz trägt, wird eine kleine Kapazitätsanzeige eingeblendet.

Beispiel:

```text
BACKPACK
72 / 100
```

Optional mit kleinem Erz-/Rucksackicon.

Wenn der Rucksack voll ist:

```text
BACKPACK FULL
```

mit kurzer visueller Rückmeldung.

---

# 14. Inventar

Der Spieler besitzt ein Inventarsystem für geeignete Gegenstände.

Dazu gehören beispielsweise:

- Pickaxes
- Backpacks
- Drills
- Conveyors

Bei platzierbaren Gegenständen wie Drills und Conveyors:

1. Gegenstand auswählen.
2. gültige Platzierungspositionen werden angezeigt.
3. Spieler wählt Position.
4. Server validiert.
5. Gegenstand wird platziert.

---

# 15. Ausrüstung auswählen

Pickaxes und Backpacks sollen über eine klare Inventar-/Equipment-Ansicht auswählbar sein.

Der Spieler kann gekaufte Ausrüstung wechseln.

Das UI zeigt mindestens:

- Name
- Icon / Vorschau
- relevante Stats
- Equipped-Status

---

# 16. Mining-Feedback

Beim manuellen Mining erhält der Spieler dezentes Feedback.

Mögliche Anzeige:

```text
+2 Coal
```

Sie erscheint kurz in der Nähe des relevanten HUD-/Weltbereichs und verschwindet wieder.

Normale Mining-Hits dürfen nicht den Bildschirm mit Text überfluten.

---

# 17. Rare-Drop-Anzeige

Rare Drops müssen deutlich stärker hervorgehoben werden.

Beispiel:

```text
RARE DROP!

+1 SILVER
```

oder:

```text
LUCKY DROP!

x8 COAL
```

Mögliche Effekte:

- kurzer Glow
- hochwertiger Sound
- kleine Partikel
- kurze UI-Bewegung

Keine lange Unterbrechung des Gameplays.

---

# 18. Rare-Drop-Regel

Die UI darf nur einen tatsächlich vom Server bestätigten Rare Drop anzeigen.

Der Client entscheidet niemals selbst, dass ein Rare Drop erfolgt ist.

---

# 19. Zusatzfenster für Stats

Der Spieler kann ein kleines Zusatzfenster für persönliche Stats öffnen.

Dort stehen mindestens:

- Mining Power
- Mining Speed
- Mining Luck
- Backpack Capacity

Später können weitere relevante persönliche Werte ergänzt werden.

---

# 20. Keine falschen globalen Stats

Folgende Werte werden nicht als universelle Spieler-Upgrades dargestellt:

- Ore Value
- Machine Efficiency
- Production Capacity

Diese Werte gehören zu Erzdefinitionen bzw. einzelnen Maschinen/Systemen.

---

# 21. Laptop – Grundfunktion

Der Laptop befindet sich in der Blechhütte.

Er ist das zentrale Managementsystem der Mining Company.

Beim Interagieren:

1. Spieler startet Laptop-Interaktion.
2. Kamera zoomt kurz sauber auf den Laptop.
3. Laptop-UI öffnet sich.
4. Hintergrund kann leicht abgedunkelt/unscharf werden.
5. Spieler verwaltet die Firma.

Beim Schließen kehrt die Kamera sauber zurück.

---

# 22. Laptop-Stil

Das Laptop-UI soll wie ein modernes internes Firmenbetriebssystem wirken.

Nicht wie ein echtes Windows-Desktop-Clone.

Design:

- Sidebar
- große Content-Fläche
- klare Cards
- industrielle Icons
- Firmenname oben
- Firmenlogo
- Firmenfarbakzent

---

# 23. Laptop – Hauptnavigation

Geplante Kernbereiche:

```text
DASHBOARD
EMPLOYEES
STORAGE
ELEVATOR
PRODUCTION
COMPANY
```

Weitere Bereiche können später ergänzt werden.

Nur tatsächlich verfügbare Systeme sollen sinnvoll angezeigt werden.

---

# 24. Laptop – Dashboard

Das Dashboard gibt einen schnellen Firmenüberblick.

Beispiel:

```text
FELIX MINING CO.

Mining Level: 18
Cash: $12.4K

Storage:
720 / 1000

Employees:
3 Active

Production:
2 Active
1 Blocked
```

Das Dashboard soll keine riesige Tabellenansicht werden.

---

# 25. Laptop – Company

Die Company-App zeigt:

- Firmenname
- Firmenlogo
- Firmenfarbe
- Unternehmensinformationen

Änderungen an benutzerdefinierten Texten müssen Roblox-Textfilterregeln beachten.

Ob Name/Logo/Farbe später kostenlos oder gegen Gebühr geändert werden können, wird noch festgelegt.

---

# 26. Laptop – Employees

Die Employee-App zeigt die verfügbaren Unternehmensbereiche und Arbeitsplätze.

Beispiel:

```text
EMPLOYEES

MINE 01

Mining Slot 1
Worker #001
WORKING

Mining Slot 2
[ HIRE ]

Transport Slot 1
Worker #002
CARRYING

Transport Slot 2
[ HIRE ]
```

---

# 27. Mitarbeiter-Detailansicht

Beim Auswählen eines Workers erscheint ein kleines Detailfenster.

Mindestens:

- Rolle
- Mine
- Slot
- Status
- Gehalt pro Minute

Aktionen können sein:

```text
MOVE
FIRE
```

Weitere Funktionen werden nur ergänzt, wenn sie tatsächlich benötigt werden.

---

# 28. Mitarbeiterstatus

Statuswerte sollen verständlich formuliert werden.

Beispiele:

```text
Working
Carrying Ore
Waiting for Material
Storage Full
Paused
Unpaid
```

Der Spieler soll erkennen, warum ein Worker nicht arbeitet.

---

# 29. Laptop – Storage

Die Storage-App zeigt:

```text
STORAGE

2,438 / 5,000

Coal       1,200
Copper       620
Iron         418
Iron Bar     200
```

Zusätzlich:

- Upgrade-Button
- nächste Kapazität
- Upgrade-Kosten
- eventuelle Levelanforderung

---

# 30. Storage-Upgrade

Beispiel:

```text
STORAGE UPGRADE

Current:
5,000

Next:
7,500

Cost:
$...

[ UPGRADE ]
```

Alle Werte kommen aus zentraler Konfiguration.

---

# 31. Laptop – Elevator

Die Elevator-App zeigt mindestens:

- aktuelle Kapazität
- nächste Upgrade-Stufe
- Upgrade-Kosten
- Status

Beispiel:

```text
ELEVATOR

Capacity
500

Next Upgrade
750

[ UPGRADE ]
```

Die Zahlen sind Platzhalter.

---

# 32. Laptop – Production

Die Production-App zeigt aktive Produktionssysteme.

Beispiel:

```text
PRODUCTION

Drill – Mine 04
RUNNING

Drill – Mine 06
OUTPUT FULL

Smelter
WAITING FOR INPUT
```

Der Spieler soll Blockaden schnell finden können.

---

# 33. Maschinen-Detailansicht

Bei Auswahl einer Maschine können angezeigt werden:

- Typ
- Standort
- Status
- Production Rate
- Input
- Output
- Capacity

Keine Informationen anzeigen, die der Spieler nicht sinnvoll verwenden kann.

---

# 34. Mine-Auswahl

Der Elevator besitzt eine Mine-Auswahl.

Das UI soll freundlich, clean und als geordnete Liste aufgebaut sein.

Nicht einfach ein riesiges Debug-Menü.

Beispiel:

```text
SELECT MINE

Mine 01
Coal
[ GO ]

Mine 02
Coal
[ GO ]

Mine 03
Copper
[ GO ]

Mine 04
Copper
LOCKED
Requires Mining Level ...
```

---

# 35. Mine-Liste

Die Liste muss auch bei später sehr vielen Minen funktionieren.

Deshalb:

- ScrollingFrame
- Such-/Filteroption später möglich
- klare Mine-Nummer
- Erzname
- Lock-Status

Die Architektur soll langfristig auch deutlich mehr als 100 Minen unterstützen können.

---

# 36. Mine-Unlock-Feedback

Wenn eine neue Mine verfügbar wird:

```text
NEW MINE UNLOCKED

MINE 05
TIN
```

Kurze Animation, danach verschwindet die Meldung.

---

# 37. Shop-UI – gemeinsame Struktur

Equipment-, Machine- und Vehicle-Shop sollen dieselbe grundlegende UI-Sprache verwenden.

Jedes Produkt zeigt abhängig vom Typ:

- Name
- Vorschau
- Preis
- Levelanforderung
- wichtige Stats
- Besitzstatus
- Buy-Button

---

# 38. Equipment-Shop-UI

Pickaxe-Beispiel:

```text
STEEL PICKAXE

Mining Power: ...
Mining Speed: ...

Required Level: ...
Price: $...

[ BUY ]
```

Backpack-Beispiel:

```text
MINER BACKPACK

Capacity: ...

Required Level: ...
Price: $...

[ BUY ]
```

---

# 39. Machine-Shop-UI

Drill-Beispiel:

```text
INDUSTRIAL DRILL

Production: ... / sec
Output Capacity: ...

Required Level: ...
Price: $...

[ BUY ]
```

Conveyor-Beispiel:

```text
CONVEYOR MK1

Throughput: ...

Required Level: ...
Price: $...

[ BUY ]
```

---

# 40. Vehicle-Shop-UI

Beispiel:

```text
UTILITY PICKUP

Capacity: 1,000
Speed: ...

Required Level: ...
Price: $...

[ BUY ]
```

Zusätzlich soll eine hochwertige 3D-Vorschau möglich sein.

---

# 41. Gekaufte Gegenstände

Nach erfolgreichem Kauf:

```text
PURCHASED
```

Kurzes positives Feedback.

Der Button ändert sich abhängig vom Gegenstand beispielsweise zu:

```text
OWNED
```

oder:

```text
EQUIP
```

---

# 42. Kaufvalidierung

UI darf Käufe niemals lokal als erfolgreich behandeln, bevor der Server sie bestätigt hat.

Server prüft:

- Geld
- Mining Level
- Besitz
- Voraussetzungen
- Inventarkapazität soweit relevant

---

# 43. Garage-UI

Die Garage besitzt ein eigenes Fahrzeugauswahlfenster.

Das UI verwendet Akzente der Firmenfarbe.

Es zeigt:

- gekaufte Fahrzeuge
- 3D-Vorschau
- Kapazität
- Geschwindigkeit
- ausgewähltes Fahrzeug

Beispiel:

```text
GARAGE

UTILITY PICKUP

Capacity: 1,000
Speed: ...

[ SPAWN ]
```

---

# 44. Fahrzeug-Spawn

Nach erfolgreicher Auswahl:

- UI schließt
- Fahrzeug erscheint
- Spieler wird direkt in das Fahrzeug gesetzt

Fehler werden klar angezeigt:

```text
SPAWN AREA BLOCKED
```

oder eine passendere kontextbezogene Meldung.

---

# 45. Loading-UI

Im Ladebereich erscheint das Loading-UI nur, wenn ein gültiges eigenes Fahrzeug vorhanden ist.

Beispiel:

```text
LOAD VEHICLE

Vehicle
340 / 1000

Coal
Storage: 1,200
[ LOAD ]

Copper
Storage: 620
[ LOAD ]
```

---

# 46. Mengenwahl

Für Materialtransfers soll eine angenehme Mengenwahl existieren.

Mögliche Controls:

- Slider
- `+`
- `-`
- `MAX`
- direkte Eingabe auf Desktop

Das System muss auch bei großen Zahlen bedienbar bleiben.

---

# 47. Selling-UI

Beim Verkauf aus dem Fahrzeug:

```text
SELL CARGO

Estimated Value:
$12,450

Mining XP:
+820

[ SELL ALL ]
```

Der tatsächliche Verkauf wird erst nach Serverbestätigung abgeschlossen.

---

# 48. Verkauf am Tresen

Beim Verkauf zu Fuß zeigt das UI die verkaufbaren Materialien aus dem relevanten Spielerinventar/Rucksack.

Das Design entspricht grundsätzlich dem Fahrzeugverkauf, damit der Spieler nicht zwei völlig unterschiedliche Systeme lernen muss.

---

# 49. Verkaufsfeedback

Nach erfolgreichem Verkauf:

```text
SOLD

+$12,450
+820 Mining XP
```

Die Geldanzeige und XP-Bar aktualisieren sich flüssig.

---

# 50. Tycoon-Kaufbutton

Baukaufbuttons am Boden sollen sauber und sofort verständlich sein.

Anzeige:

```text
BUILD STORAGE
$2,500
```

oder bei Levelanforderung:

```text
BUILD GARAGE
Requires Mining Level 12
```

Die Zahlen sind Beispiele.

---

# 51. Gesperrte Tycoon-Käufe

Wenn der nächste Bauabschnitt noch nicht freigeschaltet ist, soll das UI erklären warum.

Nicht nur:

```text
LOCKED
```

sondern beispielsweise:

```text
Requires Mining Level 12
```

---

# 52. Platzierungsmodus

Bei Drills und Conveyors:

1. Item im Inventar auswählen.
2. gültige Positionen leuchten.
3. Spieler nähert sich/selektiert Position.
4. Vorschau erscheint.
5. Spieler bestätigt.
6. Server prüft.
7. Objekt wird platziert.

Ungültige Bereiche werden nicht als freie Platzierung angeboten.

---

# 53. Platzierungsfarben

Für die Vorschau können klare Zustände verwendet werden:

```text
Valid
Invalid
Selected
```

Die genaue Farbe wird später im Style Guide festgelegt.

Nicht ausschließlich Farbe verwenden; Icons/Outline können zusätzlich helfen.

---

# 54. Benachrichtigungssystem

Das Spiel benötigt ein zentrales Notification-System.

Beispiele:

```text
Backpack Full
Storage Full
Vehicle Full
New Mine Unlocked
Worker Unpaid
Rare Drop
Purchase Successful
```

Nicht jedes Ereignis benötigt dieselbe Stärke.

---

# 55. Notification-Prioritäten

Empfohlene Kategorien:

## Info

kleine neutrale Meldung

## Success

Kauf, Verkauf, Unlock

## Warning

Storage Full, Worker Unpaid

## Special

Rare Drop, Prestige, besondere Unlocks

Dadurch kann die UI angemessen reagieren.

---

# 56. Keine Popup-Flut

Gleiche Warnungen dürfen nicht jede Sekunde erneut erscheinen.

Beispiel:

Wenn Storage 10 Minuten voll ist, darf nicht jede Sekunde ein neues:

```text
STORAGE FULL
```

erscheinen.

Benachrichtigungen benötigen Cooldowns bzw. Zustandswechsel.

---

# 57. Tooltip-System

Stats und komplexere Begriffe können Tooltips besitzen.

Beispiel:

```text
Mining Luck

Increases your chance of receiving
special drops while mining manually.
```

Tooltips sollen kurz und verständlich sein.

---

# 58. Hover- und Click-Feedback

Buttons sollen hochwertiges Feedback besitzen:

- leichter Hover
- kurzer Click
- dezenter Sound
- klarer Disabled-State

Keine übertriebenen Bounce-Animationen bei jedem Button.

---

# 59. Animationen

UI-Animationen sollen meistens kurz sein.

Empfohlener Charakter:

- schnell
- smooth
- kontrolliert

Animationen dürfen Gameplay nicht blockieren.

---

# 60. Audio

Wichtige UI-Aktionen können dezente Sounds besitzen.

Beispiele:

- Button Click
- Purchase
- Error
- Level Up
- Rare Drop
- Sell

Audio muss zentral verwaltet werden, damit Lautstärke und Stil konsistent bleiben.

---

# 61. Icons

Icons sollen eine konsistente visuelle Sprache verwenden.

Benötigte Kategorien:

- Money
- Mining Level
- XP
- Pickaxe
- Backpack
- Worker
- Storage
- Elevator
- Drill
- Conveyor
- Smelter
- Vehicle
- Ore
- Settings

Keine Mischung aus völlig unterschiedlichen Icon-Stilen.

---

# 62. Erzicons

Erze sollen tatsächlich visuell als Erze erkennbar sein.

Nicht nur ein farbiger Kreis.

Jedes wichtige Erz erhält später:

- eigenes Icon
- passende Farbe
- passende Material-/Kristallform

Seltene Erze dürfen auffälliger wirken.

---

# 63. UI und Performance

Zu vermeiden:

- hunderte dauerhaft aktive ViewportFrames
- unnötige RenderStepped-Verbindungen
- ständig neu erstellte UI-Objekte
- riesige Listen ohne Virtualisierung/vernünftige Aktualisierung

Listen werden nur aktualisiert, wenn sich relevante Daten ändern.

---

# 64. Client und Server

Der Client darf darstellen und Eingaben senden.

Der Server entscheidet über wirtschaftlich relevante Ergebnisse.

Serverautorität gilt mindestens für:

- Kauf
- Verkauf
- Upgrade
- Worker einstellen/entlassen
- Drill-/Conveyor-Platzierung
- Fahrzeugspawn-Berechtigung
- Materialtransfer
- XP
- Geld
- Rare Drops

---

# 65. UI-Datenfluss

Empfohlen:

```text
PLAYER INPUT
     ↓
CLIENT UI
     ↓
REMOTE REQUEST
     ↓
SERVER VALIDATION
     ↓
SERVER STATE CHANGE
     ↓
CONFIRMED DATA
     ↓
UI UPDATE
```

Nicht:

```text
Button Click
↓
Client gibt sich Geld/Item selbst
```

---

# 66. Loading States

Serverabhängige Aktionen benötigen bei Bedarf einen kurzen Loading-/Pending-State.

Beispiel:

```text
BUY
↓
...
↓
PURCHASED
```

Mehrfachklick während einer laufenden Transaktion muss verhindert werden.

---

# 67. Fehlermeldungen

Fehler sollen konkret sein.

Gut:

```text
Not enough money.
```

```text
Requires Mining Level 25.
```

```text
Vehicle capacity reached.
```

Schlecht:

```text
Error 14
```

Technische Debug-Fehler gehören nicht in die Spieler-UI.

---

# 68. Roblox Text Filtering

Benutzerdefinierte Texte wie Firmenname müssen über Roblox-Textfilter abgesichert werden.

Ungefilterter benutzerdefinierter Text darf anderen Spielern nicht angezeigt werden.

---

# 69. UI-Ordnerstruktur

Empfohlene Struktur:

```text
StarterGui
└── GameUI
    ├── HUD
    ├── Notifications
    ├── Inventory
    ├── Stats
    ├── Laptop
    ├── MineSelector
    ├── Shops
    ├── Garage
    ├── Loading
    ├── Selling
    └── Placement
```

Die finale technische Architektur kann Komponenten modularer organisieren.

---

# 70. Wiederverwendbare Komponenten

Claude soll wiederverwendbare UI-Komponenten erstellen.

Beispiele:

- PrimaryButton
- SecondaryButton
- ItemCard
- StatRow
- ProgressBar
- Notification
- Modal
- Tooltip
- MaterialRow
- VehicleCard
- WorkerCard

Nicht jedes Menü soll dieselben Buttons neu implementieren.

---

# 71. Zentrale Style-Konfiguration

Farben, Abstände und Standardgrößen sollen möglichst zentral definiert werden.

Beispiel:

```lua
UITheme = {
    CornerRadius = ...,
    PanelTransparency = ...,
    AnimationSpeed = ...,
}
```

Konkrete Werte werden mit den finalen UI-Referenzbildern abgestimmt.

---

# 72. Visual References

Für die UI sollen später mindestens folgende Referenzbilder erstellt werden:

```text
VISUAL_REFERENCES/16_LAPTOP_UI.png
VISUAL_REFERENCES/17_MAIN_HUD.png
VISUAL_REFERENCES/18_MINE_SELECTION_UI.png
VISUAL_REFERENCES/19_SHOP_UI.png
```

Diese Bilder definieren später die visuelle Umsetzung genauer.

---

# 73. Referenzregel

Bis die finalen UI-Mockups existieren:

- Funktion und Informationshierarchie dieses Dokuments sind verbindlich.
- Farben, Pixelabstände und exakte Positionen bleiben anpassbar.

Nach Erstellung der finalen UI-Mockups besitzen diese für die visuelle Gestaltung höhere Genauigkeit.

---

# 74. Prestige-Anzeige

Prestige/Rebirth wird später im entsprechenden Progressionssystem genauer definiert.

Wenn verfügbar, soll der Laptop bzw. das relevante Menü klar zeigen:

- Voraussetzung
- dauerhaften Bonus
- was zurückgesetzt wird
- was erhalten bleibt

Ein Prestige darf niemals durch einen einzelnen versehentlichen Klick ausgelöst werden.

---

# 75. Bestätigungsdialoge

Bestätigung ist nur für relevante irreversible oder schwerwiegende Aktionen nötig.

Beispiele:

- Prestige
- Worker entlassen
- möglicherweise wertvolle Handelsaktionen

Normale Käufe benötigen nicht ständig zusätzliche Bestätigungsfenster.

---

# 76. Accessibility-Grundlagen

Wichtige Zustände sollen nicht ausschließlich durch Farbe kommuniziert werden.

Beispiel:

```text
RUNNING
```

zusätzlich zu Grün.

```text
BLOCKED
```

zusätzlich zu Rot.

Text muss ausreichend kontrastreich und lesbar sein.

---

# 77. Keine unnötigen Mobile-Buttons auf Desktop

Desktop-Spieler sollen nicht mit riesigen Touch-Controls zugedeckt werden.

Input-spezifische UI wird abhängig vom Gerät angezeigt.

---

# 78. Tastatursteuerung

Wichtige Menüs dürfen später Shortcuts erhalten.

Beispiele:

- Inventory
- Stats
- Laptop schließen
- Interaktion

Die endgültige Tastenbelegung wird separat festgelegt.

---

# 79. Tutorial-Hinweise

Neue Systeme können beim ersten Freischalten einen kurzen Hinweis erhalten.

Beispiel:

```text
GARAGE UNLOCKED

Buy your first vehicle and transport
larger loads to the selling station.
```

Keine langen Tutorial-Textwände.

---

# 80. Verbindliche Regeln

1. UI bleibt clean und modern.
2. Mining Level wird dauerhaft unten mittig angezeigt.
3. Mining XP wird über eine Progress-Bar dargestellt.
4. Geld ist dauerhaft sichtbar.
5. Rucksackkapazität wird beim aktiven Tragen klar angezeigt.
6. Rare Drops erhalten deutlich stärkeres Feedback als normale Drops.
7. Persönliche Stats besitzen ein kleines Zusatzfenster.
8. Laptop ist das zentrale Firmenmanagement.
9. Kamera zoomt beim Laptop kurz auf das Gerät.
10. Laptop enthält mindestens Dashboard, Employees, Storage, Elevator, Production und Company.
11. Mitarbeiter können am Laptop verwaltet werden.
12. Lagerkapazität wird in der Storage-App verbessert.
13. Elevator-Kapazität wird am Laptop verbessert.
14. Mine-Auswahl ist eine cleane scrollbare Liste.
15. Shop-UIs verwenden eine gemeinsame Designsprache.
16. Equipment-, Machine- und Vehicle-Shop bleiben funktional getrennt.
17. Garage besitzt ein eigenes Fahrzeugauswahl-UI.
18. Loading-UI zeigt Material und Fahrzeugkapazität.
19. Selling-UI unterstützt `SELL ALL`.
20. Tycoon-Kaufbuttons zeigen Preis und ggf. Levelanforderung.
21. Platzierbare Items werden nur an gültigen festen Slots angeboten.
22. Benachrichtigungen besitzen Prioritäten und Cooldowns.
23. Erzicons stellen echte Erze dar und sind nicht nur Farbpunkte.
24. Firmenfarbe wird als Akzent verwendet.
25. UI muss responsiv aufgebaut werden.
26. Wirtschaftlich relevante Aktionen werden serverseitig bestätigt.
27. Benutzerdefinierte Texte werden über Roblox-Textfilter abgesichert.
28. UI-Komponenten werden wiederverwendbar gebaut.
29. Designwerte werden zentral konfiguriert.
30. Finale UI-Mockups werden später als visuelle Referenzen ergänzt.
