"""Bake VFX + HUD textures: slash curtains, ink blots, grass clumps, scroll plaque, paper."""
import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
from brush import Canvas, _fbm
OUT = '../art'
rng = np.random.default_rng(7)

def save_ink(a, path, rgb=(20, 17, 15), colors=128):
    """Single ink colour, so only alpha carries information: save as grey+alpha (LA) to keep
    all 256 alpha levels (RGBA octree quantizing collapsed them to ~8 bands)."""
    a = np.clip(a, 0, 1)
    im = np.zeros(a.shape + (2,), np.uint8); im[..., 0] = int(sum(rgb) / 3)
    im[..., 1] = (a * 255).astype(np.uint8)
    Image.fromarray(im, 'LA').save(path, optimize=True)

def slash(path, seed, W=1024, H=512):
    r_ = np.random.default_rng(seed)
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    cx, cy = W * 0.5, H * 1.02
    dx, dy = x - cx, cy - y
    r = np.hypot(dx, dy) / (H * 0.98); th = np.arctan2(dx, dy)  # th: -pi/2..pi/2 left->right
    t = (th + 1.35) / 2.7  # 0 trailing (left) -> 1 leading (right)
    # C59 (audit gap 1): MULTI-BAND parallel bristle sweep - the sibling reference's
    # slash reads as 3-5 parallel dry-brush tracks spanning the screen, not one curtain.
    # broad faint wash sweeping wider than the ink bands - the layered grey under-stroke
    w0, w1 = 0.26, 1.02
    inw = (r > w0) & (r < w1 - 0.02 * _fbm(H, W, r_, 2, 16)) & (t > 0.02) & (t < 1)
    wash = inw.astype(np.float32) * 0.15 * (0.45 + 0.55 * _fbm(H, W, r_, 3, 7)) * np.clip(t * 2.0, 0, 1)
    # four parallel strands spread across a wide radial span; outer strands lead more
    nst = 4
    rcs = np.linspace(0.40, 0.94, nst)
    hws = np.linspace(0.075, 0.055, nst)          # inner strands a touch broader
    tlead = np.linspace(0.0, 0.10, nst)           # outer strands sweep slightly ahead
    a_ink = np.zeros((H, W), np.float32)
    for k in range(nst):
        rc, hw = rcs[k], hws[k]
        tk = np.clip(t - tlead[k] * (1.0 - t), 0, 1)  # strand-local sweep param
        d = np.clip(1.0 - np.abs(r - rc) / hw, 0, 1)  # 1 at strand centre
        instr = (d > 0) & (tk > 0) & (tk < 1)
        # C59: streaky bristle noise in (t,d) param space - along-arc dry gaps kill
        # the concentric-ring read (pixel-space noise is isotropic, rings follow the arc)
        def _streak(nu, nv):
            g = r_.random((nv + 1, nu + 1)).astype(np.float32)
            fu = np.clip(tk * nu, 0, nu - 1e-6); fv = np.clip(d * nv, 0, nv - 1e-6)
            iu = fu.astype(int); iv = fv.astype(int)
            du = fu - iu; dv = fv - iv
            return (g[iv, iu] * (1 - du) * (1 - dv) + g[iv, iu + 1] * du * (1 - dv)
                    + g[iv + 1, iu] * (1 - du) * dv + g[iv + 1, iu + 1] * du * dv)
        _nu = 48 + k * 26  # outer strands get finer along-arc cells (constant px size)
        streak = 0.6 * _streak(_nu, 3) + 0.4 * _streak(_nu * 2 + 14, 7)
        fib = 0.5 + 0.5 * _fbm(H, W, r_, 3, 6)
        fib = fib * (0.25 + 1.35 * streak)
        along = _fbm(H, W, r_, 3, 5)
        # bold dense body over the leading two-thirds of each strand
        body_t = np.clip((tk - 0.30) / 0.25, 0, 1)
        dens_body = np.clip((fib - 0.47) * 2.2, 0, 1) * (0.35 + 0.65 * body_t)
        # tail frays into discrete dry-brush bristlelets that separate as tk -> 0
        nb = 9
        sidx = np.clip((d * nb).astype(int), 0, nb - 1)
        sgap = (d * nb) % 1.0
        sphase = r_.random(nb).astype(np.float32)[sidx]
        sharp = 1.0 - np.abs(sgap - 0.5) * 2.0
        split = np.clip((0.45 - tk) / 0.3, 0, 1)
        gapmask = np.clip((sharp - (1.0 - split)) * 3.0, 0, 1)
        tail_dry = np.clip(tk / 0.28, 0, 1) ** 1.2
        dens_tail = gapmask * (0.5 + 0.5 * sphase) * tail_dry * (0.6 + 0.4 * along) * 0.7
        dens = np.clip(dens_body + dens_tail * (1.0 - 0.4 * body_t), 0, 1)
        # wet dark rim on each strand's outer edge, soft inner edge
        rim = np.exp(-((d - 0.85) / 0.10) ** 2) * 0.85 * np.clip(tk * 1.6, 0, 1)
        inner = np.clip(d / 0.25, 0, 1)
        lead = np.clip((1 - tk) / 0.06, 0, 1)
        a_k = np.clip((dens * inner + rim) * lead, 0, 1) * instr
        # ragged strand contour
        a_k *= (d > 0.02 * _fbm(H, W, r_, 3, 24))
        # C67: outward dry-brush rays past each strand's outer edge - the reference's
        # band edges fray into long separated bristles, not a compact contour
        so = (r - rc) / hw                    # signed: +1 at outer edge
        dist = so - 1.0                       # past the edge
        nray = 110
        rt = tk * nray
        ridx = np.clip(rt.astype(int), 0, nray - 1)
        rph0 = r_.random(nray).astype(np.float32)
        rph1 = r_.random(nray).astype(np.float32)
        rph2 = r_.random(nray).astype(np.float32)
        rphase = rph0[ridx]; rwid = rph1[ridx]; rint = rph2[ridx]
        reach = 0.5 + 2.4 * rphase            # each ray frays a different distance
        ray = np.clip(1.0 - dist / np.maximum(reach, 1e-3), 0, 1) * (dist > 0)
        ray = ray ** 1.7                      # taper along the ray
        # thin lateral profile: only a narrow centre of each cell carries the ray
        lat = np.abs((rt - ridx) - (0.25 + 0.5 * rwid))
        ray *= np.clip(1.0 - lat / 0.22, 0, 1)
        ray *= (rphase > 0.42)                # sparse: most cells carry no ray
        ray *= (0.35 + 0.65 * rint)           # varied darkness
        ray *= np.clip((along - 0.30) * 2.2, 0, 1)  # organic grouping along the arc
        a_k = np.clip(a_k + ray * 0.9 * np.clip(tk * 2.0, 0, 1), 0, 1)
        a_ink = np.maximum(a_ink, a_k)
    a = np.clip(a_ink + wash, 0, 1)
    # C59: fade the top edge - at 3.1x scale the quad's top rim crosses the wash
    # band (r~1.04 at top-centre) and a hard rectangular cut shows in-game
    a *= np.clip(y / (0.12 * H), 0, 1)
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

def drips():
    """Flying-ink streaks: a wet head (right) trailing a thin dry tail (left)."""
    for i in range(3):
        c = Canvas(128, 2, seed=800 + i)
        L = 70 + i * 18; y0 = 64 + c.rng.normal(0, 1)
        pts = [(118 - L + k * L / 6, y0 + c.rng.normal(0, 0.6) + (k - 6) ** 2 * 0.05) for k in range(7)]
        c.stroke(pts, w=3.2 + i * 0.6, dry=0.55, taper=(0.9, 0.02), ink=0.95)
        c.dab(116, y0, 4.2 + i * 0.8, ink=0.97, rag=0.25)
        for _ in range(3):
            c.dab(118 - L * c.rng.uniform(0.2, 0.9), y0 + c.rng.normal(0, 3), c.rng.uniform(0.6, 1.3), ink=0.9)
        c.render().crop((0, 40, 128, 88)).save(f'{OUT}/drip{i}.png', optimize=True)
    for i in range(3):
        c = Canvas(32, 2, seed=820 + i)
        c.dab(16, 16, 3.0 + i * 1.3, ink=0.97, rag=0.4)
        if i == 2: c.dab(22, 19, 1.4, ink=0.95)
        c.render().save(f'{OUT}/speck{i}.png', optimize=True)

def grass():
    """Grass swath clumps: many thin dry-brush fibres, dense and dark at the root,
    thinning to pale hairline tips (reference grass reads as grey fibre, not hedge)."""
    for i in range(3):
        c = Canvas(256, 2, seed=400 + i)
        for k in range(150):
            x = c.rng.uniform(6, 250); base = 252 - c.rng.uniform(0, 14)
            hgt = c.rng.uniform(35, 175) * (1 - abs(x - 128) / 150) ** 0.7
            if hgt < 12: continue
            lean = c.rng.normal(5, 7)
            c.stroke([(x, base), (x + lean * 0.35, base - hgt * 0.5), (x + lean, base - hgt)], w=c.rng.uniform(0.9, 2.1), ink=c.rng.uniform(0.25, 0.65), dry=0.85, taper=(0.02, 0.85))
        for k in range(10):
            x = c.rng.uniform(30, 226)
            c.stroke([(x - 16, 250), (x + 16, 249)], w=2.4, ink=0.35, dry=0.8, taper=(0.3, 0.3))
        img = c.render()
        a = np.asarray(img, np.float32)
        yy = np.linspace(0, 1, 256)[:, None]
        a[..., 3] *= np.clip(0.35 + yy * 0.8, 0, 1)
        Image.fromarray(a.astype(np.uint8), 'RGBA').quantize(colors=128, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(f'{OUT}/grass{i}.png', optimize=True)

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

def skill_icons():
    """Inked glyphs for the skill rings / touch buttons: cut, evade, burst."""
    c = Canvas(96, 2, seed=900)                       # cut: one diagonal stroke with a dry tail
    c.stroke([(22, 74), (46, 50), (76, 20)], w=7, dry=0.5, taper=(0.1, 0.8))
    c.dab(24, 72, 4.5, ink=0.95)
    c.render().save(f'{OUT}/icon_cut.png', optimize=True)
    c = Canvas(96, 2, seed=901)                       # evade: a comma swirl
    pts = [(48 + (30 - t * 3.2) * math.cos(t * 1.1 - 1.0), 48 + (30 - t * 3.2) * math.sin(t * 1.1 - 1.0)) for t in np.linspace(0, 6.2, 28)]
    c.stroke(pts, w=6, dry=0.55, taper=(0.05, 0.9))
    c.render().save(f'{OUT}/icon_evade.png', optimize=True)
    c = Canvas(96, 2, seed=902)                       # burst: blot with splatter
    c.dab(48, 48, 19, ink=0.95, rag=0.45)
    c.splatter(48, 48, 22, 18, 5)
    c.render().save(f'{OUT}/icon_burst.png', optimize=True)

def cloud():
    """Dash puff: a pale wash cloud with a lumpy dry-brush outline (reference dash smoke)."""
    c = Canvas(256, 2, seed=950)
    lumps = [(80, 150, 46), (128, 120, 56), (178, 146, 48), (110, 168, 40), (156, 172, 38)]
    for (x, y, r) in lumps:
        c.wash([(x + math.cos(t) * r, y + math.sin(t) * r * 0.8) for t in np.linspace(0, 2 * math.pi, 20, endpoint=False)], dens=0.12, edge=0.2, layer='fill', rag=1.0)
    # outer contour only: each top lump inks the arc facing away from the cloud centre
    for (x, y, r), (a0, a1) in zip(lumps[:3], ((0.75, 1.55), (1.2, 1.85), (1.45, 2.3))):
        pts = [(x + math.cos(t) * r, y + math.sin(t) * r * 0.8) for t in np.linspace(math.pi * a0, math.pi * a1, 14)]
        c.stroke(pts, w=3.4, dry=0.6, taper=(0.1, 0.5), ink=0.85)
    c.stroke([(40, 186), (120, 196), (216, 186)], w=3.0, dry=0.7, taper=(0.2, 0.4), ink=0.8)
    c.render().save(f'{OUT}/cloud.png', optimize=True)

def redblot():
    """Red ink blot for hit marks (baked in red so modulate isn't multiplying black ink)."""
    c = Canvas(128, 2, seed=960)
    for k in range(7):
        x, y = 64 + c.rng.normal(0, 10), 64 + c.rng.normal(0, 8); r = c.rng.uniform(8, 20) if k == 0 else c.rng.uniform(3, 9)
        if k == 0: r = 22
        c.wash([(x + math.cos(t) * r * (1 + 0.25 * math.cos(3 * t + k)), y + math.sin(t) * r) for t in np.linspace(0, 2 * math.pi, 22, endpoint=False)], dens=0.95, edge=0.3, layer='red', rag=1.4)
    for k in range(14):
        a = c.rng.uniform(0, 2 * math.pi); d = c.rng.uniform(26, 44); r = c.rng.uniform(1.2, 3.5)
        x, y = 64 + math.cos(a) * d, 64 + math.sin(a) * d * 0.8
        c.wash([(x + math.cos(t) * r, y + math.sin(t) * r) for t in np.linspace(0, 2 * math.pi, 10, endpoint=False)], dens=0.95, edge=0.2, layer='red', rag=0.4)
    c.render().save(f'{OUT}/redblot.png', optimize=True)

def barstroke():
    c = Canvas(512, 2, seed=700)
    c.stroke([(10, 256), (180, 253), (340, 257), (502, 255)], w=16, dry=0.35, taper=(0.03, 0.08))
    img = c.render().crop((0, 226, 512, 286)); img.save(f'{OUT}/bar.png', optimize=True)

if __name__ == '__main__':
    import os; os.makedirs(OUT, exist_ok=True)
    slash(f'{OUT}/slash0.png', 1); slash(f'{OUT}/slash1.png', 2)
    blots(); drips(); grass(); footprint(); plaque(); icon_ring(); skill_icons(); cloud(); redblot(); barstroke()
    print('fx ok')
