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
@onready var apply_btn: Button = %ApplyBtn

# Bottom Bar
@onready var level_id_edit: LineEdit = %LevelIDEdit
@onready var level_name_edit: LineEdit = %LevelNameEdit
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

func _ready() -> void:
	setup_grid_options()
	setup_palette()
	connect_signals()
	populate_level_selector()

	# Load initial default level
	var loaded = LevelManager.get_default_level()
	if loaded:
		load_level(loaded, LevelManager.active_level_path)
	else:
		new_level()

func setup_grid_options() -> void:
	grid_size_opt.clear()
	grid_size_opt.add_item("16 px", 16)
	grid_size_opt.add_item("32 px", 32)
	grid_size_opt.add_item("64 px", 64)
	grid_size_opt.add_item("128 px", 128)
	grid_size_opt.select(1) # 32px default

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
		btn.pressed.connect(func(): set_active_tool(id, btn))
		palette_container.add_child(btn)
		tool_buttons[id] = btn

func populate_level_selector() -> void:
	level_select_opt.clear()
	level_paths_list = LevelManager.get_all_level_paths()

	var selected_idx = 0
	for i in range(level_paths_list.size()):
		var path = level_paths_list[i]
		var file_name = path.get_file()
		level_select_opt.add_item(file_name, i)
		if path == current_level_path:
			selected_idx = i

	if level_paths_list.size() > 0:
		level_select_opt.select(selected_idx)

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

	# Bottom bar edits
	level_id_edit.text_changed.connect(func(t): if current_level: current_level.level_id = t)
	level_name_edit.text_changed.connect(func(t): if current_level: current_level.level_name = t)
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

func on_level_selected_from_opt(idx: int) -> void:
	if idx >= 0 and idx < level_paths_list.size():
		var path = level_paths_list[idx]
		var loaded = LevelManager.load_level_data(path)
		if loaded:
			load_level(loaded, path)

func new_level() -> void:
	var existing = LevelManager.get_all_level_paths()
	var new_num = existing.size() + 1
	var new_id = "level_%03d" % new_num

	current_level = LevelData.new()
	current_level.level_id = new_id
	current_level.level_name = "Level %d" % new_num
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
	on_save_pressed()
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
