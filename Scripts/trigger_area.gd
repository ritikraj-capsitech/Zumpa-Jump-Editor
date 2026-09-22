@tool
extends Area2D
class_name TriggerArea

@export var trigger_tag: String = "trap_1"
@export var area_width: float = 200.0
@export var area_height: float = 150.0

var triggered: bool = false

func _ready() -> void:
	add_to_group("trigger_area")
	update_shape_size()

	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)

func update_shape_size() -> void:
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		(col.shape as RectangleShape2D).size = Vector2(area_width, area_height)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_shape_size()
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if body is CharacterBody2D or body.name.begins_with("Player") or body.is_in_group("player") or body.has_method("game_over"):
		triggered = true
		activate_triggers()

func activate_triggers() -> void:
	var nodes = get_tree().get_nodes_in_group("triggerable")
	for node in nodes:
		if "trigger_tag" in node:
			if node.trigger_tag == trigger_tag or trigger_tag == "" or node.trigger_tag == "":
				if node.has_method("trigger"):
					node.trigger()

func _draw() -> void:
	if Engine.is_editor_hint():
		var rect = Rect2(-Vector2(area_width, area_height) / 2.0, Vector2(area_width, area_height))
		draw_rect(rect, Color(1.0, 0.8, 0.1, 0.35), true)
		draw_rect(rect, Color(1.0, 0.8, 0.1, 0.9), false, 2.5)
		var font = ThemeDB.fallback_font
		if font:
			draw_string(font, Vector2(-area_width / 2.0 + 10, 5), "TRIGGER: " + trigger_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 1))
