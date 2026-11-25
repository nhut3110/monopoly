extends Node3D

const Game = preload("res://src/game.gd")
const BoardArt = preload("res://src/board_art.gd")
const MoneyPile = preload("res://src/money_pile.gd")
const DiceRig = preload("res://src/dice_rig.gd")
const Character = preload("res://src/character.gd")
const Sound = preload("res://src/sound.gd")
const PlayerBanner = preload("res://src/player_banner.gd")
const HudModals = preload("res://src/hud_modals.gd")
const TileText = preload("res://src/tile_text.gd")

const COLORS := [Color("f01e6b"), Color("1aa3ec"), Color("84bd22"), Color("f2bf18")]
const GROUP_COLORS := [
	Color("c97b53"), Color("38bdf8"), Color("ec5ca5"), Color("fb923c"),
	Color("f04e54"), Color("f4c430"), Color("43b868"), Color("536de8")
]
const NAMES := ["An", "Bảo", "Chi", "Dương", "Hải", "Khánh", "Linh", "Mai", "Minh", "Ngọc", "Phúc", "Quân", "Thảo", "Vy"]
const MAPS := [
	{
		"name": "Nông trại nắng",
		"description": "Thung lũng cối xay gió, nông trang đỏ, đàn cừu bò và nhà ga hơi nước.",
		"detail": "Mùa vụ: thưởng +100K hoặc chi phí -50K · Nhịp chơi cân bằng.",
		"sky_top": Color("9cccf0"),
		"sky_upper": Color("ccead2"),
		"sky_lower": Color("f6ebc8"),
		"sky_bottom": Color("fef4d4")
	},
	{
		"name": "Vịnh hải tặc",
		"description": "Quần đảo ngọc bích với Soái hạm 3 buồm lắc lư theo sóng và Hang kho báu.",
		"detail": "Kho báu: thưởng +150K hoặc chi phí -75K · Biến động cao kịch tính.",
		"sky_top": Color("8dcbe6"),
		"sky_upper": Color("c4e5ec"),
		"sky_lower": Color("f6dfc6"),
		"sky_bottom": Color("fdefd2")
	},
	{
		"name": "Phố Hội",
		"description": "Công viên đu quay, hồ thuyền thiên nga, đường phố hoa anh đào và sân bay.",
		"detail": "Cơ hội: thưởng +100K hoặc chi phí -50K · Đầu tư chuỗi bất động sản.",
		"sky_top": Color("aab2e8"),
		"sky_upper": Color("e5c1da"),
		"sky_lower": Color("fadcc6"),
		"sky_bottom": Color("fef0d6")
	}
]

const BASE_CAM_POS := Vector3(124.0, 106.0, 124.0)
const BASE_CAM_TARGET := Vector3(0.0, 1.8, 0.0)
const BASE_CAM_SIZE := 108.0
const CITY_CHARACTERS := ["salaryman-commuter-4170c1", "shopkeeper-be5547", "school-student-385134", "delivery-courier-327e30"]
const PIRATE_CHARACTERS := ["pirate-captain-91f545", "naval-officer-93027f", "cove-trader-0f94a6", "pirate-deckhand-98a6e7"]
const SAVE_PATH := "user://session.save"

var game = Game.new()
var pieces: Array = []
var markers: Array = []
var status_label: Label
var player_names: Array = []
var player_cash: Array = []
var player_cards: Array = []
var player_initials: Array = []
var player_stats: Array = []
var last_cash: Array = [1500, 1500, 1500, 1500]
var action_button: Button
var skip_button: Button
var dice: Array = []
var dice_values: Array = []
var dice_bundle: Dictionary = {}
var selected_dice_skin := 0
var board: Node3D
var camera: Camera3D
var environment: WorldEnvironment
var backdrop_material: ShaderMaterial
var game_ui: Control
var menu_ui: Control
var name_input: LineEdit
var bot_label: Label
var map_title: Label
var map_description: Label
var map_detail: Label
var map_buttons: Array = []
var skin_label: Label
var selected_map := 2
var names: Array = []
var playing := false
var in_lobby := false
var lobby_orbit := 0.0
var world_clock := 0.0
var rolling := false
var animation_phase := ""
var bot_timer := 0.0
var visual_positions: Array = [0, 0, 0, 0]
var moving_player := -1
var paused := false
var top_label: Label
var toolbar: VBoxContainer
var assets_tool_btn
var sound_tool_btn
var level_labels: Array = []
var selected_tile := -1
var last_saved := false
var game_length: OptionButton
var persistence_enabled := true
var camera_follow := false
var sound_enabled := true
var sound_player: AudioStreamPlayer
var roll_sound: AudioStreamWAV
var step_sound: AudioStreamWAV
var action_sound: AudioStreamWAV
var save_path := SAVE_PATH
var visual_rng := RandomNumberGenerator.new()
var scoreboard_root: Control
var scoreboard_sub_label: Label
var roll_total_label: Label
var portrait_characters: Array = []
var portrait_viewports: Array = []
var map_overlay: Control
var inspect_panel: PanelContainer
var inspect_header: PanelContainer
var inspect_header_title: Label
var inspect_text: Label
var inspected_tile := -1
var selection_marker: Node3D
var buy_deed_card: PanelContainer
var buy_deed_header: PanelContainer
var buy_deed_title: Label
var buy_deed_price: Label
var buy_deed_body: Label
var buy_card_btn: Button
var skip_card_btn: Button
var speech_bubble
var speech_speaker := 0
var speech_timer := 0.0
var emote_index := 0
var skin_popup: PanelContainer
var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween
var last_turn_owner := -1

func _ready() -> void:
	game.setup()
	visual_rng.randomize()
	sound_player = AudioStreamPlayer.new()
	sound_player.volume_db = -12
	add_child(sound_player)
	roll_sound = Sound.tone(195, 0.45, true)
	step_sound = Sound.tone(440, 0.06)
	action_sound = Sound.tone(660, 0.18)
	randomize_names()
	create_scene()
	create_ui()
	create_menu()
	show_welcome()
	refresh()

func create_scene() -> void:
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = -1
	env.background_color = Color("aab2e8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f6f2f8")
	env.ambient_light_energy = 0.56
	environment.environment = env
	add_child(environment)

	var backdrop_layer := CanvasLayer.new()
	backdrop_layer.layer = -1
	add_child(backdrop_layer)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_material = ShaderMaterial.new()
	backdrop_material.shader = load("res://assets/backdrop.gdshader")
	backdrop.material = backdrop_material
	backdrop_layer.add_child(backdrop)

	# Crisp directional sun with fast 2048 shadow map for sharp shadows & locked 60 FPS
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -36, 0)
	light.light_energy = 0.64
	light.light_color = Color("fff7ea")
	light.shadow_enabled = true
	light.shadow_opacity = 0.26
	light.directional_shadow_max_distance = 195.0
	light.shadow_bias = 0.025
	add_child(light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-38, 146, 0)
	fill.light_color = Color("eaf3ff")
	fill.light_energy = 0.36
	add_child(fill)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = BASE_CAM_SIZE
	camera.position = BASE_CAM_POS
	add_child(camera)
	camera.look_at(BASE_CAM_TARGET)
	rebuild_board()

func _character_id_for(index: int) -> String:
	if selected_map == 2:
		return CITY_CHARACTERS[index]
	if selected_map == 1:
		return PIRATE_CHARACTERS[index]
	return "farmer-304a43" if index == 0 else CITY_CHARACTERS[index]

func _apply_map_sky() -> void:
	if not backdrop_material:
		return
	var m: Dictionary = MAPS[selected_map]
	backdrop_material.set_shader_parameter("top_color", m.sky_top)
	backdrop_material.set_shader_parameter("upper_mid_color", m.sky_upper)
	backdrop_material.set_shader_parameter("lower_mid_color", m.sky_lower)
	backdrop_material.set_shader_parameter("bottom_color", m.sky_bottom)

func rebuild_board() -> void:
	if is_instance_valid(board):
		board.free()
	board = BoardArt.build(game, selected_map)
	add_child(board)
	_apply_map_sky()

	pieces.clear()
	markers.clear()
	dice.clear()
	dice_values.clear()
	markers = board.get_meta("markers")

	selection_marker = Node3D.new()
	board.add_child(selection_marker)
	for edge in range(4):
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(8.4, 0.24, 0.38) if edge < 2 else Vector3(0.38, 0.24, 15.0)
		bar.mesh = mesh
		bar.material_override = BoardArt.material(Color("ffd43b"), 0.35)
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bar.position = [Vector3(0, 0, -7.45), Vector3(0, 0, 7.45), Vector3(-4.1, 0, 0), Vector3(4.1, 0, 0)][edge]
		selection_marker.add_child(bar)
	selection_marker.visible = false

	visual_positions = [0, 0, 0, 0]
	for index in range(4):
		var p_pos: int = game.players[index].position if index < game.players.size() else 0
		visual_positions[index] = p_pos
		var piece := Character.new()
		board.add_child(piece)
		var cid := _character_id_for(index)
		piece.setup(cid, COLORS[index], true)
		piece.scale = Vector3.ONE * 5.35
		piece.rotation.y = deg_to_rad(35.0)
		var tag := Label3D.new()
		tag.name = "NameTag"
		tag.text = "▼"
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size = 44
		tag.pixel_size = 0.012
		tag.position.y = 2.02
		tag.modulate = COLORS[index]
		tag.outline_modulate = Color("ffffff")
		tag.outline_size = 10
		piece.add_child(tag)
		piece.position = pawn_position(p_pos, index)
		pieces.append(piece)
		if index < portrait_characters.size():
			portrait_characters[index].setup(cid, COLORS[index], false)
			if index < portrait_viewports.size():
				portrait_viewports[index].render_target_update_mode = SubViewport.UPDATE_ONCE

	var shown_roll := [maxi(1, game.last_roll[0]), maxi(1, game.last_roll[1])] if game.last_roll[0] > 0 else [5, 2]
	dice_bundle = DiceRig.create_die_pair(board, selected_dice_skin)
	dice = dice_bundle.dice
	dice_values = dice_bundle.dice_values
	DiceRig.apply_skin(dice_bundle, selected_dice_skin, shown_roll)

	level_labels.clear()
	for index in range(40):
		var badge := Label3D.new()
		badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		badge.font_size = 44
		badge.pixel_size = 0.022
		badge.modulate = Color("fff9db")
		badge.outline_modulate = Color("1e293b")
		badge.outline_size = 10
		badge.position = tile_position(index) + Vector3(0, 8.6, 0)
		board.add_child(badge)
		level_labels.append(badge)

	var money_stacks: Array = board.get_meta("money_stacks")
	for p in range(mini(4, money_stacks.size())):
		var cash_v: int = game.players[p].cash if p < game.players.size() else 1500
		var nw_v: int = game.net_worth(p) if p < game.players.size() else 1500
		var owned_v := 0
		for t in game.tiles:
			if t.owner == p:
				owned_v += 1
		MoneyPile.update_pile(money_stacks[p], cash_v, nw_v, owned_v, true)

func tile_position(index: int) -> Vector3:
	return BoardArt.tile_position(index)

func pawn_position(index: int, player: int) -> Vector3:
	var base := BoardArt.path_position(index)
	var occupants: Array = []
	for p in range(4):
		if p < game.players.size() and not game.players[p].alive:
			continue
		var vpos: int = visual_positions[p] if p < visual_positions.size() else 0
		if vpos == index:
			occupants.append(p)
	if occupants.size() <= 1:
		return base
	var slot := maxi(0, occupants.find(player))
	var offsets := [
		Vector3(-1.6, 0.0, -1.4),
		Vector3(1.6, 0.0, -1.4),
		Vector3(-1.6, 0.0, 1.4),
		Vector3(1.6, 0.0, 1.4)
	]
	return base + offsets[slot % 4]

func set_die_value(index: int, value: int) -> void:
	if not dice_bundle.is_empty():
		DiceRig.set_die_value(dice_bundle, index, value, selected_dice_skin)

func select_dice_skin(skin_index: int) -> void:
	selected_dice_skin = posmod(skin_index, DiceRig.SKINS.size())
	var current_vals := [maxi(1, game.last_roll[0]), maxi(1, game.last_roll[1])] if game.last_roll[0] > 0 else [5, 2]
	if not dice_bundle.is_empty():
		DiceRig.apply_skin(dice_bundle, selected_dice_skin, current_vals)
		DiceRig.spawn_impact_vfx(self, board, Vector3(0, 1.15, 0), selected_dice_skin, 1.1)
	if is_instance_valid(skin_label):
		skin_label.text = "Xúc xắc: %s" % DiceRig.SKINS[selected_dice_skin].name
	play_sound(action_sound)

func say_bubble(player_idx: int, text: String, duration := 2.4) -> void:
	speech_speaker = clampi(player_idx, 0, 3)
	speech_timer = duration
	if speech_bubble:
		speech_bubble.accent = COLORS[speech_speaker]
		speech_bubble.text = text

func show_turn_toast(text: String, accent := Color("1aa3ec")) -> void:
	if not toast_panel or not toast_label:
		return
	toast_label.text = text
	toast_panel.add_theme_stylebox_override("panel", juicy_style(accent, Color("ffffff"), 18, 4))
	toast_panel.visible = true
	toast_panel.modulate.a = 1.0
	toast_panel.pivot_offset = toast_panel.size * 0.5
	toast_panel.scale = Vector2(0.75, 0.75)
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_interval(1.25)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.35)
	toast_tween.tween_callback(toast_panel.hide)

func spawn_cash_popup(player_idx: int, delta_val: int) -> void:
	if not playing or not map_overlay or delta_val == 0 or player_idx not in range(4):
		return
	var card: Control = player_cards[player_idx]
	var pop := Label.new()
	pop.text = ("+%dK" % delta_val) if delta_val > 0 else ("%dK" % delta_val)
	pop.add_theme_font_size_override("font_size", 24)
	pop.add_theme_color_override("font_color", Color("40c057") if delta_val > 0 else Color("fa5252"))
	pop.add_theme_color_override("font_outline_color", Color("ffffff"))
	pop.add_theme_constant_override("outline_size", 6)
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var start_pos := card.position + Vector2(card.size.x * 0.5 - 38.0, 28.0 if player_idx >= 2 else 82.0)
	pop.position = start_pos
	map_overlay.add_child(pop)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(pop, "position:y", start_pos.y - 44.0, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(pop, "modulate:a", 0.0, 0.45).set_delay(0.70)
	tw.chain().tween_callback(pop.queue_free)

func trigger_emote() -> void:
	if not playing:
		return
	var lines := ["Đi thôi nào!", "Đất này của tôi!", "Căng thẳng đấy!", "Tỷ phú tương lai!"]
	say_bubble(0, lines[emote_index % lines.size()], 2.5)
	emote_index += 1
	play_sound(action_sound)

func _pop_scoreboard() -> void:
	if not scoreboard_root:
		return
	scoreboard_root.pivot_offset = scoreboard_root.size * 0.5
	scoreboard_root.scale = Vector2(0.68, 0.68)
	var tw := create_tween()
	tw.tween_property(scoreboard_root, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animate_roll() -> void:
	play_sound(roll_sound)
	rolling = true
	animation_phase = "dice"
	moving_player = game.current
	var actor := moving_player
	say_bubble(actor, "Đang tung xúc xắc...", 1.8)

	DiceRig.animate_throw(self, board, dice_bundle, actor, game.last_roll, selected_dice_skin, visual_rng)
	await get_tree().create_timer(1.18).timeout

	var sum_val: int = game.last_roll[0] + game.last_roll[1]
	var is_double: bool = game.last_roll[0] == game.last_roll[1]
	animation_phase = "move"
	refresh()
	_pop_scoreboard()
	if is_double:
		show_turn_toast("TUNG ĐÔI %d · THÊM LƯỢT!" % game.last_roll[0], Color("f59f00"))
	say_bubble(actor, "Đôi %d! Đi %d ô!" % [game.last_roll[0], sum_val] if is_double else "Được %d nút!" % sum_val, 1.8)
	await get_tree().create_timer(0.28).timeout

	var destination: int = game.players[actor].position
	var steps: int = (destination - visual_positions[actor] + 40) % 40
	if game.players[actor].jail > 0:
		steps = 0
	var step_time := clampf(1.22 / maxf(1.0, float(steps)), 0.10, 0.20)
	pieces[actor].walking = steps > 0
	for step in range(steps):
		var next_tile: int = (visual_positions[actor] + 1) % 40
		visual_positions[actor] = next_tile
		var target := pawn_position(next_tile, actor)
		var direction: Vector3 = target - pieces[actor].position
		if direction.length() > 0.01:
			pieces[actor].rotation.y = atan2(direction.x, direction.z)
		play_sound(step_sound)
		var movement := create_tween()
		movement.set_parallel(true)
		movement.tween_property(pieces[actor], "position", target, step_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var hop := create_tween()
		hop.tween_property(pieces[actor], "hop_height", 0.28, step_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hop.tween_property(pieces[actor], "hop_height", 0.0, step_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await movement.finished

	pieces[actor].walking = false
	pieces[actor].hop_height = 0.0
	visual_positions[actor] = destination
	for p in range(4):
		if game.players[p].alive:
			pieces[p].position = pawn_position(visual_positions[p], p)

	var landed_tile: Dictionary = game.tiles[destination]
	if game.players[actor].jail > 0 and destination == 10:
		say_bubble(actor, "Vào tù mất rồi!", 2.2)
	elif destination in [4, 38]:
		say_bubble(actor, "Nộp thuế -100K", 2.2)
	elif landed_tile.owner >= 0 and landed_tile.owner != actor:
		say_bubble(actor, "Trả thuê -%dK" % game.rent_for(destination), 2.2)
	elif game.phase == "buy":
		say_bubble(actor, "%s · %dK" % [landed_tile.name, landed_tile.price], 2.5)

	moving_player = -1
	rolling = false
	animation_phase = ""
	refresh()

func panel_style(background: Color, border: Color, radius: int, border_w := 2, shadow_size := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(radius)
	if shadow_size > 0:
		style.shadow_color = Color(0.10, 0.08, 0.16, 0.22)
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0, 4)
	return style

func juicy_style(bg: Color, rim := Color("ffffff"), radius := 18, lip := 5, pressed := false) -> StyleBoxFlat:
	# AAA Mobile 3D-extruded glossy button style!
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = bg.darkened(0.26)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2 if pressed else lip
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.10, 0.08, 0.18, 0.24)
	style.shadow_size = 4 if pressed else 8
	style.shadow_offset = Vector2(0, 2 if pressed else 4)
	if rim.a > 0.01 and not pressed:
		style.border_color = bg.darkened(0.28)
	return style

func style_juicy_button(btn: Button, accent: Color, radius := 18, lip := 5) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_color_override("font_color", Color("ffffff"))
	btn.add_theme_color_override("font_disabled_color", Color("64748b"))
	btn.add_theme_color_override("font_outline_color", accent.darkened(0.45))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_stylebox_override("normal", juicy_style(accent, Color("ffffff"), radius, lip, false))
	btn.add_theme_stylebox_override("hover", juicy_style(accent.lightened(0.09), Color("ffffff"), radius, lip, false))
	btn.add_theme_stylebox_override("pressed", juicy_style(accent.darkened(0.08), Color("ffffff"), radius, lip, true))
	btn.add_theme_stylebox_override("disabled", panel_style(Color("e2e8f0"), Color("cbd5e1"), radius, 2))

func create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	game_ui = root

	var tile_text := TileText.new()
	tile_text.camera = camera
	tile_text.game = game
	tile_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(tile_text)

	create_map_overlay(root)

	# Sleek top match info pill
	var top_pill := PanelContainer.new()
	top_pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	top_pill.offset_left = -205
	top_pill.offset_right = 205
	top_pill.offset_top = 6
	top_pill.offset_bottom = 30
	top_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_pill.add_theme_stylebox_override("panel", panel_style(Color(0.18, 0.22, 0.32, 0.68), Color(1, 1, 1, 0.65), 12, 1))
	root.add_child(top_pill)

	top_label = Label.new()
	top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_label.add_theme_font_size_override("font_size", 13)
	top_label.add_theme_color_override("font_color", Color("ffffff"))
	top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_pill.add_child(top_label)

	# Animated Turn / Event Banner Toast
	toast_panel = PanelContainer.new()
	toast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_panel.offset_left = -165
	toast_panel.offset_right = 165
	toast_panel.offset_top = 40
	toast_panel.offset_bottom = 82
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.visible = false
	root.add_child(toast_panel)

	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 17)
	toast_label.add_theme_color_override("font_color", Color("ffffff"))
	toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	toast_label.add_theme_constant_override("outline_size", 3)
	toast_panel.add_child(toast_label)

	# 4 Corner Player Cards
	for index in range(4):
		create_player_card(root, index)

	# Stadium Scoreboard anchored cleanly over upper center dice arena
	scoreboard_root = Control.new()
	scoreboard_root.size = Vector2(118, 72)
	scoreboard_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scoreboard_root.visible = false
	root.add_child(scoreboard_root)

	var sb_dark := PanelContainer.new()
	sb_dark.position = Vector2(7, 0)
	sb_dark.size = Vector2(104, 28)
	sb_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb_dark.add_theme_stylebox_override("panel", panel_style(Color("283040"), Color("5c677d"), 6, 2, 4))
	scoreboard_root.add_child(sb_dark)

	scoreboard_sub_label = Label.new()
	scoreboard_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scoreboard_sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scoreboard_sub_label.add_theme_font_size_override("font_size", 13)
	scoreboard_sub_label.add_theme_color_override("font_color", Color("f8fafc"))
	sb_dark.add_child(scoreboard_sub_label)

	var total_panel := PanelContainer.new()
	total_panel.position = Vector2(29, 18)
	total_panel.size = Vector2(60, 52)
	total_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	total_panel.add_theme_stylebox_override("panel", panel_style(Color("ffffff"), Color("1aa3ec"), 8, 3, 6))
	scoreboard_root.add_child(total_panel)

	roll_total_label = Label.new()
	roll_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roll_total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	roll_total_label.add_theme_font_size_override("font_size", 28)
	roll_total_label.add_theme_color_override("font_color", Color("1e242e"))
	total_panel.add_child(roll_total_label)

	# Right-side glossy circular toolbar
	toolbar = VBoxContainer.new()
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	toolbar.offset_left = -72
	toolbar.offset_right = -16
	toolbar.offset_top = -432
	toolbar.offset_bottom = -126
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar.add_theme_constant_override("separation", 7)
	root.add_child(toolbar)

	var dice_btn := HudModals.CircleToolButton.new("dice", "Đổi Skin Xúc xắc & Hiệu ứng")
	dice_btn.pressed.connect(toggle_skin_popup)
	toolbar.add_child(dice_btn)

	var emote_btn := HudModals.CircleToolButton.new("emote", "Biểu cảm nhân vật")
	emote_btn.pressed.connect(trigger_emote)
	toolbar.add_child(emote_btn)

	sound_tool_btn = HudModals.CircleToolButton.new("sound", "Bật/tắt âm thanh")
	sound_tool_btn.pressed.connect(toggle_sound)
	toolbar.add_child(sound_tool_btn)

	var pause_btn := HudModals.CircleToolButton.new("pause", "Tạm nghỉ")
	pause_btn.pressed.connect(show_pause)
	toolbar.add_child(pause_btn)

	assets_tool_btn = HudModals.CircleToolButton.new("assets", "Tài sản & Giao dịch")
	assets_tool_btn.badge_count = 0
	assets_tool_btn.pressed.connect(show_assets)
	toolbar.add_child(assets_tool_btn)

	# Juicy AAA Mobile Bottom Action Dock
	var bottom_bar := Control.new()
	bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_bar.offset_left = -210
	bottom_bar.offset_right = 210
	bottom_bar.offset_top = -94
	bottom_bar.offset_bottom = -10
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_bar)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_END
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_bar.add_child(box)

	var status_panel := PanelContainer.new()
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel", panel_style(Color(0.16, 0.19, 0.27, 0.80), Color(1, 1, 1, 0.35), 14, 1))
	box.add_child(status_panel)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(0, 25)
	status_label.add_theme_color_override("font_color", Color("ffffff"))
	status_label.add_theme_font_size_override("font_size", 14)
	status_panel.add_child(status_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(246, 50)
	action_button.add_theme_font_size_override("font_size", 19)
	style_juicy_button(action_button, Color("1aa3ec"), 25, 6)
	action_button.pressed.connect(on_action)
	row.add_child(action_button)

	skip_button = Button.new()
	skip_button.text = "Đấu giá"
	skip_button.custom_minimum_size = Vector2(124, 50)
	skip_button.add_theme_font_size_override("font_size", 17)
	style_juicy_button(skip_button, Color("f59f00"), 25, 6)
	skip_button.pressed.connect(on_skip)
	row.add_child(skip_button)

	_create_buy_deed_modal(root)
	_create_skin_popup(root)

func _create_buy_deed_modal(root: Control) -> void:
	buy_deed_card = PanelContainer.new()
	buy_deed_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	buy_deed_card.offset_left = 26
	buy_deed_card.offset_right = 316
	buy_deed_card.offset_top = -172
	buy_deed_card.offset_bottom = 178
	buy_deed_card.add_theme_stylebox_override("panel", panel_style(Color("ffffff"), Color("ffffff"), 20, 3, 14))
	buy_deed_card.visible = false
	root.add_child(buy_deed_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	buy_deed_card.add_child(vbox)

	buy_deed_header = PanelContainer.new()
	buy_deed_header.custom_minimum_size.y = 66
	buy_deed_header.add_theme_stylebox_override("panel", panel_style(Color("1aa3ec"), Color("ffffff"), 16, 0))
	vbox.add_child(buy_deed_header)

	var hbox_title := VBoxContainer.new()
	hbox_title.alignment = BoxContainer.ALIGNMENT_CENTER
	buy_deed_header.add_child(hbox_title)

	buy_deed_title = Label.new()
	buy_deed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_deed_title.add_theme_font_size_override("font_size", 20)
	buy_deed_title.add_theme_color_override("font_color", Color("ffffff"))
	hbox_title.add_child(buy_deed_title)

	buy_deed_price = Label.new()
	buy_deed_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_deed_price.add_theme_font_size_override("font_size", 15)
	buy_deed_price.add_theme_color_override("font_color", Color("fff9db"))
	hbox_title.add_child(buy_deed_price)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	margin.add_theme_constant_override("margin_top", 2)
	vbox.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	margin.add_child(inner)

	buy_deed_body = Label.new()
	buy_deed_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buy_deed_body.add_theme_font_size_override("font_size", 14)
	buy_deed_body.add_theme_color_override("font_color", Color("2b3442"))
	inner.add_child(buy_deed_body)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	inner.add_child(btn_row)

	buy_card_btn = Button.new()
	buy_card_btn.text = "Mua ngay"
	buy_card_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_card_btn.custom_minimum_size.y = 44
	buy_card_btn.add_theme_font_size_override("font_size", 15)
	style_juicy_button(buy_card_btn, Color("68b817"), 14, 5)
	buy_card_btn.pressed.connect(on_action)
	btn_row.add_child(buy_card_btn)

	skip_card_btn = Button.new()
	skip_card_btn.text = "Đấu giá"
	skip_card_btn.custom_minimum_size = Vector2(96, 44)
	skip_card_btn.add_theme_font_size_override("font_size", 15)
	style_juicy_button(skip_card_btn, Color("f59f00"), 14, 5)
	skip_card_btn.pressed.connect(on_skip)
	btn_row.add_child(skip_card_btn)

func _create_skin_popup(root: Control) -> void:
	skin_popup = PanelContainer.new()
	skin_popup.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skin_popup.offset_left = -355
	skin_popup.offset_right = -86
	skin_popup.offset_top = -396
	skin_popup.offset_bottom = -132
	skin_popup.add_theme_stylebox_override("panel", panel_style(Color("ffffff"), Color("ffffff"), 20, 3, 14))
	skin_popup.visible = false
	root.add_child(skin_popup)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	skin_popup.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var hdr := Label.new()
	hdr.text = "SKIN XÚC XẮC 3D"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 16)
	hdr.add_theme_color_override("font_color", Color("1e293b"))
	col.add_child(hdr)

	for i in range(DiceRig.SKINS.size()):
		var sk: Dictionary = DiceRig.SKINS[i]
		var b := Button.new()
		b.text = sk.name
		b.custom_minimum_size.y = 40
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", Color("ffffff") if i != 1 else Color("1f2633"))
		b.add_theme_stylebox_override("normal", juicy_style(sk.body, sk.pip, 12, 4, false))
		b.add_theme_stylebox_override("hover", juicy_style(sk.bevel, sk.pip, 12, 4, false))
		b.pressed.connect(func(): select_dice_skin(i); skin_popup.hide())
		col.add_child(b)

func toggle_skin_popup() -> void:
	if skin_popup:
		skin_popup.visible = not skin_popup.visible

func create_map_overlay(root: Control) -> void:
	map_overlay = Control.new()
	map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(map_overlay)

	speech_bubble = HudModals.SpeechBubble.new()
	map_overlay.add_child(speech_bubble)

	inspect_panel = PanelContainer.new()
	inspect_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	inspect_panel.offset_left = 26
	inspect_panel.offset_right = 316
	inspect_panel.offset_top = -155
	inspect_panel.offset_bottom = 155
	inspect_panel.add_theme_stylebox_override("panel", panel_style(Color("ffffff"), Color("ffffff"), 20, 3, 14))
	root.add_child(inspect_panel)

	var card_col := VBoxContainer.new()
	card_col.add_theme_constant_override("separation", 8)
	inspect_panel.add_child(card_col)

	inspect_header = PanelContainer.new()
	inspect_header.custom_minimum_size.y = 52
	inspect_header.add_theme_stylebox_override("panel", panel_style(Color("1aa3ec"), Color("ffffff"), 16, 0))
	card_col.add_child(inspect_header)

	var hdr_row := HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 6)
	inspect_header.add_child(hdr_row)

	inspect_header_title = Label.new()
	inspect_header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inspect_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inspect_header_title.add_theme_font_size_override("font_size", 18)
	inspect_header_title.add_theme_color_override("font_color", Color("ffffff"))
	hdr_row.add_child(inspect_header_title)

	var close := Button.new()
	close.text = "×"
	close.custom_minimum_size = Vector2(38, 38)
	close.add_theme_font_size_override("font_size", 22)
	close.add_theme_color_override("font_color", Color("ffffff"))
	close.flat = true
	close.pressed.connect(close_inspection)
	hdr_row.add_child(close)

	var body_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_bottom"]:
		body_margin.add_theme_constant_override(side, 14)
	body_margin.add_theme_constant_override("margin_top", 4)
	card_col.add_child(body_margin)

	var body_col := VBoxContainer.new()
	body_col.add_theme_constant_override("separation", 10)
	body_margin.add_child(body_col)

	inspect_text = Label.new()
	inspect_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_text.add_theme_font_size_override("font_size", 15)
	inspect_text.add_theme_color_override("font_color", Color("26303d"))
	body_col.add_child(inspect_text)

	var manage_btn := Button.new()
	manage_btn.text = "Quản lý / Giao dịch"
	manage_btn.custom_minimum_size.y = 40
	manage_btn.add_theme_font_size_override("font_size", 14)
	style_juicy_button(manage_btn, Color("1aa3ec"), 12, 4)
	manage_btn.pressed.connect(func():
		var t := inspected_tile
		close_inspection()
		if t >= 0 and game.tiles[t].owner >= 0:
			show_property(t)
		else:
			show_assets()
	)
	body_col.add_child(manage_btn)

	inspect_panel.hide()
	if is_instance_valid(selection_marker):
		selection_marker.visible = false

func close_inspection() -> void:
	inspected_tile = -1
	if inspect_panel:
		inspect_panel.hide()
	if is_instance_valid(selection_marker):
		selection_marker.visible = false
	refresh()

func _deed_details_text(index: int) -> String:
	var tile: Dictionary = game.tiles[index]
	var owner_str: String = "Chưa có chủ" if tile.owner < 0 else game.players[tile.owner].name
	if tile.price <= 0:
		return "%s\nÔ sự kiện đặc biệt trên bàn cờ." % tile.name
	var base_rent: int = tile.rent
	if tile.group >= 0:
		return "%s · Giá %dK\nChủ sở hữu: %s (Cấp %d/5)\n──────────────\n• Thuê cơ bản: %dK (Đủ bộ: %dK)\n• 1–2 Nhà: %dK  /  %dK\n• 3–4 Nhà: %dK  /  %dK\n• Khách sạn ★: %dK\n• Chi phí xây: %dK" % [
			tile.name, tile.price, owner_str, tile.level,
			base_rent, base_rent * 2,
			base_rent * 3, base_rent * 7,
			base_rent * 12, base_rent * 18,
			base_rent * 25, game.build_cost(index)
		]
	return "%s · Giá %dK\nChủ sở hữu: %s\n• Tiền thuê hiện tại: %dK\n• Thế chấp nhận: %dK" % [
		tile.name, tile.price, owner_str, maxi(tile.rent, game.rent_for(index)), tile.price / 2
	]

func inspect_tile(index: int) -> void:
	if not playing or rolling or paused or index not in range(40):
		return
	if skin_popup:
		skin_popup.hide()
	if buy_deed_card:
		buy_deed_card.hide()
	inspected_tile = index
	var side := index / 10
	selection_marker.position = tile_position(index) + Vector3(0, 1.12, 0)
	selection_marker.rotation.y = 0.0 if side % 2 == 0 else PI / 2.0
	selection_marker.scale = Vector3(1.62, 1.0, 1.0) if index % 10 == 0 else Vector3.ONE
	selection_marker.visible = true

	var tile: Dictionary = game.tiles[index]
	var hdr_col: Color = GROUP_COLORS[tile.group] if tile.group >= 0 else (COLORS[tile.owner] if tile.owner >= 0 else Color("3b82f6"))
	inspect_header.add_theme_stylebox_override("panel", panel_style(hdr_col, Color("ffffff"), 16, 0))
	inspect_header_title.text = "  " + tile.name.to_upper()
	inspect_text.text = _deed_details_text(index)
	inspect_panel.show()

func _unhandled_input(event: InputEvent) -> void:
	if not playing or paused or rolling or inspected_tile >= 0:
		return
	var position: Vector2
	if event is InputEventScreenTouch and event.pressed:
		position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		position = event.position
	else:
		return
	if skin_popup and skin_popup.visible:
		skin_popup.hide()
	var closest := -1
	var best := 40.0
	for index in range(40):
		var world_position := tile_position(index) + Vector3(0, 1.1, 0)
		if camera.is_position_behind(world_position):
			continue
		var distance := camera.unproject_position(world_position).distance_to(position)
		if distance < best:
			closest = index
			best = distance
	if closest >= 0:
		inspect_tile(closest)
		get_viewport().set_input_as_handled()

func update_map_overlay() -> void:
	if not playing:
		return
	if scoreboard_root and camera:
		var anchor_screen := camera.unproject_position(Vector3(-25.0, 2.2, -25.0))
		scoreboard_root.position = anchor_screen - Vector2(scoreboard_root.size.x * 0.5, scoreboard_root.size.y * 0.55)
	if speech_bubble:
		var modal_open := (inspect_panel and inspect_panel.visible) or (buy_deed_card and buy_deed_card.visible)
		if not speech_bubble.text.is_empty() and speech_speaker in range(pieces.size()):
			var head_world: Vector3 = pieces[speech_speaker].global_position + Vector3(0, 9.6, 0)
			if not camera.is_position_behind(head_world):
				var screen_pt := camera.unproject_position(head_world)
				if modal_open and screen_pt.x < 430.0:
					speech_bubble.visible = false
				else:
					speech_bubble.visible = true
					speech_bubble.position = screen_pt

func randomize_names() -> void:
	var pool := NAMES.duplicate()
	pool.shuffle()
	names = [pool[0], pool[1], pool[2], pool[3]]

func create_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	menu_ui = Control.new()
	menu_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(menu_ui)

func clear_menu() -> void:
	for child in menu_ui.get_children():
		menu_ui.remove_child(child)
		child.queue_free()

func create_menu_panel(width := 430.0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 26
	panel.offset_right = 26 + width
	panel.offset_top = 20
	panel.offset_bottom = -20
	panel.add_theme_stylebox_override("panel", panel_style(Color(0.995, 0.99, 0.98, 0.96), Color("ffffff"), 24, 3, 18))
	menu_ui.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box

func menu_label(box: VBoxContainer, content: String, size: int, color := Color("1f2633")) -> Label:
	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	box.add_child(label)
	return label

func menu_button(box: VBoxContainer, content: String, callback: Callable, accent := Color("1aa3ec")) -> Button:
	var button := Button.new()
	button.text = content
	button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size", 16)
	style_juicy_button(button, accent, 14, 5)
	button.pressed.connect(callback)
	box.add_child(button)
	return button

func _style_input_control(ctrl: Control) -> void:
	ctrl.add_theme_color_override("font_color", Color("1f2633"))
	ctrl.add_theme_stylebox_override("normal", panel_style(Color("f1f5f9"), Color("cbd5e1"), 10, 2))
	ctrl.add_theme_stylebox_override("focus", panel_style(Color("ffffff"), Color("1aa3ec"), 10, 2))

func show_welcome() -> void:
	# AAA Mobile Full-Screen Home Lobby floating cleanly over the live orbiting 3D miniature world!
	playing = false
	paused = false
	in_lobby = true
	camera.size = 112.0
	camera.h_offset = 0.0
	camera.position = BASE_CAM_POS
	camera.look_at(BASE_CAM_TARGET)
	game_ui.hide()
	menu_ui.show()
	clear_menu()

	# Top-Left Profile Pill
	var prof := PanelContainer.new()
	prof.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	prof.offset_left = 20
	prof.offset_top = 16
	prof.offset_right = 248
	prof.offset_bottom = 66
	prof.add_theme_stylebox_override("panel", panel_style(Color(1, 1, 1, 0.92), Color("f01e6b"), 24, 3, 8))
	menu_ui.add_child(prof)
	var pm := MarginContainer.new()
	for s in ["margin_left", "margin_right"]:
		pm.add_theme_constant_override(s, 14)
	prof.add_child(pm)
	var pl := Label.new()
	pl.text = "★  %s  ·  1 500 000" % names[0].to_upper()
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pl.add_theme_font_size_override("font_size", 14)
	pl.add_theme_color_override("font_color", Color("1e293b"))
	pm.add_child(pl)

	# Top-Right Quick World & Dice Skin Pill Bar
	var top_right := HBoxContainer.new()
	top_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -380
	top_right.offset_right = -20
	top_right.offset_top = 16
	top_right.offset_bottom = 64
	top_right.alignment = BoxContainer.ALIGNMENT_END
	top_right.add_theme_constant_override("separation", 8)
	menu_ui.add_child(top_right)

	var map_cycle := Button.new()
	map_cycle.text = "Thế giới: %s" % MAPS[selected_map].name
	map_cycle.custom_minimum_size = Vector2(185, 44)
	map_cycle.add_theme_font_size_override("font_size", 14)
	style_juicy_button(map_cycle, Color("1aa3ec"), 20, 4)
	map_cycle.pressed.connect(func(): select_map((selected_map + 1) % MAPS.size()); show_welcome())
	top_right.add_child(map_cycle)

	var skin_cycle := Button.new()
	skin_cycle.text = "Xúc xắc: %s" % DiceRig.SKINS[selected_dice_skin].name
	skin_cycle.custom_minimum_size = Vector2(165, 44)
	skin_cycle.add_theme_font_size_override("font_size", 14)
	style_juicy_button(skin_cycle, Color("f59f00"), 20, 4)
	skin_cycle.pressed.connect(func(): select_dice_skin(selected_dice_skin + 1); show_welcome())
	top_right.add_child(skin_cycle)

	# Floating AAA Mobile Hero Title Crest at Top-Center
	var title_box := VBoxContainer.new()
	title_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title_box.offset_left = -280
	title_box.offset_right = 280
	title_box.offset_top = 18
	title_box.offset_bottom = 128
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 4)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_ui.add_child(title_box)

	var title_lbl := Label.new()
	title_lbl.text = "CỜ TỶ PHÚ"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 50)
	title_lbl.add_theme_color_override("font_color", Color("ffffff"))
	title_lbl.add_theme_color_override("font_outline_color", Color("f01e6b"))
	title_lbl.add_theme_constant_override("outline_size", 12)
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.18, 0.08, 0.20, 0.45))
	title_lbl.add_theme_constant_override("shadow_offset_y", 5)
	title_box.add_child(title_lbl)

	var sub_pill := PanelContainer.new()
	sub_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sub_pill.add_theme_stylebox_override("panel", panel_style(Color("f59f00"), Color("fff9db"), 14, 2, 6))
	title_box.add_child(sub_pill)
	var sm := MarginContainer.new()
	for s in ["margin_left", "margin_right"]:
		sm.add_theme_constant_override(s, 18)
	sub_pill.add_child(sm)
	var sub_lbl := Label.new()
	sub_lbl.text = "★  ĐA THẾ GIỚI 3D  ★"
	sub_lbl.add_theme_font_size_override("font_size", 15)
	sub_lbl.add_theme_color_override("font_color", Color("ffffff"))
	sm.add_child(sub_lbl)

	# Bottom-Center Hero Mobile Action Dock
	var dock := HBoxContainer.new()
	dock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dock.offset_left = -360
	dock.offset_right = 360
	dock.offset_top = -94
	dock.offset_bottom = -22
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 12)
	menu_ui.add_child(dock)

	var rules_btn := Button.new()
	rules_btn.text = "Luật chơi"
	rules_btn.custom_minimum_size = Vector2(124, 52)
	rules_btn.add_theme_font_size_override("font_size", 16)
	style_juicy_button(rules_btn, Color("1aa3ec"), 22, 5)
	rules_btn.pressed.connect(show_rules)
	dock.add_child(rules_btn)

	var play_btn := Button.new()
	play_btn.text = "CHƠI NGAY  →"
	play_btn.custom_minimum_size = Vector2(246, 62)
	play_btn.add_theme_font_size_override("font_size", 22)
	style_juicy_button(play_btn, Color("68b817"), 28, 7)
	play_btn.pressed.connect(show_setup)
	dock.add_child(play_btn)

	if FileAccess.file_exists(SAVE_PATH):
		var cont_btn := Button.new()
		cont_btn.text = "Tiếp tục"
		cont_btn.custom_minimum_size = Vector2(130, 52)
		cont_btn.add_theme_font_size_override("font_size", 16)
		style_juicy_button(cont_btn, Color("f01e6b"), 22, 5)
		cont_btn.pressed.connect(load_game)
		dock.add_child(cont_btn)

	var cred_btn := Button.new()
	cred_btn.text = "3D Credits"
	cred_btn.custom_minimum_size = Vector2(118, 52)
	cred_btn.add_theme_font_size_override("font_size", 15)
	style_juicy_button(cred_btn, Color("64748b"), 22, 5)
	cred_btn.pressed.connect(show_credits)
	dock.add_child(cred_btn)

func show_credits() -> void:
	in_lobby = false
	camera.h_offset = -22.0
	clear_menu()
	var box := create_menu_panel()
	menu_label(box, "NGUỒN MÔ HÌNH 3D", 24)
	menu_label(box, "Polyfork · Mesh dùng theo giấy phép CC BY 4.0\nhttps://polyfork.dev", 14, Color("475569"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var text := FileAccess.get_file_as_string("res://assets/polyfork/CREDITS.md")
	menu_label(list, text, 13, Color("334155"))
	menu_button(box, "← Quay lại", show_welcome, Color("64748b"))

func show_setup() -> void:
	in_lobby = false
	camera.size = 114.0
	camera.h_offset = -22.0
	camera.position = BASE_CAM_POS
	camera.look_at(BASE_CAM_TARGET)
	clear_menu()

	var box := create_menu_panel(424.0)
	box.add_theme_constant_override("separation", 8)
	menu_label(box, "CHUẨN BỊ VÁN CHƠI", 23, Color("18202c"))
	menu_label(box, "Tên tỷ phú của bạn", 14, Color("64748b"))

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	box.add_child(name_row)
	name_input = LineEdit.new()
	name_input.text = names[0]
	name_input.max_length = 18
	name_input.placeholder_text = "Nhập tên của bạn"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.custom_minimum_size.y = 42
	_style_input_control(name_input)
	name_row.add_child(name_input)

	var random_button := Button.new()
	random_button.text = "↻"
	random_button.custom_minimum_size = Vector2(46, 42)
	random_button.add_theme_font_size_override("font_size", 18)
	style_juicy_button(random_button, Color("1aa3ec"), 10, 4)
	random_button.pressed.connect(func(): name_input.text = NAMES.pick_random())
	name_row.add_child(random_button)

	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 8)
	box.add_child(bot_row)
	bot_label = Label.new()
	bot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_label.add_theme_font_size_override("font_size", 14)
	bot_label.add_theme_color_override("font_color", Color("334155"))
	bot_row.add_child(bot_label)
	update_bot_label()
	var reroll_bots := Button.new()
	reroll_bots.text = "Đổi đối thủ"
	reroll_bots.custom_minimum_size = Vector2(104, 34)
	reroll_bots.add_theme_font_size_override("font_size", 13)
	reroll_bots.add_theme_color_override("font_color", Color("1f2633"))
	reroll_bots.add_theme_stylebox_override("normal", panel_style(Color("e2e8f0"), Color("cbd5e1"), 8, 1))
	reroll_bots.pressed.connect(func(): randomize_bots(); update_bot_label())
	bot_row.add_child(reroll_bots)

	menu_label(box, "Chọn thế giới 3D", 14, Color("64748b"))
	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 6)
	box.add_child(map_row)
	map_buttons.clear()
	for index in range(MAPS.size()):
		var map_button := Button.new()
		map_button.text = ["Nông trại", "Hải tặc", "Phố Hội"][index]
		map_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		map_button.custom_minimum_size.y = 40
		map_button.add_theme_font_size_override("font_size", 14)
		map_button.pressed.connect(select_map.bind(index))
		map_row.add_child(map_button)
		map_buttons.append(map_button)

	map_title = menu_label(box, "", 19, Color("18202c"))
	map_description = menu_label(box, "", 14, Color("475569"))
	map_detail = menu_label(box, "", 13, Color("0f766e"))

	skin_label = menu_label(box, "Xúc xắc: %s" % DiceRig.SKINS[selected_dice_skin].name, 14, Color("64748b"))
	var skin_row := HBoxContainer.new()
	skin_row.add_theme_constant_override("separation", 6)
	box.add_child(skin_row)
	for s_idx in range(DiceRig.SKINS.size()):
		var sk: Dictionary = DiceRig.SKINS[s_idx]
		var sb := Button.new()
		sb.text = ["Đen Vàng", "Ngà Đỏ", "Ruby", "Ngọc Bích"][s_idx]
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.custom_minimum_size.y = 36
		sb.add_theme_font_size_override("font_size", 13)
		sb.add_theme_color_override("font_color", Color("ffffff") if s_idx != 1 else Color("1f2633"))
		sb.add_theme_stylebox_override("normal", panel_style(sk.body, Color("f01e6b") if s_idx == selected_dice_skin else sk.pip, 10, 3 if s_idx == selected_dice_skin else 1))
		sb.pressed.connect(func(): select_dice_skin(s_idx); show_setup())
		skin_row.add_child(sb)

	game_length = OptionButton.new()
	game_length.add_item("Cổ điển · Đến khi phá sản", 0)
	game_length.add_item("Ván nhanh · 80 lượt", 80)
	game_length.add_item("Ván tiêu chuẩn · 160 lượt", 160)
	game_length.custom_minimum_size.y = 38
	_style_input_control(game_length)
	box.add_child(game_length)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	menu_button(box, "VÀO BÀN CHƠI  →", start_game, Color("68b817"))
	menu_button(box, "← Về Sảnh Chính", show_welcome, Color("64748b"))
	update_map_labels()

func randomize_bots() -> void:
	var pool := NAMES.duplicate()
	if is_instance_valid(name_input):
		pool.erase(name_input.text.strip_edges())
	pool.shuffle()
	for index in range(1, 4):
		names[index] = pool[index - 1]

func update_bot_label() -> void:
	if is_instance_valid(bot_label):
		bot_label.text = "Đối thủ: %s · %s · %s" % [names[1], names[2], names[3]]

func update_map_labels() -> void:
	if is_instance_valid(map_title):
		map_title.text = MAPS[selected_map].name
	if is_instance_valid(map_description):
		map_description.text = MAPS[selected_map].description
	if is_instance_valid(map_detail):
		map_detail.text = MAPS[selected_map].detail
	for i in range(map_buttons.size()):
		var btn: Button = map_buttons[i]
		if is_instance_valid(btn):
			var is_sel := i == selected_map
			if is_sel:
				style_juicy_button(btn, Color("f01e6b"), 12, 4)
			else:
				btn.add_theme_color_override("font_color", Color("1f2633"))
				btn.add_theme_constant_override("outline_size", 0)
				btn.add_theme_stylebox_override("normal", panel_style(Color("f1f5f9"), Color("cbd5e1"), 12, 2))
				btn.add_theme_stylebox_override("hover", panel_style(Color("e2e8f0"), Color("cbd5e1"), 12, 2))

func select_map(index: int) -> void:
	selected_map = clampi(index, 0, MAPS.size() - 1)
	rebuild_board()
	update_map_labels()

func start_game() -> void:
	close_inspection()
	in_lobby = false
	if is_instance_valid(name_input):
		names[0] = name_input.text.strip_edges()
		if names[0].is_empty():
			names[0] = NAMES.pick_random()
		name_input.text = names[0]
	if names[0] in names.slice(1):
		randomize_bots()
	game.setup(0, names)
	game.theme = selected_map
	game.max_turns = game_length.get_selected_id() if is_instance_valid(game_length) else 0
	last_cash = [1500, 1500, 1500, 1500]
	last_turn_owner = 0
	rebuild_board()
	menu_ui.hide()
	game_ui.show()
	playing = true
	paused = false
	camera.position = BASE_CAM_POS
	camera.size = BASE_CAM_SIZE
	camera.h_offset = 0.0
	camera.look_at(BASE_CAM_TARGET)
	say_bubble(0, "Bắt đầu thôi!", 2.0)
	show_turn_toast("LƯỢT CỦA BẠN!", COLORS[0])
	refresh()

func save_game() -> bool:
	if not persistence_enabled or not playing or rolling:
		return false
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_var(game.snapshot())
	file.close()
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".tmp"), ProjectSettings.globalize_path(save_path))
	last_saved = result == OK
	return last_saved

func load_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var data = file.get_var(false)
	file.close()
	if not data is Dictionary or not game.restore(data):
		clear_menu()
		var box := create_menu_panel()
		menu_label(box, "Không thể đọc ván đã lưu.", 22)
		menu_button(box, "Quay lại", show_welcome, Color("64748b"))
		return
	in_lobby = false
	selected_map = clampi(game.theme, 0, MAPS.size() - 1)
	last_cash = [game.players[0].cash, game.players[1].cash, game.players[2].cash, game.players[3].cash]
	last_turn_owner = game.current
	rebuild_board()
	for index in range(2):
		set_die_value(index, maxi(1, game.last_roll[index]))
	playing = true
	paused = false
	menu_ui.hide()
	game_ui.show()
	camera.position = BASE_CAM_POS
	camera.size = BASE_CAM_SIZE
	camera.h_offset = 0.0
	camera.look_at(BASE_CAM_TARGET)
	refresh()

func resume_game() -> void:
	paused = false
	menu_ui.hide()
	refresh()

func show_pause() -> void:
	if rolling:
		return
	close_inspection()
	paused = true
	menu_ui.show()
	clear_menu()
	var box := create_menu_panel()
	menu_label(box, "TẠM NGHỈ", 26)
	menu_label(box, "%s · Lượt %d · Đang tới %s" % [MAPS[selected_map].name, game.turn_count + 1, game.players[game.current].name], 15, Color("475569"))
	menu_button(box, "Tiếp tục chơi", resume_game, Color("68b817"))
	menu_button(box, "Đổi Skin Xúc xắc: %s" % DiceRig.SKINS[selected_dice_skin].name, func(): select_dice_skin(selected_dice_skin + 1); show_pause(), Color("f59f00"))
	menu_button(box, "Âm thanh: %s" % ("Bật" if sound_enabled else "Tắt"), func(): toggle_sound(); show_pause(), Color("1aa3ec"))
	menu_button(box, "Lưu ván hiện tại", func(): menu_label(box, "✓ Đã lưu ván thành công." if save_game() else "Chưa lưu được ván.", 14, Color("0f766e")), Color("1aa3ec"))
	menu_button(box, "Cách chơi", show_rules, Color("64748b"))
	menu_button(box, "Lưu và về Sảnh Chính", func():
		if save_game():
			show_welcome()
		else:
			menu_label(box, "Chưa lưu được, hãy thử lại.", 14, Color("dc2626")), Color("f01e6b"))

func show_rules() -> void:
	in_lobby = false
	camera.h_offset = -22.0
	clear_menu()
	var box := create_menu_panel()
	menu_label(box, "LUẬT CHƠI TỶ PHÚ", 25)
	menu_label(box, "• Tung 2 xúc xắc 3D để di chuyển quanh bàn cờ. Qua ô Xuất phát nhận ngay +200K.", 15, Color("334155"))
	menu_label(box, "• Dừng ở ô đất trống: Mua ngay theo giá niêm yết hoặc mở phiên Đấu giá công khai.", 15, Color("334155"))
	menu_label(box, "• Sở hữu trọn bộ cùng màu để xây đều từ 1–4 Nhà đến Khách sạn ★ (nhân tiền thuê lên tới 25 lần!).", 15, Color("334155"))
	menu_label(box, "• Tung đôi được đi thêm lượt; tung đôi 3 lần liên tiếp sẽ vào Đảo Tù.", 15, Color("334155"))
	menu_label(box, "• Mở giỏ Tài sản bên phải để nâng cấp nhà, thế chấp hoặc mua lại đất từ đối thủ AI.", 15, Color("334155"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	menu_button(box, "← Quay lại", show_pause if playing else show_welcome, Color("1aa3ec"))

func show_assets() -> void:
	if rolling:
		return
	close_inspection()
	paused = true
	menu_ui.show()
	clear_menu()
	var box := create_menu_panel(430.0)
	menu_label(box, "TÀI SẢN & GIAO DỊCH", 23)
	menu_label(box, "Tiền mặt: %s\nTổng giá trị tài sản: %s" % [HudModals.format_cash(game.players[0].cash), HudModals.format_cash(game.net_worth(0))], 15, Color("0f766e"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var listing := VBoxContainer.new()
	listing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listing.add_theme_constant_override("separation", 7)
	scroll.add_child(listing)

	for index in range(40):
		var tile: Dictionary = game.tiles[index]
		if tile.owner >= 0:
			var col: Color = GROUP_COLORS[tile.group] if tile.group >= 0 else COLORS[tile.owner]
			var stars: String = (" · ★KS" if tile.level == 5 else (" · %d Nhà" % tile.level if tile.level > 0 else ""))
			menu_button(listing, "%s (%dK)%s — %s" % [tile.name, tile.price, stars, game.players[tile.owner].name], show_property.bind(index), col.darkened(0.08))
	if listing.get_child_count() == 0:
		menu_label(listing, "Chưa có bất động sản nào có chủ.\nHãy tung xúc xắc để mua lô đất đầu tiên!", 16, Color("64748b"))
	menu_button(box, "← Quay lại bàn cờ", resume_game, Color("64748b"))

func show_property(index: int) -> void:
	selected_tile = index
	clear_menu()
	var box := create_menu_panel(420.0)
	var tile: Dictionary = game.tiles[index]
	var hdr_col: Color = GROUP_COLORS[tile.group] if tile.group >= 0 else COLORS[maxi(0, tile.owner)]

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", panel_style(hdr_col, Color("ffffff"), 14, 2))
	box.add_child(banner)
	var bm := MarginContainer.new()
	for s in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		bm.add_theme_constant_override(s, 12)
	banner.add_child(bm)
	var btitle := Label.new()
	btitle.text = "%s  ·  %dK" % [tile.name.to_upper(), tile.price]
	btitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btitle.add_theme_font_size_override("font_size", 20)
	btitle.add_theme_color_override("font_color", Color("ffffff"))
	bm.add_child(btitle)

	menu_label(box, "Chủ sở hữu: %s\nCấp công trình: %d / 5\nTiền thuê hiện tại: %dK (%s)" % [
		game.players[tile.owner].name,
		tile.level,
		game.rent_for(index),
		"Đang thế chấp" if tile.mortgaged else "Đang hoạt động"
	], 16, Color("334155"))

	var allowed: bool = game.current == 0 and game.phase in ["roll", "end"] and game.winner < 0
	if tile.owner == 0:
		var upgrade := menu_button(box, "Xây công trình · %dK" % game.build_cost(index), property_action.bind("build", index), Color("68b817"))
		upgrade.disabled = not allowed or not game.can_build(index, 0)
		var sell := menu_button(box, "Bán 1 cấp · +%dK" % (game.build_cost(index) / 2), property_action.bind("sell", index), Color("f59f00"))
		sell.disabled = not allowed or tile.level == 0
		var pledge := menu_button(box, ("Chuộc đất · %dK" % ceili(tile.price * 0.55)) if tile.mortgaged else ("Thế chấp · +%dK" % (tile.price / 2)), property_action.bind("mortgage", index), Color("1aa3ec"))
		pledge.disabled = not allowed
	else:
		menu_label(box, "Đề nghị mua lại bằng tiền mặt (đối thủ định giá cao hơn nếu bạn sắp đủ bộ màu).", 14, Color("64748b"))
		var trade := menu_button(box, "Mua lại ngay · %dK" % game.trade_price(index), property_action.bind("trade", index), Color("f01e6b"))
		trade.disabled = not allowed

	menu_label(box, "Lưu ý: Cần sở hữu trọn bộ màu để xây nhà và xây đều giữa các ô.", 13, Color("64748b"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	menu_button(box, "Danh sách tài sản", show_assets, Color("1aa3ec"))
	menu_button(box, "← Quay lại bàn cờ", resume_game, Color("64748b"))

func property_action(action: String, index: int) -> void:
	if game.current != 0 or game.phase not in ["roll", "end"]:
		return
	var success := false
	match action:
		"build": success = game.build(index, 0)
		"sell": success = game.sell_level(index, 0)
		"mortgage": success = game.mortgage(index, 0)
		"trade": success = game.buy_from_bot(index, game.trade_price(index))
	refresh()
	show_property(index)
	if not success:
		menu_label(menu_ui.get_child(0).get_child(0).get_child(0), "Chưa đủ điều kiện tiền mặt hoặc quy tắc xây đều.", 14, Color("dc2626"))
	else:
		play_sound(action_sound)

func play_sound(stream: AudioStreamWAV) -> void:
	if sound_enabled and sound_player:
		sound_player.stream = stream
		sound_player.play()

func toggle_sound() -> void:
	sound_enabled = not sound_enabled
	if not sound_enabled and sound_player:
		sound_player.stop()
	if is_instance_valid(sound_tool_btn):
		sound_tool_btn.sound_on = sound_enabled

func create_player_card(root: Control, index: int) -> void:
	var card := PlayerBanner.new()
	var right := index == 1 or index == 3
	var bottom := index >= 2
	card.anchor_left = 1.0 if right else 0.0
	card.anchor_right = card.anchor_left
	card.anchor_top = 1.0 if bottom else 0.0
	card.anchor_bottom = card.anchor_top
	card.offset_left = -298 if right else 12
	card.offset_right = -12 if right else 298
	card.offset_top = -108 if bottom else 12
	card.offset_bottom = -12 if bottom else 108
	card.color = COLORS[index]
	card.right_aligned = right
	card.bottom_aligned = bottom
	card.is_vip = index == 0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card)
	player_cards.append(card)

	var avatar := Control.new()
	avatar.position = Vector2(206 if right else 10, 11)
	avatar.size = Vector2(70, 66 if index == 0 else 72)
	avatar.clip_contents = true
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(avatar)

	var initial := Label.new()
	initial.text = ["B", "L", "H", "M"][index]
	initial.hide()
	avatar.add_child(initial)
	player_initials.append(initial)
	create_portrait(avatar, index)

	var text_x := 22.0 if right else 88.0
	var name_y := 58.0 if bottom else 8.0
	var cash_y := 18.0 if bottom else 44.0

	var name_label := Label.new()
	name_label.position = Vector2(text_x, name_y)
	name_label.size = Vector2(174, 28)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color("ffffff"))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.28))
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(name_label)
	player_names.append(name_label)

	var money_label := Label.new()
	money_label.position = Vector2(text_x, cash_y)
	money_label.size = Vector2(142, 32)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 19)
	money_label.add_theme_color_override("font_color", Color("1f2633"))
	card.add_child(money_label)
	player_cash.append(money_label)

	var stats := Label.new()
	stats.hide()
	card.add_child(stats)
	player_stats.append(stats)

func create_portrait(parent: Control, index: int) -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(144, 152)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	# CRITICAL 60 FPS OPTIMIZATION: render static portraits ONCE instead of 4 extra 3D worlds every frame!
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	container.add_child(viewport)
	portrait_viewports.append(viewport)

	var character := Character.new()
	viewport.add_child(character)
	character.setup(_character_id_for(index), COLORS[index], false)
	character.set_process(false)
	character.rotation.y = deg_to_rad(-18.0 if (index % 2 == 1) else 18.0)
	portrait_characters.append(character)

	var portrait_camera := Camera3D.new()
	portrait_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	portrait_camera.size = 0.78
	portrait_camera.position = Vector3(0.0, 1.48, 4.0)
	viewport.add_child(portrait_camera)
	portrait_camera.look_at(Vector3(0.0, 1.44, 0.0))

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-34, -24, 0)
	light.light_energy = 1.45
	viewport.add_child(light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 145, 0)
	fill.light_energy = 0.75
	viewport.add_child(fill)

func active_actor() -> int:
	return game.auction.turn if game.phase == "auction" else game.current

func _animate_world_props(delta: float) -> void:
	if not is_instance_valid(board) or not board.has_meta("animated_props"):
		return
	world_clock += delta
	var props: Array = board.get_meta("animated_props")
	for item in props:
		var node: Node3D = item.get("node")
		if not is_instance_valid(node):
			continue
		match item.kind:
			"spin":
				node.rotation.y += delta * float(item.get("speed", 0.5))
			"bob":
				node.position.y = float(item.base_y) + sin(world_clock * 2.1 + float(item.phase)) * 0.16
			"rock":
				node.rotation.z = sin(world_clock * 1.5 + float(item.phase)) * 0.045
				node.rotation.x = cos(world_clock * 1.2 + float(item.phase)) * 0.03

func _process(delta: float) -> void:
	_animate_world_props(delta)
	if not dice_bundle.is_empty():
		DiceRig.sync_shadows(dice_bundle)

	if in_lobby and not playing:
		lobby_orbit += delta * 0.14
		var radius := 175.0
		var ang := deg_to_rad(45.0) + sin(lobby_orbit) * 0.22
		camera.position = Vector3(cos(ang) * radius, 108.0, sin(ang) * radius)
		camera.look_at(BASE_CAM_TARGET)

	if speech_timer > 0.0:
		speech_timer -= delta
		if speech_timer <= 0.0 and speech_bubble:
			speech_bubble.text = ""

	if playing:
		var target_focus := BASE_CAM_TARGET
		var target_size := BASE_CAM_SIZE
		if inspected_tile >= 0:
			target_focus = tile_position(inspected_tile) * 0.16 + BASE_CAM_TARGET
			target_size = 90.0
		elif rolling and animation_phase == "dice":
			target_size = 105.5
		camera.position = camera.position.lerp(BASE_CAM_POS + (target_focus - BASE_CAM_TARGET), minf(1.0, delta * 4.5))
		camera.size = lerpf(camera.size, target_size, minf(1.0, delta * 4.5))
		update_map_overlay()

	if not playing or paused or rolling or active_actor() == 0 or game.winner >= 0:
		return

	bot_timer += delta
	if bot_timer < 1.18:
		return
	bot_timer = 0.0
	var actor := active_actor()
	match game.phase:
		"auction":
			var price: int = game.tiles[game.auction.tile].price
			var reserve: float = 160 + (1 - game.players[actor].risk) * 280
			var will_bid: bool = game.auction.bid + 10 <= mini(int(price * 1.3), int(game.players[actor].cash - reserve))
			say_bubble(actor, "Trả %dK!" % (game.auction.bid + 10) if will_bid else "Nhường thôi!", 1.5)
			game.auction_action(will_bid)
		"roll":
			game.roll()
			animate_roll()
		"buy":
			if game.bot_buy():
				var tname: String = game.tiles[game.players[actor].position].name
				game.buy()
				say_bubble(actor, "Mua %s!" % tname, 1.9)
				play_sound(action_sound)
			else:
				say_bubble(actor, "Đem đấu giá!", 1.6)
				game.skip_buy()
		"end":
			game.end_turn()
	refresh()

func on_action() -> void:
	if game.winner >= 0:
		show_welcome()
		return
	if active_actor() != 0 or rolling or paused:
		return
	close_inspection()
	if skin_popup:
		skin_popup.hide()
	match game.phase:
		"auction":
			say_bubble(0, "Trả %dK!" % (game.auction.bid + 10), 1.6)
			game.auction_action(true)
			play_sound(action_sound)
		"roll":
			game.roll()
			animate_roll()
		"buy":
			var tname: String = game.tiles[game.players[0].position].name
			game.buy()
			say_bubble(0, "Đã mua %s!" % tname, 2.0)
			play_sound(action_sound)
		"end":
			game.end_turn()
	refresh()

func on_skip() -> void:
	if active_actor() == 0 and not rolling and not paused:
		if game.phase == "auction":
			say_bubble(0, "Bỏ lượt đấu giá", 1.5)
			game.auction_action(false)
		else:
			say_bubble(0, "Mở đấu giá!", 1.6)
			game.skip_buy()
		refresh()

func refresh() -> void:
	if not status_label:
		return
	status_label.text = game.message
	var has_roll: bool = game.last_roll[0] > 0
	roll_total_label.text = str(game.last_roll[0] + game.last_roll[1]) if has_roll else "–"
	if scoreboard_sub_label and has_roll:
		scoreboard_sub_label.text = "%d + %d%s" % [game.last_roll[0], game.last_roll[1], " · ĐÔI!" if game.last_roll[0] == game.last_roll[1] else ""]
	if scoreboard_root:
		scoreboard_root.visible = has_roll and inspected_tile < 0

	if rolling:
		status_label.text = "%s đang %s…" % [game.players[game.current].name, "tung xúc xắc" if animation_phase == "dice" else "di chuyển"]
	top_label.text = "%s  ·  Lượt %d  ·  Skin: %s" % [MAPS[selected_map].name, game.turn_count + 1, DiceRig.SKINS[selected_dice_skin].name]

	if playing and not rolling and game.phase == "roll" and game.current != last_turn_owner and game.winner < 0:
		last_turn_owner = game.current
		show_turn_toast("LƯỢT CỦA BẠN!" if game.current == 0 else "LƯỢT CỦA %s" % game.players[game.current].name.to_upper(), COLORS[game.current])

	var human_owned_count := 0
	var money_stacks: Array = board.get_meta("money_stacks") if is_instance_valid(board) else []

	for index in range(4):
		var player: Dictionary = game.players[index]
		if playing and not rolling and index < last_cash.size() and player.cash != last_cash[index]:
			spawn_cash_popup(index, player.cash - last_cash[index])
			last_cash[index] = player.cash

		player_names[index].text = player.name.to_upper()
		player_initials[index].text = player.name.left(1).to_upper()
		player_cash[index].text = HudModals.format_cash(player.cash) if player.alive else "PHÁ SẢN"

		var owned := 0
		for tile in game.tiles:
			if tile.owner == index:
				owned += 1
		if index == 0:
			human_owned_count = owned
		player_stats[index].text = "%d khu đất · Tổng %s" % [owned, HudModals.format_cash(game.net_worth(index))]

		var card = player_cards[index]
		card.bankrupt = not player.alive
		card.owned_count = owned
		card.active = index == active_actor()
		card.queue_redraw()
		card.modulate = Color.WHITE if player.alive else Color("9ca3af")

		if not rolling:
			visual_positions[index] = player.position
			pieces[index].position = pawn_position(player.position, index)
		pieces[index].visible = player.alive
		pieces[index].get_node("NameTag").visible = index == active_actor()

		if index < money_stacks.size():
			MoneyPile.update_pile(money_stacks[index], player.cash, game.net_worth(index), owned, player.alive)

	if is_instance_valid(assets_tool_btn):
		assets_tool_btn.badge_count = human_owned_count

	for index in range(40):
		var tile: Dictionary = game.tiles[index]
		var owner: int = tile.owner
		var owner_col: Color = COLORS[owner] if owner >= 0 else Color("94a3b8")
		BoardArt.update_tile_buildings(board, index, owner, tile.level, tile.mortgaged, owner_col)
		level_labels[index].text = ("★" if tile.level == 5 else ("★%d" % tile.level if tile.level > 0 else ""))

	var show_buy_deed: bool = playing and not paused and not rolling and active_actor() == 0 and game.phase == "buy" and game.winner < 0 and inspected_tile < 0
	if buy_deed_card:
		buy_deed_card.visible = show_buy_deed
		if show_buy_deed:
			var pos_idx: int = game.players[0].position
			var btile: Dictionary = game.tiles[pos_idx]
			var hcol: Color = GROUP_COLORS[btile.group] if btile.group >= 0 else Color("1aa3ec")
			buy_deed_header.add_theme_stylebox_override("panel", panel_style(hcol, Color("ffffff"), 16, 0))
			buy_deed_title.text = btile.name.to_upper()
			buy_deed_price.text = "Giá niêm yết: %dK" % btile.price
			buy_deed_body.text = _deed_details_text(pos_idx)
			buy_card_btn.text = "Mua (%dK)" % btile.price
			buy_card_btn.disabled = game.players[0].cash < btile.price

	action_button.disabled = active_actor() != 0 or rolling
	skip_button.visible = active_actor() == 0 and game.phase in ["buy", "auction"] and game.winner < 0 and not rolling
	skip_button.text = "Bỏ lượt" if game.phase == "auction" else "Đấu giá"

	match game.phase:
		"auction":
			action_button.text = "Trả giá · %dK" % (game.auction.bid + 10)
		"roll":
			action_button.text = "TUNG XÚC XẮC"
		"buy":
			var p_tile: Dictionary = game.tiles[game.players[active_actor()].position]
			action_button.text = "Mua %s · %dK" % [p_tile.name, p_tile.price]
		"end":
			action_button.text = "Kết thúc lượt  →"

	if rolling:
		action_button.text = "Đang tung xúc xắc…" if animation_phase == "dice" else "Đang di chuyển…"
	elif active_actor() != 0 and game.winner < 0:
		action_button.text = "Lượt của %s…" % game.players[active_actor()].name

	if game.winner >= 0:
		action_button.text = "Về Sảnh Chính"
		action_button.disabled = false

	update_map_overlay()
	if playing and not rolling:
		save_game()
