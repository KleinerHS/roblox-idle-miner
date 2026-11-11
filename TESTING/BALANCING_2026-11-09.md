# Balancing-Rechenentwurf – 2026-11-09

Status: TESTING_REQUIRED. Zielbild durch Felix mit „weiter“ für diesen Excel-Rechenschritt freigegeben; neue Zahlen und Spielumsetzung noch nicht USER_APPROVED.

Arbeitskopie: `outputs/balancing-20261109/Balancing_Neuentwurf.xlsx`. Originaldatei auf dem Desktop bleibt unverändert. Keine Änderung an `src/` oder Spielständen.

## Inhalt

24 Blätter: zwölf ursprüngliche Blätter mit erhaltenen numerischen Istwerten plus Ergebnis, Modellannahmen, neue Rezepte, zehn Simulationsläufe, Levelstände, Kauf-/Verkaufsereignisse, Upgrade-Stufen, Sonderfunde, Fundwahrscheinlichkeiten, Kapazitätsvorschau, Belastungstest und Eingabeabgleich.

Vorschläge für 25 Spitzhacken, 22 Rucksäcke, 30 Drill-Typen, sechs Fahrzeuge, zehn Elevator-Stufen, 100 Minen, 50 reguläre Erze, 22 Barren/Rezepte und 192 Kistenpreise. Dazu Worker, Gebäude, Förderband, Drill-Level, Luck, Offline-Upgrades und drei manuelle Fundqualitäten je Quellerz (150 vorgeschlagene Varianten-IDs). Neue Inhalte sind keine bereits existierenden Spielgegenstände.

## Tatsächlich berechnete Zeiten

Referenz: neue Firma ohne Robux, Handelsgeschenke oder Zufallsfunde; zwei frühe Worker und zwei jeweils neueste gekaufte Drilltypen. Andere gekaufte Drills liegen im Inventar. Keine neue Begrenzung auf zwei Drills im Spiel behauptet. Managementzeit wird über abnehmende manuelle Aktivitätsanteile berücksichtigt. Laufwege sind Modellannahmen, keine Studio-Messwerte.

| Meilenstein | Ziel | Berechneter Referenzlauf |
|---|---:|---:|
| Erster Verkauf und erstes Upgrade | 1–4 Minuten | 2,0 Minuten |
| Erster Worker | 8–12 Minuten | 9,7 Minuten |
| Level 10 / erster Drill | 30 Minuten | 29,2 Minuten |
| Level 25 | 2 Stunden | 1,90 Stunden |
| Level 50 | 6 Stunden | 5,67 Stunden |
| Level 60 | 8,5 Stunden | 8,39 Stunden |
| Level 75 | 14 Stunden | 14,17 Stunden |
| Level 90 | 22 Stunden | 22,36 Stunden |
| Level 100 / Prestige verfügbar | 30 Stunden | 30,53 Stunden |
| Zweiter Durchlauf | ca. 15 % kürzer als grober Wunsch | 23,95 Stunden, ca. 21,5 % kürzer |

Felix akzeptiert ausdrücklich einen stärker beschleunigten Anfang mit sofort nutzbaren behaltenen Spitzhacken/Rucksäcken. Keine künstlichen Wartezeiten für einen exakten 15%-Wert eingebaut.

Weitere Läufe: kurze Sitzungen mit Offlinegeld, vier betriebene Drills, drei weitere Prestige-Stände sowie jeweils ±20 % Produktion und ±20 % Fahrtzeit. Alle zehn Läufe erreichen Level 100. Die genauen aktiven und verstrichenen Zeiten stehen unter Simulationsläufe. Gelegenheitsspieler erhalten nur Cash, keine Offline-XP; 30-minütige Sitzungen mit jeweils acht Stunden Pause sind ein explizites Szenario, keine Kalenderzeit-Prognose für alle Spieler.

## Kapazität und Nutzen

Kleinste erfasste Autonomie im Referenzlauf bei normalem Durchsatz ohne Zufalls-Mengenbonus:

- Rucksack: 16,54 Minuten ununterbrochene manuelle Förderung.
- Fahrzeug: 29,34 Minuten automatischer Materialzufluss.
- Lager: 18,97 Minuten automatischer Materialzufluss.

Alle 30 Drill-Leistungen steigen strikt. Alle 30 Typen erzeugen im Referenzlauf tatsächlich Material. Zwischen je zwei aufeinanderfolgenden Typkäufen liegt mindestens ein Verkauf; kleinster Kaufabstand 9,33 Minuten. MK12 und MK18 wurden dafür gezielt günstiger vorgeschlagen, statt künstliche Kaufwartezeiten einzuführen.

Diese Aussagen gelten für die modellierte bezahlbare Firma, nicht jede beliebige Belegung. Separater Extremtest: 200 Slots mit maximalen MK30-Drills würden 408.000 Erz/min erzeugen, der Elevator lässt höchstens 13.200/min durch. Dann reichen die größte Fracht roh nur ca. 9,09 Minuten und das maximale Lager ca. 14,55 Minuten. Eine Sortenpriorität kann bei dieser Belegung wertvollere Erze verdrängen. Das ist als Belastungsgrenze sichtbar, kein behauptetes vollständiges Endgame-Gleichgewicht.

## Geprüft

- Cash-Zuflüsse, tatsächliche Käufe, Löhne und Endcash aller zehn Läufe stimmen zusammen; keine doppelte Geldverwendung oder negativen Cash-Kaufereignisse.
- Mining-XP stammen aus tatsächlichen aktiven Verkaufsereignissen. Offline-Cash erzeugt weder Material noch XP.
- Materialbilanzen der sechs vollständig protokollierten Läufe stimmen in Erzäquivalenten einschließlich verarbeiteter und verkaufter Barren. Vier Sensitivitätsläufe sind kompakter protokolliert, nicht als separat vollständig aufgezeichnete Materiallogs ausgegeben.
- Mining-Worker und Drills belegen unterschiedliche zulässige Slots; transportierte Mengen, sortenreine Kisten, Zwischenbestände und Verarbeitung sind im Modell berücksichtigt.
- Eindeutige IDs, 30 streng steigende Drill-Typen, positive Fundchancen und feste tierbezogene Jackpotpreise geprüft. Jackpot-XP übersteigen nicht den Wert einer normalen Einheit des Quellerzes.
- Excel-Formelprüfung mit der Tabellenbibliothek: keine gefundenen Fehlerwerte. Eingabetest: Starter-Power verdoppelt → Produktionsvorschau verdoppelt, Kapazitätsdauer halbiert, Eingabeabweichung erkannt. Danach ursprünglichen Vorschlagswert wiederhergestellt.
- Visuelle Prüfung aller 24 Blätter. Numerische Ist-Spalten gegenüber Original unabhängig verglichen.
- Fünf ursprüngliche Filter mit ihren fünf lokalen Namen, eingefrorene Identitätsspalten, ursprüngliche Ansichten und Berechnungseinstellungen erhalten. Fehlende Export-Metadaten wurden gezielt restauriert, ohne Zellen zu ändern. ZIP-Integrität geprüft.

Formelprüfung und Vorschauen erfolgten mit Artifact Tool, nicht durch eine laufende Microsoft-Excel-Sitzung. Keine Roblox-Studio-Spieltests oder Spielerbindungsdaten daraus ableiten.

## Grenzen und offene Entscheidung

- Endkriterium ist Mining-Level 100, nicht der vollständige Kauf aller 100 Minen. Die Referenzfirma hat dann Mine 97 gekauft. Die letzten Minen bleiben zusätzliche Cashziele nach Freischaltung von Prestige.
- Konkrete Kaufstrategie ist kein globales Optimum über alle Belegungen. Insbesondere vier statt zwei Drills beschleunigen den Durchlauf deutlich.
- Zufällige Fundereignisse und optionale Luck-/Offline-Upgrades sowie das Premiumbüro sind nicht als bereits bezahlte Teile des Referenzlaufs verbucht. Fund-Wartezeiten und Upgrade-Effekte werden separat gerechnet. Keine garantierten Jackpotzeiten.
- Acht Stunden Offline-Cash bei 30 % entsprechen 144 Minuten berechtigter automatischer Bruttoleistung. Das kann bei viel Offlinezeit große Cashüberschüsse erzeugen; XP bleibt an aktive Verkäufe gebunden. Offline ist dadurch besser als langes untätiges Online-Stehen mit vollem Lager. Vor Spielumsetzung Q-037 bewusst entscheiden.
- Nach Änderung gelber Zellen rechnen Vorschauen direkt, die gespeicherten Ereignissimulationen jedoch nicht. Prüfungen zeigt Abweichungen zum Simulationseingabestand. Neue Durchläufe müssen gesondert berechnet werden; kein automatischer Simulator in Excel behauptet.
- Zeitschritte, anteilige Produktionsmengen, angenommene Wege und feste Kaufentscheidungen können im echten Spiel abweichen. Kleine Fahrtänderungen können durch andere Kauf-/Verkaufszeitpunkte zu nicht monotonen Ergebnissen führen.

## Excel-Prüfung jetzt

1. Arbeitskopie öffnen; Anleitung lesen, danach Ergebnis öffnen. Zielzeiten und berechnete Zeiten vergleichen.
2. Spitzhacken: J2 (neue Starter-Power) vorübergehend von 1 auf 2 setzen. M2 muss von 1 auf 2 Erz/s steigen. Unter Kapazitätsvorschau halbiert sich H2 von 40 auf 20 Minuten. Unter Prüfungen erscheint die Eingabeabweichung. Danach J2 auf 1 zurücksetzen.
3. Alle Neu-Spalten prüfen; alte blaue Istwerte bleiben erkennbar erhalten. Unter Drills müssen O2:O31 streng steigen.
4. Simulationsläufe: zehn Ergebnisse „Level 100 erreicht“, Cash-Differenz innerhalb eines Cents. Bei gespeicherten Bilanzzahlen Rundungstoleranz beachten.
5. Belastungstest, Modellannahmen und Hinweise unter Ergebnis lesen; die Kapazitätsgrenzen sind nicht als Freigabe jeder Maximalfirma dargestellt.

## Studio-Test nach separater Freigabe und Umsetzung

Aktuell nicht gegen das unveränderte Spiel erwarten. Erst nach Übernahme der bestätigten Zahlen und Regeln:

1. Frisches Testprofil ohne Echtgeldboni/Handel verwenden. Erste Verkäufe, Upgrades, Worker und Drill mit Zeitstempeln protokollieren; L10 mit ca. 29–30 Minuten Referenz vergleichen.
2. Rucksack, Lager und Fahrzeuge in den vorgesehenen Firmenzuständen mindestens 15 Minuten ohne Verkaufszwang testen. Nebenminen und Produktion während einer Verkaufsfahrt mit einbeziehen; verbleibende Bestände prüfen.
3. Drilltypen und Drill-Level getrennt kaufen. Tatsächliche Produktion, Rückstau und zusätzlichen Ertrag vor/nach Upgrade messen. Worker und Drill dürfen keinen Slot doppelt nutzen.
4. Verkauf: Mengen, Geld und XP getrennt nachrechnen. Rohverkauf und Barrenverkauf prüfen. Seltene Funde kontrolliert mit Testchance auslösen; ohne Testchance keine garantierte Fundzeit erwarten.
5. Bekannten Firmenzustand speichern, Offline-Anspruch für kurze und lange Abwesenheit prüfen: 30 %, acht Stunden Limit, Cash-only, keine doppelten Ansprüche, vorhandene Bestände unverändert. Kurze Reconnects und Serverwechsel prüfen.
6. Prestige: nur normale Spitzhacken/Rucksäcke behalten, sofort nutzbar; Fahrzeuge, Luck, Maschinen und Firmenfortschritt zurücksetzen. Entitlements/Metadaten separat erhalten. Zweiten Durchlauf messen.
7. Save/Rejoin sowie zwei Spieler für Besitzschutz und Handels-/Weiterverkaufsfälle prüfen.

Nach diesem Rechenentwurf STOPP. Änderungen an den Vorschlägen oder Übernahme in das Spiel erst nach Felix' ausdrücklicher Freigabe des konkreten Ergebnisses.
