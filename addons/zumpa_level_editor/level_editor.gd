@tool
extends Control

@onready var canvas: Control = %Canvas
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var palette_container: VBoxContainer = %PaletteContainer

# Top Toolbar
@onready var new_btn: Button = %NewBtn
@onready var save_btn: Button = %SaveBtn
@onready var load_btn: Button = %LoadBtn
@onready var level_select_opt: OptionButton = %LevelSelectOpt
@onready var play_btn: Button = %PlayBtn
@onready var center_view_btn: Button = %CenterViewBtn
@onready var delete_btn: Button = %DeleteBtn
@onready var duplicate_btn: Button = %DuplicateBtn
@onready var snap_check: CheckBox = %SnapCheck
@onready var grid_size_opt: OptionButton = %GridSizeOpt

# Right Inspector
@onready var inspector_panel: PanelContainer = %InspectorPanel
@onready var type_label: Label = %TypeLabel
@onready var pos_x_spin: SpinBox = %PosXSpin
@onready var pos_y_spin: SpinBox = %PosYSpin
@onready var rot_spin: SpinBox = %RotSpin
@onready var scale_x_spin: SpinBox = %ScaleXSpin
@onready var scale_y_spin: SpinBox = %ScaleYSpin
@onready var rot_speed_spin: SpinBox = %RotSpeedSpin
@onready var prop_speed_row: HBoxContainer = %PropSpeedRow
@onready var move_speed_spin: SpinBox = %MoveSpeedSpin
@onready var prop_move_speed_row: HBoxContainer = %PropMoveSpeedRow
@onready var move_dist_spin: SpinBox = %MoveDistSpin
@onready var prop_move_dist_row: HBoxContainer = %PropMoveDistRow
@onready var prop_move_dir_row: HBoxContainer = %PropMoveDirRow
@onready var move_dir_opt: OptionButton = %MoveDirOpt
@onready var apply_btn: Button = %ApplyBtn

# Tile Palette Inspector
@onready var atlas_x_spin: SpinBox = %AtlasXSpin
@onready var atlas_y_spin: SpinBox = %AtlasYSpin
@onready var tile_size_opt: OptionButton = %TileSizeOpt
@onready var atlas_picker: AtlasPalettePicker = %AtlasPicker
@onready var zoom_out_btn: Button = %ZoomOutBtn
@onready var zoom_label: Label = %ZoomLabel
@onready var zoom_in_btn: Button = %ZoomInBtn
@onready var zoom_fit_btn: Button = %ZoomFitBtn
@onready var atlas_scroll_container: ScrollContainer = %AtlasScrollContainer
@onready var tile_preview_rect: TextureRect = %TilePreviewRect
@onready var btn_grass_top: Button = %BtnGrassTop
@onready var btn_grass_left: Button = %BtnGrassLeft
@onready var btn_grass_right: Button = %BtnGrassRight
@onready var btn_dirt: Button = %BtnDirt
@onready var btn_sand: Button = %BtnSand
@onready var btn_stone: Button = %BtnStone

# Bottom Bar
@onready var level_id_edit: LineEdit = %LevelIDEdit
@onready var level_name_edit: LineEdit = %LevelNameEdit
@onready var world_theme_opt: OptionButton = %WorldThemeOpt
@onready var width_spin: SpinBox = %WidthSpin
@onready var height_spin: SpinBox = %HeightSpin
@onready var player_x_spin: SpinBox = %PlayerXSpin
@onready var player_y_spin: SpinBox = %PlayerYSpin

# Dialogs
@onready var save_dialog: FileDialog = %SaveDialog
@onready var load_dialog: FileDialog = %LoadDialog

var current_level: LevelData = null
var current_level_path: String = "res://Levels/level_001.tres"
var tool_buttons: Dictionary = {}
var level_paths_list: Array[String] = []
var world_theme_keys: Array[String] = []

func _ready() -> void:
	setup_grid_options()
	setup_world_theme_options()
	setup_palette()
	connect_signals()
	populate_level_selector()
	update_tile_preview()

	# Load initial default level
	var existing_paths = LevelManager.get_all_level_paths()
	if existing_paths.size() > 0:
		var loaded = LevelManager.load_level_data(existing_paths[0])
		if loaded:
			load_level(loaded, existing_paths[0])
		else:
			new_level()
	else:
		new_level()

func setup_grid_options() -> void:
	grid_size_opt.clear()
	grid_size_opt.add_item("16 px", 16)
	grid_size_opt.add_item("32 px", 32)
	grid_size_opt.add_item("64 px", 64)
	grid_size_opt.add_item("128 px", 128)
	grid_size_opt.select(1) # 32px default

func setup_world_theme_options() -> void:
	world_theme_opt.clear()
	world_theme_keys.clear()
	var themes = WorldThemeRegistry.get_all_themes()
	var idx = 0
	for key in themes:
		world_theme_keys.append(key)
		world_theme_opt.add_item(themes[key].get("name", key), idx)
		idx += 1

func setup_palette() -> void:
	for child in palette_container.get_children():
		child.queue_free()
	tool_buttons.clear()

	# Select/Move Tool
	var select_btn := Button.new()
	select_btn.text = "✋ Select / Move"
	select_btn.toggle_mode = true
	select_btn.button_pressed = true
	select_btn.pressed.connect(func(): set_active_tool("", select_btn))
	palette_container.add_child(select_btn)
	tool_buttons[""] = select_btn

	# Player Start Tool
	var p_btn := Button.new()
	p_btn.text = "🚩 Player Start"
	p_btn.toggle_mode = true
	p_btn.pressed.connect(func(): set_active_tool("player_start", p_btn))
	palette_container.add_child(p_btn)
	tool_buttons["player_start"] = p_btn

	# Tile Brush Tool
	var tb_btn := Button.new()
	tb_btn.text = "🧱 Draw Tile"
	tb_btn.toggle_mode = true
	tb_btn.pressed.connect(func(): set_active_tool("tile_brush", tb_btn))
	palette_container.add_child(tb_btn)
	tool_buttons["tile_brush"] = tb_btn

	# Tile Eraser Tool
	var te_btn := Button.new()
	te_btn.text = "🧹 Erase Tile"
	te_btn.toggle_mode = true
	te_btn.pressed.connect(func(): set_active_tool("tile_eraser", te_btn))
	palette_container.add_child(te_btn)
	tool_buttons["tile_eraser"] = te_btn

	# Separator
	var sep := HSeparator.new()
	palette_container.add_child(sep)

	# Registered Objects
	var entries = ObjectRegistry.get_all_entries()
	for id in entries:
		var entry = entries[id]
		var btn := Button.new()
		btn.text = "+ " + entry.get("name", id)
		btn.toggle_mode = true
		btn.clip_text = true
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(func(): set_active_tool(id, btn))
		palette_container.add_child(btn)
		tool_buttons[id] = btn

func populate_level_selector() -> void:
	level_select_opt.clear()
	level_paths_list = LevelManager.get_all_level_paths()

	var selected_idx = -1
	for i in range(level_paths_list.size()):
		var path = level_paths_list[i]
		var file_name = path.get_file()
		level_select_opt.add_item(file_name, i)
		if path == current_level_path:
			selected_idx = i

	if level_paths_list.size() > 0:
		if selected_idx >= 0:
			level_select_opt.select(selected_idx)
		else:
			level_select_opt.select(0)
	elif current_level:
		var unsaved_name = current_level_path.get_file() + " (Unsaved)"
		level_select_opt.add_item(unsaved_name, 0)
		level_select_opt.select(0)

func set_active_tool(id: String, active_btn: Button) -> void:
	canvas.active_placement_id = id
	for tool_id in tool_buttons:
		tool_buttons[tool_id].button_pressed = (tool_buttons[tool_id] == active_btn)

func connect_signals() -> void:
	new_btn.pressed.connect(new_level)
	save_btn.pressed.connect(on_save_pressed)
	load_btn.pressed.connect(on_load_pressed)
	play_btn.pressed.connect(on_play_pressed)
	center_view_btn.pressed.connect(center_view_on_player)
	delete_btn.pressed.connect(delete_selected)
	duplicate_btn.pressed.connect(duplicate_selected)
	level_select_opt.item_selected.connect(on_level_selected_from_opt)

	snap_check.toggled.connect(func(toggled):
		canvas.grid_snap = toggled
		canvas.queue_redraw()
	)
	grid_size_opt.item_selected.connect(func(idx):
		canvas.grid_size = grid_size_opt.get_item_id(idx)
		canvas.queue_redraw()
	)

	canvas.object_selected.connect(on_object_selected)
	canvas.object_moved.connect(update_inspector_values)
	canvas.player_start_changed.connect(on_player_start_changed)

	apply_btn.pressed.connect(apply_inspector_changes)

	# Tile Palette signals
	if atlas_picker:
		atlas_picker.tile_selected.connect(on_atlas_tile_selected)
		atlas_picker.zoom_changed.connect(func(z):
			if zoom_label:
				zoom_label.text = "%.1fx" % z
		)

	if zoom_out_btn:
		zoom_out_btn.pressed.connect(func():
			if atlas_picker:
				atlas_picker.zoom_scale -= 0.5
		)
	if zoom_in_btn:
		zoom_in_btn.pressed.connect(func():
			if atlas_picker:
				atlas_picker.zoom_scale += 0.5
		)
	if zoom_fit_btn:
		zoom_fit_btn.pressed.connect(func():
			if atlas_picker and atlas_scroll_container and atlas_picker.texture:
				var cols = atlas_picker._get_cols()
				var avail_w = atlas_scroll_container.size.x - 10
				if cols > 0 and avail_w > 0:
					atlas_picker.zoom_scale = max(0.5, avail_w / (cols * 16.0))
		)

	atlas_x_spin.value_changed.connect(func(_v): update_tile_preview())
	atlas_y_spin.value_changed.connect(func(_v): update_tile_preview())

	if tile_size_opt:
		tile_size_opt.item_selected.connect(func(idx):
			var ts_id = tile_size_opt.get_item_id(idx)
			var theme_id = "world_1"
			if current_level:
				theme_id = current_level.world_theme
			WorldThemeRegistry.set_theme_tile_size(theme_id, Vector2i(ts_id, ts_id))
			update_tile_preview()
			if canvas:
				canvas.refresh_canvas()
		)

	btn_grass_top.pressed.connect(func(): set_tile_atlas(1, 1))
	btn_grass_left.pressed.connect(func(): set_tile_atlas(0, 1))
	btn_grass_right.pressed.connect(func(): set_tile_atlas(2, 1))
	btn_dirt.pressed.connect(func(): set_tile_atlas(1, 2))
	btn_sand.pressed.connect(func(): set_tile_atlas(7, 1))
	btn_stone.pressed.connect(func(): set_tile_atlas(11, 1))

	# Bottom bar edits
	level_id_edit.text_changed.connect(func(t): if current_level: current_level.level_id = t)
	level_name_edit.text_changed.connect(func(t): if current_level: current_level.level_name = t)
	world_theme_opt.item_selected.connect(func(idx):
		if current_level and idx >= 0 and idx < world_theme_keys.size():
			current_level.world_theme = world_theme_keys[idx]
			var theme_info = WorldThemeRegistry.get_theme(current_level.world_theme)
			var def_atlas: Vector2i = theme_info.get("default_atlas_coords", Vector2i(1, 1))
			set_tile_atlas(def_atlas.x, def_atlas.y)
			canvas.queue_redraw()
	)
	width_spin.value_changed.connect(func(v):
		if current_level:
			current_level.level_size.x = v
			canvas.update_canvas_size()
			canvas.queue_redraw()
	)
	height_spin.value_changed.connect(func(v):
		if current_level:
			current_level.level_size.y = v
			canvas.update_canvas_size()
			canvas.queue_redraw()
	)
	player_x_spin.value_changed.connect(func(v):
		if current_level:
			current_level.player_start.x = v
			canvas.refresh_canvas()
	)
	player_y_spin.value_changed.connect(func(v):
		if current_level:
			current_level.player_start.y = v
			canvas.refresh_canvas()
	)

	save_dialog.file_selected.connect(save_level_to_file)
	load_dialog.file_selected.connect(load_level_from_file)

func on_atlas_tile_selected(coords: Vector2i) -> void:
	set_tile_atlas(coords.x, coords.y)
	if tool_buttons.has("tile_brush"):
		set_active_tool("tile_brush", tool_buttons["tile_brush"])

func set_tile_atlas(ax: int, ay: int) -> void:
	atlas_x_spin.value = ax
	atlas_y_spin.value = ay
	if atlas_picker:
		atlas_picker.selected_coords = Vector2i(ax, ay)
		atlas_picker.ensure_selected_visible(atlas_scroll_container)
	update_tile_preview()

func update_tile_preview() -> void:
	var ax = int(atlas_x_spin.value)
	var ay = int(atlas_y_spin.value)
	canvas.current_tile_atlas = Vector2i(ax, ay)

	var theme_id = "world_1"
	if current_level:
		theme_id = current_level.world_theme
	var theme_info = WorldThemeRegistry.get_theme(theme_id)
	var tex_path: String = theme_info.get("platform_texture", "res://tiles/Terrain (16x16).png")
	var t_size: Vector2i = theme_info.get("tile_size", Vector2i(16, 16))

	if tile_size_opt:
		for i in range(tile_size_opt.item_count):
			if tile_size_opt.get_item_id(i) == t_size.x:
				tile_size_opt.select(i)
				break

	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		if atlas_picker:
			atlas_picker.tile_size = t_size
			if atlas_picker.texture != tex:
				atlas_picker.texture = tex
			atlas_picker.selected_coords = Vector2i(ax, ay)

		var atlas_tex := AtlasTexture.new()
		atlas_tex.atlas = tex
		atlas_tex.region = Rect2(ax * t_size.x, ay * t_size.y, t_size.x, t_size.y)
		tile_preview_rect.texture = atlas_tex

func on_level_selected_from_opt(idx: int) -> void:
	if idx >= 0 and idx < level_paths_list.size():
		var path = level_paths_list[idx]
		var loaded = LevelManager.load_level_data(path)
		if loaded:
			load_level(loaded, path)

func new_level() -> void:
	var existing = LevelManager.get_all_level_paths()
	var max_num = 0
	for path in existing:
		var file_name = path.get_file().get_basename()
		if file_name.begins_with("level_"):
			var num_str = file_name.replace("level_", "")
			if num_str.is_valid_int():
				var num = num_str.to_int()
				if num > max_num:
					max_num = num
	var new_num = max_num + 1
	var new_id = "level_%03d" % new_num

	current_level = LevelData.new()
	current_level.level_id = new_id
	current_level.level_name = "Level %d" % new_num
	current_level.world_theme = "world_1"
	current_level.player_start = Vector2(529, 1135)
	current_level.level_size = Vector2(1080, 3000)

	# Add default platform
	var plt := ObjectData.new("platform", Vector2(540, 1839))
	current_level.add_object(plt)

	# Add default win area
	var win := ObjectData.new("win_area", Vector2(571, -627))
	current_level.add_object(win)

	var target_path = "res://Levels/%s.tres" % new_id
	load_level(current_level, target_path)

func load_level(lvl: LevelData, path: String) -> void:
	current_level = lvl
	current_level_path = path
	LevelManager.active_level_path = path
	LevelManager.current_level_data = lvl
	canvas.set_level_data(lvl)

	level_id_edit.text = lvl.level_id
	level_name_edit.text = lvl.level_name

	# Select world theme in option button
	var theme_idx = world_theme_keys.find(lvl.world_theme)
	if theme_idx != -1:
		world_theme_opt.select(theme_idx)
	else:
		world_theme_opt.select(0)

	var theme_info = WorldThemeRegistry.get_theme(lvl.world_theme)
	var def_atlas: Vector2i = theme_info.get("default_atlas_coords", Vector2i(1, 1))
	set_tile_atlas(def_atlas.x, def_atlas.y)

	width_spin.value = lvl.level_size.x
	height_spin.value = lvl.level_size.y
	player_x_spin.value = lvl.player_start.x
	player_y_spin.value = lvl.player_start.y

	populate_level_selector()
	on_object_selected(null)
	call_deferred("center_view_on_player")

func center_view_on_player() -> void:
	if not current_level or not scroll_container or not canvas:
		return
	var target_c_y = canvas.world_to_canvas(current_level.player_start).y
	var scroll_val = int(target_c_y - scroll_container.size.y / 2.0)
	scroll_container.scroll_vertical = max(0, scroll_val)

func on_object_selected(obj: ObjectData) -> void:
	if not obj:
		type_label.text = "None Selected"
		pos_x_spin.editable = false
		pos_y_spin.editable = false
		rot_spin.editable = false
		scale_x_spin.editable = false
		scale_y_spin.editable = false
		prop_speed_row.visible = false
		prop_move_speed_row.visible = false
		prop_move_dist_row.visible = false
		prop_move_dir_row.visible = false
		apply_btn.disabled = true
		delete_btn.disabled = true
		duplicate_btn.disabled = true
		return

	type_label.text = obj.object_id
	pos_x_spin.editable = true
	pos_y_spin.editable = true
	rot_spin.editable = true
	scale_x_spin.editable = true
	scale_y_spin.editable = true
	apply_btn.disabled = false
	delete_btn.disabled = false
	duplicate_btn.disabled = false

	update_inspector_values(obj)

func update_inspector_values(obj: ObjectData) -> void:
	if not obj:
		return
	pos_x_spin.value = obj.position.x
	pos_y_spin.value = obj.position.y
	rot_spin.value = obj.rotation
	scale_x_spin.value = obj.scale.x
	scale_y_spin.value = obj.scale.y

	if obj.properties.has("rotation_speed"):
		prop_speed_row.visible = true
		rot_speed_spin.value = obj.properties["rotation_speed"]
	else:
		prop_speed_row.visible = false

	if obj.properties.has("move_speed"):
		prop_move_speed_row.visible = true
		move_speed_spin.value = obj.properties["move_speed"]
	else:
		prop_move_speed_row.visible = false

	if obj.properties.has("move_distance"):
		prop_move_dist_row.visible = true
		move_dist_spin.value = obj.properties["move_distance"]
	else:
		prop_move_dist_row.visible = false

	if obj.properties.has("move_direction") or obj.properties.has("move_distance"):
		prop_move_dir_row.visible = true
		var dir = obj.properties.get("move_direction", "X")
		move_dir_opt.select(1 if dir == "Y" else 0)
	else:
		prop_move_dir_row.visible = false

func apply_inspector_changes() -> void:
	if not canvas.selected_object:
		return
	var obj = canvas.selected_object
	obj.position = Vector2(pos_x_spin.value, pos_y_spin.value)
	obj.rotation = rot_spin.value
	obj.scale = Vector2(scale_x_spin.value, scale_y_spin.value)

	if prop_speed_row.visible:
		obj.properties["rotation_speed"] = rot_speed_spin.value
	if prop_move_speed_row.visible:
		obj.properties["move_speed"] = move_speed_spin.value
	if prop_move_dist_row.visible:
		obj.properties["move_distance"] = move_dist_spin.value
	if prop_move_dir_row.visible:
		var selected_id = move_dir_opt.get_selected_id()
		obj.properties["move_direction"] = "Y" if selected_id == 1 else "X"

	canvas.refresh_canvas()

func on_player_start_changed(pos: Vector2) -> void:
	player_x_spin.value = pos.x
	player_y_spin.value = pos.y

func delete_selected() -> void:
	if canvas.selected_object and current_level:
		current_level.remove_object(canvas.selected_object)
		canvas.selected_object = null
		canvas.refresh_canvas()
		on_object_selected(null)

func duplicate_selected() -> void:
	if canvas.selected_object and current_level:
		var dup = canvas.selected_object.duplicate_data()
		dup.position += Vector2(40, 40)
		current_level.add_object(dup)
		canvas.selected_object = dup
		canvas.refresh_canvas()
		on_object_selected(dup)

func on_save_pressed() -> void:
	if current_level_path != "":
		save_level_to_file(current_level_path)
	else:
		save_dialog.popup_centered()

func save_level_to_file(path: String) -> void:
	if current_level:
		LevelManager.save_level_data(current_level, path)
		current_level_path = path
		populate_level_selector()

func on_load_pressed() -> void:
	load_dialog.popup_centered()

func load_level_from_file(path: String) -> void:
	var loaded = LevelManager.load_level_data(path)
	if loaded:
		load_level(loaded, path)

func on_play_pressed() -> void:
	if current_level and current_level_path != "":
		save_level_to_file(current_level_path)
		LevelManager.set_active_level_path(current_level_path)
		LevelManager.current_level_data = current_level
	elif current_level:
		on_save_pressed()
		LevelManager.set_active_level_path(current_level_path)
		LevelManager.current_level_data = current_level

	if Engine.is_editor_hint():
		EditorInterface.play_main_scene()
	else:
		get_tree().change_scene_to_file("res://Scenes/game_play.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var ke := event as InputEventKey
		if ke.keycode == KEY_DELETE or ke.keycode == KEY_BACKSPACE:
			delete_selected()
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_D and ke.ctrl_pressed:
			duplicate_selected()
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_S and ke.ctrl_pressed:
			on_save_pressed()
			get_viewport().set_input_as_handled()
