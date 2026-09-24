# CURRENT TASK — M105 (character ink figures) SHIPPED; next: M106
Updated: 2026-09-25 1:20 AM IST
Standing: distance-to-reference audit every cycle; mobile (390px) leads; hourly parent batching; no mid-build reports.
Shipped M105: both fighters rebuilt as brush-stroke figures. New builders strokeGeo (ragged pressure-tapered stroke tube, smooth value-noise silhouette, frayed bristle tail) and stripGeo (torn flat strip, S-sway, mirrored back-layer verts with reversed winding - never gl_FrontFacing, it blackens the kasa). Player: limb/torso strokes, 5 hakama strips, 3 hair locks. Boss: arm strokes + 6 vertical robe wash strips (robeM uHem .5). Minion/lancer inherit via shared buildBoss.
QA: 390px idle/attack/bow close-ups PASS; boss lit/shadow sides PASS; minion PASS; desktop fresh tab PASS (no touch buttons, coarse=false). Security sweep PASS (155-line delta, geometry only).
Deployed: repo + live md5 361f463238828a07cb632132d189ca65. Published File gen 66 (preview preview-m105.png).
M106 queue: 1) ground ink pooling under combatants (feet-contact splats that accumulate + fade), 2) bamboo depth haze (back layers desaturate/lighten with distance). Then full distance-to-reference re-audit.
