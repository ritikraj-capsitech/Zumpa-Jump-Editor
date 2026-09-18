@tool
class_name WorldThemeRegistry
extends RefCounted

static var _themes: Dictionary = {
	"world_1": {
		"id": "world_1",
		"name": "World 1 - Forest Hills",
		"background": "res://Sprite/ENV/setting screen.png",
		"wall_texture": "res://Sprite/LVLFrames/Union.png",
		"platform_texture": "res://Sprite/ENV/RecPlatform.png",
		"theme_color": Color(0.2, 0.8, 0.4, 1.0)
	},
	"world_2": {
		"id": "world_2",
		"name": "World 2 - Desert Sunset",
		"background": "res://Sprite/ENV/setting screen-1.png",
		"wall_texture": "res://Sprite/LVLFrames/Union (2).png",
		"platform_texture": "res://Sprite/ENV/Group 215.png",
		"theme_color": Color(0.9, 0.6, 0.2, 1.0)
	},
	"world_3": {
		"id": "world_3",
		"name": "World 3 - Cyber Night",
		"background": "res://Sprite/ENV/setting screen-2.png",
		"wall_texture": "res://Sprite/LVLFrames/Union (3).png",
		"platform_texture": "res://Sprite/ENV/Group 217.png",
		"theme_color": Color(0.2, 0.6, 1.0, 1.0)
	}
}

static func get_all_themes() -> Dictionary:
	return _themes

static func get_theme(theme_id: String) -> Dictionary:
	if _themes.has(theme_id):
		return _themes[theme_id]
	return _themes["world_1"]

static func create_tileset_for_theme(theme_id: String) -> TileSet:
	var theme_info = get_theme(theme_id)
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(64, 64)

	# 1. Add physics collision layer FIRST
	tileset.add_physics_layer(0)
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 1)

	var tex_path: String = theme_info.get("platform_texture", "res://Sprite/ENV/RecPlatform.png")
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		var atlas_source := TileSetAtlasSource.new()
		atlas_source.texture = tex
		atlas_source.texture_region_size = Vector2i(64, 64)

		# 2. Add atlas source to TileSet FIRST so physics layer index 0 is known
		tileset.add_source(atlas_source, 0)

		# 3. Create tile and assign collision polygon
		atlas_source.create_tile(Vector2i(0, 0))
		var tile_data = atlas_source.get_tile_data(Vector2i(0, 0), 0)
		if tile_data:
			var poly = PackedVector2Array([
				Vector2(-32, -32),
				Vector2(32, -32),
				Vector2(32, 32),
				Vector2(-32, 32)
			])
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, poly)

	return tileset
