extends Control

@onready var level_root: Node2D = $LevelRoot
@onready var bg_texture_rect: TextureRect = $TextureRect if has_node("TextureRect") else null

var hud_canvas: CanvasLayer = null
var current_lvl_data: LevelData = null

func _ready() -> void:
	current_lvl_data = LevelManager.get_default_level()
	if current_lvl_data:
		load_current_level(current_lvl_data)
	else:
		push_error("GamePlay: Failed to obtain LevelData")

func load_current_level(lvl_data: LevelData) -> void:
	current_lvl_data = lvl_data
	var player = LevelLoader.load_level(lvl_data, level_root)
	apply_world_theme(lvl_data, player)
	setup_hud(lvl_data)

func apply_world_theme(lvl_data: LevelData, player: Node2D = null) -> void:
	var theme_info = WorldThemeRegistry.get_theme(lvl_data.world_theme)
	var bg_path: String = theme_info.get("background", "res://Sprite/ENV/setting screen.png")
	if ResourceLoader.exists(bg_path):
		var bg_tex = load(bg_path)
		if player and player.has_node("Camera2D/TextureRect"):
			var p_bg = player.get_node("Camera2D/TextureRect") as TextureRect
			if p_bg:
				p_bg.texture = bg_tex
				p_bg.z_index = -100
				p_bg.z_as_relative = false

func setup_hud(lvl_data: LevelData) -> void:
	if hud_canvas and is_instance_valid(hud_canvas):
		hud_canvas.queue_free()

	var theme_info = WorldThemeRegistry.get_theme(lvl_data.world_theme)
	var theme_name: String = theme_info.get("name", "World 1")

	hud_canvas = CanvasLayer.new()
	add_child(hud_canvas)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.position = Vector2(15, 15)
	hud_canvas.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	var bg := PanelContainer.new()
	hbox.add_child(bg)

	var display_title = lvl_data.level_name if lvl_data.level_name != "" else lvl_data.level_id
	var label := Label.new()
	label.text = " 🎮 " + display_title + "  |  🌍 " + theme_name + " "
	bg.add_child(label)

	var lvl_select_btn := Button.new()
	lvl_select_btn.text = " 📋 Level Select "
	lvl_select_btn.pressed.connect(open_level_select_panel)
	hbox.add_child(lvl_select_btn)

	var editor_btn := Button.new()
	editor_btn.text = " ✏️ Editor "
	editor_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://addons/zumpa_level_editor/level_editor.tscn")
	)
	hbox.add_child(editor_btn)

func open_level_select_panel() -> void:
	get_tree().paused = true

	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# Overlay Backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 340)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var all_paths = LevelManager.get_all_level_paths()

	var title := Label.new()
	title.text = "SELECT LEVEL (%d Levels)" % all_paths.size()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 220)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	var current_path = LevelManager.get_active_level_path()

	for i in range(all_paths.size()):
		var path = all_paths[i]
		var file_name = path.get_file().get_basename()
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(110, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var level_num_str = file_name.replace("level_", "")
		if level_num_str.is_valid_int():
			btn.text = "Level %d" % level_num_str.to_int()
		else:
			btn.text = file_name

		if path.get_file() == current_path.get_file():
			btn.text = "▶ " + btn.text

		btn.pressed.connect(func():
			get_tree().paused = false
			canvas.queue_free()
			var loaded = LevelManager.load_level_data(path)
			if loaded:
				load_current_level(loaded)
		)
		grid.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = " ❌ Close "
	close_btn.pressed.connect(func():
		get_tree().paused = false
		canvas.queue_free()
	)
	vbox.add_child(close_btn)
