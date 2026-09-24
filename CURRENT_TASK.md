# CURRENT TASK — M91 (done), next M92

## M91 shipped (Sep 24, ~12:17 PM IST)
- Subject scale pass (the M90 lesson applied): player root 1.08, boss 1.10 (ch3 iron bulk stacks to
  1.188), minion .88->.95, lancer .94->1.0. Models carry the larger read; camera untouched.
- Verified live (md5 4b973aa7): scales read back via QA, frames desktop + 390px, no occlusion.
- Security delta scan PASS. File gen 52 published; preview smoke PASS (playerScale 1.08 in the File build).

## M92 candidates (pick by audit)
- Watch for reach/range feel after the scale-up: blades grew visually, hit ranges unchanged (by design) -
  if contact reads early/late in frames, nudge arc visuals not ranges.
- Fresh reference audit may surface something higher.
