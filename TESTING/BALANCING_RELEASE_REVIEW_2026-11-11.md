# Prüfung vor der Spielübernahme am 11.11.2026

**Status** `TESTING_REQUIRED`. Die Arbeitskopie ist eine Rechengrundlage für einen Roblox-Studio-Teststand. Die Veröffentlichung setzt die unten beschriebenen Anpassungen und Spieltests voraus.

Geprüft wurden die Excel-Arbeitskopie vom 09.11., die zugehörigen Modellwerte und der aktuelle Server- und Clientcode. Die Meilensteine in Excel stimmen mit dem Referenzlauf überein. Für die Veröffentlichung entscheidend sind die folgenden Abweichungen zwischen Modell und Spiel.

## Schmelzer und Verladung

Die Arbeitskopie setzt 0,02 Sekunden je Barren an, entsprechend bis zu 3.000 Barren pro Minute. Der Server verarbeitet pro Sekundentakt maximal einen Barren. Ein Wechsel des Zahlenwerts ergibt daher höchstens 60 Barren pro Minute. Die Fahrzeugverladung hält schmelzbares Roherz bereits zurück, sobald der Ofen gebaut ist. Bei einem Rückstau kann folglich Material im Lager liegen, das der Spieler nicht aufladen kann. Das Modell kann dieses Roherz mitnehmen. Vor der Übernahme müssen Verarbeitungskapazität und Verkaufsregel zusammenpassen. [Schmelzer](../src/server/Services/SmelterService.luau#L96) · [Sekundentakt](../src/server/Services/SmelterService.luau#L272) · [Verladung](../src/server/Services/LoadingService.luau#L166) · [Modell](../tools/balancing_20261109/model.py#L356)

## Fahrzeuge, Verkäufe und Wege

Der Referenzlauf kauft `vehicle_hauler` und `vehicle_roadtrain`. Beide stehen im aktuellen Autohaus bis zum Fahrtest auf `Available = false`. Für einen Start mit den vier kaufbaren Fahrzeugen verfehlt die Fracht im Modell das Ziel von 15 Minuten. [Fahrzeugdefinitionen](../src/shared/Definitions/Vehicles.luau#L102) · [Fahrtestplan](../PLANS/ROAD_TRAINS.md#L67)

Die Gegenproben verwenden dieselben Preise und XP-Schwellen. Sie wurden mit geänderten Annahmen im Arbeitsspeicher gerechnet.

| Modellvariante | Level 50 | Level 100 | Kürzeste Frachtreserve |
|---|---:|---:|---:|
| Referenz | 5,67 h | 30,53 h | 29,34 min |
| Vier kaufbare Fahrzeuge | 5,67 h | 33,25 h | 10,25 min |
| Schmelzer maximal 60 Barren/min | 6,14 h | 32,08 h | 24,84 min |
| Beide Einschränkungen | 6,14 h | 34,81 h | 10,25 min |

Diese Zeiten bleiben Modellwerte. Das Spiel verkauft Fahrzeugfracht während der Fahrt und Rucksackmaterial zu Fuß. Die Simulation fasst beides in einer Fahrt zusammen und kauft bzw. versetzt Ausrüstung ohne einzelne Shop- und Schachtwege. Sie lässt außerdem bei allen Gegenproben den Verkauf schmelzbarer Rohstoffe über Fahrzeuge zu. Fahrzeit, Rangieren, Laden, Aussteigen und Drillplatzierung müssen im Teststand gemessen werden. [Verkaufsablauf](../src/server/Services/SellingService.luau#L91) · [Drillplatzierung](../src/server/Services/DrillService.luau#L87) · [Modellverkauf](../tools/balancing_20261109/model.py#L380)

## Wertetransfer und Spielstände

- Die neuen XP-Schwellen, Minenpreise und Kistenpreise sind Einzelwerte. Das Spiel berechnet XP und Minenpreise mit Kurven. Die 192 Kistenpreise passen in die vorhandene Preisliste, wenn alle Einträge übernommen werden. Das Eintragen des neuen Wachstumsfaktors allein würde die Preise nach den ersten drei Kisten konstant halten. Für Level ab 121 braucht die XP-Berechnung eine definierte Fortsetzung, da Prestige freiwillig bleibt. [XP](../src/shared/Util/Leveling.luau#L11) · [Minen](../src/shared/Definitions/Mines.luau#L19) · [Kistenpreise](../src/shared/Util/CrateLogic.luau#L63)
- Der Ausrüstungs- und Maschinenshop prüft derzeit Preis und Freischaltlevel. Die im Modell bezahlten Vorgängerstufen brauchen eine entsprechende Kaufregel oder einen weiteren Modelllauf nach den bestehenden Shopregeln. [Shop](../src/server/Services/ShopService.luau#L131) · [Maschinenkauf](../src/server/Services/ShopService.luau#L181)
- Altprofile speichern Rest-XP des aktuellen Levels und die Elevator-Kapazität. Ein Level-50-Profil mit 95 % des alten XP-Bedarfs hätte etwa 24,29 Mio. Rest-XP. Bei unverändertem Restwert wäre damit im neuen System schon Level 77 erreichbar, sobald der nächste Verkauf das Level aktualisiert. Ein gespeicherter Elevator mit 10.000 Einheiten liegt außerdem über dem neuen Maximum von 2.200. Vor dem Einsatz mit Altprofilen sind Fortschritts- und Kapazitätsmigration sowie der Umgang mit Beständen zu testen. [Datenschema](../src/server/Data/DataSchema.luau#L29) · [Elevator-Kapazität](../src/server/Data/DataSchema.luau#L72) · [Stufenerkennung](../src/shared/Definitions/Upgrades.luau#L37)
- Reguläre Erz-, Ausrüstungs- und Fahrzeug-IDs passen zum Modell. Die Rezept-IDs unterscheiden sich, etwa `recipe_bar_copper` im Modell und `recipe_copper` im Spiel. Die Zuordnung erfolgt über die stabilen Erz- und Barren-IDs. [Modellrezepte](../tools/balancing_20261109/model.py#L121) · [Spielrezepte](../src/shared/Definitions/Recipes.luau#L69)

## Offline, Prestige und seltene Funde

- Offline berechnet das Spiel Material für bis zu eine Stunde. Die vereinbarten acht Stunden bei 30 % Cash brauchen Berechnung, Oberfläche und eine einmalige Verbuchung von Auszahlung und Zeitgrenze im Profil. Q-037 hält die offene Entscheidung zum Vorteil gegenüber untätigem Onlinebetrieb fest. [Offline-Service](../src/server/Services/OfflineService.luau#L23) · [Zeitgrenze](../src/shared/Config/GameConfig.luau#L28) · [Q-037](../QUESTIONS/OPEN_QUESTIONS.md#q-037--offline-cash-gegenüber-untätigem-onlinebetrieb)
- Der aktuelle Prestige-Reset behält Fahrzeuge und Luck. Die neue Besitzregel und der Bestätigungstext müssen gemeinsam umgestellt werden. Behaltene Spitzhacken und Rucksäcke lassen sich beim bestehenden Besitzcheck sofort ausrüsten. [Reset](../src/server/Util/PrestigeReset.luau#L15) · [Bestätigung](../src/client/UI/Strings.luau#L273) · [Ausrüsten](../src/server/Services/ShopService.luau#L162)
- Die 150 vorgeschlagenen Fundvarianten brauchen Definitionen für Verkauf und Anzeige. Die reguläre Erzliste erzeugt zwei Minen je Eintrag. Deshalb brauchen die Varianten einen eigenen Materialtyp oder eine getrennte Registrierung. Für die vorgeschlagene Handelssperre ist eine Serverprüfung nötig. Auch die neuen Luck-Stufen und die Anzeige sehr kleiner Chancen brauchen Anpassungen. [Materialregister](../src/shared/Definitions/Materials.luau#L22) · [Minen-Erzeugung](../src/shared/Definitions/Mines.luau#L33) · [Handel](../src/server/Services/TradeService.luau#L119) · [Luck-Logik](../src/shared/Util/RareDropLogic.luau#L34)

## Roblox-Studio-Testanleitung für den nächsten Hauptschritt

1. Nach Freigabe einen separaten Teststand mit den übernommenen Tabellen und angepassten Regeln vorbereiten. Mit einem frischen Profil einen ersten Verkauf, das erste Upgrade und Level 10 spielen. Spielzeit und Cash, XP sowie gekaufte Voraussetzungen protokollieren.
2. Mit bekanntem Rohstoffbestand und begrenzten Puffern den Schmelzer eine Minute laufen lassen. Durchsatz und erhaltene Rohstoffmenge prüfen. Anschließend die Fahrzeugverladung mit Rohmaterial und Barren testen.
3. Den Fahrtest für beide Lastzüge mit Laden, Rangieren und Verkaufen durchführen. Die Fahrt mit der tatsächlich kaufbaren Fahrzeugreihe wiederholen und den 15-Minuten-Puffer prüfen. Rucksackverkauf getrennt messen.
4. Kopien bestehender Profile mit Rest-XP, gekauften Gegenständen, Elevator-Stufe und Material im Puffer laden. Level, relativen Fortschritt und Materialerhaltung prüfen. Beim nächsten Verkauf auf unerwartete Levelsprünge achten.
5. Offline mit kurzer Abwesenheit und oberhalb der Acht-Stunden-Grenze testen. Auszahlung beim Rejoin und Serverwechsel einmalig bestätigen. Prestige anschließend mit Fahrzeugen, Luck und Spitzhacke/Rucksack prüfen. Anzeigen und tatsächlich behaltenen Besitz vergleichen.
6. Einen seltenen Fund kontrolliert auslösen und Preis, XP, Anzeige und Handelsregel prüfen. Erst danach Spielzeiten und Kapazitätswerte für die Veröffentlichung bestätigen.

Für diese Prüfung wurden Quellcode und Arbeitskopie gelesen und Gegenproben gerechnet. Die Studio-Prüfung der neuen Werte setzt einen Teststand voraus.
