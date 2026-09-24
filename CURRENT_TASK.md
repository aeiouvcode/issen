# CURRENT TASK — M94 (done), next M95

## M94 shipped (Sep 24, ~3:44 PM IST)
- Audit first: biggest remaining distance to the reference was the high top-down camera
  (reference sits low and close, fighters large) and the over-busy ground (reference leaves
  large bare paper).
- Fix 1 (camera): duel pitch clamp .84-1.15 -> .62-.94 (h ~5.9 close, ~7.6 far; dist unchanged
  at 9.0/10.6). Verified no kasa occlusion at d=2.6 worst case, desktop + 390px.
- Fix 2 (ground): speckle thresholds raised, amplitudes ~35% lower, inkAmt scale .72->.60.
  Much more bare paper; reads far closer to the reference.
- Security delta scan PASS (3 changed lines: shader constants + camera clamp only).
- File gen 55 published; preview smoke PASS (camPitch converges to .63 at close range).

## M95 candidates (pick by audit)
- HUD bars: reference uses tapered brush-stroke bars; ours are rounded rects.
- Figure interior brushwork (dry-brush streaks inside silhouettes) - deep shader work, high risk.
- Fresh reference audit may surface something higher.
