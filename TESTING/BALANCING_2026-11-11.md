# Checkpoint für die Balancing-Revision am 11.11.2026

**Status** `TESTING_REQUIRED`. Die aktuelle Arbeitskopie liegt unter `outputs/balancing-20261111/Balancing_Neuentwurf.xlsx`. Die [Übergabe an Claude](../docs/BALANCING_UEBERGABE_CLAUDE.md) beschreibt den Spielcode und die Roblox-Studio-Tests, die für die Übernahme erforderlich sind.

Die Fracht des Box Trucks steigt auf 110.000. Die beiden Lastzüge liegen bei 145.000 und 180.000 Einheiten. Die Standardläufe verwenden die vier derzeit kaufbaren Fahrzeuge. Der Schmelzer ist auf 1.500 Barren pro Minute ausgelegt. Ab Level 60 steigen die XP-Schwellen langsamer als im früheren Entwurf. Die Preise später Minen und Drills wurden passend dazu gesenkt.

| Messpunkt im Referenzlauf mit kaufbaren Fahrzeugen | Ergebnis |
|---|---:|
| Erster Verkauf und Upgrade | 2 Minuten |
| Level 10 und erster Drill | 29,2 Minuten |
| Level 50 | 5,67 aktive Stunden |
| Level 100 und Prestige verfügbar | 26,17 aktive Stunden |
| Kürzeste Frachtreserve mit zwei Drills | 28,19 Minuten |
| Kürzeste Frachtreserve mit vier Drills | 15,82 Minuten |

Die kaufbare Vier-Drill-Firma erreicht Level 100 nach 19,09 aktiven Stunden. In den beiden kaufbaren Grundläufen trat im Modell kein Produktionsstillstand auf. Die Frachtreserve ist das Minimum über die gespeicherten Levelstände. Der Belastungstest für die Extrembelegung mit 200 maximalen Drills bleibt ein eigener Fall.

Bei gleicher Fracht und Schmelzerleistung lag die längste Pause zwischen größeren Käufen ab Level 50 vor der Anpassung bei 49 Minuten. Mit kürzeren XP-Abschnitten und niedrigeren späten Preisen liegt sie bei etwa 33 Minuten. Die Messung zählt Minen, Ausrüstung, Drills und Drill-Level, Fahrzeuge und Elevator-Upgrades. Alle 30 Drill-Typen produzieren im Referenzlauf. MK22 und MK23 werden bei demselben Kaufzeitpunkt erworben und anschließend gemeinsam eingesetzt.

Die zwölf Läufe erreichen Level 100. Geld- und XP-Bilanzen sowie die Materialbilanzen der vollständig protokollierten Läufe stimmen. Die Modellannahmen zum Verkauf und zur Bedienzeit gelten weiter. Konkrete Lade- und Fahrzeiten, Schmelzdurchsatz und die erlebte Dauer zwischen Verbesserungen werden in Roblox Studio geprüft. Den vorhandenen Spielstand von Felix getrennt vom frischen Testprofil prüfen.

Der Hauptschritt endet mit dieser Arbeitskopie und der Übergabe. Die Freigaberegel in `AGENTS.md` gilt für den nächsten Hauptschritt.
