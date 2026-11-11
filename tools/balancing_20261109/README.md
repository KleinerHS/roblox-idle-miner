# Economy-Rechenmodell – 2026-11-09

Status: TESTING_REQUIRED. Alle neuen Zahlen sind Vorschläge, keine Spielcodeänderung.

Die Revision vom 11.11.2026 wird aus den ursprünglichen Seeds und den gezielten Änderungen in `model.py` erzeugt. Der Standardlauf rechnet mit kaufbaren Fahrzeugen. Zwei zusätzliche Läufe berücksichtigen die Lastzüge. Der Standardlauf exportiert außerdem `definitions.json` gemeinsam mit `model.json`. Die Ergebnisse der aktuellen Revision stehen in `TESTING/BALANCING_2026-11-11.md`. Aussagen zur ursprünglichen Kalibrierung weiter unten beziehen sich auf den Stand vom 09.11.

## Reproduzieren

`python tools/balancing_20261109/model.py`

Der Standardlauf verwendet die nach echten Simulationen kalibrierten XP-Eingaben aus `xp_seed.json`. Er erzeugt `model.json` erneut. `--iterations N` führt optional zusätzliche XP-Kalibrierschritte aus und verändert dadurch das Ergebnis; für die veröffentlichte Arbeitskopie wurde der feste Standardlauf verwendet. `calibration_history.json` dokumentiert die letzte Kalibrierungsphase vor dem Schlusslauf. Zeiten in TARGETS sind Designziele; Simulationszeiten entstehen unabhängig davon aus Verkäufen, Bestand, Käufen und XP.

Die abschließende Drill-Prüfung korrigiert gerundete Doppelstufen: jeder neue Drill erzeugt je Fünf-Sekunden-Takt mindestens eine Einheit mehr als sein Vorgänger. `price_seed.json` hält dabei alle zuvor abgestimmten Preisvorschläge fest; Freischaltlevel und XP-Schwellen bleiben unverändert. Das finale Ergebnis ist der anschließend erneut durchgerechnete Standardlauf, nicht ein früherer Kalibrierungslauf.

Eine zweite gezielte Prüfung senkt ausschließlich MK12 von 350.000 auf 120.000 und MK18 von 2.400.000 auf 1.400.000 Cash. Dadurch werden beide nicht erst gemeinsam mit dem Nachfolger gekauft. Im finalen Referenzlauf haben alle 30 Typen tatsächlich produziert; zwischen allen 29 aufeinanderfolgenden Typkäufen liegt mindestens ein Verkauf, der kürzeste Zeitabstand beträgt 9,333 Minuten. Die vollständigen Zeitabstände stehen in `baseline_drill_purchase_gaps`, die tatsächliche Modellproduktion je Typ in `simulations[].drill_usage`. Es wurden dafür keine künstlichen Wartezeiten oder zusätzlichen Freischaltregeln eingeführt.

## Eingaben und Umfang

Bestehende IDs, Anzeigenamen und Quellzeilen kommen aus der ursprünglichen Balancing.xlsx. Der Quellpfad steht im Modell. Es werden keine Quellwerte überschrieben. Neue Definitionen enthalten 25 Spitzhacken, 22 Rucksäcke, 30 Drilltypen, 6 vorhandene Fahrzeuge, 100 Minen, 50 Erze, 22 Barren/Rezeptpaare, 10 Elevator-Upgrades, 192 Lagerkisten sowie Gebäude und zentrale Betriebswerte.

Das Modell benutzt zehn Sekunden je Schritt. Während einer Verkaufsfahrt wird nicht manuell abgebaut, die Firmenproduktion läuft weiter. XP entsteht nur aus verkauftem Rucksack-/Fahrzeugmaterial. Rucksack, Lager, Minenpuffer, Ofeneingang, Ofenausgang und Fahrzeug werden getrennt geführt. Verkäufe tragen ganze Stückzahlen ab; rechnerische Produktionsreste bleiben erhalten. Je zwei Erze werden zu einem Barren verarbeitet.

Alle Minen und persönlichen Ausrüstungsstufen werden in Reihenfolge bezahlt. Drilltypen werden einmalig freigekauft; typische Spieler platzieren die zwei neuesten gekauften Drills, das Automationsprofil vier. Ältere demontierte Drills liegen im Inventar. Zwei Worker arbeiten zusätzlich weiter. Daher ist dies ein transparenter Beispielfirmenpfad, keine Behauptung über jede mögliche Spielerstrategie.

## Prüfen

`simulations[].events` enthält Käufe, Verkäufe und Offlinegutschriften mit Cash- und XP-Zwischensummen. Die Cashidentität je Ereignis lautet:

`Startcash + CashSalesToDate + CashOfflineToDate − CashSpentToDate − WagesToDate = Cash`

Die unabhängige Materialbilanz rechnet Barren in zwei eingesetzte Erze um:

`Manuell produziert + automatisch produziert − Rohäquivalent verkauft − Rohäquivalent aller Endbehälter = 0`

Die XP-Bilanz lautet:

`Verkaufs-XP − Summe der bezahlten Levelschwellen − Rest-XP = 0`

Cashbilanzen gelten in allen zehn Läufen. Materialbilanzen werden in den sechs vollständig protokollierten Profil-/Prestigeläufen geprüft. Sensitivitäten speichern aus Platzgründen nur Zusammenfassungen/Snapshots, daher steht deren Materialbilanz auf null im Sinne von nicht verfügbar (JSON null), nicht auf einem behaupteten Prüfergebnis 0. Die XP-Bilanz wird auch in den Sensitivitäten geprüft.

## Grenzen

- Alle Annahmen und Einschränkungen stehen zusätzlich in `model.json`.
- Luck, außergewöhnliche Funde, Robux, Handel und optionale Luck-/Offline-/Büro-Upgrades sind nicht Teil der regulären Zielzeitläufe.
- Feste Wegezeiten sind Annahmen; keine Roblox-Studio-Messungen.
- Die unterschiedliche Dauer anderer Firmenstrategien ist ein Ergebnis, keine Fehlerfreiheit aller denkbaren Belegungen. Ein eigener analytischer 200-Slot-Belastungstest weist den Elevator-Engpass ausdrücklich aus.
- Offlinegeld bezahlt keine XP. Es kann große Cashüberschüsse erzeugen; nach Rückkehr bleibt aktiver Materialverkauf nötig.
- Wiederholtes Prestige wird mit sofort behaltenem persönlichen Equipment gerechnet. Der zweite Durchlauf liegt im Schlusslauf etwa 23 % unter dem ersten; der weiche 15%-Wunsch wird nicht durch künstliches Warten erzwungen.
- Die Excel-Arbeitskopie kann Eingaben und sichtbare Rechenbeziehungen ändern. Die hier berechneten Ereignissimulationen werden dadurch nicht automatisch neu ausgeführt.
