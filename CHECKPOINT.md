# CHECKPOINT — M81 shipped, verified live + File preview

## M81 (Sep 24, gen 41 live / File gen 42)
- Armored shade (wave 3): minion rig gains armor plate group (chest/back/shoulder boxes + pale band, hidden until armored). Dead minion respawns armored (hp 80) 4.5s after lancer dies. Cut 1 on armor = crack (plates drop, 砕 kanji, clank, hitstop, no hp dmg); cut 2 damages.
- Lancer shield BLOCKS frontal cuts outright (dmg 0, posture chips .5x, clank); counter/perfect-dodge riposte pierces. cleanCutLanded only when dmg>0. New sfx.clank voice.
- Verified numerically on live (armor crack hp80→80 plates hidden, cut2 hp73; frontal block hp90 posture 100→60 earlier stage; unguarded full dmg; counter pierces; armored respawn fires) and on File preview (QA.attack: cracked hp80, damaged hp73, blocked hp90 posture chipped).
- QA artifact (not a bug): staged foes must be frozen (thinkT=999) and staged+measured in ONE evaluate; page rAF consumes staged state between calls. File build exposes state via QA.G/QA.player/QA.minion/QA.lancer, attacks via QA.attack(), states are 'atk'-prefixed with ATK table + stamina gate (set p.stam=100).
- Security delta: PASS (no secrets, 0 outbound, pinned three@0.160.0, no new sinks).
- Frames: desktop /downloads/cloud-browser-20260923-195304.png, 390px /downloads/cloud-browser-20260923-195344.png (also issen-file/preview-m81.png).
