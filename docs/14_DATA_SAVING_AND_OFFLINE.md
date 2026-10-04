# 14 – DATA SAVING AND OFFLINE PRODUCTION

## 1. Ziel
Alle wichtigen Spieler- und Firmenzustände müssen sicher persistent gespeichert werden. Offline-Produktion ist auf maximal 1 Stunde begrenzt.

## 2. Persistente Hauptdaten
Mindestens:
- Cash
- Mining Level / XP
- Prestige Count / permanente Boni
- Firmenname, Logo, Farbe
- gekaufte/ausgerüstete Pickaxes
- gekaufte/ausgerüstete Backpacks
- Worker
- Storage-/Elevator-Upgrades
- Gebäudeprogression
- Owned/Placed Drills
- Owned/Placed Conveyors
- Owned Vehicles
- relevante Materialbestände
- Produktionszustände
- Robux-Entitlements
- Tutorial-/Unlockstatus
- letzter gültiger Logout-/Save-Zeitpunkt

## 3. Schema-Version
Gespeicherte Profile besitzen eine `DataVersion`. Migrationen müssen alte Profile kontrolliert auf neue Strukturen übertragen.

## 4. Serverautorität
Nur der Server verändert persistente Economy-Daten. Der Client sendet Wünsche, keine fertigen Ergebnisse.

## 5. Autosave
Regelmäßige Autosaves plus Save bei wichtigen Zustandswechseln. Save-Spam vermeiden. Beim Server-Shutdown werden Profile kontrolliert gespeichert.

## 6. Session Lock
Dasselbe Profil darf nicht gleichzeitig von zwei Servern widersprüchlich beschrieben werden. Eine Session-Lock-/Profile-Management-Lösung ist erforderlich.

## 7. Offline-Zeit
```text
OfflineSeconds = clamp(CurrentTime - LastValidTime, 0, 3600)
```
Maximal 3600 Sekunden Produktion.

## 8. Keine direkte Offline-Cash-Belohnung
Offline-Zeit simuliert Produktion in Materialbestände und Zwischenlager. Geld entsteht erst später beim Verkauf.

## 9. Produktionskette
Offline-Berechnung respektiert die reale Kette:
```text
Mine/Drill
→ local output
→ transport
→ elevator
→ storage
→ optional processing
→ output storage
```
Wenn ein Zwischenschritt voll wird, stoppt die nachgelagerte Simulation entsprechend.

## 10. Worker
Offline werden nur Worker berücksichtigt, die im gespeicherten Zustand gültig angestellt und einsetzbar waren. Gehälter und Zahlungsfähigkeit müssen berücksichtigt werden.

## 11. Keine NPC-Simulation
Offline werden keine Figuren physisch bewegt. Es wird mathematisch berechnet, wie viel Material innerhalb der verfügbaren Zeit und Kapazitäten hätte transportiert/produziert werden können.

## 12. Event-basierte Simulation
Nicht jede Sekunde einzeln simulieren. Berechnung soll anhand von Raten, Kapazitäten und Zeit bis zum nächsten Bottleneck erfolgen.

## 13. Smelter
Offline-Verarbeitung respektiert:
- Inputmenge
- Rezept
- Cycle/Rate
- Output Capacity
- Storage Capacity

## 14. Fahrzeuge
Offline fährt kein Fahrzeug automatisch zum Verkauf. Fahrzeugcargo bleibt Cargo. Verkaufsfahrten sind aktives Gameplay.

## 15. Offline-Zusammenfassung
Beim Login kann ein cleanes Fenster erscheinen:
```text
WHILE YOU WERE AWAY – 47 MIN

Coal produced: 620
Copper produced: 180
Processed bars: 95

Storage: 82% full
```
Nur serverseitig bestätigte Werte anzeigen.

## 16. Zeitmanipulation
Offline-Zeit wird serverseitig bestimmt. Lokale Gerätezeit des Clients ist keine vertrauenswürdige Quelle.

## 17. Prestige
Nach Prestige wird der Offline-Baseline-Zeitpunkt neu gesetzt. Alte Produktionszustände dürfen nicht nachträglich Material erzeugen.

## 18. Trade
Items in einer aktiven Transaktion dürfen nicht gleichzeitig gespeichert/dupliziert/platziert werden. Besitzänderungen müssen vor Save konsistent abgeschlossen sein.

## 19. Failure Handling
Bei DataStore-/Persistenzfehlern:
- keine stillen Datenüberschreibungen
- Retry mit kontrolliertem Backoff
- kritische Fehler protokollieren
- Spieler nicht mit einem leeren Defaultprofil über ein vorhandenes Profil überschreiben

## 20. Default Data
Neue Spieler erhalten eine zentrale Default-Datenstruktur. Defaults werden nicht an mehreren Stellen dupliziert.

## 21. Robux
Permanente Robux-Entitlements werden getrennt und sicher behandelt. Prestige darf sie nicht entfernen.

## 22. Verbindliche Regeln
1. Maximal 1 Stunde Offline-Produktion.
2. Offline produziert Material, kein direktes Cash.
3. Kapazitäten und Bottlenecks gelten offline.
4. Keine physische NPC-Simulation offline.
5. Serverzeit ist maßgeblich.
6. Daten besitzen Schema-Version.
7. Alte Daten müssen migrierbar sein.
8. Session Lock verhindert parallele widersprüchliche Profile.
9. Autosave und Shutdown-Save sind Pflicht.
10. Fehler dürfen bestehende Daten nicht mit leeren Defaults überschreiben.
11. Prestige setzt Offline-Baseline neu.
12. Fahrzeuge verkaufen offline nichts.
