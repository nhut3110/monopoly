extends RefCounted

# Performance-optimized 3D money stacks (shared materials & meshes, no unnecessary shadow casting)
# placed cleanly beside the 4 player edges of the board.

const STACK_TRANSFORMS := [
	{"pos": Vector3(-66.5, -1.1, -8.0), "rot": 0.0},
	{"pos": Vector3(-8.0, -1.1, -66.5), "rot": -PI / 2.0},
	{"pos": Vector3(8.0, -1.1, 66.5), "rot": PI / 2.0},
	{"pos": Vector3(66.5, -1.1, 8.0), "rot": PI}
]

static func _mat(color: Color, roughness := 0.72, metallic := 0.0, alpha := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func _box_shared(parent: Node3D, pos: Vector3, mesh: BoxMesh, mat: StandardMaterial3D, cast_shadows := false) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	if not cast_shadows:
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst

static func create_all(parent: Node3D, player_colors: Array) -> Array:
	var stacks: Array = []
	var mat_bill_top := _mat(Color("7fd163"), 0.75)
	var mat_bill_edge := _mat(Color("4c9b41"), 0.85)
	var mat_strap := _mat(Color("f4fae8"), 0.60)
	var mat_seal := _mat(Color("52a846"), 0.55)
	var mat_silver := _mat(Color("dce6f0"), 0.24, 0.65)
	var mat_silver_base := _mat(Color("9fb0c2"), 0.35, 0.55)
	var mat_gold := _mat(Color("ffd646"), 0.22, 0.72)
	var mat_gold_base := _mat(Color("e09a19"), 0.32, 0.62)
	var mat_shadow := _mat(Color(0.20, 0.16, 0.26, 0.20), 1.0, 0.0, true)
	var mat_card_white := _mat(Color("fbfbf9"), 0.55)

	var m_edge := BoxMesh.new(); m_edge.size = Vector3(3.35, 0.74, 3.85)
	var m_top := BoxMesh.new(); m_top.size = Vector3(3.22, 0.68, 3.72)
	var m_strap := BoxMesh.new(); m_strap.size = Vector3(3.41, 0.78, 0.92)
	var m_seal := BoxMesh.new(); m_seal.size = Vector3(0.85, 0.04, 0.62)
	var m_sh := BoxMesh.new(); m_sh.size = Vector3(8.8, 0.06, 13.6)
	var m_ingot_b := BoxMesh.new(); m_ingot_b.size = Vector3(2.55, 0.46, 3.55)
	var m_ingot_t := BoxMesh.new(); m_ingot_t.size = Vector3(2.15, 0.38, 3.15)
	var m_card := BoxMesh.new(); m_card.size = Vector3(3.4, 0.18, 2.4)
	var m_card_bar := BoxMesh.new(); m_card_bar.size = Vector3(1.1, 0.05, 2.1)

	for owner in range(4):
		var root := Node3D.new()
		root.name = "MoneyPile_%d" % owner
		root.position = STACK_TRANSFORMS[owner].pos
		root.rotation.y = STACK_TRANSFORMS[owner].rot
		parent.add_child(root)

		var shadow := _box_shared(root, Vector3(0.0, 0.05, 0.0), m_sh, mat_shadow)
		shadow.name = "Shadow"

		var bills_root := Node3D.new()
		bills_root.name = "Bills"
		root.add_child(bills_root)

		for tier in range(4):
			for row in range(3):
				for col in range(2):
					var bundle := Node3D.new()
					bundle.position = Vector3(-1.85 + col * 3.7, 0.42 + tier * 0.82, -4.1 + row * 4.1)
					bundle.rotation.y = ((row * 3 + col + tier) % 3 - 1) * 0.035
					bills_root.add_child(bundle)
					_box_shared(bundle, Vector3.ZERO, m_edge, mat_bill_edge)
					_box_shared(bundle, Vector3(0, 0.06, 0), m_top, mat_bill_top)
					_box_shared(bundle, Vector3.ZERO, m_strap, mat_strap)
					_box_shared(bundle, Vector3(0, 0.40, 0), m_seal, mat_seal)

		var bullion_root := Node3D.new()
		bullion_root.name = "Bullion"
		root.add_child(bullion_root)

		var silver_group := Node3D.new()
		silver_group.name = "Silver"
		bullion_root.add_child(silver_group)
		for idx in range(6):
			var ingot := Node3D.new()
			ingot.position = Vector3(-1.3 + (idx % 2) * 2.8, 0.42 + (idx / 2) * 0.78, 7.6 + (idx % 3) * 1.35)
			silver_group.add_child(ingot)
			_box_shared(ingot, Vector3(0, -0.12, 0), m_ingot_b, mat_silver_base)
			_box_shared(ingot, Vector3(0, 0.16, 0), m_ingot_t, mat_silver)

		var gold_group := Node3D.new()
		gold_group.name = "Gold"
		bullion_root.add_child(gold_group)
		for idx in range(4):
			var ingot := Node3D.new()
			ingot.position = Vector3(-1.2 + (idx % 2) * 2.6, 0.40 + (idx / 2) * 0.76, 13.2 + (idx % 2) * 0.9)
			gold_group.add_child(ingot)
			_box_shared(ingot, Vector3(0, -0.12, 0), m_ingot_b, mat_gold_base)
			_box_shared(ingot, Vector3(0, 0.15, 0), m_ingot_t, mat_gold)

		var deeds_group := Node3D.new()
		deeds_group.name = "Deeds"
		bullion_root.add_child(deeds_group)
		var owner_accent := _mat(player_colors[owner], 0.5)
		for card_idx in range(4):
			var card := Node3D.new()
			card.position = Vector3(-0.6 + card_idx * 0.18, 0.16 + card_idx * 0.22, 17.6)
			card.rotation.y = 0.18 - card_idx * 0.07
			deeds_group.add_child(card)
			_box_shared(card, Vector3.ZERO, m_card, mat_card_white)
			_box_shared(card, Vector3(-0.85, 0.10, 0), m_card_bar, owner_accent)

		stacks.append(root)
	return stacks

static func update_pile(pile: Node3D, cash: int, net_worth_val: int, owned_count: int, alive: bool) -> void:
	if not is_instance_valid(pile):
		return
	pile.visible = alive and (cash > 0 or owned_count > 0)
	if not pile.visible:
		return
	var bills := pile.get_node_or_null("Bills")
	if bills:
		var visible_bundles := 0
		if cash > 0:
			visible_bundles = clampi(ceili(float(cash) / 82.0), 2, bills.get_child_count())
		for i in range(bills.get_child_count()):
			bills.get_child(i).visible = i < visible_bundles
	var shadow := pile.get_node_or_null("Shadow")
	if shadow:
		shadow.visible = cash > 0

	var bullion := pile.get_node_or_null("Bullion")
	if bullion:
		var silver := bullion.get_node_or_null("Silver")
		var gold := bullion.get_node_or_null("Gold")
		var deeds := bullion.get_node_or_null("Deeds")
		if silver:
			var show_silver := cash >= 1550 or net_worth_val >= 1650
			silver.visible = show_silver
			if show_silver:
				var silver_count := clampi(1 + (maxi(cash, net_worth_val) - 1520) / 110, 2, 6)
				for i in range(silver.get_child_count()):
					silver.get_child(i).visible = i < silver_count
		if gold:
			var show_gold := cash >= 1650 or net_worth_val >= 1800
			gold.visible = show_gold
			if show_gold:
				var gold_count := clampi(1 + (maxi(cash, net_worth_val) - 1620) / 140, 2, 4)
				for i in range(gold.get_child_count()):
					gold.get_child(i).visible = i < gold_count
		if deeds:
			deeds.visible = owned_count > 0
			for i in range(deeds.get_child_count()):
				deeds.get_child(i).visible = i < mini(4, owned_count)
