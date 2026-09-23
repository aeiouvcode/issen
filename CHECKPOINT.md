# CHECKPOINT - end of M84 (Sep 24 ~04:02 IST)
Live: https://aeiouvcode.github.io/issen/ md5 e417d92ecc469033ce47896c9568340d (M84, verified LIVE-MATCH).
File: file-01M326B85G08ZT1X3M6QWB72NX gen 45 (M84) https://files.instinct.com/file-01M326B85G08ZT1X3M6QWB72NX PRIVATE.
M84 built: stance picker row (none/iai/tetsu, 34px seals, locked=dashed), STANCES def+flavor, PROGRESS gains tetsu+stance; tetsu stance (unlock ch2): posture dmg x1.5 all 3 sites (player._postMul), swing 13% slower (p._atkSpd=.87); boss-per-chapter (ch1 maxhp 140 _phaseLock, ch2 _wspeed 1.15, windup stateT scales by _wspeed); combined endGame unlock notes; ch2 win sets PROGRESS.tetsu.
QA (live, numeric): fresh seals none-sel/iai+tetsu locked PASS; ch1 boss 140 phaseLock PASS; ch2 boss 185 wspeed 1.15, windup_spin stateT 0.575 after 30 steps = 1.15x PASS; tetsu posture 18 (12x1.5) + swing stateT .145 after 10 steps PASS; ch2-win combined note "stance tetsu · chapter iron unlocked" + persistence PASS; File preview smoke PASS (boss 140, posture 12, 3 seals).
INCIDENT: first M84 deploy (md5 7ec1a42f) broke live ~6 min (3:48-3:55 AM) - stance forEach missing `});`; my syntax check used .js (CJS sloppy) which masked the module-goal error. Fixed + redeployed. Rule: syntax-check module script AS .mjs.
Security delta scan: PASS.
