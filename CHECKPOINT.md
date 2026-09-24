# CHECKPOINT — 2026-09-25 2:41 AM IST
Milestone: M106 SHIPPED (footstep ink + intro ghost-pass + bamboo depth haze).
Live: https://aeiouvcode.github.io/issen/ serves md5 20360d6edcdb0c53a271395122250fe0 (= repo = local).
File: file-01M326B85G08ZT1X3M6QWB72NX gen 67 published (rev filerevision-01M3AM2CNQPHRZYPBWR8FWRRS5, preview preview-m106.png). PRIVATE. URL https://files.instinct.com/file-01M326B85G08ZT1X3M6QWB72NX
Working copies: /home/sandbox/issen/index.html and /home/sandbox/issen-file/src/game-main.ts (identical M106; module extracted and node --check'd).
M106 techniques: intro-branch boss fade via boss._fadeMats (fI clamp .16-1 by camera-boss dist 1.6-3.4); stepDecals own array+cap (don't share the combat decals cap); inkStep displacement accumulator with alternating foot side; footstep rotation.z = yaw - PI/2 after rotation.x=-PI/2.
QA: QA.step(dt,n) deterministic stepper beats wall-clock polling; rAF throttled. File preview leases last 15 min - remint on 'Content lease expired'. set-viewport is lease-wide; verify innerWidth after change; reload page to resize the canvas.
Security: delta scan clean; CDN importmap untouched; no new outbound.
Next cycle: M107 = distance-to-reference re-audit (see CURRENT_TASK.md leads).
