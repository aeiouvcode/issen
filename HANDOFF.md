# HANDOFF — read me first if you are a fresh run

Standing mandate: autonomous 50-min craft cycles on ISSEN (single-file three.js sumi-e duel).
Every cycle: distance-to-reference audit (390px + desktop, blunt, priority order), 6-axis gauntlet
(game design, product design, cybersecurity, overall design, presentation, UI/UX + SOUND), security
delta scan, deploy via PAT bridge, verify numerically on live (never ship blind), publish Instinct
File, update CURRENT_TASK/CHECKPOINT/HANDOFF, commit, one final report to parent with frames + File URL.
No mid-build reports. Sound bar: synthesized, no assets, low levels, softened highs, never harsh.

Roadmap (user, Sep 23 10:19 PM, parallel, blade feel leads): 1 blade feel (M78-80) 2 enemy variety
(M81) 3 boss per chapter 4 progression (M83: chapters+persist+iai stub) 5 sound (M82) 6 store-ready.
Next: M84 stances complete + boss-per-chapter variety, then store-ready (listing, icon, screenshots).

Key IDs: File file-01M326B85G08ZT1X3M6QWB72NX (gen 44). Wake wakeschedule-01M2Z3KSHZFC4DM8FKZB7XC8F8.
Vault: "GitHub push token - aeiouvcode" (kind login, key password). Repo github.com/aeiouvcode/issen.
PAT bridge: navigate to https://aeiouvcode.github.io/issen/ (ROOT has CSP meta blocking api.github.com!)
-> inject visible input aria-label 'pat bridge' -> vault fill -> window.__tok -> base64 via /tmp file
chunks of 8000 (NEVER argv; verify window.__b64.length==expected BEFORE PUT; M82 incident: argv fail
caused empty commit, live empty ~40s) -> GET sha + PUT -> clear -> poll live md5.
Plain-URL navigations can hit browser disk cache - cache-bust (?v=tag) before DOM/visual checks.
File port: game-main.ts anchors identical; combat API differs (QA.attack(), atk-states, p.stam=100).
game-markup.ts/game-css.ts are single-line escaped strings - patch with literal \n and \" escapes and
\uXXXX kanji. File iframe sandbox blocks localStorage (try/catch'd). Preview tokens expire ~60s.
Audio QA: click startscreen first; counters __plucks/__taikos/_qaTones/__windDbg; sustained-intensity
tests: windup_spin, re-assert state + zero slowmo/hitstop every 60 steps, player parked z=18.
Workspace wipes: restore index.html from live URL, state files from raw.githubusercontent, File via
tools file checkout, notes repo re-clone, ref frames via api.fxtwitter.com + ffmpeg.
