# HANDOFF
- Deploy path: GitHub web UI in the signed-in cloud-browser session only (token never enters sandbox). Upload widget mangles names - use the editor: /edit/main/index.html, select-all + paste full content, commit. Verify repo md5 via contents API, then live md5.
- Verify: live https://aeiouvcode.github.io/issen/ md5 must equal local /home/sandbox/issen/index.html md5 (currently 55fdd5274a2d88801679cbeb0fd693ed).
- QA hooks: QA.G.timeScale=0.02 freezes; real click for startOrRetry; File preview content lease ~60s - grab iframe src fast.
