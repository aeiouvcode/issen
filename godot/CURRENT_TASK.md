# Current task

Godot 4 (Compatibility / WebGL2) take on the ISSEN ground truth: sensonoken's "Thousands Layered Blade: Reforged" sumi-e action RPG footage (https://x.com/sensonoken/status/2100371695727198244). ISSEN on `main` stays in Three.js; this branch (`godot-take`) is the Godot build.

## Goal
Close the gaps ISSEN can't: hand-animated brushwork silhouettes, ragged dry-brush strokes, dense grass swaths, ink-wash vignette.

## Acceptance (per cycle)
- Side-by-side distance-to-reference audit at desktop and 390px, blunt gap list, fixes in priority order
- Web export boots with no console errors, only same-origin requests, strict CSP meta
- State files updated, one commit per logical change, delta secret scan clean
- Deploy to Pages only on Main's go

## Roadmap (Naksh 10:19 PM: "All features need working on"; blade feel keeps the lead)
1. Blade feel - parry window, slow-mo finisher, ink-splash kills (ongoing)
2. Enemy variety - spear types forcing different slash angles, armored foes needing two cuts (C19: armored ronin)
3. A boss - one multi-phase duel per chapter (C22: Kageyama, 2 phases, every 8 kills)
4. Progression - chapter map with unlockable blade stances (C23: map overlay, Kasumi/Tsubame/Iwa, saved)
5. Sound - full SFX pass + sparse shamisen/taiko loop reacting to combat (code-synthesized, low levels, soft highs)
6. Store-ready - Play listing, icon, screenshots, publishable v1.0 (C24: draft listing + art in godot/store; submission needs Naksh: Play Console account, contact email, privacy URL)

## Non-goals (until asked)
- Replacing ISSEN on main
- Deploys (web or APK) without Naksh's go, relayed per release
- Engagement / dopamine mechanics
