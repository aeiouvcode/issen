# Task spec: ISSEN distance-to-reference rebuild

## Goal

Single-file three.js sumi-e duel that reads like sensonoken's "Thousands Layered Blade: Reforged" reference footage (https://x.com/sensonoken/status/2100371695727198244), playable on phone first.

## References

- https://x.com/sensonoken/status/2100371695727198244 - the visual reference: towering vertical ink-wash slash arcs, wet-ink figures with dry-brush highlights, parchment ground with dash speckle, grass swaths, strong mottled edge vignette, rolled-scroll timer plaque, brush-stroke health bars
- /tmp/research-archive/projects/issen.md - archived trait list and known gaps

## Acceptance criteria

- [ ] Every cycle: side-by-side audit vs reference at 390px + desktop, blunt findings list, fixes in priority order
- [ ] Slash arcs read as dominant vertical ink curtains (reference frame 0.5s)
- [ ] No geometry reads as an artifact (bamboo poles, seams, floating props)
- [ ] Ship only after visual verification on the deployed build

## Non-goals

- Hand-animated brushwork silhouettes (rigged 3D characters stay; biggest known residual gap)
- New UI libraries or external assets

## Findings

| ID | Finding | Severity | Status |
| --- | --- | --- | --- |
| F-01 | Player slash arcs lie flat on the ground; reference arcs tower vertically | high | fixed in M65 |
| F-02 | Timer is plain text; reference uses a rolled-scroll plaque | medium | fixed in M66 |
| F-03 | Edge vignette weaker than reference's dark mottled wash | medium | fixed in M66 |
| F-04 | Grass reads as sparse tufts; reference has dense swaths | medium | fixed in M67 |
| F-05 | Hit sparks read as red butterflies; reference uses dark ink splatter | medium | fixed in M66+M67 |
| F-06 | Lone bamboo stalk planes (8-11 tall) read as pole artifacts | high | fixed in M65 |
| F-07 | Boss kasa still dominates frame at close range | low | open |
| G-01 | Figures read as smooth shaded 3D, not wet-ink mass with dry-brush | high | improved in M68 (uBand/uDry pools+streaks); still mid-tone heavy vs reference's graphic black-on-pale contrast - open |
| G-03 | Slash arc band edges too clean; reference edges are ragged/wispy | medium | improved in M68 (edgeN ragged edges); still smoother than reference - open |
| G-04 | Reference robes are pale paper with bold black accent shapes; ours are mid-tan gradients | high | open - next cycle |

## Definition of done

- [ ] All acceptance criteria evidenced
- [ ] Diff reviewed
- [ ] Live URL verified, screenshots at desktop and 390px
- [ ] Checkpoint and handoff updated
