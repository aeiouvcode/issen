"""Store listing art (Play: 512 icon, 1024x500 feature graphic) composed from the baked game art.
Deterministic. Usage: python3 bake_store.py  -> ../store/"""
import json, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ART = os.path.join(os.path.dirname(__file__), "..", "art")
OUT = os.path.join(os.path.dirname(__file__), "..", "store")
rng = np.random.default_rng(23)

def parchment(w, h):
    base = np.array([228, 214, 184], np.float32)
    n = rng.normal(0, 1, (h // 8 + 2, w // 8 + 2)).astype(np.float32)
    n = np.array(Image.fromarray(((n - n.min()) / (np.ptp(n)) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), np.float32) / 255 - 0.5
    img = base[None, None, :] + n[..., None] * 22 + rng.normal(0, 4, (h, w, 1))
    # stipple flecks
    for _ in range(w * h // 900):
        x, y = rng.integers(0, w), rng.integers(0, h)
        img[y:y + 2, x:x + 2] *= 0.72
    # ink-wash vignette
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    img *= (1 - np.clip(d - 0.55, 0, 1) ** 1.6 * 0.55)[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).convert("RGBA")

def frame(kind, anim, i):
    m = json.load(open(os.path.join(ART, kind + ".json")))
    a = m["anims"][anim]; f = m["frame"]
    page = Image.open(os.path.join(ART, "%s_p%d.png" % (kind, a.get("page", 0)))).convert("RGBA")
    col = a.get("col0", 0) + i
    return page.crop((col * f, a["row"] * f, col * f + f, a["row"] * f + f))

def tinted(path, rgb, alpha=1.0):
    im = Image.open(os.path.join(ART, path)).convert("RGBA")
    arr = np.array(im, np.float32)
    if arr[..., 3].max() == 0:
        arr[..., 3] = 255 - arr[..., :3].mean(-1)
    arr[..., :3] = rgb
    arr[..., 3] *= alpha
    return Image.fromarray(arr.astype(np.uint8))

def slash_layer(size, alpha):
    s = Image.open(os.path.join(ART, "slash0.png")).convert("LA").convert("RGBA")
    arr = np.array(s, np.float32)
    lum = arr[..., 0:1]
    arr[..., :3] = lum * 0.55 + 20
    arr[..., 3] *= alpha
    return Image.fromarray(arr.astype(np.uint8)).resize(size, Image.LANCZOS)

def blots(img, cx, cy, n, spread, rmax, red=False):
    d = ImageDraw.Draw(img)
    for _ in range(n):
        r = abs(rng.normal(0, spread))
        a = rng.uniform(0, 6.283)
        x, y = cx + np.cos(a) * r, cy + np.sin(a) * r * 0.7
        rr = max(1.0, rmax * np.exp(-r / spread) * rng.uniform(0.3, 1.0))
        col = (150, 20, 16, 235) if red and rng.random() < 0.35 else (22, 18, 16, 235)
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=col)

def seal(img, x, y, s, text=None):
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((x, y, x + s, y + s), radius=s * 0.12, fill=(160, 24, 20, 235))
    d.rounded_rectangle((x + s * 0.12, y + s * 0.12, x + s * 0.88, y + s * 0.88), radius=s * 0.08, outline=(236, 220, 196, 230), width=max(2, int(s * 0.05)))
    if text:
        f = ImageFont.truetype(os.path.join(ART, "brush.ttf"), int(s * 0.46))
        d.text((x + s / 2, y + s / 2), text, font=f, fill=(236, 220, 196, 240), anchor="mm")

def icon():
    W = 512
    im = parchment(W, W)
    im.alpha_composite(slash_layer((W + 160, (W + 160) // 2), 0.9).rotate(28, resample=Image.BICUBIC, expand=False), (-110, 70))
    p = frame("player", "atk3", 3).resize((440, 440), Image.LANCZOS)
    im.alpha_composite(p, (22, 60))
    blots(im, 360, 250, 70, 40, 9, red=True)
    seal(im, 392, 34, 86, "I")
    im = im.convert("RGB")
    im.save(os.path.join(OUT, "icon-512.png"))

def feature():
    W, H = 1024, 500
    im = parchment(W, H)
    # grass swaths along the ground line
    for i in range(3):
        g = Image.open(os.path.join(ART, "grass%d.png" % i)).convert("RGBA")
        g = g.resize((int(g.width * 0.5), int(g.height * 0.5)))
        for x in range(340, W, 80):
            im.alpha_composite(g, (x + int(rng.integers(-30, 30)), 380 - g.height + 40 + i * 12))
    im.alpha_composite(slash_layer((760, 380), 0.85).rotate(-10, resample=Image.BICUBIC), (300, 30))
    p = frame("player", "atk2", 3).resize((400, 400), Image.LANCZOS)
    r = frame("ronin", "hit", 1).resize((420, 420), Image.LANCZOS).transpose(Image.FLIP_LEFT_RIGHT)
    im.alpha_composite(r, (600, 70))
    im.alpha_composite(p, (380, 80))
    blots(im, 700, 250, 140, 55, 10, red=True)
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(os.path.join(ART, "brush.ttf"), 132)
    f2 = ImageFont.truetype(os.path.join(ART, "brush.ttf"), 34)
    d.text((70, 120), "ISSEN", font=f, fill=(24, 20, 17))
    d.text((76, 270), "one cut, a thousand layers", font=f2, fill=(60, 50, 42))
    seal(im, 392, 196, 50, "I")
    im.convert("RGB").save(os.path.join(OUT, "feature-1024x500.jpg"), quality=90)

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    icon(); feature()
