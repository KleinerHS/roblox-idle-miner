# 00 – READ ME FIRST

> **MANDATORY ENTRY POINT FOR CLAUDE CODE**
>
> Read this file completely before inspecting or modifying the Roblox project. Do not begin implementation until the documentation audit below is complete.

## 1. Project and purpose

Expected project root:

```text
C:\Users\Allmo\OneDrive\Desktop\Roblox Idel Mine game
```

Treat the actual workspace Claude can access as authoritative.

This repository specifies an original Roblox mining-company / idle-production game. It may use the broad progression idea of idle mining games, but must not copy another game's protected map, UI, artwork, characters, branding, names, text, or exact content.

## 2. First action: audit, not code

Before writing gameplay code:

1. Read this file.
2. Read every specification file `01` through `20`.
3. Inspect all four approved PNG references.
4. Compare older documents against the final corrections in this file.
5. Identify genuine unresolved questions.
6. Create the `QUESTIONS` and `TESTING` structures if missing.
7. Write unresolved questions to `QUESTIONS/OPEN_QUESTIONS.md`.
8. Create/update `IMPLEMENTATION_STATUS.md`.
9. Only then begin the first implementation phase.

Do not attempt to generate the complete game in one pass.

## 3. Document order

```text
00_READ_ME_FIRST.md
01_GAME_DESIGN.md
02_GAMEPLAY_PROGRESSION.md
03_MINING_AND_ORES.md
04_TYCOON_AND_BUILDINGS.md
05_WORKERS_AND_DRILLS.md
06_STORAGE_AND_PRODUCTION.md
07_VEHICLES_AND_SELLING.md
08_MAP_AND_WORLD.md
09_UI_AND_LAPTOP.md
10_EQUIPMENT_AND_SHOPS.md
11_ECONOMY_AND_BALANCE.md
12_PROGRESSION_AND_PRESTIGE.md
13_TRADING_AND_MULTIPLAYER.md
14_DATA_SAVING_AND_OFFLINE.md
15_TECHNICAL_ARCHITECTURE.md
16_CLAUDE_CODE_BUILD_PLAN.md
17_QUESTIONS_AND_DECISION_WORKFLOW.md
18_TESTING_AND_QUALITY.md
19_ASSET_AND_VISUAL_PIPELINE.md
20_MASTER_INSTRUCTIONS_FOR_CLAUDE.md
```

## 4. Approved visual references

```text
MAP_MASTERPLAN_TOPDOWN.png
FACTORY_MASTERPLAN_TOPDOWN.png
CENTRAL_AREA_REFERENCE.png
MINE_SHAFT_REFERENCE.png
```

Inspect them before implementing the corresponding areas. They communicate layout, scale, spatial relationships, style and atmosphere; they are not pixel-perfect blueprints.

## 5. Conflict priority

The project was designed iteratively. If information conflicts, use:

```text
1. 00_READ_ME_FIRST.md
2. QUESTIONS/DECISION_LOG.md
3. newer answered project questions
4. specialized numbered specification
5. 20_MASTER_INSTRUCTIONS_FOR_CLAUDE.md
6. older/general descriptions
7. visual reference for visual/layout interpretation
```

Visual references remain authoritative for approved spatial composition unless a written final rule explicitly corrects them. Never silently invent a solution to a genuine unresolved core conflict.

# FINAL PROJECT CORRECTIONS

## 6. Surface map

The surface world is **not a full city** and is **not divided into playable mine zones**.

It contains:
- 6 large player-company plots
- one compact central service area
- Equipment Shop
- Machine Shop
- Vehicle Shop
- Selling Building
- proper roads
- grass, trees, rocks and landscaping
- surrounding mountains
- limited decorative mining scenery
- only a few non-functional decorative structures

The center should feel like a clean mining service/commercial area, not a dense town. Do not add unnecessary functional NPCs.

## 7. Surface mining scenery is decoration only

Any quarry/mining-looking surface scenery is **DECORATION ONLY**.

Players do not access progression mines by walking into surface mining areas. Actual gameplay mines are separate Mine Shaft spaces accessed through each player's Elevator.

## 8. Player plots and factory scale

There are six similarly sized plots. Each is large enough for the complete company.

The final factory occupies a **large portion of the usable plot**, matching `MAP_MASTERPLAN_TOPDOWN.png` and `FACTORY_MASTERPLAN_TOPDOWN.png`.

Do not create a tiny hall in the middle of a huge empty plot.

Exterior space may contain road connection, entrance, low fence, landscaping and industrial/loading decoration.

## 9. Factory masterplan

`FACTORY_MASTERPLAN_TOPDOWN.png` is the primary factory spatial reference.

The final company is a large predetermined industrial hall. It is progressively constructed through Tycoon purchases, but its end layout is planned from the start.

**The original sheet-metal office hut is INSIDE the final factory.**

The player initially builds the small hut for `$0`. The factory later develops around it. The hut remains recognizable as the office in the endgame and contains the company laptop.

Functional progression:

```text
Office / Blechhütte
→ Elevator / early infrastructure
→ Storage
→ Garage
→ Smelter
→ later production expansion
```

Final corrections:

```text
STORAGE BEFORE GARAGE
GARAGE BEFORE SMELTER
```

The hall has a large industrial/glass roll-up vehicle entrance/exit.

## 10. Tycoon construction

The final layout is predetermined. Construction uses classic Roblox Tycoon floor purchase buttons.

- Prefer only the relevant next build button being visible.
- Purchased construction appears immediately.
- No freeform factory builder.
- No random/procedural hall layout.

## 11. Central area

Use `CENTRAL_AREA_REFERENCE.png`.

Core shared buildings:

```text
Equipment Shop
Machine Shop
Vehicle Shop
Selling Building
```

Keep the center clean, friendly, landscaped and road-connected, but compact. It is not a full city.

Equipment Shop sells Pickaxes and Backpacks.
Machine Shop sells Drills and Conveyors.
Vehicle Shop sells Cars/Utility Vehicles/Trucks.

There is **no generic Upgrade Shop**.

## 12. Selling

The Selling Building sits directly on the road.

Early game: player can sell carried ore.
Later: player drives vehicle cargo to the selling interaction.

Selling awards:

```text
Cash + Mining XP
```

The player continues driving sales vehicles manually in the endgame. Do not add automatic selling.

## 13. Mine Shaft – final layout

Use `MINE_SHAFT_REFERENCE.png`.

Every Mine Shaft is a **single-level compact underground room**.

It is not:
- multi-level
- a cave maze
- a railway mine
- a room filled with permanent conveyors

The player must instantly recognize:
1. Elevator arrival
2. Mining Area/Slot 1
3. Mining Area/Slot 2

The Elevator is the obvious central arrival/navigation point.

### Explicitly forbidden in the standard Mine Shaft

Do **not** add:
- railway tracks
- minecarts / Loren
- decorative rail systems
- default conveyor belts through the basic Mine Shaft

Earlier image drafts contained these and they were intentionally rejected.

Later conveyor automation may use only the specifically designed fixed logistics system; do not infer railway/conveyor decoration from generic mining aesthetics.

Mine visual style:
- rough organic rock walls
- readable single floor
- industrial mining lights
- timber supports
- compact industrial props
- mining cage Elevator
- two obvious mining areas
- no plain rectangular gray box

Early rock stays relatively gray; later shafts may become darker.

## 14. Infinite ore source

The ore vein is effectively infinite. Mining never permanently destroys/excavates the room.

Manual mining provides animation, hit feedback, small debris/stone effects and ore feedback while the source remains available.

## 15. Mining slots

Each Mine Shaft has two primary mining slots.

For each mining slot:

```text
Worker OR Drill
```

A Drill replaces the mining worker at that slot. Transport workers are separate logistics roles.

## 16. Early workers

Workers are an early-game system. Around the second mine, the player should be able to begin automating the first mine.

Worker economy:

```text
one-time hire cost
+ recurring wage
```

Do not postpone workers until late game.

## 17. Storage, Garage, Smelter

Storage is built before Garage.

Initial storage target:

```text
1000 total capacity
```

It is one logical company storage system, not one mandatory silo per ore. Capacity upgrades are managed through the laptop.

Garage follows Storage. It manages vehicles and includes the glowing vehicle spawn/departure ring. The first vehicle currently targets `1000` cargo capacity.

Smelter follows Garage. It automatically selects the appropriate recipe and processes ore into more valuable material/bars. Running VFX appear only while active.

## 18. Conveyors

Conveyors arrive later than workers.

Current target:

```text
around Mining Level 35
```

Exact level is `TODO_BALANCE`.

Conveyors use fixed intended placement slots/paths. Do not create a fully freeform conveyor editor.

## 19. Vehicles

Vehicles are player-driven, responsive utility/industrial vehicles. Later vehicles become larger trucks.

Vehicle cargo is separate from Backpack inventory.

Player vehicles should not collide with one another in a griefing/blocking manner.

The player always drives to sell; no automatic endgame vehicle selling.

## 20. Mining Level and XP

There is one central Mining Level. It is permanently visible near the bottom center of the HUD.

Mining Level unlocks mines, equipment, machines, vehicles, building stages and systems.

Level 100 initially unlocks Prestige, but the architecture must support Level 1000+ later.

**Mining XP is awarded only when material is sold.**

No XP for:
- mining a hit
- transporting
- Drill production
- trading

Ore XP is independent from Cash SellValue.

## 21. Manual mining and Luck

Manual mining uses:
- Mining Power
- Mining Speed
- Mining Luck
- Backpack-controlled Ore Capacity

Only manual mining can trigger special Luck results.

A special result is either:

```text
1x–10x quantity
```

OR

```text
rare ore from up to approximately the next 4 ore tiers
```

Never both on the same result.

Workers, Drills and offline production do not generate these rare drops.

## 22. Ore progression

General pattern:

```text
Mine 01 – Coal
Mine 02 – Coal
Mine 03 – Copper
Mine 04 – Copper
...
```

Normally two consecutive mines per main ore type.

Diamonds are currently the final ore of the first major content set, but content must be expandable.

Coal remains Coal with the same base identity/value regardless of which Coal shaft produced it.

Do not use uncontrolled exponential ore values. Balance is finalized through testing.

## 23. Performance/material representation

Logical quantities are server-side numbers.

Do not create one physical Part per ore unit.

Transport can use visual piles representing roughly 1–100 units while the exact quantity remains logical/server-side.

## 24. Offline production

Offline production is enabled for a maximum of:

```text
1 hour
```

It produces materials, **not automatic Cash**.

It respects:
- production rates
- worker state
- wages/payment
- intermediate capacities
- Elevator capacity
- Storage capacity
- processing capacity
- bottlenecks

Do not simulate physical NPC movement second-by-second offline.

## 25. Multiplayer and ownership

Core progression remains personal/solo-oriented within a 6-player shared server.

Players may visit and trade, but cannot manipulate another player's:
- Tycoon buttons
- laptop
- machines
- inventory
- storage
- vehicle cargo
- production

No stealing, PvP or sabotage.

## 26. Trading

V1 plans direct player trading for:
- ores/materials
- selected Drills

No global Auction House required.

Trades must be server-authoritative, atomic and duplication-safe. Trading awards no Mining XP.

## 27. Prestige – intentionally unresolved item

Prestige becomes available at Mining Level 100 and grants permanent bonus/progression benefits.

Robux purchases/entitlements remain.

The following is intentionally still open:

```text
Which normal Cash-purchased Pickaxes, Backpacks, Drills and Vehicles
reset or remain after Prestige?
```

Claude must **not decide this automatically**.

If still unanswered when Prestige implementation is reached, write it to `QUESTIONS/OPEN_QUESTIONS.md` and postpone only the affected Prestige behavior.

## 28. Robux

Robux entitlements persist where appropriate and survive Prestige.

Normal core progression must not require Robux.

Monetization is not required for the first vertical slice.

# PROJECT WORKFLOW

## 29. Questions folder

Create if missing:

```text
QUESTIONS/
├── OPEN_QUESTIONS.md
├── ANSWERED_QUESTIONS.md
└── DECISION_LOG.md
```

Follow `17_QUESTIONS_AND_DECISION_WORKFLOW.md`.

Do not interrupt development for every small uncertainty. Bundle non-blocking questions and continue safe work.

## 30. Testing folder

Create if missing:

```text
TESTING/
├── TEST_PLAN.md
├── REGRESSION_CHECKLIST.md
└── BUGS.md
```

Follow `18_TESTING_AND_QUALITY.md`.

## 31. Technical principles

The project must be:

```text
server-authoritative
modular
data-driven
save-safe
multiplayer-safe
performance-conscious
expandable
```

Use stable internal IDs, centralized definitions/configuration and typed Luau where practical.

Do not create giant monolithic scripts.

Never trust the client for:
- Cash
- XP
- Level
- ore rewards
- rare drops
- inventory
- ownership
- placement
- production
- worker state
- vehicle cargo
- selling
- trades
- Prestige

The client requests actions; the server validates and determines economy-changing results.

## 32. First playable vertical slice

The first implementation target is only:

```text
Player joins
→ receives/claims Plot
→ builds $0 Office
→ chooses Company Name + Color + Logo
→ uses Elevator
→ enters Mine 01 (Coal)
→ arrives in the approved single-level Mine Shaft
→ manually mines Coal
→ Coal enters Starter Backpack
→ returns to Surface
→ sells Coal
→ receives Cash + Mining XP
→ Mining Level HUD updates
→ data saves
→ rejoin restores progress
```

Make this polished and architecturally correct before expanding.

## 33. Development order

Follow `16_CLAUDE_CODE_BUILD_PLAN.md`.

Core rule:

```text
BUILD SMALL
→ TEST
→ FIX
→ COMMIT
→ NEXT SYSTEM
```

Do not build 100 mines before Mine 01 works.
Do not build many vehicles before the first vehicle loop works.
Do not implement offline production before online production is correct.

## 34. Placeholders

Clean replaceable placeholders are allowed during technical development, but world layout must respect the approved masterplans from the start.

Do not create a completely different temporary map that later forces spatial systems to be rewritten.

## 35. Required audit output

After reading all documents and visual references, create/update:

```text
IMPLEMENTATION_STATUS.md
```

with:

```md
# Documentation Audit

## Documents Read
## Visual References Inspected
## Confirmed Core Rules
## Contradictions Resolved by 00_READ_ME_FIRST
## Remaining Open Blocking Questions
## Remaining Open Non-Blocking Questions
## Proposed First Build Phase
## Planned Files / Systems
```

Do not ask the user about contradictions already resolved by this file.

# 36. DO NOT DO

Do not:
- copy Idle Miner directly
- turn the central area into a large city
- create playable surface mine zones
- put the office outside the final factory
- make the final factory tiny relative to the plot
- create multi-level Mine Shaft rooms
- add rails or minecarts to the standard Mine Shaft
- add default conveyors through the basic Mine Shaft
- add Pets
- invent extra currencies
- add a generic Upgrade Shop
- automate vehicle selling
- give automated mining manual-only rare drops
- award Mining XP for trading
- let the client determine rewards
- make foreign company systems controllable
- silently invent unresolved major progression rules
- generate the entire game before testing the first loop

# 37. Product goal

The experience should evolve from:

```text
one miner
→ manual extraction
→ selling
→ better equipment
→ workers
→ logistics
→ storage
→ industrial drills
→ vehicles
→ conveyors
→ processing
→ large mining company
→ Prestige
```

The player's company should visibly grow from a tiny sheet-metal office into a serious mining operation.

It should feel like building and managing a **mining company**, not merely standing on purchase buttons while numbers increase.

# 38. Final instruction to Claude Code

When you first read this file:

**Do not immediately write gameplay code.**

First perform the documentation audit.

Then:
1. create missing project-management files/folders
2. record only genuinely unresolved questions
3. prepare the first implementation phase
4. build the smallest correct vertical slice
5. test it
6. fix it
7. continue phase by phase

If the user later explicitly changes a project rule, update the relevant specification and `QUESTIONS/DECISION_LOG.md` so the repository remains the source of truth.
