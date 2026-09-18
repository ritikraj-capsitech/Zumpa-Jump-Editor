#extends StaticBody2D
#
#@export var rotation_speed: float = 2.0
#
#func _physics_process(delta: float) -> void:
	#rotation += rotation_speed * delta
#
#extends StaticBody2D
#
#@export var rotation_speed: float = 2.0
#
#func _ready() -> void:
	#$HitArea.body_entered.connect(_on_hit_area_body_entered)
#
#func _physics_process(delta: float) -> void:
	#rotation += rotation_speed * delta
#
#func _on_hit_area_body_entered(body: Node2D) -> void:
	#if body is CharacterBody2D:
		#print("GAME OVER!")
		#show_restart_button()
#
#func show_restart_button() -> void:
	#var button := Button.new()
#
	#button.text = "RESTART LEVEL"
	#button.position = Vector2(500, 300)
	#button.size = Vector2(200, 60)
	#button.process_mode = Node.PROCESS_MODE_ALWAYS
#
	#get_tree().current_scene.add_child(button)
#
	#button.pressed.connect(_restart_level)
#
	#get_tree().paused = true
#
#func _restart_level() -> void:
	#get_tree().paused = false
	#get_tree().reload_current_scene()

extends StaticBody2D

@export var rotation_speed: float = 2.0

func _physics_process(delta: float) -> void:
	rotation += rotation_speed * delta
