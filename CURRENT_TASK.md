# CURRENT_TASK — ISSEN rebuild (M78 shipped)

## Milestone: M78 — cut-press parry (blade feel leads)
Shipped Sep 23, 2026 ~8:29 PM IST. Live md5 ae88fa819b5de17512a675207a89beb2. Instinct File gen 39.

### Built
- strikeEta(f): continuous ETA to a foe's true strike from state+stateT; feints return Infinity (a lie invites the swing, never the parry)
- doCutParry(f): cancels the pending hit, foe enters 'reel' (guard broken ~1s), ink spray + two crossed pale slashArcs + 捌 kanji, hitstop .14s + slowmo .3s, sfx.parry (softened highs per sound bar)
- doAttack parry check: true strike landing inside .22s from a foe within 4.2u deflects; the swing continues as riposte (normal stamina)
- 'reel' state on boss/minion/lancer (1.0s -> idle/approach); reuses stagger pose in all three anim fns
- Damage: reeling foes take 2x (3x with perfect-dodge counter), lancer shield guard disabled while reeling
- Dodge-read perfect dodge in hurtPlayer untouched (remains the defensive layer)

### Verified on live (numeric, QA.step)
- Out-of-window press: no parry, normal swing
- In-window press: reel + 0 dmg taken + hitstop + slowmo
- Feint in window: no parry
- Riposte on reeling minion: 12 = 2x base 6
- Clash FX screenshotted desktop + 390px (crossed strokes + kanji + reeling foe read at both widths)
- File preview exercised: parry fires in the File build

### Security (delta scan): PASS
No secrets, no outbound calls anywhere in file, CDN pinned three@0.160.0 (importmap, no SRI possible - unchanged posture), no new innerHTML sinks.

## Next (M79 candidates)
- Finisher: slow-mo kill on reeling foe (G.slowmo + camera push), ink-splash kill effects
- Parry window tuning from feel (.22s vs reference)
- Improvement cycle continues: robe mid-tone pooling, arc wash center alpha, balance pass, sound tuning
