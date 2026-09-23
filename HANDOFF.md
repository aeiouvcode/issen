# Handoff

## Resume here

Next cycle (M73): fresh audit first (390px-forced + desktop vs /tmp/refframes; re-extract via api.fxtwitter.com/sensonoken/status/2100371695727198244 variants - the old syndication endpoint went dead; ffmpeg frames). M72 shipped the lancer wave + kasa ink tone (live md5 25dd6a420b64b64f80a13a34a9823e83, File gen 33). Candidates in priority order: G-10 vanish/spawn ink-triangle shards (ref-6.5/ref-8.5 show small triangle glyphs orbiting clouds and figures - signature detail, cheap); lancer idle spear pose reads horizontal from some angles (ref holds it upright); balance pass on shade+lancer numbers; F-07 residual kasa size/tilt; boss dark accents one step deeper (G-01 residual). Note: only ONE wave-2 bar shows at a time by design (shade then lancer); reference stacks two - deliberate divergence, crown-tracking wins on phone.

## Blocked

- Nothing blocked.

## Failed approaches

- M73: G.hitstop freeze for shard capture - puffs/shards run on raw render dt, not game time; they keep animating. Screenshot immediately after spawning instead.

| Approach | Why it failed | Date |
| --- | --- | --- |
| Flat ground-plane slash arcs (faceCam=false) for player attacks | Foreshortened to thin ellipses from the phone camera; nothing like the reference's towering wash | 2026-09-23 |
| Lone bamboo stalk planes 8-11 units tall at r 13-19 | Read as thin pole artifacts against the sky, not bamboo | 2026-09-23 |
| Treating Play Store "Ronin: The Last Samurai" as the reference | Wrong reference; the true one is sensonoken's X post (recovered from original brief) | 2026-09-23 |
| Curtain spawn at y=0.95 with default recenter translate | Band center landed at ankle height (.58); per-swing compensation y=1.65/1.0/1.65 fixes it | 2026-09-23 |
| QA-driving attacks via key:'j' keyboard events | The handler reads e.code, not e.key - 'j' never fires; use code:'KeyJ' | 2026-09-23 |
| Parking the boss for minion QA by setting pos far + state='idle' | Boss AI re-engages on its next think tick and walks back; only G.over or dead actually holds it | 2026-09-23 |
| Continuing a minion kill loop after the player died in QA | updateMinion early-returns when G.over; mhp freezes mid-fight. Retry (resetFight) restores the shade to hp70 | 2026-09-23 |
| Wall-clock sleep + screenshot to catch a .18s slash arc in a cloud tab | rAF throttling makes page stateT lag wall time badly (stateT froze at .52 over a 350ms sleep); per browser-automation notes, verify via scene state or freeze with hitstop timed off stateT, not sleeps | 2026-09-23 |
| Shield guard angle test as |wrap(toL - yaw)| < 1.0 | Backwards: toL (player->foe) and the foe's facing (foe->player) are opposite directions, so a face-to-face duel reads ~PI, not ~0. Guard is facing > PI-1.0. Verified live: frontal halved, flank full | 2026-09-23 |

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
- screenshot --save --json returns the PNG path under .structured.path (jq -r '.structured.path'; top-level .path is null); save=false returns an inline JPEG for reasoning only.
- inkMat positional args are getting long (11 params) - if more shader knobs are needed, switch to an options object before it gets error-prone.
- files.instinct.com viewer page CSP blocks cross-origin fetch: the GitHub PAT bridge must run from an aeiouvcode.github.io tab, not from the File preview tab.
- vault fill fails on offscreen or low-opacity injected inputs ("browser input failed"): make the PAT field visible (opacity 1, small, on-screen), re-find the ref AFTER restyling, fill, then hide+clear. Stale refs from before a DOM change also fail.
- issen-file/src/game-css.ts and game-markup.ts are single-line escaped JS strings: patch them with literal \n escape sequences, never real newlines, or the File build fails with "Unterminated string literal" (game-main.ts is a normal multiline module).
- game-css.ts holds raw JS-string escaping: any double quote inside the CSS must be \" - a raw " in content:"" silently terminates the string and the File compiler fails with an unhelpful "Compiler exited unsuccessfully" diagnostic. Also .tbtn/#mutebtn blocks have NO leading two-space indent there (unlike index.html).
- USER STEERING 2026-09-23 6:38 PM IST (verified verbatim, wamid...QUNEMUIzNzY1ODc4RUZGNEEzMzZBMEI5MzEyOTg4OUUA): blade feel is the ISSEN priority - parry window, slow-mo finisher on perfect runs, ink-splash kill effects. Park all other feature work until blade feel is perfected; parallel tracks allowed but delivery is mandatory.

