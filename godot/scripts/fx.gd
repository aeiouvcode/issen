class_name InkFX
extends Node3D
## Ink effects: sweeping slash curtains, splatter bursts, lingering ground stains, dodge ghosts.

var blots: Array[Texture2D] = []
var slash_tex: Array[Texture2D] = []
var dab_tex: Texture2D
var slash_shader: Shader
var quad: QuadMesh
var items: Array = []   # {node, kind, t, life, vel, ...}
const MAX_STAINS := 70
var stains: Array = []

func _ready() -> void:
	for i in 6:
		blots.append(load("res://art/blot%d.png" % i))
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
	# central bloom: a few big blots that swell and dry out
	for i in int(10 + 8 * power):
		var s := _billboard(blots[randi() % 6], 0.009 * power * randf_range(0.6, 1.3))
		add_child(s)
		s.global_position = pos + Vector3(randf_range(-1.0, 1.0), randf_range(-0.8, 0.9), 0.1)
		s.rotation.z = randf() * TAU
		items.append({"node": s, "kind": "bloom", "t": 0.0, "dur": randf_range(0.35, 0.6), "s0": s.pixel_size})
	# flying droplets that land as stains
	for i in int(80 * power):
		var tex := blots[3 + randi() % 3] if randf() < 0.6 else blots[randi() % 3]
		var s := _billboard(tex, randf_range(0.0012, 0.0045) * (1.0 + power * 0.3))
		if randf() < red:
			s.modulate = Color(0.75, 0.1, 0.1)
		add_child(s)
		s.global_position = pos + Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.6), 0)
		var v := Vector3(dir * randf_range(0.5, 6.0) + randf_range(-2.0, 2.0), randf_range(0.5, 5.0), randf_range(-2.5, 2.5))
		items.append({"node": s, "kind": "drop", "t": 0.0, "vel": v})

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
				s.pixel_size = it["s0"] * (1.0 + k2 * 0.7)
				s.modulate.a = clampf(1.3 - k2 * 1.3, 0.0, 1.0)
				if k2 >= 1.0:
					n.queue_free(); continue
			"drop":
				var v: Vector3 = it["vel"]
				v.y -= 16.0 * delta
				it["vel"] = v
				n.global_position += v * delta
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
