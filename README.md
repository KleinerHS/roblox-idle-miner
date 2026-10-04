# Roblox Idle Miner

Originales Roblox-Mining-Company-/Idle-Produktionsspiel. Die komplette Spezifikation liegt in [`docs/`](docs/), Einstieg: [`docs/00_READ_ME_FIRST.md`](docs/00_READ_ME_FIRST.md).

## Ordnerstruktur

```text
default.project.json   Rojo-Projekt (Zuordnung src/ → Roblox-Instanzen)
rokit.toml             Toolchain (Rojo-Version)
plugin.project.json    Studio-Plugin "Idle Miner Preview" (nur Werkzeug, kein Spielcode)
plugin/                Quellcode des Studio-Plugins
src/
├── shared/            → ReplicatedStorage.Shared   (Config, Definitions, Types, Util)
├── server/            → ServerScriptService        (Services, Bootstrap)
└── client/            → StarterPlayer.StarterPlayerScripts (Controllers, Bootstrap)
docs/                  Spezifikation 00–20
docs/references/       Freigegebene Visual References (PNG)
QUESTIONS/             Offene/beantwortete Fragen, Decision Log
TESTING/               Testplan, Regression-Checkliste, Bugs
IMPLEMENTATION_STATUS.md  Status je System
```

Ab Phase 1:

```text
src/shared/Config        GameConfig, BalanceConfig (TODO_BALANCE), LayoutConfig (TODO_LAYOUT), UITheme
src/shared/Definitions   Ores, Mines, Pickaxes, Backpacks, BuildSteps, CompanyIdentity
src/shared/Util          Result, Signal, NumberFormat, Log, Leveling
src/shared/Remotes.luau  zentrale Remote-Liste
src/server/Services      RemoteService, DataService, PlotService (Reihenfolge in Bootstrap.server.luau)
src/server/Data          DataSchema (Default-Profil, Migrationen)
src/server/Packages      ProfileStore (Apache-2.0, Lizenz in licenses/)
src/server/World         PlotBuilder (Platzhalter-Geometrie der 6 Plots)
src/client/Controllers   StateController, PlotController (Reihenfolge in Bootstrap.client.luau)
```

Speichern funktioniert in Studio nur in einem veröffentlichten Place mit aktiviertem „Enable Studio Access to API Services“ (Game Settings → Security).

## Setup (Windows)

1. **Rokit installieren** (Toolchain-Manager): <https://github.com/rojo-rbx/rokit> → Installationsanleitung im README befolgen.
2. Im Projektordner einmalig ausführen:
   ```powershell
   rokit install
   ```
   Danach ist `rojo` in der festgelegten Version verfügbar (`rojo --version`).
3. **Rojo-Plugin für Roblox Studio** installieren:
   ```powershell
   rojo plugin install
   ```
4. Sync starten:
   ```powershell
   rojo serve
   ```
5. In Roblox Studio eine leere Baseplate öffnen → Plugins → Rojo → **Connect**.

Alternativ ohne Live-Sync eine Place-Datei bauen:

```powershell
rojo build -o RobloxIdleMiner.rbxlx
```

### Welt im Bearbeitungsmodus ansehen (Edit-Vorschau)

Die Spielwelt wird zur Laufzeit vom Server-Code gebaut (`src/server/World`). Im Bearbeitungsmodus ist sie deshalb leer. Das Plugin **Idle Miner Preview** baut sie auf Knopfdruck auf und entfernt sie wieder:

```powershell
rojo build plugin.project.json -o "$env:LOCALAPPDATA\Roblox\Plugins\IdleMinerPreview.rbxm"
```

Studio neu starten → Reiter **Plugins** → Toolbar „Idle Miner“ → **World Preview**. Die Vorschau liegt in `Workspace.EditPreview` (Archivable = false): Sie wird nicht gespeichert und beim Play nicht mitkopiert. Plot 1 wird voll ausgebaut gezeigt, die anderen Plots leer, darunter die Minenräume mit Mine 01. Jeder Klick baut mit dem aktuellen Code neu auf. Nach Code-Änderungen also einmal aus- und wieder einschalten.

## Arbeitsweise

```text
BUILD SMALL → TEST → FIX → COMMIT → NEXT SYSTEM
```

Nach jedem Hauptschritt wird gestoppt und ein Checkpoint mit Testanleitung geliefert. Status je System steht in [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md).

## Wichtig

- Code-Quelle der Wahrheit ist dieses Repository, nicht die Studio-Place-Datei. Änderungen an Scripts direkt in Studio gehen beim nächsten Sync verloren.
- Weltobjekte (Map, Gebäude) werden später als Modelle unter `assets/` versioniert.
