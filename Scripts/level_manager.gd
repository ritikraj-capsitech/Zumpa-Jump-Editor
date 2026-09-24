@tool
class_name LevelManager
extends RefCounted

static var current_level_data: LevelData = null
static var active_level_path: String = "res://Levels/level_001.tres"

static func set_active_level_path(path: String) -> void:
	active_level_path = path
	var f := FileAccess.open("user://active_level_path.txt", FileAccess.WRITE)
	if f:
		f.store_string(path)
		f.close()

static func get_active_level_path() -> String:
	if FileAccess.file_exists("user://active_level_path.txt"):
		var f := FileAccess.open("user://active_level_path.txt", FileAccess.READ)
		if f:
			var saved_path = f.get_as_text().strip_edges()
			f.close()
			if saved_path != "" and (ResourceLoader.exists(saved_path) or FileAccess.file_exists(saved_path)):
				active_level_path = saved_path
				return saved_path
	return active_level_path

static func load_level_data(path: String) -> LevelData:
	if ResourceLoader.exists(path):
		var res = ResourceLoader.load(path)
		if res is LevelData:
			current_level_data = res
			set_active_level_path(path)
			return res

	# Fallback for mobile file paths or direct user:// paths
	if FileAccess.file_exists(path):
		var res = ResourceLoader.load(path)
		if res is LevelData:
			current_level_data = res
			set_active_level_path(path)
			return res

	push_warning("LevelManager: Failed to load level data at path: '%s'" % path)
	return null

static func save_level_data(level_data: LevelData, path: String) -> bool:
	if not level_data:
		return false

	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var err = ResourceSaver.save(level_data, path)
	if err == OK:
		set_active_level_path(path)
		current_level_data = level_data
		return true
	else:
		push_error("LevelManager: Failed to save level to '%s', error code: %d" % [path, err])
		return false

static func get_all_level_paths() -> Array[String]:
	var paths_map: Dictionary = {}

	# 1. Scan res://Levels (handles desktop and exported APK .remap / .import extensions)
	var res_dir_path := "res://Levels"
	if DirAccess.dir_exists_absolute(res_dir_path):
		var dir := DirAccess.open(res_dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					var clean_name = file_name.trim_suffix(".remap").trim_suffix(".import")
					if clean_name.ends_with(".tres"):
						var full_path = res_dir_path + "/" + clean_name
						paths_map[clean_name] = full_path
				file_name = dir.get_next()
			dir.list_dir_end()

	# 2. Scan user://Levels (for custom levels saved at runtime on mobile/desktop)
	var user_dir_path := "user://Levels"
	if DirAccess.dir_exists_absolute(user_dir_path):
		var udir := DirAccess.open(user_dir_path)
		if udir:
			udir.list_dir_begin()
			var file_name = udir.get_next()
			while file_name != "":
				if not udir.current_is_dir():
					var clean_name = file_name.trim_suffix(".remap").trim_suffix(".import")
					if clean_name.ends_with(".tres"):
						var full_path = user_dir_path + "/" + clean_name
						paths_map[clean_name] = full_path
				file_name = udir.get_next()
			udir.list_dir_end()

	var result: Array[String] = []
	for key in paths_map:
		result.append(paths_map[key])

	result.sort_custom(func(a, b): return a.get_file() < b.get_file())

	if result.size() == 0:
		ensure_default_level_files()
		return get_all_level_paths()

	return result

static func ensure_default_level_files() -> void:
	var user_dir := "user://Levels"
	if not DirAccess.dir_exists_absolute(user_dir):
		DirAccess.make_dir_recursive_absolute(user_dir)

	var p1 = user_dir + "/level_001.tres"
	if not ResourceLoader.exists(p1) and not FileAccess.file_exists(p1):
		save_level_data(create_default_level_1(), p1)

	var p2 = user_dir + "/level_002.tres"
	if not ResourceLoader.exists(p2) and not FileAccess.file_exists(p2):
		save_level_data(create_default_level_2(), p2)

	var p3 = user_dir + "/level_003.tres"
	if not ResourceLoader.exists(p3) and not FileAccess.file_exists(p3):
		save_level_data(create_default_level_3(), p3)

static func get_next_level_path(current_path: String = "") -> String:
	if current_path == "":
		current_path = get_active_level_path()

	var all_levels = get_all_level_paths()
	var current_file = current_path.get_file()

	for i in range(all_levels.size()):
		if all_levels[i].get_file() == current_file:
			if i + 1 < all_levels.size():
				return all_levels[i + 1]
			break

	return ""

static func load_next_level() -> LevelData:
	var next_path = get_next_level_path(get_active_level_path())
	if next_path != "":
		return load_level_data(next_path)
	return null

static func get_default_level() -> LevelData:
	var active_path = get_active_level_path()
	if active_path != "" and ResourceLoader.exists(active_path):
		var loaded = load_level_data(active_path)
		if loaded:
			return loaded

	var all_paths = get_all_level_paths()
	if all_paths.size() > 0:
		var loaded = load_level_data(all_paths[0])
		if loaded:
			return loaded

	return create_default_level_1()

static func ensure_default_levels() -> void:
	ensure_default_level_files()

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
		lvl.add_packed_tile(cell_x, 24, ax, 1)
		lvl.add_packed_tile(cell_x, 25, 1, 2)

	# Stepping platforms
	for cell_x in range(3, 9):
		var ax = 1
		if cell_x == 3: ax = 0
		elif cell_x == 8: ax = 2
		lvl.add_packed_tile(cell_x, 18, ax, 1)

	for cell_x in range(13, 19):
		var ax = 1
		if cell_x == 13: ax = 0
		elif cell_x == 18: ax = 2
		lvl.add_packed_tile(cell_x, 14, ax, 1)

	for cell_x in range(7, 15):
		var ax = 1
		if cell_x == 7: ax = 0
		elif cell_x == 14: ax = 2
		lvl.add_packed_tile(cell_x, 9, ax, 1)

	for cell_x in range(4, 10):
		var ax = 1
		if cell_x == 4: ax = 0
		elif cell_x == 9: ax = 2
		lvl.add_packed_tile(cell_x, 3, ax, 1)

	# Top goal platform
	for cell_x in range(6, 17):
		var ax = 1
		if cell_x == 6: ax = 0
		elif cell_x == 16: ax = 2
		lvl.add_packed_tile(cell_x, -5, ax, 1)

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

	for cell_x in range(5, 18):
		lvl.add_packed_tile(cell_x, 25, 7, 1)

	var obs1 := ObjectData.new("obs_1", Vector2(300, 800), 0.0, Vector2(1, 1), {"rotation_speed": 2.5})
	lvl.add_object(obs1)

	var obs2 := ObjectData.new("obs_2", Vector2(540, 100), 0.0, Vector2(1, 1), {"rotation_speed": 2.0, "move_speed": 120.0, "move_distance": 250.0})
	lvl.add_object(obs2)

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

	for cell_x in range(4, 19):
		lvl.add_packed_tile(cell_x, 25, 11, 1)

	var obs2 := ObjectData.new("obs_2", Vector2(369, 204), 0.0, Vector2(1, 1), {"rotation_speed": 2.0, "move_speed": 100.0, "move_distance": 200.0})
	lvl.add_object(obs2)

	var obs1 := ObjectData.new("obs_1", Vector2(569, 684), 0.0, Vector2(1, 1), {"rotation_speed": 2.0})
	lvl.add_object(obs1)

	var win := ObjectData.new("win_area", Vector2(571, -627), 0.0, Vector2(1, 1))
	lvl.add_object(win)

	return lvl


static func bake_level_to_tscn(lvl_data: LevelData, save_path: String) -> Error:
	if not lvl_data:
		return ERR_INVALID_DATA

	var temp_root := Node2D.new()
	temp_root.name = "LevelRoot"

	# Build level nodes dynamically
	LevelLoader.load_level(lvl_data, temp_root)

	# Set owner recursively so PackedScene includes all child nodes & TileMap
	set_node_owner_recursive(temp_root, temp_root)

	# Pack into scene and save .tscn
	var packed_scene := PackedScene.new()
	var err = packed_scene.pack(temp_root)
	if err == OK:
		var dir_path = save_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)
		err = ResourceSaver.save(packed_scene, save_path)
		print("LevelManager: Successfully baked scene to '%s'" % save_path)
	else:
		push_error("LevelManager: Failed to pack level scene: %d" % err)

	temp_root.free()
	return err

static func set_node_owner_recursive(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		if child.owner == null:
			child.owner = root_node
			set_node_owner_recursive(child, root_node)


static func bake_level_to_res(lvl_data: LevelData, save_path: String) -> Error:
	if not lvl_data:
		return ERR_INVALID_DATA
	var dir_path = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var err = ResourceSaver.save(lvl_data, save_path, ResourceSaver.FLAG_COMPRESS)
	if err == OK:
		print("LevelManager: Successfully exported binary .res to '%s'" % save_path)
	else:
		push_error("LevelManager: Failed to save binary .res to '%s', error: %d" % [save_path, err])
	return err


static func bake_all_levels_to_tscn() -> void:
	var paths = get_all_level_paths()
	for p in paths:
		var lvl = load_level_data(p)
		if lvl:
			var tscn_p = p.get_basename() + ".tscn"
			bake_level_to_tscn(lvl, tscn_p)


