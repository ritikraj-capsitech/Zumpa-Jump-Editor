extends StaticBody2D

@export var rotation_speed: float = 2.0
@export var move_speed: float = 100.0
@export var move_distance: float = 200.0
@export_enum("X", "Y") var move_direction: String = "X"

var start_pos: Vector2

func _ready() -> void:
	start_pos = position
	add_to_group("obstacle")

func _physics_process(delta: float) -> void:
	# Rotate on its own axis
	rotation += rotation_speed * delta

	# Move back and forth in X or Y direction based on move_direction property
	if move_distance > 0.0:
		var offset = sin(Time.get_ticks_msec() / 1000.0 * (move_speed / 50.0)) * move_distance
		if move_direction == "Y":
			position.x = start_pos.x
			position.y = start_pos.y + offset
		else:
			position.y = start_pos.y
			position.x = start_pos.x + offset
