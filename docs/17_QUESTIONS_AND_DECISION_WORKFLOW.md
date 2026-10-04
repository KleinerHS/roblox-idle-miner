# 17 – QUESTIONS AND DECISION WORKFLOW

## 1. Projektpfad

Der lokale Projektordner des Nutzers ist:

```text
C:\Users\Allmo\OneDrive\Desktop\Roblox Idel Mine game
```

Claude Code soll diesen Ordner als Projektwurzel behandeln, sofern die aktuelle Arbeitsumgebung tatsächlich auf diesen Ordner zeigt.

Claude darf niemals aufgrund dieses Dokuments behaupten, Zugriff auf einen Pfad zu besitzen, den es in seiner aktuellen Umgebung nicht sehen kann.

---

## 2. Fragenordner

Claude soll im Projektstamm folgenden Ordner anlegen:

```text
QUESTIONS
```

Struktur:

```text
Roblox Idel Mine game
├── QUESTIONS
│   ├── OPEN_QUESTIONS.md
│   ├── ANSWERED_QUESTIONS.md
│   └── DECISION_LOG.md
```

---

## 3. Zweck

Claude soll die Entwicklung nicht ständig wegen kleiner Detailfragen unterbrechen.

Fragen werden in drei Kategorien behandelt:

### BLOCKING
Ohne Antwort kann ein System nicht korrekt implementiert werden.

→ Frage in `OPEN_QUESTIONS.md` schreiben und Arbeit an genau diesem blockierten Teil stoppen.

### IMPORTANT_NON_BLOCKING
Die Entscheidung ist wichtig, aber eine andere Phase kann weitergebaut werden.

→ Frage dokumentieren und an anderen Aufgaben weiterarbeiten.

### POLISH
Geschmack, genaue Optik oder späteres Balancing.

→ Als offene Frage/TODO dokumentieren, aber niemals den technischen Fortschritt blockieren.

---

## 4. Format für offene Fragen

```md
## Q-001 – Prestige: Standard Equipment

**Status:** OPEN
**Priority:** IMPORTANT_NON_BLOCKING
**System:** Prestige / Inventory
**Date:** YYYY-MM-DD

### Question
Bleiben normal gekaufte Pickaxes und Backpacks nach Prestige erhalten?

### Why this matters
Die Save-/Reset-Logik muss wissen, welche Itemklassen permanent sind.

### Current project information
- Robux purchases remain.
- Prestige bonuses remain.
- Normal company progression resets.
- Standard equipment retention has not yet been decided.

### Safe work that can continue
The item ownership system can be implemented with a `PersistenceClass` field, while the final value remains undecided.

### Do not decide automatically
Do not choose a permanent/reset behavior until answered.
```

---

## 5. IDs

Fragen erhalten fortlaufende IDs:

```text
Q-001
Q-002
Q-003
...
```

IDs werden niemals wiederverwendet.

---

## 6. Antwortworkflow

Wenn der Nutzer eine Frage beantwortet:

1. Antwort in die betreffende Frage übernehmen.
2. Status auf `ANSWERED` setzen.
3. Frage aus `OPEN_QUESTIONS.md` entfernen.
4. Eintrag nach `ANSWERED_QUESTIONS.md` verschieben.
5. daraus eine klare Projektentscheidung in `DECISION_LOG.md` schreiben.
6. relevante Spezifikationsdatei aktualisieren.
7. erst danach Code implementieren, der von der Entscheidung abhängt.

---

## 7. Decision Log

Beispiel:

```md
## D-014 – Conveyors unlock before Level 50

**Source Question:** Q-008
**Decision:** Conveyors should become available around Mining Level 35.
**Final exact level:** Pending balance tests.
**Affected systems:** Progression, Machine Shop, UI
```

---

## 8. Keine Fragen zu bereits entschiedenen Dingen

Bevor Claude eine Frage stellt:

1. alle relevanten `.md`-Dateien durchsuchen
2. `DECISION_LOG.md` prüfen
3. `ANSWERED_QUESTIONS.md` prüfen
4. Visual References prüfen, falls es um Gestaltung geht

Nur wenn keine eindeutige Antwort existiert, wird eine neue Frage erstellt.

---

## 9. Keine eigenmächtigen Änderungen

Claude darf eine bestehende Entscheidung nicht stillschweigend überschreiben.

Wenn eine neue technische Einschränkung eine Änderung sinnvoll macht:

→ neue Frage erstellen und begründen.

---

## 10. Widersprüche

Bei widersprüchlichen Dokumenten:

```text
1. neuere ausdrückliche Entscheidung
2. spezialisierte Systemdatei
3. Decision Log
4. allgemeines Design-Dokument
```

Wenn weiterhin unklar:

→ BLOCKING oder IMPORTANT_NON_BLOCKING Question.

---

## 11. Fragen an den Nutzer bündeln

Claude soll möglichst mehrere nicht blockierende Fragen sammeln.

Nicht nach jeder kleinen Unklarheit einzeln stoppen.

Beispiel:

```text
QUESTIONS/OPEN_QUESTIONS.md
```

kann 5–10 sauber erklärte Fragen enthalten, die der Nutzer gesammelt beantwortet.

---

## 12. Balancefragen

Exakte Werte wie:

- Preise
- XP
- Produktionsraten
- Gehälter
- Dropchancen

werden normalerweise nicht als blockierende Fragen behandelt, solange der Vertical Slice mit zentralen Testwerten gebaut werden kann.

Diese Werte werden als `TODO_BALANCE` markiert.

---

## 13. Grafische Fragen

Wenn ein Referenzbild fehlt:

- keine zufällige komplett neue Designsprache erfinden
- vorhandenen Style Guide verwenden
- Frage als POLISH dokumentieren, sofern Implementierung weitergehen kann
- später Visual Reference ergänzen

---

## 14. Verbindliche Regeln

1. `QUESTIONS`-Ordner im Projektstamm.
2. Claude bündelt offene Fragen.
3. Nur wirklich blockierende Fragen stoppen die betreffende Arbeit.
4. Keine Frage stellen, die bereits dokumentiert beantwortet ist.
5. Keine offenen Designentscheidungen eigenmächtig finalisieren.
6. Antworten werden in Spezifikation und Decision Log übertragen.
7. Balancefragen blockieren den Prototyp normalerweise nicht.
8. Frage-IDs bleiben stabil und eindeutig.
