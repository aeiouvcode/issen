# HANDOFF — read me first if you are a fresh run

Standing mandate: autonomous 50-min craft cycles on ISSEN (single-file three.js sumi-e duel).
Every cycle: distance-to-reference audit (390px + desktop, blunt, priority order), 6-axis gauntlet
(game design, product design, cybersecurity, overall design, presentation, UI/UX + SOUND), security
delta scan, deploy via PAT bridge, verify numerically on live (never ship blind), publish Instinct
File, update CURRENT_TASK/CHECKPOINT/HANDOFF, commit, one final report to parent with frames + File URL.
No mid-build reports. Sound bar: synthesized, no assets, low levels, softened highs, never harsh.

Roadmap (user, Sep 23 10:19 PM, all parallel, blade feel leads):
1 blade feel (M78-80) 2 enemy variety (M81: armored shade + shield turn) 3 boss per chapter
4 progression/stance unlocks 5 sound pass (M82: tuned voices + reactive shamisen/taiko) 6 store-ready.
Next: M83 chapter shell + persistence, M84 stances + boss tie-in, then store-ready assets.

Key IDs: File file-01M326B85G08ZT1X3M6QWB72NX (gen 43). Wake wakeschedule-01M2Z3KSHZFC4DM8FKZB7XC8F8.
Vault: "GitHub push token - aeiouvcode" (kind login, key password). Repo github.com/aeiouvcode/issen.
PAT bridge: navigate to https://aeiouvcode.github.io/issen/ (ROOT has CSP meta blocking api.github.com
fetches!) -> inject visible input aria-label 'pat bridge' -> vault fill -> window.__tok ->
base64 content via /tmp file chunks of 8000 (NEVER argv; verify __b64.length before PUT) ->
GET sha + PUT -> clear token+input -> poll live md5.
File port: game-main.ts anchors identical to index.html JS; combat API differs (QA.attack(),
atk-states, p.stam=100). Preview tokens expire in ~60s: fresh status -> navigate immediately.
Audio QA: click startscreen first (starts wind + unlocks ac); counters __plucks/__taikos/_qaTones.
Workspace wipes: restore index.html from live URL, state files from raw.githubusercontent, File via
tools file checkout, notes repo re-clone, ref frames via api.fxtwitter.com + ffmpeg.
