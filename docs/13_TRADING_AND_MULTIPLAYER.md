# 13 – TRADING AND MULTIPLAYER

## 1. Ziel
Das Spiel bleibt primär ein Solo-Idle-/Mining-Company-Spiel. Multiplayer ergänzt den Core Loop, ersetzt ihn aber nicht.

## 2. Serverstruktur
- Maximal 6 aktive Firmenplots pro Server.
- Jeder Spieler erhält einen eigenen Plot.
- Produktionsdaten, Gebäude, Worker, Maschinen, Lager und Fahrzeuge gehören eindeutig einem Spieler.
- Andere Spieler dürfen fremde Produktionssysteme ansehen, aber nicht bedienen, abbauen oder verändern.

## 3. Spielerbesuche
Spieler dürfen andere Grundstücke und die gemeinsame Bergbaustadt besuchen. Fremde Tycoon-Buttons, Laptop, Maschinen-Slots, Lager, Garage und Firmenmanagement sind gesperrt.

## 4. Kollisionen
Spielerfahrzeuge kollidieren nicht miteinander. Spieler sollen sich gegenseitig nicht blockieren können. Welt und feste Infrastruktur besitzen weiterhin sinnvolle Kollision.

## 5. Handel
Geplant ist direkter Spieler-zu-Spieler-Handel für:
- Erze/Materialien
- ausgewählte Drills

Andere Gegenstandskategorien sind nicht automatisch handelbar.

## 6. Trade-Ablauf
```text
Player A sends request
→ Player B accepts
→ Trade window opens
→ both add items/materials
→ both see exact offer
→ both lock offer
→ short confirmation state
→ both confirm
→ server executes atomic exchange
```

## 7. Trade-UI
Das Fenster zeigt beide Seiten getrennt:
```text
YOUR OFFER                 THEIR OFFER
Coal x500                  Copper x200
Drill MK2 x1               —

[LOCK OFFER]               Waiting...
```
Nach jeder Angebotsänderung werden vorherige Bestätigungen zurückgesetzt.

## 8. Sicherheit
Der Server validiert unmittelbar vor Abschluss:
- beide Spieler noch verbunden
- Distanz/Trade-Session gültig
- angebotene Mengen noch vorhanden
- Drill-Instanz gehört tatsächlich dem Anbieter
- Item handelbar
- kein Item aktuell platziert/gesperrt
- keine negativen/ungültigen Mengen

Die Übertragung erfolgt atomar: entweder vollständig oder gar nicht.

## 9. Drill-Trading
Handelbare Drills sollen eindeutige Instance IDs besitzen. Ein platzierter Drill kann nicht direkt gehandelt werden; er muss zuerst sicher ausgebaut und als verfügbarer Besitz geführt werden.

## 10. Erzhandel
Materialhandel nutzt exakte serverseitige Mengen. Materialien dürfen nicht durch Clientwerte erzeugt werden. Ein Trade darf keine Mining XP erzeugen. XP entsteht weiterhin nur beim echten Verkauf.

## 11. Kein globaler Marktplatz in V1
V1 benötigt kein Auction House und keinen globalen Markt. Direkte Trades reichen. Das reduziert Exploits und hält den Fokus auf der eigenen Firma.

## 12. Trade-Einstellungen
Spieler sollen Trade Requests deaktivieren können. Spam benötigt Cooldowns und pro Spieler nur eine aktive Trade-Session.

## 13. Firmenfarben
Jeder Spieler besitzt seine gewählte Firmenfarbe. Sie erscheint dezent an Plot-Schild, UI-Akzenten und geeigneten Firmen-/Fahrzeugelementen. Spielerplots bleiben dadurch schnell unterscheidbar.

## 14. Gemeinsame Stadt
Die drei Shops und die Verkaufsstelle sind gemeinsam nutzbare Weltbereiche. Käufe und Verkäufe bleiben immer dem jeweiligen Spielerzustand zugeordnet.

## 15. Minen
Die Mine-Shaft-Erfahrung ist spielerbezogen. Andere Spieler dürfen niemals Mining-Slots, Worker oder Drills eines fremden Spielers übernehmen. Die technische Instanzierung/Zuordnung wird so gebaut, dass Produktionszustände nicht vermischt werden.

## 16. Verkauf
Jeder Spieler verkauft nur eigene Materialien aus eigenem Backpack/Fahrzeug. Fremde Fahrzeuge können nicht entladen oder verkauft werden.

## 17. Fahrzeugrechte
Nur der Besitzer bzw. serverseitig autorisierte Spieler darf ein Firmenfahrzeug benutzen. Fremde Spieler dürfen kein Cargo manipulieren.

## 18. Keine PvP-Mechanik
Kein:
- Stehlen
- Sabotieren
- fremde Worker töten
- Maschinen zerstören
- Erz aus fremden Lagern nehmen
- Fahrzeugdiebstahl

## 19. Serverwechsel
Persistente Daten dürfen nicht an einen bestimmten Server gebunden sein. Beim Wechsel werden Firmenfortschritt und handelbarer Besitz aus dem persistenten Profil rekonstruiert.

## 20. Disconnect während Trade
Bei Disconnect vor Commit wird der Trade abgebrochen und nichts übertragen. Bei Commit muss die serverseitige Transaktion eindeutig abgeschlossen oder vollständig zurückgerollt werden.

## 21. Trade Logging
Für spätere Exploit-/Supportanalyse sollen wichtige Trade-Daten protokollierbar sein:
- Trade ID
- User IDs
- Zeit
- Item IDs / Instance IDs
- Materialmengen
- Ergebnis

Keine unnötigen personenbezogenen Inhalte speichern.

## 22. Verbindliche Regeln
1. 6 Spielerplots pro Server.
2. Kernspiel bleibt Solo.
3. Fremde Firmen dürfen nicht verändert werden.
4. Fahrzeuge kollidieren nicht miteinander.
5. Erze und ausgewählte Drills sind handelbar.
6. Trade erzeugt keine Mining XP.
7. Direkte Trades statt Auction House in V1.
8. Tradeabschluss ist serverautoritativ und atomar.
9. Angebotsänderung setzt Bestätigung zurück.
10. Platzierte Drills sind nicht handelbar.
11. Drill-Instanzen werden duplikationssicher identifiziert.
12. Trade Requests können deaktiviert werden.
13. Kein PvP/Stehlen/Sabotieren.
14. Fremdes Cargo und fremde Fahrzeuge sind geschützt.
15. Multiplayer darf die Solo-Progression nicht erzwingen.
