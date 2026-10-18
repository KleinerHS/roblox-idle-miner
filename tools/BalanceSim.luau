--!strict
-- Balance-Simulator (Phase 14a, docs/16 §17, docs/11 §22–23, §41). Spielt einen Spieler mit den
-- echten Definitionen (ReplicatedStorage.Shared) von Level 1 bis Level 100 durch und liefert
-- Zeiten, Einnahmen, Amortisationszeiten und Käufe. Läuft in Studio (Edit) per execute_luau:
-- Inhalt der Datei als Code ausführen. Reines Rechenmodell, ändert nichts am Spiel.
--
-- Strategie: Der Spieler kauft immer das Angebot mit der kürzesten Amortisationszeit
-- (Preis / zusätzlicher Gewinn pro Sekunde, docs/11 §23) und spart darauf, wenn es noch zu
-- teuer ist. Voraussetzungen (Gebäude, Fahrzeug, Lagerkiste) werden mitgekauft.
--
-- Annahmen (ASSUME, mit Felix abstimmen):
--   * aktives Dauerspiel, manuell immer in der besten freien Mine
--   * Verkaufsweg Rucksack: ManualTripSeconds (Laufen, Förderkorb, Tresen)
--   * Lager → Verkauf nur per Fahrzeug: VehicleTripSeconds + Beladen (höchstens Loading.FullLoadSeconds)
--   * nicht simuliert: Schmelzer, Förderbänder, Prestige, Rare Drops, Handel, Offline

local ASSUME = {
	ManualTripSeconds = 40,
	VehicleTripSeconds = 60,
	TickSeconds = 5,
	MaxHours = 400,
	TargetLevel = 100,
	-- XP-Kurve zum Ausprobieren (nil = BalanceConfig.Leveling); per _G.BalanceSimXP überschreibbar
	XPBase = nil :: number?,
	XPExponent = nil :: number?,
	XPKnee = nil :: number?, -- ab diesem Level steiler (abschnittsweise Kurve)
	XPLateExponent = nil :: number?,
	XPSegments = nil :: { { UpTo: number, Exponent: number } }?, -- abschnittsweise (wie BalanceConfig.Leveling.Segments)
	Quiet = false, -- true = nur Level-Zeiten
}
local override = (_G :: any).BalanceSimXP
if override then
	ASSUME.XPBase, ASSUME.XPExponent, ASSUME.Quiet = override.Base, override.Exponent, override.Quiet == true
	ASSUME.XPKnee, ASSUME.XPLateExponent = override.Knee, override.LateExponent
	ASSUME.XPSegments = override.Segments
end

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BC = require(Shared.Config.BalanceConfig)
local Leveling = require(Shared.Util.Leveling)
local D = Shared.Definitions
local Pickaxes = require(D.Pickaxes)
local Backpacks = require(D.Backpacks)
local Mines = require(D.Mines)
local Ores = require(D.Ores)
local Drills = require(D.Drills)
local Vehicles = require(D.Vehicles)
local BuildSteps = require(D.BuildSteps)
local ContentCurve = require(D.ContentCurve)

local W = BC.Workers
local SLOTS = 2

-- XP-Bedarf je Level (wie Leveling.xpRequired, optional mit Testwerten)
local function xpRequired(level: number): number
	if ASSUME.XPSegments then
		-- stetig zusammengesetzte Potenzkurve: in jedem Abschnitt Faktor × (L / Start)^Exponent
		local base = ASSUME.XPBase or 100
		local value, from = base, 1
		for _, seg in ASSUME.XPSegments :: any do
			local upTo = math.min(level, seg.UpTo)
			value *= (upTo / from) ^ seg.Exponent
			from = upTo
			if level <= seg.UpTo then
				break
			end
		end
		return math.max(1, math.floor(value))
	end
	if ASSUME.XPBase then
		local base, e = ASSUME.XPBase :: number, ASSUME.XPExponent :: number
		local knee = ASSUME.XPKnee
		if knee and level > knee then
			return math.max(1, math.floor(base * knee ^ e * (level / knee) ^ (ASSUME.XPLateExponent :: number)))
		end
		return math.max(1, math.floor(base * level ^ e))
	end
	return Leveling.xpRequired(level)
end
local function addXP(level: number, xp: number, amount: number): (number, number)
	xp += amount
	local need = xpRequired(level)
	while xp >= need do
		xp -= need
		level += 1
		need = xpRequired(level)
	end
	return level, xp
end

type State = {
	level: number,
	pick: number,
	pack: number,
	vehicle: number,
	elevator: number,
	crates: number,
	built: number, -- Anzahl gebauter BuildSteps (in Listenreihenfolge)
	mines: number, -- freigeschaltete Minen 1..n
	slots: { [number]: { any } }, -- je Mine: "worker" oder Drill-Index
	transport: { [number]: number },
}

local S: State = {
	level = 1,
	pick = 1,
	pack = 1,
	vehicle = 0,
	elevator = 0,
	crates = BC.Storage.StartCrates,
	built = 0,
	mines = 1,
	slots = {},
	transport = {},
}
local t, xp, cash = 0, 0, BC.StartCash
local earnedManual, earnedAuto, wagesPaid = 0, 0, 0
local log: { string } = {}
local levelTimes: { [number]: number } = { [1] = 0 }
local levelCash: { [number]: number } = {}

local function fmt(n: number): string
	if n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fk", n / 1e3)
	end
	return string.format("%d", math.floor(n))
end
local function clock(sec: number): string
	return string.format("%dh%02dm", sec // 3600, (sec % 3600) // 60)
end

local function copy(st: State): State
	local c = table.clone(st)
	c.slots = {}
	for i, s in st.slots do
		c.slots[i] = table.clone(s)
	end
	c.transport = table.clone(st.transport)
	return c
end

local function ore(i: number)
	return Ores.Get(Mines.List[i].OreId) :: any
end
local function stepIndex(id: string): number
	for i, s in BuildSteps.List do
		if s.Id == id then
			return i
		end
	end
	error(id)
end
local STORAGE_STEP = stepIndex("build_storage")
local GARAGE_STEP = stepIndex("build_garage")
local ELEVATOR_STEP = stepIndex("build_elevator")

local function cratePrice(n: number): number
	local p = BC.Storage.CratePrices
	if n <= #p then
		return p[n]
	end
	return math.floor(p[#p] * BC.Storage.CrateGrowth ^ (n - #p))
end
local function elevatorCap(st: State): number
	return if st.elevator == 0 then BC.Elevator.StartCapacity else BC.Elevator.Upgrades[st.elevator].Capacity
end
local function slotRate(s: any): number
	if s == "worker" then
		return W.Mining.OrePerMinute / 60
	end
	local d = Drills.List[s]
	return d.OrePerCycle / d.CycleSeconds
end

-- Geld/s, XP/s, Lohn/s und Detailwerte eines Zustands
local function rates(st: State): (number, number, number, { [string]: number })
	-- manuell
	local p = Pickaxes.List[st.pick]
	local cap = Backpacks.List[st.pack].Capacity
	local o = ore(st.mines)
	local manualUnits = cap / (cap / (p.MiningPower * p.MiningSpeed) + ASSUME.ManualTripSeconds)
	local money = manualUnits * o.SellValue
	local xpRate = manualUnits * o.XPValue
	-- Automation: Slots → Transport → Elevator → Lager → Fahrzeug
	local produced, value, xpSum, wage = 0, 0, 0, 0
	for i, slots in st.slots do
		local mined = 0
		for _, s in slots do
			mined += slotRate(s)
			if s == "worker" then
				wage += W.Mining.WagePerMinute / 60
			end
		end
		-- direkt in den Elevator (D-041), keine Transport-Worker
		local flow = mined
		produced += flow
		value += flow * ore(i).SellValue
		xpSum += flow * ore(i).XPValue
	end
	local sold = 0
	if produced > 0 and st.vehicle > 0 and st.crates > 0 then
		local load = math.min(Vehicles.List[st.vehicle].Capacity, st.crates * BC.Storage.CrateSize)
		local vehicleRate = load / (ASSUME.VehicleTripSeconds + math.min(load / BC.Loading.UnitsPerSecond, BC.Loading.FullLoadSeconds))
		sold = math.min(produced, elevatorCap(st) / BC.Elevator.CycleSeconds, vehicleRate)
	end
	local share = if produced > 0 then sold / produced else 0
	return money + value * share - wage, xpRate + xpSum * share, wage, { manual = manualUnits, produced = produced, sold = sold }
end

-- Voraussetzungen: Gebäude bis Index `step`, Fahrzeug, Lagerkiste
local function prereqCost(st: State, step: number): number
	local cost = 0
	for i = st.built + 1, step do
		local b = BuildSteps.List[i]
		if st.level < b.RequiredLevel then
			return math.huge
		end
		cost += b.Price
	end
	st.built = math.max(st.built, step)
	return cost
end
local function automationPrereq(st: State): number
	local cost = prereqCost(st, math.max(STORAGE_STEP, GARAGE_STEP))
	if cost == math.huge then
		return cost
	end
	if st.vehicle == 0 then
		local v = Vehicles.List[1]
		if st.level < v.RequiredLevel then
			return math.huge
		end
		cost += v.Price
		st.vehicle = 1
	end
	if st.crates == 0 then
		cost += cratePrice(1)
		st.crates = 1
	end
	return cost
end

type Offer = { name: string, cost: number, after: State }

local function offers(st: State): { Offer }
	local list: { Offer } = {}
	local function add(name: string, build: (State) -> number)
		local after = copy(st)
		local cost = build(after)
		if cost < math.huge then
			table.insert(list, { name = name, cost = cost, after = after })
		end
	end
	local np = Pickaxes.List[st.pick + 1]
	if np and np.Available ~= false and st.level >= np.RequiredLevel then
		add(np.Id, function(a)
			a.pick += 1
			return np.Price
		end)
	end
	local nb = Backpacks.List[st.pack + 1]
	if nb and nb.Available ~= false and st.level >= nb.RequiredLevel then
		add(nb.Id, function(a)
			a.pack += 1
			return nb.Price
		end)
	end
	local nm = Mines.List[st.mines + 1]
	if nm and nm.RequiredLevel and st.level >= nm.RequiredLevel then
		add(nm.Id, function(a)
			a.mines += 1
			return (nm.UnlockCost or 0) + prereqCost(a, ELEVATOR_STEP)
		end)
	end
	if st.vehicle > 0 then
		local nv = Vehicles.List[st.vehicle + 1]
		if nv and st.level >= nv.RequiredLevel then
			add(nv.Id, function(a)
				a.vehicle += 1
				local need = math.ceil(nv.Capacity / BC.Storage.CrateSize)
				local cost = nv.Price
				while a.crates < need and a.crates < BC.Storage.MaxCrates do
					a.crates += 1
					cost += cratePrice(a.crates)
				end
				return cost
			end)
		end
		local ne = BC.Elevator.Upgrades[st.elevator + 1]
		if ne and st.level >= ne.RequiredLevel then
			-- Paket: Elevator-Stufe + (falls nötig) Fahrzeuge/Kisten, damit der Verkauf mithält
			add(`Elevator {ne.Capacity}`, function(a)
				a.elevator += 1
				local cost = ContentCurve.latePrice(ne.Cost, ne.RequiredLevel) -- Spätspiel-Aufschlag (D-046)
				local elevatorRate = ne.Capacity / BC.Elevator.CycleSeconds
				while true do
					local v = Vehicles.List[a.vehicle]
					local load = math.min(v.Capacity, a.crates * BC.Storage.CrateSize)
					local rate = load / (ASSUME.VehicleTripSeconds + math.min(load / BC.Loading.UnitsPerSecond, BC.Loading.FullLoadSeconds))
					if rate >= elevatorRate then
						break
					end
					if load < v.Capacity and a.crates < BC.Storage.MaxCrates then
						a.crates += 1
						cost += cratePrice(a.crates)
					else
						local nv2 = Vehicles.List[a.vehicle + 1]
						if not nv2 or a.level < nv2.RequiredLevel then
							break
						end
						a.vehicle += 1
						cost += nv2.Price
					end
				end
				return cost
			end)
		end
	end
	-- Slots: neue Belegung oder besserer Drill, inkl. nötiger Transport-Worker
	local bestDrill = 0
	for di, d in Drills.List do
		if st.level >= d.RequiredLevel then
			bestDrill = di
		end
	end
	local choices: { any } = { "worker" }
	for di, d in Drills.List do
		if st.level >= d.RequiredLevel then
			table.insert(choices, di)
		end
	end
	local function better(target: any, cur: any): boolean
		if cur == nil then
			return true
		end
		return slotRate(target) > slotRate(cur)
	end
	for i = st.mines, 1, -1 do
		local slots = st.slots[i] or {}
		for s = 1, SLOTS do
			local cur = slots[s]
			for _, target in choices do
				if better(target, cur) then
					local label = if target == "worker" then "Mining-Worker" else Drills.List[target].Id
					add(`{label} → {Mines.List[i].Id} Slot {s}`, function(a)
						local cost = automationPrereq(a)
						if cost == math.huge then
							return cost
						end
						a.slots[i] = a.slots[i] or {}
						a.slots[i][s] = target
						if target == "worker" then
							cost += W.Mining.HireCost
						else
							-- neue MK-Stufe nur per Kauf (D-043); Drill-Level 1–10 simuliert das Modell nicht
							cost += Drills.List[target].Price
						end
						return cost
					end)
				end
			end
		end
		if i < st.mines - 6 then
			break -- nur die 7 besten Minen anbieten (Rechenzeit)
		end
	end
	return list
end

local target: Offer? = nil
local function decide()
	local base = rates(S)
	local best: Offer? = nil
	local bestPayback = math.huge
	for _, o in offers(S) do
		local gain = rates(o.after) - base
		-- Minen öffnen auch zwei neue Slots: mindestens 10 % des aktuellen Gewinns als Nutzen
		if string.sub(o.name, 1, 5) == "mine_" then
			gain = math.max(gain, base * 0.1)
		end
		local payback = if o.cost <= 0 then 0 elseif gain > 1e-9 then o.cost / gain else math.huge
		-- Bewertung: Wartezeit bis bezahlbar + Amortisation (nicht ewig auf Teures sparen)
		local wait = math.max(0, o.cost - cash) / math.max(base, 1e-6)
		local score = wait + payback
		if score < bestPayback then
			best, bestPayback = o, score
			local oa: any = o
			oa.payback = payback
		end
	end
	target = best
end

local ticks = 0
decide()
while S.level < ASSUME.TargetLevel and t < ASSUME.MaxHours * 3600 do
	t += ASSUME.TickSeconds
	local money, xpRate, wage, detail = rates(S)
	local manualMoney = detail.manual * ore(S.mines).SellValue
	earnedManual += manualMoney * ASSUME.TickSeconds
	earnedAuto += (money + wage - manualMoney) * ASSUME.TickSeconds
	wagesPaid += wage * ASSUME.TickSeconds
	cash += money * ASSUME.TickSeconds
	local before = S.level
	S.level, xp = addXP(S.level, xp, xpRate * ASSUME.TickSeconds)
	for l = before + 1, S.level do
		levelTimes[l] = t
		levelCash[l] = cash
	end
	decide()
	local tg = target
	if tg and cash >= tg.cost then
		cash -= tg.cost
		local newLevel = S.level
		S = tg.after
		S.level = newLevel
		local after = rates(S)
		table.insert(log, `{clock(t)} L{S.level}: {tg.name} für ${fmt(tg.cost)} (Amortisation {math.floor(((tg :: any).payback or 0) / 60 + 0.5)} min, Gewinn jetzt ${fmt(after * 60)}/min)`)
		decide()
	end
	ticks += 1
	if ticks % 2000 == 0 then
		task.wait()
	end
end

local out = { `Annahmen: Rucksack-Weg {ASSUME.ManualTripSeconds}s, Fahrzeugfahrt {ASSUME.VehicleTripSeconds}s, aktives Dauerspiel` }
local marks = { 2, 3, 5, 7, 10, 12, 15, 17, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100 }
local prev = 1
for _, l in marks do
	if levelTimes[l] then
		table.insert(out, `L{l}: {clock(levelTimes[l])} (+{clock(levelTimes[l] - levelTimes[prev])} ab L{prev}) Geld ${fmt(levelCash[l] or 0)}`)
		prev = l
	end
end
local money, xpRate, _, detail = rates(S)
table.insert(out, `Ende: L{S.level} nach {clock(t)}, Geld ${fmt(cash)}, Gewinn ${fmt(money * 60)}/min, XP {fmt(xpRate * 60)}/min`)
table.insert(out, `Verdient: manuell ${fmt(earnedManual)}, automatisch ${fmt(earnedAuto)}, Löhne ${fmt(wagesPaid)}`)
table.insert(out, `Zustand: {Pickaxes.List[S.pick].Id}, {Backpacks.List[S.pack].Id}, Fahrzeug {S.vehicle}, Elevator-Stufe {S.elevator}, Kisten {S.crates}, Minen {S.mines}, Erz/s manuell {string.format("%.1f", detail.manual)}, Automation {string.format("%.1f", detail.produced)} produziert / {string.format("%.1f", detail.sold)} verkauft`)
if not ASSUME.Quiet then
	table.insert(out, "--- Käufe ---")
	for _, line in log do
		table.insert(out, line)
	end
end
return table.concat(out, "\n")
