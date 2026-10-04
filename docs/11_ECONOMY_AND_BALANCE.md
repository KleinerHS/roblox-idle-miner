# 11 – ECONOMY AND BALANCE

## 1. Zweck dieses Dokuments

Dieses Dokument definiert das wirtschaftliche Grundmodell des Spiels.

Wichtig: Die konkrete Balance soll **nicht vor dem ersten spielbaren Build künstlich festgenagelt werden**. Stattdessen definiert dieses Dokument:

- welche Werte voneinander abhängen
- wie Progression kontrolliert wird
- wie exponentiell explodierende Zahlen vermieden werden
- welche Daten zentral konfigurierbar sein müssen
- wie Level, Erze, Equipment, Worker, Maschinen und Prestige zusammenhängen
- welche Zielzeiten beim späteren Playtesting gemessen werden

Die endgültigen Zahlen werden erst nach Tests festgelegt.

---

# 2. Kernziel der Economy

Die Economy soll sich langfristig steigern, ohne bereits nach kurzer Zeit in absurde Zahlenbereiche zu geraten.

Der Spieler soll regelmäßig Fortschritt spüren:

```text
besseres Erz
→ mehr Einkommen
→ bessere Ausrüstung
→ mehr Automation
→ größere Firma
→ neue Mine
```

Aber:

```text
neue Mine ≠ automatisch 100x mehr Geld
```

Jeder Fortschrittsschritt muss kontrollierbar bleiben.

---

# 3. Wichtigste Regel gegen Zahlenexplosion

Die frühere Idee:

> Jedes nächste Erz bringt doppelt so viel Ertrag.

wird **nicht** als dauerhaftes `2^n`-System umgesetzt.

Bei vielen Erzstufen würde das zu unbrauchbaren Zahlen führen.

Stattdessen wird zwischen folgenden Dingen unterschieden:

- Erzmenge pro Produktionszyklus
- Basisverkaufswert
- Produktionsgeschwindigkeit
- Seltenheit
- Verarbeitungsbonus
- Equipment-/Maschinenkosten

Diese Werte wachsen kontrolliert und getrennt.

---

# 4. Economy-Layer

Die Wirtschaft besteht aus fünf Hauptschichten:

```text
1. RESOURCE VALUE
   Wert eines Erzes

2. PRODUCTION
   Menge pro Zeit

3. CAPACITY
   Backpack / Storage / Elevator / Vehicle / Machine

4. COSTS
   Equipment / Machines / Buildings / Wages

5. PROGRESSION
   Mining Level / Unlocks / Prestige
```

Keine einzelne Formel soll die komplette Economy kontrollieren.

---

# 5. Primäre Währung

Die primäre normale Spielwährung ist:

**Money / Cash**

Darstellung:

```text
$1,250
```

Geld wird hauptsächlich durch Materialverkauf verdient.

---

# 6. Keine unnötigen Standardwährungen

Version 1 benötigt nicht zusätzlich:

- Gems
- Tokens
- Crystals
- Coins
- Tickets

nur weil andere Roblox-Simulatoren dies tun.

Weitere Währungen werden nur eingeführt, wenn sie später einen klaren Zweck besitzen.

---

# 7. Mining XP

Mining XP ist keine Währung.

XP dient ausschließlich dem Mining-Level-Fortschritt.

Mining XP wird nur beim erfolgreichen Verkauf vergeben.

---

# 8. Mining XP und Geld sind getrennt

Für jedes Material werden mindestens zwei getrennte Werte definiert:

```text
SellValue
MiningXP
```

Beispiel:

```lua
Coal = {
    SellValue = ...,
    MiningXP = ...,
}
```

XP wird nicht einfach aus dem Verkaufspreis berechnet.

---

# 9. Warum XP getrennt bleibt

Dadurch kann ein seltenes Erz beispielsweise:

- viel XP geben
- einen angemessenen Geldwert besitzen

ohne die komplette Geld-Economy zu zerstören.

Außerdem können spätere Marktpreise schwanken, ohne gleichzeitig das Levelsystem zu verändern.

---

# 10. Erzprogression

Jede Erzart besitzt einen eigenen Basiswert.

Neue Erzarten sind wertvoller als frühere.

Die Steigerung soll jedoch kontrolliert erfolgen.

Empfohlenes Prinzip:

```text
Ore 1 → moderater Wert
Ore 2 → merklich höher
Ore 3 → merklich höher
...
```

Nicht:

```text
1
2
4
8
16
32
...
2^100
```

---

# 11. Erz-Tiers

Um die Economy übersichtlich zu halten, können Erze intern in Tiers gruppiert werden.

Beispiel:

```text
Tier 1 – Early Game
Tier 2 – Early/Mid
Tier 3 – Mid Game
Tier 4 – Late Mid
Tier 5 – Late Game
```

Innerhalb eines Tiers steigen Werte moderat.

Beim Wechsel in ein neues Tier darf ein größerer Sprung stattfinden.

---

# 12. Zwei Minen pro Haupt-Erz

Die aktuelle Weltstruktur verwendet grundsätzlich:

```text
Mine 01 → Coal
Mine 02 → Coal

Mine 03 → Copper
Mine 04 → Copper

Mine 05 → nächstes Erz
Mine 06 → nächstes Erz
```

und so weiter.

Das bedeutet:

**Eine neue Mine muss nicht automatisch eine komplett neue Erzart bedeuten.**

Dadurch kann Progression feiner gesteuert werden.

---

# 13. Unterschied zwischen zwei Minen derselben Erzart

Wenn zwei aufeinanderfolgende Minen dasselbe Erz besitzen, kann die spätere Mine beispielsweise Vorteile besitzen durch:

- höhere Grundproduktionsmöglichkeit
- bessere Slot-Nutzung
- bessere Maschinenökonomie
- höhere mögliche Produktionsrate

Der Basiswert von Coal bleibt trotzdem:

**Coal = Coal**

Coal erhält nicht je nach Mine einen anderen Verkaufspreis.

---

# 14. Fester Materialwert

In Version 1 besitzt jedes Material einen festen Basisverkaufswert.

Beispiel:

```text
Coal ist immer gleich viel wert.
```

Es gibt zunächst keinen dynamischen Markt.

Die Datenstruktur soll einen späteren Markt-Multiplikator unterstützen können.

---

# 15. Späterer Markt

Später denkbar:

```text
FinalSellPrice =
BaseSellValue × MarketMultiplier
```

Version 1 verwendet:

```text
MarketMultiplier = 1
```

Die Marktmechanik wird nicht vorzeitig implementiert, wenn sie für den Core Loop nicht benötigt wird.

---

# 16. Manuelles Mining – Early Game

Die ersten Minuten sollen bewusst langsamer beginnen.

Die erste Pickaxe produziert ungefähr eine sehr kleine Erzmenge pro Schlag.

Aktuelle Designrichtung:

```text
ca. 1–2 Erz pro Schlag
```

Der genaue Wert wird getestet.

Das Ziel ist:

- Fortschritt spürbar machen
- erstes Equipment wertvoll wirken lassen
- Automation attraktiv machen

---

# 17. Manuelles Mining – spätere Phase

Später darf manuelles Mining deutlich schneller werden.

Es soll jedoch irgendwann wirtschaftlich weniger wichtig sein als die Firma.

Manuelles Mining bleibt trotzdem interessant wegen:

- Mining Luck
- Drop-Multiplikatoren
- Rare Ores

---

# 18. Rare Drop – Multiplikator

Beim manuellen Mining kann ein erfolgreicher Luck-Proc einen Mengenmultiplikator erzeugen.

Aktueller Rahmen:

```text
1x bis 10x Drop
```

Ein Rare-Event ist entweder:

```text
Mengenmultiplikator
```

ODER:

```text
seltenes Erz
```

Nicht beides gleichzeitig.

---

# 19. Rare Ore Drop

Beim manuellen Mining kann mit sehr geringer Wahrscheinlichkeit ein Erz aus einer späteren Progressionsstufe erhalten werden.

Maximaler aktueller Bereich:

**bis zu 4 Erzstufen weiter**

Je weiter das Rare Ore vom aktuellen Erz entfernt ist, desto geringer muss die Wahrscheinlichkeit sein.

---

# 20. Rare Drops nur beim Spieler

Rare-Drop-System gilt ausschließlich für manuelles Mining.

Nicht für:

- Worker
- Drills
- Offline-Produktion
- Conveyor
- Smelter

Dadurch bleibt aktives Mining langfristig besonders.

---

# 21. Rare Drop – Economy-Schutz

Rare Ores dürfen die Progression nicht überspringen.

Deshalb müssen sie:

- sehr selten sein
- kleine Mengen liefern
- nicht automatisch neue Minen freischalten
- keine Maschinen-/Levelanforderungen umgehen

Sie sind ein Bonus, kein Progressionsskip.

---

# 22. Produktionswert

Für Automation ist nicht nur der Wert pro Erz relevant.

Wichtiger ist:

```text
IncomePerMinute =
ProducedUnitsPerMinute × SellValue
```

Daher werden Produktionsrate und Erzpreis gemeinsam gebalanced.

---

# 23. Ziel: Upgrade-Payback

Bei Maschinen wird später gemessen:

```text
PaybackTime =
MachinePrice / AdditionalProfitPerMinute
```

Ein Upgrade darf weder:

- nach wenigen Sekunden komplett bezahlt sein
- noch mehrere reale Stunden benötigen, obwohl es ein frühes Upgrade ist

Die gewünschten Payback-Zeiten werden nach Playtests festgelegt.

---

# 24. Worker-Kosten

Worker besitzen zwei Kostenarten:

```text
HireCost
WagePerMinute
```

Der HireCost wird einmal bezahlt.

Danach verursacht der Worker laufende Gehaltskosten.

---

# 25. Worker-Gehalt

Gehalt wird pro Minute berechnet.

Der Spieler muss dadurch darauf achten, dass seine Firma wirtschaftlich sinnvoll läuft.

Worker sollen keine kostenlose permanente Produktion darstellen.

---

# 26. Worker-Wirtschaftlichkeit

Für Worker wird später gemessen:

```text
NetProfitPerMinute =
WorkerGeneratedRevenue
-
WorkerWage
```

Ein sinnvoll eingesetzter Worker muss profitabel sein.

Ein schlecht eingesetzter oder blockierter Worker kann dagegen Kosten verursachen.

---

# 27. Worker ohne Geld

Wenn der Spieler ein Gehalt nicht bezahlen kann, muss das Verhalten eindeutig sein.

Aktuelle Designrichtung:

```text
Worker → UNPAID → stoppt Arbeit
```

Es entstehen keine negativen Geldbestände durch unbegrenzt weiterlaufende Gehälter.

Die genaue Grace Period wird später getestet.

---

# 28. Drill-Economy

Drills besitzen:

- einmaligen Kaufpreis
- keine laufenden Worker-Gehälter für das Mining selbst
- feste Produktionsrate
- lokale Kapazität

Aber das Material muss weiterhin transportiert werden.

Dadurch können Transport Worker weiterhin Kosten verursachen.

---

# 29. Worker vs. Drill

Ein Drill soll langfristig effizienter als ein einfacher Mining Worker sein.

Er ist dafür:

- teurer in der Anschaffung
- an Progression gebunden
- auf einen Mining-Slot angewiesen

Worker bleiben früh verfügbar und bilden den Einstieg in Automation.

---

# 30. Conveyors

Conveyors ersetzen später Teile der manuellen/Worker-basierten Logistik.

Ihr wirtschaftlicher Nutzen entsteht durch:

- weniger benötigte Transportarbeit
- höheren Durchsatz
- weniger Blockaden

Sie müssen daher gegen Worker-Gehälter und Produktionsvolumen gebalanced werden.

---

# 31. Storage-Economy

Storage-Upgrades erzeugen nicht direkt mehr Erz.

Sie erhöhen die Zeit, die eine Firma ohne Rückstau produzieren kann.

Der wirtschaftliche Nutzen steigt deshalb mit der Produktionsrate.

Storage darf nicht so billig sein, dass Kapazitätsmanagement bedeutungslos wird.

---

# 32. Elevator-Economy

Elevator-Upgrades erhöhen die logistische Kapazität.

Auch hier gilt:

```text
Upgrade Value =
weniger Produktionsstau
+
mehr transportierbares Material
```

Der Elevator ist kein direkter Geldmultiplikator.

---

# 33. Fahrzeug-Economy

Fahrzeuge erhöhen primär:

- Transportkapazität

und teilweise:

- Komfort
- Fahrleistung

Das erste Fahrzeug besitzt aktuell:

**1.000 Kapazität**

Spätere Fahrzeuge erhöhen die Kapazität schrittweise.

---

# 34. Fahrzeug-Upgrade-Nutzen

Der Nutzen eines größeren Fahrzeugs lässt sich später messen als:

```text
weniger Verkaufsfahrten
+
größere Ladung pro Fahrt
```

Da der Spieler immer selbst fährt, bleibt Fahrzeugkapazität wirtschaftlich relevant.

---

# 35. Smelter-Economy

Verarbeitung muss profitabel sein.

Grundregel:

```text
ProcessedSellValue > RawInputSellValue
```

Beispiel:

```text
Raw Input Value = X
Processed Output Value > X
```

Die Differenz bezahlt indirekt für:

- Maschinenanschaffung
- zusätzliche Logistik
- Wartezeit
- Kapazitätsmanagement

---

# 36. Kein extremer Processing-Multiplikator

Der Schmelzer darf den Wert nicht so stark erhöhen, dass Rohmaterialverkauf vollständig sinnlos wird.

Ziel:

- direkt verkaufen = schneller
- verarbeiten = profitabler

Dadurch entsteht eine echte Entscheidung.

---

# 37. Gebäude-Kosten

Tycoon-Gebäude werden in einer festen Reihenfolge gebaut.

Die Kosten steigen mit dem Unternehmensfortschritt.

Die Preisentwicklung soll den Spieler dazu bringen, das jeweils neu freigeschaltete System zunächst zu nutzen, bevor sofort der nächste große Bereich gekauft wird.

---

# 38. Gebäude und Mining Level

Gebäudeteile können gleichzeitig verlangen:

```text
Mining Level
+
Money
```

Dadurch verhindert das Spiel, dass ein einzelner großer Geldfund sämtliche Firmenprogression überspringt.

---

# 39. Level-Kurve

Mining Level soll langfristig weit über Level 100 hinaus erweiterbar sein.

Zukünftiges Ziel kann bis Level 1000 gehen.

Daher darf die XP-Kurve nicht hart auf Level 100 zugeschnitten sein.

---

# 40. XP-Formel

Die XP-Anforderung pro Level soll über eine zentrale Formel oder Tabelle berechnet werden.

Grundprinzip:

```text
XPRequired(level)
```

Die Kurve soll:

- am Anfang schnell verständlichen Fortschritt liefern
- später langsamer werden
- nicht extrem exponentiell explodieren

Empfohlen wird eine kontrollierte polynomial-/piecewise-basierte Kurve statt reinem Exponentialwachstum.

Die konkrete Formel wird nach Tests bestimmt.

---

# 41. Level-Zielzeiten

Beim Balancing werden Zielzeiten definiert.

Beispielhafte Messpunkte:

```text
Level 1 → 5
Level 5 → 10
Level 10 → 25
Level 25 → 50
Level 50 → 100
```

Für jeden Bereich wird gemessen:

- aktive Spielzeit
- durchschnittliches Einkommen
- Equipment-Fortschritt
- Automation

Erst danach werden finale XP-Werte festgelegt.

---

# 42. Level 100 und Prestige

Prestige/Rebirth wird ab:

**Mining Level 100**

verfügbar.

Level 100 ist trotzdem nicht das technische Maximallevel.

Der Spieler kann später grundsätzlich weiterleveln, sofern das finale Prestige-Design dies zulässt.

---

# 43. Prestige-Grundidee

Beim Prestige startet die normale Firmenprogression neu.

Dafür erhält der Spieler einen dauerhaften Bonus.

Aktuelles Grundprinzip:

```text
Reach Level 100
↓
Prestige available
↓
Reset normal progression
↓
Permanent Stats + Money Bonus
```

---

# 44. Prestige-Bonus

Der Prestige-Bonus soll dauerhaft sein.

Er kann mindestens beeinflussen:

- Geldfortschritt
- ausgewählte persönliche Stats

Die konkrete Formel wird später definiert.

Der Bonus darf nicht nach wenigen Prestiges die komplette Economy zerstören.

---

# 45. Prestige-Skalierung

Prestige-Multiplikatoren müssen gedeckelt bzw. kontrolliert skalieren.

Nicht empfohlen:

```text
Prestige 1 = x2
Prestige 2 = x4
Prestige 3 = x8
...
```

wenn dies unbegrenzt weiterläuft.

Besser ist eine kontrollierte Bonuskurve mit abnehmendem relativen Wachstum.

---

# 46. Prestige-Reset

Die genaue Reset-Liste wird später im Progressionsdokument finalisiert.

Grundsätzlich zurücksetzbar sind normale Fortschrittsbereiche wie:

- Money
- Mining Level
- normale Firmenbauten
- normale Progressionsfreischaltungen
- erspielte Standardausrüstung, sofern final so beschlossen

Permanent bleiben mindestens:

- Prestige-Bonus
- Robux-Käufe

---

# 47. Robux-Käufe

Robux-Käufe dürfen nicht durch Prestige verloren gehen.

Sie werden als permanente Entitlements gespeichert.

Die normale Economy darf trotzdem nicht davon abhängen, dass der Spieler Robux ausgibt.

---

# 48. Offline-Produktion

Offline-Produktion läuft maximal:

**1 Stunde**

Sie respektiert:

- Produktionsrate
- Worker
- Drill
- Elevator
- Storage
- Smelter
- Kapazitäten
- Blockaden

Offline-Einkommen wird nicht direkt als Geld ausgezahlt.

Es produziert Materialien.

Der Spieler muss diese später weiterhin verkaufen.

---

# 49. Warum Offline-Produktion Material erzeugt

Dadurch bleibt der Core Loop erhalten:

```text
Produktion
→ Lager
→ Transport
→ Verkauf
```

Offline-Zeit umgeht nicht das Fahrzeug- und Verkaufssystem.

---

# 50. Economy und Offline-Cap

Die 1-Stunden-Grenze verhindert, dass Spieler nach mehreren Wochen Abwesenheit sofort riesige Progressionssprünge machen.

Sie kann später anhand von Retention-Tests angepasst werden.

---

# 51. Kostenkategorien

Die Economy muss getrennte Kostenkurven besitzen für:

```text
Pickaxes
Backpacks
Drills
Conveyors
Vehicles
Worker Hire
Worker Wages
Storage Upgrades
Elevator Upgrades
Buildings
```

Nicht alles wird mit derselben Preisformel skaliert.

---

# 52. Preisformeln

Preise sollen möglichst aus nachvollziehbaren Tabellen/Kurven kommen.

Beispielsweise kann eine Kategorie verwenden:

```text
BaseCost
GrowthFactor
TierModifier
```

Aber Claude darf keine universelle Formel auf alle Items anwenden, wenn dies zu schlechter Balance führt.

---

# 53. Datengetriebene Balance

Alle Balancewerte müssen zentral bearbeitbar sein.

Keine wichtigen Zahlen tief in Gameplay-Scripts verteilen.

Empfohlene Struktur:

```text
Balance/
├── Ores
├── Levels
├── Pickaxes
├── Backpacks
├── Workers
├── Drills
├── Conveyors
├── Storage
├── Elevator
├── Vehicles
├── Buildings
├── Smelter
└── Prestige
```

---

# 54. Balance-Versionen

Später soll eine Balance-Version definiert werden können.

Beispiel:

```lua
BalanceVersion = 3
```

Dadurch lassen sich größere Economy-Änderungen nachvollziehen und bei Bedarf Datenmigrationen durchführen.

---

# 55. Keine hardcodierten Display-Zahlen

UI liest Werte aus denselben Definitionen wie das Gameplay.

Nicht:

```text
Shop UI sagt $5,000
Server verlangt $7,500
```

Eine zentrale Datenquelle verhindert solche Fehler.

---

# 56. Zahlenbereich

Die technische Architektur soll große Zahlen sicher unterstützen.

Trotzdem soll das Design absurde Größen so lange wie möglich vermeiden.

Ziel ist nicht:

```text
1e150 Cash
```

nur damit die Progression „groß“ aussieht.

---

# 57. Number Formatting

Für größere Werte wird ein einheitliches Format verwendet.

Beispiel:

```text
1,250
12.5K
3.4M
1.2B
```

Die endgültige Suffix-Liste wird später definiert.

Intern bleiben exakte Werte erhalten.

---

# 58. Keine Rundungsfehler bei Käufen

Anzeige darf gerundet sein.

Wirtschaftliche Berechnungen verwenden den tatsächlichen serverseitigen Wert.

Beispiel:

```text
UI: $12.5K
Internal: 12,487
```

---

# 59. Verkaufstransaktion

Serverseitiger Ablauf:

```text
1. Materialbestand prüfen
2. SellValue laden
3. Marktmodifikator laden
4. Geld berechnen
5. XP separat berechnen
6. Material entfernen
7. Geld gutschreiben
8. XP gutschreiben
9. Transaktion bestätigen
```

Die Operation muss gegen doppeltes Auslösen geschützt sein.

---

# 60. Keine Geldproduktion ohne Quelle

Jede normale Geldgutschrift muss eine nachvollziehbare Quelle besitzen.

Beispiele:

- Materialverkauf
- später definierte Quest/Belohnung
- Robux-Produkt, falls vorhanden

Gameplay-Scripts dürfen nicht willkürlich Geld erzeugen.

---

# 61. Economy-Telemetrie

Für spätere Tests sollen wichtige Werte messbar sein.

Mindestens interessant:

- Spielzeit bis erste Automation
- Spielzeit bis erster Worker
- Spielzeit bis erster Drill
- Spielzeit bis erstes Fahrzeug
- Spielzeit bis Conveyor
- Spielzeit bis Smelter
- durchschnittliches Einkommen pro Minute
- durchschnittliche Lagerauslastung
- Worker-Wage-Anteil
- häufigste Kaufreihenfolge
- Levelgeschwindigkeit
- Prestige-Zeit

---

# 62. Warum Telemetrie wichtig ist

Die Economy kann nicht nur auf Papier perfekt gebalanced werden.

Spieler:

- spielen unterschiedlich effizient
- vergessen Upgrades
- min-maxen
- fahren unterschiedlich schnell
- nutzen Rare Drops unterschiedlich

Deshalb werden Zahlen nach echten Tests angepasst.

---

# 63. Testprofile

Beim Balancing sollen mindestens drei Spielweisen getestet werden:

```text
ACTIVE PLAYER
viel manuelles Mining

BALANCED PLAYER
Mining + Automation

IDLE PLAYER
starker Fokus auf Automation
```

Alle drei sollen spielbar sein.

Der Balanced Player kann als Hauptreferenz dienen.

---

# 64. Soft Bottlenecks

Die Economy soll bewusst Engpässe erzeugen.

Beispiele:

- Backpack voll
- Storage voll
- Elevator zu klein
- zu wenig Transport Worker
- Fahrzeug zu klein
- Smelter Output voll

Diese Engpässe zeigen dem Spieler, was er als Nächstes verbessern sollte.

---

# 65. Keine künstlichen Hard-Walls

Zu vermeiden:

```text
Du brauchst 10 Stunden AFK, bevor irgendetwas möglich ist.
```

Progression darf langsamer werden, aber der Spieler soll normalerweise ein sinnvolles nächstes Ziel besitzen.

---

# 66. Kaufentscheidungen

Nicht jedes Upgrade soll gleichzeitig bezahlbar sein.

Idealerweise entstehen Entscheidungen:

```text
Neue Pickaxe?
ODER
Storage Upgrade?
ODER
Worker?
ODER
für Fahrzeug sparen?
```

Dadurch wird Geldmanagement relevant.

---

# 67. Early-Game-Ziel

Das Early Game soll dem Spieler schnell den vollständigen Grundgedanken zeigen:

```text
selbst minen
→ verkaufen
→ besseres Equipment
→ neue Mine
→ ersten Worker einstellen
```

Der erste Worker soll bereits früh erreichbar sein, da die zweite Mine die erste Automation ermöglichen soll.

---

# 68. Mid-Game-Ziel

Im Mid Game verschiebt sich der Fokus:

```text
mehrere Minen
→ Worker
→ Drills
→ Lager
→ Fahrzeug
→ Logistik
→ Conveyors
→ Verarbeitung
```

Der Spieler baut zunehmend ein Unternehmen statt nur selbst zu minen.

---

# 69. Late-Game-Ziel

Später liegt der Fokus auf:

- Produktionsoptimierung
- große Drills
- Logistik
- große Fahrzeuge
- Verarbeitung
- seltene manuelle Drops
- Prestige

Manuelles Mining bleibt Bonusaktivität, nicht Hauptproduktion.

---

# 70. Balancing-Reihenfolge

Die finale Balance soll nicht alles gleichzeitig einstellen.

Empfohlene Reihenfolge:

```text
1. Ore Base Values
2. Manual Mining Output
3. XP Curve
4. Pickaxes
5. Backpacks
6. Worker Production + Wages
7. Drills
8. Storage + Elevator
9. Vehicles
10. Conveyors
11. Smelter
12. Building Costs
13. Prestige
14. Rare Drops
15. Offline Production
```

Danach folgen mehrere komplette Playthroughs.

---

# 71. Erste Testversion

Für den ersten spielbaren Prototyp reichen wenige Inhalte.

Beispielsweise:

```text
2–4 Erzarten
einige Minen
2–3 Pickaxes
2 Backpacks
1–2 Worker-Typen
1–2 Drills
1 Fahrzeug
Basislager
Elevator
Selling
```

Erst wenn dieser Loop Spaß macht, werden dutzende Content-Stufen ergänzt.

---

# 72. Kein Balancing durch Content-Masse

Mehr Items lösen keine schlechte Progression.

Claude soll nicht sofort 50 Pickaxes und 40 Drills erzeugen, bevor die grundlegende Economy getestet wurde.

Zuerst:

**kleiner funktionierender Vertical Slice**

Danach:

**Content skalieren**

---

# 73. Balance-Simulation

Später soll ein separates kleines Balance-Script bzw. Spreadsheet-Modell erstellt werden.

Damit können simuliert werden:

- Einkommen pro Minute
- Zeit bis Upgrade
- XP pro Minute
- Worker-Kosten
- Drill-Payback
- Fahrzeugnutzen
- Prestige-Zeit

Dies soll vor dem finalen Content-Ausbau erfolgen.

---

# 74. Noch nicht final festgelegte Werte

Noch offen sind insbesondere:

- SellValue jeder Erzart
- XP jeder Erzart
- XP-Kurve
- Pickaxe-Stats
- Backpack-Kapazitäten
- Worker Hire Costs
- Worker Wages
- Worker-Geschwindigkeiten
- Drill-Preise
- Drill-Produktionsraten
- Conveyor-Kosten
- Conveyor-Durchsatz
- Storage-Upgrades
- Elevator-Upgrades
- Fahrzeugpreise
- Fahrzeugkapazitäten nach dem ersten Fahrzeug
- Gebäude-Kosten
- Smelter-Rezepte
- Processing-Bonus
- Prestige-Bonus
- Rare-Drop-Wahrscheinlichkeiten

Diese Werte werden bewusst nicht geraten.

---

# 75. Verbindliche Regeln

1. Cash ist die primäre normale Währung.
2. Mining XP ist keine Währung.
3. Mining XP wird ausschließlich beim Verkauf vergeben.
4. Geldwert und XP-Wert eines Erzes sind getrennt.
5. Coal bleibt überall Coal und besitzt denselben Basiswert.
6. Zwei aufeinanderfolgende Minen können dieselbe Erzart besitzen.
7. Neue Erzarten werden wertvoller, aber nicht dauerhaft mit `2^n` skaliert.
8. Rare Drops gelten nur für manuelles Mining.
9. Rare Event ist entweder 1–10x Menge oder Rare Ore, nicht beides.
10. Rare Ore kann maximal aus ungefähr den nächsten vier Erzstufen stammen.
11. Rare Ores dürfen Progression nicht direkt überspringen.
12. Worker kosten einmaligen HireCost und laufendes Gehalt.
13. Worker sollen bei unbezahltem Gehalt nicht unbegrenzt weiterarbeiten.
14. Drills besitzen feste Produktionsraten und keine Rare Drops.
15. Storage und Elevator erhöhen Kapazität, nicht direkt den Erzpreis.
16. Erstes Fahrzeug besitzt aktuell 1.000 Kapazität.
17. Spieler fährt Verkaufsfahrzeuge selbst.
18. Verarbeitetes Material ist wertvoller als Rohmaterial.
19. Rohmaterial bleibt trotzdem sinnvoll verkaufbar.
20. Version 1 verwendet feste Materialpreise.
21. Dynamischer Markt wird nur architektonisch vorbereitet.
22. Offline-Produktion läuft maximal eine Stunde.
23. Offline-Produktion erzeugt Material, nicht automatisch Geld.
24. Mining-Level-System muss später weit über Level 100 erweiterbar sein.
25. Prestige wird ab Level 100 verfügbar.
26. Prestige gibt einen dauerhaften Bonus.
27. Prestige-Bonus darf nicht unkontrolliert exponentiell wachsen.
28. Robux-Käufe bleiben bei Prestige erhalten.
29. Balancewerte werden zentral und datengetrieben gespeichert.
30. Beispielwerte sind keine finalen Werte.
31. Economy wird mit Telemetrie und Playtests angepasst.
32. Zuerst wird ein kleiner Vertical Slice gebalanced.
33. Erst danach wird der Content massiv erweitert.
34. Das Spiel soll bewusst Engpässe erzeugen, aber keine stumpfen AFK-Hard-Walls.
35. Spieler soll regelmäßig zwischen mehreren sinnvollen Investitionen entscheiden können.
