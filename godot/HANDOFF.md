# Handoff

## Resume here
Cycle 36: ronin + variants ink-wash rebake (gap 2 done) - robes paler (body dens 0.7->0.3, sleeves -0.28), bold near-black hem band + collar cross + cuff accents, dry paper chest highlight; all six sheets rebaked (shared helpers, one pass). Verified at 1280x720 --autoplay. Next: gap 3 (stronger/warmer vignette corners), then gap 4 (splatter density around hits). Store submission still needs Naksh.
Cycle 35: player ink-wash rebake (gap 2, player first) - pale wash with texture/streaks and gradient pooling kept, bold near-black accents added at hakama hems and sleeve cuffs, dry paper highlight strokes, wet edge now breaks dry-brush when streak_dir is set, new wash(grad) + stroke(layer='fill') brush ops. Verified vs reference at 1280x720, 390x844 and --autoplay-depth (turned views clean). Next: same rebake for the ronin + variants (draw_ronin, draw_sleeve_dark, draw_leg_dark - reference robes are paler with bolder hem/collar accents), then gap 3 (warmer/darker vignette corners). Store submission still needs Naksh.
Cycle 27: adaptive launcher icons (godot/android_icons, Android preset) + blade drip after kills. The next APK picks up the new icon; building one waits for Naksh. Next: re-capture store screenshots with the new foe art, then the distance-to-reference gap list (blade feel first).
Cycle 26: foe variants baked (ronin_armor, ronin_spear, boss sheets; `python3 bake_sprites.py <kind>` in tools/). Next: C27 Android adaptive icon from store/icon-512 + blade-feel polish; store screenshots predate the new foe art and should be re-captured before submission.
Cycle 25: per-chapter field palettes (--autoplay-palettes) + camera kick on heavy cuts. Next: C26 sprite bake (armored plates, yari spear rig, distinct boss rig), C27 Android adaptive icon + blade-feel polish.
Cycle 24: store assets drafted in godot/store (listing.md, icon, feature graphic, 8 screenshots; regenerate with tools/bake_store.py + Movie Maker). Roadmap items 1-6 all have a first pass. Next: per-chapter field palettes, owed sprite bake (plates, yari, boss rig), Android adaptive icon from icon-512, blade-feel polish. Large binaries: the push bridge is a data: URL, keep each page under ~1.5 MB (one screenshot set per page).
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
Cycle 28: store screenshots re-captured with new foe art + perfect-parry paper-white wash. Next: distance-to-reference gap list (blade feel first). Store submission still needs Naksh (Play Console account, contact email, privacy URL).
Cycle 29: hit shiver on struck foes (runs through hit-stop). Next gap list: longer combo chains (4th cut / directional finisher), chapter-to-chapter map flow, then enemy variety. Store submission still needs Naksh.
Cycle 30: four-cut combo ending in the issen dash-through. Next gaps: chapter-to-chapter map flow, enemy variety, then a directional (up/down) finisher variant. Store submission still needs Naksh.
Cycle 31: map travel animation + chapter title card, and the noto sheath sound after a boss. Next gaps: enemy variety (a new foe type per chapter), directional finisher variant, then another reference audit. Store submission still needs Naksh.
Cycle 32: twin-blade foe + issen afterimages. Next gaps: directional finisher for 3/4 views, a bow/ranged foe for later chapters, then a fresh reference audit. Store submission still needs Naksh.
Cycle 33: directional falling finisher for 3/4 views + archer foe. Roster now: kasa ronin, armored, spear, twin-blade, archer, boss. Next: fresh distance-to-reference audit with side-by-side frames, then fix the top gaps. Store submission still needs Naksh.
Cycle 34: fresh distance-to-reference audit (yt-dlp frames vs Movie Maker captures at 1920x1080 + 390x844). Fixed top gap: ground stipple reworked from an all-over squashed-dash hatch to sparse round dots in drifting patches over clean parchment. Blade feel: heavy/riposte cuts scar the parchment (flat slash stroke, dries with the stains). Next: gap list below, top item first. Store submission still needs Naksh.

## Distance-to-reference gap list (C34 audit, ranked)
1. [done C34] Ground: was a uniform horizontal dash hatch everywhere; reference is clean parchment with sparse round stipple in patches. Fixed in shaders/ground.gdshader.
2. [done C35+C36] Figure rendering: flat fills -> ink-wash. Player (C35) and ronin + all variants (C36) rebaked: pale washes with texture/pooling, bold near-black accents at hems/cuffs/collar, dry paper highlights, ragged dry edges. Residual: authored animation fluidity is out of scope (non-goal).
3. Parchment vignette: reference has stronger burnt/umber edges and corners; ours is close but the corners could go darker and warmer.
4. Splatter: reference bursts sit denser around the hit with more mid-size blots; ours are close since C20/C34.
5. UI: reference carries three ink pips + a brush HP stroke under each fighter and a scroll timer plaque; ours adapts this (top-left plaque, bottom bar, skill rings) - acceptable divergence for playability.
6. Camera: reference holds a fixed side view; ours matches in landscape and adapts in portrait. OK.
