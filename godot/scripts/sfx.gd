class_name Sfx
extends Node
## Every sound is synthesized at startup from noise and sine: no audio assets.
## Levels stay low and highs are rolled off (one-pole low-pass) so nothing is harsh.

const RATE := 44100
var sounds := {}
var pool: Array[AudioStreamPlayer] = []
var next := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 11
	sounds["swing"] = _wav(_sweep(0.22, 900.0, 2600.0, 0.0), -13.0)
	sounds["swing_heavy"] = _wav(_sweep(0.30, 600.0, 2000.0, 0.0), -11.0)
	sounds["foe_swing"] = _wav(_sweep(0.34, 350.0, 1200.0, 0.0), -12.0)
	sounds["hit"] = _wav(_impact(0.26, 95.0, 0.55), -9.0)
	sounds["hit_heavy"] = _wav(_impact(0.40, 70.0, 0.7), -7.5)
	sounds["hurt"] = _wav(_impact(0.32, 60.0, 0.45), -9.0)
	sounds["kill"] = _wav(_kill(), -8.0)
	sounds["parry"] = _wav(_ring(0.35), -16.0)
	sounds["parry_perfect"] = _wav(_ring(0.7), -12.5)
	sounds["finisher"] = _wav(_finish(), -8.0)
	sounds["patter"] = _wav(_patter(), -19.0)
	sounds["armor"] = _wav(_clack(0.16, 420.0), -14.0)
	sounds["armor_break"] = _wav(_clack(0.34, 300.0), -11.0)
	sounds["dodge"] = _wav(_sweep(0.26, 1400.0, 500.0, 0.0), -16.0)
	var wind := AudioStreamPlayer.new()
	wind.stream = _wav(_wind(6.0), -24.0, true)
	wind.volume_db = -24.0
	add_child(wind)
	wind.play()
	for i in 8:
		var a := AudioStreamPlayer.new()
		add_child(a)
		pool.append(a)

func play(name: String, pitch_jitter := 0.06) -> void:
	if not sounds.has(name):
		return
	var a := pool[next]
	next = (next + 1) % pool.size()
	var s: Array = sounds[name]
	a.stream = s[0]
	a.volume_db = s[1]
	a.pitch_scale = 1.0 + rng.randf_range(-pitch_jitter, pitch_jitter)
	a.play()

# --- synthesis -------------------------------------------------------------

## C19: blade on lacquered armor - a dull wooden clack (body resonance + short damped noise),
## no metallic ring and nothing above the 3.2 kHz roll-off.
func _clack(dur: float, f0: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array(); out.resize(n)
	var y := 0.0
	var k := 1.0 - exp(-TAU * 1800.0 / RATE)
	for i in n:
		var t := float(i) / RATE
		y += k * (rng.randf_range(-1.0, 1.0) - y)
		var body := sin(TAU * f0 * t) * 0.8 + sin(TAU * f0 * 1.52 * t) * 0.35
		out[i] = (body * exp(-t * 22.0) + y * exp(-t * 60.0) * 1.4) * 0.9
	return out

## C17: wet ink landing - a loose run of soft, dull ticks (1.2 kHz low-pass, no clicks) that
## thin out, matching the flung kill trail hitting the ground.
func _patter() -> PackedFloat32Array:
	var n := int(0.5 * RATE)
	var out := PackedFloat32Array(); out.resize(n)
	var t0 := 0.0
	for j in 11:
		var st := int(t0 * RATE)
		var amp := lerpf(1.0, 0.3, j / 10.0) * rng.randf_range(0.7, 1.0)
		var ln := int(rng.randf_range(0.012, 0.03) * RATE)
		var y := 0.0
		var k := 1.0 - exp(-TAU * 1200.0 / RATE)
		for i in ln:
			if st + i >= n:
				break
			y += k * (rng.randf_range(-1.0, 1.0) - y)
			var e := sin(PI * float(i) / ln)
			out[st + i] += y * e * amp * 2.2
		t0 += rng.randf_range(0.02, 0.05)
	return out

## Air through cloth: noise through a low-pass whose cutoff glides from f0 to f1.
func _sweep(dur: float, f0: float, f1: float, _unused: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array(); out.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / n
		var fc := lerpf(f0, f1, sin(t * PI))
		var k := 1.0 - exp(-TAU * fc / RATE)
		y += k * (rng.randf_range(-1.0, 1.0) - y)
		var env := pow(sin(t * PI), 1.6)
		out[i] = y * env * 1.6
	return out

## Blade meeting body: a falling sine thump under a short dark noise burst.
func _impact(dur: float, f: float, noise: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array(); out.resize(n)
	var ph := 0.0
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += TAU * f * (1.0 + 1.5 * exp(-t * 30.0)) / RATE
		y += 0.18 * (rng.randf_range(-1.0, 1.0) - y)
		var body := sin(ph) * exp(-t * 11.0)
		var crack := y * exp(-t * 38.0) * noise * 2.5
		out[i] = body * 0.9 + crack
	return out

## A kill: deeper thump, then a soft wet spatter tail.
func _kill() -> PackedFloat32Array:
	var a := _impact(0.5, 55.0, 0.8)
	var y := 0.0
	for i in a.size():
		var t := float(i) / RATE
		y += 0.12 * (rng.randf_range(-1.0, 1.0) - y)
		var grit := 1.0 if rng.randf() < 0.02 else 0.3
		a[i] += y * grit * 1.8 * exp(-pow((t - 0.12) * 9.0, 2.0))
	return a

## C15 parry: two inharmonic partials ring and die fast, over a short dull knock. Kept low and
## rolled off by _wav so the steel reads as a clean "tink", never a shriek.
func _ring(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array(); out.resize(n)
	var knock := _impact(0.12, 140.0, 0.3)
	for i in n:
		var t := float(i) / RATE
		var r := sin(TAU * 1180.0 * t) * 0.5 + sin(TAU * 1730.0 * t) * 0.32 + sin(TAU * 2410.0 * t) * 0.12
		out[i] = r * exp(-t * 9.0) * 0.55 + (knock[i] * 0.8 if i < knock.size() else 0.0)
	return out

## C15 finisher: a slow low cut through air, then the deep kill thump under it.
func _finish() -> PackedFloat32Array:
	var a := _sweep(0.5, 250.0, 900.0, 0.0)
	var k := _kill()
	var off := int(0.16 * RATE)
	a.resize(off + k.size())
	for i in k.size():
		a[off + i] += k[i] * 1.1
	return a

## Distant wind over grass: very dark noise with a slow swell, seamless loop.
func _wind(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array(); out.resize(n)
	var y := 0.0
	var y2 := 0.0
	for i in n:
		var t := float(i) / n
		y += 0.02 * (rng.randf_range(-1.0, 1.0) - y)
		y2 += 0.05 * (y - y2)
		out[i] = y2 * (0.6 + 0.4 * sin(t * TAU * 2.0)) * 9.0
	# crossfade the ends so the loop has no click
	var f := int(0.25 * RATE)
	for i in f:
		var w := float(i) / f
		out[i] = out[i] * w + out[n - f + i] * (1.0 - w)
	return out

func _wav(buf: PackedFloat32Array, db: float, loop := false) -> Variant:
	# final roll-off: two one-pole passes at 3.2 kHz (12 dB/oct) keep the top end soft
	var k := 1.0 - exp(-TAU * 3200.0 / RATE)
	for _p in 2:
		var y := 0.0
		for i in buf.size():
			y += k * (buf[i] - y)
			buf[i] = y
	db -= 3.0
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray(); data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.8, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = buf.size()
		return w
	return [w, db]
