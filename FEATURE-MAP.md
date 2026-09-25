# ISSEN (Godot take) - Feature Map

A sitemap of what the game does and how to reach each feature. Exists so vague bug
reports ("it feels choppy", "the map broke") can be matched to a system and a code path.
Update this file in the same commit whenever behavior changes.

Live: https://aeiouvcode.github.io/issen/godot/ (branch `main`); source on branch `godot-take`, game code under `godot/`.

## Controls
- Move: WASD or arrow keys. Touch: virtual joystick, left 45% of the screen.
- Attack: J or Enter. Touch: tap right side of the screen (outside the dodge button).
- Dodge: K, Space, or Shift. Touch: the round dodge button, right side.
- Mute: M key or the "sound" chip.
- Cycle stance: Q key, gamepad stance button, or the "stance" chip.
- Map: Tab key or the "map" chip. Tap/click the map to dismiss.

Code: `_input_map`, `_input`, `_move_input` in `scripts/main.gd`; touch UI in `_touch_redraw`.

## HUD chrome
- Timer plaque (top-left), player HP + stamina bar (bottom), per-foe HP bars, boss bar (during boss).
- Chips row (top-right): sound, stance, map, credits, web.
- Banner flashes for unlocks/chapter titles.
- Rendering: static chrome bakes into an offscreen SubViewport (1 draw/frame); dynamic fills/labels/timer draw live. `scripts/hud_canvas.gd`, `scripts/chips_canvas.gd`, `_hud*` / `_sv_update` in `scripts/main.gd`.

## Combat systems
- Attack chains: consecutive attacks build combo; whiffing breaks the chain and locks attack briefly.
- Stamina: each swing costs stamina (HUD sliver); exhausted swings are denied.
- Parry: attacking a foe blade during its window (`PARRY_WIN` + stance bonus) deflects and staggers the foe.
- Posture/poise: foe windup/swing shrugs off light cuts; posture break staggers.
- Finisher: 5 clean hits in a row without taking damage (or a riposte) triggers a slow-mo finisher.
- Code: `scripts/fighter.gd` (combatant state machine), combat constants and `_resolve_*` in `scripts/main.gd`.

## Stances
- Kasumi (balanced), Tsubame (fast, wider parry), Iwa (slow, heavy, breaks armor).
- Unlocked by clearing chapters (stance i unlocks at best_chapter >= i). Cycling a locked stance shows a banner hint.
- `STANCES` const, `_cycle_stance`, `_stance_label` in `scripts/main.gd`.

## Progression
- 5 chapters: Grass sea, Bamboo ford, Ash temple, Snow pass, Castle of blades. Each has its own field palette.
- Foes walk in from screen sides; after `CHAPTER_KILLS * (chapter+1)` kills the field clears and the boss walks in alone.
- Chapter clear: map opens with an ink-travel animation to the next stop, palette blends, new-stance note, chapter title card.
- Save: best_chapter + stance in a ConfigFile at the user save path (skipped in autoplay/no-save).
- `_chapter_cleared`, `_show_map_travel`, `_load_save`/`_write_save` in `scripts/main.gd`.

## Boss (Kageyama, chapter-end duel)
- 4 HP phases. Habit model reads press aggression (landed + stuffed attempts, 4s decay), opener cadence, and dodge side.
- Phase 3: mirrors the player's opener and shades their habitual dodge side.
- Phase 4: reads attack cadence; a stillness beat + glint is the tell before a clash punish; over-aggression gets baited into whiff-stagger.
- Deliberate pauses clear the habit read.
- `_spawn_boss`, `_boss_phase2/3/4` in `scripts/main.gd`.

## Menus and overlays
- Map: chapter path with cleared stops; opens automatically after a clear, or via Tab/chip.
- Credits: "credits" chip; pauses the game; lists engine, font, and Android licenses.
- Web: "web" chip opens the hand-built web ISSEN (https://aeiouvcode.github.io/issen/) in a new tab.
- `_menu_chips`, `_show_map`, `_show_credits` in `scripts/main.gd`.

## FX and audio
- Slash arcs: MultiMesh pools (2 textures), per-instance progress/life/flip/tint via INSTANCE_CUSTOM (`shaders/slash.gdshader`, `scripts/fx.gd`).
- Ink-splash kills, chapter palettes, grass field (`shaders/`).
- All sound synthesized in code (`scripts/sfx.gd`).

## QA / dev entry points (not user-facing)
- Run flags: `--autoplay`, `--autoplay-boss`, `--autoplay-combo`, `--autoplay-pattern [--mash|--phase3|--phase4|--seed]`, `--autoplay-chips`, `--autoplay-parry`, `--autoplay-foe`, `--autoplay-armor`, `--autoplay-spear`, `--autoplay-twin`, `--autoplay-bow`, `--perf`, `--probe-nohud`.
- Export build: `./build.sh` (import, web export, CSP hash injection into index.html).
- Visual verification: Godot Movie Maker mode (see HANDOFF.md "Capture method").
