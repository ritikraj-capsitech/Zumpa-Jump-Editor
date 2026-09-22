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
		"default_properties": {"rotation_speed": 2.0, "move_speed": 100.0, "move_distance": 200.0, "move_direction": "X"},
		"default_scale": Vector2(1, 1)
	},
	"spike": {
		"id": "spike",
		"name": "Spike Trap",
		"scene_path": "res://Obstacle/spike.tscn",
		"category": "Obstacles",
		"default_properties": {"rotation_speed": 0.0},
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
	},
	"falling_stone": {
		"id": "falling_stone",
		"name": "Falling Stone",
		"scene_path": "res://Obstacle/falling_stone.tscn",
		"category": "Obstacles",
		"default_properties": {"trigger_tag": "trap_1", "fall_speed": 600.0, "rotation_speed": 4.0},
		"default_scale": Vector2(1, 1)
	},
	"trigger_area": {
		"id": "trigger_area",
		"name": "Trigger Area",
		"scene_path": "res://Obstacle/trigger_area.tscn",
		"category": "Triggers",
		"default_properties": {"trigger_tag": "trap_1", "area_width": 200.0, "area_height": 150.0},
		"default_scale": Vector2(1, 1)
	},
	"falling_stone_trap": {
		"id": "falling_stone_trap",
		"name": "Falling Stone Trap",
		"scene_path": "res://Obstacle/falling_stone_trap.tscn",
		"category": "Obstacles",
		"default_properties": {"trigger_distance_y": 300.0, "fall_speed": 600.0, "trigger_width": 200.0},
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
