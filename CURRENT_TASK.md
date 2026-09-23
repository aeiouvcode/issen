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
| F-07 | Boss kasa still dominates frame at close range | low | improved in M72 (kasa paper 0xd9d2bd, bias 1.58, floor .30 - reads as brushed ink w/ pale streaks, not a tan mushroom); size/tilt still open |
| G-01 | Figures read as smooth shaded 3D, not wet-ink mass with dry-brush | high | improved in M68 (uBand/uDry pools+streaks); still mid-tone heavy vs reference's graphic black-on-pale contrast - open |
| G-03 | Slash arc band edges too clean; reference edges are ragged/wispy | medium | improved M68+M69 (2-octave edgeN torn edges); close to reference now - watch, low residual |
| G-04 | Reference robes are pale paper with bold black accent shapes; ours are mid-tan gradients | high | fixed in M69 (pale robe + black hem read verified on deployed build) |
| G-05 | Camera sits lower than reference's high top-down follow cam; ground not the canvas | medium | fixed M69 (.40->.55) + M70 (pitch floor .85, dist 9.0/10.6 - near-overhead duel framing like ref-4.5) |
| G-06 | Reference fields multiple foes with their own health bars; ours is a single boss | medium | stage 1 fixed M70 (shade); stage 2 fixed M72 (the lancer: round spiked shield + long spear, guard halves frontal dmg, 3.9-reach thrust, wave-two spawn 4s after the shade falls, hp90/posture70 vs shade's 70/50 - distinct maxes like ref's 109/105) |
| G-08 | Ground speckle far sparser than reference's dense washi dash texture | high | fixed in M71 (thresholds .74/.83 + .79/.87, mask floors .45/.38, inkAmt .72) |
| G-09 | Shade read gray-mud, not the reference's bold black ink mass; its slash arc was muddy brown-red, off the sumi palette | high | fixed in M71 (uPaper lerp .82 toward 0x0d0a06; slash arc red 0 = ink; telegraph ring .55->.42) |

## Definition of done

- [ ] All acceptance criteria evidenced
- [ ] Diff reviewed
- [ ] Live URL verified, screenshots at desktop and 390px
- [ ] Checkpoint and handoff updated
