# Checkpoint

- 2026-09-23 M1: offline brush baker (tools/brush.py): bristle strokes that run dry toward the tail, wet-edge washes, ragged blots. Deterministic per seed.
- 2026-09-23 M1: side-view rigs (tools/figures.py) + keyframed poses (tools/bake_sprites.py). Player: idle/run/atk1-3/dodge/hit/die (47 frames). Ronin (kasa + naginata): idle/walk/windup/swing/recover/hit/die (38 frames). Every frame re-drawn with its own seed so the line boils like hand animation.
- 2026-09-23 M1: VFX + HUD textures (tools/bake_fx.py): curtain slash sweeps, blots, grass clumps, footprint dab, scroll plaque, ring, bar stroke.
- 2026-09-23 M1: Godot project: parchment ground shader with stippled flecks + distance haze, 3 multimesh grass swath layers (Y-billboard, wind sway, alpha scissor), Y-billboard Sprite3D fighters, sweeping slash shader, ink bursts that land as ground stains, dodge ghosts + footprints, post pass (paper grain, ink-wash vignette, hurt tint).
- 2026-09-23 M1: duel loop: 3-hit combo with hit-stop and shake, dodge with i-frames, ronin AI (approach / windup / swing / recover / stagger / die), escalating respawns up to 3 foes, death + restart. Keyboard, mouse, gamepad, touch joystick + buttons.
- 2026-09-23 M1: web export verified in headless Chrome at 1280x720 and 390x844: boot ~3-4 s local, 0 console errors, only same-origin requests, CSP meta with hashed inline script.
