extends Control

# Business-Tour style 4-corner Player Banner HUD:
# - Top-Left (0): Hot Pink, Avatar Left, Name Ribbon Top, Cash White Pill Bottom
# - Top-Right (1): Sky Blue, Avatar Right, Name Ribbon Top, Cash White Pill Bottom
# - Bottom-Left (2): Leaf Green, Avatar Left, Cash White Pill Top, Name Ribbon Bottom
# - Bottom-Right (3): Golden Yellow, Avatar Right, Cash White Pill Top, Name Ribbon Bottom
# Includes custom crisp vector isometric green banknote stack icon next to cash!

var color := Color("f01e6b")
var right_aligned := false
var bottom_aligned := false
var is_vip := false
var bankrupt := false
var owned_count := 0
var cash_icon_pos := Vector2(180, 56)

var active := false:
	set(value):
		active = value
		queue_redraw()

static func draw_banknote_icon(canvas: CanvasItem, center: Vector2, scale_f := 1.0) -> void:
	# Draws a crisp layered green stack of bills with gold/cream band (like 💵 in reference)
	var s := scale_f
	# Drop shadow / bottom bill layers
	var dark_green := Color("3b8732")
	var mid_green := Color("5cb849")
	var light_green := Color("8ce070")
	var strap := Color("fff3bf")
	var strap_edge := Color("e6b83a")

	for layer in range(3):
		var dy := (2 - layer) * 2.6 * s
		var pts := PackedVector2Array([
			center + Vector2(-11.0 * s, (1.5 * s) + dy),
			center + Vector2(-2.0 * s, (-5.5 * s) + dy),
			center + Vector2(11.0 * s, (-1.0 * s) + dy),
			center + Vector2(2.0 * s, (6.0 * s) + dy)
		])
		canvas.draw_colored_polygon(pts, light_green if layer == 2 else (mid_green if layer == 1 else dark_green))
		canvas.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("2f6e27"), 1.1, true)

	# Inner decorative border & emblem on top banknote
	canvas.draw_circle(center + Vector2(0.0, 0.2 * s), 2.3 * s, Color("449639"))
	# Paper currency strap across middle
	var band := PackedVector2Array([
		center + Vector2(-3.6 * s, -4.4 * s),
		center + Vector2(0.2 * s, -5.0 * s),
		center + Vector2(4.2 * s, 4.4 * s),
		center + Vector2(0.4 * s, 5.2 * s)
	])
	canvas.draw_colored_polygon(band, strap)
	canvas.draw_polyline(PackedVector2Array([band[0], band[1], band[2], band[3], band[0]]), strap_edge, 1.0, true)

func _draw() -> void:
	var w := size.x if size.x > 10 else 284.0
	var h := size.y if size.y > 10 else 96.0
	var primary := Color("8d949e") if bankrupt else color
	var darker := primary.darkened(0.22)

	# Active turn warm outer glow
	if active and not bankrupt:
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color(1.0, 0.96, 0.72, 0.28)
		glow.border_color = Color("ffe066")
		glow.set_border_width_all(3)
		glow.set_corner_radius_all(16)
		var glow_rect := Rect2(2, 2, w - 4, h - 4)
		draw_style_box(glow, glow_rect)

	var av_size := Vector2(78, 80)
	var av_pos := Vector2(w - av_size.x - 6 if right_aligned else 6.0, (h - av_size.y) * 0.5)

	# Ribbon (colored name trapezoid) & White Cash Pill geometry
	var body_left := 14.0 if right_aligned else (av_pos.x + av_size.x - 10.0)
	var body_right := (av_pos.x + 10.0) if right_aligned else (w - 14.0)

	# Outer colored backing shell wrapping both ribbon and cash bar (matches reference trapezoid wings!)
	var wing_slant := 10.0
	var outer_poly: PackedVector2Array
	if not bottom_aligned:
		if not right_aligned:
			outer_poly = PackedVector2Array([
				Vector2(body_left - 6, 4),
				Vector2(body_right + wing_slant, 4),
				Vector2(body_right - 2, h - 8),
				Vector2(body_left - 6, h - 8)
			])
		else:
			outer_poly = PackedVector2Array([
				Vector2(body_left - wing_slant, 4),
				Vector2(body_right + 6, 4),
				Vector2(body_right + 6, h - 8),
				Vector2(body_left + 2, h - 8)
			])
	else:
		if not right_aligned:
			outer_poly = PackedVector2Array([
				Vector2(body_left - 6, 8),
				Vector2(body_right - 2, 8),
				Vector2(body_right + wing_slant, h - 4),
				Vector2(body_left - 6, h - 4)
			])
		else:
			outer_poly = PackedVector2Array([
				Vector2(body_left + 2, 8),
				Vector2(body_right + 6, 8),
				Vector2(body_right + 6, h - 4),
				Vector2(body_left - wing_slant, h - 4)
			])

	# Drop shadow behind card wing
	var shadow_poly := PackedVector2Array()
	for pt in outer_poly:
		shadow_poly.append(pt + Vector2(0, 3.5))
	draw_colored_polygon(shadow_poly, Color(0.12, 0.07, 0.12, 0.25))

	# White outer trim + primary colored trapezoid shell
	draw_colored_polygon(outer_poly, primary)
	var closed_outer := outer_poly.duplicate()
	closed_outer.append(outer_poly[0])
	draw_polyline(closed_outer, Color("ffffff") if active else Color(1, 1, 1, 0.85), 2.4, true)

	# White inner pill for Cash row
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color("fcfcfa")
	pill.border_color = darker.lightened(0.35)
	pill.set_border_width_all(1)
	pill.set_corner_radius_all(9)
	var pill_y := 38.0 if not bottom_aligned else 13.0
	var pill_rect := Rect2(body_left + 4.0, pill_y, (body_right - body_left) - 10.0, 42.0)
	draw_style_box(pill, pill_rect)

	# Banknote stack icon inside right side of white cash pill
	if not bankrupt:
		var icon_center := Vector2(pill_rect.end.x - 20.0, pill_rect.get_center().y)
		draw_banknote_icon(self, icon_center, 1.08)

	# Avatar rounded-square frame (on top of wing overlap!)
	var av_shadow := StyleBoxFlat.new()
	av_shadow.bg_color = Color(0.10, 0.06, 0.10, 0.30)
	av_shadow.set_corner_radius_all(14)
	draw_style_box(av_shadow, Rect2(av_pos + Vector2(0, 3), av_size))

	var av_box := StyleBoxFlat.new()
	av_box.bg_color = Color("2b303a") if bankrupt else primary.darkened(0.38)
	av_box.border_color = Color("ffd43b") if (is_vip or active) else Color("ffffff")
	av_box.set_border_width_all(4 if (is_vip or active) else 3)
	av_box.set_corner_radius_all(13)
	draw_style_box(av_box, Rect2(av_pos, av_size))

	# Owned properties pill badge tucked cleanly on outer bottom/top edge of avatar
	if owned_count > 0 and not bankrupt:
		var b_y := (av_pos.y + av_size.y - 14) if not bottom_aligned else (av_pos.y - 4)
		if is_vip and not bottom_aligned:
			b_y = av_pos.y - 4
		var prop_rect := Rect2(av_pos.x + (av_size.x - 36 if not right_aligned else 0), b_y, 36, 17)
		var prop_style := StyleBoxFlat.new()
		prop_style.bg_color = Color("1e293b")
		prop_style.border_color = Color("ffffff")
		prop_style.set_border_width_all(1)
		prop_style.set_corner_radius_all(8)
		draw_style_box(prop_style, prop_rect)
		draw_string(ThemeDB.fallback_font, Vector2(prop_rect.position.x, prop_rect.position.y + 12.5), "★%d" % owned_count, HORIZONTAL_ALIGNMENT_CENTER, prop_rect.size.x, 10, Color("ffd43b"))

	# VIP / Active golden ribbon crest under avatar (matches top-right VIP wreath vibe in reference!)
	if is_vip and not bankrupt:
		var vip_rect := Rect2(av_pos.x + 10, av_pos.y + av_size.y - 13, av_size.x - 20, 16)
		var vip_style := StyleBoxFlat.new()
		vip_style.bg_color = Color("f59f00")
		vip_style.border_color = Color("fff3bf")
		vip_style.set_border_width_all(1)
		vip_style.set_corner_radius_all(7)
		draw_style_box(vip_style, vip_rect)
		draw_string(ThemeDB.fallback_font, Vector2(vip_rect.position.x, vip_rect.position.y + 12), "BẠN", HORIZONTAL_ALIGNMENT_CENTER, vip_rect.size.x, 10, Color("ffffff"))
