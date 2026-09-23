# Handoff

## Resume here
Cycle 5 done: F-06 (brush font + skill glyphs), F-11 (portrait framing), F-10 (ronin front/back walk). Open gaps, priority order:
1. F-12 Slash curtain inner fibres read as fine concentric rings up close; reference curtain is a broader grey dry-brush sweep.
2. F-13 Camera lags when the player runs toward the camera: figure gets huge and cropped at the bottom edge. Lead the camera on z or clamp the follow offset.
3. F-14 At 390px the HUD (bars, rings, plaque) is small; scale the HUD up on narrow screens.
4. F-15 Attacks, hit and death are side view only; turned locomotion snaps back to side view on attack.

## Capture method (use this, not Playwright timing)
`printf '[display]\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720\n' > override.cfg` then
`xvfb-run -a -s "-screen 0 1400x1000x24" $GODOT --path . --rendering-driver opengl3 --write-movie /tmp/mv/f.png --fixed-fps 30 --quit-after 125 -- --autoplay` (or `-- --autoplay-views` for the locomotion views timeline) and delete override.cfg (never commit it). Frames 30-60 cover the first combo.

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
| Per-vertex random jitter for blots | Spiky star shapes, not ink drops; switched to low-harmonic radius | 2026-09-23 |
| Sine-stack fibres for slash texture | Read as clean concentric rings; replaced with random radial profile x arc noise | 2026-09-23 |

## Discoveries
- Godot Compatibility renderer: hint_screen_texture works in canvas_item post shaders; MODEL_MATRIX is per-instance in MultiMesh so Y-billboard grass works in a spatial shader.
- Sprite3D flip: foot pixel sits 10 px left of centre, so offset.x must be 10 * facing.
