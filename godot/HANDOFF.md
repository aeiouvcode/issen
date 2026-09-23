# Handoff

## Resume here
Cycle 3. Cycle 2 closed F-01 (figure scale + splashed silhouettes), F-02 (dense burst engulfing the target), F-03 (player curtain visible, translucent grey wash with wet rim), and improved F-07. Open gaps, priority order:
1. F-04 Side views only (mirrored). Reference shows 3/4 and back views. Add 3/4-back rows to the baker and pick by camera-relative heading.
2. F-08 Burst blots read as chunky lumps up close; reference droplets are finer, with streaked motion trails. Bake an animated burst sheet with directional drips.
3. F-07 Portrait: the target sits at the right edge; bias the focus toward the midpoint on narrow screens.
4. F-05 Distant grass still reads as dark hedges, not soft grey fibres.
5. F-06 HUD font is the engine default; skill rings are empty.
6. F-09 Figures overlap during lunges (combo forward velocity carries through spacing).

## Capture method (use this, not Playwright timing)
`printf '[display]\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720\n' > override.cfg` then
`xvfb-run -a -s "-screen 0 1400x1000x24" $GODOT --path . --rendering-driver opengl3 --write-movie /tmp/mv/f.png --fixed-fps 30 --quit-after 125 -- --autoplay` and delete override.cfg (never commit it). Frames 30-60 cover the first combo.

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
| Per-vertex random jitter for blots | Spiky star shapes, not ink drops; switched to low-harmonic radius | 2026-09-23 |
| Sine-stack fibres for slash texture | Read as clean concentric rings; replaced with random radial profile x arc noise | 2026-09-23 |

## Discoveries
- Godot Compatibility renderer: hint_screen_texture works in canvas_item post shaders; MODEL_MATRIX is per-instance in MultiMesh so Y-billboard grass works in a spatial shader.
- Sprite3D flip: foot pixel sits 10 px left of centre, so offset.x must be 10 * facing.
