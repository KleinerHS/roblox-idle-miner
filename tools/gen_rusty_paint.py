# Erzeugt die kachelbare Lacktextur für das rostige Startauto (Pickup, D-054).
# Cremeweißer Altlack, an Stellen abgeplatzt (Rost/blankes Metall darunter), Schmutz, Rostpunkte.
# Aufruf: python tools/gen_rusty_paint.py  ->  assets/textures/rusty_pickup_paint.png
# (Benötigt numpy + pillow. Die PNG wird in Roblox hochgeladen und als ColorMap der
# MaterialVariant "RustyPickupPaint" genutzt.)
import os
import numpy as np
from PIL import Image

N = 1024
rng = np.random.default_rng(54)


def fractal(power: float, seed: int) -> np.ndarray:
    """Periodisches (kachelbares) Rauschen über FFT, Werte 0..1."""
    r = np.random.default_rng(seed)
    fx = np.fft.fftfreq(N)[:, None]
    fy = np.fft.fftfreq(N)[None, :]
    f = np.sqrt(fx * fx + fy * fy)
    f[0, 0] = 1
    spec = (r.normal(size=(N, N)) + 1j * r.normal(size=(N, N))) / f ** power
    spec[0, 0] = 0
    img = np.real(np.fft.ifft2(spec))
    img -= img.min()
    return img / img.max()


def blur(a: np.ndarray, k: int) -> np.ndarray:
    out = a.copy()
    for axis in (0, 1):
        acc = np.zeros_like(out)
        for s in range(-k, k + 1):
            acc += np.roll(out, s, axis=axis)
        out = acc / (2 * k + 1)
    return out


big = fractal(1.6, 1)  # große Flecken
mid = fractal(1.5, 2)  # mittlere Struktur
fine = fractal(1.0, 3)  # Körnung
grime = fractal(1.7, 4)

# Abgeplatzte Bereiche: ca. 18 % der Fläche, ausgefranste Ränder
peel_field = 0.45 * big + 0.55 * mid
thr = np.quantile(peel_field, 0.84)
peel = peel_field > thr
# Rand um die Abplatzungen (dünner, hellerer Lackrand + dunkle Rostkante)
soft = blur(peel.astype(float), 3)
edge = (soft > 0.05) & (~peel)

# kleine Rostpunkte im Lack
dots = (fine > np.quantile(fine, 0.992)) & (big > 0.35)
dots = blur(dots.astype(float), 1) > 0.15

cream = np.array([226, 219, 196], float)
rust_dark = np.array([92, 52, 30], float)
rust_light = np.array([156, 92, 50], float)
metal = np.array([128, 124, 118], float)

t = (0.6 * mid + 0.4 * fine)[..., None]
rust = rust_dark * (1 - t) + rust_light * t
# etwas blankes Metall in den Abplatzungen
metal_mask = (fine > 0.62)[..., None]
under = np.where(metal_mask, metal * (0.85 + 0.3 * fine[..., None]), rust)

paint = cream * (0.9 + 0.12 * fine[..., None])
# Schmutz/Verblassen
paint = paint * (1 - 0.18 * np.clip(grime - 0.45, 0, 1)[..., None] * 2)
# leichte Rostschlieren unter den Abplatzungen (nach unten = +y)
streak = np.zeros((N, N))
src = soft.copy()
for i in range(1, 40):
    streak = np.maximum(streak, np.roll(src, i, axis=0) * (1 - i / 40))
streak = blur(streak, 1) * (0.4 + 0.6 * fine)
paint = paint * (1 - 0.35 * streak[..., None]) + rust_light * 0.35 * streak[..., None]

img = paint
img = np.where(dots[..., None], rust_dark * 1.1, img)
img = np.where(edge[..., None], rust_dark * 0.9 + 20, img)
img = np.where(peel[..., None], under, img)

os.makedirs("assets/textures", exist_ok=True)
Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save("assets/textures/rusty_pickup_paint.png")
print("ok", float(peel.mean()))
