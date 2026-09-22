@tool
extends CharacterBody2D
class_name FallingStone

@export var trigger_tag: String = "trap_1"
@export var fall_speed: float = 500.0
@export var roll_speed: float = 400.0
@export var gravity: float = 980.0
@export var rotation_speed: float = 4.0
@export var fall_distance: float = 3000.0

var is_falling: bool = false
var start_pos: Vector2

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var area_detector: Area2D = $Area2D if has_node("Area2D") else null
#
#func _ready() -> void:
	#add_to_group("obstacle")
	#add_to_group("falling_stone")
	#add_to_group("triggerable")
	#start_pos = position
#
	## Obstacle collision layer (2) & Terrain collision mask (1)
	#collision_layer = 2
	#collision_mask = 1
	#
	## Allow steep slopes up to 80 degrees to be recognized as floor
	#floor_max_angle = deg_to_rad(80.0)
	#floor_snap_length = 16.0
#
	#if not Engine.is_editor_hint():
		#if area_detector and not area_detector.body_entered.is_connected(_on_area_body_entered):
			#area_detector.body_entered.connect(_on_area_body_entered)
#
#func _physics_process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#return
#
	#if is_falling:
		#var on_slope: bool = false
		#var slope_dir: float = 0.0
#
		## Check floor normal for sloped surfaces
		#if is_on_floor():
			#var normal = get_floor_normal()
			#if abs(normal.x) > 0.05:
				#on_slope = true
				#slope_dir = -sign(normal.x) # Downhill direction is opposite to surface normal horizontal component
#
		## Also check slide collision contact points if floor didn't pick up slope
		#if not on_slope:
			#for i in range(get_slide_collision_count()):
				#var col = get_slide_collision(i)
				#var normal = col.get_normal()
				#if abs(normal.x) > 0.05 and normal.y < 0.2:
					#on_slope = true
					#slope_dir = -sign(normal.x)
					#break
#
		#if on_slope:
			## Roll down the slope in downhill direction
			#velocity.x = lerp(velocity.x, slope_dir * roll_speed, delta * 10.0)
			#velocity.y += gravity * delta
			#if sprite:
				#sprite.rotation += (velocity.x / 30.0) * delta
		#elif is_on_floor():
			## Flat ground - stop horizontal movement and vertical falling
			#velocity.x = lerp(velocity.x, 0.0, delta * 15.0)
			#velocity.y = 0.0
			#if sprite:
				#sprite.rotation += (velocity.x / 30.0) * delta
		#else:
			## In air - fall DIRECTLY straight down with zero horizontal movement
			#velocity.x = 0.0
			#velocity.y += gravity * delta
			#if sprite:
				#sprite.rotation += rotation_speed * delta
#
		#move_and_slide()
#
		## Check slide collisions for player contact
		#for i in range(get_slide_collision_count()):
			#var col = get_slide_collision(i)
			#var collider = col.get_collider()
			#if collider and (collider is CharacterBody2D or collider.has_method("game_over") or collider.is_in_group("player")):
				#if collider.has_method("game_over"):
					#collider.game_over()
#
		## Despawn if fallen too far
		#if position.y > start_pos.y + fall_distance:
			#queue_free()
#
#func trigger() -> void:
	#is_falling = true
	#velocity = Vector2.ZERO
#
#func _on_area_body_entered(body: Node2D) -> void:
	#if body is CharacterBody2D or body.has_method("game_over") or body.is_in_group("player"):
		#if body.has_method("game_over"):
			#body.game_over()

func _ready() -> void:
	add_to_group("obstacle")
	add_to_group("falling_stone")

	# Stone collides with terrain
	collision_layer = 2
	collision_mask = 1

	# Connect Area2D
	if area_detector:
		area_detector.body_entered.connect(_on_area_body_entered)


func _physics_process(delta: float) -> void:
	if not is_falling:
		return

	# Gravity
	velocity.y += gravity * delta

	# ALWAYS fall vertically
	velocity.x = 0.0

	move_and_slide()


func _on_area_body_entered(body: Node2D) -> void:
	# Player entered the trigger area
	if body.is_in_group("player") or body.has_method("game_over"):
		trigger()

		if body.has_method("game_over"):
			body.game_over()


func trigger() -> void:
	if is_falling:
		return

	is_falling = true
	velocity = Vector2.ZERO
