class_name InkFX
extends Node3D
## Ink effects: sweeping slash curtains, splatter bursts, lingering ground stains, dodge ghosts.

var blots: Array[Texture2D] = []
var drips: Array[Texture2D] = []
var specks: Array[Texture2D] = []
var slash_tex: Array[Texture2D] = []
var dab_tex: Texture2D
var cloud_tex: Texture2D
var red_tex: Texture2D
var slash_shader: Shader
var quad: QuadMesh
var items: Array = []   # {node, kind, t, life, vel, ...}
const MAX_STAINS := 240
var stains: Array = []

func _ready() -> void:
	for i in 6:
		blots.append(load("res://art/blot%d.png" % i))
	for i in 3:
		drips.append(load("res://art/drip%d.png" % i))
		specks.append(load("res://art/speck%d.png" % i))
	slash_tex = [load("res://art/slash0.png"), load("res://art/slash1.png")]
	dab_tex = load("res://art/dab.png")
	cloud_tex = load("res://art/cloud.png")
	red_tex = load("res://art/redblot.png")
	slash_shader = load("res://shaders/slash.gdshader")
	quad = QuadMesh.new()
	quad.size = Vector2(4.6, 2.3)
	quad.center_offset = Vector3(0, 1.15, 0)

func slash(pos: Vector3, facing: float, scale_k := 1.0, dur := 0.32, red := 0.0, variant := 0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	var m := ShaderMaterial.new()
	m.shader = slash_shader
	m.set_shader_parameter("tex", slash_tex[variant % 2])
	m.set_shader_parameter("flip", 1.0 if facing < 0.0 else 0.0)
	m.set_shader_parameter("prog", 0.0)
	m.set_shader_parameter("life", 1.0)
	m.set_shader_parameter("tint", red)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3.ONE * scale_k
	add_child(mi)
	mi.global_position = pos
	items.append({"node": mi, "kind": "slash", "t": 0.0, "dur": dur, "mat": m})

func _billboard(tex: Texture2D, px: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return s

func burst(pos: Vector3, dir: float, power := 1.0, red := 0.25) -> void:
	# central bloom: a dense black cloud of many overlapping blots, clustered toward the
	# middle, holding full ink before drying out (reference bloom is black, not grey)
	for i in 3:
		var w := _billboard(dab_tex, 0.02 * power * randf_range(0.8, 1.2))
		w.modulate = Color(0.45, 0.43, 0.42, 0.55)
		add_child(w)
		w.global_position = pos + Vector3(randfn(0.0, 0.25) + dir * 0.3, randfn(0.0, 0.2), 0.08)
		w.rotation.z = randf() * TAU
		items.append({"node": w, "kind": "bloom", "t": 0.0, "dur": randf_range(0.5, 0.75), "s0": w.pixel_size})
	for i in int(34 + 30 * power):
		var s := _billboard(blots[3 + randi() % 3] if randf() < 0.6 else blots[randi() % 3], 0.0026 * power * randf_range(0.4, 1.2))
		s.modulate = Color(0.55, 0.52, 0.5)
		add_child(s)
		var off := Vector2(randfn(0.0, 0.45), randfn(0.0, 0.4))
		s.global_position = pos + Vector3(off.x + dir * 0.2, off.y, 0.1 + randf() * 0.05)
		s.rotation.z = randf() * TAU
		items.append({"node": s, "kind": "bloom", "t": 0.0, "dur": randf_range(0.45, 0.8), "s0": s.pixel_size})
	# flying ink: many fine specks, streaking drips aligned to their flight, a few fat drops.
	# All land as stains, so a fight leaves a dense splattered floor like the reference.
	for i in int(150 * power):
		var r := randf()
		var tex: Texture2D
		var px: float
		var kind := "drop"
		if r < 0.62:
			tex = specks[randi() % 3]; px = randf_range(0.0028, 0.0085)
		elif r < 0.8:
			tex = drips[randi() % 3]; px = randf_range(0.0013, 0.0028); kind = "drip"
		else:
			tex = blots[3 + randi() % 3]; px = randf_range(0.0018, 0.0038)
		var s := _billboard(tex, px * (1.0 + power * 0.25))
		if randf() < red:
			s.modulate = Color(0.75, 0.1, 0.1)
		add_child(s)
		s.global_position = pos + Vector3(randf_range(-0.35, 0.35), randf_range(-0.4, 0.5), 0)
		# radial spray biased along the cut, so the burst reads as a splash, not speed lines
		var a := randf() * TAU
		var sp := randf_range(1.0, 6.5)
		var v := Vector3(cos(a) * sp + dir * randf_range(0.5, 3.5), sin(a) * sp * 0.8 + 2.0, randf_range(-2.5, 2.5))
		items.append({"node": s, "kind": kind, "t": 0.0, "vel": v})

## Dash puff: an inked cloud left where the dodge started; swells and fades.
func puff(pos: Vector3) -> void:
	var s := _billboard(cloud_tex, 0.0062)
	s.modulate = Color(1, 1, 1, 0.85)
	add_child(s)
	s.global_position = pos + Vector3(0, 0.7, -0.3)
	items.append({"node": s, "kind": "puff", "t": 0.0, "dur": 0.9, "s0": s.pixel_size})

## Dash trail: small upright black ink dabs stepping along the dodge path.
func dash_mark(pos: Vector3, k := 0.5) -> void:
	# k = dodge progress 0..1: marks grow along the dash like the reference's stepping dabs
	var s := _billboard(blots[randi() % 3], lerpf(0.0036, 0.0062, k) * randf_range(0.9, 1.1))
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.scale = Vector3(0.7, 2.1, 1.0)
	s.modulate = Color(0.7, 0.7, 0.7)
	add_child(s)
	s.global_position = pos + Vector3(randf_range(-0.08, 0.08), lerpf(0.3, 0.5, k), 0.0)
	items.append({"node": s, "kind": "mark", "t": 0.0, "dur": 1.6})

## Hit mark: a red ink blot that blooms on the struck figure's body, then fades.
func red_mark(f: Node3D, h := 1.5) -> void:
	var s := _billboard(red_tex, 0.0095)
	s.modulate = Color(1, 1, 1, 0.95)
	s.render_priority = 2
	s.no_depth_test = true
	f.add_child(s)
	s.position = Vector3(randf_range(-0.15, 0.15), h + randf_range(-0.2, 0.2), 0.4)
	s.rotation.z = randf() * TAU
	items.append({"node": s, "kind": "redmark", "t": 0.0, "dur": 0.55, "s0": s.pixel_size})

func ghost(src: Sprite3D, pos: Vector3) -> void:
	var s := Sprite3D.new()
	s.texture = src.texture
	s.hframes = src.hframes
	s.vframes = src.vframes
	s.frame = src.frame
	s.flip_h = src.flip_h
	s.offset = src.offset
	s.pixel_size = src.pixel_size
	s.billboard = src.billboard
	s.shaded = false
	s.modulate = Color(0.35, 0.33, 0.32, 0.55)
	add_child(s)
	s.global_position = pos + Vector3(0, 0, -0.05)
	items.append({"node": s, "kind": "ghost", "t": 0.0, "dur": 0.4})

func stain(pos: Vector3, size: float, tex: Texture2D = null, col := Color(1, 1, 1, 0.8), rot := INF) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex if tex else blots[randi() % 6]
	s.axis = Vector3.AXIS_Y
	s.pixel_size = size
	s.shaded = false
	s.modulate = col
	s.rotation.y = randf() * TAU if rot == INF else rot
	s.scale = Vector3(1.0, 1.0, 0.6)
	add_child(s)
	s.global_position = Vector3(pos.x, 0.015 + randf() * 0.01, pos.z)
	stains.append({"node": s, "t": 0.0, "a": col.a})
	if stains.size() > MAX_STAINS:
		var old = stains.pop_front()
		old["node"].queue_free()
	return s

func footprint(pos: Vector3) -> void:
	stain(pos, randf_range(0.003, 0.0045), dab_tex, Color(1, 1, 1, 0.85))

func _process(delta: float) -> void:
	var keep: Array = []
	for it in items:
		it["t"] += delta
		var n: Node3D = it["node"]
		match it["kind"]:
			"slash":
				var k: float = it["t"] / it["dur"]
				var m: ShaderMaterial = it["mat"]
				m.set_shader_parameter("prog", clampf(k * 1.8, 0.0, 1.0))
				m.set_shader_parameter("life", clampf(1.0 - maxf(0.0, k - 0.45) / 0.9, 0.0, 1.0))
				if k > 1.4:
					n.queue_free(); continue
			"bloom":
				var k2: float = it["t"] / it["dur"]
				var s: Sprite3D = n
				s.pixel_size = it["s0"] * (1.0 + k2 * 0.45)
				s.modulate.a = clampf(1.8 - k2 * 1.8, 0.0, 1.0)
				if k2 >= 1.0:
					n.queue_free(); continue
			"drop", "drip":
				var v: Vector3 = it["vel"]
				v.y -= 16.0 * delta
				it["vel"] = v
				n.global_position += v * delta
				if it["kind"] == "drip":
					# head leads, tail trails along screen-space velocity; stretch with speed
					var s3: Sprite3D = n
					s3.rotation.z = atan2(v.y, v.x)
					s3.scale = Vector3(clampf(0.5 + Vector2(v.x, v.y).length() * 0.07, 0.5, 1.1), 1.0, 1.0)
				if n.global_position.y <= 0.02:
					var s2: Sprite3D = n
					stain(n.global_position, s2.pixel_size * 1.1, s2.texture, Color(s2.modulate.r, s2.modulate.g, s2.modulate.b, 0.75))
					n.queue_free(); continue
			"fling":
				var vf: Vector3 = it["vel"]
				vf.y -= 16.0 * delta
				it["vel"] = vf
				n.global_position += vf * delta
				if n.global_position.y <= 0.02:
					var sf: Sprite3D = n
					var st_ := stain(n.global_position, it["sz"], sf.texture, Color(1, 1, 1, it["a"]), it["rot"])
					if it["rot"] != INF:
						st_.scale = Vector3(1.0, 1.0, 0.45)
					n.queue_free(); continue
			"cue":
				var fc = it["f"]
				if not is_instance_valid(fc) or fc.state != "stagger":
					n.queue_free(); continue
				var sc: Sprite3D = n
				var beat := 0.5 + 0.5 * cos(it["t"] * TAU * 3.0)
				sc.pixel_size = it["s0"] * (0.85 + beat * 0.3)
				sc.modulate.a = clampf(it["t"] * 8.0, 0.0, 1.0) * (0.55 + beat * 0.45)
			"puff":
				var kp: float = it["t"] / it["dur"]
				var sp_: Sprite3D = n
				sp_.pixel_size = it["s0"] * (1.0 + kp * 0.5)
				sp_.modulate.a = 0.85 * clampf(1.4 - kp * 1.4, 0.0, 1.0)
				n.global_position.y += delta * 0.3
				if kp >= 1.0:
					n.queue_free(); continue
			"mark":
				var km: float = it["t"] / it["dur"]
				(n as Sprite3D).modulate.a = clampf(1.6 - km * 1.6, 0.0, 1.0)
				if km >= 1.0:
					n.queue_free(); continue
			"redmark":
				var kr: float = it["t"] / it["dur"]
				var sr: Sprite3D = n
				sr.pixel_size = it["s0"] * (0.6 + minf(kr * 4.0, 1.0) * 0.6)
				sr.modulate.a = 0.95 * clampf(1.5 - kr * 1.5, 0.0, 1.0)
				if kr >= 1.0 or not is_instance_valid(n):
					n.queue_free(); continue
			"ghost":
				var k3: float = it["t"] / it["dur"]
				(n as Sprite3D).modulate.a = 0.55 * (1.0 - k3)
				if k3 >= 1.0:
					n.queue_free(); continue
		keep.append(it)
	items = keep
	for st in stains:
		st["t"] += delta
		if st["t"] > 9.0:
			var sp: Sprite3D = st["node"]
			sp.modulate.a = st["a"] * clampf(1.0 - (st["t"] - 9.0) / 6.0, 0.0, 1.0)

## C15 parry: a pale flash of crossed steel - a tight spray of fine specks and two thin strokes.
func clash(pos: Vector3, dir: float, power := 1.0) -> void:
	for i in int(40 * power):
		var sp := _billboard(specks[randi() % 3], randf_range(0.002, 0.005))
		sp.modulate = Color(0.2, 0.18, 0.16)
		add_child(sp)
		sp.global_position = pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0.12)
		var a := randf() * TAU
		var v := Vector3(cos(a), sin(a) * 0.9 + 0.4, 0) * randf_range(2.0, 6.0)
		items.append({"node": sp, "kind": "drop", "t": 0.0, "vel": v})
	slash(pos + Vector3(0, -0.6, 0), dir, 0.7 * power, 0.22, 0.0, 0)
	slash(pos + Vector3(0, -0.6, 0), -dir, 0.6 * power, 0.22, 0.0, 1)

## C15 kill: ink thrown along the cut - a trail of ground splats that thins out with distance,
## plus a heavy pool under the body.
func kill_splash(pos: Vector3, dir: float, power := 1.0) -> void:
	var d := dir if dir != 0.0 else 1.0
	stain(pos + Vector3(d * 0.3, 0, 0.3), 0.014 * power, null, Color(1, 1, 1, 0.85))
	# C17: the trail starts past where the body slides to rest (~0.6 m), runs on the camera side
	# of the body line (+z) so the falling figure can't cover it, and is flung: each splat flies
	# as a drop and lands a beat later, so the eye follows the cut outward.
	var n := int(11 * power)
	for i in n:
		var k := float(i + 1) / n
		var at := pos + Vector3(d * (1.0 + k * 2.6 * power) + randfn(0.0, 0.15), 0, 0.35 + k * 0.4 + randfn(0.0, 0.18))
		var sz := lerpf(0.011, 0.0035, k) * randf_range(0.8, 1.2) * power
		# C20: the far end of the trail lands as dragged streaks pointing along the cut
		var streak := k > 0.55
		var sp := _billboard(drips[randi() % 3] if streak else blots[randi() % 6], sz * (0.9 if streak else 0.6))
		sp.modulate = Color(1, 1, 1, 0.9)
		add_child(sp)
		var t := 0.12 + k * 0.28
		var h0 := 1.0
		sp.global_position = pos + Vector3(d * 0.2, h0, 0.2)
		var v := (at - sp.global_position) / t
		v.y = (0.02 - h0 + 8.0 * t * t) / t
		items.append({"node": sp, "kind": "fling", "t": 0.0, "vel": v, "sz": sz * (1.7 if streak else 1.0), "a": lerpf(0.9, 0.6, k), "rot": (0.0 if d > 0.0 else PI) + randfn(0.0, 0.12) if streak else INF})

var glint_tex: Texture2D

## C15 parry tell: a small four-point ink star with a red heart, drawn in code, popped above a
## foe the moment its blade enters the parry window.
func glint(f: Node3D, pos: Vector3) -> void:
	if glint_tex == null:
		var n := 128
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var u := (x - n * 0.5 + 0.5) / (n * 0.5)
				var v := (y - n * 0.5 + 0.5) / (n * 0.5)
				var r := sqrt(u * u + v * v)
				# astroid-like star: thin arms along the axes, thicker core
				var arm := maxf(1.0 - absf(u) * 14.0 * (0.2 + absf(v)), 1.0 - absf(v) * 14.0 * (0.2 + absf(u)))
				var a := clampf(maxf(arm, 1.0 - r * 3.2), 0.0, 1.0) * clampf((1.0 - r) * 3.0, 0.0, 1.0)
				var core := clampf(1.0 - r * 5.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.08 + core * 0.62, 0.06, 0.05, a))
		glint_tex = ImageTexture.create_from_image(img)
	var s := _billboard(glint_tex, 0.0065)
	s.render_priority = 2
	s.no_depth_test = true
	f.add_child(s)
	s.global_position = pos
	items.append({"node": s, "kind": "redmark", "t": 0.0, "dur": 0.3, "s0": s.pixel_size})

## C18 riposte cue: while a parried foe reels, the tell star stays by its sword arm and beats
## (3 per second), so the opening reads as "cut now". Gone the moment the stagger ends.
func riposte_cue(f: Node3D, big := false, at := Vector3(0, 2.1, 0.35)) -> void:
	if glint_tex == null:
		glint(f, f.global_position + Vector3(0, -50, 0))
	var s := _billboard(glint_tex, 0.0072 if big else 0.0058)
	s.render_priority = 2
	s.no_depth_test = true
	f.add_child(s)
	s.position = at
	items.append({"node": s, "kind": "cue", "t": 0.0, "f": f, "s0": s.pixel_size})

## C19 armor: lacquer shards - flat grey-black flakes that tumble off and land as small stains.
func shards(pos: Vector3, dir: float, power := 1.0) -> void:
	for i in int(14 * power):
		var sp := _billboard(blots[randi() % 6], randf_range(0.0022, 0.004))
		sp.modulate = Color(0.34, 0.35, 0.39)
		sp.scale = Vector3(1.0, randf_range(0.35, 0.6), 1.0)
		sp.rotation.z = randf() * TAU
		add_child(sp)
		sp.global_position = pos + Vector3(randf_range(-0.2, 0.2), randf_range(-0.3, 0.3), 0.15)
		var v := Vector3(dir * randf_range(1.0, 4.0), randf_range(1.5, 4.5), randf_range(-0.8, 0.8))
		items.append({"node": sp, "kind": "drop", "t": 0.0, "vel": v})
	for k in 2:
		slash(pos + Vector3(0, -0.5, 0), dir if k == 0 else -dir, 0.45 * power, 0.18, 0.0, k)
