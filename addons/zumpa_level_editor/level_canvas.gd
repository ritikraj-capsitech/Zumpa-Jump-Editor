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
var active_placement_id: String = "" # "" for select mode, "player_start" or object_id

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var preview_nodes: Dictionary = {} # ObjectData -> Node2D
var player_start_preview: Node2D = null

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

	if not level_data:
		update_canvas_size()
		queue_redraw()
		return

	update_canvas_size()

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

func _gui_input(event: InputEvent) -> void:
	if not level_data:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var c_pos = mb.position
				var w_pos = canvas_to_world(c_pos)

				if active_placement_id == "player_start":
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

	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		if selected_object:
			var w_pos = canvas_to_world(mm.position) + drag_offset
			selected_object.position = snap_pos(w_pos)

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

	# Fill portrait playable corridor with subtle tint
	draw_rect(Rect2(Vector2(left_c_x, top_c_y), Vector2(1080, bot_c_y - top_c_y)), Color(0.1, 0.1, 0.2, 0.15))

	# Boundary side lines
	draw_line(Vector2(left_c_x, top_c_y), Vector2(left_c_x, bot_c_y), Color(0.2, 0.8, 1.0, 0.8), 3.0)
	draw_line(Vector2(right_c_x, top_c_y), Vector2(right_c_x, bot_c_y), Color(0.2, 0.8, 1.0, 0.8), 3.0)
	draw_line(Vector2(left_c_x, top_c_y), Vector2(right_c_x, top_c_y), Color(1.0, 0.3, 0.3, 0.8), 3.0) # Top Goal boundary
	draw_line(Vector2(left_c_x, bot_c_y), Vector2(right_c_x, bot_c_y), Color(1.0, 0.8, 0.2, 0.8), 3.0) # Bottom threshold boundary

	# Draw Grid Overlay if enabled
	if grid_snap and grid_size > 0:
		var g_color := Color(1.0, 1.0, 1.0, 0.08)
		var start_x = int(left_c_x)
		var end_x = int(right_c_x)
		for x in range(start_x, end_x + 1, grid_size):
			draw_line(Vector2(x, top_c_y), Vector2(x, bot_c_y), g_color, 1.0)
		for y in range(int(top_c_y), int(bot_c_y) + 1, grid_size):
			draw_line(Vector2(left_c_x, y), Vector2(right_c_x, y), g_color, 1.0)

	# Draw Selection Outline around selected object
	if selected_object and preview_nodes.has(selected_object):
		var node = preview_nodes[selected_object]
		var n_pos = node.position
		var box_size = Vector2(120, 120) * selected_object.scale
		var rect := Rect2(n_pos - box_size / 2.0, box_size)
		draw_rect(rect, Color(1.0, 0.9, 0.1, 0.9), false, 2.5)
