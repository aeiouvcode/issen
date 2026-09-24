## C60: one-draw HUD clusters. All static chrome + bars + labels of a cluster are
## drawn by a single canvas item (the web build pays per GL call - C51 diagnosis).
## Callers rebuild or patch fields and commit(); queue_redraw only fires on change.
extends Control
class_name HudCanvas

var quads: Array = []   # {tex: Texture2D, rect: Rect2, modulate: Color}
var texts: Array = []   # {pos: Vector2, text: String, size: int, color: Color, ocolor: Color, osize: int, width: float}
var font: Font

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font

func reset() -> void:
	quads.clear()
	texts.clear()

func quad(tex: Texture2D, rect: Rect2, mod := Color.WHITE) -> int:
	quads.append({"tex": tex, "rect": rect, "modulate": mod})
	return quads.size() - 1

## Solid fill rect (the hp/stamina fills) - same look as a ColorRect.
func fill_rect(rect: Rect2, color: Color) -> int:
	quads.append({"tex": null, "rect": rect, "modulate": color})
	return quads.size() - 1

## pos is the TOP-LEFT of the text run (Label convention); converted to baseline here.
func text(pos: Vector2, s: String, size: int, color: Color, osize := 0, ocolor := Color.BLACK, width := -1.0) -> int:
	texts.append({"pos": pos, "text": s, "size": size, "color": color, "osize": osize, "ocolor": ocolor, "width": width})
	return texts.size() - 1

func set_fill_x(idx: int, x: float) -> void:
	quads[idx].rect.size.x = x

func set_text(idx: int, s: String) -> void:
	texts[idx].text = s

func commit() -> void:
	queue_redraw()

func _draw() -> void:
	for q in quads:
		if q.tex:
			draw_texture_rect(q.tex, q.rect, false, q.modulate)
		else:
			draw_rect(q.rect, q.modulate, true)
	for t in texts:
		var ascent := font.get_ascent(t.size)
		var p: Vector2 = t.pos + Vector2(0, ascent)
		if t.osize > 0:
			draw_string_outline(font, p, t.text, HORIZONTAL_ALIGNMENT_CENTER if t.width > 0.0 else HORIZONTAL_ALIGNMENT_LEFT, t.width, t.size, t.osize, t.ocolor)
		draw_string(font, p, t.text, HORIZONTAL_ALIGNMENT_CENTER if t.width > 0.0 else HORIZONTAL_ALIGNMENT_LEFT, t.width, t.size, t.color)
