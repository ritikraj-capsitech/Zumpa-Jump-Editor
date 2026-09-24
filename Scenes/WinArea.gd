#extends Area2D
#
#var result_button: Button
#
#func _ready() -> void:
	#body_entered.connect(_on_body_entered)
#
#func _on_body_entered(body: Node2D) -> void:
	#if body is CharacterBody2D:
		#print("GAME WIN!")
		#show_restart_button()
#
#func show_restart_button() -> void:
	#if result_button:
		#return
#
	#result_button = Button.new()
	#result_button.text = "RESTART LEVEL"
	#result_button.position = Vector2(500, 300)
	#result_button.size = Vector2(200, 60)
	#result_button.process_mode = Node.PROCESS_MODE_ALWAYS
#
	#get_tree().current_scene.add_child(result_button)
#
	#result_button.pressed.connect(_restart_level)
#
	#get_tree().paused = true
#
#func _restart_level() -> void:
	#get_tree().paused = false
	#get_tree().reload_current_scene()

@tool
extends Area2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	if body is CharacterBody2D:
		body.level_won()

