## C60: the chips row as ONE canvas item. The Buttons used one identical StyleBoxFlat
## for normal/hover/pressed/focus, so a drawn stylebox + _gui_input hit-testing is
## pixel-identical at rest and costs 1 draw instead of ~10.
extends HudCanvas
class_name ChipsCanvas

var labels: Array = []
var callbacks: Array = []
var sb: StyleBoxFlat
var rects: Array = []
const SEP := 8.0
const H := 30.0
const FS := 16

func _init() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_STOP
	sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.88, 0.78, 0.82)
	sb.border_color = Color(0.12, 0.1, 0.08, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)

func setup(lbls: Array, cbs: Array) -> void:
	labels = lbls.duplicate()
	callbacks = cbs.duplicate()
	rebuild()

func set_label(i: int, s: String) -> void:
	if i < labels.size() and labels[i] != s:
		labels[i] = s
		rebuild()

func rebuild() -> void:
	rects.clear()
	var x := 0.0
	for s in labels:
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x + 20.0
		rects.append(Rect2(x, 0, w, H))
		x += w + SEP
	size = Vector2(maxf(0.0, x - SEP), H)
	queue_redraw()

func _draw() -> void:
	for i in rects.size():
		draw_style_box(sb, rects[i])
		var s: String = labels[i]
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x
		var p := Vector2(rects[i].position.x + (rects[i].size.x - w) * 0.5,
			rects[i].position.y + (rects[i].size.y - font.get_height(FS)) * 0.5 + font.get_ascent(FS))
		draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, Color(0.12, 0.1, 0.08))

func _press_at(pos: Vector2) -> bool:
	for i in rects.size():
		if rects[i].has_point(pos):
			callbacks[i].call()
			return true
	return false

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		if _press_at(ev.position):
			accept_event()
	elif ev is InputEventScreenTouch and ev.pressed:
		if _press_at(ev.position):
			accept_event()
