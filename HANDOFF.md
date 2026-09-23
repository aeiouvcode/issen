# Handoff

## Resume here

Next cycle: fix F-02 (rolled-scroll timer plaque) then F-03 (stronger mottled edge vignette), per priority order in CURRENT_TASK.md. Slash curtain polish if time: ragged dry-brush edges + white streak gaps (arc fragment shader), arc still reads slightly smooth/blobby up close. Re-run the 390px + desktop side-by-side against the reference frames (re-extract if /tmp/refframes is gone: download mp4 via cdn.syndication.twimg.com tweet-result?id=2100371695727198244, ffmpeg -ss frames).

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
