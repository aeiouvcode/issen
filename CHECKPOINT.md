# CHECKPOINT — M82 shipped, verified live + File preview

## M82 (Sep 24, live md5 971de619 / File gen 43)
- Voice retune: every voice lowered and highs softened (parry 1900->1650 lead, big/slam/drum/crack/hit/clank all trimmed ~25%, clank square 1300->1150). Sound bar: synthesized, no assets, low levels, softened highs.
- NEW reactive music layer: shamisen-style pluck (detuned saw pair through sweeping bandpass + plectrum noise bite, D-minor pentatonic) + taiko voice (105->44 sine + lowpassed noise). Phrase scheduler in sfx.tick: phrases only when G.running && intensity>=.45, 1-3 plucks, ~8-20s apart (tighter when hot), sim-time queue (G.time) so QA.step stays deterministic. Parry adds a soft taiko accent. Idle = near silence (wind/rustle only).
- Robe mid-tone pooling: M.robe floor .10->.15, streakAmp 2.1->2.35, bias 1.34->1.30, hatch .5->.55 — robe pools mid-gray instead of reading flat.
- Verified numerically on live: idle 20s = 0 plucks; sustained hot (windup_spin, per-batch state re-assert, slowmo/hitstop zeroed) = plucks fired (first ~6s in, by design). File preview depth-1: idle 0, hot 2 in 10s. Parry-taiko verified by construction (parry() calls taiko(.07)). Levels/character graded by construction — audio can't be screenshot-verified.
- Security delta: PASS (no secrets, 0 outbound, pinned three@0.160.0, no new sinks).
- Frames: desktop /downloads/cloud-browser-20260923-204233.png, 390px /downloads/cloud-browser-20260923-204248.png (preview-m82.png in File source).

## INCIDENT (honest): empty-content commit
During deploy, a base64 chunking step failed (argv too long) and the first PUT committed EMPTY index.html; live served empty ~40s (d41d8cd9) until the corrected PUT landed. Fixed immediately, live verified md5-matched. Lesson: never argv-pass bulk base64 — write to /tmp file, split with python reading the file, and ALWAYS verify window.__b64.length == expected before PUT.

## QA learnings
- sfx.tick scheduler sits behind the windG guard: wind starts on startscreen click — in QA call document.getElementById('startscreen').click() first (also unlocks AudioContext; ac shows 'running').
- Boss attack states decay intensity fast; iai strike triggers slowmo which scales dt under QA.step — for sustained-intensity tests use windup_spin, re-assert state+zero slowmo/hitstop every 60 steps, player parked far (z=18).
- Counters for audio QA: window.__plucks, window.__taikos, window._qaTones, window.__windDbg.
