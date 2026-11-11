# Open Questions

Q-033 bis Q-036 wurden am 2026-11-08 beantwortet: siehe `ANSWERED_QUESTIONS.md`, D-084 und `docs/BALANCING_ZIELBILD_2026-11-08.md`. Der Excel-Rechenschritt wurde am 2026-11-09 durch „weiter“ freigegeben (D-085). Konkrete neue Zahlen sind noch nicht USER_APPROVED.

## Q-038 – Probleme im Balancing-Entwurf vom 11.11.2026

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Economy
**Date:** 2026-11-11

Beim Übernehmen (D-087) aufgefallen, trotzdem so eingebaut:
1. Bessere Drills sind teils billiger als schwächere: MK11 < MK10, MK12 < MK11, MK15 < MK14, MK17 < MK16, MK21 < MK20, MK23 < MK22, MK25 = MK24.
2. Einige Minen sind billiger als die vorherige (z. B. 40, 65, 70, 73, 77, 80, 81). Minen werden der Reihe nach gekauft, also nicht ausnutzbar, wirkt aber seltsam.
3. XP-Bedarf ab Level 100 bleibt gleich (7.647.031 je Level), ab 121 ebenso. Bisher stieg er nach 100 weiter.
4. Die größten Rucksäcke (103.000) fassen fast so viel wie der Box Truck (110.000); früher galt „Rucksack soll kein Fahrzeug ersetzen“ (max. 15.000).
5. Büro-Upgrade jetzt Level 25 / $21.000 statt der vereinbarten 15 / $35.000 (D-082).
6. Erzwerte mit Nachkommastellen: der Erlös eines Verkaufs wird abgerundet (bei kleinen Mengen ein paar Cent weniger).
7. In der Excel-Vorschau steht beim Prestige-Tempobonus 5 %, eingetragen ist 0 (Excel-Formel wertet die 0 als „leer“). Übernommen: 0.

Regeln (D-088), ebenfalls trotzdem eingebaut:
8. Offline 8 h × 30 % bringt mehr als untätiges Online-Stehen mit vollem Lager (siehe Q-037). Eingebaut wie in der Datei.
9. Ein Sonderfund belegt eine ganze Lagerkiste (1.000er-Kiste je Sorte), auch bei 1 Stück.
10. Sonderfund-Werte sehr hoch: z. B. Ancient Diamond $9,68 Mrd. gegenüber Mine 100 für $1,9 Mrd. Ein Glückstreffer kann Stunden Fortschritt überspringen.
11. Mengenbonus: eingebaut als 1 % eigene Chance plus 0,15 % nächstes Erz (so in der Datei). Falls 1 % als Gesamtchance gemeint war, sinkt der Bonus leicht.
12. Vorgänger-Regel auch für Rucksäcke (Zielbild), die Datei nennt nur Spitzhacken und Drills.
13. Offline-Upgrades liegen in der Laptop-App „Company“ und ersetzen dort die zwei Platzhalter-Karten.
14. Offline-Geld enthält den Prestige-Geldbonus, der Schmelzer zählt offline nicht.
15. Echter Spielstand: Beim ersten Play ohne `UseMockData` wird Felix' Profil auf v15 umgestellt (nicht rückgängig zu machen, vorher nicht gesichert).

## Q-037 – Offline-Cash gegenüber untätigem Onlinebetrieb

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Offline / Economy
**Date:** 2026-11-09

### Frage
Soll die lange Offline-Cash-Gutschrift bewusst mehr bringen als langes untätiges Online-Stehen mit vollem Lager? Im vorgeschlagenen Modell gilt diese Folge: acht Stunden bei 30 % ergeben 144 Referenz-Betriebsminuten Cash; online wird nach Erreichen der Kapazitätsgrenze nicht weiter produziert und es muss manuell verkauft werden.

### Warum relevant
Ein dauerhafter virtueller Offline-Abnehmer umgeht die begrenzte Lagerautonomie. Das ist ein sichtbarer Designunterschied, kein Bilanzfehler. Cash-only-Offline erleichtert Käufe, schaltet ohne aktive Verkaufs-XP aber keine Level frei; bei häufigen Rückkehrern sammelt sich später viel Cash an.

### Aktueller Entwurf / sichere Weiterarbeit
Die Excel-Arbeitskopie rechnet die gewünschte achtstündige 30%-Variante und weist die Folge ausdrücklich aus. Kein ungefragtes Online-Autosell oder zusätzliche XP eingeführt. Zahlen und Rückkehrszenarien können geprüft werden. Vor späterer Spielumsetzung diese Regel bewusst bestätigen oder eine konkrete Alternative rechnen; nicht stillschweigend bestehende Material-/Lagerregeln mischen.

Format und Workflow: `docs/17_QUESTIONS_AND_DECISION_WORKFLOW.md`. IDs fortlaufend (Q-001 …), nie wiederverwenden.

Stand: 2026-10-10

Q-001 bis Q-019 sind beantwortet (siehe `ANSWERED_QUESTIONS.md`, Entscheidungen D-002 bis D-023).

Offene Balancewerte (Level-Anforderungen ab Mine 03) sind als `TODO_BALANCE` markiert.

Q-020, Q-021 und Q-024 sind beantwortet (D-031).

Q-025 ist beantwortet (D-034).

Q-026 ist beantwortet (D-035).

Q-027 ist beantwortet (D-036).

Q-029 bis Q-032 sind beantwortet (D-041, D-042, D-043; Felix 2026-10-18). Rückfrage „später mehr Drills“: mehr Stufen (D-044).

Q-028 ist durch den Auftrag zum vollständigen Neubalancing einschließlich aller sechs Fahrzeugtypen abgelöst. Alte Einzelwerte wurden damit nicht bestätigt; neue Werte werden im Rechenmodell vorgeschlagen. Historie siehe `ANSWERED_QUESTIONS.md`.
