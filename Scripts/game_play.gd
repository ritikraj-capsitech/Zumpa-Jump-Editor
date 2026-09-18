extends Control

@onready var level_root: Node2D = $LevelRoot

func _ready() -> void:
	var lvl_data: LevelData = LevelManager.get_default_level()
	if lvl_data:
		LevelLoader.load_level(lvl_data, level_root)
		setup_hud(lvl_data)
	else:
		push_error("GamePlay: Failed to obtain LevelData")

func setup_hud(lvl_data: LevelData) -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.position = Vector2(20, 20)
	canvas.add_child(margin)

	var bg := PanelContainer.new()
	margin.add_child(bg)

	var label := Label.new()
	var display_title = lvl_data.level_name if lvl_data.level_name != "" else lvl_data.level_id
	label.text = " 🎮 " + display_title + " (" + lvl_data.level_id + ") "
	bg.add_child(label)
