# CURRENT_TASK — M99 (shipped 2026-09-24 ~19:08 IST)
Mobile-optimization cycle 2 (mobile leads per user steering 9/24 18:24; playtest feedback 18:30).
- CDN: three.module.js -> three.module.min.js (1.27MB -> 670KB raw, 255KB -> 166KB br), same pinned 0.160.0, fresh SRI sha384 hash. Verified game boots live.
- Touch targets (pointer:coarse only): mute/engine seals 42->48px (enginebtn right 70->76px), chapter seals 44->52px, stance seals 34->44px, wider gaps. Desktop unchanged.
- Reference audit: vignette deepened toward reference burned-edge look (.62->.70 at 68%, start 30->26%, corner .94->.95).
- File build: vendor-three.js replaced with the minified build too (1.27MB -> 670KB).
Live md5: 262ee826940eab1319ebb33aa9e8a490. File gen 60 published (PRIVATE).
Audit findings standing: ground stipple density still lighter than reference; grass stroke patches thinner than ref; smoke puffs on dash exist in ref, partial in ours.
NEXT (M100): distance-to-reference top item (ground stipple density / grass stroke patches), prInfo full-fight behavior note (cloud GPU too slow to exercise stepper - needs real phone), mute-seal hit area on real phone playtest.
