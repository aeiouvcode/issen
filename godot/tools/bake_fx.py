"""Bake VFX + HUD textures: slash curtains, ink blots, grass clumps, scroll plaque, paper."""
import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from brush import Canvas, _fbm
OUT = '../art'
rng = np.random.default_rng(7)

def save_ink(a, path, rgb=(20, 17, 15)):
    a = np.clip(a, 0, 1)
    im = np.zeros(a.shape + (4,), np.uint8); im[..., 0], im[..., 1], im[..., 2] = rgb
    im[..., 3] = (a * 255).astype(np.uint8)
    Image.fromarray(im, 'RGBA').quantize(colors=128, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(path, optimize=True)

def slash(path, seed, W=1024, H=512):
    r_ = np.random.default_rng(seed)
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    cx, cy = W * 0.5, H * 1.02
    dx, dy = x - cx, cy - y
    r = np.hypot(dx, dy) / (H * 0.98); th = np.arctan2(dx, dy)  # th: -pi/2..pi/2 left->right
    t = (th + 1.35) / 2.7  # 0 trailing (left) -> 1 leading (right)
    r0, r1 = 0.52, 0.97
    band = np.clip((r - r0) / (r1 - r0), 0, 1)
    inb = (r > r0) & (r < r1) & (t > 0) & (t < 1)
    # fibers: vary across radius, smooth along arc
    prof = np.repeat(r_.random(96), 1).astype(np.float32)
    prof = np.convolve(prof, np.ones(2) / 2, 'same')
    idx = np.clip((band * 95).astype(int), 0, 95)
    fib = prof[idx] * 0.7 + 0.3 * _fbm(H, W, r_, 3, 10)
    # break fibers along the arc too
    along = _fbm(H, W, r_, 3, 5)
    fib = fib * (0.65 + 0.7 * along)
    # trailing dry-out: fibers drop out progressively toward the tail
    dry = np.clip((t - 0.02) / 0.55, 0, 1)
    thresh = 0.85 - dry * 0.75
    dens = np.clip((fib - thresh) * 2.2, 0, 1) * 0.62 + 0.12 * (1 - dry) * inb
    # outer edge dark wet rim, inner edge soft
    rim = np.exp(-((band - 0.93) / 0.05) ** 2) * 0.9 * np.clip(t * 1.6, 0, 1)
    inner = np.clip(band / 0.25, 0, 1)
    lead = np.clip((1 - t) / 0.06, 0, 1)
    a = np.clip((dens * inner + rim) * lead, 0, 1) * inb
    # ragged outer contour
    a *= (r < r1 - 0.03 * _fbm(H, W, r_, 3, 24))
    img = Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    save_ink(np.asarray(img, np.float32) / 255, path)

def blots():
    for i in range(6):
        c = Canvas(128, 2, seed=300 + i)
        if i < 3:
            c.dab(64, 64, 26 + i * 4, ink=0.95, rag=0.3, n=20)
            c.splatter(64, 64, 22, 10, 6)
        else:
            c.splatter(64, 64, 18, 16, 8)
        img = c.render(); img.save(f'{OUT}/blot{i}.png', optimize=True)

def grass():
    for i in range(3):
        c = Canvas(256, 2, seed=400 + i)
        for k in range(46):
            x = c.rng.uniform(10, 246); base = 250 - c.rng.uniform(0, 20)
            hgt = c.rng.uniform(40, 150) * (1 - abs(x - 128) / 170)
            lean = c.rng.normal(4, 6)
            c.stroke([(x, base), (x + lean * 0.5, base - hgt * 0.5), (x + lean, base - hgt)], w=c.rng.uniform(2.5, 5), ink=c.rng.uniform(0.35, 0.8), dry=0.7, taper=(0.05, 0.7))
        # soft ground wash at base
        img = c.render()
        a = np.asarray(img, np.float32)
        yy = np.linspace(0, 1, 256)[:, None]
        a[..., 3] *= np.clip(0.4 + yy * 0.9, 0, 1)
        Image.fromarray(a.astype(np.uint8), 'RGBA').save(f'{OUT}/grass{i}.png', optimize=True)

def footprint():
    c = Canvas(64, 2, seed=500)
    c.dab(32, 34, 13, ink=0.9, rag=0.25, n=16); c.splatter(32, 34, 8, 5, 3)
    c.render().save(f'{OUT}/dab.png', optimize=True)

def plaque():
    W, H = 360, 128
    r_ = np.random.default_rng(9)
    n = _fbm(H, W, r_, 4, 6)
    base = np.array([214, 190, 150], np.float32)
    rgb = base[None, None, :] * (0.88 + 0.2 * n[..., None])
    a = np.zeros((H, W), np.float32)
    im = Image.new('L', (W, H), 0); d = ImageDraw.Draw(im)
    # ragged bottom edge body + rolled right end
    pts = [(0, 14), (300, 10), (300, 112)] + [(x, 114 + r_.normal(0, 2) + (4 if (x // 9) % 2 else 0)) for x in range(300, -1, -9)]
    d.polygon(pts, fill=255)
    d.rounded_rectangle((292, 2, 330, 124), radius=16, fill=255)
    a = np.asarray(im, np.float32) / 255
    edge = a - np.asarray(im.filter(ImageFilter.GaussianBlur(5)), np.float32) / 255
    rgb = rgb * (1 - np.clip(edge, 0, 1)[..., None] * 0.9)
    # roll shading
    x = np.arange(W)[None, :]
    roll = ((x >= 292) & (x <= 330)).astype(np.float32) * (0.75 + 0.25 * np.cos((x - 311) / 19 * 1.3))
    rgb = rgb * np.where(roll > 0, roll, 1)[..., None]
    rgb[:, 292:294] *= 0.45; rgb[:, 329:331] *= 0.5
    out = np.dstack([np.clip(rgb, 0, 255), a * 255]).astype(np.uint8)
    Image.fromarray(out, 'RGBA').save(f'{OUT}/plaque.png', optimize=True)

def icon_ring():
    c = Canvas(96, 2, seed=600)
    pts = [(48 + 34 * math.cos(t), 48 + 34 * math.sin(t)) for t in np.linspace(-1.9, 4.3, 30)]
    c.stroke(pts, w=5, dry=0.4, taper=(0.05, 0.3))
    c.render().save(f'{OUT}/ring.png', optimize=True)

def barstroke():
    c = Canvas(512, 2, seed=700)
    c.stroke([(10, 256), (180, 253), (340, 257), (502, 255)], w=16, dry=0.35, taper=(0.03, 0.08))
    img = c.render().crop((0, 226, 512, 286)); img.save(f'{OUT}/bar.png', optimize=True)

if __name__ == '__main__':
    import os; os.makedirs(OUT, exist_ok=True)
    slash(f'{OUT}/slash0.png', 1); slash(f'{OUT}/slash1.png', 2)
    blots(); grass(); footprint(); plaque(); icon_ring(); barstroke()
    print('fx ok')
