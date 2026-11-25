extends SceneTree

func _initialize() -> void:
	call_deferred("run_flow")

func run_flow() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	await process_frame
	assert(not scene.playing and scene.menu_ui.visible)
	scene.show_setup()
	assert(scene.name_input.text.length() > 0)
	scene.name_input.text = "An"
	scene.randomize_bots()
	assert("An" not in scene.names.slice(1))
	scene.select_map(1)
	assert(scene.selected_map == 1 and scene.map_title.text == "Vịnh hải tặc")
	scene.start_game()
	assert(scene.playing and scene.game.players[0].name == "An")
	assert(scene.game.players[1].name != "An")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = scene.camera.unproject_position(scene.tile_position(1) + Vector3(0, 1.1, 0))
	scene._unhandled_input(tap)
	assert(scene.inspected_tile == 1 and scene.inspect_panel.visible)
	assert(scene.selection_marker.visible)
	assert(scene.inspect_text.text.contains(scene.game.tiles[1].name))
	scene.close_inspection()
	assert(scene.inspected_tile == -1 and not scene.inspect_panel.visible and not scene.selection_marker.visible)
	scene.on_action()
	assert(scene.rolling and scene.game.last_roll[0] >= 1 and scene.game.last_roll[1] >= 1)
	await create_timer(3.0).timeout
	assert(not scene.rolling and scene.dice_values[0].get_node("Top").get_child_count() == scene.game.last_roll[0])
	assert(scene.dice_values[1].get_node("Top").get_child_count() == scene.game.last_roll[1])
	scene.save_path = "user://qa-flow.save"
	scene.persistence_enabled = true
	assert(scene.save_game())
	var snapshot: Dictionary = scene.game.snapshot()
	scene.show_welcome()
	scene.load_game()
	assert(scene.game.snapshot() == snapshot)
	assert(scene.dice_values[0].get_node("Top").get_child_count() == snapshot.last_roll[0])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.save_path))
	print("Flow: setup, tên, map và xúc xắc 3D hoạt động")
	quit()
