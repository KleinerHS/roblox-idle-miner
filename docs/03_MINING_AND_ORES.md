# 03 – MINING AND ORES

## 1. Ziel

Dieses Dokument definiert das Mining-System, die Erzprogression, die manuellen Mining-Regeln, seltene Drops und die grundlegenden Regeln für Erzwerte.

Die konkreten Balancewerte werden später in einer eigenen Balancing-Phase getestet und angepasst. Alle Werte müssen deshalb datengetrieben und leicht veränderbar sein.

---

## 2. Erzprogression

Das Spiel besitzt zunächst 100 Minen.

Jede Erzart belegt zwei aufeinanderfolgende Minen. Damit ergeben sich zunächst 50 Erzarten.

| Minen | Erz |
|---|---|
| 01–02 | Coal |
| 03–04 | Copper |
| 05–06 | Tin |
| 07–08 | Iron |
| 09–10 | Lead |
| 11–12 | Zinc |
| 13–14 | Silver |
| 15–16 | Nickel |
| 17–18 | Cobalt |
| 19–20 | Chromium |
| 21–22 | Manganese |
| 23–24 | Aluminum |
| 25–26 | Titanium |
| 27–28 | Tungsten |
| 29–30 | Platinum |
| 31–32 | Palladium |
| 33–34 | Osmium |
| 35–36 | Iridium |
| 37–38 | Rhodium |
| 39–40 | Uranium |
| 41–42 | Mythril |
| 43–44 | Obsidian |
| 45–46 | Ruby |
| 47–48 | Sapphire |
| 49–50 | Emerald |
| 51–52 | Amethyst |
| 53–54 | Topaz |
| 55–56 | Aquamarine |
| 57–58 | Opal |
| 59–60 | Black Opal |
| 61–62 | Jade |
| 63–64 | Amber |
| 65–66 | Meteorite Ore |
| 67–68 | Star Metal |
| 69–70 | Luminous Crystal |
| 71–72 | Dragonstone |
| 73–74 | Netherium |
| 75–76 | Celestial Metal |
| 77–78 | Astralium |
| 79–80 | Aetherium |
| 81–82 | Void Ore |
| 83–84 | Darksteel |
| 85–86 | Sun Crystal |
| 87–88 | Moon Crystal |
| 89–90 | Galaxium |
| 91–92 | Cosmium |
| 93–94 | Quantium |
| 95–96 | Singularium |
| 97–98 | Primal Crystal |
| 99–100 | Diamond |

### Progressionsprinzip

- Mine 01 beginnt mit Coal.
- Die Erzarten werden schrittweise wertvoller.
- Die frühen Erze sind überwiegend reale Rohstoffe.
- Im späteren Spiel kommen zunehmend Fantasy-/Science-Fiction-Erze hinzu.
- Diamond ist aktuell das letzte Erz der Grundprogression.
- Die Erzliste muss in einer zentralen Konfiguration liegen und darf nicht hart in einzelne Scripts eingebaut werden.

---

## 3. Unendliche Erzadern

Erzadern sind unendlich.

Ein Spieler kann eine Mine dauerhaft nutzen. Das Erz wird nicht dauerhaft abgebaut und die Mine wird nicht leer.

Das bedeutet:

- keine zerstörbaren Erzblöcke als langfristiger Vorrat
- keine endlichen Minen
- keine zufällig irgendwann leer werdenden Minen
- Mining produziert Ressourcen aus einer permanent verfügbaren Erzquelle

Die Umgebung kann visuell Mining-Effekte zeigen, ohne dass die komplette Mine dauerhaft verändert werden muss.

---

## 4. Manuelles Mining

Der Spieler kann selbst mit seiner Spitzhacke Erz abbauen.

### Grundablauf

1. Spieler steht innerhalb der zulässigen Mining-Distanz.
2. Spieler schlägt mit der Spitzhacke.
3. Server validiert den Mining-Versuch.
4. Nach gültigem Hit wird Erz gutgeschrieben.
5. Visuelle und akustische Mining-Effekte werden ausgelöst.
6. Ein schwebender Text kann den erhaltenen Betrag anzeigen.
7. Wenn der Rucksack voll ist, wird kein weiteres Erz aufgenommen.

### Servervalidierung

Mining darf nicht ausschließlich clientseitig funktionieren.

Der Server muss mindestens prüfen:

- Spieler besitzt eine gültige Spitzhacke.
- Spieler befindet sich nahe genug an der Erzquelle.
- Mining-Cooldown ist eingehalten.
- Mine/Erzquelle ist gültig.
- Rucksackkapazität wird eingehalten.
- Der Spieler kann keine beliebigen Erztypen über RemoteEvents anfordern.

Ziel: einfache Exploits wie Speed-Mining, Fake-Ore-Requests oder Remote-Spam sollen verhindert werden.

---

## 5. Mining Power und Mining Speed

Die Spitzhacke beeinflusst mindestens:

### Mining Power

Bestimmt, wie viel Erz ein gültiger Mining-Hit erzeugt.

### Mining Speed

Bestimmt, wie schnell der Spieler erneut schlagen darf.

Bessere Spitzhacken sollen das aktive Mining spürbar verbessern.

Die genauen Werte werden später balanciert.

---

## 6. Erzmenge pro Hit

Die genaue Menge pro Hit wird noch nicht endgültig festgelegt.

Grundidee:

- frühe Spitzhacke: geringe Produktionsmenge
- bessere Spitzhacken: höhere Produktionsmenge
- Mining Power wird zentral konfiguriert
- die Werte dürfen nicht unkontrolliert exponentiell anwachsen

Die Balance soll so gestaltet werden, dass aktives Mining relevant bleibt, aber Automation im späteren Spiel deutlich größere Produktionsmengen erreichen kann.

---

## 7. Seltene Drops

Seltene Drops gibt es ausschließlich beim manuellen Mining durch den Spieler.

Worker und Drills erzeugen keine Rare Drops.

Bei einem erfolgreichen manuellen Mining-Hit kann zusätzlich ein besonderer Drop ausgelöst werden.

### Rare-Drop-Ergebnis

Der Rare Drop ist genau eine von zwei Möglichkeiten:

**Variante A – Extra-Menge des aktuellen Erzes**

Der Spieler erhält zusätzlich eine zufällige Menge des aktuell abgebauten Erzes:

- 1× bis 10× der normalen Erzmenge

**ODER**

**Variante B – seltenes Erz aus der Zukunft**

Der Spieler erhält ein einzelnes Erz aus den nächsten vier besseren Erzarten.

Beispiel:

Spieler baut Iron ab.

Mögliche seltene Zukunftserze:
- Lead
- Zinc
- Silver
- Nickel

Der Spieler erhält dabei genau ein seltenes Erz.

Es werden nicht beide Varianten gleichzeitig ausgelöst.

> **Entscheidung D-006:** Rare Drops kommen nicht in Vertical Slice A, sondern direkt danach. Ist der Rucksack bei einem Rare Drop fast voll, darf der Drop die Kapazität einmalig überschreiten, nichts geht verloren. Danach greift `BACKPACK FULL` normal.

### Wichtig

Rare Drops dürfen nicht dazu führen, dass Spieler durch einen einzigen Hit völlig aus der normalen Progression herauskatapultiert werden.

Die Dropchance und die genaue Balance werden später getestet.

---

## 8. Rare-Drop-Feedback

Ein Rare Drop soll deutlich sichtbar sein.

Mögliche Effekte:

- große Floating-Text-Anzeige
- „RARE DROP!“
- Name des erhaltenen Erzes
- Glow
- Partikel
- kurzer besonderer Sound
- etwas stärkere Bildschirm-/UI-Reaktion

Beispiel:

**RARE DROP!**  
**+1 Silver**

Das Feedback darf auffällig sein, ohne den normalen Spielfluss dauerhaft zu stören.

---

## 9. Erzvisualisierung

Erze werden als farblich erkennbare Ablagerungen in der Felswand dargestellt.

### Anforderungen

- Keine einfachen rechteckigen grauen Erzblöcke.
- Fels soll handgehauen und unregelmäßig wirken.
- Erzadern sollen in der Wand eingebettet sein.
- Seltene Erze sollen visuell deutlich erkennbar sein.
- Höhere Erzstufen dürfen stärker leuchten oder besondere Materialien/Partikeleffekte besitzen.
- Die Visualisierung muss performant bleiben.

Die Mine soll wie ein echter, stilisierter Minenschacht wirken und nicht wie eine Ansammlung von Würfeln.

---

## 10. Zwei Minen pro Erz

Jede Erzart besitzt zunächst zwei Minen.

Beispiel:

- Mine 01–02 = Coal
- Mine 03–04 = Copper
- Mine 05–06 = Tin

Die beiden Minen derselben Erzart können sich visuell leicht unterscheiden, müssen aber dieselbe grundlegende Erzquelle und Progressionsstufe besitzen.

---

## 11. Erzwerte und XP

### Erzpreis

Jede Erzart besitzt einen eigenen Basiswert.

Der Verkaufspreis eines Erzes ist unabhängig von der XP-Menge.

### XP

XP wird ausschließlich durch Verkäufe vergeben.

Mining selbst gibt keine XP.

Ein seltener Drop kann wertvoller für die Progression sein, aber XP wird erst beim Verkauf vergeben.

### Wichtig

**Erzwert ≠ XP-Wert**

Die Systeme müssen getrennt konfigurierbar sein.

---

## 12. Verdopplungsprinzip

Als Ausgangspunkt gilt:

> Jede nächste Erzart soll ungefähr den doppelten Basiswert bzw. die doppelte grundlegende wirtschaftliche Bedeutung der vorherigen Erzart besitzen.

Dieses Prinzip ist zunächst ein Balancing-Leitfaden und keine starre mathematische Formel.

Der Grund:

Eine echte Verdopplung über alle 50 Erzarten würde zu absurden Zahlen führen.

Beispielsweise würde eine streng mathematische Verdopplung nach sehr vielen Stufen Werte erzeugen, die für ein Roblox-Spiel wirtschaftlich und technisch unpraktisch wären.

Deshalb wird später ein kontrolliertes Wachstumssystem entwickelt.

Mögliche spätere Lösung:

- logarithmisches oder gestaffeltes Wachstum
- verschiedene Preisbereiche
- Multiplikatoren je Progressionsabschnitt
- Begrenzung von Geld- und XP-Zahlen
- kompakte Zahlendarstellung wie 1.25K, 3.4M, 8.2B usw.
- getrennte Skalierung von Preis, Produktionsmenge und XP

**Die endgültige Formel wird bewusst noch nicht festgelegt.**

---

## 13. Keine absurden Zahlen

Das Spiel soll sich trotz 100 Minen und 50 Erzarten kontrolliert anfühlen.

Zu vermeiden:

- unnötige Zahlen mit dutzenden Stellen
- unlesbare Geldbeträge
- extrem große XP-Werte ohne spielerischen Nutzen
- Overflow-/Precision-Probleme
- Balance, die nur durch immer größere Zahlen funktioniert

Die Wirtschaft wird später gemeinsam mit der Gesamtprogression berechnet.

---

## 14. Rohmaterial und verarbeitete Materialien

Rohes Erz bleibt verkaufbar.

Verarbeitetes Material aus dem Smelter kann ebenfalls verkauft werden.

Dadurch entstehen zwei mögliche Spielweisen:

- Rohmaterial direkt verkaufen
- Material weiterverarbeiten und anschließend verkaufen

Die Verarbeitung soll wirtschaftlich sinnvoll sein, darf aber nicht dazu führen, dass Rohmaterial komplett nutzlos wird.

---

## 15. Automation

Worker und Drills verwenden dasselbe grundlegende Erz-/Produktionssystem wie manuelles Mining.

Unterschied:

- Spieler kann Rare Drops erhalten.
- Worker erhalten keine Rare Drops.
- Drills erhalten keine Rare Drops.
- Automatisierte Produktion ist planbarer.
- Aktives Spielen bleibt durch Rare Drops und direktes Mining interessant.

---

## 16. Datenstruktur

Alle Erzarten sollen zentral konfiguriert werden.

Beispielhafte Struktur:

```lua
OreDefinitions = {
    Coal = {
        MineStart = 1,
        MineEnd = 2,
        BaseValue = 1,
        XPValue = 1,
        Tier = 1,
    },

    Copper = {
        MineStart = 3,
        MineEnd = 4,
        BaseValue = 2,
        XPValue = 2,
        Tier = 2,
    },
}
```

Die tatsächlichen Werte sind nur Beispiele und dürfen nicht als finale Balance übernommen werden.

Die Definitionen sollen später einfach erweitert oder geändert werden können.

---

## 17. Was noch nicht final gebalanced ist

Folgende Werte werden erst nach Aufbau des funktionierenden Systems festgelegt:

- exakte Erzpreise
- XP pro verkauftem Erz
- Mining Power pro Spitzhacke
- Mining Speed pro Spitzhacke
- Erzmenge pro Hit
- Rare-Drop-Chance
- Verteilung der Rare-Drop-Wahrscheinlichkeiten
- Worker-Produktion
- Drill-Produktion
- Smelter-Multiplikatoren
- Produktionszeiten
- Verkaufswerte verarbeiteter Materialien
- Level-Anforderungen der Minen
- Geldkosten der Minen
- genaue Zahlenprogression über Mine 01–100

Diese Werte müssen zentral konfigurierbar sein.

---

## 18. Ziel des Mining-Systems

Das Mining-System soll drei Dinge gleichzeitig erreichen:

1. **Aktives Spielen:** Der Spieler kann jederzeit selbst effektiv minen.
2. **Automation:** Worker und Maschinen bauen zuverlässig Ressourcen ab.
3. **Langzeitprogression:** Neue Minen, bessere Erze und bessere Produktionssysteme geben einen klaren Fortschritt.

Keiner dieser Bereiche soll die anderen vollständig entwerten.

---

## 19. Harte Designregeln

Diese Regeln gelten als verbindlich:

- 100 Minen in der ersten Grundprogression.
- 50 Erzarten.
- Zwei Minen pro Erzart.
- Diamond ist Mine 99–100.
- Erzadern sind unendlich.
- Rare Drops ausschließlich beim manuellen Mining.
- Worker und Drills bekommen keine Rare Drops.
- Rare Drop ist entweder Extra-Menge des aktuellen Erzes ODER ein einzelnes Erz aus den nächsten vier besseren Erzarten.
- XP gibt es ausschließlich beim Verkauf.
- Erzpreis und XP-Wert sind getrennte Werte.
- Rohes und verarbeitetes Material kann verkauft werden.
- Alle Balancewerte sind zentral konfigurierbar.
- Keine unkontrollierte Zahlenexplosion.
- Mining muss serverseitig validiert werden.
