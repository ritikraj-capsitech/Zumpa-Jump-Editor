@tool
extends CharacterBody2D
class_name FallingStone

@export var trigger_tag: String = "trap_1"
@export var fall_speed: float = 400.0
@export var roll_speed: float = 350.0
@export var gravity: float = 980.0
@export var rotation_speed: float = 4.0
@export var fall_distance: float = 3000.0

var is_falling: bool = false
var start_pos: Vector2
var roll_direction: float = 1.0 # 1.0 for right, -1.0 for left

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var area_detector: Area2D = $Area2D if has_node("Area2D") else null

func _ready() -> void:
	add_to_group("obstacle")
	add_to_group("falling_stone")
	add_to_group("triggerable")
	start_pos = position

	# Obstacle collision layer (2) & Terrain collision mask (1)
	collision_layer = 2
	collision_mask = 1

	if not Engine.is_editor_hint():
		if area_detector and not area_detector.body_entered.is_connected(_on_area_body_entered):
			area_detector.body_entered.connect(_on_area_body_entered)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if is_falling:
		if is_on_floor():
			# Landed on tile terrain! Roll horizontally over tiles
			velocity.y = 0.0
			velocity.x = roll_direction * roll_speed
			if sprite:
				sprite.rotation += (velocity.x / 40.0) * delta
		else:
			# In air - fall downwards
			velocity.y += gravity * delta
			velocity.x = lerp(velocity.x, 0.0, delta * 2.0)
			if sprite:
				sprite.rotation += rotation_speed * delta

		move_and_slide()

		# Wall bounce detection
		if is_on_wall():
			roll_direction *= -1.0
			velocity.x = roll_direction * roll_speed

		# Check slide collisions for player touch
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider and (collider is CharacterBody2D or collider.has_method("game_over") or collider.is_in_group("player")):
				if collider.has_method("game_over"):
					collider.game_over()

		# Despawn if fallen too far
		if position.y > start_pos.y + fall_distance:
			queue_free()

func trigger() -> void:
	is_falling = true
	velocity.y = fall_speed

func _on_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body.has_method("game_over") or body.is_in_group("player"):
		if body.has_method("game_over"):
			body.game_over()
