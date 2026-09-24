# HANDOFF
- Deploy path: GitHub web UI upload at /aeiouvcode/issen/upload/main in the signed-in cloud-browser session only. Token never enters sandbox.
- Verify: live md5 must equal local index.html md5 after deploy.
- QA hooks: QA.G.timeScale=0.02 freezes; real click needed for startOrRetry; File preview content lease ~60s — grab iframe src fast.
