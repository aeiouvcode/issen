# CURRENT TASK — M95 (done), next M96

## M95 shipped (Sep 24, ~4:45 PM IST)
- Audit first: M94 camera + ground changes verified holding in real fights at desktop + 390px.
  Arena-wall watch-item at phone width: PASS. Burned down a recurring "white-out" scare:
  (a) one lease had a genuinely lost WebGL context, (b) screenshots right after long
  synchronous sims catch un-presented frames. Not a code bug; gl.isContextLost() separates them.
- Fix: HUD bars now brush strokes. `.brushbar .fill` mask gradient replaced with a tapered
  clip-path polygon (thin at both ends, thick middle) like the reference's hand-painted bars.
  Verified live at desktop (1440) + 390px: partial and full bars read as painted strokes.
- Security delta scan PASS (one CSS block changed; no scripts, no outbound, no sinks).
  File details panel confirms "External services: None".
- File gen 56 published; preview smoke PASS (QA boots in the revision frame, fight runs,
  tapered bars present).

## M96 candidates (pick by audit)
- Figure interior brushwork (dry-brush streaks inside silhouettes) - deep shader work;
  assess risk first, prototype behind a uniform.
- Arena-wall horizon line polish at phone width.
- Fresh distance-to-reference audit may surface something higher.
