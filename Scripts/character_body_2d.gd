#extends CharacterBody2D
#
#const MOVE_SPEED = 300.0
#const JUMP_FORCE = -400.0
#
#func _physics_process(delta: float) -> void:
	## Gravity
	#velocity += get_gravity() * delta
#
	## Right key
	#if Input.is_action_just_pressed("ui_right"):
		#velocity.x = MOVE_SPEED
		#velocity.y = JUMP_FORCE
#
	## Left key
	#elif Input.is_action_just_pressed("ui_left"):
		#velocity.x = -MOVE_SPEED
		#velocity.y = JUMP_FORCE
#
	#move_and_slide()
#extends CharacterBody2D 
 #
#const MOVE_SPEED = 300.0 
#const JUMP_FORCE = -400.0 
 #
#func _physics_process(delta: float) -> void: 
	## Gravity 
	#velocity += get_gravity() * delta 
#
	## Bounce automatically when on the ground
	#if is_on_floor():
		#velocity.y = JUMP_FORCE
 #
	## Right key 
	#if Input.is_action_just_pressed("ui_right"): 
		#velocity.x = MOVE_SPEED 
		#velocity.y = JUMP_FORCE 
 #
	## Left key 
	#elif Input.is_action_just_pressed("ui_left"): 
		#velocity.x = -MOVE_SPEED 
		#velocity.y = JUMP_FORCE 
 #
	#move_and_slide()
#
#
#extends CharacterBody2D
#
#const MOVE_SPEED = 350.0
#const JUMP_FORCE = -500.0
#
#@export var FALL_Y: float = 2000.0
#
#var level_ended := false
#
#
#func _physics_process(delta: float) -> void:
	#if level_ended:
		#return
#
	## Gravity
	#velocity += get_gravity() * delta
#
	## Bounce automatically when on the ground
	#if is_on_floor():
		#velocity.y = JUMP_FORCE
#
	## Right key
	#if Input.is_action_just_pressed("ui_right"):
		#velocity.x = MOVE_SPEED
		#velocity.y = JUMP_FORCE
#
	## Left key
	#elif Input.is_action_just_pressed("ui_left"):
		#velocity.x = -MOVE_SPEED
		#velocity.y = JUMP_FORCE
#
	#move_and_slide()
#
	## Check obstacle collision
	#for i in get_slide_collision_count():
		#var collision = get_slide_collision(i)
		#var collider = collision.get_collider()
#
		#if collider.is_in_group("obstacle"):
			#game_over()
			#return
#
	## Check if player falls out of the level
	#if global_position.y > FALL_Y:
		#game_over()
#
#
#func game_over() -> void:
	#if level_ended:
		#return
#
	#level_ended = true
#
	#print("GAME OVER!")
#
	#show_restart_button()
#
#
#func level_won() -> void:
	#if level_ended:
		#return
#
	#level_ended = true
#
	#print("GAME WIN!")
#
	#show_restart_button()
#
#
#func show_restart_button() -> void:
	## Create CanvasLayer
	#var canvas_layer := CanvasLayer.new()
	#canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	#get_tree().current_scene.add_child(canvas_layer)
#
	## Create button
	#var button := Button.new()
#
	#button.text = "RESTART LEVEL"
	#button.size = Vector2(250, 70)
#
	## Center button on screen
	#var screen_size = get_viewport().get_visible_rect().size
	#button.position = (screen_size - button.size) / 2.0
#
	#button.process_mode = Node.PROCESS_MODE_ALWAYS
#
	#canvas_layer.add_child(button)
#
	#button.pressed.connect(restart_level)
#
	## Pause game
	#get_tree().paused = true
#
#
#func restart_level() -> void:
	#get_tree().paused = false
	#get_tree().reload_current_scene()




extends CharacterBody2D

const MOVE_SPEED = 350.0
const JUMP_FORCE = -500.0

@export var FALL_Y: float = 2000.0

var level_ended := false


func _physics_process(delta: float) -> void:
	if level_ended:
		return

	# Gravity
	velocity += get_gravity() * delta

	# Bounce automatically when on the ground
	if is_on_floor():
		velocity.y = JUMP_FORCE

	# PC input
	if Input.is_action_just_pressed("ui_right"):
		velocity.x = MOVE_SPEED
		velocity.y = JUMP_FORCE

	elif Input.is_action_just_pressed("ui_left"):
		velocity.x = -MOVE_SPEED
		velocity.y = JUMP_FORCE

	move_and_slide()

	# Check obstacle collision
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("obstacle"):
			game_over()
			return

	# Check if player falls out of the level
	if global_position.y > FALL_Y:
		game_over()


func _input(event: InputEvent) -> void:
	if level_ended:
		return

	# Mobile touch
	if event is InputEventScreenTouch:
		if event.pressed:
			var screen_width = get_viewport().get_visible_rect().size.x

			# Left half of screen
			if event.position.x < screen_width / 2.0:
				velocity.x = -MOVE_SPEED
				velocity.y = JUMP_FORCE

			# Right half of screen
			else:
				velocity.x = MOVE_SPEED
				velocity.y = JUMP_FORCE


func game_over() -> void:
	if level_ended:
		return

	level_ended = true

	print("GAME OVER!")

	show_restart_button()


func level_won() -> void:
	if level_ended:
		return

	level_ended = true

	print("GAME WIN!")

	show_win_ui()


func show_restart_button() -> void:
	# Create CanvasLayer
	var canvas_layer := CanvasLayer.new()
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(canvas_layer)

	var panel := PanelContainer.new()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var screen_size = get_viewport().get_visible_rect().size
	panel.size = Vector2(300, 150)
	panel.position = (screen_size - panel.size) / 2.0
	canvas_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var label := Label.new()
	label.text = "GAME OVER"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	# Create button
	var button := Button.new()
	button.text = "RESTART LEVEL"
	button.custom_minimum_size = Vector2(200, 50)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(button)

	button.pressed.connect(restart_level)

	# Pause game
	get_tree().paused = true


func show_win_ui() -> void:
	var next_path = LevelManager.get_next_level_path(LevelManager.active_level_path)

	# Create CanvasLayer
	var canvas_layer := CanvasLayer.new()
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(canvas_layer)

	var panel := PanelContainer.new()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var screen_size = get_viewport().get_visible_rect().size
	panel.size = Vector2(350, 220)
	panel.position = (screen_size - panel.size) / 2.0
	canvas_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var label := Label.new()
	if next_path != "":
		label.text = "LEVEL COMPLETED! 🎉"
	else:
		label.text = "🏆 ALL LEVELS CLEARED! 🏆"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	if next_path != "":
		var next_btn := Button.new()
		next_btn.text = "▶ NEXT LEVEL"
		next_btn.custom_minimum_size = Vector2(220, 50)
		next_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		vbox.add_child(next_btn)
		next_btn.pressed.connect(func():
			get_tree().paused = false
			LevelManager.load_level_data(next_path)
			get_tree().reload_current_scene()
		)
	else:
		var restart_all_btn := Button.new()
		restart_all_btn.text = "🔄 RESTART FROM LEVEL 1"
		restart_all_btn.custom_minimum_size = Vector2(220, 50)
		restart_all_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		vbox.add_child(restart_all_btn)
		restart_all_btn.pressed.connect(func():
			get_tree().paused = false
			LevelManager.load_level_data("res://Levels/level_001.tres")
			get_tree().reload_current_scene()
		)

	var retry_btn := Button.new()
	retry_btn.text = "RESTART THIS LEVEL"
	retry_btn.custom_minimum_size = Vector2(220, 40)
	retry_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(retry_btn)
	retry_btn.pressed.connect(restart_level)

	# Pause game
	get_tree().paused = true


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
