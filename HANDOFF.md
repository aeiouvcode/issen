# HANDOFF
- Deploy path: GitHub web editor in the signed-in cloud-browser session (token never enters sandbox). Replace doc via cmTile.view.dispatch, commit through the UI dialog, verify repo md5 via contents API, then live md5.
- Verify: live https://aeiouvcode.github.io/issen/ md5 must equal local /home/sandbox/issen/index.html md5 (currently 068396b06f587611eaac7d4d25586003).
- QA hooks: QA.G.timeScale small freezes; QA.attack() fires a strike; QA.arcs tracks live slash ribbons; real click needed for startOrRetry; File preview content lease ~60s - grab iframe src fast.
