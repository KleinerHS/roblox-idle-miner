# Übergabe der Balancing-Revision an Claude

Stand 11.11.2026. Felix hat größere Fahrzeugladungen beauftragt. Die Spielzeiten sind Richtwerte. Der Fortschritt soll sich auch im späten Spiel regelmäßig lohnen. Die Spielumsetzung übernimmt Claude in separaten Hauptschritten nach der Freigaberegel aus `AGENTS.md`.

## Aktuelle Eingaben

- `outputs/balancing-20261111/Balancing_Neuentwurf.xlsx` enthält die aktuelle Arbeitskopie.
- `tools/balancing_20261109/definitions.json` enthält die aktuellen Einzelwerte für die Übernahme nach stabilen IDs.
- `tools/balancing_20261109/model.json` enthält in `xp_curve` die XP-Schwelle für jeden Übergang von Level 1 bis 120 sowie die überprüften Simulationsläufe.
- `tools/balancing_extras_20261109/extras.json` enthält die separat festgelegten Vorschläge für seltene Funde, Luck und Offline-Upgrades vom 09.11. Diese Vorschläge haben ihren ursprünglichen Rechenstand.

## Fahrzeugfracht und Schmelzer

| Fahrzeug | ID | Neue Fracht |
|---|---|---:|
| Pickup | `vehicle_pickup` | 6.000 |
| Cargo Van | `vehicle_van` | 12.000 |
| High-Roof Van | `vehicle_boxtruck` | 24.000 |
| Box Truck | `vehicle_truck` | 110.000 |
| Tipper Road Train | `vehicle_hauler` | 145.000 |
| Grain Road Train | `vehicle_roadtrain` | 180.000 |

Die kaufbare Fahrzeugreihe im Teststand umfasst die ersten vier Fahrzeuge. Die Lastzüge sind eine zusätzliche Modellvariante und werden nach dem vorgesehenen Fahrtest separat freigegeben. Fahrzeugfracht und Firmenlager sind verschiedene Kapazitäten.

Zielwert des Schmelzers sind 1.500 Barren pro Minute bei ausreichendem Eingangsmaterial und Ausgangsplatz. Das entspricht rechnerisch 0,04 Sekunden je Barren oder 25 Barren pro Sekunde. `SmelterService` verarbeitet im aktuellen Sekundentakt höchstens einen Barren. Claude muss die Verarbeitung daher bündeln und Menge, Rezeptbedarf und freien Platz gemeinsam begrenzen. Zwei Erze ergeben einen Barren.

`LoadingService` reserviert schmelzbares Roherz für den Ofen, sobald er gebaut ist. Bei fehlendem Förderweg oder vollem Ofeneingang kann es im Lager liegen bleiben. Im Teststand den Materialfluss und die Rohverkaufsregel zusammen prüfen. Das Modell verkauft überschüssiges Roherz. Eine Möglichkeit für die Umsetzung ist, der Verarbeitung Vorrang zu geben und Restmaterial bei Rückstau weiterhin zur Beladung zuzulassen.

## Fortschritt und gespeichertes Profil

Der XP-Bedarf sinkt gegenüber dem früheren Entwurf ab Level 60 schrittweise um bis zu 35 %. Späte Minen werden um bis zu 30 % und späte Drill-Typen um bis zu 18 % günstiger. Dadurch verteilt sich der beschleunigte Fortschritt auch auf bezahlbare Käufe. Die Einzelwerte im neuen Export sind maßgeblich. Neue Wartepflichten zwischen Käufen sind kein Bestandteil des Entwurfs.

Die XP-Tabelle und individuellen Minenpreise brauchen eine passende Auswertung im Spiel. Alle 192 Kistenpreise gehören in die Preisliste. Für XP ab Level 121 braucht es eine Fortsetzung, falls Spieler über Prestige hinaus leveln. Im Modell enthaltene Vorgängerkäufe mit der gewünschten Shopregel abgleichen. Rezeptzuordnung über Input- und Output-ID vornehmen, damit die bestehende Rezept-ID erhalten bleibt.

Felix hat einen vorhandenen Spielstand. Diesen separat im Studio prüfen und vor der Umstellung sichern. Besonders Rest-XP im aktuellen Level und gespeicherte Elevator-Kapazität prüfen. Eine Möglichkeit ist, den erreichten Level und den relativen Fortschritt innerhalb des Levels zu erhalten.

## Weitere vereinbarte Systeme

- Offline-Cash startet bei 30 % automatischer Firmenleistung für maximal acht Stunden. Auszahlungszeit und Betrag gemeinsam speichern und auf einmalige Auszahlung prüfen. Die Entscheidung in Q-037 zum Verhältnis zu untätigem Onlinebetrieb ist offen.
- Beim Prestige bleiben normale Spitzhacken und Rucksäcke sofort nutzbar. Fahrzeuge, Luck und Firmenausbau werden zurückgesetzt. Bestätigungstext und Serververhalten abgleichen.
- Vorgeschlagene seltene Funde getrennt von der minenerzeugenden Erzliste registrieren. Verkaufswert, XP, Fundanzeige und Handel serverseitig prüfen.

## Roblox-Studio-Tests

1. Mit bekanntem Erzbestand eine Minute schmelzen. Bei ausreichendem Material und Platz soll der Durchsatz nahe 1.500 Barren liegen. Bei vollem Ausgang Materialerhaltung prüfen.
2. Box Truck mit 110.000 Einheiten beladen und verkaufen. Eine Firma mit zwei und danach vier betriebenen Drills testen. Produktionsmenge, Fahrtzeiten, Frachtreserve und Rückstau über mehrere Verkäufe messen.
3. Mit einem frischen Profil den ersten Verkauf und Level 10 spielen. Mit einem späten Testprofil prüfen, ob der nächste sinnvolle Kauf sichtbar und in vertretbarer Zeit bezahlbar ist. Mehrere verschiedene Spielweisen verwenden.
4. Felix' gesichertes Profil laden, Fortschritt und Elevator-Stufe prüfen und den ersten Verkauf nach der Umstellung beobachten. Offline-Auszahlung, Wiederanmeldung und Prestige separat testen.

Die modellierten Spielzeiten und Frachtreserven stehen im [Checkpoint der Revision](../TESTING/BALANCING_2026-11-11.md).
