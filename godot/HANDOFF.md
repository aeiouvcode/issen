# Handoff

## Resume here
Cycle 23: chapter map + three blade stances with save data (--autoplay-map). Chapters have names on the map but the field art does not change per chapter yet. Next: C24 store assets (icon, feature graphic, screenshots, listing copy), then per-chapter ground/grass palettes and the owed sprite bake.
Cycle 22: multi-phase boss Kageyama (every 8 kills, parry/riposte to break him, phase 2 at half HP adds thrusts; --autoplay-boss). Next: C23 chapter map + unlockable blade stances (save data), C24 store assets. Owed in the next sprite bake: armored ronin with plates, spear rig with a yari, a distinct boss rig. Cycles 18-21: riposte cue, armored and spear ronin, reactive taiko/shamisen music, kill trail streaks. Source only since the 10:02 PM web refresh (main fa7bbfd).
Cycle 16: perfect/late parry tiers, spawn hold after finishers, chip/bar overlap fix. Cycle 15 (Naksh: blade feel leads; 6:52 PM amended: keep the improvement cycle running alongside): parry window, slow-mo finisher, ink-splash kills in source; not yet in an APK or on the web. Cycle 14: v0.12 - F-27 credits/licenses screen and a sound mute chip (M key), APK v0.12 (versionCode 2, same key, installs over v0.11) and web refresh on Naksh's go. Signing keystore + password are backed up in the vault (agent entries "ISSEN APK signing keystore file (base64)" and "ISSEN APK signing keystore password (alias issen)"). Cycle 13: F-22 closed (depth foes 0.8 m off axis, camera swings sideways to keep them apart). Procedural sound added (scripts/sfx.gd, no audio assets). APK v0.11 shipped as a GitHub pre-release (tag godot-apk-v0.11, branch apk) and audited read-only (no permissions, only launcher + DUMP-guarded profileinstaller receiver exported, not debuggable, v2+v3 self-signed). Audit gaps: keystore has no backup, no in-game license/credits screen. Cycle 11: F-24 and F-26 done (depth kill readable, fresh kills stay framed). Cycle 10 done: F-21 (sprite sheets split into <=2048 px pages), F-23 (turned death captured). First Pages preview deployed at /issen/godot/ on Naksh's go (main:/godot/ holds only the web export; source stays on godot-take). Open gaps, priority order:
3. F-25 Real older-Android device check still not done (only the texture size rule is enforced).

## Android APK
- `./build_android.sh` (see header for env). Tooling: Godot 4.5.2 Android templates (from the official export_templates.tpz), JDK 17 (Temurin), Android SDK build-tools 35.0.0 + platform 35 via sdkmanager. Editor settings file `~/.config/godot/editor_settings-4.5.tres` sets android_sdk_path and java_sdk_path.
- Signing: self-signed release keystore (alias `issen`) generated in the agent workspace, NOT in the repo. The workspace is ephemeral: if the keystore is lost, the next APK has a different signature and Android will refuse to update in place - uninstall the old app first. Keep one keystore per release line if updates matter.
- Output: export_android/issen.apk (gitignored). Package com.aeiouvcode.issen, minSdk 24, GLES3 required, no permissions.
- Not tested on a real device or emulator.

## Deploy
Pages serves main root. The Godot preview lives in main:/godot/ (index.html, index.js, index.wasm, index.pck, worklets, icons). Redeploy only on Main's go; commit with base_tree so the Three.js files on main are untouched, non-force ref update.

## Capture method (use this, not Playwright timing)
`printf '[display]\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720\n' > override.cfg` then
`xvfb-run -a -s "-screen 0 1400x1000x24" $GODOT --path . --rendering-driver opengl3 --write-movie /tmp/mv/f.png --fixed-fps 30 --quit-after 125 -- --autoplay` (or `-- --autoplay-views` / `--autoplay-depth` / `--autoplay-foe`) and delete override.cfg (never commit it). Frames 30-60 cover the first combo.

## Build
- Godot 4.5.2 stable + web templates (nothreads variant, Pages-safe, no COOP/COEP needed).
- `cd godot && ./build.sh` (set GODOT=path). Art is baked: `cd godot/tools && python3 bake_sprites.py player && python3 bake_sprites.py ronin && python3 bake_fx.py` (numpy + Pillow).
- QA: serve godot/export, drive with Playwright + /usr/bin/google-chrome (swiftshader); frame rates there are meaningless.

## Blocked
- Nothing blocked. Not deployed; Pages deploy waits for Main's go.

## Failed approaches
| Approach | Why it failed | Date |
| --- | --- | --- |
| Fixed-sleep Playwright screenshots to catch attack frames | Swiftshader screenshots take ~1 s; the whole 0.3 s attack plays between shots | 2026-09-23 |
| Opaque dark curtain at 1.45-1.8x scale | A black crescent covering the screen with a hard rectangular cut from the quad edge | 2026-09-23 |
| Default 844x390 stretch base | HUD shrank to ~45% on portrait phones; now 480x400 base | 2026-09-23 |
| CJK glyphs on HUD rings | Engine default font has no CJK, rendered as tofu boxes | 2026-09-23 |
| Long fast drip streaks thrown along the cut | Read as horizontal speed lines, not splatter; now radial spray, short streaks, stretch capped 1.1x | 2026-09-23 |
| Bigger bloom blots at full ink | Read as black rocks; replaced with soft wash dabs + many small blots | 2026-09-23 |
| Tinting black ink blots red via modulate | Modulate multiplies the near-black ink, so the mark stayed black; baked a red blot texture instead | 2026-09-23 |
| Per-vertex random jitter for blots | Spiky star shapes, not ink drops; switched to low-harmonic radius | 2026-09-23 |
| Sine-stack fibres for slash texture | Read as clean concentric rings; replaced with random radial profile x arc noise | 2026-09-23 |

## Discoveries
- Godot Compatibility renderer: hint_screen_texture works in canvas_item post shaders; MODEL_MATRIX is per-instance in MultiMesh so Y-billboard grass works in a spatial shader.
- Sprite3D flip: foot pixel sits 10 px left of centre, so offset.x must be 10 * facing.
