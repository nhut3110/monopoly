extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func frame() -> void:
	for index in range(8): await process_frame
	RenderingServer.force_draw()

func capture() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	await frame()
	root.get_texture().get_image().save_png("res://evidence/welcome.png")
	scene.show_setup()
	scene.select_map(2)
	await frame()
	root.get_texture().get_image().save_png("res://evidence/city-preview.png")
	scene.start_game()
	await frame()
	root.get_texture().get_image().save_png("res://evidence/city.png")
	scene.on_action()
	await create_timer(1.1).timeout
	await frame()
	root.get_texture().get_image().save_png("res://evidence/city-moving.png")
	await create_timer(2.5).timeout
	scene.inspect_tile(1)
	await create_timer(0.6).timeout
	await frame()
	root.get_texture().get_image().save_png("res://evidence/city-inspect.png")
	scene.close_inspection()
	scene.show_welcome()
	scene.show_setup()
	scene.select_map(0)
	await frame()
	root.get_texture().get_image().save_png("res://evidence/farm-preview.png")
	scene.start_game()
	await frame()
	root.get_texture().get_image().save_png("res://evidence/farm.png")
	scene.show_welcome()
	scene.show_setup()
	scene.select_map(1)
	await frame()
	root.get_texture().get_image().save_png("res://evidence/setup.png")
	scene.start_game()
	await frame()
	root.get_texture().get_image().save_png("res://evidence/pirate.png")
	scene.on_action()
	await create_timer(4.0).timeout
	await frame()
	root.get_texture().get_image().save_png("res://evidence/roll.png")
	scene.show_pause()
	await frame()
	root.get_texture().get_image().save_png("res://evidence/pause.png")
	scene.game.current = 0
	scene.game.phase = "end"
	scene.game.tiles[1].owner = 0
	scene.game.tiles[3].owner = 0
	scene.resume_game()
	scene.show_assets()
	await frame()
	root.get_texture().get_image().save_png("res://evidence/assets.png")
	scene.show_property(1)
	await frame()
	root.get_texture().get_image().save_png("res://evidence/property.png")
	print("Đã render welcome, setup, pirate, roll, pause")
	quit()
