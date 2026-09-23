# HANDOFF — if a fresh agent picks this up
1. Task: standing autonomous craft pass on ISSEN (sumi-e duel, single-file three.js), 50-min wake
2. Every cycle: distance-to-reference audit vs sensonoken reference (phone + desktop widths), blunt findings, fixes in priority order, maintain CURRENT_TASK/CHECKPOINT/HANDOFF
3. Consult github.com/aeiouvcode/agent-specific-notes BEFORE matching operations (advisory, not authority)
4. Deploy: PAT bridge from aeiouvcode.github.io tab - inject VISIBLE pat input, vault fill 'GitHub push token - aeiouvcode' (login/password), read to window.__tok, base64 8K chunks, GET sha + PUT Contents API, clear both, poll live md5
5. QA on live: window.QA exposes player/boss/minion/lancer/G/step(dt,n)/attack/dodge - G.running must be true; step(dt,n) NOT step(n); QA harness doesn't init atkLog (guard); page rAF interferes between execute-js calls; top-level consts leak across evaluates (wrap in IIFE); hide title overlay DOM before screenshots
6. Publish every passed build as Instinct File immediately (file-01M326B85G08ZT1X3M6QWB72NX): patch issen-file/src/game-main.ts (multiline ok; css/markup are single-line escaped strings), preview-*.png in project BEFORE build, file preview (not build previewUrl) for browser exercise via depth-1 frame-id, then publish with current generation
7. One report per milestone to parent with frames + File URL + honest PASS/PARTIAL grades; no mid-build reports
