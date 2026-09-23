# Checkpoint

Completed atomic steps, newest last. Do not redo anything listed here.

| Date | Step | Evidence (commit, URL, screenshot) |
| --- | --- | --- |
| 2026-09-17 | Original brief: make sensonoken's sumi-e duel multiplatform; art style is the bar | observation archive, x.com/sensonoken/status/2100371695727198244 |
| 2026-09-22 | M52-M55 core duel loop, ridge clamp fix | github.com/aeiouvcode/issen |
| 2026-09-22 | M56 security/SRI pass | commit series on main |
| 2026-09-22 | M57-M60 boss robe ink, wound gash x2, ground speckle clusters | https://aeiouvcode.github.io/issen/ |
| 2026-09-22 | M61-M64 anti-eclipse camera ink-fade, grass tufts, bamboo skyline, dash variation | md5 9cc364788fe4f72967a9fae402b176c0 |
| 2026-09-23 | M65 audit cycle 1: reference frames captured from sensonoken video (syndication API + ffmpeg) | /tmp/refframes |
| 2026-09-23 | M65: F-01 fixed - player slash arcs are vertical camera-facing curtains (3 swing rolls), bolder ink (pale .48-.55), per-swing spawn height | live md5 ce413959c76e44a2c82891f3c5264153 |
| 2026-09-23 | M65: F-06 fixed - bamboo stalks 4.2-6 tall, paired clumps at r 15-21 | same commit |
| 2026-09-23 | M65: verified at 390px + 1280px on deployed build (in-page canvas capture via rAF arc hunter) | /tmp/arc-atk1b.png, /tmp/arc-desktop.png |
| 2026-09-23 | M66: F-02 scroll-plaque timer (stitched tan scroll, rolled spiral end, now on phones too), F-03 mottled vignette, F-05 ink-dark blood, arc dry-brush gaps | live md5 94a04ad19f8ef302ce352a9e199873d1, File gen 27 |
| 2026-09-23 | M67: F-04 dense grass swaths (8 patches x 2 cross-planes, chisel-dab texture), F-05 blood falls 2.75x faster and dies in <=0.65s | live md5 c4bff889544d3d4a1d862eb7d406cd78, File gen 28 |
| 2026-09-23 | M68: G-01 figure wet-ink read - tonal pools (uBand) + dry-brush streaks (uDry) on hair/dark/wrap/robe; G-03 ragged arc edges via edgeN noise on band smoothsteps | live md5 aa1363f87d0fd9053a7ff663ffeb7e00, File gen 29 |
| 2026-09-23 | M69: G-04 graphic-contrast figures (robe pale paper 0xe8e1ca, floor .10, bias 1.34, dry .65; harder pool thresholds; darker player top), G-05 higher duel camera (pitch floor .40->.55), G-03 torn arc edges (2nd octave edgeN), warmer denser-speckled ground | live md5 c1215e8125ddf7cb284daa3f0b5f439f, File gen 30 |
| 2026-09-23 | M70: G-06 stage 1 - the shade (second duelist: buildBoss clone at .88 scale, no kasa, red eyes, uPaper lerped .66 toward black, hp70/posture50, full idle->approach->windup->slash->recover/stagger/dead AI, crown-tracking minbars HUD, hurtPlayer src param, auto-face picks nearest living foe); G-05/G-07 near-overhead duel camera (pitch .85-1.18, dist 9.0/10.6); heavier corner vignette (.62@70%, .94@100%). Verified live: AI loop, player<->shade damage both ways, stagger, death path (alive=false, root+bar hidden, kanji 影), reset on retry, 390px-coarse HUD | live md5 1e5e2a40384aaccda5db45e5ff1b52df, File gen 31 |
| 2026-09-23 | M71: G-08 dense washi ground (speckle thresholds/masks/inkAmt raised - side-by-side vs ref-4.5 now close); G-09 shade true ink black (uPaper lerp .82 toward 0x0d0a06), shade slash arc back on the sumi palette (red 0), quieter telegraph ring (.42). Verified live: duel frame vs ref-4.5, shade black read, ring-as-ink, forced-coarse HUD, File preview in-frame | live md5 7fd316f6b8640c7efb78d9b5b5d21590, File gen 32 |
