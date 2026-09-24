# CHECKPOINT — 2026-09-25 3:36 AM IST
Milestone: M107 SHIPPED (shade readability + leap puff chain + puff life).
Live: https://aeiouvcode.github.io/issen/ serves md5 fd8f3dc109b1535ca1aeb241eff7b3d9 (= repo = local).
File: file-01M326B85G08ZT1X3M6QWB72NX gen 68 published (rev filerevision-01M3AQ7VV3NQ803BRRPFQX8DHK, preview preview-m107.png). PRIVATE. URL https://files.instinct.com/file-01M326B85G08ZT1X3M6QWB72NX
Working copies: /home/sandbox/issen/index.html and /home/sandbox/issen-file/src/game-main.ts (both M107; node --check'd).
M107 techniques: minion darkening = uPaper lerp toward 0x0d0a06 (was .82, now .62 - higher = flatter blob); leap puff chain hooked in the leap case with b._puffT accumulator; QA freeze trick: QA.G.timeScale=0 stops sim while screenshots still render.
QA notes: force boss leap via QA.boss.state='windup_slam'; stateT=.55; _feint=false, then QA.step; raise QA.player.hp/maxhp to survive QA slams; timeScale=0 freeze before screenshots (screenshots force frames that advance the sim otherwise).
Security: delta scan clean; importmap untouched.
Next cycle: M108 = distance-to-reference re-audit (leads in CURRENT_TASK.md).
