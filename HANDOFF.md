# Handoff

## Resume here

Next cycle (M70): fresh audit first (390px-forced + desktop vs reference frames). M69 shipped graphic-contrast figures, higher camera, torn arc edges, warmer ground (live md5 c1215e8125ddf7cb284daa3f0b5f439f, File gen 30). Candidates in priority order: G-06 enemy variety (reference fields multiple foes with own health bars - structural, design first); boss readability when the kasa occludes the body from the raised camera at close range; F-07 kasa close-range dominance (related); vignette strength vs reference's darker mottled edges after ground warm-down. Re-extract reference frames if /tmp/refframes is gone (cdn.syndication.twimg.com tweet-result?id=2100371695727198244 + ffmpeg).

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
- files.instinct.com viewer page CSP blocks cross-origin fetch: the GitHub PAT bridge must run from an aeiouvcode.github.io tab, not from the File preview tab.
