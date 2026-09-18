@tool
extends Control

signal object_selected(obj_data: ObjectData)
signal object_moved(obj_data: ObjectData)
signal player_start_changed(pos: Vector2)
signal level_data_modified()

@export var grid_snap: bool = false
@export var grid_size: int = 32

var level_data: LevelData = null
var selected_object: ObjectData = null
var active_placement_id: String = "" # "" for select mode, "player_start", "tile_brush", "tile_eraser", or object_id

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var preview_nodes: Dictionary = {} # ObjectData -> Node2D
var player_start_preview: Node2D = null
var canvas_tilemap: TileMapLayer = null

var current_tile_atlas: Vector2i = Vector2i(1, 1)
var hover_cell: Vector2i = Vector2i(-9999, -9999)

# Canvas offset mapping: World (0,0) is at Canvas (100, 2000)
var origin_offset: Vector2 = Vector2(100, 2000)

func _ready() -> void:
	clip_contents = true

func set_level_data(p_data: LevelData) -> void:
	level_data = p_data
	selected_object = null
	refresh_canvas()

func refresh_canvas() -> void:
	# Clear existing preview nodes
	for child in get_children():
		child.queue_free()
	preview_nodes.clear()
	canvas_tilemap = null

	if not level_data:
		update_canvas_size()
		queue_redraw()
		return

	update_canvas_size()

	var theme_info = WorldThemeRegistry.get_theme(level_data.world_theme)
	var def_atlas: Vector2i = theme_info.get("default_atlas_coords", Vector2i(1, 1))

	# Create TileMapLayer Preview on Canvas
	canvas_tilemap = TileMapLayer.new()
	canvas_tilemap.name = "CanvasTileMap"
	canvas_tilemap.tile_set = WorldThemeRegistry.create_tileset_for_theme(level_data.world_theme)
	canvas_tilemap.position = origin_offset
	canvas_tilemap.scale = Vector2(3.0, 3.0) # 16px * 3 = 48px tile size
	canvas_tilemap.z_index = 2
	add_child(canvas_tilemap)

	# Render saved TileMap cells
	if level_data.tile_data.size() > 0:
		for cell in level_data.tile_data:
			var coords := Vector2i(cell.get("x", 0), cell.get("y", 0))
			var source_id: int = cell.get("source_id", 0)
			var atlas_x: int = cell.get("atlas_x", def_atlas.x)
			var atlas_y: int = cell.get("atlas_y", def_atlas.y)
			canvas_tilemap.set_cell(coords, source_id, Vector2i(atlas_x, atlas_y))

	# Create Player Start Marker preview
	var p_start_node := Node2D.new()
	p_start_node.name = "PlayerStartMarker"
	p_start_node.position = world_to_canvas(level_data.player_start)

	var p_sprite := Sprite2D.new()
	if ResourceLoader.exists("res://Sprite/Player.png"):
		p_sprite.texture = load("res://Sprite/Player.png")
		p_sprite.scale = Vector2(0.1, 0.1)
	p_start_node.add_child(p_sprite)

	var p_label := Label.new()
	p_label.text = "PLAYER START"
	p_label.position = Vector2(-50, -60)
	p_start_node.add_child(p_label)

	add_child(p_start_node)
	player_start_preview = p_start_node

	# Create Object Previews
	for obj_data in level_data.objects:
		var node = ObjectRegistry.instantiate_object(obj_data.object_id)
		if node:
			node.position = world_to_canvas(obj_data.position)
			node.rotation_degrees = obj_data.rotation
			node.scale = obj_data.scale
			add_child(node)
			preview_nodes[obj_data] = node

	queue_redraw()

func update_canvas_size() -> void:
	var h: float = 4000.0
	if level_data:
		h = level_data.level_size.y + 3000.0
	custom_minimum_size = Vector2(1280, h)

func world_to_canvas(w_pos: Vector2) -> Vector2:
	return Vector2(w_pos.x + origin_offset.x, w_pos.y + origin_offset.y)

func canvas_to_world(c_pos: Vector2) -> Vector2:
	return Vector2(c_pos.x - origin_offset.x, c_pos.y - origin_offset.y)

func snap_pos(w_pos: Vector2) -> Vector2:
	if not grid_snap or grid_size <= 0:
		return w_pos
	var sx = snapped(w_pos.x, grid_size)
	var sy = snapped(w_pos.y, grid_size)
	return Vector2(sx, sy)

func place_tile_at(w_pos: Vector2) -> void:
	if not level_data:
		return

	# 48px tile size (16px * 3.0 scale)
	var cell_x = int(floor(w_pos.x / 48.0))
	var cell_y = int(floor(w_pos.y / 48.0))

	# Check if tile already exists at cell
	for i in range(level_data.tile_data.size()):
		var cell = level_data.tile_data[i]
		if cell.get("x", 0) == cell_x and cell.get("y", 0) == cell_y:
			if cell.get("atlas_x", 0) != current_tile_atlas.x or cell.get("atlas_y", 0) != current_tile_atlas.y:
				cell["atlas_x"] = current_tile_atlas.x
				cell["atlas_y"] = current_tile_atlas.y
				refresh_canvas()
				emit_signal("level_data_modified")
			return

	level_data.tile_data.append({
		"x": cell_x,
		"y": cell_y,
		"source_id": 0,
		"atlas_x": current_tile_atlas.x,
		"atlas_y": current_tile_atlas.y
	})
	refresh_canvas()
	emit_signal("level_data_modified")

func erase_tile_at(w_pos: Vector2) -> void:
	if not level_data:
		return
	var cell_x = int(floor(w_pos.x / 48.0))
	var cell_y = int(floor(w_pos.y / 48.0))

	for i in range(level_data.tile_data.size() - 1, -1, -1):
		var cell = level_data.tile_data[i]
		if cell.get("x", 0) == cell_x and cell.get("y", 0) == cell_y:
			level_data.tile_data.remove_at(i)
			refresh_canvas()
			emit_signal("level_data_modified")
			return

func _gui_input(event: InputEvent) -> void:
	if not level_data:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var c_pos = mb.position
				var w_pos = canvas_to_world(c_pos)

				if active_placement_id == "tile_brush":
					place_tile_at(w_pos)
				elif active_placement_id == "tile_eraser":
					erase_tile_at(w_pos)
				elif active_placement_id == "player_start":
					level_data.player_start = snap_pos(w_pos)
					if player_start_preview:
						player_start_preview.position = world_to_canvas(level_data.player_start)
					emit_signal("player_start_changed", level_data.player_start)
					emit_signal("level_data_modified")
					queue_redraw()
				elif active_placement_id != "":
					var new_obj := ObjectData.new(
						active_placement_id,
						snap_pos(w_pos),
						0.0,
						Vector2.ONE,
						ObjectRegistry.get_entry(active_placement_id).get("default_properties", {})
					)
					level_data.add_object(new_obj)
					selected_object = new_obj
					refresh_canvas()
					emit_signal("object_selected", selected_object)
					emit_signal("level_data_modified")
				else:
					# Selection / Move Mode
					var hit_obj = find_object_at_canvas_pos(c_pos)
					if hit_obj:
						selected_object = hit_obj
						is_dragging = true
						drag_offset = hit_obj.position - w_pos
						emit_signal("object_selected", selected_object)
					else:
						selected_object = null
						is_dragging = false
						emit_signal("object_selected", null)
					queue_redraw()
			else:
				if is_dragging:
					is_dragging = false
					emit_signal("level_data_modified")

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var w_pos = canvas_to_world(mb.position)
			erase_tile_at(w_pos)

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var w_pos = canvas_to_world(mm.position)
		hover_cell = Vector2i(int(floor(w_pos.x / 48.0)), int(floor(w_pos.y / 48.0)))

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if active_placement_id == "tile_brush":
				place_tile_at(w_pos)
			elif active_placement_id == "tile_eraser":
				erase_tile_at(w_pos)
			elif is_dragging and selected_object:
				var target_pos = canvas_to_world(mm.position) + drag_offset
				selected_object.position = snap_pos(target_pos)

				if preview_nodes.has(selected_object):
					preview_nodes[selected_object].position = world_to_canvas(selected_object.position)

				emit_signal("object_moved", selected_object)
		
		queue_redraw()

func find_object_at_canvas_pos(c_pos: Vector2) -> ObjectData:
	var w_pos = canvas_to_world(c_pos)
	var best_obj: ObjectData = null
	var min_dist: float = 60.0 # hit radius threshold

	for obj in level_data.objects:
		var dist = obj.position.distance_to(w_pos)
		if dist < min_dist:
			min_dist = dist
			best_obj = obj
	return best_obj

func _draw() -> void:
	if not level_data:
		return

	# Draw Portrait Boundary Guides (0 to 1080 in world X)
	var top_c_y = world_to_canvas(Vector2(0, -level_data.level_size.y)).y
	var bot_c_y = world_to_canvas(Vector2(0, 2000)).y
	var left_c_x = world_to_canvas(Vector2(0, 0)).x
	var right_c_x = world_to_canvas(Vector2(1080, 0)).x

	# Fill portrait playable corridor with subtle theme tint
	var theme_info = WorldThemeRegistry.get_theme(level_data.world_theme)
	var t_color: Color = theme_info.get("theme_color", Color(0.1, 0.1, 0.2, 0.15))
	var fill_color := Color(t_color.r, t_color.g, t_color.b, 0.12)
	draw_rect(Rect2(Vector2(left_c_x, top_c_y), Vector2(1080, bot_c_y - top_c_y)), fill_color)

	# Boundary side lines
	draw_line(Vector2(left_c_x, top_c_y), Vector2(left_c_x, bot_c_y), Color(0.2, 0.8, 1.0, 0.8), 3.0)
	draw_line(Vector2(right_c_x, top_c_y), Vector2(right_c_x, bot_c_y), Color(0.2, 0.8, 1.0, 0.8), 3.0)
	draw_line(Vector2(left_c_x, top_c_y), Vector2(right_c_x, top_c_y), Color(1.0, 0.3, 0.3, 0.8), 3.0) # Top Goal boundary
	draw_line(Vector2(left_c_x, bot_c_y), Vector2(right_c_x, bot_c_y), Color(1.0, 0.8, 0.2, 0.8), 3.0) # Bottom threshold boundary

	# Draw 48px Tile Grid Overlay aligned mathematically with cell coordinates
	var is_tile_tool = (active_placement_id == "tile_brush" or active_placement_id == "tile_eraser")
	if grid_snap or is_tile_tool:
		var tile_step: float = 48.0 if is_tile_tool else float(grid_size)
		var g_color := Color(1.0, 1.0, 1.0, 0.22) if is_tile_tool else Color(1.0, 1.0, 1.0, 0.08)

		var min_cx = int(floor(0.0 / tile_step))
		var max_cx = int(ceil(1080.0 / tile_step))
		for cx in range(min_cx, max_cx + 1):
			var line_c_x = cx * tile_step + origin_offset.x
			draw_line(Vector2(line_c_x, top_c_y), Vector2(line_c_x, bot_c_y), g_color, 1.0)

		var min_cy = int(floor(-level_data.level_size.y / tile_step)) - 1
		var max_cy = int(ceil(2000.0 / tile_step)) + 1
		for cy in range(min_cy, max_cy + 1):
			var line_c_y = cy * tile_step + origin_offset.y
			draw_line(Vector2(left_c_x, line_c_y), Vector2(right_c_x, line_c_y), g_color, 1.0)

	# Draw Tile Brush / Eraser Mouse Cursor Grid Box Highlight
	if is_tile_tool and hover_cell != Vector2i(-9999, -9999):
		var cell_w_pos = Vector2(hover_cell.x * 48.0, hover_cell.y * 48.0)
		var cell_c_pos = world_to_canvas(cell_w_pos)
		var cell_rect := Rect2(cell_c_pos, Vector2(48, 48))

		if active_placement_id == "tile_brush":
			draw_rect(cell_rect, Color(0.2, 1.0, 0.5, 0.35))
			draw_rect(cell_rect, Color(0.2, 1.0, 0.5, 0.9), false, 2.0)
		elif active_placement_id == "tile_eraser":
			draw_rect(cell_rect, Color(1.0, 0.3, 0.3, 0.35))
			draw_rect(cell_rect, Color(1.0, 0.3, 0.3, 0.9), false, 2.0)

	# Draw Selection Outline around selected object
	if selected_object and preview_nodes.has(selected_object):
		var node = preview_nodes[selected_object]
		var n_pos = node.position
		var box_size = Vector2(120, 120) * selected_object.scale
		var rect := Rect2(n_pos - box_size / 2.0, box_size)
		draw_rect(rect, Color(1.0, 0.9, 0.1, 0.9), false, 2.5)
