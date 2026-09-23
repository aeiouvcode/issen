# CURRENT_TASK — ISSEN rebuild (M80 shipped)

## Milestone: M80 — blade-feel trio closed (graded parry + universal ink trails)
Shipped Sep 24, 2026 ~12:32 AM IST. Live md5 44ced7d52727e232a484e94ad7f537fc. Instinct File gen 41.

### Built
- Graded parry: perfect read (eta <=.12s) = full clash (crossed strokes, ink spray, 捌 kanji, hitstop .14 + slowmo .3, counterT .8 steadied riposte); late catch (.12-.22s) = deflect + reel with smaller FX (single stroke, hitstop .09, NO slowmo)
- Ink-splash kills for ALL kills: normal minion/lancer kills now leave a 2-splat ink trail along the cut + the standing pool; finisher keeps the deep 3-trail + 1.5x pool version
- doCutParry(f, eta) signature; strikeEta unchanged

### Verified on live (numeric, QA.step, one-call staging + calm)
- early (eta .5): no parry / perfect (eta .10): reel + slowmo .3 + counterT .8 + 2 arcs / late (eta .18): reel + slowmo 0 + 1 arc / feint: no parry
- normal kill: dead + 3 new decals (pool + 2 trail)
- File preview exercised: perfect and late grades both reproduce in the File build

### Security (delta scan): PASS
No secrets, zero outbound calls in file, CDN pinned three@0.160.0 (importmap), no new HTML sinks.

## Roadmap (user 10:19 PM: all features in parallel, blade feel leads)
1. Blade feel: CLOSED trio M78-M80 (parry, finishers, grading). Tuning from feel remains.
2. NEXT M81: enemy variety - armored foe needing two cuts + spear variant forcing different slash angles
3. M82: sound pass - SFX tune + sparse shamisen/taiko-style reactive loop
4. M83+: progression (chapter map + unlockable stances), then store-ready assets
