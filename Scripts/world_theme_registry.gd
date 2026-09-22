@tool
class_name WorldThemeRegistry
extends RefCounted

static var _themes: Dictionary = {
	"world_1": {
		"id": "world_1",
		"name": "World 1 - Forest Hills",
		"background": "res://tiles/Bg.png",
		"wall_texture": "res://Sprite/LVLFrames/Union.png",
		"platform_texture": "res://tiles/Terrain (16x16).png",
		"tile_size": Vector2i(16, 16),
		"default_atlas_coords": Vector2i(1, 1),
		"theme_color": Color(0.2, 0.8, 0.4, 1.0)
	},
	"world_2": {
		"id": "world_2",
		"name": "World 2 - Desert Sunset",
		"background": "res://tiles/Bg.png",
		"wall_texture": "res://tiles/ChatGPT Image Sep 22, 2026, 12_39_12 PM.png",
		"platform_texture": "res://tiles/image.png",
		"tile_size": Vector2i(16, 16),
		"default_atlas_coords": Vector2i(7, 1),
		"theme_color": Color(0.9, 0.6, 0.2, 1.0)
	},
	"world_3": {
		"id": "world_3",
		"name": "World 3 - Cyber Night",
		"background": "res://Sprite/ENV/setting screen-3.png",
		"wall_texture": "res://Sprite/LVLFrames/Union.png",
		"platform_texture": "res://tiles/Terrain (16x16).png",
		"tile_size": Vector2i(16, 16),
		"default_atlas_coords": Vector2i(11, 1),
		"theme_color": Color(0.2, 0.6, 1.0, 1.0)
	}
}

static func register_theme(theme_id: String, display_name: String, bg_path: String, wall_path: String, platform_tile_path: String, tile_sz: Vector2i = Vector2i(16, 16), default_atlas: Vector2i = Vector2i(1, 1), theme_color: Color = Color.WHITE) -> void:
	_themes[theme_id] = {
		"id": theme_id,
		"name": display_name,
		"background": bg_path,
		"wall_texture": wall_path,
		"platform_texture": platform_tile_path,
		"tile_size": tile_sz,
		"default_atlas_coords": default_atlas,
		"theme_color": theme_color
	}

static func set_theme_tile_size(theme_id: String, tile_sz: Vector2i) -> void:
	if _themes.has(theme_id):
		_themes[theme_id]["tile_size"] = tile_sz

static func get_all_themes() -> Dictionary:
	return _themes

static func get_theme(theme_id: String) -> Dictionary:
	if _themes.has(theme_id):
		return _themes[theme_id]
	return _themes["world_1"]

static func create_tileset_for_theme(theme_id: String) -> TileSet:
	var theme_info = get_theme(theme_id)
	var t_size: Vector2i = theme_info.get("tile_size", Vector2i(16, 16))
	var tileset := TileSet.new()
	tileset.tile_size = t_size

	# 1. Add physics collision layer FIRST
	tileset.add_physics_layer(0)
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 1)

	var tex_path: String = theme_info.get("platform_texture", "res://tiles/Terrain (16x16).png")
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		var atlas_source := TileSetAtlasSource.new()
		atlas_source.texture = tex
		atlas_source.texture_region_size = t_size

		# 2. Add atlas source to TileSet FIRST
		tileset.add_source(atlas_source, 0)

		# 3. Populate tiles across the texture sheet
		var tex_size = tex.get_size()
		var cols = max(1, int(tex_size.x / float(t_size.x)))
		var rows = max(1, int(tex_size.y / float(t_size.y)))

		var half_w = float(t_size.x) / 2.0
		var half_h = float(t_size.y) / 2.0

		for y in range(rows):
			for x in range(cols):
				var coords := Vector2i(x, y)
				atlas_source.create_tile(coords)
				var tile_data = atlas_source.get_tile_data(coords, 0)
				if tile_data:
					var poly = PackedVector2Array([
						Vector2(-half_w, -half_h),
						Vector2(half_w, -half_h),
						Vector2(half_w, half_h),
						Vector2(-half_w, half_h)
					])
					tile_data.add_collision_polygon(0)
					tile_data.set_collision_polygon_points(0, 0, poly)

	return tileset
