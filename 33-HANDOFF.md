# Handoff

## Resume here

Next cycle (C71): fresh audit pass; the audit queue is at diminishing items. STAGED for the push window (parent's 2026-09-26 01:31 fleet coordination: no new sign-ins; wait for parent's canonical go, then push through a config-a passive read lease when the pool frees): (1) fx.gd - C60 slash-pool source restore + C63 splatter; (2) main.gd - C64 grass, C65 camera, C70 camera un-dilation (see below); (3) tools/figures.py + 21 figure PNGs - C66; (4) tools/bake_fx.py + art/slash0/1.png - C67 arc fray; (5) shaders/post.gdshader - C69 vignette soften; (6) HANDOFF.md this update. godot-take head c69f97f5. C62 pushed (184bdfb1). C62-C70 non-perf visuals - live deploy waits for the parent's beat. At push: md5-compare every file vs raw.githubusercontent godot-take, skip matches. C68 perf PASSED (draws 21-30, nodes 63). C70 note: landscape deep-check caught one replay with an extreme close-up during a kill slow-mo - root cause: _camera lerps used time-scaled delta, so the follow cam froze while the lunge carried the pair toward it. Fix: _camera unscales delta by Engine.time_scale (camera follows in real time; normal play unchanged). Replay divergence: combat RNG makes Movie Maker runs non-repeatable - headless vs movie runs differ. override.cfg is the viewport override for captures (flip 576x1280 <-> 1280x720 manually; --resolution does NOT override it). Deployed live 2026-09-26 00:16 IST: C58+C59+C60 (pack 1-c60.pck md5 66e1510a). Local export at godot/export is pre-C62 - rebuild with ./build.sh before any future deploy.

## Blocked

- Nothing blocked.

## Failed approaches

| Approach | Why it failed | Date |
| --- | --- | --- |
| Flat ground-plane slash arcs (faceCam=false) for player attacks | Foreshortened to thin ellipses from the phone camera; nothing like the reference's towering wash | 2026-09-23 |
| Lone bamboo stalk planes 8-11 units tall at r 13-19 | Read as thin pole artifacts against the sky, not bamboo | 2026-09-23 |
| Treating Play Store "Ronin: The Last Samurai" as the reference | Wrong reference; the true one is sensonoken's X post (recovered from original brief) | 2026-09-23 |
| Curtain spawn at y=0.95 with default recenter translate | Band center landed at ankle height (.58); per-swing compensation y=1.65/1.0/1.65 fixes it | 2026-09-23 |

## Discoveries

- X upsell modal blocks video screenshots; remove `[data-testid="sheetDialog"]` etc. via JS, or skip the browser entirely: the syndication API returns direct mp4 variants, ffmpeg extracts frames.
- The naginata pole (r=0.035, h=3.5) probes as "at origin" because position is local to the glaive group; use world transforms when hunting artifacts.
- Player slashArc faceCam=true branch (rotateX + lookAt + rotateZ roll + translateX recenter) is the correct vertical-curtain mode; flat mode is for telegraph rings only.
- In-page capture beats screenshot timing for transient VFX: rAF hook polls for the arc's uT uniform, then canvas.toDataURL at the exact frame; works at any viewport.
- config-b lease = desktop 1280x713 viewport; config-a (default) = mobile 390x844.
- The arc-hunter hook sometimes no-fires when armed in the same execute-js as QA.step repositioning; arm it in its own call.
- body.coarse CSS was stripping the timebox to plain text on phones - the plaque only ever showed on desktop. Check coarse-pointer overrides when a HUD element looks different on phone.
- The File skeleton's game-css.ts is an escaped JS string (\n, \") and drifts slightly from index.html (extra coarse rules) - patch with escape-aware replacements, and expect the coarse section to differ.
- Shader verification in compiled bundles: read material.fragmentShader at runtime from the live scene; string-searching document HTML fails (compiler rewrites numbers).
- config-a lease viewport is not stable: it served 390x844 in M65 and 1280x713 in M66. Verify innerWidth before labeling a capture.
- Instinct File preview wraps the game in an iframe: execute-js needs list-frames + --frame-id to reach the canvas; top-level querySelector('canvas') returns null.
- screenshot --save --json returns the PNG path under .path (jq -r '.path'); save=false returns an inline JPEG for reasoning only.
- inkMat positional args are getting long (11 params) - if more shader knobs are needed, switch to an options object before it gets error-prone.
