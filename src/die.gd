extends Control

var value := 0:
	set(new_value):
		value = new_value
		queue_redraw()

func _draw() -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color("85263c")
	shadow.set_corner_radius_all(12)
	draw_style_box(shadow, Rect2(3, 6, 62, 62))
	var face := StyleBoxFlat.new()
	face.bg_color = Color("e9475c")
	face.border_color = Color("fff2e0")
	face.set_border_width_all(2)
	face.set_corner_radius_all(12)
	draw_style_box(face, Rect2(0, 0, 62, 62))
	if value == 0:
		draw_string(ThemeDB.fallback_font, Vector2(21, 43), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
		return
	var patterns := {
		1: [4], 2: [0, 8], 3: [0, 4, 8],
		4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]
	}
	for dot in patterns.get(value, []):
		var center := Vector2(17 + (dot % 3) * 14, 17 + (dot / 3) * 14)
		draw_circle(center, 4.2, Color("fff9ec"))
