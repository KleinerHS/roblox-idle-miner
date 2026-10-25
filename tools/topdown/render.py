import sys, math
from PIL import Image, ImageDraw, ImageFont
src, out = sys.argv[1], sys.argv[2]
EXT = float(sys.argv[3]) if len(sys.argv) > 3 else 330
cx = float(sys.argv[4]) if len(sys.argv) > 4 else 0
cz = float(sys.argv[5]) if len(sys.argv) > 5 else 0
S = float(sys.argv[6]) if len(sys.argv) > 6 else 3.0  # px per stud
W = int(2 * EXT * S)
img = Image.new("RGB", (W, W), (92, 140, 70))
dr = ImageDraw.Draw(img, "RGBA")
parts = []
for line in open(src, encoding="utf8"):
    if not line.startswith("P|"): continue
    name, shape, size, pos, rot, col, tr = line.rstrip("\n").split("|")[1:8]
    sx, sy, sz = map(float, size.split(",")); px, py, pz = map(float, pos.split(","))
    r = list(map(float, rot.split(","))); c = tuple(int(float(v) * 255) for v in col.split(",")); t = float(tr)
    if t >= 0.98: continue
    if abs(px - cx) > EXT + 60 or abs(pz - cz) > EXT + 60: continue
    parts.append((py + sy / 2 * abs(r[4]) + sx / 2 * abs(r[3]) + sz / 2 * abs(r[5]), name, shape, (sx, sy, sz), (px, py, pz), r, c, t))
parts.sort(key=lambda p: p[0])
def to_px(x, z): return ((x - cx + EXT) * S, (z - cz + EXT) * S)
def hull(pts):
    pts = sorted(set(pts))
    if len(pts) < 3: return pts
    def cross(o, a, b): return (a[0]-o[0])*(b[1]-o[1]) - (a[1]-o[1])*(b[0]-o[0])
    lo, up = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0: lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(up) >= 2 and cross(up[-2], up[-1], p) <= 0: up.pop()
        up.append(p)
    return lo[:-1] + up[:-1]
for top, name, shape, (sx, sy, sz), (px, py, pz), r, c, t in parts:
    alpha = int(255 * (1 - t))
    fill = c + (alpha,)
    if "Ball" in shape:
        rad = sx / 2; x, y = to_px(px, pz)
        dr.ellipse([x - rad * S, y - rad * S, x + rad * S, y + rad * S], fill=fill)
        continue
    if "Cylinder" in shape:
        # Achse = lokale X; senkrecht stehend => Kreis mit Durchmesser sy
        ax = (r[0], r[3], r[6])
        if abs(ax[1]) > 0.9:
            rad = min(sy, sz) / 2; x, y = to_px(px, pz)
            dr.ellipse([x - rad * S, y - rad * S, x + rad * S, y + rad * S], fill=fill)
            continue
    pts = []
    for dx in (-sx / 2, sx / 2):
        for dy in (-sy / 2, sy / 2):
            for dz in (-sz / 2, sz / 2):
                wx = px + r[0] * dx + r[1] * dy + r[2] * dz
                wz = pz + r[6] * dx + r[7] * dy + r[8] * dz
                pts.append((round(wx, 2), round(wz, 2)))
    h = hull(pts)
    if len(h) >= 3:
        dr.polygon([to_px(*p) for p in h], fill=fill)
# Maßstab
dr.line([to_px(cx - EXT + 20, cz + EXT - 20), to_px(cx - EXT + 120, cz + EXT - 20)], fill=(255, 255, 255, 255), width=4)
dr.text(to_px(cx - EXT + 20, cz + EXT - 34), "100 Studs", fill=(255, 255, 255, 255))
img.save(out)
print("parts", len(parts), "->", out)
