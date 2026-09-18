# Zumpa Jump - Project Progress & Context Handover

This document provides a complete state overview, architecture guide, and recent progress details for the **Zumpa Jump Level Editor & Gameplay System** in Godot 4.

---

## 1. Project Overview & Architecture

Zumpa Jump is a portrait-mode platformer built in **Godot 4**. The level architecture is data-driven: levels are saved as lightweight Resource files (`.tres` in `res://Levels/`) and loaded dynamically at runtime.

### Key Components & Data Flow

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

---

## 2. Recent Progress & Completed Tasks

### A. TileMap & Multi-World Theme System (`WorldThemeRegistry.gd`, `level_loader.gd`, `game_play.gd`)
- **World Registry**: Created [`WorldThemeRegistry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd) registering themes:
  - `"world_1"`: Forest Hills (Green BG, standard side walls, forest platforms).
  - `"world_2"`: Desert Sunset (Sunset BG, desert side walls, desert platforms).
  - `"world_3"`: Cyber Night (Cyber BG, cyber side walls, cyber platforms).
- **TileMap Terrain**: [`LevelLoader.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_loader.gd) instantiates a Godot 4 `TileMapLayer` (`$LevelRoot/WorldTileMap`) dynamically built from the level's selected `world_theme`.
- **Dynamic Backgrounds & HUD**: [`game_play.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/game_play.gd) updates background texture and HUD world labels dynamically as the player advances across levels/worlds.
- **Editor Theme Picker**: Added **World Theme** dropdown (`WorldThemeOpt`) to the level editor bottom toolbar in [`level_editor.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_editor.gd) with visual canvas tint updates in [`level_canvas.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_canvas.gd).

### B. Obstacle 2 Integration (`obs_2.tscn` & `obs_2.gd`)
- **Node & Script**: `res://Obstacle/obs_2.tscn` and `res://obs_2.gd`.
- **Group Registration**: Root `StaticBody2D` belongs to group `"obstacle"`. Contact with player triggers immediate Game Over.
- **Physics Motion**: Performs simultaneous rotation and horizontal sine-wave movement using `rotation_speed`, `move_speed`, and `move_distance`.
- **Registry Entry**: Added `"obs_2"` to [`ObjectRegistry`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd) with default properties `{"rotation_speed": 2.0, "move_speed": 100.0, "move_distance": 200.0}`.
- **Editor Inspector Support**: Extended [`level_editor.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_editor.gd) to expose spinboxes for `Move Speed` and `Move Dist` when `obs_2` is selected.

### C. Multi-Level System (`LevelManager.gd`)
- **Directory Scanning**: [`LevelManager`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_manager.gd) scans `res://Levels/` for `.tres` files (`get_all_level_paths()`) sorted in order.
- **Sequential Level Navigation**: Added `get_next_level_path(current_path)` and `load_next_level()`.
- **Default Level Generation**:
  - `level_001.tres`: Level 1 - Forest Hills (`world_1`).
  - `level_002.tres`: Level 2 - Desert Challenge (`world_2`).
  - `level_003.tres`: Level 3 - Cyber Zone (`world_3`).

---

## 3. World Themes & Object Registry Reference

### World Themes ([`Scripts/world_theme_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd))

| Theme ID | Display Name | Background Image | Side Wall Texture | Platform Texture |
|---|---|---|---|---|
| `world_1` | World 1 - Forest Hills | `setting screen.png` | `Union.png` | `RecPlatform.png` |
| `world_2` | World 2 - Desert Sunset | `setting screen-1.png` | `Union (2).png` | `Group 215.png` |
| `world_3` | World 3 - Cyber Night | `setting screen-2.png` | `Union (3).png` | `Group 217.png` |

### Placeable Objects ([`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd))

| `object_id` | Display Name | Scene Path | Category | Default Properties |
|---|---|---|---|---|
| `obs_1` | Rotating Obstacle 1 | `res://Obstacle/obs_1.tscn` | Obstacles | `{"rotation_speed": 2.0}` |
| `obs_2` | Moving & Rotating Obstacle 2 | `res://Obstacle/obs_2.tscn` | Obstacles | `{"rotation_speed": 2.0, "move_speed": 100.0, "move_distance": 200.0}` |
| `platform` | Ground Platform | `res://Obstacle/platform.tscn` | Platforms | `{}` |
| `win_area` | Win Area | `res://Scenes/win_area_node.tscn` | Triggers | `{}` |

---

## 4. Key File Map

- **Data & World Models**:
  - [`Scripts/level_data.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_data.gd) - Level resource class with `world_theme` & `tile_data`.
  - [`Scripts/world_theme_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd) - Registry for multi-world TileSets and visuals.
  - [`Scripts/object_data.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_data.gd) - Placed object instance class.
  - [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd) - Central object registry dictionary.

- **System Core**:
  - [`Scripts/level_manager.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_manager.gd) - Multi-level loader, saver, and scanner.
  - [`Scripts/level_loader.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_loader.gd) - Spawns TileMapLayer terrain, player, and dynamic boundaries into scene tree.

- **Gameplay & Player**:
  - [`Scripts/character_body_2d.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/character_body_2d.gd) - Player movement, obstacle collision, Game Over, and Win UI with Level transition.
  - [`Scripts/game_play.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/game_play.gd) - Gameplay scene manager with dynamic background & Level/World HUD.
  - [`Scenes/game_play.tscn`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scenes/game_play.tscn) - Main game play scene.

- **Editor Addon**:
  - [`addons/zumpa_level_editor/level_editor.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_editor.gd) - Editor plugin main UI script with World Theme picker.
  - [`addons/zumpa_level_editor/level_editor.tscn`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_editor.tscn) - Editor scene layout.
  - [`addons/zumpa_level_editor/level_canvas.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_canvas.gd) - Drag & drop level editing canvas with theme color hints.

---

## 5. Instructions for Antigravity AI

1. Refer to `PROGRESS_CONTEXT.md` and `EDITOR_GUIDE.md`.
2. All level `.tres` files reside in `res://Levels/`.
3. To add a new World Theme:
   - Add entry in [`Scripts/world_theme_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd) with background image path, wall texture path, and platform texture path.
