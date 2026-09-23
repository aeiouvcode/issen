class_name Fighter
extends Node3D
## A brush-animated combatant: a Y-billboard Sprite3D stepping through baked sheet frames.

const PIXEL := 0.0158
var sheet: Texture2D
var meta: Dictionary
var sprite: Sprite3D
var shadow: Sprite3D
var anim := "idle"
var frame_t := 0.0
var frame := 0
var fps := {"idle": 8.0, "run": 15.0, "idle_f": 8.0, "run_f": 15.0, "idle_b": 8.0, "run_b": 15.0, "walk": 10.0, "walk_f": 10.0, "walk_b": 10.0, "atk1": 20.0, "atk1_f": 20.0, "atk1_b": 20.0, "atk2": 20.0, "atk2_f": 20.0, "atk2_b": 20.0, "atk3": 18.0, "atk3_f": 18.0, "atk3_b": 18.0, "dodge": 18.0, "hit": 14.0, "hit_f": 14.0, "hit_b": 14.0, "die": 9.0, "die_f": 9.0, "die_b": 9.0, "windup": 9.0, "windup_f": 9.0, "windup_b": 9.0, "swing": 18.0, "swing_f": 18.0, "swing_b": 18.0, "recover": 10.0, "recover_f": 10.0, "recover_b": 10.0}
var loops := {"idle": true, "run": true, "walk": true, "idle_f": true, "run_f": true, "idle_b": true, "run_b": true, "walk_f": true, "walk_b": true}
## View suffix for locomotion rows: "" side, "_f" 3/4 toward camera, "_b" 3/4 away.
var view := ""
var facing := 1.0
var vel := Vector3.ZERO
var hp := 100.0
var max_hp := 100.0
var posture := 100.0
var state := "idle"
var state_t := 0.0
var flash := 0.0
var anim_done := false

func setup(tex: Texture2D, meta_path: String) -> void:
	sheet = tex
	meta = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	shadow = Sprite3D.new()
	shadow.texture = load("res://art/dab.png")
	shadow.axis = Vector3.AXIS_Y
	shadow.pixel_size = 0.04
	shadow.modulate = Color(1, 1, 1, 0.35)
	shadow.position.y = 0.01
	shadow.scale = Vector3(1.6, 1, 0.8)
	shadow.shaded = false
	add_child(shadow)
	sprite = Sprite3D.new()
	sprite.texture = sheet
	sprite.hframes = int(meta["cols"])
	sprite.vframes = int(sheet.get_height() / float(meta["frame"]))
	sprite.pixel_size = PIXEL
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.offset = Vector2(10, 110)
	add_child(sprite)
	play("idle")

func play(a: String, restart := false) -> void:
	if a == anim and not restart:
		return
	anim = a
	frame = 0
	frame_t = 0.0
	anim_done = false
	_apply()

func frame_count() -> int:
	return int(meta["anims"][anim]["count"])

func _apply() -> void:
	var info: Dictionary = meta["anims"][anim]
	sprite.frame = int(info["row"]) * int(meta["cols"]) + int(info.get("col0", 0)) + frame
	sprite.flip_h = facing < 0.0
	sprite.offset.x = 10.0 * facing

func tick_anim(delta: float) -> void:
	frame_t += delta * fps.get(anim, 10.0)
	while frame_t >= 1.0:
		frame_t -= 1.0
		if frame < frame_count() - 1:
			frame += 1
		elif loops.get(anim, false):
			frame = 0
		else:
			anim_done = true
	_apply()
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 4.0)
	sprite.modulate = Color(1.0, 1.0 - flash * 0.55, 1.0 - flash * 0.6, 1.0)

func alive() -> bool:
	return hp > 0.0

## World-space point of the weapon tip for the current frame (for VFX anchoring).
func tip_world() -> Vector3:
	var tips: Array = meta["tips"].get(anim, [])
	if frame >= tips.size() or tips[frame] == null:
		return global_position + Vector3(0, 1.2, 0)
	var t: Array = tips[frame]
	var fx := (float(t[0]) - 118.0) * PIXEL * facing
	var fy := (238.0 - float(t[1])) * PIXEL
	return global_position + Vector3(fx, fy, 0.05)
