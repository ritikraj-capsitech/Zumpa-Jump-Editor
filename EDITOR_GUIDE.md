# Zumpa Editor Guide & Documentation

This document explains the architecture of the **Zumpa Jump Level Editor & Multi-World System**, how levels, TileMaps, and objects are structured, and step-by-step instructions on how to add a new obstacle or world theme.

---

## 1. How the Editor & World Architecture Works

The Zumpa Editor is built around a data-driven node instantiation architecture in Godot 4. Levels are saved as lightweight data resources (`.tres`) and constructed dynamically at runtime with custom **TileMaps**, background visuals, side boundary frames, and placeable objects.

### Key Architecture Components

```
+------------------------------------------------------------------+
|                          LevelData (.tres)                       |
|  - level_id / level_name / world_theme                           |
|  - player_start / level_size                                     |
|  - objects: Array[ObjectData]                                    |
|  - tile_data: Array[Dictionary]                                  |
+------------------------------------------------------------------+
								  |
								  v
+------------------------------------------------------------------+
|                       WorldThemeRegistry                         |
|  Maps world_theme -> TileSet, Background, Wall Textures          |
+------------------------------------------------------------------+
								  |
								  v
+------------------------------------------------------------------+
|                            LevelLoader                           |
|  1. Spawns Player (res://Scenes/Player.tscn)                     |
|  2. Spawns dynamic TileMapLayer for World Terrain                |
|  3. Spawns side wall boundaries dynamically per world theme      |
|  4. Iterates over objects -> calls ObjectRegistry.instantiate    |
+------------------------------------------------------------------+
								  |
								  v
+------------------------------------------------------------------+
|                          ObjectRegistry                          |
|  Maps object_id -> Scene Path, Category, Default Properties      |
+------------------------------------------------------------------+
```

1. **[`WorldThemeRegistry`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd)**
   - Maps world theme IDs (e.g. `"world_1"`, `"world_2"`, `"world_3"`) to background images, dynamic side wall textures, platform textures, and TileSet resources.

2. **[`LevelData`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_data.gd)**
   - Resource holding level metadata (`level_id`, `level_name`, `world_theme`, `player_start`, `level_size`, `objects`, and `tile_data`).

3. **[`ObjectRegistry`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd)**
   - Central dictionary mapping `object_id` strings (e.g. `"obs_1"`, `"obs_2"`, `"platform"`, `"win_area"`) to display names, scene paths, categories, and default properties.

4. **[`LevelLoader`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_loader.gd)**
   - Takes a `LevelData` resource and instantiates a Godot 4 `TileMapLayer` (`$LevelRoot/WorldTileMap`), player node, theme side wall boundaries, and placed objects.

---

## 2. How to Add a New World Theme

1. Open [`Scripts/world_theme_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd).
2. Add a new theme entry to `_themes` dictionary:

```gdscript
"world_4": {
	"id": "world_4",
	"name": "World 4 - Volcano Pass",
	"background": "res://Sprite/ENV/setting screen-3.png",
	"wall_texture": "res://Sprite/LVLFrames/Union (6).png",
	"platform_texture": "res://Sprite/ENV/Group 218.png",
	"theme_color": Color(0.9, 0.2, 0.2, 1.0)
}
```

3. The new world theme will automatically appear in the **World Theme** dropdown inside the Level Editor toolbar and adapt the level background, tile set, side walls, and HUD graphics upon selection!

---

## 3. How to Add a New Obstacle to the Editor

1. **Create Scene**: Create a PackedScene in `res://Obstacle/` (e.g. `res://Obstacle/obs_3.tscn`).
2. **Assign Group**: Add root node to group `"obstacle"`.
3. **Script with Exports**: Attach GDScript defining `@export` properties.
4. **Register**: Add entry in [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd).
