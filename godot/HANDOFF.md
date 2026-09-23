# Handoff

## Resume here
Cycle 8 done: dodge dab fix, F-18 (256-level slash alpha), F-20 (ronin depth-lane attacks). Open gaps, priority order:
1. F-19 Hit and death are still side view only (player and ronin); bake _f/_b hit/die rows.
2. F-21 Player sheet is 4096 px wide, ronin 3840 px tall: fine for WebGL2 on current phones, check an older Android before Pages.
3. F-22 Depth-lane foes sit 1.4 m off axis so both figures stay readable; if the reference wants straight-on depth clashes, revisit with a camera nudge instead.

## Capture method (use this, not Playwright timing)
`printf '[display]\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720\n' > override.cfg` then
`xvfb-run -a -s "-screen 0 1400x1000x24" $GODOT --path . --rendering-driver opengl3 --write-movie /tmp/mv/f.png --fixed-fps 30 --quit-after 125 -- --autoplay` (or `-- --autoplay-views` / `--autoplay-depth` / `--autoplay-foe`) and delete override.cfg (never commit it). Frames 30-60 cover the first combo.

## Build
- Godot 4.5.2 stable + web templates (nothreads variant, Pages-safe, no COOP/COEP needed).
- `cd godot && ./build.sh` (set GODOT=path). Art is baked: `cd godot/tools && python3 bake_sprites.py player && python3 bake_sprites.py ronin && python3 bake_fx.py` (numpy + Pillow).
- QA: serve godot/export, drive with Playwright + /usr/bin/google-chrome (swiftshader); frame rates there are meaningless.

## Blocked
- Nothing blocked. Not deployed; Pages deploy waits for Main's go.

## Failed approaches
| Approach | Why it failed | Date |
| --- | --- | --- |
| Fixed-sleep Playwright screenshots to catch attack frames | Swiftshader screenshots take ~1 s; the whole 0.3 s attack plays between shots | 2026-09-23 |
| Opaque dark curtain at 1.45-1.8x scale | A black crescent covering the screen with a hard rectangular cut from the quad edge | 2026-09-23 |
| Default 844x390 stretch base | HUD shrank to ~45% on portrait phones; now 480x400 base | 2026-09-23 |
| CJK glyphs on HUD rings | Engine default font has no CJK, rendered as tofu boxes | 2026-09-23 |
| Long fast drip streaks thrown along the cut | Read as horizontal speed lines, not splatter; now radial spray, short streaks, stretch capped 1.1x | 2026-09-23 |
| Bigger bloom blots at full ink | Read as black rocks; replaced with soft wash dabs + many small blots | 2026-09-23 |
| Tinting black ink blots red via modulate | Modulate multiplies the near-black ink, so the mark stayed black; baked a red blot texture instead | 2026-09-23 |
| Per-vertex random jitter for blots | Spiky star shapes, not ink drops; switched to low-harmonic radius | 2026-09-23 |
| Sine-stack fibres for slash texture | Read as clean concentric rings; replaced with random radial profile x arc noise | 2026-09-23 |

## Discoveries
- Godot Compatibility renderer: hint_screen_texture works in canvas_item post shaders; MODEL_MATRIX is per-instance in MultiMesh so Y-billboard grass works in a spatial shader.
- Sprite3D flip: foot pixel sits 10 px left of centre, so offset.x must be 10 * facing.
