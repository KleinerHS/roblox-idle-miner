# 16 – CLAUDE CODE BUILD PLAN

## 1. Ziel
Claude Code soll **nicht versuchen, das komplette Spiel in einem einzigen Prompt zu erzeugen**.

Es arbeitet in klaren Phasen. Nach jeder Phase muss das Projekt spielbar und überprüfbar bleiben.

## 2. Quellenpriorität
Claude liest vor jeder Implementierung die relevanten Projektdokumente.

Reihenfolge der Wahrheit:
```text
1. neueste ausdrücklich festgelegte Projektregel
2. spezialisierte Markdown-Datei des Systems
3. Visual Reference für Gestaltung
4. allgemeine Architektur-/Designregeln
```

Bei Widerspruch: nicht raten, sondern markieren.

## 3. Phase 0 – Audit
Claude:
- liest alle `.md`
- erstellt eine Feature-Matrix
- listet offene Entscheidungen
- erkennt Widersprüche
- verändert noch keinen Gameplay-Code

Output:
```text
IMPLEMENTATION_STATUS.md
OPEN_QUESTIONS.md
```

Nur wirklich blockierende Fragen an den Nutzer stellen.

## 4. Phase 1 – Project Skeleton
Erstellen:
- Ordnerstruktur
- Shared Definitions
- Service Bootstrap
- Controller Bootstrap
- Remote Registry
- Data Schema
- zentrale Configs
- grundlegende Plot Ownership

Noch keine Content-Masse.

## 5. Phase 2 – Vertical Slice A
Implementieren:
```text
Plot claim
→ Blechhütte $0
→ Firmenidentität
→ Elevator
→ Mine 01 Coal
→ Starter Pickaxe
→ Starter Backpack
→ Mining
→ Backpack
→ Surface
→ Selling
→ Cash + XP
→ Mining Level HUD
→ Save/Load
```
Erst wenn dieser Loop stabil ist, weiter.

## 6. Phase 3 – Vertical Slice B
```text
Equipment Shop
→ bessere Pickaxe
→ besserer Backpack
→ Mine 02
→ erster Worker
→ Worker Management am Laptop
→ Transport Worker
→ frühe Produktionskette
```

## 7. Phase 4 – Storage
```text
Storage building
→ 1000 capacity
→ Worker transport
→ Laptop Storage App
→ Capacity bottlenecks
→ Offline production foundation
```

## 8. Phase 5 – Drill
```text
Machine Shop
→ Drill purchase
→ inventory
→ fixed placement slot
→ drill animation/VFX
→ production
→ output
→ worker transport
```

## 9. Phase 6 – Garage and Vehicles
```text
Garage building
→ Vehicle Shop
→ first vehicle
→ 1000 cargo
→ garage spawn ring
→ spawn directly into vehicle
→ loading zone
→ drive to selling station
→ sell from vehicle
```

## 10. Phase 7 – Conveyors
Erst nach stabiler Worker-/Drill-Logistik:
```text
Conveyor Shop
→ inventory
→ fixed slots
→ throughput
→ automated material paths
```

## 11. Phase 8 – Smelter
```text
Smelter building
→ automatic recipe selection
→ input/output
→ bars
→ increased sell value
→ VFX only while running
```

## 12. Phase 9 – Multiplayer Hardening
```text
6 plots
→ ownership validation
→ no vehicle-player blocking
→ protected cargo
→ visits
→ direct trading
```

## 13. Phase 10 – Offline Production
Erst wenn Online-Kette korrekt funktioniert:
- mathematische Simulation
- 1h cap
- bottlenecks
- wages
- summary UI

## 14. Phase 11 – Prestige
Erst nachdem Level-/Economy-System stabil:
- Level 100 availability
- preview reset
- confirmation
- atomic reset
- permanent bonuses
- Robux preservation

## 15. Phase 12 – Content Expansion
Erst jetzt:
- viele Minen
- Ore progression
- weitere Pickaxes
- Backpacks
- Drills
- Vehicles
- Building stages

Keine 100 Minen vor funktionierendem Vertical Slice.

## 16. Phase 13 – Visual Polish
Mit Visual References:
- Map
- shops
- mine shafts
- office
- factory
- UI
- machines
- vehicles
- lighting
- VFX
- audio

## 17. Phase 14 – Balance
Mit Simulation/Playtests:
- ore values
- XP
- prices
- wages
- production rates
- capacities
- unlock levels
- prestige

## 18. Arbeitsweise pro Phase
Claude soll für jede Phase:
1. relevante Dokumente nennen
2. Plan mit betroffenen Dateien erstellen
3. kleine implementierbare Schritte festlegen
4. Code erstellen
5. Tests/Checkliste erstellen
6. bekannte offene Punkte dokumentieren
7. erst danach nächste Phase beginnen

## 19. Keine eigenmächtigen Designänderungen
Claude darf nicht aus Bequemlichkeit:
- Shops zusammenlegen
- Worker entfernen
- freie Placement-Systeme erfinden
- Pets hinzufügen
- zusätzliche Währungen hinzufügen
- Auto-Selling einbauen
- Fahrzeugfahren automatisieren
- Rare Drops auf Drills übertragen

## 20. Placeholder-Regel
Wenn Balancewert unbekannt ist:
```text
TODO_BALANCE
```
bzw. zentrale Placeholder-Config.

Nicht zufällig „vernünftige“ Endwerte über das gesamte Spiel verteilen.

## 21. Visual-Regel
Wenn ein grafisches Element durch eine Referenzdatei definiert ist, soll Claude:
- Layout/Formen daraus ableiten
- nicht pixelgenau kopieren, wenn technisch unpassend
- Stil konsistent halten
- fehlende Details nach dem gemeinsamen Style Guide ergänzen

## 22. Roblox Studio
Claude Code soll Dateien/Module so organisieren, dass die Übertragung bzw. Synchronisierung in Roblox Studio sauber möglich ist. Wenn Rojo verwendet wird, muss die Projektstruktur dokumentiert und reproduzierbar sein.

## 23. Definition of Done
Eine Phase gilt erst als fertig, wenn:
- keine offensichtlichen Errors
- Kernpfad funktioniert
- Servervalidierung vorhanden
- Save-State berücksichtigt
- UI-State korrekt
- keine bekannten Dupes
- Testcheckliste bestanden

## 24. Verbindliche Regel
**Nie mehrere große ungetestete Systeme gleichzeitig bauen.**

Das wichtigste Entwicklungsprinzip dieses Projekts lautet:

```text
BUILD SMALL
→ TEST
→ FIX
→ COMMIT
→ NEXT SYSTEM
```
