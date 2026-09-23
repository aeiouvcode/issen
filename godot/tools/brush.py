"""Brush renderer: dry-brush bristle strokes and wet washes, rendered at 2x then downsampled.
Used offline to bake sprite sheets. Deterministic per seed."""
import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter

def _fbm(h, w, rng, octaves=4, base=8):
    out = np.zeros((h, w), np.float32); amp = 1.0; tot = 0
    for o in range(octaves):
        n = base * (2 ** o)
        g = rng.random((n + 1, n + 1)).astype(np.float32)
        img = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        out += amp * (np.asarray(img, np.float32) / 255.0); tot += amp; amp *= 0.5
    return out / tot

class Canvas:
    """Ink layer (density 0..1), light fill layer (opaque paper-white body), red layer."""
    def __init__(self, size=256, ss=2, seed=0):
        self.S = size * ss; self.ss = ss; self.size = size
        self.rng = np.random.default_rng(seed)
        self.ink = np.zeros((self.S, self.S), np.float32)
        self.fill = np.zeros((self.S, self.S), np.float32)
        self.fillshade = np.zeros((self.S, self.S), np.float32)
        self.red = np.zeros((self.S, self.S), np.float32)
        self.noise = _fbm(self.S, self.S, self.rng, 5, 6)
        self.grain = _fbm(self.S, self.S, self.rng, 3, 64)
        # streak noise: stretched along one axis for dry-brush texture
        st = self.rng.random((self.S // 16, self.S)).astype(np.float32)
        self.streak = np.asarray(Image.fromarray((st * 255).astype(np.uint8)).resize((self.S, self.S), Image.BILINEAR), np.float32) / 255

    def _mask(self, poly):
        im = Image.new('L', (self.S, self.S), 0)
        ImageDraw.Draw(im).polygon([(x * self.ss, y * self.ss) for x, y in poly], fill=255)
        return np.asarray(im, np.float32) / 255

    def _jitter(self, poly, amt=1.5):
        # ragged polygon edge: subdivide and displace
        out = []
        n = len(poly)
        for i in range(n):
            a = np.array(poly[i], float); b = np.array(poly[(i + 1) % n], float)
            L = np.linalg.norm(b - a); k = max(1, int(L / 4))
            for j in range(k):
                p = a + (b - a) * (j / k)
                out.append((p[0] + self.rng.normal(0, amt), p[1] + self.rng.normal(0, amt)))
        return out

    def wash(self, poly, dens=0.5, edge=0.35, rag=1.6, texture=0.45, layer='ink', streak_dir=None):
        m = self._mask(self._jitter(poly, rag))
        if m.max() == 0: return
        blur = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3 * self.ss)), np.float32) / 255
        rim = np.clip(m - blur, 0, 1) * 2.2  # wet-edge darkening
        tex = 1 - texture + texture * (self.noise * 0.6 + self.grain * 0.4) * 1.4
        if streak_dir is not None:
            tex = tex * (0.75 + 0.5 * self.streak)
        d = np.clip(m * (dens * tex + edge * rim), 0, 1)
        if layer == 'ink':
            self.ink = 1 - (1 - self.ink) * (1 - d)
        elif layer == 'red':
            self.red = np.maximum(self.red, d)
        elif layer == 'fill':
            self.fill = np.maximum(self.fill, m)
            self.ink *= (1 - m)  # light fill covers ink below it
            self.red *= (1 - m)
            self.fillshade = self.fillshade * (1 - m) + m * np.clip(dens * tex + edge * rim * 0.6, 0, 1)

    def stroke(self, pts, w=6, ink=0.95, dry=0.45, taper=(0.15, 0.35), layer='ink', press=1.0):
        """Bristle stroke along polyline pts (canvas px). dry = how much the brush runs out."""
        P = np.array(pts, float) * self.ss
        if len(P) < 2: return
        # resample (catmull-rom-ish via linear with fine step)
        seg = np.linalg.norm(np.diff(P, axis=0), axis=1); L = seg.sum()
        if L < 1: return
        n = max(4, int(L / 1.2))
        cum = np.concatenate([[0], np.cumsum(seg)])
        ts = np.linspace(0, L, n)
        xs = np.interp(ts, cum, P[:, 0]); ys = np.interp(ts, cum, P[:, 1])
        dx = np.gradient(xs); dy = np.gradient(ys); nl = np.hypot(dx, dy) + 1e-6
        nx, ny = -dy / nl, dx / nl
        W = w * self.ss * 1.45
        nb = int(np.clip(W / 1.6, 3, 28))
        off = np.sort(self.rng.uniform(-1, 1, nb))
        load = self.rng.uniform(0.55, 1.0, nb)
        phase = self.rng.uniform(0, 100, nb)
        freq = self.rng.uniform(0.02, 0.07, nb)
        im = Image.new('L', (self.S, self.S), 0); dr = ImageDraw.Draw(im)
        r = max(0.9, W / nb * 0.95)
        for i in range(n):
            t = i / (n - 1)
            prof = min(1, t / max(taper[0], 1e-3)) if taper[0] > 0 else 1
            if t > 1 - taper[1]: prof *= max(0.12, 1 - (t - (1 - taper[1])) / taper[1] * 0.88)
            prof = prof ** 0.7 * press
            half = W * 0.5 * prof
            for b in range(nb):
                # bristle runs dry toward tail; noise gaps
                gate = load[b] - dry * t * 1.2 + 0.35 * math.sin(phase[b] + i * freq[b] * 6) * dry
                if gate < 0.18: continue
                v = int(255 * ink * min(1, 0.55 + gate))
                cx = xs[i] + nx[i] * off[b] * half; cy = ys[i] + ny[i] * off[b] * half
                rr = r * (0.6 + 0.4 * prof)
                dr.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=v)
        d = np.asarray(im, np.float32) / 255
        if layer == 'ink':
            self.ink = 1 - (1 - self.ink) * (1 - d)
        elif layer == 'red':
            self.red = np.maximum(self.red, d)

    def dab(self, x, y, r, ink=0.9, rag=0.35, n=None):
        """Irregular blot."""
        n = max(n or 24, 24)
        ang = np.linspace(0, 2 * math.pi, n, endpoint=False)
        rs = np.full(n, float(r))
        for k in (2, 3, 5):
            rs += r * rag * 0.5 / k * 2 * np.cos(k * ang + self.rng.uniform(0, 6.28))
        poly = [(x + math.cos(a) * q, y + math.sin(a) * q) for a, q in zip(ang, rs)]
        self.wash(poly, dens=ink, edge=0.25, rag=min(1.2, r * 0.06), texture=0.25)

    def splatter(self, x, y, spread, count, rmax, ink=0.9):
        for _ in range(count):
            a = self.rng.uniform(0, 2 * math.pi); d = abs(self.rng.normal(0, spread))
            self.dab(x + math.cos(a) * d, y + math.sin(a) * d * 0.8, self.rng.uniform(0.6, rmax) * max(0.3, 1 - d / (spread * 3)), ink)

    def render(self, ink_rgb=(22, 18, 16), fill_rgb=(236, 228, 212), shade_rgb=(150, 142, 132), red_rgb=(176, 22, 26)):
        f = self.fill[..., None]; sh = self.fillshade[..., None]
        base = np.array(fill_rgb, np.float32) * (1 - sh) + np.array(shade_rgb, np.float32) * sh
        ink = self.ink[..., None]; red = self.red[..., None]
        rgb = base * f
        a = f[..., 0].copy()
        # red over fill
        rgb = rgb * (1 - red) + np.array(red_rgb, np.float32) * red
        a = 1 - (1 - a) * (1 - red[..., 0])
        rgbp = np.where(a[..., None] > 0, rgb / np.maximum(a[..., None], 1e-4), 0)
        # ink on top
        rgbo = rgbp * (1 - ink) * a[..., None] + np.array(ink_rgb, np.float32) * ink
        ao = 1 - (1 - a) * (1 - ink[..., 0])
        rgbo = np.where(ao[..., None] > 0, rgbo / np.maximum(ao[..., None], 1e-4), 0)
        out = np.dstack([np.clip(rgbo, 0, 255), np.clip(ao * 255, 0, 255)]).astype(np.uint8)
        # premultiplied downsample to avoid dark fringes
        im = Image.fromarray(out, 'RGBA')
        return im.resize((self.size, self.size), Image.LANCZOS)
