# CURRENT TASK — M90 (done), next M91

## M90 shipped (Sep 24, ~10:40 AM IST)
- Camera: mild pitch trim only (target clamp .85-1.18 -> .84-1.15). Distance left at 9.0/10.6 -
  a first attempt at 8.4/10.0 overshot badly (player kasa filled the frame and occluded the boss);
  tested live, reverted within the cycle, re-verified. Reference characters read larger mostly
  because its models are bigger, not because its camera is closer.
- Security delta scan PASS. File gen 51 published; preview smoke PASS.
- Reference frames re-fetched after a workspace wipe (api.fxtwitter.com/sensonoken/status/2100371695727198244 -> 1276x720 mp4 -> ffmpeg).

## M91 candidates (pick by audit)
- Subject scale: if the reference's larger read still matters, scale the MODELS slightly rather than
  moving the camera (camera is tuned; models are cheap to scale).
- Fresh reference audit may surface something higher.
