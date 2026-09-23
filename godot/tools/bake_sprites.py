"""Bake player and ronin sprite sheets: godot/art/player.png, godot/art/ronin.png + JSON frame maps."""
import sys, json, math, numpy as np
from PIL import Image
from brush import Canvas
import figures as F

FR = 256; GROUND = 238; CX = 118
YAW = {'_f': 55.0, '_b': -55.0}

def sin(x): return math.sin(x)

# --- player poses
P_IDLE = dict(lean=6, head=4, fa_sh=30, fa_el=55, sword=75, ba_sh=12, ba_el=40, fl_hip=22, fl_knee=-22, bl_hip=-16, bl_knee=-14)

def player_anims():
    A = {}
    A['idle'] = [dict(P_IDLE, lean=6 + 1.5 * sin(i / 6 * 2 * math.pi), fa_sh=30 + 2 * sin(i / 6 * 2 * math.pi), fl_knee=-22 - 3 * sin(i / 6 * 2 * math.pi), bl_knee=-14 - 3 * sin(i / 6 * 2 * math.pi)) for i in range(6)]
    run = []
    for i in range(8):
        p = i / 8 * 2 * math.pi
        run.append(dict(lean=20, head=-8, fa_sh=-35 + 8 * sin(p), fa_el=25, sword=-55, ba_sh=25 * sin(p + math.pi), ba_el=60,
                        fl_hip=38 * sin(p), fl_knee=-12 - 55 * max(0, math.cos(p)), bl_hip=-38 * sin(p), bl_knee=-12 - 55 * max(0, -math.cos(p)),
                        dy=5 * abs(math.sin(p))))
    A['run'] = run
    legs_lunge = dict(fl_hip=48, fl_knee=-42, bl_hip=-38, bl_knee=-8)
    def seq(keys, n):
        out = []
        for i in range(n):
            t = i / (n - 1) * (len(keys) - 1); k = min(int(t), len(keys) - 2)
            u = t - k; u = u * u * (3 - 2 * u)
            out.append(F.lerp_pose(keys[k], keys[k + 1], u))
        return out
    A['atk1'] = seq([dict(P_IDLE, lean=-4, fa_sh=165, fa_el=15, sword=30, ba_sh=-20, ba_el=30, fl_hip=15, fl_knee=-20, bl_hip=-20, bl_knee=-10),
                     dict(legs_lunge, lean=22, fa_sh=110, fa_el=-5, sword=0, ba_sh=-40, ba_el=20),
                     dict(legs_lunge, lean=28, fa_sh=55, fa_el=-10, sword=-15, ba_sh=-50, ba_el=10),
                     dict(legs_lunge, lean=18, fa_sh=15, fa_el=15, sword=-30, ba_sh=-30, ba_el=30)], 6)
    A['atk2'] = seq([dict(legs_lunge, lean=18, fa_sh=5, fa_el=10, sword=-40, ba_sh=-30, ba_el=30),
                     dict(fl_hip=30, fl_knee=-30, bl_hip=-30, bl_knee=-20, lean=5, fa_sh=60, fa_el=40, sword=40, ba_sh=10, ba_el=40, dy=6),
                     dict(fl_hip=20, fl_knee=-45, bl_hip=-25, bl_knee=-30, lean=-8, fa_sh=150, fa_el=20, sword=10, ba_sh=60, ba_el=40, dy=10),
                     dict(P_IDLE, lean=-2, fa_sh=165, fa_el=5, sword=0, dy=4)], 6)
    A['atk3'] = seq([dict(P_IDLE, lean=-10, fa_sh=175, fa_el=0, sword=15, ba_sh=160, ba_el=10, fl_hip=10, fl_knee=-50, bl_hip=-30, bl_knee=-40, dy=0),
                     dict(lean=-5, fa_sh=180, fa_el=-10, sword=0, ba_sh=170, ba_el=0, fl_hip=40, fl_knee=-80, bl_hip=-10, bl_knee=-70, dy=26),
                     dict(lean=35, fa_sh=95, fa_el=-10, sword=-5, ba_sh=90, ba_el=0, fl_hip=60, fl_knee=-70, bl_hip=-20, bl_knee=-40, dy=14),
                     dict(legs_lunge, lean=40, fa_sh=35, fa_el=0, sword=-10, ba_sh=35, ba_el=0, dy=0),
                     dict(legs_lunge, lean=32, fa_sh=20, fa_el=10, sword=-20, ba_sh=10, ba_el=20)], 7)
    A['dodge'] = seq([dict(lean=40, head=-10, fa_sh=-40, fa_el=30, sword=-60, ba_sh=-20, ba_el=40, fl_hip=50, fl_knee=-90, bl_hip=-30, bl_knee=-60, dy=4),
                      dict(lean=55, head=-15, fa_sh=-60, fa_el=20, sword=-70, ba_sh=-50, ba_el=30, fl_hip=70, fl_knee=-110, bl_hip=10, bl_knee=-100, dy=8),
                      dict(lean=35, head=-10, fa_sh=-40, fa_el=30, sword=-60, ba_sh=-20, ba_el=40, fl_hip=40, fl_knee=-60, bl_hip=-45, bl_knee=-20, dy=2),
                      dict(P_IDLE, lean=14)], 5)
    A['hit'] = seq([dict(P_IDLE, lean=-18, head=-15, fa_sh=60, fa_el=60, sword=80, ba_sh=-40, ba_el=50, fl_hip=30, fl_knee=-10, bl_hip=-5, bl_knee=-30),
                    dict(P_IDLE, lean=-25, head=-20, fa_sh=80, fa_el=70, sword=90, ba_sh=-50, ba_el=60, fl_hip=35, fl_knee=-5, bl_hip=0, bl_knee=-40),
                    dict(P_IDLE, lean=-5)], 3)
    A['die'] = seq([dict(P_IDLE, lean=-20, head=-20, fa_sh=70, fa_el=70, sword=90, fl_hip=30, fl_knee=-40),
                    dict(lean=-10, head=10, fa_sh=20, fa_el=30, sword=40, ba_sh=10, ba_el=20, fl_hip=60, fl_knee=-120, bl_hip=40, bl_knee=-110),
                    dict(lean=-60, head=20, fa_sh=-10, fa_el=10, sword=30, ba_sh=-20, ba_el=10, fl_hip=80, fl_knee=-60, bl_hip=70, bl_knee=-50),
                    dict(lean=-86, head=10, fa_sh=-80, fa_el=10, sword=10, ba_sh=-100, ba_el=20, fl_hip=95, fl_knee=-20, bl_hip=85, bl_knee=-10)], 6)
    # 3/4 front (running toward camera) and 3/4 back (running away) views; yaw from suffix
    A['idle_f'] = [dict(p) for p in A['idle']]
    A['run_f'] = [dict(p) for p in A['run']]
    A['idle_b'] = [dict(p) for p in A['idle']]
    A['run_b'] = [dict(p) for p in A['run']]
    # turned attacks for targets that lie mostly in depth (F-15)
    for v in ('_f', '_b'):
        for a in ('atk1', 'atk2', 'atk3'):
            A[a + v] = [dict(p) for p in A[a]]
    # turned hit / death for blows that land along depth (F-19)
    for v in ('_f', '_b'):
        for a in ('hit', 'die'):
            A[a + v] = [dict(p) for p in A[a]]
    return A

R_IDLE = dict(lean=10, fa_sh=40, fa_el=40, pole=-20, ba_sh=20, ba_el=50, fl_hip=24, fl_knee=-18, bl_hip=-18, bl_knee=-12)
def ronin_anims():
    A = {}
    A['idle'] = [dict(R_IDLE, lean=10 + 1.5 * sin(i / 6 * 2 * math.pi), fa_sh=40 + 2 * sin(i / 6 * 2 * math.pi), fl_knee=-18 - 3 * sin(i / 6 * 2 * math.pi)) for i in range(6)]
    w = []
    for i in range(8):
        p = i / 8 * 2 * math.pi
        w.append(dict(R_IDLE, lean=16, fl_hip=26 * sin(p), fl_knee=-8 - 35 * max(0, math.cos(p)), bl_hip=-26 * sin(p), bl_knee=-8 - 35 * max(0, -math.cos(p)), dy=3 * abs(math.sin(p))))
    A['walk'] = w
    def seq(keys, n):
        out = []
        for i in range(n):
            t = i / (n - 1) * (len(keys) - 1); k = min(int(t), len(keys) - 2)
            u = t - k; u = u * u * (3 - 2 * u)
            out.append(F.lerp_pose(keys[k], keys[k + 1], u))
        return out
    lunge = dict(fl_hip=45, fl_knee=-35, bl_hip=-40, bl_knee=-6)
    A['windup'] = seq([R_IDLE, dict(R_IDLE, lean=-12, fa_sh=150, fa_el=20, pole=-40, ba_sh=120, ba_el=20, fl_hip=10, fl_knee=-30, bl_hip=-30, bl_knee=-20, pole_behind=1),
                       dict(R_IDLE, lean=-18, fa_sh=170, fa_el=15, pole=-60, ba_sh=150, ba_el=10, fl_hip=5, fl_knee=-35, bl_hip=-35, bl_knee=-25, pole_behind=1)], 5)
    A['swing'] = seq([dict(R_IDLE, lean=-18, fa_sh=170, fa_el=15, pole=-60, ba_sh=150, ba_el=10, fl_hip=5, fl_knee=-35, bl_hip=-35, bl_knee=-25, pole_behind=1),
                      dict(lunge, lean=20, fa_sh=110, fa_el=0, pole=-5, ba_sh=100, ba_el=0),
                      dict(lunge, lean=32, fa_sh=60, fa_el=-5, pole=0, ba_sh=50, ba_el=0),
                      dict(lunge, lean=26, fa_sh=20, fa_el=10, pole=10, ba_sh=10, ba_el=20)], 6)
    A['recover'] = seq([dict(lunge, lean=26, fa_sh=20, fa_el=10, pole=10, ba_sh=10, ba_el=20), R_IDLE], 4)
    A['hit'] = seq([dict(R_IDLE, lean=-15, fa_sh=70, fa_el=60, pole=-10, fl_hip=30, fl_knee=-5), dict(R_IDLE, lean=-22, fa_sh=90, fa_el=70, fl_hip=35), R_IDLE], 3)
    A['die'] = seq([dict(R_IDLE, lean=-15, fa_sh=70, fa_el=60),
                    dict(lean=5, fa_sh=10, fa_el=20, pole=10, fl_hip=60, fl_knee=-120, bl_hip=40, bl_knee=-110, pole_behind=1),
                    dict(lean=40, fa_sh=30, fa_el=10, pole=20, fl_hip=70, fl_knee=-130, bl_hip=60, bl_knee=-120, pole_behind=1),
                    dict(lean=80, head=10, fa_sh=90, fa_el=10, pole=0, fl_hip=90, fl_knee=-100, bl_hip=80, bl_knee=-100, pole_behind=1)], 6)
    # 3/4 views for foes that close in depth; appended so existing rows keep their seeds
    A['walk_f'] = [dict(p) for p in A['walk']]
    A['walk_b'] = [dict(p) for p in A['walk']]
    # turned attack rows so a foe can strike from in front of / behind the player (F-20)
    for v in ('_f', '_b'):
        for a in ('windup', 'swing', 'recover'):
            A[a + v] = [dict(p) for p in A[a]]
    # turned hit / death (F-19)
    for v in ('_f', '_b'):
        for a in ('hit', 'die'):
            A[a + v] = [dict(p) for p in A[a]]
    return A

PAGE_ROWS = 8  # 8 x 256 px: every page is at most 2048 px, the WebGL2 guaranteed minimum (F-21)

def bake(name, anims, dims, drawer, seed0, cols=8, only=None):
    """One animation per row, split across pages of PAGE_ROWS rows so no texture exceeds
    2048 px. Frame seeds depend only on animation order, so appended rows keep old frames."""
    order = list(anims.keys())
    npages = (len(order) + PAGE_ROWS - 1) // PAGE_ROWS
    pages = []
    for k in range(npages):
        rows = min(PAGE_ROWS, len(order) - k * PAGE_ROWS)
        pages.append(Image.new('RGBA', (cols * FR, rows * FR), (0, 0, 0, 0)))
    meta = {'frame': FR, 'cols': cols, 'pages': npages, 'anims': {}}
    tips = {}
    for r, an in enumerate(order):
        frames = anims[an]
        page, row = r // PAGE_ROWS, r % PAGE_ROWS
        meta['anims'][an] = {'page': page, 'row': row, 'col0': 0, 'count': len(frames)}
        if only and an not in only: continue
        for i, pose in enumerate(frames):
            c = Canvas(FR, 2, seed=seed0 + r * 100 + i)
            yaw = YAW.get(an[-2:], 0.0)
            J = F.place(F.turn(F.fk(pose, dims), yaw), pose, CX, GROUND)
            tip = drawer(c, J, pose)
            pages[page].paste(c.render(), (i * FR, row * FR))
            tips.setdefault(an, []).append([round(float(tip[0]), 1), round(float(tip[1]), 1)] if tip is not None else None)
        print(name, an, len(frames), flush=True)
    meta['tips'] = tips
    return pages, meta

if __name__ == '__main__':
    which = sys.argv[1]; only = sys.argv[2].split(',') if len(sys.argv) > 2 else None
    out = sys.argv[3] if len(sys.argv) > 3 else '../art'
    if which == 'player':
        s, m = bake('player', player_anims(), F.PDIM, F.draw_player, 1000, only=only)
    else:
        s, m = bake('ronin', ronin_anims(), F.RDIM, F.draw_ronin, 5000, only=only)
    # palette PNG: ink + red need few colours; keeps the repo and the Pages download small
    for k, pg in enumerate(s):
        pg.quantize(colors=128, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(f'{out}/{which}_p{k}.png', optimize=True)
    json.dump(m, open(f'{out}/{which}.json', 'w'))
