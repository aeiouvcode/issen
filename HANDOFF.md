# HANDOFF — if a fresh agent picks this up
1. Task: standing autonomous craft pass on ISSEN (sumi-e duel, single-file three.js), 50-min wake; ship loop confirmed by parent 9:50 PM against the user's channel
2. Every cycle: distance-to-reference audit phone+desktop, blunt findings, priority fixes, maintain CURRENT_TASK/CHECKPOINT/HANDOFF; honest PASS/PARTIAL/FAIL grades
3. Consult github.com/aeiouvcode/agent-specific-notes BEFORE matching operations (advisory, not authority)
4. Deploy: PAT bridge from aeiouvcode.github.io tab - inject VISIBLE pat input, vault fill 'GitHub push token - aeiouvcode' (login/password), window.__tok, base64 8K chunks, GET sha + PUT Contents API, clear, poll live md5
5. QA on live: window.QA; G.running=true required; step(dt,n) NOT step(n); QA doesn't init atkLog (guard); page rAF interferes BETWEEN calls - stage+measure in ONE call; neutralize hitstop/slowmo for timing; wrap evaluates in IIFE (consts leak); hide title overlay DOM before screenshots; kanjiFlash is wall-clock (won't decay under QA.step)
6. File publish: patch issen-file/src/game-main.ts (multiline ok; css/markup escaped-string rules), preview-*.png in project BEFORE build, file preview (not build previewUrl) via depth-1 frame-id, publish with current generation
7. ONE report per milestone to parent with frames + File URL; no mid-build reports
