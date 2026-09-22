extends Area2D
class_name Spike

@export var rotation_speed: float = 0.0

func _ready() -> void:
	add_to_group("obstacle")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if rotation_speed != 0.0:
		rotation += rotation_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body.has_method("game_over"):
		if body.has_method("game_over"):
			body.game_over()
