--!strict
-- Runde Ausrundungen für Straßen (Felix 2026-10-27): Übergang einer geraden Fahrbahn in einen
-- Kreisverkehr bzw. in eine gerade Kante (Vorplatz). Fläche exakt aus Rechtecken und
-- rechtwinkligen Dreiecken (WedgePart), keine Stufen.
--
-- Koordinaten je Ausrundung: E = Punkt auf der Fahrbahnkante, u = Richtung entlang der Straße
-- (zum Kreisel bzw. weg vom Vorplatz), n = quer, weg von der Fahrbahn. Lokal a = quer (≥ 0),
-- b = entlang.

local RoadFillet = {}

local function rect(parent: Instance, name: string, F: CFrame, sgn: number, a0: number, a1: number, b0: number, b1: number, topY: number, color: Color3)
	if a1 - a0 < 0.01 or b1 - b0 < 0.01 then
		return
	end
	local cf = F * CFrame.new((a0 + a1) / 2, 0, sgn * (b0 + b1) / 2)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Size = Vector3.new(a1 - a0, 0.1, b1 - b0 + 0.01)
	p.CFrame = cf.Rotation + Vector3.new(cf.X, topY - 0.05, cf.Z)
	p.Color = color
	p.Material = Enum.Material.Asphalt
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
end

-- Rechtwinkliges Dreieck, rechter Winkel bei c
local function tri(parent: Instance, name: string, c: Vector3, a: Vector3, b: Vector3, topY: number, color: Color3)
	local u, v = a - c, b - c
	local la, lb = u.Magnitude, v.Magnitude
	if la < 0.02 or lb < 0.02 then
		return
	end
	u, v = u.Unit, v.Unit
	local zAxis, yAxis = -u, v
	local center = c + u * (la / 2) + v * (lb / 2)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.CanTouch = false
	w.CanCollide = false
	w.CanQuery = false
	w.Size = Vector3.new(0.1, lb, la)
	w.CFrame = CFrame.fromMatrix(Vector3.new(center.X, topY - 0.05, center.Z), yAxis:Cross(zAxis), yAxis, zAxis)
	w.Color = color
	w.Material = Enum.Material.Asphalt
	w.Parent = parent
end

type Frame = { F: CFrame, sgn: number, E: Vector3, u: Vector3, n: Vector3 }

local function frame(E: Vector3, u: Vector3, n: Vector3): Frame
	local flatE = Vector3.new(E.X, 0, E.Z)
	local zAxis = n:Cross(Vector3.yAxis)
	local sgn = if zAxis:Dot(u) >= 0 then 1 else -1
	return { F = CFrame.fromMatrix(flatE, n, Vector3.yAxis, zAxis), sgn = sgn, E = flatE, u = u, n = n }
end

local function world(fr: Frame, a: number, b: number): Vector3
	return fr.E + fr.n * a + fr.u * b
end

-- Fläche zwischen der Kurve (Punkte mit a ≥ 0, b monoton) und der Linie a = 0
local function fillCurve(parent: Instance, name: string, fr: Frame, pts: { Vector2 }, topY: number, color: Color3)
	for k = 1, #pts - 1 do
		local A, B = pts[k], pts[k + 1]
		local aMin = math.min(A.X, B.X)
		local bLo, bHi = math.min(A.Y, B.Y), math.max(A.Y, B.Y)
		rect(parent, `{name}R{k}`, fr.F, fr.sgn, 0, aMin, bLo, bHi, topY, color)
		local outerP = if A.X > B.X then A else B
		local innerP = if A.X > B.X then B else A
		tri(parent, `{name}T{k}`, world(fr, aMin, outerP.Y), world(fr, outerP.X, outerP.Y), world(fr, innerP.X, innerP.Y), topY, color)
	end
end

-- Erster Schnitt der Geraden E + n·a + u·b (b wachsend) mit dem Kreis (center, R); nil = kein Schnitt
local function ringEntry(E: Vector3, u: Vector3, n: Vector3, a: number, center: Vector3, R: number): number?
	local p = Vector2.new(E.X + n.X * a - center.X, E.Z + n.Z * a - center.Z)
	local d = Vector2.new(u.X, u.Z)
	local b = p:Dot(d)
	local disc = b * b - (p:Dot(p) - R * R)
	if disc < 0 then
		return nil
	end
	return -b - math.sqrt(disc)
end
RoadFillet.ringEntry = ringEntry

-- Ausrundung Fahrbahnkante → Kreisverkehr. Gibt zurück, wo die Ausrundung auf der Kante beginnt
-- (Abstand b ab E), damit Randlinien dort enden können.
function RoadFillet.toRing(parent: Instance, name: string, E: Vector3, u: Vector3, n: Vector3, center: Vector3, R: number, f: number, topY: number, color: Color3): number?
	local fr = frame(E, u, n)
	-- Mittelpunkt C = E + n·f + u·s mit |C − center| = R + f (erste Lösung vor dem Kreisel)
	local s = ringEntry(E, u, n, f, center, R + f)
	if not s then
		return nil
	end
	local C = fr.E + n * f + u * s
	local c2 = Vector3.new(center.X, 0, center.Z)
	local toCenter = (c2 - C).Unit
	-- Winkel in der Ebene (n, u): Start bei −n, Ende Richtung Kreiselmitte, kürzester Weg
	local th0 = math.atan2(0, -1)
	local th1 = math.atan2(toCenter:Dot(u), toCenter:Dot(n))
	local delta = (th1 - th0 + math.pi) % (2 * math.pi) - math.pi
	local steps = 18
	local pts: { Vector2 } = {}
	local maxA, maxB = 0, -math.huge
	for k = 0, steps do
		local th = th0 + delta * k / steps
		local a = f + math.cos(th) * f
		local b = s + math.sin(th) * f
		table.insert(pts, Vector2.new(a, b))
		maxA = math.max(maxA, a)
		maxB = math.max(maxB, b)
	end
	fillCurve(parent, name, fr, pts, topY, color)
	-- hinter dem Bogen bis in den Kreisel auffüllen (sonst bleibt ein Pflasterkeil)
	local e0 = ringEntry(E, u, n, 0, center, R)
	local e1 = ringEntry(E, u, n, maxA, center, R)
	if e0 and e1 then
		local bEnd = math.max(e0, e1) + 0.5
		if bEnd > maxB then
			rect(parent, `{name}Base`, fr.F, fr.sgn, 0, maxA, maxB, bEnd, topY, color)
		end
	end
	return s
end

-- Ausschwenkkurve Fahrbahnkante → gerade Querkante (b = 0 ist die Querkante, u zeigt von ihr weg)
function RoadFillet.toEdge(parent: Instance, name: string, E: Vector3, u: Vector3, n: Vector3, f: number, topY: number, color: Color3)
	local fr = frame(E, u, n)
	local steps = 14
	local pts: { Vector2 } = {}
	-- Viertelkreis um (f, f) von (0, f) bis (f, 0)
	for k = 0, steps do
		local th = math.pi + (math.pi / 2) * k / steps
		table.insert(pts, Vector2.new(f + math.cos(th) * f, f + math.sin(th) * f))
	end
	fillCurve(parent, name, fr, pts, topY, color)
end

return table.freeze(RoadFillet)
