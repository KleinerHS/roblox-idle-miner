# 20 – MASTER INSTRUCTIONS FOR CLAUDE CODE

## ROLE

You are the lead Roblox engineer for this project.

Your job is **not** to improvise a generic simulator. Your job is to implement the game described by the project documentation in this repository.

The game is a high-quality stylized Roblox mining-company game inspired by the broad production-loop ideas of idle mining games, but it must be its own Roblox game and must not reproduce another game's protected art, maps, branding, characters, UI, text, or exact content.

---

# PROJECT ROOT

Expected local project folder:

```text
C:\Users\Allmo\OneDrive\Desktop\Roblox Idel Mine game
```

Treat the actual current workspace as authoritative. Never claim access to a path you cannot actually access.

---

# FIRST ACTION – DO NOT CODE YET

Before implementing gameplay:

1. recursively inspect the project
2. read every project `.md` specification
3. inspect `VISUAL_REFERENCES`
4. create/read the `QUESTIONS` workflow
5. create a project implementation inventory
6. identify contradictions and missing blocking decisions
7. write those into the project files

Create if missing:

```text
QUESTIONS/
    OPEN_QUESTIONS.md
    ANSWERED_QUESTIONS.md
    DECISION_LOG.md

TESTING/
    TEST_PLAN.md
    REGRESSION_CHECKLIST.md
    BUGS.md
```

Do **not** start by generating the entire game.

---

# PRODUCT VISION

The player starts as a miner and gradually builds a real mining company.

Core progression:

```text
manual mining
→ selling
→ better pickaxe/backpack
→ more mines
→ workers
→ transport workers
→ storage
→ drills
→ garage
→ vehicles
→ conveyors
→ smelting
→ industrial automation
→ prestige
```

The player always remains involved in important active gameplay, especially vehicle-based selling and optional manual mining for rare drops.

---

# WORLD

- 6 player plots.
- Central small mining town.
- Equipment Shop.
- Machine Shop.
- Vehicle Shop.
- Selling station/building directly accessible by road.
- 2–3 decorative buildings without gameplay purpose.
- Grass, trees, rocks and nature.
- Mountains surround the playable map.
- Proper roads suitable for later trucks.
- Each plot has the same fixed maximum size.

Do not build a flat empty baseplate experience.

---

# PLAYER COMPANY

At the beginning, almost nothing is built.

The first $0 tycoon purchase creates a small sheet-metal office hut.

The office:
- remains permanently
- later sits inside the larger factory
- contains the company laptop

During initial company setup, player chooses:
- company name
- company color
- company logo

Company name must use Roblox text filtering.

The final factory layout is predetermined. The player reveals/builds it in stages through classic tycoon floor purchase buttons.

Only the relevant next build button should normally be visible.

Important order:

```text
Office
→ early infrastructure
→ Storage
→ Garage
→ Smelter
→ later industrial expansion
```

Storage must be before Garage.
Garage must be before Smelter.

---

# MINES

The elevator connects the surface to many compact mine shafts.

It may technically teleport the player; it does not need to simulate a kilometer-long physical shaft.

Player can return directly from any mine to the surface.

Mine UI primarily displays shaft number.

Each mine:
- compact mine-shaft room
- organic/rough rock appearance
- infinite ore vein
- ore vein visually matches current ore
- two wooden mine support structures
- two mining slots
- worker OR drill per mining slot
- transport workers handle material movement toward elevator

The wall is never permanently depleted.

Early rock remains relatively gray; later shafts may become darker.

---

# ORE PROGRESSION

General pattern:

```text
Mine 01 – Coal
Mine 02 – Coal
Mine 03 – Copper
Mine 04 – Copper
...
```

Normally two mines per main ore type.

Diamonds are currently intended as the last ore in the first major content set, but architecture must allow more later.

Coal is always Coal and has the same base value regardless of shaft.

Do not use an uncontrolled `2^n` sell-value formula.

---

# MANUAL MINING

Player uses their Roblox avatar.

Manual mining uses:
- animated Pickaxe
- Mining Power
- Mining Speed
- Backpack Capacity
- Mining Luck

Early mining should start slowly, roughly around 1–2 ore per successful hit as a balancing direction, not a permanently hardcoded final value.

Rare drops occur **only** from manual mining.

A rare event is either:

```text
1x–10x quantity result
```

OR

```text
rare ore from up to roughly the next four ore tiers
```

Never both in the same mining result.

Drills, workers and offline production do not generate rare drops.

---

# EQUIPMENT

Equipment Shop:
- Pickaxes
- Backpacks

Machine Shop:
- Drills
- Conveyors

Vehicle Shop:
- Cars
- Trucks

No generic upgrade shop.

Company upgrades are managed through the laptop/progression systems.

Mining Level unlocks items; money purchases them.

---

# WORKERS

Workers become available very early.

By/around the second mine, the player should be able to begin automating the first mine.

Workers:
- have one-time HireCost
- have WagePerMinute
- are managed on laptop
- can mine or transport depending on role
- wear consistent mining-worker outfits

A mine can support up to the designed worker roles/slots; mining slots remain two.

Transport workers move ore to the elevator before conveyors are available.

Workers should use fixed primary routes and alternative routing when blocked.

The economic simulation must not depend on tiny visual pathfinding timing differences.

---

# DRILLS

Drills replace mining workers on a mining slot.

Rule:

```text
Worker OR Drill
```

Drill:
- animates while operating
- drilling effect
- small stone/debris VFX
- produces a defined amount per time
- has output capacity
- has no rare drops

Purchased drills go to inventory first.

Player selects a drill and places it only on a valid fixed slot.

---

# MATERIAL VISUALIZATION

Do not create one physical ore object per unit.

Transport material as visual piles.

A pile may represent approximately 1–100 units.

The visual pile may stay approximately the same size to avoid unnecessary performance cost.

Logical quantity remains exact server-side.

---

# STORAGE

Storage is built before Garage.

Initial total capacity:

```text
1000
```

There is one logical large company storage rather than requiring a separate silo for every ore.

Visually the storage area includes a large silo/industrial storage system with:
- fill display
- conveyor connections
- industrial presentation

Storage capacity is upgraded through the laptop Storage app.

Production continues until relevant intermediate stages and storage are full; then bottlenecks stop upstream production.

---

# ELEVATOR

Elevator has limited material capacity.

Capacity is upgraded from the laptop.

It is also the player's mine navigation system.

Visual design:
- mining cage
- metal grid
- industrial/old mining character
- stylized high quality

---

# GARAGE AND VEHICLES

Garage comes after Storage and before Smelter.

Vehicle Shop is in the central town.

Purchased vehicles are managed/spawned through Garage UI.

Garage has a glowing spawn/departure ring.

When spawning a vehicle:
- spawn safely
- place player directly in driver seat

First vehicle capacity:

```text
1000
```

Later vehicles increase capacity.

Driving:
- realistic enough
- responsive
- not floaty
- clean utility vehicles
- later trucks

Player always drives the selling vehicle manually, including late game.

Do not add automatic endgame selling.

Player vehicles should not collide with one another in a way that allows griefing/blocking.

---

# SELLING

Selling station is directly beside/connected to the main road.

Player can:
- enter building and sell carried material
- later sell vehicle cargo through the appropriate selling interaction

Selling gives:

```text
Cash
+
Mining XP
```

Mining XP is awarded only when selling.

Trading does not award XP.

---

# CONVEYORS

Conveyors arrive significantly after workers.

Current target is around Mining Level 35, but exact level is `TODO_BALANCE`.

Conveyors:
- are bought in Machine Shop
- enter inventory
- are placed only on fixed intended slots
- automate designated logistics paths
- have throughput

Do not build a freeform Factorio-style conveyor editor.

---

# SMELTER

Garage comes before Smelter.

Smelter:
- processes ore into bars/processed material
- automatically selects appropriate recipe
- only shows active running VFX while operating
- has input/output capacity
- processed product must be worth more than raw input

Raw selling must remain valid.

---

# LAPTOP

Laptop is in the permanent office hut.

On interaction:
- short camera zoom
- clean company-management UI

Core apps:

```text
DASHBOARD
EMPLOYEES
STORAGE
ELEVATOR
PRODUCTION
COMPANY
```

Use it for:
- employee management
- storage upgrades
- elevator upgrades
- company overview
- production status
- company identity information

Do not turn it into a fake Windows clone.

---

# HUD

Permanent important UI:

- Cash
- Mining Level
- Mining XP
- Backpack status when relevant

Mining Level is permanently displayed at the bottom center.

Rare drops get a clear but short special notification.

UI style:
- clean
- modern
- gamer-oriented
- pleasant tones
- company color as accent
- responsive Roblox UI

Avoid cheap simulator UI, excessive neon and popup spam.

---

# MINING LEVEL

Mining Level is the central progression value.

It unlocks:
- mines
- equipment
- machines
- vehicles
- building stages
- systems

Level 100 is not the technical maximum.

Architecture must support eventual Level 1000+ content.

Level 100 initially unlocks Prestige.

---

# ECONOMY

Primary normal currency: Cash.

Do not invent Gems/Tokens/etc. unless later explicitly specified.

Ore has separate:
- SellValue
- MiningXP

Do not calculate XP directly from price.

Balance must be data-driven.

Do not scatter final numbers throughout scripts.

Unknown values should be marked centrally as:

```text
TODO_BALANCE
```

Build a small vertical slice before scaling content.

---

# PRESTIGE

Prestige becomes available at Mining Level 100.

It is optional, never automatic.

Before prestige show:
- what resets
- what remains
- permanent bonus

Permanent:
- Prestige Count
- Prestige bonuses
- Robux entitlements
- company identity should currently remain

Normal company progression largely resets.

Important unresolved item:
whether normal purchased Pickaxes/Backpacks remain after Prestige.

Do not decide that yourself. Put it in `QUESTIONS/OPEN_QUESTIONS.md` if still unanswered.

Prestige must be atomic and duplication-safe.

---

# OFFLINE PRODUCTION

Maximum:

```text
1 hour
```

Offline production generates material, not cash.

It respects:
- production rates
- worker state
- wages/payment
- drill output
- elevator capacity
- storage
- smelter
- intermediate bottlenecks

Do not simulate every NPC second-by-second.

Use mathematical/event-based calculation.

Vehicles do not automatically sell while offline.

---

# MULTIPLAYER

Core game remains primarily solo.

6 player plots per server.

Players may visit each other but cannot:
- use foreign laptop
- alter foreign machines
- press foreign tycoon buttons
- steal cargo
- sell foreign material
- sabotage production

No PvP.

---

# TRADING

Direct player trading is planned for:
- ores/materials
- selected Drills

No global auction house required in V1.

Trade must:
- be server-authoritative
- use atomic commit
- reset confirmations when offer changes
- protect against disconnects
- prevent placed Drill trading
- use unique Drill Instance IDs where required
- generate no Mining XP

---

# DATA

Persistent data includes all major progression and ownership.

Use:
- DataVersion
- migration support
- session locking
- autosave
- safe shutdown handling

Never overwrite a valid existing profile with empty defaults because of a load failure.

---

# SECURITY

Never trust client values for:
- money
- XP
- level
- ore amount
- price
- sell value
- item ownership
- rare drops
- placement ownership
- worker state
- vehicle cargo
- trade ownership

Validate every economy-changing Remote on server.

---

# PERFORMANCE

Design for:
- 6 plots
- many mines
- workers
- drills
- conveyors
- vehicles
- factory VFX

Avoid:
- one physical object per ore
- thousands of independent loops
- excessive Pathfinding
- permanent heavy particles
- hundreds of active ViewportFrames

Prepare for `StreamingEnabled`.

---

# DEVELOPMENT ORDER

Follow `16_CLAUDE_CODE_BUILD_PLAN.md`.

Core rule:

```text
BUILD SMALL
→ TEST
→ FIX
→ COMMIT
→ NEXT SYSTEM
```

Do not build 100 mines before Mine 01 works correctly.

---

# QUESTIONS WORKFLOW

Follow `17_QUESTIONS_AND_DECISION_WORKFLOW.md`.

Write unresolved questions into:

```text
QUESTIONS/OPEN_QUESTIONS.md
```

Do not repeatedly interrupt development for non-blocking questions.

Bundle them.

Only block the affected feature when the decision is truly required.

---

# VISUALS

Use project visual references.

Do not copy protected assets/UI/maps from Idle Miner or another game.

Use only the general production/management inspiration and create original Roblox-specific assets and layouts.

If a final visual reference does not yet exist:
- follow the project's shared visual style
- use clean replaceable placeholders where necessary
- record important unresolved visual decisions rather than inventing a conflicting art direction

---

# CODE QUALITY

Use:
- modular services
- modular controllers
- central definitions
- stable IDs
- reusable UI components
- clear naming
- typed Luau where practical
- comments for non-obvious architecture, not noise

Do not create giant scripts containing the entire game.

---

# TESTING

Follow `18_TESTING_AND_QUALITY.md`.

Every major phase needs:
- happy-path test
- failure-path test
- save/rejoin test
- ownership/security test where relevant
- regression checklist

Critical dupe/economy bugs block dependent development.

---

# FIRST IMPLEMENTATION TARGET

The first playable target is only:

```text
Player joins
→ receives plot
→ builds $0 office
→ chooses company identity
→ uses elevator
→ enters Mine 01 (Coal)
→ manually mines with animated Starter Pickaxe
→ Coal enters Starter Backpack
→ returns to surface
→ sells Coal
→ receives Cash + Mining XP
→ Mining Level HUD updates
→ data saves
→ rejoin restores state
```

Make this polished and architecturally correct before adding the next major system.

---

# FINAL INSTRUCTION

When uncertain, do not silently invent core game rules.

Check documentation first.

If still unresolved:
- write a precise question into `QUESTIONS`
- explain why it matters
- state what work can continue safely
- continue with non-blocked work

The objective is a maintainable, polished Roblox mining-company game, not the fastest possible pile of generated scripts.
