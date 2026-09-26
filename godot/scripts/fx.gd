class_name InkFX
extends Node3D
## Ink effects: sweeping slash curtains, splatter bursts, lingering ground stains, dodge ghosts.
##
## C52 perf: every ink quad (burst blooms, flying drops, drips, flings, puffs, dash
## marks, ground stains) lives in a per-texture MultiMesh pool instead of its own
## Sprite3D. A full hit burst used to cost ~200 nodes and ~200 draw calls; now the
## whole fight's ink is ~one draw call per texture (~10). Web WASM->GL call overhead
## is the frame-time bottleneck, so instance count is what matters. Figure-parented
## sprites (red marks, tell stars, ghosts) stay Sprite3D - there are only ever a few.

var blots: Array[Texture2D] = []
var drips: Array[Texture2D] = []
var specks: Array[Texture2D] = []
var slash_tex: Array[Texture2D] = []
var dab_tex: Texture2D
var cloud_tex: Texture2D
var red_tex: Texture2D
var slash_shader: Shader
var quad: QuadMesh
var cam: Camera3D   # set by main; billboard basis comes from here

var items: Array = []   # {kind, t, ...} - pooled entries carry {p, slot, px, pos, col, ...}
const MAX_STAINS := 240
var stains: Array = []

# per-texture MultiMesh pools: Texture2D -> {mm, n, cap, owners[]}
var pools := {}
var flat_quad: QuadMesh
var FLIP_B := Basis()
const POOL_CAP0 := 64

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
	flat_quad = QuadMesh.new()
	flat_quad.size = Vector2(1, 1)
	FLIP_B = Basis(Vector3(1, 0, 0), -PI / 2.0)

# ------------------------------------------------------------------ pools
func _pool(tex: Texture2D) -> Dictionary:
	var p: Dictionary = pools.get(tex, {})
	if not p.is_empty():
		return p
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = flat_quad
	mm.instance_count = POOL_CAP0
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 128.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mi.material_override = m
	add_child(mi)
	p = {"mm": mm, "n": 0, "cap": POOL_CAP0, "tex": tex, "owners": []}
	pools[tex] = p
	return p

func _alloc(tex: Texture2D) -> Dictionary:
	return _alloc_p(_pool(tex))

func _alloc_p(p: Dictionary) -> Dictionary:
	if p["n"] >= p["cap"]:
		var ncap: int = p["cap"] * 2
		p["mm"].instance_count = ncap   # grows the buffer, existing instances keep their data
		p["cap"] = ncap
	var slot: int = p["n"]
	p["n"] += 1
	p["mm"].visible_instance_count = p["n"]
	return {"p": p, "slot": slot}

func _free_slot(it: Dictionary) -> void:
	var p: Dictionary = it["p"]
	var slot: int = it["slot"]
	p["n"] -= 1
	var n: int = p["n"]
	if slot != n:
		var moved: Dictionary = p["owners"][n]
		p["mm"].set_instance_transform(slot, moved["xf"])
		if moved.has("cust"):
			p["mm"].set_instance_custom_data(slot, moved["cust"])
		else:
			p["mm"].set_instance_color(slot, moved["col"])
		p["owners"][slot] = moved
		moved["slot"] = slot
	p["owners"].resize(n)
	p["mm"].visible_instance_count = n

func _cam() -> Camera3D:
	if cam and is_instance_valid(cam):
		return cam
	return get_viewport().get_camera_3d()

func _write_bill(it: Dictionary) -> void:
	var tex: Texture2D = it["p"]["tex"]
	var u: float = tex.get_width() * it["px"] * it.get("sx", 1.0)
	var v: float = tex.get_height() * it["px"] * it.get("sv", 1.0)
	var b: Basis
	var c := _cam()
	if it.get("bb", 0) == 1 and c:
		# fixed-Y billboard: upright, yawed to face the camera
		var d: Vector3 = c.global_position - it["pos"]
		b = Basis(Vector3.UP, atan2(d.x, d.z))
	elif c:
		b = c.global_transform.basis
	else:
		b = Basis()
	if it.get("rot", 0.0) != 0.0:
		b = b * Basis(Vector3(0, 0, 1), it["rot"])
	b = b * Basis.from_scale(Vector3(u, v, 1.0))
	it["xf"] = Transform3D(b, it["pos"])
	it["p"]["mm"].set_instance_transform(it["slot"], it["xf"])
	it["p"]["mm"].set_instance_color(it["slot"], it["col"])

func _write_flat(st: Dictionary) -> void:
	var tex: Texture2D = st["p"]["tex"]
	var b := Basis(Vector3.UP, st["ry"]) * FLIP_B * Basis.from_scale(Vector3(tex.get_width() * st["px"] * st["sx"], tex.get_height() * st["px"] * st["sv"], 1.0))
	st["xf"] = Transform3D(b, st["pos"])
	st["p"]["mm"].set_instance_transform(st["slot"], st["xf"])
	st["p"]["mm"].set_instance_color(st["slot"], st["col"])

## C60 phase B: slash curtains pooled per texture (was one MeshInstance3D + own
## ShaderMaterial per swing - the biggest live 3D draw mass in combat). prog/life/
## flip/tint ride INSTANCE_CUSTOM; the slash shader billboards off MODEL_MATRIX,
## which is per-instance in a MultiMesh.
var slash_pools := {}

func _slash_pool(variant: int) -> Dictionary:
	var key := "slash%d" % variant
	var p: Dictionary = slash_pools.get(key, {})
	if not p.is_empty():
		return p
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = POOL_CAP0
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 128.0
	var m := ShaderMaterial.new()
	m.shader = slash_shader
	m.set_shader_parameter("tex", slash_tex[variant])
	mi.material_override = m
	add_child(mi)
	p = {"mm": mm, "n": 0, "cap": POOL_CAP0, "owners": []}
	slash_pools[key] = p
	return p

func _write_slash(it: Dictionary, prog: float, life: float) -> void:
	var b := Basis.from_scale(Vector3(it["sk"] * it["sxk"], it["sk"] * it["svk"], it["sk"]))
	it["xf"] = Transform3D(b, it["pos"])
	it["cust"] = Color(prog, life, 1.0 if it["flip"] else 0.0, it["tint"])
	it["p"]["mm"].set_instance_transform(it["slot"], it["xf"])
	it["p"]["mm"].set_instance_custom_data(it["slot"], it["cust"])

## Spawn one pooled ink quad. bb: 0 = face camera, 1 = fixed-Y upright.
func _blot(tex: Texture2D, px: float, pos: Vector3, col := Color(1, 1, 1, 1), bb := 0, rot := 0.0, sx := 1.0, sv := 1.0) -> Dictionary:
	var a := _alloc(tex)
	var it := {"p": a["p"], "slot": a["slot"], "px": px, "pos": pos, "col": col, "bb": bb, "rot": rot, "sx": sx, "sv": sv}
	a["p"]["owners"].append(it)
	_write_bill(it)
	return it

func slash(pos: Vector3, facing: float, scale_k := 1.0, dur := 0.32, red := 0.0, variant := 0) -> Dictionary:
	var p: Dictionary = _slash_pool(variant % 2)
	var a := _alloc_p(p)
	var it := {"p": p, "slot": a["slot"], "kind": "slash", "t": 0.0, "dur": dur,
		"pos": pos, "flip": facing < 0.0, "tint": red, "sk": scale_k, "sxk": 1.0, "svk": 1.0,
		"col": Color(1, 1, 1, 1)}
	p["owners"].append(it)
	_write_slash(it, 0.0, 1.0)
	items.append(it)
	return it

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
		var it := _blot(dab_tex, 0.02 * power * randf_range(0.8, 1.2), pos + Vector3(randfn(0.0, 0.25) + dir * 0.3, randfn(0.0, 0.2), 0.08), Color(0.45, 0.43, 0.42, 0.55), 0, randf() * TAU)
		it["kind"] = "bloom"; it["t"] = 0.0; it["dur"] = randf_range(0.5, 0.75); it["s0"] = it["px"]
		items.append(it)
	for i in int(40 + 32 * power):
		var tex: Texture2D = blots[3 + randi() % 3] if randf() < 0.6 else blots[randi() % 3]
		var off := Vector2(randfn(0.0, 0.36), randfn(0.0, 0.32))
		var it := _blot(tex, 0.0026 * power * randf_range(0.5, 1.3), pos + Vector3(off.x + dir * 0.2, off.y, 0.1 + randf() * 0.05), Color(0.55, 0.52, 0.5), 0, randf() * TAU)
		it["kind"] = "bloom"; it["t"] = 0.0; it["dur"] = randf_range(0.45, 0.8); it["s0"] = it["px"]
		items.append(it)
	# mid-size blots hugging the hit: reference bursts sit denser around the centre
	for i in int(12 + 10 * power):
		var moff := Vector2(randfn(0.0, 0.18), randfn(0.0, 0.16))
		var it := _blot(blots[3 + randi() % 3], 0.0042 * power * randf_range(0.7, 1.3), pos + Vector3(moff.x + dir * 0.15, moff.y, 0.12 + randf() * 0.05), Color(0.5, 0.47, 0.45), 0, randf() * TAU)
		it["kind"] = "bloom"; it["t"] = 0.0; it["dur"] = randf_range(0.5, 0.85); it["s0"] = it["px"]
		items.append(it)
	# flying ink: many fine specks, streaking drips aligned to their flight, a few fat drops.
	# All land as stains, so a fight leaves a dense splattered floor like the reference.
	for i in int(90 * power):
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
		var col := Color(1, 1, 1, 1)
		if randf() < red:
			col = Color(0.75, 0.1, 0.1)
		var it := _blot(tex, px * (1.0 + power * 0.25), pos + Vector3(randf_range(-0.35, 0.35), randf_range(-0.4, 0.5), 0), col)
		# radial spray biased along the cut, so the burst reads as a splash, not speed lines
		var a2 := randf() * TAU
		var sp := randf_range(0.8, 5.0)
		it["vel"] = Vector3(cos(a2) * sp + dir * randf_range(0.5, 3.5), sin(a2) * sp * 0.8 + 2.0, randf_range(-1.6, 1.6))
		it["kind"] = kind; it["t"] = 0.0
		items.append(it)

## Dash puff: an inked cloud left where the dodge started; swells and fades.
func puff(pos: Vector3) -> void:
	var it := _blot(cloud_tex, 0.0062, pos + Vector3(0, 0.7, -0.3), Color(1, 1, 1, 0.85))
	it["kind"] = "puff"; it["t"] = 0.0; it["dur"] = 0.9; it["s0"] = it["px"]
	items.append(it)

## Dash trail: small upright black ink dabs stepping along the dodge path.
func dash_mark(pos: Vector3, k := 0.5) -> void:
	# k = dodge progress 0..1: marks grow along the dash like the reference's stepping dabs
	var it := _blot(blots[randi() % 3], lerpf(0.0036, 0.0062, k) * randf_range(0.9, 1.1), pos + Vector3(randf_range(-0.08, 0.08), lerpf(0.3, 0.5, k), 0.0), Color(0.7, 0.7, 0.7), 1, 0.0, 0.7, 2.1)
	it["kind"] = "mark"; it["t"] = 0.0; it["dur"] = 1.6
	items.append(it)

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

func stain(pos: Vector3, size: float, tex: Texture2D = null, col := Color(1, 1, 1, 0.8), rot := INF) -> Dictionary:
	var a := _alloc(tex if tex else blots[randi() % 6])
	var st := {
		"p": a["p"], "slot": a["slot"], "px": size, "sx": 1.0, "sv": 0.6,
		"pos": Vector3(pos.x, 0.015 + randf() * 0.01, pos.z),
		"ry": randf() * TAU if rot == INF else rot,
		"col": col, "t": 0.0, "a": col.a, "nx": 9.0,
	}
	a["p"]["owners"].append(st)
	_write_flat(st)
	stains.append(st)
	if stains.size() > MAX_STAINS:
		_free_slot(stains.pop_front())
	return st

func footprint(pos: Vector3) -> void:
	stain(pos, randf_range(0.003, 0.0045), dab_tex, Color(1, 1, 1, 0.85))

## C34 blade feel: a landed heavy cut scars the parchment - the slash stroke laid flat
## along the cut line, stretched thin, drying out with the other stains.
func scar(pos: Vector3, dir: float, strong := false) -> void:
	var d := dir if dir != 0.0 else 1.0
	var s := stain(pos + Vector3(d * 0.55, 0, 0.28), 0.009 if strong else 0.0065, slash_tex[randi() % 2], Color(0.38, 0.36, 0.34, 0.6), 0.0 if d > 0.0 else PI)
	s["sx"] = 2.1 if strong else 1.6
	s["sv"] = 0.35
	_write_flat(s)

func _physics_process(delta: float) -> void:  # C55: was _process - physics interpolation warns on MultiMesh writes outside physics tick; sim rate matches camera tick
	var keep: Array = []
	for it in items:
		it["t"] += delta
		match it["kind"]:
			"slash":
				# C43: echoes hold at prog 0 until their delay passes
				var td: float = it["t"] - float(it.get("delay", 0.0))
				if td < 0.0:
					keep.append(it); continue
				var k: float = td / it["dur"]
				_write_slash(it, clampf(k * 1.8, 0.0, 1.0), clampf(1.0 - maxf(0.0, k - 0.45) / 0.9, 0.0, 1.0))
				if k > 1.4:
					_free_slot(it); continue
			"bloom":
				var k2: float = it["t"] / it["dur"]
				it["px"] = it["s0"] * (1.0 + k2 * 0.45)
				it["col"].a = clampf(1.8 - k2 * 1.8, 0.0, 1.0)
				if k2 >= 1.0:
					_free_slot(it); continue
			"drop", "drip":
				var v: Vector3 = it["vel"]
				v.y -= 16.0 * delta
				it["vel"] = v
				it["pos"] += v * delta
				if it["kind"] == "drip":
					# head leads, tail trails along screen-space velocity; stretch with speed
					it["rot"] = atan2(v.y, v.x)
					it["sx"] = clampf(0.5 + Vector2(v.x, v.y).length() * 0.07, 0.5, 1.1)
				if it["pos"].y <= 0.02:
					stain(it["pos"], it["px"] * 1.1, it["p"]["tex"], Color(it["col"].r, it["col"].g, it["col"].b, 0.75))
					_free_slot(it); continue
			"fling":
				var vf: Vector3 = it["vel"]
				vf.y -= 16.0 * delta
				it["vel"] = vf
				it["pos"] += vf * delta
				if it["pos"].y <= 0.02:
					var st := stain(it["pos"], it["sz"], it["p"]["tex"], Color(1, 1, 1, it["a"]), it["srot"])
					if it["srot"] != INF:
						st["sv"] = 0.45
						_write_flat(st)
					_free_slot(it); continue
			"cue":
				var n2: Node3D = it["node"]
				var fc = it["f"]
				if not is_instance_valid(fc) or fc.state != "stagger":
					n2.queue_free(); continue
				var sc: Sprite3D = n2
				var beat := 0.5 + 0.5 * cos(it["t"] * TAU * 3.0)
				sc.pixel_size = it["s0"] * (0.85 + beat * 0.3)
				sc.modulate.a = clampf(it["t"] * 8.0, 0.0, 1.0) * (0.55 + beat * 0.45)
			"puff":
				var kp: float = it["t"] / it["dur"]
				it["px"] = it["s0"] * (1.0 + kp * 0.5)
				it["col"].a = 0.85 * clampf(1.4 - kp * 1.4, 0.0, 1.0)
				it["pos"].y += delta * 0.3
				if kp >= 1.0:
					_free_slot(it); continue
			"mark":
				var km: float = it["t"] / it["dur"]
				it["col"].a = clampf(1.6 - km * 1.6, 0.0, 1.0)
				if km >= 1.0:
					_free_slot(it); continue
			"redmark":
				var n3: Node3D = it["node"]
				var kr: float = it["t"] / it["dur"]
				var sr: Sprite3D = n3
				sr.pixel_size = it["s0"] * (0.6 + minf(kr * 4.0, 1.0) * 0.6)
				sr.modulate.a = 0.95 * clampf(1.5 - kr * 1.5, 0.0, 1.0)
				if kr >= 1.0 or not is_instance_valid(n3):
					n3.queue_free(); continue
			"shed":
				var fs = it["f"]
				if not is_instance_valid(fs) or it["t"] > it["dur"]:
					it["node"].queue_free(); continue
				if it["t"] >= it["next"]:
					it["next"] += randf_range(0.06, 0.13)
					var tex: Texture2D = specks[randi() % 3] if randf() < 0.6 else blots[3 + randi() % 3]
					var col := Color(1, 1, 1, 1)
					if randf() < 0.3:
						col = Color(0.72, 0.1, 0.09)
					var d := _blot(tex, randf_range(0.0025, 0.0055), fs.tip_world() + Vector3(randf_range(-0.12, 0.12), randf_range(-0.1, 0.05), 0.02), col)
					d["kind"] = "drop"; d["t"] = 0.0
					d["vel"] = Vector3(randf_range(-0.4, 0.4), randf_range(-0.6, 0.3), randf_range(-0.2, 0.2))
					items.append(d)
			"ghost":
				var n4: Node3D = it["node"]
				var k3: float = it["t"] / it["dur"]
				(n4 as Sprite3D).modulate.a = 0.55 * (1.0 - k3)
				if k3 >= 1.0:
					n4.queue_free(); continue
		if it.has("slot") and it["kind"] != "slash":
			_write_bill(it)
		keep.append(it)
	items = keep
	for st in stains:
		st["t"] += delta
		if st["t"] > st["nx"]:
			# dry-out fade, stepped ~8 times a second instead of every frame
			st["nx"] = st["t"] + 0.12
			st["col"].a = st["a"] * clampf(1.0 - (st["t"] - 9.0) / 6.0, 0.0, 1.0)
			if st["col"].a <= 0.0:
				_free_slot(st)
				stains.erase(st)
			else:
				st["p"]["mm"].set_instance_color(st["slot"], st["col"])

## C15 parry: a pale flash of crossed steel - a tight spray of fine specks and two thin strokes.
func clash(pos: Vector3, dir: float, power := 1.0) -> void:
	for i in int(40 * power):
		var it := _blot(specks[randi() % 3], randf_range(0.002, 0.005), pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0.12), Color(0.2, 0.18, 0.16))
		var a := randf() * TAU
		it["vel"] = Vector3(cos(a), sin(a) * 0.9 + 0.4, 0) * randf_range(2.0, 6.0)
		it["kind"] = "drop"; it["t"] = 0.0
		items.append(it)
	slash(pos + Vector3(0, -0.6, 0), dir, 0.7 * power, 0.22, 0.0, 0)
	slash(pos + Vector3(0, -0.6, 0), -dir, 0.6 * power, 0.22, 0.0, 1)

## C43 blade feel: an issen kill leaves layered echo cuts - two thinner curtains staggered
## behind the main slash, so the one flash reads as several layered blades.
func echo(pos: Vector3, facing: float, scale_k := 0.85) -> void:
	for i in 2:
		slash(pos + Vector3(facing * (0.35 + 0.45 * i), 0.12 + 0.1 * i, -0.06 * (i + 1)), facing, scale_k * (0.92 - 0.14 * i), 0.34, 0.0, 1 - (i % 2))
		items[items.size() - 1]["delay"] = 0.07 + 0.08 * i

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
		var sp := _blot(drips[randi() % 3] if streak else blots[randi() % 6], sz * (0.9 if streak else 0.6), pos + Vector3(d * 0.2, 1.0, 0.2), Color(1, 1, 1, 0.9))
		var t := 0.12 + k * 0.28
		var v: Vector3 = (at - sp["pos"]) / t
		v.y = (0.02 - 1.0 + 8.0 * t * t) / t
		sp["vel"] = v
		sp["kind"] = "fling"; sp["t"] = 0.0
		sp["sz"] = sz * (1.7 if streak else 1.0)
		sp["a"] = lerpf(0.9, 0.6, k)
		sp["srot"] = (0.0 if d > 0.0 else PI) + randfn(0.0, 0.12) if streak else INF
		items.append(sp)

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
		var it := _blot(blots[randi() % 6], randf_range(0.0022, 0.004), pos + Vector3(randf_range(-0.2, 0.2), randf_range(-0.3, 0.3), 0.15), Color(0.34, 0.35, 0.39), 0, randf() * TAU, 1.0, randf_range(0.35, 0.6))
		it["vel"] = Vector3(dir * randf_range(1.0, 4.0), randf_range(1.5, 4.5), randf_range(-0.8, 0.8))
		it["kind"] = "drop"; it["t"] = 0.0
		items.append(it)
	for k in 2:
		slash(pos + Vector3(0, -0.5, 0), dir if k == 0 else -dir, 0.45 * power, 0.18, 0.0, k)

## C21 spear thrust: one straight dry stroke along the line of the thrust plus a few specks off the point.
func thrust(pos: Vector3, dir: float) -> void:
	for i in 9:
		var k := float(i) / 8.0
		var it := _blot(dab_tex, lerpf(0.0065, 0.003, k), pos + Vector3(dir * (0.6 + k * 3.4), randfn(0.0, 0.02), 0), Color(0.14, 0.12, 0.11, 0.9), 0, 0.0, 2.6, 0.28)
		it["kind"] = "mark"; it["t"] = -k * 0.05; it["dur"] = 0.3
		items.append(it)
	for i in 10:
		var d2 := _blot(specks[randi() % 3], randf_range(0.002, 0.004), pos + Vector3(dir * 4.0, 0, 0), Color(0.2, 0.18, 0.16))
		d2["vel"] = Vector3(dir * randf_range(1.0, 3.0), randf_range(0.5, 2.5), randf_range(-0.5, 0.5))
		d2["kind"] = "drop"; d2["t"] = 0.0
		items.append(d2)

## C45 blade feel: a slain foe breaks into ink - body-sized blots flung from head, chest
## and legs along the cut, so the figure reads as becoming ink instead of only falling.
func body_break(pos: Vector3, dir: float, power := 1.0) -> void:
	var d := dir if dir != 0.0 else 1.0
	var heights := [1.45, 1.1, 0.75, 0.4]
	for h0 in heights:
		for j in 2:
			var sz := randf_range(0.007, 0.012) * power
			var it := _blot(blots[randi() % 6], sz, pos + Vector3(randfn(0.0, 0.1), h0, 0.18), Color(1, 1, 1, 0.95))
			var k := randf_range(0.5, 1.0)
			var at := pos + Vector3(d * (0.7 + k * 1.8 * power) + randfn(0.0, 0.2), 0.0, 0.3 + randf_range(0.0, 0.35))
			var t := 0.16 + k * 0.26
			var v: Vector3 = (at - it["pos"]) / t
			v.y = (0.02 - h0 + 8.0 * t * t) / t
			it["vel"] = v
			it["kind"] = "fling"; it["t"] = 0.0
			it["sz"] = sz; it["a"] = 0.85; it["srot"] = INF
			items.append(it)

## C27 blade feel: after a kill the blade sheds ink - drops fall from the sword tip for a moment and stain the grass
func blade_drip(f: Node3D, dur := 0.8) -> void:
	var holder := Node3D.new()
	add_child(holder)
	items.append({"node": holder, "kind": "shed", "t": 0.0, "dur": dur, "next": 0.08, "f": f})
