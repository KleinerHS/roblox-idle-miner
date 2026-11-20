"""Felix' Mine V5 (OBJ aus Primitiven) -> Luau-Datenmodule fuer Raum und Foerderkorb."""
import math, re, sys

src, out_room, out_cage = sys.argv[1], sys.argv[2], sys.argv[3]

BOX_FACES = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (3, 7, 6, 2), (0, 4, 7, 3), (1, 2, 6, 5)]
MATERIAL_BY_ID = {"272": "SmoothPlastic"}

mats = {}
cur = None
for l in open(src.replace(".obj", ".mtl"), encoding="utf-8"):
    p = l.split()
    if not p:
        continue
    if p[0] == "newmtl":
        cur = p[1]
        mats[cur] = {"kd": None, "d": 1.0}
    elif p[0] == "Kd":
        mats[cur]["kd"] = tuple(float(x) for x in p[1:4])
    elif p[0] == "d":
        mats[cur]["d"] = float(p[1])


def material_of(name):
    parts = name.split("_")
    if parts[0] == "Lift":
        mat = MATERIAL_BY_ID.get(parts[1], parts[1])
        hexc = parts[2]
        rgb = (int(hexc[0:2], 16), int(hexc[2:4], 16), int(hexc[4:6], 16))
    else:
        mat = parts[0]
        rgb = tuple(int(x) for x in parts[1:4])
    return mat, rgb


objs = []
verts = []
for l in open(src, encoding="utf-8"):
    p = l.split()
    if not p:
        continue
    if p[0] == "o":
        cur = {"name": l[2:].strip(), "v0": len(verts), "faces": [], "mtl": None}
        objs.append(cur)
    elif p[0] == "v":
        verts.append(tuple(float(x) for x in p[1:4]))
    elif p[0] == "usemtl":
        cur["mtl"] = p[1]
    elif p[0] == "f":
        cur["faces"].append(tuple(int(x) - 1 for x in p[1:]))

sub = lambda a, b: (a[0] - b[0], a[1] - b[1], a[2] - b[2])
add = lambda a, b: (a[0] + b[0], a[1] + b[1], a[2] + b[2])
mul = lambda a, s: (a[0] * s, a[1] * s, a[2] * s)
dot = lambda a, b: a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
length = lambda a: math.sqrt(dot(a, a))
norm = lambda a: mul(a, 1 / length(a))
cross = lambda a, b: (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def avg(pts):
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts), sum(p[2] for p in pts) / len(pts))


def frame(xv, yv):
    x = norm(xv)
    y = sub(yv, mul(x, dot(yv, x)))
    y = norm(y)
    z = cross(x, y)
    return x, y, z


parts = []
for o in objs:
    n = len(o["faces"])
    nv = (objs[objs.index(o) + 1]["v0"] if objs.index(o) + 1 < len(objs) else len(verts)) - o["v0"]
    v = verts[o["v0"]:o["v0"] + nv]
    rel = [tuple(i - o["v0"] for i in f) for f in o["faces"]]
    if nv == 8:
        shape = "Block"
        c = avg(v)
        nb = set()
        for f in rel:
            for k in range(len(f)):
                if f[k] == 0:
                    nb.add(f[k - 1]); nb.add(f[(k + 1) % len(f)])
        assert len(nb) == 3, o["name"]
        edges = [sub(v[i], v[0]) for i in sorted(nb)]
        # kanonisch: X = Kante am staerksten entlang Welt-X, Y = entlang Welt-Y (nah an der Original-Lage)
        ex = max(edges, key=lambda e: abs(e[0]) / length(e))
        rest = [e for e in edges if e is not ex]
        ey = max(rest, key=lambda e: abs(e[1]) / length(e))
        ez = next(e for e in rest if e is not ey)
        if ex[0] < 0:
            ex = mul(ex, -1)
        if ey[1] < 0:
            ey = mul(ey, -1)
        a, b = ex, ey
        cc = cross(norm(a), norm(b))
        cc = mul(cc, length(ez))
        size = (length(a), length(b), length(cc))
        x, y, z = frame(a, b)
        assert abs(dot(norm(a), norm(b))) < 1e-3 and abs(dot(norm(a), norm(cc))) < 1e-3, o["name"]
    elif nv == 48:
        shape = "Cylinder"
        caps = [f for f in rel if len(f) == 24]
        assert len(caps) == 2, o["name"]
        c1, c2 = avg([v[i] for i in caps[0]]), avg([v[i] for i in caps[1]])
        c = mul(add(c1, c2), 0.5)
        ax = sub(c2, c1)
        yv = sub(v[caps[0][0]], c1)
        r = length(yv)
        size = (length(ax), 2 * r, 2 * r)
        x, y, z = frame(ax, yv)
    elif nv == 146:
        shape = "Ball"
        c = avg(v)
        r = length(sub(v[0], c))
        size = (2 * r, 2 * r, 2 * r)
        x, y, z = (1, 0, 0), (0, 1, 0), (0, 0, 1)
    else:
        raise SystemExit(f"unbekannte Form {o['name']} {nv}")
    mat, rgb = material_of(o["mtl"])
    transp = 1 - mats[o["mtl"]]["d"]
    # Roblox-CFrame: Spalten = Achsen
    rot = (x[0], y[0], z[0], x[1], y[1], z[1], x[2], y[2], z[2])
    parts.append({"name": o["name"], "shape": shape, "pos": c, "rot": rot, "size": size, "mat": mat, "rgb": rgb, "t": transp})

CAGE = "Elevator/Foerderkorb/"
floor = next(p for p in parts if re.sub(r"_\d+$", "", p["name"]) == CAGE + "Korb/Boden")
cage_base = (-floor["pos"][0], floor["pos"][1] + floor["size"][1] / 2, floor["pos"][2])
assert abs(floor["size"][1] - 0.5) < 1e-3, floor["size"]
ROOM_SHIFT = (0, -1, 0)  # OBJ-Ursprung = Mitte des Bodens (o * (0, -1, 0))


def fmt(x):
    s = f"{x:.4f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def mirror_x(p):
    """Spiegelung an der YZ-Ebene: Felix' Programm zeigt OBJ seitenverkehrt zu Roblox
    (Ziffern „01“, Pult links). Fuer Quader/Zylinder/Kugeln: Lage (-x, y, z), Drehung M·R·M."""
    r = list(p["rot"])
    for i in (1, 2, 3, 6):  # R01, R02, R10, R20
        r[i] = -r[i]
    pos = (-p["pos"][0], p["pos"][1], p["pos"][2])
    return dict(p, pos=pos, rot=tuple(r))


def emit(path, header, items, origin, strip_index):
    lines = [
        "--!strict",
        header,
        "-- Automatisch erzeugt aus Felix' OBJ (tools: obj_to_luau.py). Nicht von Hand bearbeiten.",
        "-- Eintrag: { Pfad, Form, x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22, Breite, Hoehe, Tiefe, Material, R, G, B }",
        "",
        "return {",
    ]
    for p in items:
        name = p["name"]
        if strip_index:
            name = re.sub(r"_\d+$", "", name)
        pos = sub(p["pos"], origin)
        nums = [*pos, *p["rot"], *p["size"]]
        lines.append(
            f'\t{{ "{name}", "{p["shape"]}", {", ".join(fmt(n) for n in nums)}, "{p["mat"]}", {p["rgb"][0]}, {p["rgb"][1]}, {p["rgb"][2]} }},'
        )
    lines.append("}")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")


room = [p for p in parts if not p["name"].startswith(CAGE)]
cage = [mirror_x(dict(p, name=p["name"][len(CAGE):])) for p in parts if p["name"].startswith(CAGE)]
emit(out_room, "-- Mine-Shaft-Raum V5 (Felix 2026-11-20): alle sichtbaren Teile relativ zum Raumursprung (Bodenoberkante Mitte).", room, (-ROOM_SHIFT[0], -ROOM_SHIFT[1], -ROOM_SHIFT[2]), False)
emit(out_cage, "-- Foerderkorb V5 (Felix 2026-11-20): alle Teile relativ zur Korbboden-Oberkante Mitte, vorne = -Z.", cage, cage_base, True)
print("Raum", len(room), "Korb", len(cage), "Korbbasis (OBJ)", tuple(round(x, 3) for x in cage_base))
print("Transparente:", [(p["name"], p["t"]) for p in parts if p["t"] > 0][:5])
