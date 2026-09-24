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

SIDE_W = {'arm': 12.0, 'leg': 9.0}

def turn(J, yaw, elev=0.32):
    """Rotate a side-view skeleton about the vertical axis. yaw>0 turns the figure toward
    the camera (3/4 front), yaw<0 away (3/4 back). f_* limbs sit on the near side, b_* on
    the far side; forward motion foreshortens by cos(yaw) and drops/rises by elev."""
    if abs(yaw) < 1e-3:
        J = dict(J)
        for s in ('f', 'b'):
            J[s + '_sh'] = J['sh']; J[s + '_hip'] = J['hip']
        return J
    cy, sy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    hip0 = J['hip'].copy()
    def pr(v, z):
        x = v[0] - hip0[0]
        return np.array([hip0[0] + x * cy - z * sy, v[1] + x * sy * elev])
    out = {}
    for k, v in J.items():
        if not isinstance(v, np.ndarray):
            out[k] = v; continue
        z = 0.0
        if k[:2] in ('f_', 'b_'):
            z = (1 if k[0] == 'f' else -1) * (SIDE_W['arm'] if ('el' in k or 'hand' in k) else SIDE_W['leg'])
        out[k] = pr(v, z)
    for s, sg in (('f', 1), ('b', -1)):
        out[s + '_sh'] = pr(J['sh'], sg * SIDE_W['arm'])
        out[s + '_hip'] = pr(J['hip'], sg * SIDE_W['leg'])
    out['_yaw'] = yaw
    return out

def pvec(J, v):
    """Project a side-plane direction vector with the figure's current yaw."""
    yaw = J.get('_yaw', 0.0)
    if not yaw: return v
    cy, sy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    return np.array([v[0] * cy, v[1] + v[0] * sy * 0.32])

def place(J, pose, cx, ground):
    pts = [J[k] for k in ('f_foot', 'b_foot', 'f_knee', 'b_knee', 'head', 'f_hand', 'b_hand', 'hip')]
    low = max(p[1] for p in pts)
    off = np.array([cx, ground - low - pose.get('dy', 0)])
    return {k: (v + off if isinstance(v, np.ndarray) and v.shape == (2,) else v) for k, v in J.items()}

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
    yaw = J.get('_yaw', 0.0); ay = abs(math.sin(math.radians(yaw)))
    cyaw = math.cos(math.radians(yaw)); back = yaw < -1
    # back sleeve + arm
    draw_sleeve(c, J['b_sh'], J['b_el'], J['b_hand'], 0.5)
    # back leg hakama
    draw_hakama_leg(c, J['b_hip'], J['b_knee'], J['b_foot'], shade=0.7)
    # torso kimono
    n = perp(J['hip'], J['neck'])
    tw = 1.0 + 0.35 * ay
    hipL = J['hip'] + n * 15 * tw; hipR = J['hip'] - n * 15 * tw
    shL = J['sh'] + n * 13 * tw; shR = J['sh'] - n * 13 * tw
    body = [tuple(shL), tuple(J['neck'] + n * 4), tuple(shR), tuple(hipR + (hipR - shR) * 0.1), tuple(hipL + (hipL - shL) * 0.1)]
    c.wash(body, dens=0.2, edge=0.6, layer='fill', rag=1.2)
    c.wash([tuple(shR), tuple(lerp(shR, hipR, 0.9)), tuple(lerp(J['hip'], hipR, 0.3)), tuple(lerp(J['sh'], shR, 0.4))], dens=0.35, edge=0.2, rag=2, texture=0.6, streak_dir=1)
    c.stroke([tuple(shL), tuple(lerp(shL, hipL, 0.5) + n * 1.5), tuple(hipL)], w=3.6, dry=0.6)
    c.stroke([tuple(shR), tuple(lerp(shR, hipR, 0.5) - n * 1.5), tuple(hipR)], w=3.2, dry=0.7)
    if not back:
        # kimono collar cross (centred more as the figure turns to camera)
        cx0 = -n * 3 * ay
        c.stroke([tuple(J['neck'] + n * 5 + cx0), tuple(lerp(J['neck'], J['hip'], 0.45) - n * 5 + cx0)], w=3.2, dry=0.5)
        c.stroke([tuple(J['neck'] - n * 4 + cx0), tuple(lerp(J['neck'], J['hip'], 0.3) + n * 3 + cx0)], w=2.2, dry=0.7)
    else:
        # spine seam down the back of the kimono
        c.stroke([tuple(J['neck']), tuple(lerp(J['neck'], J['hip'], 0.8))], w=2.0, dry=0.8, ink=0.7)
    # red obi
    o1 = lerp(J['hip'], J['neck'], 0.12); o2 = lerp(J['hip'], J['neck'], 0.3)
    c.wash([tuple(o1 + n * 16), tuple(o2 + n * 15), tuple(o2 - n * 15), tuple(o1 - n * 16)], dens=0.9, edge=0.3, layer='red', rag=1.0)
    c.stroke([tuple(o1 + n * 14), tuple(o1 - n * 14)], w=2.2, dry=0.4, ink=0.8)
    if back:
        # obi bow knot on the back, trailing red tails
        ob = lerp(o1, o2, 0.5)
        c.wash([tuple(ob + n * 9 + np.array([0, -4])), tuple(ob - n * 9 + np.array([0, -4])), tuple(ob - n * 6 + np.array([0, 6])), tuple(ob + n * 6 + np.array([0, 6]))], dens=0.95, edge=0.3, layer='red', rag=1.2)
        c.stroke([tuple(ob), tuple(ob + np.array([-3, 20]))], w=4.0, dry=0.5, ink=0.8, taper=(0.1, 0.6))
    # front leg
    draw_hakama_leg(c, J['f_hip'], J['f_knee'], J['f_foot'], shade=0.45)
    # head: big black bob. Side: pale face at the front. 3/4 front: face turns toward
    # camera. Back: solid hair mass with ragged ends, no face.
    h = J['head']; lean = pose.get('lean', 0) + pose.get('head', 0)
    fwd = np.array([math.cos(math.radians(lean)), math.sin(math.radians(lean))]) * cyaw
    up = np.array([math.sin(math.radians(lean)) * cyaw, -math.cos(math.radians(lean))])
    up = up / (np.linalg.norm(up) + 1e-6)
    side = np.array([-1.0, 0.0]) * ay     # screen direction the face swings to when turned
    hc = h - fwd * 3 + up * 2
    hair = [tuple(hc + np.array([math.cos(t) * (1 + 0.08 * ay), math.sin(t)]) * (20 + rng.normal(0, 1.0))) for t in np.linspace(0, 2 * math.pi, 18, endpoint=False)]
    c.wash(hair, dens=0.97, edge=0.1, rag=1.8, texture=0.2)
    if back:
        # bob seen from behind: hangs to the jaw all round, a wider dark mass
        c.wash([tuple(hc + np.array([-21, -2])), tuple(hc + np.array([21, -2])), tuple(hc + np.array([23, 22])), tuple(hc + np.array([-23, 22]))], dens=0.96, edge=0.1, rag=2.0, texture=0.2)
        for k in range(11):
            base = hc + np.array([-21 + k * 4.2, 19 + rng.normal(0, 2)])
            c.stroke([tuple(base), tuple(base + np.array([rng.normal(0, 1.5), 9 + rng.normal(0, 3)]))], w=3.4, dry=0.8, taper=(0.05, 0.6))
        # crown sheen: one dry pale stroke across the hair
        c.stroke([tuple(hc + np.array([-10, -12])), tuple(hc + np.array([2, -15])), tuple(hc + np.array([12, -11]))], w=2.2, dry=0.9, ink=0.35)
    else:
        if ay < 0.3:
            c.wash([tuple(hc - fwd * 19), tuple(hc - fwd * 20 - up * 18), tuple(hc - fwd * 2 - up * 21), tuple(hc + fwd * 4 - up * 6)], dens=0.95, edge=0.1, rag=2.0, texture=0.2)
        else:
            # turned toward camera: the bob frames both cheeks instead of hanging behind
            fc0 = h + fwd * 7 - up * 5 + side * 5
            for sg, wd in ((1, 9), (-1, 6)):
                o = np.array([sg * (10 + 2.5 * ay), 0])
                c.wash([tuple(fc0 + o + np.array([-sg * 2, -12])), tuple(fc0 + o + np.array([sg * wd, -10])), tuple(fc0 + o + np.array([sg * (wd + 1), 12])), tuple(fc0 + o + np.array([-sg * 1, 9]))], dens=0.95, edge=0.1, rag=1.6, texture=0.2)
        fc = h + fwd * 7 - up * 5 + side * 5
        fw_ = 8.5 + 2.5 * ay
        face = [tuple(fc + np.array([math.cos(t) * fw_, math.sin(t) * 10])) for t in np.linspace(0, 2 * math.pi, 12, endpoint=False)]
        c.wash(face, dens=0.03, edge=0.2, layer='fill', rag=0.7)
        for k in range(4 + int(2 * ay)):
            b0 = h + up * 12 + fwd * (2 + k * 4) + side * (8 - k * 4) * (1 if ay > 0.1 else 0)
            c.stroke([tuple(b0), tuple(b0 - up * (13 - k * 1.5) + fwd * 1.5)], w=3.6, dry=0.6, taper=(0.05, 0.7))
        for k in range(8):
            base = hc - fwd * (4 + k * 2.2) - up * (14 + rng.normal(0, 2)) if ay < 0.3 else fc0 + np.array([(-1 if k % 2 else 1) * (13 + 2.5 * ay + (k // 2)), 9 + rng.normal(0, 2)])
            c.stroke([tuple(base), tuple(base - up * (9 + rng.normal(0, 3)) - fwd * rng.normal(1, 1.5))], w=3.4, dry=0.8, taper=(0.05, 0.6))
        c.dab(*(fc + fwd * 3 + side * 2 + np.array([2.5 * ay, -2 * ay])), 1.4, ink=0.9)
        if ay > 0.3:
            c.dab(*(fc - np.array([4.5, 2]) + fwd * 1), 1.3, ink=0.9)
    # front arm sleeve
    draw_sleeve(c, J['f_sh'], J['f_el'], J['f_hand'], 0.24)
    # hand
    c.dab(*J['f_hand'], 3.2, ink=0.25)
    # wet-ink spatter clinging to the silhouette (reference figures are splashed, not clean)
    c.splatter(*(lerp(J['hip'], J['b_foot'], 0.7)), 10, 7, 2.2, ink=0.9)
    c.splatter(*(lerp(J['sh'], J['b_el'], 0.6)), 8, 5, 1.8, ink=0.9)
    # katana
    tip = J['f_hand'] + pvec(J, V(sword_a, PDIM['sword']))
    hilt = J['f_hand'] - pvec(J, V(sword_a, 16))
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

VARIANT = ''  # C26: '' kasa ronin, 'armor' lacquer plates, 'spear' yari, 'boss' Kageyama; C32 'twin' two short blades; C33 'bow' yumi archer

def draw_ronin(c, J, pose):
    rng = c.rng
    pole_a = J['f_farm_a'] + pose.get('pole', 0)
    # naginata behind body when held back
    def naginata():
        hnd = J['f_hand']
        if VARIANT == 'spear':
            # yari: longer straight shaft, small leaf head, a tassel ring below it
            back = hnd - pvec(J, V(pole_a, 80)); tip = hnd + pvec(J, V(pole_a, RDIM['pole'] - 30))
            c.stroke([tuple(back), tuple(hnd), tuple(tip)], w=3.2, dry=0.25, taper=(0.05, 0.05))
            d = pvec(J, V(pole_a, 1.0)); d = d / (np.linalg.norm(d) + 1e-6); q = np.array([-d[1], d[0]])
            hd = tip + d * 58
            c.wash([tuple(tip), tuple(tip + d * 18 + q * 9), tuple(hd), tuple(tip + d * 18 - q * 9)], dens=0.95, edge=0.2, rag=0.5)
            c.stroke([tuple(tip - q * 12), tuple(tip + q * 12)], w=3.4, dry=0.3)
            for k in range(5):
                c.stroke([tuple(tip - d * 6), tuple(tip - d * (22 + k * 3) + q * (k - 2) * 3)], w=1.6, dry=0.6, ink=0.85)
            return hd
        if VARIANT == 'bow':
            # C33: a tall asymmetric yumi held upright in the lead hand (grip below centre), string
            # drawn back toward the chest; returns the arrow tip so tips/aim follow the bow hand
            d = pvec(J, V(pole_a, 1.0)); d = d / (np.linalg.norm(d) + 1e-6); q = np.array([-d[1], d[0]])
            up = q if q[1] < 0 else -q
            top = hnd + up * 118 + d * 14; bot = hnd - up * 64 + d * 8
            c.stroke([tuple(bot), tuple(hnd + d * 16 - up * 20), tuple(hnd + d * 18 + up * 40), tuple(top)], w=3.0, dry=0.3, taper=(0.3, 0.3))
            c.stroke([tuple(hnd), tuple(hnd - d * 3)], w=5.0, dry=0.2)
            nock = lerp(J['chest'], hnd, 0.35)
            c.stroke([tuple(top), tuple(nock), tuple(bot)], w=1.0, dry=0.5, ink=0.7)
            tip = hnd + d * 34
            c.stroke([tuple(nock), tuple(tip)], w=1.8, dry=0.3)
            return tip
        if VARIANT == 'twin':
            # C32: a short uchigatana in the lead hand, a slight curve, no pole behind the grip
            tip = hnd + pvec(J, V(pole_a, 92))
            mid = lerp(hnd, tip, 0.55) + perp(hnd, tip) * 4
            c.stroke([tuple(hnd - pvec(J, V(pole_a, 14))), tuple(hnd)], w=4.2, dry=0.2)
            c.stroke([tuple(hnd), tuple(mid), tuple(tip)], w=2.6, dry=0.25, taper=(0.1, 0.9))
            c.stroke([tuple(hnd - perp(hnd, tip) * 7), tuple(hnd + perp(hnd, tip) * 7)], w=3.0, dry=0.3)
            return tip
        if VARIANT == 'boss':
            # odachi-long naginata blade, heavier ink
            back = hnd - pvec(J, V(pole_a, 60)); tip = hnd + pvec(J, V(pole_a, RDIM['pole'] - 70))
            c.stroke([tuple(back), tuple(hnd), tuple(tip)], w=4.4, dry=0.25, taper=(0.05, 0.05))
            bl = tip + pvec(J, V(pole_a, 58)) + perp(hnd, tip) * 10
            c.wash([tuple(tip + perp(hnd, tip) * 4), tuple(lerp(tip, bl, 0.5) + perp(hnd, tip) * 14), tuple(bl), tuple(tip - perp(hnd, tip) * 3)], dens=0.95, edge=0.25, rag=0.8)
            c.stroke([tuple(tip), tuple(lerp(tip, bl, 0.5) + perp(hnd, tip) * 13), tuple(bl)], w=2.8, dry=0.25)
            return bl
        back = hnd - pvec(J, V(pole_a, 60)); tip = hnd + pvec(J, V(pole_a, RDIM['pole'] - 60))
        c.stroke([tuple(back), tuple(hnd), tuple(tip)], w=3.8, dry=0.3, taper=(0.05, 0.05))
        bl = tip + pvec(J, V(pole_a, 34)) + perp(hnd, tip) * 6
        c.wash([tuple(tip + perp(hnd, tip) * 3), tuple(lerp(tip, bl, 0.5) + perp(hnd, tip) * 9), tuple(bl), tuple(tip - perp(hnd, tip) * 2)], dens=0.85, edge=0.3, rag=0.8)
        c.stroke([tuple(tip), tuple(lerp(tip, bl, 0.5) + perp(hnd, tip) * 8), tuple(bl)], w=2.4, dry=0.3)
        return bl
    draw_sleeve_dark(c, J['b_sh'], J['b_el'], J['b_hand'], 0.55)
    if VARIANT == 'twin':
        # C32: the off hand carries a wakizashi, held low and reversed behind the body line
        bh = J['b_hand']; wa = J.get('b_farm_a', 0) + 150 if 'b_farm_a' in J else 150
        wt = bh + pvec(J, V(wa, 64))
        c.stroke([tuple(bh - pvec(J, V(wa, 10))), tuple(bh)], w=3.6, dry=0.2)
        c.stroke([tuple(bh), tuple(lerp(bh, wt, 0.5) + perp(bh, wt) * 3), tuple(wt)], w=2.2, dry=0.3, taper=(0.1, 0.9), ink=0.8)
    tipb = None
    if pose.get('pole_behind', 0) > 0.5: tipb = naginata()
    draw_leg_dark(c, J['b_hip'], J['b_knee'], J['b_foot'], 0.6)
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
    if VARIANT == 'armor':
        # do: four lacquer bands across the torso with paper gaps (the lacing), sode plates at the shoulder
        for k in range(4):
            a0, a1 = 0.08 + k * 0.22, 0.08 + k * 0.22 + 0.16
            pl = [tuple(lerp(shL, hipL, a0) + n * 3), tuple(lerp(shR, hipR, a0) - n * 3), tuple(lerp(shR, hipR, a1) - n * 3), tuple(lerp(shL, hipL, a1) + n * 3)]
            c.wash(pl, dens=0.97, edge=0.15, rag=0.6, texture=0.25)
        fsh = J['f_sh']; d = np.array([0, 1.0])
        for k in range(3):
            o = d * (6 + k * 9)
            c.wash([tuple(fsh - n * 14 + o), tuple(fsh + n * 12 + o), tuple(fsh + n * 13 + o + d * 7), tuple(fsh - n * 15 + o + d * 7)], dens=0.97, edge=0.15, rag=0.5)
    if VARIANT == 'boss':
        # haori tails streaming behind, heavier torso
        back = -1.0 if pvec(J, np.array([1.0, 0.0]))[0] >= 0 else 1.0
        for k in range(3):
            p0 = lerp(J['sh'], J['hip'], 0.35 + k * 0.28)
            tail = p0 + np.array([back * (64 + k * 16), 26 + k * 12 + rng.normal(0, 3)])
            c.wash([tuple(p0 + np.array([0, -9])), tuple(lerp(p0, tail, 0.5) + np.array([0, -4])), tuple(tail), tuple(tail + np.array([back * -6, 12])), tuple(p0 + np.array([0, 12]))], dens=0.82, edge=0.4, rag=2.4, texture=0.5)
        # heavy o-sode pauldrons widen the silhouette
        for sh in (J['b_sh'], J['f_sh']):
            c.wash([tuple(sh + np.array([-15, -2])), tuple(sh + np.array([15, -2])), tuple(sh + np.array([21, 22])), tuple(sh + np.array([-21, 22]))], dens=0.95, edge=0.2, rag=0.8, texture=0.3)
        c.wash(body, dens=0.55, edge=0.3, rag=1.6, texture=0.4, streak_dir=1)
    draw_leg_dark(c, J['f_hip'], J['f_knee'], J['f_foot'], 0.4)
    if VARIANT == 'boss':
        # no kasa: bare head with a tall topknot, wild hair, and a red eye slit
        h = J['head']
        c.dab(*h, 15, ink=0.95)
        for k in range(7):
            a = math.radians(200 + k * 20)
            c.stroke([tuple(h), tuple(h + np.array([math.cos(a) * 26, math.sin(a) * 22 - 4]))], w=3.2, dry=0.6, taper=(0.1, 0.8))
        c.stroke([tuple(h + np.array([0, -12])), tuple(h + np.array([-4, -32])), tuple(h + np.array([-12, -40]))], w=5.5, dry=0.4, taper=(0.2, 0.6))
        c.splatter(*(lerp(J['hip'], J['f_foot'], 0.8)), 14, 10, 2.6, ink=0.9)
        draw_sleeve_dark(c, J['f_sh'], J['f_el'], J['f_hand'], 0.85)
        tip = tipb
        if pose.get('pole_behind', 0) <= 0.5: tip = naginata()
        c.dab(*J['f_hand'], 4, ink=0.9)
        return tip
    if VARIANT == 'twin':
        # C32: no kasa - bare head, hachimaki band with two tails flying back, short topknot
        h = J['head']
        c.dab(*h, 14, ink=0.92)
        back = -1.0 if pvec(J, np.array([1.0, 0.0]))[0] >= 0 else 1.0
        c.stroke([tuple(h + np.array([-15, -4])), tuple(h + np.array([15, -4]))], w=4.0, dry=0.3)
        for k in range(2):
            tail = h + np.array([back * (30 + k * 10), 2 + k * 9 + rng.normal(0, 2)])
            c.stroke([tuple(h + np.array([back * 12, -4])), tuple(lerp(h, tail, 0.6) + np.array([0, -5])), tuple(tail)], w=2.6 - k * 0.6, dry=0.5, taper=(0.1, 0.8))
        c.stroke([tuple(h + np.array([0, -12])), tuple(h + np.array([-back * 3, -24]))], w=5.0, dry=0.4, taper=(0.2, 0.6))
        c.splatter(*(lerp(J['hip'], J['f_foot'], 0.8)), 14, 10, 2.6, ink=0.9)
        c.splatter(*J['chest'], 12, 6, 2.2, ink=0.9)
        draw_sleeve_dark(c, J['f_sh'], J['f_el'], J['f_hand'], 0.75)
        tip = tipb
        if pose.get('pole_behind', 0) <= 0.5: tip = naginata()
        c.dab(*J['f_hand'], 4, ink=0.9)
        return tip
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
    yaw = J.get('_yaw', 0.0)
    if yaw > 1:
        # turned toward camera: the brim's underside shows as a dark shadowed ellipse over the face
        c.wash([tuple(h + np.array([math.cos(t) * 34, 4 + math.sin(t) * 6])) for t in np.linspace(0, 2 * math.pi, 14, endpoint=False)], dens=0.8, edge=0.3, rag=1.2, texture=0.4)
        c.dab(*(h + np.array([0, 12])), 5, ink=0.9)
    c.splatter(*(lerp(J['hip'], J['f_foot'], 0.8)), 14, 10, 2.6, ink=0.9)
    c.splatter(*J['chest'], 12, 6, 2.2, ink=0.9)
    draw_sleeve_dark(c, J['f_sh'], J['f_el'], J['f_hand'], 0.75)
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
