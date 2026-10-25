#!/usr/bin/env python3
"""Fahrsimulation der Lastzüge durch den Kreisverkehr in der Map-Mitte (D-059).

Prüft, ob Grain Road Train (Scania) und Tipper Road Train (FH 540) beim Rechts-, Geradeaus- und
Linksabbiegen von jeder der sechs Einfahrten Deko auf der Promenade, Gehweg-Laternen oder
Alleebäume berühren und wie weit die Anhänger nach innen ziehen. Nachbau von LayoutConfig/CenterBuilder (Werte unten bei Änderungen
mitziehen). Achs- und Kupplungsmaße aus assets/VehicleBodies.rbxm (Vorlagen-Rahmen, +Z = hinten).

Modell: Zugmaschine als Einspurmodell (Lenkeinschlag 47°, Pure Pursuit auf einer Fahrlinie mit
Radius rc im Kreisel), Anhänger folgen schlupffrei ihrer Kupplung. Verkehr gegen den Uhrzeigersinn,
Einfahrt auf der rechten Spur.

Aufruf: python3 tools/roundabout_sweep.py [teile.txt]   (braucht numpy)
Ohne Datei werden die Hindernisse aus den Regeln unten nachgebaut. Mit einer Teileliste aus
tools/topdown (bundle.py + luau) zählen alle echten kollidierenden Teile zwischen Bordstein- und
Aufbauhöhe.
"""
import sys
import math

# --- LayoutConfig (Map-Mitte) ---------------------------------------------------------------
PLOT_ANGLES = [150, 90, 30, -30, -90, 210]
PLOT_RING = 840
DOOR_X = 40            # Straßen laufen DoorCenterX neben der Radiallinie
ROAD_W = 28
PLAZA_R = 280
INNER, OUTER, PROM = 40, 86, 104          # RoundaboutInner/Outer, Center.PromenadeOuter
SIDEWALK = 5
REST_INSET, REST_SPREAD, REST_LAMP = 2.5, 6, 10.5   # Center.RestSpotInset/RestSpotSpread/RestSpotLampSpread
LAMP_START, ALLEY_START = 45, 20                     # Center.SidewalkLampStart/AlleyStart
FENCE_R = 272
STEER = math.radians(47)                  # A-Chassis SteerInner/Outer 50/45

# --- Fahrzeuge (Z-Werte im Vorlagen-Rahmen) ----------------------------------------------------
# tractor: Vorderachse F, Hinterachsmitte R, Front/Heck, Sattelkupplung K, halbe Breite
# trailers: (Königszapfen, Achsmitte, Aufbau vorne, Aufbau hinten); hitch: Kupplung zum nächsten
TRUCKS = {
    "Grain Road Train": dict(F=-12.0, R=5.95, front=-18.5, rear=12.7, K=5.8, half=5.3,
                             tr=[(5.8, 32.5, -0.2, 38.7), (37.4, 52.0, 36.1, 60.8), (54.2, 80.5, 47.7, 86.5)],
                             hitch=[37.4, 54.2]),
    "Tipper Road Train": dict(F=-10.0, R=5.5, front=-15.0, rear=11.2, K=4.6, half=5.0,
                              tr=[(4.6, 28.5, -1.0, 37.8), (34.8, 48.0, 34.3, 56.6), (47.3, 70.5, 42.1, 79.7)],
                              hitch=[34.8, 47.3]),
}


def add(a, b): return (a[0] + b[0], a[1] + b[1])
def sub(a, b): return (a[0] - b[0], a[1] - b[1])
def mul(a, k): return (a[0] * k, a[1] * k)
def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def norm(a): return math.hypot(a[0], a[1])
def unit(a): n = norm(a); return (a[0] / n, a[1] / n)
def rot(a, ang): c, s = math.cos(ang), math.sin(ang); return (a[0] * c - a[1] * s, a[0] * s + a[1] * c)


# Koordinaten: (X, -Z) = Draufsicht mit Norden oben, Winkel wie PlotAngles
def spokes():
    out = []
    for th in PLOT_ANGLES:
        u = (math.cos(math.radians(th)), math.sin(math.radians(th)))
        right = rot(u, math.pi / 2)   # rechts in Fahrtrichtung zur Mitte
        origin = add(mul(u, PLOT_RING), mul(right, DOOR_X))
        d = mul(u, -1)

        def hit(rad, origin=origin, d=d):
            b = dot(origin, d); c = dot(origin, origin) - rad * rad
            return -b - math.sqrt(max(b * b - c, 0))
        out.append(dict(u=u, right=right, origin=origin, d=d, t0=hit(PLAZA_R + 20), t1=hit(OUTER - 4), hit=hit))
    return out


SPOKES = spokes()


def spoke_dist(p):
    best = 1e9
    for s in SPOKES:
        rel = sub(p, s["origin"]); a = max(s["t0"], min(s["t1"], dot(rel, s["d"])))
        best = min(best, norm(sub(rel, mul(s["d"], a))))
    return best


def obstacles():
    obs = []
    # Sitzecke je Sektor (CenterBuilder.promenade): Sektormitte = größter Abstand zu den Straßen
    r_bench, r_lamp, r_bed = PROM - REST_INSET, PROM - 1, PROM + 4
    for k in range(6):
        best = max((spoke_dist((math.cos(math.radians(a10 / 10)) * r_bench, math.sin(math.radians(a10 / 10)) * r_bench)), a10 / 10)
                   for a10 in range(k * 600, k * 600 + 600))
        a0 = math.radians(best[1])
        for side in (-1, 1):
            for rr, arc, rad, label in ((r_bench, REST_SPREAD, 2.7, "Bank (Sitzecke)"),
                                        (r_lamp, REST_LAMP, 0.6, "Laterne (Sitzecke)"),
                                        (r_bed, REST_SPREAD + 0.5, 3.2, "Blumenbeet (Sitzecke)")):
                a = a0 + side * arc / rr
                obs.append(((math.cos(a) * rr, math.sin(a) * rr), rad, label))
    for s in SPOKES:
        t0 = s["hit"](PLAZA_R); t1 = s["hit"](PROM); length = t1 - t0
        count = int(length // 34)
        for side in (-1, 1):
            for k in range(1, count + 1):
                z = -length / 2 + (k - 0.5) * (length / count) + (8 if side > 0 else -8)
                p = add(add(s["origin"], mul(s["d"], (t0 + t1) / 2 - z)), mul(s["right"], side * (ROAD_W / 2 + SIDEWALK - 1)))
                if norm(p) >= PROM + LAMP_START:
                    obs.append((p, 0.6, "Laterne (Gehweg)"))
            lat = ROAD_W / 2 + SIDEWALK + 4
            t = s["hit"](FENCE_R - 6) + (4 if side > 0 else 15)
            t_end = s["hit"](PROM + ALLEY_START)
            while t < t_end:
                obs.append((add(add(s["origin"], mul(s["d"], t)), mul(s["right"], side * lat)), 1.6, "Alleebaum"))
                t += 22
    return [o for o in obs if norm(o[0]) < 200]


def obstacles_from_parts(path):
    """Echte Teile aus tools/topdown: kollidierend, höher als 0,45 über dem Boden, nahe der Mitte."""
    obs = []
    for line in open(path, encoding="utf8"):
        if not line.startswith("P|"):
            continue
        f = line.rstrip("\n").split("|")
        if len(f) < 10 or f[9] != "1":
            continue
        sx, sy, sz = map(float, f[3].split(",")); px, py, pz = map(float, f[4].split(","))
        r = list(map(float, f[5].split(",")))
        half_h = abs(r[3]) * sx / 2 + abs(r[4]) * sy / 2 + abs(r[5]) * sz / 2
        # nur was ein Lastzug treffen kann: über Bordsteinhöhe, unterhalb der Aufbauhöhe (~11)
        if py + half_h < 1.45 or py - half_h > 12 or math.hypot(px, pz) > 200:
            continue
        pts = []
        for dx in (-sx / 2, 0, sx / 2):
            for dz in (-sz / 2, 0, sz / 2):
                for dy in (-sy / 2, sy / 2):
                    wx = px + r[0] * dx + r[1] * dy + r[2] * dz
                    wz = pz + r[6] * dx + r[7] * dy + r[8] * dz
                    pts.append((wx, -wz))   # in (X, -Z)
        label = f[10].split(".")[-1] if len(f) > 10 else f[1]
        for q in pts:
            obs.append((q, 0.0, f"{label}/{f[1]}"))
    return obs


def build_path(i_in, steps, rc, lane=7):
    s_in = SPOKES[i_in]; s_out = SPOKES[(i_in - steps) % 6]
    off_in, off_out = DOOR_X + lane, DOOR_X - lane
    s0 = math.sqrt(max(rc * rc - off_in * off_in, 0))
    pts = [add(mul(s_in["u"], s), mul(s_in["right"], off_in)) for s in [300 - k * 2 for k in range(int((300 - s0) / 2))]]
    a0 = math.atan2(pts[-1][1], pts[-1][0])
    s1 = math.sqrt(max(rc * rc - off_out * off_out, 0))
    pe = add(mul(s_out["u"], s1), mul(s_out["right"], off_out))
    a1 = math.atan2(pe[1], pe[0])
    while a1 <= a0 + 0.05:
        a1 += 2 * math.pi
    n = int((a1 - a0) * rc / 2)
    pts += [(math.cos(a0 + (a1 - a0) * k / n) * rc, math.sin(a0 + (a1 - a0) * k / n) * rc) for k in range(n + 1)]
    pts += [add(mul(s_out["u"], s), mul(s_out["right"], off_out)) for s in [s1 + k * 2 for k in range(int((300 - s1) / 2))]]
    return pts


def simulate(truck, pts, lookahead):
    T = TRUCKS[truck]; L = T["R"] - T["F"]
    h = unit(sub(pts[5], pts[0])); R = sub(pts[0], mul(h, L))
    def kingpin(R, h): return add(R, mul(h, -(T["K"] - T["R"])))
    axles = []; hitch = kingpin(R, h)
    for k, (kz, az, _, _) in enumerate(T["tr"]):
        A = sub(hitch, mul(h, az - kz)); axles.append(A)
        if k < 2:
            hitch = sub(A, mul(h, T["hitch"][k] - az))
    idx = 0; ds = 0.25; frames = []
    for it in range(20000):
        while idx < len(pts) - 1 and norm(sub(pts[idx], R)) < lookahead:
            idx += 1
        if idx >= len(pts) - 1:
            return frames
        v = sub(pts[idx], R)
        alpha = math.atan2(h[0] * v[1] - h[1] * v[0], dot(h, v))
        delta = max(-STEER, min(STEER, math.atan2(2 * L * math.sin(alpha), lookahead)))
        R = add(R, mul(h, ds)); h = unit(rot(h, ds * math.tan(delta) / L))
        units = [(add(R, mul(h, L)), h, T["front"] - T["F"], T["rear"] - T["F"])]
        hitch = kingpin(R, h)
        for k, (kz, az, bf, br) in enumerate(T["tr"]):
            d = unit(sub(hitch, axles[k])); A = sub(hitch, mul(d, az - kz)); axles[k] = A
            units.append((A, d, bf - az, br - az))
            if k < 2:
                hitch = sub(A, mul(d, T["hitch"][k] - az))
        if it % 4 == 0:
            frames.append(units)
    return None   # Fahrlinie nicht geschafft (Regler schwingt) – Lauf verwerfen


def main():
    import numpy as np
    obs = obstacles_from_parts(sys.argv[1]) if len(sys.argv) > 1 else obstacles()
    P = np.array([o[0] for o in obs], dtype=float).reshape(-1, 2)
    RAD = np.array([o[1] for o in obs], dtype=float)
    labels = [o[2] for o in obs]
    names = {1: "rechts", 3: "geradeaus", 5: "links"}
    print(f"Kreisverkehr {INNER}-{OUTER}, Promenade bis {PROM}; Sitzecken ±{REST_LAMP} um die Sektormitte, Gehweg-Laternen ab r={PROM + LAMP_START}, Allee ab r={PROM + ALLEY_START}")
    print("Je Zeile: Einfahrt von Plot 1-6, schlechtester Wert über Fahrlinien r=64/72/80 (Abstand < 0 = Berührung)")
    worst_all = 99.0
    contacts = {}
    for truck in TRUCKS:
        half = TRUCKS[truck]["half"]
        for steps, name in names.items():
            cells = []
            inner_min = 99.0
            for i_in in range(6):
                worst = (99.0, "-")
                for rc in (64, 72, 80):
                    for lookahead in (14, 20):
                        frames = simulate(truck, build_path(i_in, steps, rc), lookahead)
                        if frames is None:
                            continue
                        for units in frames:
                            for ref, d, zf, zb in units:
                                rt = rot(d, -math.pi / 2)
                                for z in (zf, zb):
                                    for sd in (-half, half):
                                        inner_min = min(inner_min, norm(add(sub(ref, mul(d, z)), mul(rt, sd))))
                                if len(P) == 0:
                                    continue
                                rel = P - np.array(ref)
                                along = -(rel @ np.array(d))
                                lat = rel @ np.array(rt)
                                dz = np.maximum(np.maximum(zf - along, along - zb), 0.0)
                                dl = np.maximum(np.abs(lat) - half, 0.0)
                                c = np.hypot(dz, dl) - RAD
                                k = int(np.argmin(c))
                                if c[k] < worst[0]:
                                    worst = (float(c[k]), labels[k])
                                for j in np.nonzero(c <= 0)[0][:50]:
                                    contacts.setdefault(labels[j], set()).add(f"{truck.split()[0]} Plot {i_in + 1} {name}")
                worst_all = min(worst_all, worst[0])
                cells.append(f"{worst[0]:+5.1f} {worst[1][:22]:22s}")
            print(f"  {truck:18s} {name:9s} innerste Kante r={inner_min:5.1f}")
            for i, cell in enumerate(cells):
                print(f"      von Plot {i + 1}: {cell}")
    if contacts:
        print("Berührte Teile:")
        for lab, where in sorted(contacts.items()):
            print(f"  {lab}: {', '.join(sorted(where)[:6])}{' …' if len(where) > 6 else ''}")
    print("OK – keine Berührung" if worst_all > 0 else "BERÜHRUNG – Deko/Abstände anpassen")


if __name__ == "__main__":
    main()
