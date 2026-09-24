# CURRENT_TASK — M98 (shipped 2026-09-24 ~18:35 IST)
Mobile-optimization cycle (user steering 18:24) + engine switcher (user steering 18:24:50) + touch-control enlargement (user playtest feedback 18:30).
- Adaptive DPR: coarse-pointer cap 1.5 (desktop 2, light 1); EMA frame-time stepper in rAF: <45fps steps pixelRatio down .25 (floor 1), >57fps steps up. QA.prInfo() exposes {prNow, cap, ema}.
- Engine switcher: 換 seal button top-right (next to 音), click+touchstart -> ./godot/. Verified live: navigates to /issen/godot/.
- Touch controls enlarged per user's phone playtest: atk 76->98px, dodge/heal 64->84px, fonts 26->32/32->40, joystick 110->140px, knob 40->52, travel 40->52.
Live md5: 091ded1b258f09f7cf9b8fa2b2f15f5e. File gen 59 published (PRIVATE).
NEXT (M99): mobile continues - measure prInfo on real phone playtest, touch-target audit of remaining UI (chapter select buttons, mute/engine 42px seals), load-size audit (three.js CDN payload), then audit-first distance-to-reference candidates.
