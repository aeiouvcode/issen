"""Side-view rigs for the player (ink-haired swordswoman) and the kasa ronin.
Poses are keyframed angle sets; each baked frame gets its own brush seed so the
line 'boils' like hand-drawn animation."""
import math, numpy as np
from brush import Canvas

def V(a, L):
    r = math.radians(a); return np.array([math.sin(r) * L, math.cos(r) * L])

def lerp(a, b, t): return a + (b - a) * t

def lerp_pose(p, q, t):
    return {k: lerp(p.get(k, 0), q.get(k, 0), t) for k in set(p) | set(q)}

def fk(pose, dims):
    """Return joint dict in local coords (hip at origin), y down, facing +x."""
    J = {}
    hip = np.array([pose.get('dx', 0.0), 0.0])
    J['hip'] = hip
    lean = pose.get('lean', 0)
    J['neck'] = hip + np.array([math.sin(math.radians(lean)), -math.cos(math.radians(lean))]) * dims['torso']
    J['chest'] = lerp(hip, J['neck'], 0.62)
    ha = 180 - lean - pose.get('head', 0)
    J['head'] = J['neck'] + V(ha, dims['neck'] + dims['head'])
    sh_off = np.array([0, 0])
    J['sh'] = J['neck'] + V(180 - lean, -6)
    for side in ('f', 'b'):
        a1 = pose.get(side + 'a_sh', 0); a2 = a1 + pose.get(side + 'a_el', 0)
        J[side + '_el'] = J['sh'] + V(a1, dims['uarm'])
        J[side + '_hand'] = J[side + '_el'] + V(a2, dims['farm'])
        J[side + '_farm_a'] = a2
        l1 = pose.get(side + 'l_hip', 0); l2 = l1 + pose.get(side + 'l_knee', 0)
        J[side + '_knee'] = hip + V(l1, dims['thigh'])
        J[side + '_foot'] = J[side + '_knee'] + V(l2, dims['shin'])
        J[side + '_shin_a'] = l2
    return J

def place(J, pose, cx, ground):
    pts = [J[k] for k in ('f_foot', 'b_foot', 'f_knee', 'b_knee', 'head', 'f_hand', 'b_hand', 'hip')]
    low = max(p[1] for p in pts)
    off = np.array([cx, ground - low - pose.get('dy', 0)])
    return {k: (v + off if isinstance(v, np.ndarray) else v) for k, v in J.items()}

def perp(a, b):
    d = b - a; n = np.array([-d[1], d[0]]); return n / (np.linalg.norm(n) + 1e-6)

def quad(a, b, wa, wb):
    n = perp(a, b)
    return [tuple(a + n * wa), tuple(b + n * wb), tuple(b - n * wb), tuple(a - n * wa)]

def curve(a, b, bend):
    m = (a + b) / 2 + perp(a, b) * bend
    return [tuple(a), tuple((a + m) / 2 * 0.5 + m * 0.5), tuple(m), tuple((m + b) / 2 * 0.5 + m * 0.5), tuple(b)]

# ---------------------------------------------------------------- player
PDIM = dict(thigh=40, shin=40, torso=54, neck=6, head=16, uarm=28, farm=26, sword=100)

def draw_player(c, J, pose):
    rng = c.rng
    sword_a = J['f_farm_a'] + pose.get('sword', 0)
    # back sleeve + arm
    draw_sleeve(c, J['sh'], J['b_el'], J['b_hand'], 0.5)
    # back leg hakama
    draw_hakama_leg(c, J['hip'], J['b_knee'], J['b_foot'], shade=0.7)
    # torso kimono
    n = perp(J['hip'], J['neck'])
    hipL = J['hip'] + n * 15; hipR = J['hip'] - n * 15
    shL = J['sh'] + n * 13; shR = J['sh'] - n * 13
    body = [tuple(shL), tuple(J['neck'] + n * 4), tuple(shR), tuple(hipR + (hipR - shR) * 0.1), tuple(hipL + (hipL - shL) * 0.1)]
    c.wash(body, dens=0.2, edge=0.6, layer='fill', rag=1.2)
    c.wash([tuple(shR), tuple(lerp(shR, hipR, 0.9)), tuple(lerp(J['hip'], hipR, 0.3)), tuple(lerp(J['sh'], shR, 0.4))], dens=0.35, edge=0.2, rag=2, texture=0.6, streak_dir=1)
    c.stroke([tuple(shL), tuple(lerp(shL, hipL, 0.5) + n * 1.5), tuple(hipL)], w=3.6, dry=0.6)
    c.stroke([tuple(shR), tuple(lerp(shR, hipR, 0.5) - n * 1.5), tuple(hipR)], w=3.2, dry=0.7)
    # kimono collar cross
    c.stroke([tuple(J['neck'] + n * 5), tuple(lerp(J['neck'], J['hip'], 0.45) - n * 5)], w=3.2, dry=0.5)
    c.stroke([tuple(J['neck'] - n * 4), tuple(lerp(J['neck'], J['hip'], 0.3) + n * 3)], w=2.2, dry=0.7)
    # red obi
    o1 = lerp(J['hip'], J['neck'], 0.12); o2 = lerp(J['hip'], J['neck'], 0.3)
    c.wash([tuple(o1 + n * 16), tuple(o2 + n * 15), tuple(o2 - n * 15), tuple(o1 - n * 16)], dens=0.9, edge=0.3, layer='red', rag=1.0)
    c.stroke([tuple(o1 + n * 14), tuple(o1 - n * 14)], w=2.2, dry=0.4, ink=0.8)
    # front leg
    draw_hakama_leg(c, J['hip'], J['f_knee'], J['f_foot'], shade=0.45)
    # head: big black bob with a small pale face showing at the front
    h = J['head']; lean = pose.get('lean', 0) + pose.get('head', 0)
    fwd = np.array([math.cos(math.radians(lean)), math.sin(math.radians(lean))])
    up = np.array([math.sin(math.radians(lean)), -math.cos(math.radians(lean))])
    hc = h - fwd * 3 + up * 2
    hair = [tuple(hc + np.array([math.cos(t), math.sin(t)]) * (20 + rng.normal(0, 1.0))) for t in np.linspace(0, 2 * math.pi, 18, endpoint=False)]
    hair += []
    c.wash(hair, dens=0.97, edge=0.1, rag=1.8, texture=0.2)
    # bob hangs to the jaw at the back
    c.wash([tuple(hc - fwd * 19), tuple(hc - fwd * 20 - up * 18), tuple(hc - fwd * 2 - up * 21), tuple(hc + fwd * 4 - up * 6)], dens=0.95, edge=0.1, rag=2.0, texture=0.2)
    face = [tuple(h + fwd * 7 - up * 5 + np.array([math.cos(t) * 8.5, math.sin(t) * 10])) for t in np.linspace(0, 2 * math.pi, 12, endpoint=False)]
    c.wash(face, dens=0.03, edge=0.2, layer='fill', rag=0.7)
    # fringe over the brow
    for k in range(4):
        b0 = h + up * 12 + fwd * (2 + k * 4)
        c.stroke([tuple(b0), tuple(b0 - up * (13 - k * 1.5) + fwd * 1.5)], w=3.6, dry=0.6, taper=(0.05, 0.7))
    # ragged strands at the bob ends
    for k in range(8):
        base = hc - fwd * (4 + k * 2.2) - up * (14 + rng.normal(0, 2))
        c.stroke([tuple(base), tuple(base - up * (9 + rng.normal(0, 3)) - fwd * rng.normal(1, 1.5))], w=3.4, dry=0.8, taper=(0.05, 0.6))
    c.dab(*(h + fwd * 10 - up * 5), 1.4, ink=0.9)
    # front arm sleeve
    draw_sleeve(c, J['sh'], J['f_el'], J['f_hand'], 0.24)
    # hand
    c.dab(*J['f_hand'], 3.2, ink=0.25)
    # wet-ink spatter clinging to the silhouette (reference figures are splashed, not clean)
    c.splatter(*(lerp(J['hip'], J['b_foot'], 0.7)), 10, 7, 2.2, ink=0.9)
    c.splatter(*(lerp(J['sh'], J['b_el'], 0.6)), 8, 5, 1.8, ink=0.9)
    # katana
    tip = J['f_hand'] + V(sword_a, PDIM['sword'])
    hilt = J['f_hand'] - V(sword_a, 16)
    c.stroke([tuple(hilt), tuple(J['f_hand'])], w=4.2, dry=0.2, taper=(0, 0))
    c.stroke([tuple(J['f_hand'] + perp(hilt, tip) * 5), tuple(J['f_hand'] - perp(hilt, tip) * 5)], w=3.0, dry=0.1, taper=(0, 0))
    mid = lerp(J['f_hand'], tip, 0.5) + perp(J['f_hand'], tip) * 3
    c.stroke([tuple(J['f_hand']), tuple(mid), tuple(tip)], w=3.4, dry=0.35, taper=(0.02, 0.5), ink=0.9)
    return tip

def draw_sleeve(c, sh, el, hand, shade):
    # wide hanging kimono sleeve: from shoulder to elbow, drapes downward
    drop = np.array([0, 1.0])
    d = el - sh
    s1 = sh + perp(sh, el) * 7
    s2 = sh - perp(sh, el) * 7
    e1 = el + perp(sh, el) * 8 + drop * 18
    e2 = el - perp(sh, el) * 8 + drop * 4
    h2 = lerp(el, hand, 0.35)
    poly = [tuple(s1), tuple(e1), tuple(e1 + drop * 6 + (h2 - el) * 0.4), tuple(h2), tuple(e2), tuple(s2)]
    c.wash(poly, dens=shade, edge=0.45, layer='fill', rag=1.4)
    c.stroke([tuple(s1), tuple(e1), tuple(e1 + drop * 6 + (h2 - el) * 0.4)], w=3.0, dry=0.65)
    c.stroke([tuple(s2), tuple(e2), tuple(h2)], w=2.4, dry=0.75)
    c.stroke([tuple(el), tuple(hand)], w=4.0, ink=0.35, dry=0.5)

def draw_hakama_leg(c, hip, knee, foot, shade):
    n = perp(hip, foot)
    a = hip; b = knee; f = foot
    poly = [tuple(a + n * 11), tuple(b + n * 12), tuple(f + n * 15 + np.array([0, -6])), tuple(f - n * 15 + np.array([0, -6])), tuple(b - n * 11), tuple(a - n * 10)]
    c.wash(poly, dens=shade, edge=0.5, layer='fill', rag=1.5, streak_dir=1)
    c.stroke([tuple(a + n * 11), tuple(b + n * 12), tuple(f + n * 15 + np.array([0, -6]))], w=3.4, dry=0.6)
    c.stroke([tuple(a - n * 10), tuple(b - n * 11), tuple(f - n * 15 + np.array([0, -6]))], w=2.6, dry=0.75)
    # pleat
    c.stroke([tuple(lerp(a, b, 0.3)), tuple(lerp(b, f, 0.8))], w=1.8, dry=0.8, ink=0.7)
    # black tabi foot
    c.dab(f[0] + 3, f[1] - 2, 5.5, ink=0.95, rag=0.25)

# ---------------------------------------------------------------- ronin
RDIM = dict(thigh=44, shin=42, torso=58, neck=4, head=16, uarm=30, farm=28, pole=170)

def draw_ronin(c, J, pose):
    rng = c.rng
    pole_a = J['f_farm_a'] + pose.get('pole', 0)
    # naginata behind body when held back
    def naginata():
        hnd = J['f_hand']
        back = hnd - V(pole_a, 60); tip = hnd + V(pole_a, RDIM['pole'] - 60)
        c.stroke([tuple(back), tuple(hnd), tuple(tip)], w=3.8, dry=0.3, taper=(0.05, 0.05))
        bl = tip + V(pole_a, 34) + perp(hnd, tip) * 6
        c.wash([tuple(tip + perp(hnd, tip) * 3), tuple(lerp(tip, bl, 0.5) + perp(hnd, tip) * 9), tuple(bl), tuple(tip - perp(hnd, tip) * 2)], dens=0.85, edge=0.3, rag=0.8)
        c.stroke([tuple(tip), tuple(lerp(tip, bl, 0.5) + perp(hnd, tip) * 8), tuple(bl)], w=2.4, dry=0.3)
        return bl
    draw_sleeve_dark(c, J['sh'], J['b_el'], J['b_hand'], 0.55)
    tipb = None
    if pose.get('pole_behind', 0) > 0.5: tipb = naginata()
    draw_leg_dark(c, J['hip'], J['b_knee'], J['b_foot'], 0.6)
    n = perp(J['hip'], J['neck'])
    hipL = J['hip'] + n * 19; hipR = J['hip'] - n * 19
    shL = J['sh'] + n * 17; shR = J['sh'] - n * 17
    body = [tuple(shL), tuple(shR), tuple(hipR - n * 3 + np.array([0, 10])), tuple(hipL + n * 4 + np.array([0, 12]))]
    c.wash(body, dens=0.7, edge=0.35, rag=2.4, texture=0.55, streak_dir=1)
    # tattered robe hem strokes
    for k in range(6):
        p0 = lerp(hipL, hipR, k / 5) + np.array([0, 6])
        c.stroke([tuple(p0), tuple(p0 + np.array([rng.normal(-3, 2), 12 + rng.normal(0, 4)]))], w=4, dry=0.7, taper=(0.05, 0.7))
    c.stroke([tuple(shL), tuple(hipL + np.array([0, 10]))], w=4.4, dry=0.5)
    draw_leg_dark(c, J['hip'], J['f_knee'], J['f_foot'], 0.4)
    # kasa hat: wide low cone over head
    h = J['head']; lean = pose.get('lean', 0)
    fw = np.array([math.cos(math.radians(lean * 0.5)), math.sin(math.radians(lean * 0.5))])
    up = np.array([-fw[1], fw[0]]) * -1
    up = np.array([math.sin(math.radians(lean * 0.5)), -math.cos(math.radians(lean * 0.5))])
    c.dab(*(h - up * 4), 13, ink=0.85)
    brimL = h - fw * 42 - up * 6; brimR = h + fw * 42 - up * 6; top = h + up * 17
    cone = [tuple(brimL), tuple(lerp(brimL, top, 0.5) + up * 4 - fw * 3), tuple(top), tuple(lerp(brimR, top, 0.5) + up * 4 + fw * 3), tuple(brimR), tuple(h - up * 9 + fw * 20), tuple(h - up * 10), tuple(h - up * 9 - fw * 20)]
    c.wash(cone, dens=0.62, edge=0.5, rag=1.2, texture=0.5)
    for k in range(9):
        t = (k + 0.5) / 9
        b = lerp(brimL, brimR, t) + up * (-3 * math.sin(t * math.pi))
        c.stroke([tuple(top), tuple(b)], w=1.6, dry=0.6, ink=0.8, taper=(0.1, 0.3))
    c.stroke([tuple(brimL), tuple(h - up * 11), tuple(brimR)], w=5.5, dry=0.35, taper=(0.1, 0.2))
    c.splatter(*(lerp(J['hip'], J['f_foot'], 0.8)), 14, 10, 2.6, ink=0.9)
    c.splatter(*J['chest'], 12, 6, 2.2, ink=0.9)
    draw_sleeve_dark(c, J['sh'], J['f_el'], J['f_hand'], 0.75)
    tip = tipb
    if pose.get('pole_behind', 0) <= 0.5: tip = naginata()
    c.dab(*J['f_hand'], 4, ink=0.9)
    return tip

def draw_sleeve_dark(c, sh, el, hand, dens):
    drop = np.array([0, 1.0])
    p = perp(sh, el)
    poly = [tuple(sh + p * 9), tuple(el + p * 10 + drop * 12), tuple(lerp(el, hand, 0.4) + drop * 6), tuple(el - p * 9), tuple(sh - p * 9)]
    c.wash(poly, dens=dens, edge=0.4, rag=2.0, texture=0.55, streak_dir=1)
    c.stroke([tuple(sh + p * 9), tuple(el + p * 10 + drop * 12)], w=3.6, dry=0.6)
    c.stroke([tuple(el), tuple(hand)], w=5, dry=0.4, ink=0.9)

def draw_leg_dark(c, hip, knee, foot, dens):
    n = perp(hip, foot)
    poly = [tuple(hip + n * 13), tuple(knee + n * 14), tuple(foot + n * 13 + np.array([0, -5])), tuple(foot - n * 13 + np.array([0, -5])), tuple(knee - n * 12), tuple(hip - n * 12)]
    c.wash(poly, dens=dens, edge=0.45, rag=1.8, texture=0.6, streak_dir=1)
    c.stroke([tuple(hip + n * 13), tuple(knee + n * 14), tuple(foot + n * 13 + np.array([0, -5]))], w=3.8, dry=0.55)
    c.stroke([tuple(knee), tuple(foot - n * 4)], w=2.0, dry=0.8, ink=0.8)
    c.dab(foot[0] + 3, foot[1] - 2, 6, ink=0.95)
