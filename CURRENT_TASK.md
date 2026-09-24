# CURRENT TASK — M89 (done), next M90

## M89 shipped (Sep 24, ~9:05 AM IST)
- Sound: taiko accents in the reactive loop - hot phrases (intense > .75) can open with a low
  taiko pulse (vol .07, sine 105->44 + lowpassed noise). Verified on live: 3 taikos + 16 plucks
  over ~73s of hot sim (G.slowmo forces windIntensity=1). Sparse by design.
- Visual: ground dash field denser (s3t .78->.745, dash weight .12+.18tv -> .16+.20tv) toward the
  reference's speckled ink ground. Confirmed on desktop + 390px frames.
- Security delta scan PASS. File gen 50 published; preview smoke incl. taiko counter PASS.
- Note: QA staging needs G.slowmo=99999 + p.hp refresh per step or the player dies and the mix gate closes.

## M90 candidates (pick by audit)
- Camera framing: reference duels read closer/larger than ours. Careful, small step only.
- Fresh reference audit may surface something higher.
