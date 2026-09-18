@tool
extends Resource
class_name LevelData

@export var level_id: String = "level_001"
@export var level_name: String = "Level 1"
@export var player_start: Vector2 = Vector2(529, 1135)
@export var level_size: Vector2 = Vector2(1080, 2500)
@export var objects: Array[ObjectData] = []

func add_object(obj_data: ObjectData) -> void:
	objects.append(obj_data)

func remove_object(obj_data: ObjectData) -> void:
	objects.erase(obj_data)

func clear_objects() -> void:
	objects.clear()
