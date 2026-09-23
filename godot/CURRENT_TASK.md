# Current task

Godot 4 (Compatibility / WebGL2) take on the ISSEN ground truth: sensonoken's "Thousands Layered Blade: Reforged" sumi-e action RPG footage (https://x.com/sensonoken/status/2100371695727198244). ISSEN on `main` stays in Three.js; this branch (`godot-take`) is the Godot build.

## Goal
Close the gaps ISSEN can't: hand-animated brushwork silhouettes, ragged dry-brush strokes, dense grass swaths, ink-wash vignette.

## Acceptance (per cycle)
- Side-by-side distance-to-reference audit at desktop and 390px, blunt gap list, fixes in priority order
- Web export boots with no console errors, only same-origin requests, strict CSP meta
- State files updated, one commit per logical change, delta secret scan clean
- Deploy to Pages only on Main's go

## Non-goals (until asked)
- Replacing ISSEN on main or touching the live Pages site
- Audio, progression, menus, save data
- Engagement / dopamine mechanics
