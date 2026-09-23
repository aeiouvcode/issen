# CURRENT_TASK — ISSEN rebuild (M79 shipped)

## Milestone: M79 — finishers (blade feel leads)
Shipped Sep 23, 2026 ~10:04 PM IST. Live md5 5d76e68152696d57749dfd1cffcd74f3. Instinct File gen 40.

### Built
- Reeling-kill finisher: killing a guard-broken (reeling) minion/lancer escalates - slow beat (.55), camera push-in (G.camPush, low and close), wide finishing stroke, ink splat trail along the cut (3 groundSplats) + deep pool (1.5x), 断 kanji (severed clean)
- 5-clean-cut streak beat: consecutive landed cuts (G.cleanStreak) - the 5th triggers slowmo .5 + camera push + soft tink; taking a hit resets the streak
- cleanCutLanded() shared helper; camera push hook in updateCamera (dist -16%, height dip while camPush>0)
- Boss kill keeps its own endgame cinematic (斬) - reel-finisher applies to minion/lancer
- Parry window kept at .22s (verified; tuning from feel noted honestly)

### Verified on live (numeric, QA.step, decay-neutralized)
- Reeling kill: parried -> dead, camPush .58 fired, 5 new decals (trail+pool)
- 5th clean cut: streak 4 -> 0, camPush fired, hit landed
- Hit taken: streak 3 -> 0 reset
- File preview exercised: full parry -> reeling kill -> camPush sequence fires in File build
- Frames: desktop finisher (断 over wide stroke), 390px clash with camera push

### Security (delta scan): PASS
No secrets, zero outbound calls in file, CDN pinned three@0.160.0 (importmap), no new HTML sinks.

## Next (M80 candidates)
- Ink-splash kill effects for non-reeling kills (currently only finishers get trail+pool)
- Parry window/clash FX tuning from feel
- Improvement cycle: robe mid-tone pooling, arc wash center alpha, balance pass, sound tuning
- User bar (9:35 PM): beat the reference, and accelerate
