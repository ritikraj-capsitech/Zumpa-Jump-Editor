@tool
class_name LevelManager
extends RefCounted

static var current_level_data: LevelData = null
static var active_level_path: String = "res://Levels/level_001.tres"

static func load_level_data(path: String) -> LevelData:
	if ResourceLoader.exists(path):
		var res = ResourceLoader.load(path)
		if res is LevelData:
			current_level_data = res
			active_level_path = path
			return res
	push_warning("LevelManager: Failed to load level data at path: '%s'" % path)
	return null

static func save_level_data(level_data: LevelData, path: String) -> bool:
	if not level_data:
		return false

	# Ensure directory exists
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var err = ResourceSaver.save(level_data, path)
	if err == OK:
		active_level_path = path
		current_level_data = level_data
		return true
	else:
		push_error("LevelManager: Failed to save level to '%s', error code: %d" % [path, err])
		return false

static func get_all_level_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir_path := "res://Levels"

	if DirAccess.dir_exists_absolute(dir_path):
		var dir := DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".tres"):
					paths.append(dir_path + "/" + file_name)
				file_name = dir.get_next()
			dir.list_dir_end()

	paths.sort()
	return paths

static func get_next_level_path(current_path: String = "") -> String:
	if current_path == "":
		current_path = active_level_path

	var all_levels = get_all_level_paths()
	var current_idx = all_levels.find(current_path)

	if current_idx != -1 and current_idx + 1 < all_levels.size():
		return all_levels[current_idx + 1]

	return ""

static func load_next_level() -> LevelData:
	var next_path = get_next_level_path(active_level_path)
	if next_path != "":
		return load_level_data(next_path)
	return null

static func get_default_level() -> LevelData:
	if current_level_data:
		return current_level_data
	var all_paths = get_all_level_paths()
	if all_paths.size() > 0:
		var loaded = load_level_data(all_paths[0])
		if loaded:
			return loaded
	return create_default_level_1()

static func ensure_default_levels() -> void:
	# Retained for API compatibility without auto-saving to disk
	var dir_path := "res://Levels"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

static func create_default_level_1() -> LevelData:
	var lvl := LevelData.new()
	lvl.level_id = "level_001"
	lvl.level_name = "Level 1 - Forest Hills"
	lvl.world_theme = "world_1"
	lvl.player_start = Vector2(529, 1100)
	lvl.level_size = Vector2(1080, 3000)

	# Bottom ground
	for cell_x in range(5, 18):
		var ax = 1
		if cell_x == 4: ax = 0
		elif cell_x == 18: ax = 2
		lvl.tile_data.append({"x": cell_x, "y": 24, "source_id": 0, "atlas_x": ax, "atlas_y": 1})
		lvl.tile_data.append({"x": cell_x, "y": 25, "source_id": 0, "atlas_x": 1, "atlas_y": 2})

	# Stepping platforms
	for cell_x in range(3, 9):
		var ax = 1
		if cell_x == 3: ax = 0
		elif cell_x == 8: ax = 2
		lvl.tile_data.append({"x": cell_x, "y": 18, "source_id": 0, "atlas_x": ax, "atlas_y": 1})

	for cell_x in range(13, 19):
		var ax = 1
		if cell_x == 13: ax = 0
		elif cell_x == 18: ax = 2
		lvl.tile_data.append({"x": cell_x, "y": 14, "source_id": 0, "atlas_x": ax, "atlas_y": 1})

	for cell_x in range(7, 15):
		var ax = 1
		if cell_x == 7: ax = 0
		elif cell_x == 14: ax = 2
		lvl.tile_data.append({"x": cell_x, "y": 9, "source_id": 0, "atlas_x": ax, "atlas_y": 1})

	for cell_x in range(4, 10):
		var ax = 1
		if cell_x == 4: ax = 0
		elif cell_x == 9: ax = 2
		lvl.tile_data.append({"x": cell_x, "y": 3, "source_id": 0, "atlas_x": ax, "atlas_y": 1})

	# Top goal platform
	for cell_x in range(6, 17):
		var ax = 1
		if cell_x == 6: ax = 0
		elif cell_x == 16: ax = 2
		lvl.tile_data.append({"x": cell_x, "y": -5, "source_id": 0, "atlas_x": ax, "atlas_y": 1})

	# Obs1
	var obs := ObjectData.new("obs_1", Vector2(540, 500), 0.0, Vector2(1, 1), {"rotation_speed": 2.0})
	lvl.add_object(obs)

	# WinArea
	var win := ObjectData.new("win_area", Vector2(540, -550), 0.0, Vector2(1, 1))
	lvl.add_object(win)

	return lvl

static func create_default_level_2() -> LevelData:
	var lvl := LevelData.new()
	lvl.level_id = "level_002"
	lvl.level_name = "Level 2 - Desert Challenge"
	lvl.world_theme = "world_2"
	lvl.player_start = Vector2(529, 1135)
	lvl.level_size = Vector2(1080, 3500)

	# Pre-built TileMap Ground Platform
	for cell_x in range(5, 18):
		lvl.tile_data.append({"x": cell_x, "y": 25, "source_id": 0, "atlas_x": 7, "atlas_y": 1})

	# Obs1 (Rotating)
	var obs1 := ObjectData.new("obs_1", Vector2(300, 800), 0.0, Vector2(1, 1), {"rotation_speed": 2.5})
	lvl.add_object(obs1)

	# Obs2 (Moving & Rotating Obstacle)
	var obs2 := ObjectData.new("obs_2", Vector2(540, 100), 0.0, Vector2(1, 1), {"rotation_speed": 2.0, "move_speed": 120.0, "move_distance": 250.0})
	lvl.add_object(obs2)

	# WinArea
	var win := ObjectData.new("win_area", Vector2(571, -800), 0.0, Vector2(1, 1))
	lvl.add_object(win)

	return lvl

static func create_default_level_3() -> LevelData:
	var lvl := LevelData.new()
	lvl.level_id = "level_003"
	lvl.level_name = "Level 3 - Cyber Zone"
	lvl.world_theme = "world_3"
	lvl.player_start = Vector2(529, 1135)
	lvl.level_size = Vector2(1080, 3500)

	# Pre-built TileMap Ground Platform
	for cell_x in range(4, 19):
		lvl.tile_data.append({"x": cell_x, "y": 25, "source_id": 0, "atlas_x": 11, "atlas_y": 1})

	# Obs2 (Moving & Rotating Obstacle)
	var obs2 := ObjectData.new("obs_2", Vector2(369, 204), 0.0, Vector2(1, 1), {"rotation_speed": 2.0, "move_speed": 100.0, "move_distance": 200.0})
	lvl.add_object(obs2)

	# Obs1 (Rotating)
	var obs1 := ObjectData.new("obs_1", Vector2(569, 684), 0.0, Vector2(1, 1), {"rotation_speed": 2.0})
	lvl.add_object(obs1)

	# WinArea
	var win := ObjectData.new("win_area", Vector2(571, -627), 0.0, Vector2(1, 1))
	lvl.add_object(win)

	return lvl
