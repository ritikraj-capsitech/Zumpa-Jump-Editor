# Zumpa Jump - Complete Technical Architecture & Team Guide

This document provides a complete technical specification, file map, architecture guide, and workflow manual for the **Zumpa Jump Level Editor & Gameplay System** in **Godot 4**.

---

## 1. Executive Summary & System Architecture

Zumpa Jump is a data-driven portrait-mode platformer. Levels are saved as lightweight Resource files (`.tres` in `res://Levels/`) and loaded dynamically at runtime.

### Data Flow Diagram

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

## 2. Complete File & Script Map

### A. Data Models & Registries (`res://Scripts/`)

1. **[`Scripts/level_data.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_data.gd)**
   - **Class**: `LevelData` (extends `Resource`)
   - **Purpose**: Primary data structure saved in `.tres` level files.
   - **Fields**:
     - `@export var level_id: String` (e.g. `"level_001"`)
     - `@export var level_name: String` (e.g. `"Level 1 - Forest Hills"`)
     - `@export var world_theme: String` (e.g. `"world_1"`, `"world_2"`, `"world_3"`)
     - `@export var player_start: Vector2` (Spawn coordinates)
     - `@export var level_size: Vector2` (Playable dimensions)
     - `@export var objects: Array[ObjectData]` (Placed obstacle instances)
     - `@export var tile_data: Array[Dictionary]` (Saved TileMap cell coordinates & atlas IDs)

2. **[`Scripts/object_data.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_data.gd)**
   - **Class**: `ObjectData` (extends `Resource`)
   - **Purpose**: Represents a single placed object instance.
   - **Fields**: `object_id`, `position`, `rotation`, `scale`, `properties` dictionary.

3. **[`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd)**
   - **Class**: `ObjectRegistry` (extends `RefCounted`)
   - **Purpose**: Central lookup table for placeable level objects.
   - **Registered Objects**:
     - `obs_1`: Rotating Obstacle 1 (`res://Obstacle/obs_1.tscn`)
     - `obs_2`: Moving & Rotating Obstacle 2 (`res://Obstacle/obs_2.tscn`)
     - `platform`: Ground Platform (`res://Obstacle/platform.tscn`)
     - `win_area`: Win Area Trigger (`res://Scenes/win_area_node.tscn`)

4. **[`Scripts/world_theme_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd)**
   - **Class**: `WorldThemeRegistry` (extends `RefCounted`)
   - **Purpose**: Manages multi-world themes and procedural TileSets.
   - **Themes**:
     - 🌲 `world_1` (Forest Hills): Green BG, forest side walls, `(1,1)` grass top atlas.
     - 🏜️ `world_2` (Desert Sunset): Sunset BG, desert side walls, `(7,1)` sand top atlas.
     - 🌃 `world_3` (Cyber Night): Cyber BG, cyber side walls, `(11,1)` stone top atlas.
   - **Function**: `create_tileset_for_theme(theme_id)` programmatically generates a `TileSet` with a 16x16 `TileSetAtlasSource` (`res://tiles/Terrain (16x16).png`) and automatically attaches 2D physics collision polygons to all tiles.

---

### B. Core System & Gameplay (`res://Scripts/` & `res://Scenes/`)

1. **[`Scripts/level_loader.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_loader.gd)**
   - **Class**: `LevelLoader` (extends `RefCounted`)
   - **Purpose**: Instantiates runtime nodes from `LevelData`.
   - **Workflow**:
     1. Clears existing container nodes.
     2. Spawns `Player` (`res://Scenes/Player.tscn`) at `player_start` with `z_index = 10`. Calculates `FALL_Y` threshold.
     3. Spawns `TileMapLayer` (`$LevelRoot/WorldTileMap`) scaled 3x (48px effective tile size) with theme TileSet.
     4. Spawns theme-specific dynamic side wall segments (`Union.png`, `Union (2).png`, `Union (3).png`).
     5. Instantiates placed objects from `ObjectRegistry` with position/rotation/scale/property overrides.

2. **[`Scripts/level_manager.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/level_manager.gd)**
   - **Class**: `LevelManager` (extends `RefCounted`)
   - **Purpose**: Handles level file saving, loading, directory scanning (`res://Levels/`), and level progression (`get_next_level_path()`).

3. **[`Scripts/game_play.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/game_play.gd)**
   - **Class**: `GamePlay` (extends `Control`)
   - **Purpose**: Controls `res://Scenes/game_play.tscn`. Applies theme background textures (`z_index = -100`) and displays in-game HUD overlay.

4. **[`Scripts/character_body_2d.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/character_body_2d.gd)**
   - **Class**: `CharacterBody2D` (Player)
   - **Purpose**: Player physics movement (keyboard + mobile touch), ground bounce, obstacle contact game over, and win condition dialogs (`▶ NEXT LEVEL`).

---

### C. Obstacles (`res://Obstacle/` & Root)

1. **[`Scripts/obs_1.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/obs_1.gd)**: Rotates continuously (`rotation += rotation_speed * delta`). Belongs to group `"obstacle"`.
2. **[`obs_2.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/obs_2.gd)**: Simultaneous rotation and horizontal sine-wave movement (`position.x = start_x + sin(...) * move_distance`). Belongs to group `"obstacle"`.

---

### D. Level Editor Addon (`res://addons/zumpa_level_editor/`)

1. **[`zumpa_level_editor.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/zumpa_level_editor.gd)**: Godot `EditorPlugin` script registering the level editor main tab.
2. **[`level_editor.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_editor.gd)**: Main UI script managing toolbar buttons, level dropdown, world theme selector, tile palette spinboxes, and object property inspectors.
3. **[`level_canvas.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_canvas.gd)**: 2D drawing viewport canvas:
   - Draws mathematically aligned 48px tile grid lines.
   - Draws real-time green/red hover cursor box highlights (`hover_cell`).
   - Handles tile brush painting/erasing and object drag-and-drop.
4. **[`level_editor.tscn`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/addons/zumpa_level_editor/level_editor.tscn)**: UI scene layout featuring Top Bar, Left Palette, Center Scrollable Canvas, Right Inspector (with Tile Palette zoom preview), and Bottom Bar.

---

## 3. How to Extend the Project (Team Manual)

### How to Add a New Obstacle
1. Create a PackedScene in `res://Obstacle/` (e.g. `res://Obstacle/obs_3.tscn`).
2. Add root node to group `"obstacle"`.
3. Attach script with `@export` properties.
4. Add entry to [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/object_registry.gd).

### How to Add a New World Theme
1. Open [`Scripts/world_theme_registry.gd`](file:///e:/Zumpa%20Jump/Zumpa-Jump-Editor/Scripts/world_theme_registry.gd).
2. Add a new theme definition to `_themes` dictionary or call `WorldThemeRegistry.register_theme(...)`.
