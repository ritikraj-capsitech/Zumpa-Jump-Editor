extends StaticBody2D

@export var rotation_speed: float = 2.0
@export var move_speed: float = 100.0
@export var move_distance: float = 200.0

var start_x: float


func _ready() -> void:
	start_x = position.x
	add_to_group("obstacle")


func _physics_process(delta: float) -> void:
	# Rotate on its own axis
	rotation += rotation_speed * delta

	# Move left and right
	if move_distance > 0.0:
		position.x = start_x + sin(Time.get_ticks_msec() / 1000.0 * (move_speed / 50.0)) * move_distance
