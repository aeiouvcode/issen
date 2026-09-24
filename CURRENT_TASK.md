# CURRENT TASK — M107 (shade readability + leap puff chain) SHIPPED; next: M108
Updated: 2026-09-25 3:36 AM IST
Standing: distance-to-reference audit every cycle; mobile (390px) leads; hourly parent batching; no mid-build reports.
Shipped M107: (1) minion shade readability - uPaper lerp .82->.62, internal gray wash strokes survive the dark, reads at 390px. (2) Boss leap now trails discrete round ink puffs along the arc (every .11s, k .15-.95, tint 0x6f6653) - matches ref-8 shape language; ribbon stays. (3) Puff default life .85->1.05s so hits read on phones.
QA: mobile minion close-up PASS (wash variation visible), leap chain verified by probe (puff count grows 4->8 along arc) + frozen mid-leap frame, desktop 1280 PASS (coarse=false, no touch buttons), console 200 msgs 0 errors. Security: 4+/2- delta, clean.
Deployed: repo + live md5 fd8f3dc109b1535ca1aeb241eff7b3d9. Published File gen 68 (preview preview-m107.png).
M108 queue: re-audit. Leads: slash arcs read as zigzag walls when caught edge-on at low pitch (consider ground-hugging arc fade or flatten); boss dark-side stroke variation; grass band density vs ref-6; hit-smoke puff size vs ref-6 round clouds.
