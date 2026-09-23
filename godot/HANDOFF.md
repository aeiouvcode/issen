# Handoff

## Resume here
Cycle 2 is mid-way: the F-01/F-02/F-03/F-07 changes are committed but NOT yet verified. Next: capture the player's combo curtain and a hit burst at 1280x720 and 390x844 (Playwright capture timing is flaky; hook a capture on the slash spawn instead of fixed sleeps), check the player attack still lands at the new ranges, run the side-by-side, then re-grade.

Cycle 1 audit list:
Cycle 2 audit, priority order (from the M1 side-by-side vs reference frame 03:18.90):
1. F-01 Figures too small and too clean vs reference. Reference figures fill ~50-60% of frame height and are heavy wet ink with splashed texture. Bring camera closer / scale sprites, add heavier wash and splatter on the silhouettes.
2. F-02 Hit bursts too sparse. Reference impact is a dense cloud of hundreds of droplets engulfing both fighters plus red accents. Needs a baked burst sheet (animated) rather than a few blot sprites.
3. F-03 Player slash curtain too small and rarely seen; reference curtain is a huge grey wash that spans half the screen with a dark leading rim.
4. F-04 Figures only have side views (flip). Reference shows 3/4 and back views. Add a 3/4-back row set to the baker.
5. F-05 Grass swaths read as dark hedges at distance; reference swaths are soft grey fibres, larger bands.
6. F-06 HUD: no font match (engine default), skill icons are empty rings.
7. F-07 Phone portrait framing still leaves figures small; revisit portrait camera.

## Build
- Godot 4.5.2 stable + web templates (nothreads variant, Pages-safe, no COOP/COEP needed).
- `cd godot && ./build.sh` (set GODOT=path). Art is baked: `cd godot/tools && python3 bake_sprites.py player && python3 bake_sprites.py ronin && python3 bake_fx.py` (numpy + Pillow).
- QA: serve godot/export, drive with Playwright + /usr/bin/google-chrome (swiftshader); frame rates there are meaningless.

## Blocked
- Nothing blocked. Not deployed; Pages deploy waits for Main's go.

## Failed approaches
| Approach | Why it failed | Date |
| --- | --- | --- |
| Default 844x390 stretch base | HUD shrank to ~45% on portrait phones; now 480x400 base | 2026-09-23 |
| CJK glyphs on HUD rings | Engine default font has no CJK, rendered as tofu boxes | 2026-09-23 |
| Per-vertex random jitter for blots | Spiky star shapes, not ink drops; switched to low-harmonic radius | 2026-09-23 |
| Sine-stack fibres for slash texture | Read as clean concentric rings; replaced with random radial profile x arc noise | 2026-09-23 |

## Discoveries
- Godot Compatibility renderer: hint_screen_texture works in canvas_item post shaders; MODEL_MATRIX is per-instance in MultiMesh so Y-billboard grass works in a spatial shader.
- Sprite3D flip: foot pixel sits 10 px left of centre, so offset.x must be 10 * facing.
