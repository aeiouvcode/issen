# CHECKPOINT — M83 shipped, verified live + File preview

## M83 (Sep 24, live md5 6a822522 / File gen 44)
- Chapters: 影 SHADE (shade + boss), 槍 SPEAR (+ lancer wave), 砕 IRON (+ armored shade). Wave spawns gated by CHAPTERS[G.chapter] at both kill-site triggers. Seal picker on start screen (circle seals, sel=ink-filled, locked=dashed/dim), tap stopPropagation, chapline flavor text.
- Persistence: localStorage 'issen-progress' {beaten, iai, sel}. endGame(win) records chapter beaten, unlocks next, ch1 also unlocks iai stance; win-retry auto-advances to next chapter. Chapter kanji flashes at duel start.
- iai stance stub: first cut after >2.5s stillness starts at stateT=dur*.16 (already drawn). Verified: stateT=0.067 exact.
- Verified live: seals render/lock correctly fresh + after ch1 win; ch1 gate lancer._spawnT stays Infinity; ch3 spawns (4.0 - 1 tick decay); boss kill -> stored beaten{1}+iai true, endtime "chapter spear unlocked". File preview depth-1: seals + ch1 gate PASS.
- File sandbox: localStorage blocked in File iframe (SecurityError) - caught by try/catch, fails safe to ch1, playable. Persistence is github.io-only.
- Known polish: endscreen shows only chapter-unlock note (overwrites iai note).
- Security delta: PASS (no secrets/outbound/sinks). Touch targets 44px at 390px.
- Frames: desktop /downloads/cloud-browser-20260923-213239.png, 390px /downloads/cloud-browser-20260923-213249.png (preview-m83.png in File source).
