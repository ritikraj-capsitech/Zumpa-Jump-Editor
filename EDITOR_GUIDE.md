# Zumpa Editor & Gameplay System - Complete Reference Guide

This guide explains the complete architecture, data models, level rendering pipeline, and step-by-step extension manual for the **Zumpa Jump Level Editor & Gameplay System** in **Godot 4**.

---

## 1. System Architecture & Component Interactions

```
+-------------------------------------------------------------------------+
|                           LevelData (.tres)                             |
|  - level_id / level_name / world_theme                                  |
|  - player_start / level_size                                            |
|  - objects: Array[ObjectData]                                           |
|  - tile_data: Array[Dictionary]                                         |
+-------------------------------------------------------------------------+
									|
									v
+-------------------------------------------------------------------------+
|                       WorldThemeRegistry                                |
|  Maps world_theme -> TileSet, Background, Wall Textures, Theme Color    |
+-------------------------------------------------------------------------+
									|
									v
+-------------------------------------------------------------------------+
|                            LevelLoader                                  |
|  1. Spawns Player (res://Scenes/Player.tscn) with z_index = 10          |
|  2. Spawns dynamic TileMapLayer (3x scale) for World Terrain            |
|  3. Spawns side wall boundaries dynamically per world theme             |
|  4. Iterates over objects -> calls ObjectRegistry.instantiate           |
+-------------------------------------------------------------------------+
									|
									v
+-------------------------------------------------------------------------+
|                          ObjectRegistry                                 |
|  Maps object_id -> Scene Path, Category, Default Properties             |
+-------------------------------------------------------------------------+
```

---

## 2. File-by-File & Script Technical Reference

| File Path | Role & Class | Description |
|---|---|---|
| [`Scripts/level_data.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_data.gd) | `LevelData` (Resource) | Holds level metadata, world theme ID, spawn point, dimensions, object array, and tile grid array. |
| [`Scripts/object_data.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_data.gd) | `ObjectData` (Resource) | Stores instance data for placed items (`object_id`, `position`, `rotation`, `scale`, `properties`). |
| [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd) | `ObjectRegistry` | Registry mapping `obs_1`, `obs_2`, `platform`, `win_area` to packed scenes and default parameters. |
| [`Scripts/world_theme_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd) | `WorldThemeRegistry` | Registry for world themes (`world_1`, `world_2`, `world_3`). Generates physics-enabled `TileSet` resources from `res://tiles/Terrain (16x16).png`. |
| [`Scripts/level_loader.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_loader.gd) | `LevelLoader` | Instantiates `Player`, 3x scaled `TileMapLayer` terrain, theme side walls, and placed objects into the scene tree. |
| [`Scripts/level_manager.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_manager.gd) | `LevelManager` | Handles level file saving, loading, directory scanning (`res://Levels/`), and next level transitions. |
| [`Scripts/game_play.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/game_play.gd) | `GamePlay` (Control) | Manages `res://Scenes/game_play.tscn`. Applies theme background graphics and displays level HUD. |
| [`Scripts/character_body_2d.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/character_body_2d.gd) | `CharacterBody2D` | Player controller (Keyboard + Touch), collision handling, Game Over, and Win screen UI. |
| [`Obstacle/obs_1.tscn`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Obstacle/obs_1.tscn) & [`Scripts/obs_1.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/obs_1.gd) | `StaticBody2D` | Rotating Obstacle 1. Belongs to group `"obstacle"`. |
| [`Obstacle/obs_2.tscn`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Obstacle/obs_2.tscn) & [`obs_2.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/obs_2.gd) | `StaticBody2D` | Moving & Rotating Obstacle 2. Belongs to group `"obstacle"`. |
| [`addons/zumpa_level_editor/level_editor.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_editor.gd) | `Control` (Editor) | Main Level Editor UI script managing toolbar, level switcher, world theme selector, and tile palette. |
| [`addons/zumpa_level_editor/level_canvas.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_canvas.gd) | `Control` (Canvas) | Interactive 2D drawing viewport canvas with mathematically aligned 48px tile grid overlay and green/red cursor box highlights. |

---

## 3. Step-by-Step Instructions for the Team

### 🎨 How to Use the Level Editor
1. **Open Editor**: Open `res://addons/zumpa_level_editor/level_editor.tscn`.
2. **Select or Create Level**: Use the **Level Select Dropdown** or click **`New`**.
3. **Pick World Theme**: Select `World 1` (Forest), `World 2` (Desert), or `World 3` (Cyber) from the bottom toolbar dropdown.
4. **Position Player Start**: Click **`🚩 Player Start`** and click on the canvas to set spawn position.
5. **Paint TileMap Terrain**:
   - Click **`🧱 Draw Tile`** on the left panel.
   - Adjust **Atlas X** / **Atlas Y** or click Quick Tile Presets (`Grass Top`, `Dirt`, `Sand`, `Stone`) in the right inspector panel.
   - Click or drag on the level canvas to paint platform blocks!
   - Use **`🧹 Erase Tile`** or right-click to delete tiles.
6. **Place Obstacles & Goal**: Click `+ Rotating Obstacle 1`, `+ Moving & Rotating Obstacle 2`, or `+ Win Area` and place them on the canvas. Adjust position/rotation/scale in the right inspector.
7. **Save & Play**: Click **`Save`** (`Ctrl + S`), then click **`▶ Play / Preview`**.

---

### 🚀 How to Add a New Obstacle
1. Create scene in `res://Obstacle/your_obstacle.tscn`.
2. Add root node to group `"obstacle"`.
3. Attach script with `@export` properties.
4. Register entry in [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd).

---

### 🌍 How to Add a New World Theme
1. Open [`Scripts/world_theme_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd).
2. Add a new theme entry to `_themes` dictionary with background, wall texture, tilemap sheet path, and default atlas coords.
