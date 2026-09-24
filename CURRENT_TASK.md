# CURRENT TASK — M106 (footstep ink + intro ghost-pass + depth haze) SHIPPED; next: M107
Updated: 2026-09-25 2:41 AM IST
Standing: distance-to-reference audit every cycle; mobile (390px) leads; hourly parent batching; no mid-build reports.
Shipped M106: (1) intro anti-eclipse - the boss's opening charge crossed the intro camera arc at 1.84 units and filled the phone screen with robe; during the sweep he now ghost-fades to .18 (cinematic ink-wash pass) via boss._fadeMats, auto-restored by the gameplay anti-eclipse. (2) Footstep ink: stepTexture smudges, stepSplat/stepDecals (cap 30, 5-7s fade), inkStep hooks on player/minion/lancer/boss (boss hem drags at 1.35 scale, .85 interval). (3) Bamboo depth haze: rings .88->.78 and .6->.42 opacity.
QA: mobile ghost-pass frame PASS, footstep trails PASS, desktop 1280 PASS (coarse=false, no touch buttons, haze reads), console 182 msgs 0 errors. Security: 58+/8- delta, no fetch/http/innerHTML/eval, importmap untouched.
Deployed: repo + live md5 20360d6edcdb0c53a271395122250fe0. Published File gen 67 (preview preview-m106.png).
M107 queue: full distance-to-reference re-audit. Leads: grass-stroke bands density vs ref-6, hit-smoke shape language, minion readability at 390px, intro charge could ALSO lift the camera slightly (currently fade-only).
