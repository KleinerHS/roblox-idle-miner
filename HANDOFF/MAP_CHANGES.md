# Zusammenarbeit Map (ChatGPT) ↔ Rest des Spiels (Claude)

Felix, 2026-10-29: ChatGPT arbeitet in Studio mit und ist **nur für die Map** zuständig. Claude macht den Rest.
Diese Datei ist der gemeinsame Übergabekanal. Beide lesen sie vor jedem Arbeitsschritt.

## Zuständigkeiten

| Bereich | Zuständig | Dateien |
|---|---|---|
| Map: Mitte, Straßen, Kreisel, Parkplätze, Natur, Umgebung, Plots-Außenbereich | ChatGPT | `src/server/World/CenterBuilder.luau`, `EnvironmentBuilder.luau`, `RoadFillet.luau`, `PlotBuilder.luau` (nur Außenbereich), Map-Abschnitte in `src/shared/Config/LayoutConfig.luau` |
| Shops (innen und außen), Fahrzeuge, Items, Mine, UI, Services, Daten | Claude | alles andere |
| Gemeinsam (nur kleine, abgestimmte Änderungen) | beide | `LayoutConfig.luau` (Shop-Positionen/-Größen), `IMPLEMENTATION_STATUS.md`, `QUESTIONS/DECISION_LOG.md` |

Muss jemand eine Datei des anderen ändern (z. B. ein Shop wird verschoben), zuerst hier unter „Offene Abstimmungen“ eintragen.

## Wichtige technische Regeln

1. **Die Map wird per Code gebaut.** `Workspace.EditPreview` (Vorschau-Plugin) und `Workspace.Center` (im Spiel) entstehen bei jedem Start bzw. jeder Code-Änderung neu. Was dort von Hand geändert wird, ist beim nächsten Neuaufbau weg. Änderungen gehören in die Builder-Dateien unter `src/`.
2. **Rojo synchronisiert nur in eine Richtung** (Dateien → Studio). Scripts nie im Studio-Editor ändern, Rojo überschreibt sie. Immer die Dateien im Repo bearbeiten.
3. **Handgebaute Map-Teile** (Modelle, die nicht per Code entstehen) kommen in den Ordner `Workspace.MapAdditions` und werden hier eingetragen. Claude sichert sie dann nach `assets/MapAdditions.rbxm` (wie HallLayout, D-049).
4. **Git:** gleicher Branch `claude/project-thread-1in8br`. Vor jedem Commit `git fetch` und `git pull --rebase`, kleine Commits, Commit-Nachricht beginnt mit `Map:`.
5. `src/shared/Version.luau` ändert nur Claude (sonst Konflikte). Map-Entscheidungen bekommen eigene Nummern `M-001`, `M-002` … im `QUESTIONS/DECISION_LOG.md` (Claude nutzt weiter `D-0xx`).
6. Regeln aus `CLAUDE.md`/`AGENTS.md` gelten für beide: Deutsch, `--!strict`, keine echten Marken (D-026), nach jedem Hauptschritt stoppen und Felix fragen.

## Eintrag pro Änderung (oben neu einfügen)

```
### JJJJ-MM-TT – kurzer Titel (ChatGPT | Claude)
- Was: …
- Dateien / Studio-Instanzen: …
- Auswirkung auf den anderen (Shops, Straßen, Spawns, Positionen): … oder „keine“
- Getestet: …
- Offen: …
```

## Offene Abstimmungen

(leer)

## Änderungen

### 2026-10-29 – Übergabedatei angelegt (Claude)
- Was: Regeln und Vorlage für die Zusammenarbeit.
- Stand der Map bei Übergabe: Version 0.58.2. Mitte mit Verkaufskreis (D-056), Kreisel (D-059), Promenade, Shop-Parkplätze (D-064/D-065), großer Parkplatz als eine Fläche mit zwei Einfahrten (D-073), LKW-Laden mit Zufahrt (D-058/D-068). Details im `QUESTIONS/DECISION_LOG.md`.
- Auswirkung: keine.
