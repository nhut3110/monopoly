extends RefCounted

# 3D beveled casino dice system with 4 selectable skins, impact VFX bursts,
# ground-tracking shadows, and parabolic multi-bounce throws into the center pitch.

const SKINS := [
	{
		"id": "obsidian_gold",
		"name": "Đen Hoàng Kim",
		"subtitle": "Đen nhám sang trọng · Chấm vàng kim · Tia sao vàng",
		"body": Color("1e1f26"),
		"bevel": Color("323440"),
		"pip": Color("f7cb45"),
		"pip_ace": Color("ffd859"),
		"vfx": Color("ffd43b"),
		"roughness": 0.34,
		"metallic": 0.18
	},
	{
		"id": "royal_ivory",
		"name": "Ngà Cổ Điển",
		"subtitle": "Trắng ngà bóng · Nút 1 đỏ son · Sóng sáng ngọc",
		"body": Color("faf6ed"),
		"bevel": Color("e5decb"),
		"pip": Color("1e242e"),
		"pip_ace": Color("e03131"),
		"vfx": Color("74c0fc"),
		"roughness": 0.24,
		"metallic": 0.05
	},
	{
		"id": "ruby_vegas",
		"name": "Hồng Ngọc Casino",
		"subtitle": "Đỏ Ruby rực rỡ · Chấm tuyết trắng · Pháo sáng đỏ",
		"body": Color("d62447"),
		"bevel": Color("f24968"),
		"pip": Color("ffffff"),
		"pip_ace": Color("ffe066"),
		"vfx": Color("ff6b6b"),
		"roughness": 0.22,
		"metallic": 0.15
	},
	{
		"id": "jade_cyber",
		"name": "Ngọc Bích Neon",
		"subtitle": "Xanh lục bảo · Chấm ánh bạc · Vòng xung lực xanh",
		"body": Color("0b9e73"),
		"bevel": Color("2cd4a2"),
		"pip": Color("f8fafc"),
		"pip_ace": Color("ffe885"),
		"vfx": Color("38d9a9"),
		"roughness": 0.25,
		"metallic": 0.22
	}
]

const LAUNCH_ORIGINS := [
	Vector3(-34.0, 18.0, -6.0),
	Vector3(-6.0, 18.0, -34.0),
	Vector3(6.0, 18.0, 34.0),
	Vector3(34.0, 18.0, 6.0)
]

const REST_POSITIONS := [
	Vector3(-6.8, 3.85, -2.4),
	Vector3(6.8, 3.85, 2.8)
]

const REST_YAWS := [-0.28, 0.34]

static func _mat(color: Color, roughness := 0.35, metallic := 0.0, emission := false, alpha := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if emission:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.65
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func create_die_pair(board: Node3D, skin_index: int) -> Dictionary:
	var dice: Array = []
	var dice_values: Array = []
	var shadows: Array = []

	for index in range(2):
		# Ground shadow disc that follows the die horizontally on the grass
		var shadow := MeshInstance3D.new()
		var s_mesh := CylinderMesh.new()
		s_mesh.top_radius = 3.2
		s_mesh.bottom_radius = 3.2
		s_mesh.height = 0.04
		s_mesh.radial_segments = 20
		shadow.mesh = s_mesh
		shadow.material_override = _mat(Color(0.08, 0.12, 0.06, 0.32), 1.0, 0.0, false, true)
		shadow.position = Vector3(REST_POSITIONS[index].x, 1.03, REST_POSITIONS[index].z)
		board.add_child(shadow)
		shadows.append(shadow)

		var die := Node3D.new()
		die.name = "Die_%d" % index
		die.position = REST_POSITIONS[index]
		die.rotation = Vector3(0.0, REST_YAWS[index], 0.0)
		board.add_child(die)

		var body_root := Node3D.new()
		body_root.name = "Body"
		die.add_child(body_root)

		var pip_group := Node3D.new()
		pip_group.name = "Pips"
		die.add_child(pip_group)

		dice.append(die)
		dice_values.append(pip_group)

	var bundle := {"dice": dice, "dice_values": dice_values, "shadows": shadows}
	apply_skin(bundle, skin_index, [5, 2])
	return bundle

static func apply_skin(bundle: Dictionary, skin_index: int, values: Array) -> void:
	var skin: Dictionary = SKINS[clampi(skin_index, 0, SKINS.size() - 1)]
	var body_mat := _mat(skin.body, skin.roughness, skin.metallic)
	var bevel_mat := _mat(skin.bevel, skin.roughness + 0.08, skin.metallic * 0.8)

	for i in range(2):
		var die: Node3D = bundle.dice[i]
		var body_root: Node3D = die.get_node("Body")
		for c in body_root.get_children():
			c.free()
		# Chamfered beveled casino cube: inner rounded-edge bevel core + 3 orthogonal face slabs
		var core := MeshInstance3D.new()
		var core_mesh := BoxMesh.new()
		core_mesh.size = Vector3(5.05, 5.05, 5.05)
		core.mesh = core_mesh
		core.material_override = bevel_mat
		body_root.add_child(core)

		for slab_size in [Vector3(5.36, 4.55, 4.55), Vector3(4.55, 5.36, 4.55), Vector3(4.55, 4.55, 5.36)]:
			var slab := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = slab_size
			slab.mesh = mesh
			slab.material_override = body_mat
			body_root.add_child(slab)

		set_die_value(bundle, i, values[i] if i < values.size() and values[i] > 0 else (5 if i == 0 else 2), skin_index)

static func set_die_value(bundle: Dictionary, index: int, value: int, skin_index: int) -> void:
	var v := clampi(value, 1, 6)
	var skin: Dictionary = SKINS[clampi(skin_index, 0, SKINS.size() - 1)]
	var pip_mat := _mat(skin.pip, 0.25, 0.35)
	var ace_mat := _mat(skin.pip_ace, 0.22, 0.35)

	var group: Node3D = bundle.dice_values[index]
	for child in group.get_children():
		child.free()

	var patterns := {
		1: [4],
		2: [0, 8],
		3: [0, 4, 8],
		4: [0, 2, 6, 8],
		5: [0, 2, 4, 6, 8],
		6: [0, 2, 3, 5, 6, 8]
	}
	var front := 2 if v not in [2, 5] else 1
	var left := 1
	while left in [v, 7 - v, front, 7 - front]:
		left += 1

	var faces := [
		["Top", v, Vector3.UP, Vector3.RIGHT, Vector3.FORWARD],
		["Bottom", 7 - v, Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
		["Front", front, Vector3.BACK, Vector3.RIGHT, Vector3.UP],
		["Back", 7 - front, Vector3.FORWARD, Vector3.LEFT, Vector3.UP],
		["Left", left, Vector3.LEFT, Vector3.FORWARD, Vector3.UP],
		["Right", 7 - left, Vector3.RIGHT, Vector3.BACK, Vector3.UP]
	]

	var sphere := SphereMesh.new()
	sphere.radius = 0.38
	sphere.height = 0.32
	sphere.radial_segments = 12
	sphere.rings = 6

	var ace_sphere := SphereMesh.new()
	ace_sphere.radius = 0.48
	ace_sphere.height = 0.36
	ace_sphere.radial_segments = 14
	ace_sphere.rings = 6

	for face in faces:
		var face_node := Node3D.new()
		face_node.name = face[0]
		group.add_child(face_node)
		var face_val: int = face[1]
		for dot in patterns.get(face_val, []):
			var pip := MeshInstance3D.new()
			pip.mesh = ace_sphere if face_val == 1 else sphere
			pip.material_override = ace_mat if face_val == 1 else pip_mat
			var n: Vector3 = face[2]
			var u: Vector3 = face[3]
			var w: Vector3 = face[4]
			pip.position = n * 2.66 + u * (-1.28 + (dot % 3) * 1.28) + w * (-1.28 + (dot / 3) * 1.28)
			# Orient squashed sphere flush with face normal
			if absf(n.x) > 0.5:
				pip.rotation_degrees.z = 90.0
			elif absf(n.z) > 0.5:
				pip.rotation_degrees.x = 90.0
			face_node.add_child(pip)

static func sync_shadows(bundle: Dictionary) -> void:
	var dice: Array = bundle.get("dice", [])
	var shadows: Array = bundle.get("shadows", [])
	for i in range(mini(dice.size(), shadows.size())):
		var die: Node3D = dice[i]
		var shadow: MeshInstance3D = shadows[i]
		if is_instance_valid(die) and is_instance_valid(shadow):
			shadow.position.x = die.position.x
			shadow.position.z = die.position.z
			var h := clampf((die.position.y - 3.65) / 15.0, 0.0, 1.0)
			var sc := lerpf(1.0, 0.52, h)
			shadow.scale = Vector3(sc, 1.0, sc)

static func spawn_impact_vfx(scene_host: Node, board: Node3D, world_pos: Vector3, skin_index: int, strength := 1.0) -> void:
	if not is_instance_valid(board):
		return
	var skin: Dictionary = SKINS[clampi(skin_index, 0, SKINS.size() - 1)]
	var vfx_color: Color = skin.vfx

	var fx_root := Node3D.new()
	fx_root.position = Vector3(world_pos.x, 1.08, world_pos.z)
	board.add_child(fx_root)

	var ring := MeshInstance3D.new()
	var torus := CylinderMesh.new()
	torus.top_radius = 1.6
	torus.bottom_radius = 1.6
	torus.height = 0.08
	torus.radial_segments = 20
	ring.mesh = torus
	var ring_mat := _mat(Color(vfx_color.r, vfx_color.g, vfx_color.b, 0.68), 0.3, 0.0, true, true)
	ring.material_override = ring_mat
	ring.scale = Vector3(0.3, 1.0, 0.3)
	fx_root.add_child(ring)

	var tw := scene_host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(2.5 * strength, 1.0, 2.5 * strength), 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.36)

	for s in range(6):
		var spark := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.45, 0.45, 0.45) * strength
		spark.mesh = sm
		var smat := _mat(vfx_color, 0.2, 0.1, true, true)
		spark.material_override = smat
		fx_root.add_child(spark)
		var ang := s * TAU / 6.0 + strength
		var target := Vector3(cos(ang) * 4.2 * strength, 1.8 * strength, sin(ang) * 4.2 * strength)
		tw.tween_property(spark, "position", target, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(spark, "scale", Vector3.ONE * 0.1, 0.34)

	tw.chain().tween_callback(fx_root.queue_free)

static func animate_throw(scene_host: Node, board: Node3D, bundle: Dictionary, player_index: int, roll_values: Array, skin_index: int, rng: RandomNumberGenerator) -> void:
	var origin: Vector3 = LAUNCH_ORIGINS[clampi(player_index, 0, 3)]
	for i in range(2):
		set_die_value(bundle, i, roll_values[i], skin_index)
		var die: Node3D = bundle.dice[i]
		var side_offset := Vector3(-2.8 + i * 5.6, i * 1.4, 2.2 - i * 4.4)
		var start_pos := origin + side_offset
		var rest_pos: Vector3 = REST_POSITIONS[i] + Vector3(rng.randf_range(-1.1, 1.1), 0.0, rng.randf_range(-1.1, 1.1))
		var bounce_1 := start_pos.lerp(rest_pos, 0.62)
		bounce_1.y = 3.65
		var bounce_2 := start_pos.lerp(rest_pos, 0.88)
		bounce_2.y = 3.65
		var final_yaw: float = REST_YAWS[i] + rng.randf_range(-0.18, 0.18)

		die.position = start_pos
		die.rotation = Vector3(
			TAU * rng.randi_range(2, 3) + rng.randf_range(0.6, 1.8),
			TAU * rng.randi_range(1, 2) + final_yaw + 1.4,
			TAU * rng.randi_range(2, 3) + rng.randf_range(0.6, 1.8)
		)

		# Horizontal trajectory across the pitch
		var xz_tw := scene_host.create_tween()
		xz_tw.tween_property(die, "position:x", rest_pos.x, 1.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var z_tw := scene_host.create_tween()
		z_tw.tween_property(die, "position:z", rest_pos.z, 1.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Vertical multi-bounce arc: high throw -> hit 1 -> bounce 2 -> settle hop -> rest
		var y_tw := scene_host.create_tween()
		y_tw.tween_property(die, "position:y", 19.5 + i * 1.5, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		y_tw.tween_property(die, "position:y", 3.65, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		y_tw.tween_callback(spawn_impact_vfx.bind(scene_host, board, bounce_1, skin_index, 1.0))
		y_tw.tween_property(die, "position:y", 8.6, 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		y_tw.tween_property(die, "position:y", 3.65, 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		y_tw.tween_callback(spawn_impact_vfx.bind(scene_host, board, bounce_2, skin_index, 0.65))
		y_tw.tween_property(die, "position:y", 5.2, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		y_tw.tween_property(die, "position:y", 3.65, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

		# 3D multi-axis tumble settling naturally onto exact rolled Top face with natural yaw
		var rot_tw := scene_host.create_tween()
		rot_tw.tween_property(die, "rotation", Vector3(0.0, final_yaw, 0.0), 1.14).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
