extends Node3D

var skeleton: Skeleton3D
var clock := 0.0
var walking := false
var hop_height := 0.0
var model_root: Node3D
var show_pedestal := true

func setup(id: String, color: Color, with_pedestal := true) -> void:
	show_pedestal = with_pedestal
	for child in get_children():
		child.free()
	skeleton = null
	var scene: PackedScene = load("res://assets/polyfork/%s.glb" % id)
	model_root = scene.instantiate() as Node3D
	add_child(model_root)
	var skeletons := model_root.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		skeleton = skeletons[0]
		_apply_pose(0.02)

	if show_pedestal:
		# Soft shadow disc on the tile
		var shadow := MeshInstance3D.new()
		var s_mesh := CylinderMesh.new()
		s_mesh.top_radius = 0.72
		s_mesh.bottom_radius = 0.72
		s_mesh.height = 0.02
		shadow.mesh = s_mesh
		var s_mat := StandardMaterial3D.new()
		s_mat.albedo_color = Color(0.10, 0.08, 0.12, 0.30)
		s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shadow.material_override = s_mat
		shadow.position.y = 0.015
		add_child(shadow)

		# Crisp white outer token rim
		var rim := MeshInstance3D.new()
		var r_mesh := CylinderMesh.new()
		r_mesh.top_radius = 0.60
		r_mesh.bottom_radius = 0.66
		r_mesh.height = 0.11
		r_mesh.radial_segments = 20
		rim.mesh = r_mesh
		var r_mat := StandardMaterial3D.new()
		r_mat.albedo_color = Color("ffffff")
		r_mat.roughness = 0.35
		rim.material_override = r_mat
		rim.position.y = 0.055
		add_child(rim)

		# Vibrant player-colored inner pedestal disc
		var base := MeshInstance3D.new()
		var b_mesh := CylinderMesh.new()
		b_mesh.top_radius = 0.50
		b_mesh.bottom_radius = 0.54
		b_mesh.height = 0.15
		b_mesh.radial_segments = 20
		base.mesh = b_mesh
		var b_mat := StandardMaterial3D.new()
		b_mat.albedo_color = color
		b_mat.roughness = 0.38
		base.material_override = b_mat
		base.position.y = 0.085
		add_child(base)

func _apply_pose(swing: float) -> void:
	if not skeleton:
		return
	for index in range(skeleton.get_bone_count()):
		var bone := skeleton.get_bone_name(index).to_lower()
		if "leftarm" in bone:
			skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.FORWARD, 1.18) * Quaternion(Vector3.RIGHT, swing))
		elif "rightarm" in bone:
			skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.FORWARD, -1.18) * Quaternion(Vector3.RIGHT, -swing))
		elif "leftupleg" in bone:
			skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.RIGHT, -swing))
		elif "rightupleg" in bone:
			skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.RIGHT, swing))

func _process(delta: float) -> void:
	clock += delta
	var base_y := 0.15 if show_pedestal else 0.0
	if model_root:
		var idle_bob := absf(sin(clock * 1.9)) * 0.018 if not walking else absf(sin(clock * 8.5)) * 0.06
		model_root.position.y = base_y + hop_height + idle_bob
	var swing := sin(clock * 8.5) * 0.42 if walking else sin(clock * 1.9) * 0.02
	_apply_pose(swing)
