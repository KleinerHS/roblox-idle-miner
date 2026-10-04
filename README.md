# Roblox Idle Miner

Originales Roblox-Mining-Company-/Idle-Produktionsspiel. Die komplette Spezifikation liegt in [`docs/`](docs/), Einstieg: [`docs/00_READ_ME_FIRST.md`](docs/00_READ_ME_FIRST.md).

## Ordnerstruktur

```text
default.project.json   Rojo-Projekt (Zuordnung src/ → Roblox-Instanzen)
rokit.toml             Toolchain (Rojo-Version)
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

Die Unterordner (`Services`, `Controllers`, `Config` …) entstehen mit Phase 1 (Project Skeleton).

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

## Arbeitsweise

```text
BUILD SMALL → TEST → FIX → COMMIT → NEXT SYSTEM
```

Nach jedem Hauptschritt wird gestoppt und ein Checkpoint mit Testanleitung geliefert. Status je System steht in [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md).

## Wichtig

- Code-Quelle der Wahrheit ist dieses Repository, nicht die Studio-Place-Datei. Änderungen an Scripts direkt in Studio gehen beim nächsten Sync verloren.
- Weltobjekte (Map, Gebäude) werden später als Modelle unter `assets/` versioniert.
