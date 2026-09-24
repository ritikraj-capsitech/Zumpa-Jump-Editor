@tool
extends Resource
class_name LevelData

@export var level_id: String = "level_001"
@export var level_name: String = "Level 1"
@export var world_theme: String = "world_1"
@export var player_start: Vector2 = Vector2(529, 1135)
@export var level_size: Vector2 = Vector2(1080, 2500)

@export var camera_drag_horizontal_enabled: bool = true
@export var camera_drag_vertical_enabled: bool = true
@export var camera_drag_horizontal_offset: float = 0.0
@export var camera_drag_vertical_offset: float = 0.0
@export var camera_drag_left_margin: float = 0.8
@export var camera_drag_top_margin: float = 0.6
@export var camera_drag_right_margin: float = 0.8
@export var camera_drag_bottom_margin: float = 0.2

@export var objects: Array[ObjectData] = []
@export var tile_data: Array[Dictionary] = []


func add_object(obj_data: ObjectData) -> void:
	objects.append(obj_data)

func remove_object(obj_data: ObjectData) -> void:
	objects.erase(obj_data)

func clear_objects() -> void:
	objects.clear()
