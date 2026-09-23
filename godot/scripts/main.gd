extends Node3D
## ISSEN Godot take: world, duel loop, camera, HUD and touch controls.

var cam: Camera3D
var fx: InkFX
var player: Fighter
var enemies: Array = []
var player_tex: Array[Texture2D] = []
var ronin_tex: Array[Texture2D] = []
var elapsed := 0.0
var combo := 0
var queued := false
var hit_done := false
var dodge_cd := 0.0
var foot_t := 0.0
var ghost_t := 0.0
var shake := 0.0
var spawn_t := 1.2
var kills := 0
var hud: CanvasLayer
var time_label: Label
var php_fill: Control
var php_label: Label
var pst_fill: Control
var ebars: Array = []
var post_mat: ShaderMaterial
var touch_ui: Control
var joy_id := -1
var joy_origin := Vector2.ZERO
var joy_vec := Vector2.ZERO
var joy_knob: Control
var joy_base: Control
var touch_atk := false
var touch_dodge := false
var hitstop := 0.0
var atk_buf := 0.0
var dodge_buf := 0.0
# Desktop QA only: `godot -- --autoplay` drives a fixed input timeline for Movie Maker captures.
# Web builds never receive user args, so this path is inert on Pages.
var autoplay := false
var auto_t := 0.0
var auto_steps := [[0.3, "right", true], [0.9, "right", false], [1.0, "attack"], [1.25, "attack"], [1.5, "attack"], [2.6, "dodge"], [3.3, "attack"], [3.55, "attack"], [3.8, "attack"], [5.0, "attack"], [5.25, "attack"], [5.5, "attack"]]
var banner: Label

func _ready() -> void:
	autoplay = "--autoplay" in OS.get_cmdline_user_args() or "--autoplay-views" in OS.get_cmdline_user_args() or "--autoplay-depth" in OS.get_cmdline_user_args()
	if "--autoplay-views" in OS.get_cmdline_user_args() or "--autoplay-depth" in OS.get_cmdline_user_args():
		# locomotion views: toward camera, away, then sideways
		auto_steps = [[0.3, "down", true], [1.4, "down", false], [1.8, "up", true], [3.0, "up", false], [3.2, "left", true], [3.8, "left", false]]
		if "--autoplay-depth" in OS.get_cmdline_user_args():
			auto_steps = [[0.2, "down", true], [1.0, "down", false], [1.2, "up", true], [1.45, "up", false], [1.6, "attack"], [1.85, "attack"], [2.1, "attack"]]
	if autoplay or "--autoplay-foe" in OS.get_cmdline_user_args():
		seed(7)
	else:
		randomize()
	_input_map()
	player_tex = _pages("player")
	ronin_tex = _pages("ronin")
	cam = Camera3D.new()
	cam.fov = 38.0
	cam.far = 120.0
	add_child(cam)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	ground.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = load("res://shaders/ground.gdshader")
	ground.material_override = gm
	add_child(ground)
	_grass()
	fx = InkFX.new()
	add_child(fx)
	player = Fighter.new()
	add_child(player)
	player.setup(player_tex, "res://art/player.json")
	_hud()
	_touch_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_spawn(Vector3(5.5, 0, -2.0))
	if "--autoplay-foe" in OS.get_cmdline_user_args():
		# QA: first foe squares up behind the player to exercise the turned attack rows
		# then cuts back at it so the turned hit/death rows play too
		autoplay = true; auto_steps = [[3.0, "attack"], [3.25, "attack"], [3.5, "attack"], [4.6, "attack"], [4.85, "attack"], [5.1, "attack"]]
		enemies[0].set_meta("lane", -1)
		enemies[0].hp = 52.0  # dies inside the second combo, so the turned death row is captured

func _input_map() -> void:
	var defs := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"attack": [KEY_J, KEY_ENTER], "dodge": [KEY_K, KEY_SPACE, KEY_SHIFT],
	}
	for a in defs:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.2)
		for k in defs[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)
	var mb := InputEventMouseButton.new(); mb.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mb)
	var mb2 := InputEventMouseButton.new(); mb2.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("dodge", mb2)
	for pair in [["attack", JOY_BUTTON_X], ["attack", JOY_BUTTON_Y], ["dodge", JOY_BUTTON_A], ["dodge", JOY_BUTTON_B]]:
		var jb := InputEventJoypadButton.new(); jb.button_index = pair[1]
		InputMap.action_add_event(pair[0], jb)
	for pair in [["left", -1.0, JOY_AXIS_LEFT_X], ["right", 1.0, JOY_AXIS_LEFT_X], ["up", -1.0, JOY_AXIS_LEFT_Y], ["down", 1.0, JOY_AXIS_LEFT_Y]]:
		var jm := InputEventJoypadMotion.new(); jm.axis = pair[2]; jm.axis_value = pair[1]
		InputMap.action_add_event(pair[0], jm)

func _grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var q := QuadMesh.new()
	q.size = Vector2(2.6, 1.3)
	q.center_offset = Vector3(0, 0.65, 0)
	for v in 3:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = q
		var xs: Array = []
		# swaths: long bands of clumps, like the reference's drifting grass
		for band in 26:
			var c := Vector2(rng.randf_range(-45, 45), rng.randf_range(-45, 30))
			if c.length() < 6.0:
				continue
			var ang := rng.randf_range(-0.35, 0.35)
			var n := rng.randi_range(8, 22)
			for i in n:
				if rng.randi() % 3 != v:
					continue
				var along := rng.randf_range(-6.0, 6.0)
				var p := c + Vector2(cos(ang), sin(ang)) * along + Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-1.0, 1.0))
				var s := rng.randf_range(0.7, 1.3) * (1.0 - absf(along) / 9.0)
				xs.append(Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(p.x, 0, p.y)))
		mm.instance_count = xs.size()
		for i in xs.size():
			mm.set_instance_transform(i, xs[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/grass.gdshader")
		m.set_shader_parameter("tex", load("res://art/grass%d.png" % v))
		mi.material_override = m
		add_child(mi)

## Where a foe squares up: 0 beside the player (profile duel), +1 in front of the player
## (between them and the camera), -1 behind. Depth lanes use the turned attack rows.
func _pick_lane() -> int:
	var r := randf()
	return 0 if r < 0.65 else (1 if r < 0.8 else -1)

func _spawn(pos: Vector3) -> void:
	var e := Fighter.new()
	add_child(e)
	e.setup(ronin_tex, "res://art/ronin.json")
	e.global_position = pos
	e.facing = -1.0
	e.state = "approach"
	e.set_meta("cool", randf_range(0.6, 1.2))
	e.set_meta("lane", _pick_lane())
	e.set_meta("vw", "")
	enemies.append(e)
	var bar := _bar_pair(90.0)
	hud.add_child(bar)
	ebars.append(bar)

# ------------------------------------------------------------------ loop
func _physics_process(delta: float) -> void:
	if autoplay:
		_autoplay(delta)
	if hitstop > 0.0:
		hitstop -= delta
		return
	if player.alive():
		elapsed += delta
	_player(delta)
	for e in enemies:
		_enemy(e, delta)
	# retire dead foes, keep the duel going
	for i in range(enemies.size() - 1, -1, -1):
		var e: Fighter = enemies[i]
		if not e.alive() and e.state_t > 6.0:
			e.queue_free(); enemies.remove_at(i)
			ebars[i].queue_free(); ebars.remove_at(i)
	var living: int = enemies.filter(func(x): return x.alive()).size()
	if living < mini(1 + kills / 2, 3):
		spawn_t -= delta
		if spawn_t <= 0.0:
			var a := randf() * TAU
			_spawn(player.global_position + Vector3(cos(a) * 9.0, 0, sin(a) * 5.0 - 2.0))
			spawn_t = 2.5
	_camera(delta)
	_hud_update()

func _move_input() -> Vector2:
	var v := Input.get_vector("left", "right", "up", "down")
	if joy_vec.length() > 0.12:
		v = joy_vec
	return v

func _player(delta: float) -> void:
	var p := player
	p.state_t += delta
	dodge_cd = maxf(0.0, dodge_cd - delta)
	var mv := _move_input()
	atk_buf = maxf(0.0, atk_buf - delta); dodge_buf = maxf(0.0, dodge_buf - delta)
	if touch_atk: atk_buf = 0.3
	if touch_dodge: dodge_buf = 0.3
	touch_atk = false; touch_dodge = false
	var want_atk := atk_buf > 0.0
	var want_dodge := dodge_buf > 0.0
	match p.state:
		"idle", "run":
			if not p.alive():
				pass
			elif want_dodge and dodge_cd <= 0.0:
				dodge_buf = 0.0
				_start_dodge(mv)
			elif want_atk:
				atk_buf = 0.0
				combo = 0
				_start_attack()
			elif mv.length() > 0.1:
				p.state = "run"
				# pick the view from travel direction (screen-down = toward camera)
				if mv.y > 0.45 and mv.y > absf(mv.x) * 0.6:
					p.view = "_f"
				elif mv.y < -0.45 and -mv.y > absf(mv.x) * 0.6:
					p.view = "_b"
				elif absf(mv.x) > absf(mv.y):
					p.view = ""
				p.play("run" + p.view)
				p.vel = Vector3(mv.x, 0, mv.y) * 5.6
				if absf(mv.x) > 0.15:
					p.facing = signf(mv.x)
				foot_t -= delta
				if foot_t <= 0.0:
					foot_t = 0.16
					if randf() < 0.5:
						fx.footprint(p.global_position + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.1, 0.1)))
			else:
				p.state = "idle"; p.play("idle" + p.view)
				p.vel = p.vel.lerp(Vector3.ZERO, 12.0 * delta)
		"attack":
			p.vel = p.vel.lerp(Vector3.ZERO, 9.0 * delta)
			# lunge stops at blade contact instead of carrying the figures into each other
			var near := _nearest(p.global_position, 3.0)
			if near and (near.global_position.x - p.global_position.x) * p.facing > 0.0 and absf(near.global_position.x - p.global_position.x) < 2.7:
				p.vel.x = 0.0
			if near and p.view != "" and absf(near.global_position.z - p.global_position.z) < 1.8:
				p.vel.z = 0.0
			if want_atk:
				atk_buf = 0.0
				queued = true
			var strike := 2 if combo < 2 else 3
			if not hit_done and p.frame >= strike:
				hit_done = true
				_player_strike()
			if p.anim_done or (queued and p.frame >= p.frame_count() - 2 and combo < 2):
				if queued and combo < 2:
					combo += 1
					_start_attack()
				else:
					p.state = "idle"; p.play("idle")
		"dodge":
			ghost_t -= delta
			if ghost_t <= 0.0:
				ghost_t = 0.05
				fx.dash_mark(p.global_position, clampf(p.state_t / 0.34, 0.0, 1.0))
				fx.footprint(p.global_position)
			p.vel = p.vel.lerp(Vector3.ZERO, 3.5 * delta)
			if p.state_t > 0.34:
				p.state = "idle"; p.play("idle")
		"hit":
			p.vel = p.vel.lerp(Vector3.ZERO, 8.0 * delta)
			if p.state_t > 0.32:
				p.state = "idle"; p.play("idle")
		"dead":
			p.vel = Vector3.ZERO
			if p.state_t > 3.0 and (want_atk or want_dodge):
				_restart()
	p.global_position += p.vel * delta
	p.global_position.x = clampf(p.global_position.x, -40, 40)
	p.global_position.z = clampf(p.global_position.z, -40, 25)
	p.posture = minf(100.0, p.posture + 12.0 * delta)
	p.tick_anim(delta)

func _start_attack() -> void:
	var p := player
	var tgt := _nearest(p.global_position, 4.5)
	if tgt:
		p.facing = signf(tgt.global_position.x - p.global_position.x) if absf(tgt.global_position.x - p.global_position.x) > 0.1 else p.facing
	p.state = "attack"; p.state_t = 0.0
	# target mostly in depth: swing in the 3/4 view facing it instead of snapping to profile
	p.view = ""
	if tgt:
		var td: Vector3 = tgt.global_position - p.global_position
		if absf(td.z) > absf(td.x) * 1.1:
			p.view = "_f" if td.z > 0.0 else "_b"
	p.play(["atk1", "atk2", "atk3"][combo] + p.view, true)
	queued = false; hit_done = false
	var mv := _move_input()
	p.vel = Vector3(p.facing * 3.2, 0, mv.y * 1.5) if p.view == "" else Vector3(p.facing * 1.0, 0, (3.2 if p.view == "_f" else -3.2))

func _player_strike() -> void:
	var p := player
	var dmg: float = [12.0, 14.0, 24.0][combo]
	var yoff: float = [0.1, 0.3, -0.1][combo]
	var zdir := 0.0 if p.view == "" else (1.0 if p.view == "_f" else -1.0)
	var anchor := p.global_position + (Vector3(p.facing * 1.1, yoff, 0.2) if zdir == 0.0 else Vector3(p.facing * 0.4, yoff, zdir * 1.0 + 0.2))
	var sk: float = [1.2, 1.15, 1.45][combo]
	fx.slash(anchor, p.facing, sk * (1.0 if zdir == 0.0 else 0.85), 0.42, 0.0, combo)
	for e in enemies:
		if not e.alive():
			continue
		var d: Vector3 = e.global_position - p.global_position
		var in_arc := absf(d.z) < 1.3 and d.x * p.facing > -0.4 and absf(d.x) < 3.4
		if zdir != 0.0:
			in_arc = absf(d.x) < 2.1 and d.z * zdir > -0.4 and absf(d.z) < 3.2
		if in_arc:
			_hurt(e, dmg, p.facing, combo == 2)

func _start_dodge(mv: Vector2) -> void:
	var p := player
	var d := mv if mv.length() > 0.1 else Vector2(-p.facing, 0)
	if absf(d.x) > 0.15:
		p.facing = signf(d.x)
	p.view = ""
	p.state = "dodge"; p.state_t = 0.0; p.play("dodge", true)
	p.vel = Vector3(d.x, 0, d.y).normalized() * 11.0
	dodge_cd = 0.45
	ghost_t = 0.0
	fx.puff(p.global_position)

# 3/4 view for a figure struck from mostly in front of / behind it (F-19)
func _pages(which: String) -> Array[Texture2D]:
	var n := int(JSON.parse_string(FileAccess.get_file_as_string("res://art/%s.json" % which))["pages"])
	var out: Array[Texture2D] = []
	for k in n:
		out.append(load("res://art/%s_p%d.png" % [which, k]))
	return out

func _face_view(victim: Fighter, attacker: Fighter) -> String:
	var d := attacker.global_position - victim.global_position
	if absf(d.z) > absf(d.x) * 1.2:
		return "_f" if d.z > 0.0 else "_b"
	return ""

# knockback away from the attacker, along z for turned hits
func _knock(view: String, dir: float, amt: float) -> Vector3:
	if view == "":
		return Vector3(dir * amt, 0, 0)
	return Vector3(0, 0, (-amt if view == "_f" else amt) * 0.8)

func _hurt(e: Fighter, dmg: float, dir: float, heavy: bool) -> void:
	e.hp = maxf(0.0, e.hp - dmg)
	e.posture = maxf(0.0, e.posture - dmg * 1.6)
	e.flash = 1.0
	e.facing = -dir
	var hitpos := e.global_position + Vector3(0, 1.4, 0.3)
	fx.burst(hitpos, dir, 1.3 if heavy else 0.9, 0.35)
	fx.red_mark(e, 1.6)
	fx.stain(e.global_position + Vector3(dir * 0.6, 0, 0), 0.008, null, Color(1, 1, 1, 0.7))
	hitstop = 0.06 if not heavy else 0.1
	shake = 0.18 if heavy else 0.1
	if e.hp <= 0.0:
		var hv := _face_view(e, player)
		e.state = "dead"; e.state_t = 0.0; e.play("die" + hv, true)
		e.vel = _knock(hv, dir, 3.0)
		if hv != "":
			# drift clear of the player's line so the fall isn't hidden behind them
			var side := signf(e.global_position.x - player.global_position.x)
			e.vel.x = (side if side != 0.0 else 1.0) * 2.4
		if hv == "":
			fx.burst(hitpos, dir, 1.8, 0.5)
		else:
			# F-24: depth kills spray from behind the body and lighter, so the turned fall stays readable
			fx.burst(hitpos + Vector3(0, 0.3, -0.7), dir, 1.1, 0.5)
		fx.slash(e.global_position + Vector3(0, 0.2, 0.1), dir, 0.8, 0.4, 0.8, 1)
		kills += 1
	else:
		var hv := _face_view(e, player)
		e.state = "hit"; e.state_t = 0.0; e.play("hit" + hv, true)
		e.vel = _knock(hv, dir, 4.0 if heavy else 2.2)

func _enemy(e: Fighter, delta: float) -> void:
	e.state_t += delta
	var p := player
	var d: Vector3 = p.global_position - e.global_position
	var dist := Vector2(d.x, d.z * 1.6).length()
	match e.state:
		"approach":
			var lane: int = int(e.get_meta("lane"))
			var cool: float = float(e.get_meta("cool")) - delta
			e.set_meta("cool", cool)
			if absf(d.x) > 0.2:
				e.facing = signf(d.x)
			if not p.alive():
				e.play("idle"); e.vel = e.vel.lerp(Vector3.ZERO, 6.0 * delta)
			elif (lane == 0 and dist > 3.0) or (lane != 0 and (absf(d.z) > 3.0 or absf(d.x) > 1.9)):
				var goal := p.global_position - Vector3(e.facing * 2.9, 0, 0) if lane == 0 else p.global_position + Vector3(-e.facing * 1.4, 0, lane * 2.6)
				var dir := (goal - e.global_position); dir.y = 0
				e.vel = dir.normalized() * 2.6
				# closing mostly in depth: show the kasa from the front or the back
				var vw := ""
				if absf(dir.z) > absf(dir.x) * 1.2:
					vw = "_f" if dir.z > 0.0 else "_b"
				e.play("walk" + vw)
			else:
				e.play("idle")
				e.vel = e.vel.lerp(Vector3.ZERO, 8.0 * delta)
				if cool <= 0.0:
					# depth lane: in front of the player the foe is seen from behind, and vice versa
					var vw := "" if lane == 0 else ("_b" if d.z < 0.0 else "_f")
					e.set_meta("vw", vw)
					e.state = "windup"; e.state_t = 0.0; e.play("windup" + vw, true)
		"windup":
			e.vel = e.vel.lerp(Vector3.ZERO, 10.0 * delta)
			if e.state_t > 0.62:
				e.state = "swing"; e.state_t = 0.0; e.play("swing" + str(e.get_meta("vw")), true)
				e.set_meta("struck", false)
		"swing":
			var ew: String = e.get_meta("vw")
			var zd := 0.0 if ew == "" else signf(d.z)
			if zd == 0.0:
				e.vel = e.vel.lerp(Vector3(e.facing * 1.5, 0, 0), 6.0 * delta)
				if absf(d.x) < 2.7:
					e.vel.x = 0.0
			else:
				e.vel = e.vel.lerp(Vector3(0, 0, zd * 1.2), 6.0 * delta)
				if absf(d.z) < 1.7:
					e.vel.z = 0.0
			if not e.get_meta("struck") and e.frame >= 2:
				e.set_meta("struck", true)
				var dd: Vector3 = p.global_position - e.global_position
				var hit_ok := absf(dd.z) < 1.3 and dd.x * e.facing > -0.5 and absf(dd.x) < 3.7
				if zd == 0.0:
					fx.slash(e.global_position + Vector3(e.facing * 1.1, 0.1, 0.12), e.facing, 1.25, 0.34, 0.0, 1)
				else:
					fx.slash(e.global_position + Vector3(e.facing * 0.4, 0.1, zd * 1.0 + 0.12), e.facing, 1.05, 0.34, 0.0, 1)
					hit_ok = absf(dd.x) < 2.1 and dd.z * zd > -0.5 and absf(dd.z) < 3.4
				if p.alive() and p.state != "dodge" and hit_ok:
					_player_hurt(18.0, e.facing, e)
			if e.anim_done:
				e.state = "recover"; e.state_t = 0.0; e.play("recover" + str(e.get_meta("vw")), true)
		"recover":
			e.vel = e.vel.lerp(Vector3.ZERO, 8.0 * delta)
			if e.anim_done and e.state_t > 0.5:
				e.state = "approach"; e.set_meta("cool", randf_range(0.8, 1.8))
				if randf() < 0.5:
					e.set_meta("lane", _pick_lane())
		"hit":
			e.vel = e.vel.lerp(Vector3.ZERO, 7.0 * delta)
			if e.state_t > 0.38:
				e.state = "approach"; e.set_meta("cool", randf_range(0.3, 0.9))
		"dead":
			e.vel = e.vel.lerp(Vector3.ZERO, 5.0 * delta)
	# keep foes from stacking on each other
	for o in enemies:
		if o != e and o.alive():
			var s: Vector3 = e.global_position - o.global_position
			if s.length() < 1.4 and s.length() > 0.001:
				e.global_position += s.normalized() * (1.4 - s.length()) * 0.5
	if e.alive() and p.alive():
		var sp: Vector3 = e.global_position - p.global_position
		sp.y = 0.0
		var sl := Vector2(sp.x, sp.z * 1.6).length()
		if sl < 2.5 and sl > 0.001:
			e.global_position += sp.normalized() * (2.5 - sl)
	e.global_position += e.vel * delta
	e.posture = minf(100.0, e.posture + 8.0 * delta)
	e.tick_anim(delta)

func _player_hurt(dmg: float, dir: float, by: Fighter) -> void:
	var p := player
	p.hp = maxf(0.0, p.hp - dmg)
	p.flash = 1.0
	p.facing = -dir
	fx.burst(p.global_position + Vector3(0, 1.1, 0.2), dir, 1.0, 0.6)
	fx.red_mark(p, 1.4)
	shake = 0.2; hitstop = 0.08
	post_mat.set_shader_parameter("hurt", 1.0)
	if p.hp <= 0.0:
		p.state = "dead"; p.state_t = 0.0; p.play("die" + _face_view(p, by), true)
		banner.text = "Fallen.   %d cut down" % kills
		banner.visible = true
	else:
		var hv := _face_view(p, by)
		p.state = "hit"; p.state_t = 0.0; p.play("hit" + hv, true)
		p.vel = _knock(hv, dir, 3.0)

func _restart() -> void:
	for e in enemies:
		e.queue_free()
	for b in ebars:
		b.queue_free()
	enemies.clear(); ebars.clear()
	player.hp = 100.0; player.state = "idle"; player.play("idle", true)
	player.global_position = Vector3.ZERO
	elapsed = 0.0; kills = 0; spawn_t = 1.0
	banner.visible = false

func _nearest(pos: Vector3, r: float) -> Fighter:
	var best: Fighter = null
	var bd := r
	for e in enemies:
		if e.alive():
			var dd: float = (e.global_position - pos).length()
			if dd < bd:
				bd = dd; best = e
	return best

func _camera(delta: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	var portrait := vs.y > vs.x
	var focus := player.global_position
	# lead the player's travel so running toward the camera doesn't outrun the follow
	var lead := Vector3(player.vel.x * 0.12, 0.0, player.vel.z * 0.3)
	focus += lead.limit_length(1.8)
	var tgt := _nearest(player.global_position, 7.0)
	var zoom := 1.0
	if tgt:
		# narrow screens: centre the pair and pull back when they spread wider than the frame
		focus = focus.lerp(tgt.global_position, 0.5 if portrait else 0.35)
		if portrait:
			zoom = clampf(absf(tgt.global_position.x - player.global_position.x) / 3.6, 1.0, 1.35)
	var off := Vector3(0, 3.6, 6.0) if not portrait else Vector3(0, 5.4, 4.3) * zoom
	cam.keep_aspect = Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
	cam.fov = 50.0 if portrait else 40.0
	var want := focus + off
	if cam.global_position.length() > 0.1:
		var cp := cam.global_position.lerp(want, 1.0 - exp(-5.0 * delta))
		cp.z = lerpf(cam.global_position.z, want.z, 1.0 - exp(-9.0 * delta))
		cam.global_position = cp
	else:
		cam.global_position = want
	# portrait: aim a little higher so the duel sits nearer the vertical middle, not above empty ground
	cam.look_at(cam.global_position - off + Vector3(0, 2.7 if portrait else 1.2, 0), Vector3.UP)
	if shake > 0.0:
		shake = maxf(0.0, shake - delta)
		cam.h_offset = randf_range(-1, 1) * shake * 0.5
		cam.v_offset = randf_range(-1, 1) * shake * 0.5
	else:
		cam.h_offset = 0.0; cam.v_offset = 0.0
	var h: float = post_mat.get_shader_parameter("hurt")
	post_mat.set_shader_parameter("hurt", maxf(0.0, h - delta * 2.0))

# ------------------------------------------------------------------ HUD
func _bar_pair(w: float) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lab := Label.new()
	lab.name = "L"
	lab.add_theme_color_override("font_color", Color(0.93, 0.9, 0.84))
	lab.add_theme_color_override("font_outline_color", Color(0.12, 0.1, 0.08))
	lab.add_theme_constant_override("outline_size", 4)
	lab.add_theme_font_size_override("font_size", 14)
	lab.position = Vector2(w * 0.5 - 20, -16)
	root.add_child(lab)
	var bg := TextureRect.new()
	bg.texture = load("res://art/bar.png")
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = Vector2(w, 9); bg.position = Vector2(0, 0)
	root.add_child(bg)
	var fill := ColorRect.new()
	fill.name = "F"
	fill.color = Color(0.78, 0.07, 0.08)
	fill.position = Vector2(w * 0.08, 2.5); fill.size = Vector2(w * 0.84, 4)
	fill.set_meta("w", w * 0.84)
	root.add_child(fill)
	var bg2 := bg.duplicate()
	bg2.position = Vector2(w * 0.1, 11); bg2.size = Vector2(w * 0.8, 5)
	root.add_child(bg2)
	return root

func _hud() -> void:
	var post := CanvasLayer.new(); post.layer = 1
	add_child(post)
	var pr := ColorRect.new()
	pr.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = ShaderMaterial.new(); post_mat.shader = load("res://shaders/post.gdshader")
	post_mat.set_shader_parameter("hurt", 0.0)
	pr.material = post_mat
	post.add_child(pr)
	hud = CanvasLayer.new(); hud.layer = 2
	add_child(hud)
	var plaque := TextureRect.new()
	plaque.name = "Plaque"
	plaque.texture = load("res://art/plaque.png")
	plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plaque.size = Vector2(150, 53)
	plaque.position = Vector2(0, 70)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(plaque)
	var t1 := Label.new(); t1.text = "Time:"
	t1.position = Vector2(12, 4)
	for l in [t1]:
		l.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
		l.add_theme_font_size_override("font_size", 17)
	plaque.add_child(t1)
	time_label = Label.new()
	time_label.position = Vector2(10, 19)
	time_label.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	time_label.add_theme_font_size_override("font_size", 23)
	plaque.add_child(time_label)
	var pb := Control.new(); pb.name = "PlayerBars"
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(pb)
	for i in 3:
		var r := TextureRect.new()
		r.texture = load("res://art/ring.png")
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.size = Vector2(24, 24); r.position = Vector2(34 + i * 28, -8)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.name = "R%d" % i
		pb.add_child(r)
		var glyph := TextureRect.new()
		glyph.texture = load("res://art/icon_%s.png" % ["cut", "evade", "burst"][i])
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.size = Vector2(16, 16); glyph.position = Vector2(4, 4)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_child(glyph)
	var bars := _bar_pair(150.0)
	bars.position = Vector2(0, 34)
	pb.add_child(bars)
	php_fill = bars.get_node("F"); php_label = bars.get_node("L")
	banner = Label.new()
	banner.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	banner.add_theme_font_size_override("font_size", 34)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.visible = false
	hud.add_child(banner)

func pb_scale() -> Vector2:
	var vs := get_viewport().get_visible_rect().size
	return Vector2.ONE * (1.45 if vs.y > vs.x else 1.0)

func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	# narrow screens: HUD scales up so bars, rings and timer stay readable on a phone
	var k := pb_scale().x
	var pb: Control = hud.get_node("PlayerBars")
	pb.scale = Vector2(k, k)
	pb.position = Vector2(vs.x * 0.5 - 75 * k, vs.y - 60 * k)
	var plaque: Control = hud.get_node("Plaque")
	plaque.scale = Vector2(k, k)
	plaque.position = Vector2(0, clampf(vs.y * 0.2, 50, 110))

	banner.position = Vector2(vs.x * 0.5 - 200, vs.y * 0.4)
	banner.size = Vector2(400, 40)
	if touch_ui:
		touch_ui.size = vs
		var a: Control = touch_ui.get_node("Atk"); var d: Control = touch_ui.get_node("Dodge")
		a.position = Vector2(vs.x - 110, vs.y - 150)
		d.position = Vector2(vs.x - 170, vs.y - 90)
		joy_base.position = Vector2(40, vs.y - 170)

func _hud_update() -> void:
	var m := int(elapsed / 60.0); var s := fmod(elapsed, 60.0)
	time_label.text = "%02d:%05.2f" % [m, s]
	php_fill.size.x = php_fill.get_meta("w") * player.hp / player.max_hp
	php_label.text = "%d/100" % int(ceil(player.hp))
	for i in enemies.size():
		var e: Fighter = enemies[i]
		var b: Control = ebars[i]
		var wp: Vector3 = e.global_position + Vector3(0, 3.1, 0)
		b.visible = e.alive() and not cam.is_position_behind(wp)
		if b.visible:
			var sp := cam.unproject_position(wp)
			b.scale = pb_scale()
			b.position = Vector2(sp.x - 45.0 * b.scale.x, maxf(sp.y - 16.0 * (b.scale.y - 1.0), 24.0))
			var f: ColorRect = b.get_node("F")
			f.size.x = f.get_meta("w") * e.hp / e.max_hp
			(b.get_node("L") as Label).text = "%d/100" % int(ceil(e.hp))

# ------------------------------------------------------------------ touch
func _ring(sz: float, glyph: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load("res://art/ring.png")
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = Vector2(sz, sz)
	r.modulate = Color(1, 1, 1, 0.8)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if glyph != "":
		var g := TextureRect.new()
		g.texture = load("res://art/icon_%s.png" % glyph)
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.size = Vector2(sz * 0.6, sz * 0.6); g.position = Vector2(sz * 0.2, sz * 0.2)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_child(g)
	return r

func _touch_ui() -> void:
	touch_ui = Control.new()
	touch_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_ui.visible = DisplayServer.is_touchscreen_available()
	hud.add_child(touch_ui)
	var a := _ring(84, "cut"); a.name = "Atk"; touch_ui.add_child(a)
	var d := _ring(60, "evade"); d.name = "Dodge"; touch_ui.add_child(d)
	joy_base = _ring(120, ""); joy_base.modulate.a = 0.35; touch_ui.add_child(joy_base)
	joy_knob = TextureRect.new()
	joy_knob.texture = load("res://art/blot0.png")
	joy_knob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joy_knob.size = Vector2(46, 46); joy_knob.position = Vector2(37, 37)
	joy_knob.modulate = Color(1, 1, 1, 0.6)
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_base.add_child(joy_knob)

func _input(ev: InputEvent) -> void:
	if not (ev is InputEventScreenTouch or ev is InputEventScreenDrag):
		if ev.is_action_pressed("attack", false):
			atk_buf = 0.3
		elif ev.is_action_pressed("dodge", false):
			dodge_buf = 0.3
	if ev is InputEventScreenTouch:
		touch_ui.visible = true
		var vs := get_viewport().get_visible_rect().size
		if ev.pressed:
			if ev.position.x < vs.x * 0.45 and joy_id == -1:
				joy_id = ev.index; joy_origin = ev.position
				joy_base.position = ev.position - Vector2(60, 60)
			else:
				var a: Control = touch_ui.get_node("Atk"); var d: Control = touch_ui.get_node("Dodge")
				if ev.position.distance_to(d.position + d.size * 0.5) < 46.0:
					touch_dodge = true
				else:
					touch_atk = true
		elif ev.index == joy_id:
			joy_id = -1; joy_vec = Vector2.ZERO
			joy_knob.position = Vector2(37, 37)
	elif ev is InputEventScreenDrag and ev.index == joy_id:
		var v: Vector2 = (ev.position - joy_origin) / 50.0
		if v.length() > 1.0:
			v = v.normalized()
		joy_vec = v
		joy_knob.position = Vector2(37, 37) + v * 36.0

func _autoplay(delta: float) -> void:
	auto_t += delta
	while auto_steps.size() > 0 and auto_t >= float(auto_steps[0][0]):
		var st: Array = auto_steps.pop_front()
		if st[1] == "attack":
			atk_buf = 0.3
		elif st[1] == "dodge":
			dodge_buf = 0.3
		elif st[2]:
			Input.action_press(st[1])
		else:
			Input.action_release(st[1])
