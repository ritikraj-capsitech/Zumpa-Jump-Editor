@tool
class_name AtlasPalettePicker
extends Control

signal tile_selected(coords: Vector2i)

@export var tile_size: Vector2i = Vector2i(16, 16)

var texture: Texture2D = null:
	set(val):
		texture = val
		_update_picker_size()
		queue_redraw()

var selected_coords: Vector2i = Vector2i(1, 1):
	set(val):
		selected_coords = val
		queue_redraw()

var hover_coords: Vector2i = Vector2i(-1, -1):
	set(val):
		if hover_coords != val:
			hover_coords = val
			queue_redraw()

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	clip_contents = true
	mouse_exited.connect(func(): hover_coords = Vector2i(-1, -1))
	_update_picker_size()

func _get_cols() -> int:
	if not texture or tile_size.x <= 0:
		return 1
	return max(1, int(texture.get_width() / tile_size.x))

func _get_rows() -> int:
	if not texture or tile_size.y <= 0:
		return 1
	return max(1, int(texture.get_height() / tile_size.y))

func _update_picker_size() -> void:
	var width = size.x
	if width <= 0:
		width = custom_minimum_size.x if custom_minimum_size.x > 0 else 230.0
	if not texture:
		custom_minimum_size = Vector2(0, 120)
		return
	var cols = _get_cols()
	var rows = _get_rows()
	var cell_w = width / float(cols)
	var target_h = max(60.0, rows * cell_w)
	if custom_minimum_size.y != target_h:
		custom_minimum_size = Vector2(0, target_h)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_picker_size()
		queue_redraw()

func _draw() -> void:
	var width = size.x
	if width <= 0:
		width = 230.0

	var cols = _get_cols()
	var rows = _get_rows()
	var cell_w = width / float(cols)
	var draw_height = rows * cell_w

	# 1. Draw background panel
	draw_rect(Rect2(0, 0, width, draw_height), Color(0.1, 0.1, 0.12, 1.0), true)

	if not texture:
		draw_string(ThemeDB.fallback_font, Vector2(10, 30), "No Tile Map Image", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
		return

	# 2. Draw full atlas sheet texture
	draw_texture_rect(texture, Rect2(0, 0, width, draw_height), false)

	# 3. Draw grid lines between tiles
	var grid_color := Color(1.0, 1.0, 1.0, 0.2)
	for c in range(cols + 1):
		var x = c * cell_w
		draw_line(Vector2(x, 0), Vector2(x, draw_height), grid_color, 1.0)
	for r in range(rows + 1):
		var y = r * cell_w
		draw_line(Vector2(0, y), Vector2(width, y), grid_color, 1.0)

	# 4. Draw hover indicator
	if hover_coords.x >= 0 and hover_coords.x < cols and hover_coords.y >= 0 and hover_coords.y < rows:
		var hover_rect := Rect2(hover_coords.x * cell_w, hover_coords.y * cell_w, cell_w, cell_w)
		draw_rect(hover_rect, Color(1.0, 1.0, 1.0, 0.25), true)
		draw_rect(hover_rect, Color(1.0, 1.0, 1.0, 0.7), false, 1.5)

	# 5. Draw selection box around currently selected tile
	if selected_coords.x >= 0 and selected_coords.x < cols and selected_coords.y >= 0 and selected_coords.y < rows:
		var sel_rect := Rect2(selected_coords.x * cell_w, selected_coords.y * cell_w, cell_w, cell_w)
		draw_rect(sel_rect, Color(1.0, 0.85, 0.0, 0.35), true)
		draw_rect(sel_rect, Color(1.0, 0.9, 0.0, 1.0), false, 2.5)

func _gui_input(event: InputEvent) -> void:
	if not texture:
		return

	var cols = _get_cols()
	var rows = _get_rows()
	var width = size.x
	if width <= 0:
		width = 230.0
	var cell_w = width / float(cols)

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var col = clamp(int(mm.position.x / cell_w), 0, cols - 1)
		var row = clamp(int(mm.position.y / cell_w), 0, rows - 1)
		hover_coords = Vector2i(col, row)

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var col = clamp(int(mb.position.x / cell_w), 0, cols - 1)
			var row = clamp(int(mb.position.y / cell_w), 0, rows - 1)
			selected_coords = Vector2i(col, row)
			emit_signal("tile_selected", selected_coords)
