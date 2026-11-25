extends RefCounted

const MoneyPile = preload("res://src/money_pile.gd")

# AAA Toy-Diorama Monopoly Board:
# - Clean, cohesive, ultra-legible 40-tile ring (PITCH 8.8, TILE_WIDTH 8.54, TILE_DEPTH 15.2)
# - ZERO mismatched dark buildings cluttering unowned tiles: tiles feature vivid pastel group headers,
#   CRISP 2-LINE ANISOTROPIC TYPOGRAPHY that you can actually read effortlessly, and cohesive stylized
#   3D houses/hotels that grow in the owner's color when bought & upgraded!
# - LIVING MINIATURE 3D WORLD IN THE CENTER surrounding a sunken circular Dice Arena!
# - 4 OVERSIZED SIGNATURE CORNER PLAZAS with RAISED 3D CAMERA-FACING SIGNBOARDS (never covered by models)!
# - Material caching + smart shadow culling for locked 60 FPS!

const PITCH := 8.8
const EDGE_OFFSET := 47.2
const CORNER_OFFSET := 49.0
const TILE_WIDTH := 8.54
const TILE_DEPTH := 15.2
const CORNER_SIZE := 18.0

const PLAYER_COLORS := [Color("f01e6b"), Color("1aa3ec"), Color("84bd22"), Color("f2bf18")]
const GROUP_COLORS := [
	Color("c97b53"), Color("38bdf8"), Color("ec5ca5"), Color("fb923c"),
	Color("f04e54"), Color("f4c430"), Color("43b868"), Color("536de8")
]

static var _bold_font: SystemFont
static var _mat_cache: Dictionary = {}

static func bold_font() -> SystemFont:
	if _bold_font == null:
		_bold_font = SystemFont.new()
		_bold_font.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial", "sans-serif"])
		_bold_font.font_weight = 900
	return _bold_font

static func tile_position(index: int) -> Vector3:
	match index:
		0: return Vector3(CORNER_OFFSET, 0.0, CORNER_OFFSET)
		10: return Vector3(-CORNER_OFFSET, 0.0, CORNER_OFFSET)
		20: return Vector3(-CORNER_OFFSET, 0.0, -CORNER_OFFSET)
		30: return Vector3(CORNER_OFFSET, 0.0, -CORNER_OFFSET)
	if index < 10:
		return Vector3((5 - index) * PITCH, 0.0, EDGE_OFFSET)
	if index < 20:
		return Vector3(-EDGE_OFFSET, 0.0, (15 - index) * PITCH)
	if index < 30:
		return Vector3((index - 25) * PITCH, 0.0, -EDGE_OFFSET)
	return Vector3(EDGE_OFFSET, 0.0, (index - 35) * PITCH)

static func camera_toward(side: int) -> Vector3:
	return Vector3(0.0, 0.0, 1.0) if side % 2 == 0 else Vector3(1.0, 0.0, 0.0)

static func path_position(index: int) -> Vector3:
	var pos := tile_position(index)
	match index:
		0: return pos + Vector3(3.0, 1.12, 3.0)
		10: return pos + Vector3(3.2, 1.12, 3.2)
		20: return pos + Vector3(3.2, 1.12, 3.2)
		30: return pos + Vector3(3.2, 1.12, 3.2)
	var side := index / 10
	var cam_dir := camera_toward(side)
	return pos + cam_dir * 0.55 + Vector3(0.0, 1.05, 0.0)

static func material(color: Color, roughness := 0.80, metallic := 0.0, alpha := false) -> StandardMaterial3D:
	var key := "%s:%.2f:%.2f:%d" % [color.to_html(true), roughness, metallic, 1 if alpha else 0]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	if alpha:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_cache[key] = result
	return result

static func box(parent: Node3D, position: Vector3, size: Vector3, color: Color, roughness := 0.80, cast_shadows := false) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	result.mesh = mesh
	result.material_override = material(color, roughness)
	result.position = position
	if not cast_shadows:
		result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(result)
	return result

static func cylinder(parent: Node3D, position: Vector3, top_r: float, bot_r: float, height: float, color: Color, segments := 20, cast_shadows := false) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = height
	mesh.radial_segments = segments
	result.mesh = mesh
	result.material_override = material(color, 0.72)
	result.position = position
	if not cast_shadows:
		result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(result)
	return result

static func contact_shadow(parent: Node3D, position: Vector3, rx: float, rz: float, opacity := 0.20) -> void:
	var sh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.02
	cm.radial_segments = 16
	sh.mesh = cm
	sh.scale = Vector3(rx, 1.0, rz)
	sh.material_override = material(Color(0.16, 0.14, 0.24, opacity), 1.0, 0.0, true)
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sh.position = position
	parent.add_child(sh)

static func model(parent: Node3D, id: String, position: Vector3, angle := 0.0, max_footprint := 6.0, max_height := 7.0, with_shadow := true, cast_shadows := true) -> Node3D:
	var scene: PackedScene = load("res://assets/polyfork/%s.glb" % id)
	var instance := scene.instantiate() as Node3D
	instance.position = position
	instance.rotation.y = angle
	parent.add_child(instance)
	var bounds := AABB()
	var first := true
	for mesh in instance.find_children("*", "MeshInstance3D", true, false):
		if not cast_shadows:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var transform: Transform3D = mesh.transform
		var ancestor := mesh.get_parent()
		while ancestor != instance:
			if ancestor is Node3D:
				transform = ancestor.transform * transform
			ancestor = ancestor.get_parent()
		var local_bounds: AABB = transform * mesh.get_aabb()
		bounds = local_bounds if first else bounds.merge(local_bounds)
		first = false
	if not first and max_footprint > 0.0:
		var factor := minf(max_footprint / maxf(0.1, maxf(bounds.size.x, bounds.size.z)), max_height / maxf(0.1, bounds.size.y))
		instance.scale = Vector3.ONE * factor
		if bounds.position.y < -0.05:
			instance.position.y -= bounds.position.y * factor
		if with_shadow:
			var srx := clampf(bounds.size.x * factor * 0.48, 1.2, 8.0)
			var srz := clampf(bounds.size.z * factor * 0.48, 1.2, 8.0)
			contact_shadow(parent, Vector3(position.x, position.y + 0.03, position.z), srx, srz, 0.20)
	return instance

static func flat_label(parent: Node3D, text: String, position: Vector3, rot_y_deg: float, color: Color, font_size: int, pixel_size := 0.026, max_width_px := 340.0, outline_col := Color(1, 1, 1, 0.92), outline_px := 6) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font = bold_font()
	lbl.font_size = font_size
	lbl.pixel_size = pixel_size
	lbl.modulate = color
	lbl.outline_modulate = outline_col
	lbl.outline_size = outline_px
	lbl.shaded = false
	lbl.double_sided = false
	lbl.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	lbl.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	lbl.render_priority = 4
	lbl.line_spacing = -6.0
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if max_width_px > 0.0 else TextServer.AUTOWRAP_OFF
	if max_width_px > 0.0:
		lbl.width = max_width_px
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.rotation_degrees = Vector3(-90.0, rot_y_deg, 0.0)
	lbl.position = position
	parent.add_child(lbl)
	return lbl

static func corner_signboard(parent: Node3D, text: String, pos: Vector3, badge_color: Color) -> void:
	# Raised 3D billboard plaque mounted at the front lip of each corner — 100% readable, NEVER covered by models!
	var sign_root := Node3D.new()
	sign_root.position = pos
	parent.add_child(sign_root)

	var lbl := Label3D.new()
	lbl.text = text
	lbl.font = bold_font()
	lbl.font_size = 76
	lbl.pixel_size = 0.032
	lbl.modulate = Color("ffffff")
	lbl.outline_modulate = badge_color.darkened(0.38)
	lbl.outline_size = 18
	lbl.shaded = false
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = false
	lbl.render_priority = 6
	lbl.position = Vector3(0, 1.4, 0)
	sign_root.add_child(lbl)

static func _format_tile_name_2lines(raw_name: String) -> String:
	var words := raw_name.to_upper().split(" ")
	if words.size() == 2:
		return "%s\n%s" % [words[0], words[1]]
	if words.size() > 2:
		return "%s\n%s" % [words[0], " ".join(words.slice(1))]
	return raw_name.to_upper()

static func _add_rainbow_wheel(parent: Node3D, center: Vector3) -> void:
	var palette := [
		Color("ff5c7c"), Color("ffa94d"), Color("ffe066"), Color("74d65c"),
		Color("38bdf8"), Color("6c86eb"), Color("b197fc"), Color("f783ac")
	]
	cylinder(parent, center, 2.95, 3.05, 0.14, Color("ffffff"), 24)
	for i in range(8):
		var slice := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(2.05, 0.16, 2.55)
		slice.mesh = prism
		slice.material_override = material(palette[i], 0.45)
		slice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang := i * TAU / 8.0
		slice.position = center + Vector3(sin(ang) * 1.25, 0.06, cos(ang) * 1.25)
		slice.rotation_degrees = Vector3(90.0, rad_to_deg(ang) + 180.0, 0.0)
		parent.add_child(slice)
	cylinder(parent, center + Vector3(0, 0.10, 0), 0.72, 0.78, 0.16, Color("ffffff"), 16)
	cylinder(parent, center + Vector3(0, 0.15, 0), 0.34, 0.34, 0.12, Color("ffd43b"), 14)

static func _add_tax_emblem(parent: Node3D, center: Vector3, rot_y_deg: float) -> void:
	var doc := Node3D.new()
	doc.position = center
	doc.rotation_degrees.y = rot_y_deg + 14.0
	parent.add_child(doc)
	box(doc, Vector3(0, 0.04, 0), Vector3(3.8, 0.10, 4.4), Color("cbd5e1"), 0.7)
	box(doc, Vector3(0, 0.10, 0), Vector3(3.5, 0.08, 4.1), Color("ffffff"), 0.55)
	for line_idx in range(3):
		box(doc, Vector3(-0.3, 0.16, -1.1 + line_idx * 0.78), Vector3(2.2, 0.04, 0.26), Color("94a3b8"), 0.65)
	box(doc, Vector3(0.75, 0.17, 1.2), Vector3(1.25, 0.06, 0.48), Color("ef4444"), 0.45)
	cylinder(doc, Vector3(-0.85, 0.24, 1.15), 0.58, 0.58, 0.26, Color("ffd43b"), 16)

static func _build_corner_pedestal(parent: Node3D, pos: Vector3, rim_color: Color, surface_color: Color) -> Node3D:
	contact_shadow(parent, Vector3(pos.x + 1.0, -2.30, pos.z + 1.0), 10.8, 10.8, 0.22)
	box(parent, pos + Vector3(0, -0.68, 0), Vector3(CORNER_SIZE + 0.5, 3.2, CORNER_SIZE + 0.5), Color("94a0b2"), 0.82)
	box(parent, pos + Vector3(0, 0.66, 0), Vector3(CORNER_SIZE, 0.68, CORNER_SIZE), rim_color, 0.62)
	box(parent, pos + Vector3(0, 0.98, 0), Vector3(CORNER_SIZE - 0.9, 0.12, CORNER_SIZE - 0.9), surface_color, 0.60)
	var stage := Node3D.new()
	stage.position = pos + Vector3(0, 1.04, 0)
	parent.add_child(stage)
	return stage

static func _build_corners_for_theme(root: Node3D, theme: int, animated_props: Array) -> void:
	var p0 := tile_position(0)
	var p10 := tile_position(10)
	var p20 := tile_position(20)
	var p30 := tile_position(30)

	if theme == 2:
		# === PHỐ HỘI — Festival Metropolis Corners ===
		var c0 := _build_corner_pedestal(root, p0, Color("84cc16"), Color("f2fce2"))
		model(c0, "amusement-park-entrance-arch-687549", Vector3(-3.2, 0.0, -1.6), PI / 2.0, 11.4, 10.4)
		model(c0, "cherry-blossom-tree-3f7ab7", Vector3(5.0, 0.0, 2.2), 0.3, 6.2, 7.6)
		model(c0, "city-taxi-eefa91", Vector3(-2.4, 0.0, 5.2), -PI / 2.0, 5.0, 3.5)
		corner_signboard(c0, "XUẤT PHÁT", Vector3(4.2, 0.6, 7.4), Color("65a30d"))

		var c10 := _build_corner_pedestal(root, p10, Color("38bdf8"), Color("e6f8fd"))
		cylinder(c10, Vector3(-1.2, 0.08, -1.0), 7.1, 7.4, 0.16, Color("56cfe1"), 24)
		cylinder(c10, Vector3(-1.8, 0.24, -1.4), 4.9, 5.5, 0.36, Color("f6e4b5"), 20)
		model(c10, "striped-river-lighthouse-90d74d", Vector3(-2.4, 0.42, -2.0), 0.6, 7.6, 13.5)
		model(c10, "palm-tree-a307da", Vector3(1.4, 0.40, -3.2), -0.4, 6.0, 8.0)
		var swan := model(c10, "swan-pedal-boat-8dc50b", Vector3(2.2, 0.16, 2.0), 0.8, 4.4, 4.0)
		animated_props.append({"node": swan, "kind": "bob", "base_y": swan.position.y, "phase": 0.4})
		corner_signboard(c10, "ĐẢO TÙ", Vector3(4.2, 0.6, 7.4), Color("0284c7"))

		var c20 := _build_corner_pedestal(root, p20, Color("f472b6"), Color("fdf2f8"))
		cylinder(c20, Vector3(-1.2, 0.10, -1.2), 7.2, 7.5, 0.18, Color("fce7f3"), 24)
		model(c20, "ferris-wheel-ca5b0b", Vector3(-2.6, 0.18, -2.4), deg_to_rad(45.0), 13.4, 15.6)
		var car := model(c20, "carousel-39cbc8", Vector3(3.4, 0.18, -1.8), 0.2, 6.8, 7.2)
		animated_props.append({"node": car, "kind": "spin", "speed": 0.55})
		corner_signboard(c20, "LỄ HỘI", Vector3(3.2, 0.8, 6.8), Color("db2777"))

		var c30 := _build_corner_pedestal(root, p30, Color("6366f1"), Color("eef2ff"))
		box(c30, Vector3(-0.5, 0.06, -0.5), Vector3(14.8, 0.10, 14.8), Color("cbd5e1"), 0.78)
		box(c30, Vector3(-1.2, 0.12, -1.2), Vector3(13.2, 0.05, 3.2), Color("64748b"), 0.80).rotation_degrees.y = -45.0
		model(c30, "twin-engine-piston-light-f417c7", Vector3(-1.2, 0.18, -1.0), deg_to_rad(-135.0), 11.2, 7.4)
		var heli := model(c30, "helicopter-9d1986", Vector3(3.4, 0.18, -4.0), deg_to_rad(-35.0), 7.2, 5.2)
		animated_props.append({"node": heli, "kind": "bob", "base_y": heli.position.y, "phase": 1.6})
		corner_signboard(c30, "VÀO TÙ", Vector3(6.8, 0.6, 4.2), Color("4f46e5"))

	elif theme == 1:
		# === VỊNH HẢI TẶC — Pirate Cove & Galleon Corners ===
		var c0 := _build_corner_pedestal(root, p0, Color("84cc16"), Color("f6f0dc"))
		model(c0, "cove-tavern-5861a6", Vector3(-2.4, 0.0, -2.4), deg_to_rad(45.0), 9.6, 10.8)
		model(c0, "jolly-roger-pole-803c5a", Vector3(4.2, 0.0, -3.4), 0.4, 5.0, 8.4)
		model(c0, "treasure-chest-c2ac4f", Vector3(-4.0, 0.0, 3.6), 0.6, 3.4, 3.2)
		corner_signboard(c0, "XUẤT PHÁT", Vector3(4.2, 0.6, 7.4), Color("65a30d"))

		var c10 := _build_corner_pedestal(root, p10, Color("06b6d4"), Color("e5f7fa"))
		cylinder(c10, Vector3(-1.0, 0.08, -1.0), 7.2, 7.5, 0.16, Color("4cc3d9"), 24)
		cylinder(c10, Vector3(-2.0, 0.24, -1.6), 5.2, 5.7, 0.36, Color("ecd59e"), 20)
		model(c10, "smuggler-cave-mouth-69a07e", Vector3(-2.8, 0.38, -2.4), deg_to_rad(55.0), 8.6, 8.6)
		model(c10, "palm-tree-a307da", Vector3(1.6, 0.38, -3.6), 0.5, 6.4, 8.4)
		model(c10, "wrecked-hull-section-ca6755", Vector3(1.4, 0.16, 2.0), 0.9, 5.6, 4.6)
		corner_signboard(c10, "ĐẢO TÙ", Vector3(4.2, 0.6, 7.4), Color("0891b2"))

		var c20 := _build_corner_pedestal(root, p20, Color("f59e0b"), Color("e4f7f8"))
		cylinder(c20, Vector3(-0.8, 0.10, -0.8), 7.5, 7.7, 0.20, Color("38b6cf"), 24)
		var gal := model(c20, "pirate-galleon-2e9aea", Vector3(-1.2, 0.22, -1.2), deg_to_rad(45.0), 15.2, 14.8)
		animated_props.append({"node": gal, "kind": "rock", "phase": 0.0})
		corner_signboard(c20, "LỄ HỘI", Vector3(3.2, 0.8, 6.8), Color("d97706"))

		var c30 := _build_corner_pedestal(root, p30, Color("6366f1"), Color("ebf1fa"))
		cylinder(c30, Vector3(1.4, 0.08, -1.4), 6.6, 6.9, 0.16, Color("58c4dc"), 24)
		model(c30, "old-lighthouse-48ca6c", Vector3(2.2, 0.18, -2.6), deg_to_rad(-45.0), 9.2, 13.6)
		var sloop := model(c30, "pirate-sloop-d8ead0", Vector3(-2.4, 0.18, 1.4), deg_to_rad(-35.0), 8.0, 8.6)
		animated_props.append({"node": sloop, "kind": "rock", "phase": 1.4})
		corner_signboard(c30, "VÀO TÙ", Vector3(6.8, 0.6, 4.2), Color("4338ca"))

	else:
		# === NÔNG TRẠI NẮNG — Harvest Valley Corners ===
		var c0 := _build_corner_pedestal(root, p0, Color("84cc16"), Color("f3fae6"))
		model(c0, "red-barn-d41683", Vector3(-2.4, 0.0, -2.4), deg_to_rad(45.0), 9.4, 10.0)
		model(c0, "compact-tractor-35b84b", Vector3(-3.6, 0.0, 3.6), deg_to_rad(-80.0), 5.0, 4.2)
		model(c0, "sunflower-80ce15", Vector3(4.2, 0.0, -3.2), 0.2, 3.2, 4.4)
		corner_signboard(c0, "XUẤT PHÁT", Vector3(4.2, 0.6, 7.4), Color("65a30d"))

		var c10 := _build_corner_pedestal(root, p10, Color("14b8a6"), Color("ebfaf4"))
		cylinder(c10, Vector3(-1.4, 0.08, -1.2), 6.9, 7.2, 0.14, Color("7ad7eb"), 24)
		cylinder(c10, Vector3(-2.0, 0.22, -1.8), 5.1, 5.5, 0.30, Color("cbe8a8"), 20)
		model(c10, "water-mill-b31972", Vector3(-2.4, 0.36, -2.2), deg_to_rad(45.0), 8.6, 10.4)
		model(c10, "cow-c61a66", Vector3(1.6, 0.20, 2.2), deg_to_rad(65.0), 4.2, 3.6)
		corner_signboard(c10, "ĐẢO TÙ", Vector3(4.2, 0.6, 7.4), Color("0d9488"))

		var c20 := _build_corner_pedestal(root, p20, Color("f59e0b"), Color("fdf8e6"))
		cylinder(c20, Vector3(-1.0, 0.12, -1.0), 7.1, 7.5, 0.28, Color("d8eba8"), 24)
		model(c20, "windmill-3aad49", Vector3(-2.0, 0.26, -2.0), deg_to_rad(45.0), 10.6, 14.5)
		model(c20, "apple-tree-ef0ba0", Vector3(3.4, 0.26, -2.2), 0.5, 6.0, 7.0)
		model(c20, "sheep-7b0187", Vector3(1.8, 0.26, 2.4), -0.5, 3.2, 2.8)
		corner_signboard(c20, "LỄ HỘI", Vector3(3.2, 0.8, 6.8), Color("d97706"))

		var c30 := _build_corner_pedestal(root, p30, Color("3b82f6"), Color("eef3fc"))
		box(c30, Vector3(-0.6, 0.08, -0.6), Vector3(14.6, 0.12, 3.0), Color("8d99ae"), 0.85).rotation_degrees.y = -45.0
		model(c30, "country-station-building-2d8f5e", Vector3(2.2, 0.14, -2.4), deg_to_rad(-45.0), 9.4, 9.6)
		model(c30, "tender-steam-locomotive-8e2a82", Vector3(-2.2, 0.18, 1.8), deg_to_rad(-45.0), 10.4, 5.6)
		corner_signboard(c30, "VÀO TÙ", Vector3(6.8, 0.6, 4.2), Color("2563eb"))

static func _build_living_center_world(root: Node3D, theme: int, animated_props: Array) -> void:
	# Rich, living miniature 3D world surrounding a clear central Circular Dice Arena (radius ~17)!
	var ocean := theme == 1
	var farm := theme == 0
	box(root, Vector3(0, 0.62, 0), Vector3(79.2, 0.56, 79.2), Color("677287"), 0.86)
	box(root, Vector3(0, 0.78, 0), Vector3(75.6, 0.34, 75.6), Color("eef2f6"), 0.72)

	var surface := box(root, Vector3(0, 0.88, 0), Vector3(74.0, 0.22, 74.0), Color("5bc8d8") if ocean else Color("8fd05b"))
	if ocean:
		var water := ShaderMaterial.new()
		water.shader = load("res://assets/water.gdshader")
		surface.material_override = water

		# Central Elevated Wooden Ship-Deck / Sandbar Dice Arena so dice land cleanly on a bright deck!
		cylinder(root, Vector3(0, 0.96, 0), 18.6, 19.6, 0.28, Color("f2dfa6"), 32)
		cylinder(root, Vector3(0, 1.06, 0), 16.4, 16.9, 0.20, Color("d4a36a"), 32)
		cylinder(root, Vector3(0, 1.11, 0), 15.2, 15.2, 0.12, Color("e6bd85"), 32)

		# 4 Lush Tropical Archipelago Vignettes around the lagoon!
		# NW Island: Lookout Watchtower + Palm + Treasure
		cylinder(root, Vector3(-25, 1.04, -24), 8.2, 9.2, 0.45, Color("f3dfa2"), 20)
		cylinder(root, Vector3(-25, 1.24, -24), 5.6, 6.4, 0.22, Color("84cc58"), 18)
		model(root, "lookout-watchtower-f1a5ce", Vector3(-26, 1.35, -25), 0.6, 6.2, 11.5)
		model(root, "palm-tree-a307da", Vector3(-21, 1.32, -27), 0.2, 6.5, 8.8)
		model(root, "treasure-chest-c2ac4f", Vector3(-22, 1.32, -21), 0.9, 3.0, 2.8)

		# NE Sailing Brigantine + Cargo Barge bobbing on the lagoon
		var brig := model(root, "pirate-brigantine-c29c57", Vector3(23, 1.04, -23), deg_to_rad(-135.0), 14.5, 13.5)
		animated_props.append({"node": brig, "kind": "rock", "phase": 0.8})
		var boat1 := model(root, "small-fishing-boat-4ac0e3", Vector3(26, 1.04, -7), deg_to_rad(-40.0), 7.5, 5.0)
		animated_props.append({"node": boat1, "kind": "bob", "base_y": boat1.position.y, "phase": 2.1})

		# SW Harbor Pier + Fisherman Shack + Crane
		cylinder(root, Vector3(-24, 1.04, 24), 8.4, 9.4, 0.45, Color("f3dfa2"), 20)
		model(root, "fisherman-shack-ea9b2b", Vector3(-26, 1.26, 25), deg_to_rad(45.0), 7.8, 7.6)
		model(root, "dock-cargo-crane-ccd97f", Vector3(-19, 1.26, 26), deg_to_rad(30.0), 5.8, 8.2)
		model(root, "palm-tree-a307da", Vector3(-28, 1.26, 19), 1.4, 6.2, 8.2)

		# SE Blue-Domed Tropical Island Village
		cylinder(root, Vector3(24, 1.04, 24), 8.6, 9.6, 0.45, Color("f3dfa2"), 20)
		cylinder(root, Vector3(24, 1.24, 24), 6.2, 7.0, 0.22, Color("84cc58"), 18)
		model(root, "blue-domed-chapel-297391", Vector3(25, 1.35, 24), deg_to_rad(-135.0), 8.5, 9.2)
		model(root, "boathouse-cf20e6", Vector3(19, 1.30, 27), deg_to_rad(-120.0), 6.8, 6.2)
		model(root, "palm-tree-a307da", Vector3(27, 1.32, 19), -0.5, 6.4, 8.4)

	elif farm:
		var field := ShaderMaterial.new()
		field.shader = load("res://assets/field.gdshader")
		field.set_shader_parameter("grass_light", Color("86c648"))
		field.set_shader_parameter("grass_dark", Color("78b83d"))
		surface.material_override = field

		# Central Sunlit Cobblestone & Clover Harvest Dice Plaza
		cylinder(root, Vector3(0, 0.99, 0), 17.6, 18.2, 0.16, Color("f7ecd0"), 32)
		cylinder(root, Vector3(0, 1.05, 0), 15.8, 16.0, 0.10, Color("a9da68"), 32)

		# NW Orchard & Farmhouse Cluster
		model(root, "gabled-farmhouse-c7534f", Vector3(-24, 1.0, -24), deg_to_rad(45.0), 9.6, 9.6)
		model(root, "grain-silo-58ca67", Vector3(-30, 1.0, -18), 0.2, 5.2, 11.2)
		model(root, "apple-tree-ef0ba0", Vector3(-18, 1.0, -28), 0.7, 6.4, 7.4)
		model(root, "beehive-2e70bf", Vector3(-15, 1.0, -24), 0.4, 2.4, 2.6)

		# NE Greenhouse, Windpump & Market Stand
		model(root, "greenhouse-53ab6d", Vector3(24, 1.0, -24), deg_to_rad(-45.0), 9.4, 7.8)
		model(root, "windmill-pump-2993a4", Vector3(29, 1.0, -17), 0.3, 4.8, 10.6)
		model(root, "roadside-farm-stand-e218ca", Vector3(17, 1.0, -27), deg_to_rad(-30.0), 5.2, 5.0)
		model(root, "sunflower-80ce15", Vector3(20, 1.0, -20), 0.5, 3.0, 4.2)

		# SW Pond, Open Stable & Grazing Animals
		cylinder(root, Vector3(-23, 1.02, 23), 7.6, 8.0, 0.14, Color("6bd3ea"), 22)
		model(root, "open-stable-dbf2d5", Vector3(-26, 1.0, 13), deg_to_rad(90.0), 7.4, 5.4)
		var cow1 := model(root, "cow-c61a66", Vector3(-15, 1.0, 25), deg_to_rad(30.0), 4.2, 3.6)
		var sheep1 := model(root, "sheep-7b0187", Vector3(-18, 1.0, 29), deg_to_rad(-40.0), 3.4, 2.8)
		animated_props.append({"node": cow1, "kind": "bob", "base_y": cow1.position.y, "phase": 0.2})
		animated_props.append({"node": sheep1, "kind": "bob", "base_y": sheep1.position.y, "phase": 1.7})

		# SE Timber Barn, Tractor & Apple Orchard
		model(root, "timber-barn-90b3ce", Vector3(25, 1.0, 24), deg_to_rad(-135.0), 9.6, 9.2)
		model(root, "marigold-pickup-f4b6f9", Vector3(17, 1.0, 26), deg_to_rad(-65.0), 6.2, 4.4)
		model(root, "apple-tree-ef0ba0", Vector3(28, 1.0, 16), 1.2, 6.4, 7.6)
		model(root, "hay-bale-079e8c", Vector3(21, 1.0, 19), 0.5, 3.2, 2.4)

	else:
		# === PHỐ HỘI — Living Pastel City Park, Canal & Monument World ===
		var field := ShaderMaterial.new()
		field.shader = load("res://assets/field.gdshader")
		surface.material_override = field

		# Central Circular Marble & Lawn Dice Arena Plaza (crisp sunlit focal ring!)
		cylinder(root, Vector3(0, 0.99, 0), 17.8, 18.4, 0.16, Color("f5f3ef"), 32)
		cylinder(root, Vector3(0, 1.05, 0), 15.8, 16.2, 0.12, Color("9ad460"), 32)

		# Scenic Diagonal Sky-Blue Park Lake in SW & NE corners
		cylinder(root, Vector3(-24, 1.01, 24), 9.2, 9.6, 0.14, Color("63d2ea"), 24)
		var swan_c := model(root, "swan-pedal-boat-8dc50b", Vector3(-22, 1.08, 22), deg_to_rad(35.0), 4.6, 4.2)
		animated_props.append({"node": swan_c, "kind": "bob", "base_y": swan_c.position.y, "phase": 0.9})
		model(root, "chinese-hexagonal-pavilion-09d04e", Vector3(-29, 1.02, 29), deg_to_rad(45.0), 7.6, 8.0)
		model(root, "cherry-blossom-tree-3f7ab7", Vector3(-15, 1.02, 29), 0.6, 6.8, 8.2)
		model(root, "cherry-blossom-tree-3f7ab7", Vector3(-30, 1.02, 15), 1.5, 6.5, 7.8)

		# NW Cultural Plaza: Domed Church + Bank + Cherry Blossoms
		box(root, Vector3(-25, 1.01, -25), Vector3(17.5, 0.14, 17.5), Color("efeae2"), 0.72)
		model(root, "domed-church-dcbe85", Vector3(-26, 1.08, -26), deg_to_rad(45.0), 10.6, 12.2)
		model(root, "ramen-yatai-stall-53974b", Vector3(-19, 1.08, -22), deg_to_rad(45.0), 5.0, 4.8)
		model(root, "cherry-blossom-tree-3f7ab7", Vector3(-28, 1.08, -17), 0.3, 6.6, 8.0)

		# NE Grand Downtown Skyline Cluster: tucked cleanly inside center plaza so it never crosses top-right prices
		box(root, Vector3(23, 1.01, -23), Vector3(16.5, 0.14, 16.5), Color("e6ebf2"), 0.72)
		model(root, "airport-hotel-1a1e0a", Vector3(23, 1.08, -22), deg_to_rad(-45.0), 8.2, 10.2)
		model(root, "hotel-b43f66", Vector3(17, 1.08, -25), deg_to_rad(-45.0), 6.8, 7.6)
		model(root, "city-bus-49fd97", Vector3(21, 1.08, -16), deg_to_rad(-45.0), 6.8, 4.2)
		model(root, "cherry-blossom-tree-3f7ab7", Vector3(14, 1.08, -20), 1.1, 5.8, 7.0)

		# SE Cozy Neighborhood Park: Cozy Houses + Cherry Blossoms + Taxi
		box(root, Vector3(25, 1.01, 25), Vector3(17.5, 0.14, 17.5), Color("f2ece4"), 0.72)
		model(root, "two-storey-family-house-c63c4a", Vector3(27, 1.08, 25), deg_to_rad(-135.0), 8.2, 9.2)
		model(root, "porch-front-cottage-620c29", Vector3(21, 1.08, 28), deg_to_rad(-135.0), 7.4, 7.6)
		model(root, "cherry-blossom-tree-3f7ab7", Vector3(28, 1.08, 17), -0.4, 6.8, 8.2)
		model(root, "city-taxi-eefa91", Vector3(18, 1.08, 20), deg_to_rad(-135.0), 5.2, 3.6)

static func _add_station_emblem(parent: Node3D, pos: Vector3, rot_y_deg: float, theme: int) -> void:
	var id := "city-bus-49fd97" if theme == 2 else ("small-fishing-boat-4ac0e3" if theme == 1 else "tank-steam-locomotive-314bb1")
	model(parent, id, pos, deg_to_rad(rot_y_deg), 5.0, 3.6, false, false)

static func _add_utility_emblem(parent: Node3D, pos: Vector3, is_water: bool) -> void:
	var id := "fuel-farm-tank-ed67f0" if is_water else "windpump-tower-1633a9"
	model(parent, id, pos, 0.0, 3.6, 5.2, false, false)

static func build(game, theme: int) -> Node3D:
	var root := Node3D.new()
	var animated_props: Array = []

	# Soft pastel drop shadow + clean 2-tone architectural stone board base
	var board_shadow := MeshInstance3D.new()
	var shadow_mesh := BoxMesh.new()
	shadow_mesh.size = Vector3(114.5, 0.1, 114.5)
	board_shadow.mesh = shadow_mesh
	board_shadow.material_override = material(Color(0.22, 0.18, 0.30, 0.22), 1.0, 0.0, true)
	board_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	board_shadow.position = Vector3(1.6, -2.35, 1.6)
	root.add_child(board_shadow)

	box(root, Vector3(0, -1.22, 0), Vector3(111.2, 2.25, 111.2), Color("8e99ab"), 0.84)
	box(root, Vector3(0, -0.02, 0), Vector3(109.6, 0.92, 109.6), Color("dde4ee"), 0.76)

	_build_living_center_world(root, theme, animated_props)
	_build_corners_for_theme(root, theme, animated_props)

	var markers: Array = []
	var buildings: Array = []
	var plinths: Array = []

	for index in range(40):
		var pos := tile_position(index)
		var tile: Dictionary = game.tiles[index]
		var side := index / 10
		var is_corner := index % 10 == 0
		var cam_dir := camera_toward(side)
		var rot_y_deg := 0.0 if side % 2 == 0 else 90.0

		if is_corner:
			var dm := Node3D.new()
			root.add_child(dm)
			markers.append(dm)
			var db := Node3D.new()
			root.add_child(db)
			buildings.append(db)
			plinths.append(null)
			continue

		# Crisp, cohesive pastel-ivory Monopoly tile (NO messy mismatched buildings on unowned lots!)
		var tile_size := Vector3(TILE_WIDTH, 0.90, TILE_DEPTH) if side % 2 == 0 else Vector3(TILE_DEPTH, 0.90, TILE_WIDTH)
		var top_size := Vector3(TILE_WIDTH - 0.30, 0.11, TILE_DEPTH - 0.34) if side % 2 == 0 else Vector3(TILE_DEPTH - 0.34, 0.11, TILE_WIDTH - 0.30)
		box(root, pos + Vector3(0, 0.52, 0), tile_size, Color("bac3d2"), 0.78)
		box(root, pos + Vector3(0, 0.97, 0), top_size, Color("fcfdfe"), 0.66)

		# Wide camera-facing price bevel strip (3.75 deep)
		var strip_size := Vector3(TILE_WIDTH - 0.30, 0.13, 3.75) if side % 2 == 0 else Vector3(3.75, 0.13, TILE_WIDTH - 0.30)
		var divider_size := Vector3(TILE_WIDTH - 0.30, 0.15, 0.18) if side % 2 == 0 else Vector3(0.18, 0.15, TILE_WIDTH - 0.30)
		box(root, pos + cam_dir * 5.52 + Vector3(0, 1.00, 0), strip_size, Color("eef2f8"), 0.62)
		box(root, pos + cam_dir * 3.60 + Vector3(0, 1.02, 0), divider_size, Color("b4bfd0"), 0.74)

		# Bold, saturated Monopoly Group Color Header Band at the back of property tiles!
		var group_color: Color = GROUP_COLORS[tile.group] if tile.group >= 0 else (Color("64748b") if tile.price > 0 else Color("cbd5e1"))
		var plinth: MeshInstance3D = null
		if tile.group >= 0:
			var band_size := Vector3(TILE_WIDTH - 0.44, 0.16, 3.35) if side % 2 == 0 else Vector3(3.35, 0.16, TILE_WIDTH - 0.44)
			plinth = box(root, pos - cam_dir * 5.55 + Vector3(0, 1.03, 0), band_size, group_color, 0.52)
		elif index in [5, 15, 25, 35]:
			_add_station_emblem(root, pos - cam_dir * 4.95 + Vector3(0, 1.04, 0), rot_y_deg, theme)
		elif index in [12, 28]:
			_add_utility_emblem(root, pos - cam_dir * 4.95 + Vector3(0, 1.04, 0), index == 28)
		plinths.append(plinth)

		var marker_size := Vector3(TILE_WIDTH - 0.32, 0.20, 0.72) if side % 2 == 0 else Vector3(0.72, 0.20, TILE_WIDTH - 0.32)
		var owner_marker := box(root, pos + cam_dir * 7.15 + Vector3(0, 1.06, 0), marker_size, group_color, 0.42)
		owner_marker.visible = false
		markers.append(owner_marker)

		# Cohesive stylized 3D houses/hotel slot on the back band (grows dynamically when bought!)
		var building := Node3D.new()
		building.position = pos - cam_dir * 5.25 + Vector3(0, 1.12, 0)
		building.rotation_degrees.y = rot_y_deg
		root.add_child(building)
		buildings.append(building)

		# ULTRA-LEGIBLE, HIGH-CONTRAST 2-LINE TILE NAMES (zero mid-word breaks!) & LARGE BOLD PRICES!
		if tile.price > 0:
			flat_label(root, "%dK" % tile.price, pos + cam_dir * 5.58 + Vector3(0, 1.12, 0), rot_y_deg, Color("0f172a"), 118, 0.0265, 0.0)
			flat_label(root, _format_tile_name_2lines(tile.name), pos - cam_dir * 0.15 + Vector3(0, 1.09, 0), rot_y_deg, Color("1e293b"), 76, 0.0225, 0.0)
		elif index in [2, 7, 17, 22, 33, 36]:
			_add_rainbow_wheel(root, pos - cam_dir * 1.85 + Vector3(0, 1.04, 0))
			flat_label(root, tile.name.to_upper(), pos + cam_dir * 5.52 + Vector3(0, 1.12, 0), rot_y_deg, Color("1e293b"), 78, 0.0225, 0.0)
		elif index in [4, 38]:
			_add_tax_emblem(root, pos - cam_dir * 2.55 + Vector3(0, 1.04, 0), rot_y_deg)
			flat_label(root, "THUẾ", pos + cam_dir * 1.45 + Vector3(0, 1.09, 0), rot_y_deg, Color("1e293b"), 82, 0.0235, 0.0)
			flat_label(root, "100K", pos + cam_dir * 5.58 + Vector3(0, 1.12, 0), rot_y_deg, Color("dc2626"), 114, 0.026, 0.0)

	var money_stacks := MoneyPile.create_all(root, PLAYER_COLORS)
	root.set_meta("markers", markers)
	root.set_meta("buildings", buildings)
	root.set_meta("plinths", plinths)
	root.set_meta("money_stacks", money_stacks)
	root.set_meta("animated_props", animated_props)
	root.set_meta("build_states", {})
	return root

static func _make_toy_house(parent: Node3D, pos: Vector3, owner_color: Color, scale_f := 1.0) -> void:
	var h := Node3D.new()
	h.position = pos
	h.scale = Vector3.ONE * scale_f
	parent.add_child(h)
	box(h, Vector3(0, 0.85, 0), Vector3(1.65, 1.70, 1.75), Color("ffffff"), 0.48, true)
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(2.05, 1.15, 2.02)
	roof.mesh = prism
	roof.material_override = material(owner_color, 0.38)
	roof.position = Vector3(0, 2.25, 0)
	h.add_child(roof)
	box(h, Vector3(-0.40, 1.0, 0.89), Vector3(0.36, 0.40, 0.06), Color("ffe066"), 0.35)
	box(h, Vector3(0.40, 1.0, 0.89), Vector3(0.36, 0.40, 0.06), Color("ffe066"), 0.35)
	box(h, Vector3(0.0, 0.44, 0.89), Vector3(0.38, 0.78, 0.06), owner_color.darkened(0.20), 0.45)

static func _make_toy_hotel(parent: Node3D, owner_color: Color) -> void:
	var hotel := Node3D.new()
	parent.add_child(hotel)
	box(hotel, Vector3(0, 0.30, 0), Vector3(6.4, 0.6, 2.7), owner_color.lightened(0.22), 0.48)
	box(hotel, Vector3(-1.45, 2.85, 0), Vector3(2.6, 5.1, 2.3), Color("ffffff"), 0.42, true)
	box(hotel, Vector3(-1.45, 5.65, 0), Vector3(2.9, 0.62, 2.55), owner_color, 0.36)
	box(hotel, Vector3(1.55, 2.15, 0), Vector3(2.45, 3.7, 2.2), owner_color, 0.42, true)
	box(hotel, Vector3(1.55, 4.18, 0), Vector3(2.7, 0.50, 2.45), Color("ffd43b"), 0.32)
	for f in range(3):
		box(hotel, Vector3(-1.45, 1.45 + f * 1.25, 1.18), Vector3(1.85, 0.48, 0.06), Color("bae6fd"), 0.28)
	for g in range(2):
		box(hotel, Vector3(1.55, 1.45 + g * 1.20, 1.13), Vector3(1.75, 0.44, 0.06), Color("fff3bf"), 0.28)
	box(hotel, Vector3(-1.45, 6.70, 0), Vector3(0.14, 1.55, 0.14), Color("ffffff"))
	box(hotel, Vector3(-0.78, 7.10, 0), Vector3(1.30, 0.72, 0.12), Color("ffd43b"), 0.35)

static func update_tile_buildings(board: Node3D, index: int, owner: int, level: int, mortgaged: bool, owner_color: Color) -> void:
	if index % 10 == 0:
		return
	var states: Dictionary = board.get_meta("build_states")
	var state_key := "%d:%d:%d" % [owner, level, 1 if mortgaged else 0]
	var markers: Array = board.get_meta("markers")
	if index < markers.size():
		var marker: MeshInstance3D = markers[index]
		marker.visible = owner >= 0
		if owner >= 0:
			marker.material_override.albedo_color = Color("94a3b8") if mortgaged else owner_color

	if states.get(index, "") == state_key:
		return
	states[index] = state_key

	var buildings: Array = board.get_meta("buildings")
	var slot: Node3D = buildings[index]
	for child in slot.get_children():
		child.queue_free()

	if owner < 0:
		return
	var paint := Color("94a3b8") if mortgaged else owner_color
	if mortgaged:
		box(slot, Vector3(0, 0.32, 0), Vector3(4.0, 0.60, 1.6), Color("64748b"), 0.7)
		flat_label(slot, "THẾ CHẤP", Vector3(0, 0.66, 0), 0.0, Color("ffffff"), 48, 0.018, 280.0, Color("334155"), 4)
		return
	if level == 0:
		box(slot, Vector3(-2.6, 1.45, 0), Vector3(0.18, 2.9, 0.18), Color("ffffff"), 0.45)
		box(slot, Vector3(-1.7, 2.40, 0), Vector3(1.75, 0.98, 0.16), paint, 0.38)
		_make_toy_house(slot, Vector3(1.1, 0.0, 0.0), paint, 0.85)
	elif level <= 4:
		var spacing := 1.82
		var start_x := -0.5 * (level - 1) * spacing
		var sc := 1.02 if level <= 3 else 0.88
		for i in range(level):
			_make_toy_house(slot, Vector3(start_x + i * spacing, 0.0, 0.0), paint, sc)
	else:
		_make_toy_hotel(slot, paint)
