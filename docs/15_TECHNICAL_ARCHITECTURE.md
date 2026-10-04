# 15 – TECHNICAL ARCHITECTURE

## 1. Ziel
Claude Code soll das Spiel modular, datengetrieben und serverautoritativ bauen. Keine riesigen Monolith-Scripts.

## 2. Architekturprinzip
```text
Shared Definitions
        ↓
Server Services ←→ Persistence
        ↓
Replicated State / Remotes
        ↓
Client Controllers
        ↓
UI / Visuals
```

## 3. Server
Server ist Wahrheit für:
- Cash / XP / Level
- Inventar
- Mining-Ergebnisse
- Rare Drops
- Produktion
- Worker
- Maschinen
- Storage
- Elevator
- Gebäude
- Fahrzeuge/Cargo
- Verkauf
- Trading
- Prestige

## 4. Client
Client übernimmt:
- Input
- Kamera
- UI
- lokale Animationen/VFX
- Preview/Placement-Darstellung
- Fahrzeuginput gemäß Roblox-Fahrzeugarchitektur

Keine Economy-Autorität.

## 5. Empfohlene Struktur
```text
ReplicatedStorage
├── Shared
│   ├── Config
│   ├── Types
│   ├── Util
│   └── Definitions
├── Remotes
└── Assets

ServerScriptService
├── Services
│   ├── DataService
│   ├── EconomyService
│   ├── MiningService
│   ├── InventoryService
│   ├── WorkerService
│   ├── ProductionService
│   ├── StorageService
│   ├── ElevatorService
│   ├── BuildingService
│   ├── VehicleService
│   ├── SellingService
│   ├── TradingService
│   ├── PrestigeService
│   └── OfflineService
└── Bootstrap

StarterPlayer
└── StarterPlayerScripts
    ├── Controllers
    └── Bootstrap

StarterGui
└── GameUI
```

## 6. Datengetriebener Content
Erze, Pickaxes, Backpacks, Drills, Fahrzeuge, Unlocks, Gebäude und Rezepte kommen aus Definitionen statt aus hardcodierten Scriptzweigen.

## 7. IDs
Persistente Inhalte verwenden stabile interne IDs:
```text
ore_coal
pickaxe_basic
drill_mk1
vehicle_pickup_01
building_storage
```
Display-Namen dürfen sich ändern.

## 8. Remotes
RemoteEvents/Functions werden zentral registriert. Keine unübersichtlichen Remotes in zufälligen Models.

Jeder Remote:
- klarer Zweck
- serverseitige Typ-/Wertprüfung
- Rate Limit wo sinnvoll
- Besitzprüfung
- keine vom Client gelieferten Preise/Belohnungen akzeptieren

## 9. State
Client bekommt nur Daten, die er zur Darstellung benötigt. Sensitive serverinterne Berechnungen müssen nicht vollständig repliziert werden.

## 10. Mining
Mining Request enthält höchstens Identifikation des Ziels/Inputs. Server prüft:
- Entfernung
- Mine
- Cooldown
- Equipment
- Slot/Ader gültig
- Kapazität
- Luck
und berechnet Ergebnis selbst.

## 11. Produktion
Maschinenproduktion soll nicht von tausenden `while task.wait()`-Loops pro Objekt abhängen. Zentraler/taktbasierter Produktionsservice oder ereignisbasierte Berechnung.

## 12. Worker
Worker-Visuals und tatsächliche Economy werden getrennt. Die Economy darf nicht davon abhängen, ob ein NPC wegen Roblox-Pathfinding 0,3 Sekunden länger läuft.

## 13. Worker Pathing
Feste Hauptwege, bei Blockierung alternative Route. Keine Kollision zwischen Spielern und Worker, soweit für sauberes Gameplay erforderlich.

## 14. Ore Piles
Materialtransport wird als Haufen visualisiert. Ein Haufen repräsentiert 1–100 Items, behält optisch dieselbe Grundgröße und reduziert Part-/NPC-Last.

## 15. Placement
Drills/Conveyors besitzen serverdefinierte Slots. Client zeigt Preview; Server entscheidet final, ob Slot frei und Item vorhanden ist.

## 16. Plot Ownership
Jedes Plot-Objekt kann eindeutig einem `OwnerUserId`/Plot-State zugeordnet werden. Fremde Requests werden abgewiesen.

## 17. Tags/Attributes
CollectionService-Tags und Attributes können für Weltobjekte genutzt werden:
```text
MiningSlot
ConveyorSlot
TycoonButton
SellZone
VehicleSpawn
Elevator
```
Keine Namenssuche als einzige Logik.

## 18. UI
UI-Komponenten wiederverwenden. Datenbindung über Controller/State statt Businesslogik direkt in Buttons.

## 19. Fehlerbehandlung
Services geben definierte Resultate zurück:
```lua
{ success = false, code = "NOT_ENOUGH_MONEY" }
```
UI übersetzt Codes in verständliche Texte.

## 20. Logging
Debug/Telemetry zentral. Produktionsbuild darf nicht permanent Console-Spam erzeugen.

## 21. Performance Budgets
Besonders überwachen:
- Parts
- aktive NPCs
- Pathfinding
- ViewportFrames
- Partikel
- physische Erzhaufen
- Fahrzeuge
- Remote-Frequenz
- DataStore Calls

## 22. Streaming
Map soll für `StreamingEnabled` vorbereitet sein. Kritische Interaktionssysteme dürfen nicht blind voraussetzen, dass die komplette Welt clientseitig geladen ist.

## 23. Tests
Services sollen soweit möglich unabhängig testbar sein. Besonders:
- Economy
- XP
- Inventory
- Trades
- Prestige
- Offline-Produktion

## 24. Security
Nie vertrauen auf:
- Client Cash
- Client Level
- Client Item Count
- Client Price
- Client Rare Drop
- Client Sell Value
- Client Placement Ownership

## 25. Verbindliche Regeln
1. Modularer Service-/Controller-Aufbau.
2. Serverautorität für Economy.
3. Content datengetrieben.
4. Stabile interne IDs.
5. Zentral verwaltete Remotes.
6. Jede Remote-Eingabe validieren.
7. Keine Produktion über tausende unabhängige Endlosschleifen.
8. Worker-Visual und Economy entkoppeln.
9. Feste Placement-Slots.
10. Plot Ownership serverseitig.
11. UI enthält keine Businesslogik.
12. StreamingEnabled berücksichtigen.
13. Kritische Systeme testbar halten.
14. Performance von Anfang an berücksichtigen.
