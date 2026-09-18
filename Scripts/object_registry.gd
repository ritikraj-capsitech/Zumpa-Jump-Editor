@tool
class_name ObjectRegistry

static var _registry: Dictionary = {
	"obs_1": {
		"id": "obs_1",
		"name": "Rotating Obstacle 1",
		"scene_path": "res://Obstacle/obs_1.tscn",
		"category": "Obstacles",
		"default_properties": {"rotation_speed": 2.0},
		"default_scale": Vector2(1, 1)
	},
	"obs_2": {
		"id": "obs_2",
		"name": "Moving & Rotating Obstacle 2",
		"scene_path": "res://Obstacle/obs_2.tscn",
		"category": "Obstacles",
		"default_properties": {"rotation_speed": 2.0, "move_speed": 100.0, "move_distance": 200.0},
		"default_scale": Vector2(1, 1)
	},
	"platform": {
		"id": "platform",
		"name": "Ground Platform",
		"scene_path": "res://Obstacle/platform.tscn",
		"category": "Platforms",
		"default_properties": {},
		"default_scale": Vector2(1, 1)
	},
	"win_area": {
		"id": "win_area",
		"name": "Win Area",
		"scene_path": "res://Scenes/win_area_node.tscn",
		"category": "Triggers",
		"default_properties": {},
		"default_scale": Vector2(1, 1)
	},
	"wall": {
		"id": "wall",
		"name": "Wall",
		"scene_path": "res://Walls/Wall.tscn",
		"category": "Walls",
		"default_properties": {},
		"default_scale": Vector2(1, 1)
	}
}

static func register_object(id: String, display_name: String, scene_path: String, category: String = "Obstacles", default_properties: Dictionary = {}, default_scale: Vector2 = Vector2.ONE) -> void:
	_registry[id] = {
		"id": id,
		"name": display_name,
		"scene_path": scene_path,
		"category": category,
		"default_properties": default_properties,
		"default_scale": default_scale
	}

static func get_all_entries() -> Dictionary:
	return _registry

static func get_entry(id: String) -> Dictionary:
	return _registry.get(id, {})

static func instantiate_object(id: String) -> Node2D:
	var entry = get_entry(id)
	if entry.is_empty() or not entry.has("scene_path"):
		push_error("ObjectRegistry: Unknown object ID '%s'" % id)
		return null
	var path: String = entry["scene_path"]
	if not ResourceLoader.exists(path):
		push_error("ObjectRegistry: Scene path '%s' does not exist" % path)
		return null
	var packed: PackedScene = load(path)
	if packed:
		return packed.instantiate() as Node2D
	return null
