extends RefCounted

# Custom drawn UI widgets matching the reference screenshot:
# 1. Currency formatting helpers (1 500 000 & 60K)
# 2. SpeechBubble: Comic elliptical white bubble with pointer tail anchored to 3D characters
# 3. CircleActionButton: Glossy white-rimmed circular buttons on the right toolbar + badge counter
# 4. PropertyDeedCard: Authentic Monopoly deed modal for buying/inspecting tiles

const PlayerBanner = preload("res://src/player_banner.gd")

static func format_cash(internal_amount: int) -> String:
	var full := internal_amount * 1000
	var negative := full < 0
	var digits := str(absi(full))
	var parts: PackedStringArray = []
	while digits.length() > 3:
		parts.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	parts.insert(0, digits)
	return ("-" if negative else "") + " ".join(parts)

static func format_k(internal_amount: int) -> String:
	return "%dK" % internal_amount

class SpeechBubble extends Control:
	var text := "":
		set(v):
			text = v
			visible = not v.is_empty()
			queue_redraw()
	var tail_dir := Vector2(-18, 22)
	var accent := Color("1aa3ec")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(210, 62)
		visible = false

	func _draw() -> void:
		if text.is_empty():
			return
		var font := ThemeDB.fallback_font
		var fsize := 15
		var text_w := clampf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x + 36.0, 128.0, 250.0)
		var bubble_rect := Rect2(-text_w * 0.5, -52.0, text_w, 44.0)

		# Soft drop shadow
		var sh := StyleBoxFlat.new()
		sh.bg_color = Color(0.12, 0.08, 0.14, 0.22)
		sh.set_corner_radius_all(22)
		draw_style_box(sh, Rect2(bubble_rect.position + Vector2(0, 3), bubble_rect.size))

		# Pointer tail toward character
		var tail_base_l := Vector2(-9, -10)
		var tail_base_r := Vector2(9, -10)
		var tail_tip := Vector2(0, 6)
		draw_colored_polygon(PackedVector2Array([tail_base_l, tail_base_r, tail_tip]), Color("ffffff"))
		draw_polyline(PackedVector2Array([tail_base_l, tail_tip, tail_base_r]), Color("cfd6e0"), 1.6, true)

		# Crisp white comic oval/pill
		var box := StyleBoxFlat.new()
		box.bg_color = Color("ffffff")
		box.border_color = accent.lightened(0.35)
		box.set_border_width_all(2)
		box.set_corner_radius_all(22)
		draw_style_box(box, bubble_rect)

		draw_string(
			font,
			Vector2(bubble_rect.position.x, bubble_rect.position.y + 27.0),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			bubble_rect.size.x,
			fsize,
			Color("222934")
		)

class CircleToolButton extends Button:
	var kind := "pause"
	var badge_count := -1:
		set(v):
			badge_count = v
			queue_redraw()
	var sound_on := true:
		set(v):
			sound_on = v
			queue_redraw()

	func _init(p_kind := "pause", tip := "") -> void:
		kind = p_kind
		tooltip_text = tip
		custom_minimum_size = Vector2(54, 54)
		flat = true
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.44
		var hovered := is_hovered()
		if kind == "assets":
			# Warm wooden/golden property bucket like the bottom-right icon in reference!
			draw_circle(c + Vector2(0, 3), r, Color(0.14, 0.08, 0.12, 0.28))
			# Colorful property cards peeking out the top
			draw_rect(Rect2(c.x - 12, c.y - 19, 10, 13), Color("1aa3ec"), true)
			draw_rect(Rect2(c.x - 3, c.y - 21, 10, 14), Color("ffd43b"), true)
			draw_rect(Rect2(c.x + 4, c.y - 18, 9, 12), Color("f01e6b"), true)
			# Bucket body
			var bucket := PackedVector2Array([
				c + Vector2(-16, -8),
				c + Vector2(16, -8),
				c + Vector2(13, 17),
				c + Vector2(-13, 17)
			])
			draw_colored_polygon(bucket, Color("e09132").lightened(0.08 if hovered else 0.0))
			draw_polyline(PackedVector2Array([bucket[0], bucket[1], bucket[2], bucket[3], bucket[0]]), Color("9c5816"), 2.0, true)
			draw_rect(Rect2(c.x - 16, c.y - 4, 32, 4), Color("f7cb45"), true)
			draw_rect(Rect2(c.x - 14, c.y + 8, 28, 3.5), Color("f7cb45"), true)
		else:
			# Glossy white-bordered circular button matching reference right toolbar
			draw_circle(c + Vector2(0, 3), r + 1.5, Color(0.14, 0.08, 0.12, 0.26))
			draw_circle(c, r + 1.5, Color("ffffff"))
			var fill := Color("3b9be8")
			if kind == "dice":
				fill = Color("4dabf7")
			if hovered:
				fill = fill.lightened(0.12)
			draw_circle(c, r - 2.2, fill)

			match kind:
				"dice":
					# Golden orb / dice skin emblem
					draw_circle(c, 12.5, Color("fab005"))
					draw_circle(c + Vector2(-3.5, -3.5), 4.2, Color("ffe066"))
					draw_circle(c + Vector2(3.5, 3.5), 2.0, Color("fff9db"))
				"emote":
					# Cheerful smiley face
					draw_arc(c, 11.5, 0.0, TAU, 24, Color("ffffff"), 2.2, true)
					draw_circle(c + Vector2(-4.0, -3.0), 1.9, Color("ffffff"))
					draw_circle(c + Vector2(4.0, -3.0), 1.9, Color("ffffff"))
					draw_arc(c + Vector2(0, -0.5), 6.5, 0.35, PI - 0.35, 16, Color("ffffff"), 2.2, true)
				"pause":
					draw_rect(Rect2(c.x - 6.5, c.y - 8.5, 4.4, 17.0), Color("ffffff"), true)
					draw_rect(Rect2(c.x + 2.1, c.y - 8.5, 4.4, 17.0), Color("ffffff"), true)
				"sound":
					var pts := PackedVector2Array([
						c + Vector2(-9, -4), c + Vector2(-4, -4),
						c + Vector2(2, -9), c + Vector2(2, 9),
						c + Vector2(-4, 4), c + Vector2(-9, 4)
					])
					draw_colored_polygon(pts, Color("ffffff"))
					if sound_on:
						draw_arc(c + Vector2(2, 0), 6.0, -0.8, 0.8, 12, Color("ffffff"), 2.0, true)
						draw_arc(c + Vector2(2, 0), 10.0, -0.8, 0.8, 12, Color("ffffff"), 2.0, true)
					else:
						draw_line(c + Vector2(5, -5), c + Vector2(12, 5), Color("ffd43b"), 2.4, true)
						draw_line(c + Vector2(12, -5), c + Vector2(5, 5), Color("ffd43b"), 2.4, true)

		if badge_count >= 0:
			var bc := c + Vector2(13, 14)
			draw_circle(bc, 10.5, Color("ffffff"))
			draw_circle(bc, 8.6, Color("1aa3ec"))
			draw_string(ThemeDB.fallback_font, Vector2(bc.x - 10, bc.y + 4.5), str(badge_count), HORIZONTAL_ALIGNMENT_CENTER, 20, 12, Color("ffffff"))
