extends Control

@onready var level_root: Node2D = $LevelRoot
@onready var bg_texture_rect: TextureRect = $TextureRect if has_node("TextureRect") else null

func _ready() -> void:
	var lvl_data: LevelData = LevelManager.get_default_level()
	if lvl_data:
		var player = LevelLoader.load_level(lvl_data, level_root)
		apply_world_theme(lvl_data, player)
		setup_hud(lvl_data)
	else:
		push_error("GamePlay: Failed to obtain LevelData")

func apply_world_theme(lvl_data: LevelData, player: Node2D = null) -> void:
	var theme_info = WorldThemeRegistry.get_theme(lvl_data.world_theme)
	var bg_path: String = theme_info.get("background", "res://Sprite/ENV/setting screen.png")
	if ResourceLoader.exists(bg_path):
		var bg_tex = load(bg_path)
		if player and player.has_node("Camera2D/TextureRect"):
			var p_bg = player.get_node("Camera2D/TextureRect") as TextureRect
			if p_bg:
				p_bg.texture = bg_tex
				p_bg.z_index = -100
				p_bg.z_as_relative = false

func setup_hud(lvl_data: LevelData) -> void:
	var theme_info = WorldThemeRegistry.get_theme(lvl_data.world_theme)
	var theme_name: String = theme_info.get("name", "World 1")

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
	label.text = " 🎮 " + display_title + " (" + lvl_data.level_id + ")  |  🌍 " + theme_name + " "
	bg.add_child(label)
