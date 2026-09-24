# CURRENT TASK — M96 (done), next M97

## M96 shipped (Sep 24, ~5:31 PM IST)
- Audit first: side-by-side vs the reference showed the biggest remaining gap is figure
  interior brushwork. Reference fighters (light AND dark) carry visible dry-brush streaks
  inside their silhouettes; our dark masses (boss robe, hair, wraps) read too solid.
- Fix: two-scale dry-brush in the ink shader - broad raking streaks (uv.x*6) plus the
  existing fine splits, combined with max(); uDry raised robe .65->1.05, hair .5->.8,
  dark .45->.7, wrap .4->.62. The boss's kasa and robe now rake pale strokes through the
  ink mass like the reference's dark fighter.
- Verified live: desktop close-up (kasa streaks read hand-painted), 390px in-fight
  (touch buttons confirmed: body.coarse + in-fight shows #touchui; a mid-session viewport
  switch without reload hides them - test artifact, not a bug).
- Security delta scan PASS (shader lines + 4 material constants only).
- File gen 57 published; preview smoke PASS (bundle carries the new shader; fight runs).

## M97 candidates (pick by audit)
- Figure streak DIRECTION: reference streaks follow the garment flow (curved, parallel);
  ours are fbm blotches. Consider anisotropic streak field aligned to UV/limb direction.
- Grass tufts: reference has clumped brush-dab grass bands; ours are sparse. Density pass.
- Fresh distance-to-reference audit may surface something higher.
