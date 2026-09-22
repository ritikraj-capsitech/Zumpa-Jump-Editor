@tool
extends Node2D
class_name FallingStoneTrap

@export var trigger_distance_y: float = 300.0
@export var fall_speed: float = 600.0
@export var trigger_width: float = 200.0

@onready var stone: FallingStone = $FallingStone if has_node("FallingStone") else null
@onready var trigger_zone: TriggerArea = $TriggerArea if has_node("TriggerArea") else null

func _ready() -> void:
	update_components()

func update_components() -> void:
	if trigger_zone:
		trigger_zone.position = Vector2(0, trigger_distance_y)
		trigger_zone.area_width = trigger_width
		trigger_zone.area_height = 100.0
		trigger_zone.update_shape_size()
	if stone:
		stone.fall_speed = fall_speed

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_components()
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2.ZERO, Vector2(0, trigger_distance_y), Color(1.0, 0.4, 0.4, 0.8), 2.0)
