class_name InkFX
extends Node3D
## Ink effects: sweeping slash curtains, splatter bursts, lingering ground stains, dodge ghosts.

var blots: Array[Texture2D] = []
var drips: Array[Texture2D] = []
var specks: Array[Texture2D] = []
var slash_tex: Array[Texture2D] = []
var dab_tex: Texture2D
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

func stain(pos: Vector3, size: float, tex: Texture2D = null, col := Color(1, 1, 1, 0.8)) -> void:
	var s := Sprite3D.new()
	s.texture = tex if tex else blots[randi() % 6]
	s.axis = Vector3.AXIS_Y
	s.pixel_size = size
	s.shaded = false
	s.modulate = col
	s.rotation.y = randf() * TAU
	s.scale = Vector3(1.0, 1.0, 0.6)
	add_child(s)
	s.global_position = Vector3(pos.x, 0.015 + randf() * 0.01, pos.z)
	stains.append({"node": s, "t": 0.0, "a": col.a})
	if stains.size() > MAX_STAINS:
		var old = stains.pop_front()
		old["node"].queue_free()

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
