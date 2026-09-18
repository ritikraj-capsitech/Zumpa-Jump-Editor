# Zumpa Jump - Project Progress & Context Handover

This document provides a complete state overview, architecture guide, and recent progress details for the **Zumpa Jump Level Editor & Gameplay System** in Godot 4.

---

## 1. Project Overview & Architecture

Zumpa Jump is a portrait-mode platformer built in **Godot 4**. The level architecture is data-driven: levels are saved as lightweight Resource files (`.tres` in `res://Levels/`) and loaded dynamically at runtime.

### Key Components & Data Flow

```
+------------------------------------------------------------------+
|                          LevelData (.tres)                       |
|  - level_id / level_name                                         |
|  - player_start / level_size                                     |
|  - objects: Array[ObjectData]                                    |
+------------------------------------------------------------------+
                                  |
                                  v
+------------------------------------------------------------------+
|                            LevelLoader                           |
|  1. Spawns Player (res://Scenes/Player.tscn)                     |
|  2. Spawns side wall boundaries dynamically                      |
|  3. Iterates over objects -> calls ObjectRegistry.instantiate    |
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

### A. Obstacle 2 Integration (`obs_2.tscn` & `obs_2.gd`)
- **Node & Script**: `res://Obstacle/obs_2.tscn` and `res://obs_2.gd`.
- **Group Registration**: Root `StaticBody2D` belongs to group `"obstacle"`. Contact with player triggers immediate Game Over.
- **Physics Motion**: Performs simultaneous rotation and horizontal sine-wave movement using `rotation_speed`, `move_speed`, and `move_distance`.
- **Registry Entry**: Added `"obs_2"` to [`ObjectRegistry`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_registry.gd) with default properties `{"rotation_speed": 2.0, "move_speed": 100.0, "move_distance": 200.0}`.
- **Editor Inspector Support**: Extended [`level_editor.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/addons/zumpa_level_editor/level_editor.gd) to expose spinboxes for `Move Speed` and `Move Dist` when `obs_2` is selected.

### B. Multi-Level System (`LevelManager.gd`)
- **Directory Scanning**: [`LevelManager`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_manager.gd) scans `res://Levels/` for `.tres` files (`get_all_level_paths()`) sorted in order.
- **Sequential Level Navigation**: Added `get_next_level_path(current_path)` and `load_next_level()`.
- **Default Level Generation**:
  - `level_001.tres`: Level 1 (Platforms, `obs_1`, `win_area`).
  - `level_002.tres`: Level 2 (Platforms, `obs_1`, `obs_2`, `win_area`).

### C. Level Editor Level Selector (`level_editor.gd` & `level_editor.tscn`)
- **Level Dropdown**: Added an `OptionButton` (`LevelSelectOpt`) in the editor top toolbar to quick-switch between saved levels in `res://Levels/`.
- **Auto-Increment Level ID**: Clicking **New** generates the next available level ID (`level_003`, `level_004`, etc.).

### D. Game Win & Progression (`character_body_2d.gd` & `game_play.gd`)
- **Win Screen & Level Progression**: Reaching the `WinArea` opens a win dialog in [`character_body_2d.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/character_body_2d.gd):
  - Displays a **"▶ NEXT LEVEL"** button if another level exists, advancing to Level 2 upon click.
  - Displays **"🏆 ALL LEVELS CLEARED!"** with **"🔄 RESTART FROM LEVEL 1"** if completing the last level.
- **In-Game Level HUD**: Added an overlay label in [`game_play.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/game_play.gd) displaying active level name and ID (e.g. `🎮 Level 1 - Beginning (level_001)`).

---

## 3. Object Registry Reference

All placeable editor objects are registered in [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_registry.gd):

| `object_id` | Display Name | Scene Path | Category | Default Properties |
|---|---|---|---|---|
| `obs_1` | Rotating Obstacle 1 | `res://Obstacle/obs_1.tscn` | Obstacles | `{"rotation_speed": 2.0}` |
| `obs_2` | Moving & Rotating Obstacle 2 | `res://Obstacle/obs_2.tscn` | Obstacles | `{"rotation_speed": 2.0, "move_speed": 100.0, "move_distance": 200.0}` |
| `platform` | Ground Platform | `res://Obstacle/platform.tscn` | Platforms | `{}` |
| `win_area` | Win Area | `res://Scenes/win_area_node.tscn` | Triggers | `{}` |

---

## 4. Key File Map

- **Data Models**:
  - [`Scripts/level_data.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_data.gd) - Level resource class.
  - [`Scripts/object_data.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_data.gd) - Placed object instance class.
  - [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_registry.gd) - Central registry dictionary.

- **System Core**:
  - [`Scripts/level_manager.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_manager.gd) - Multi-level loader, saver, and scanner.
  - [`Scripts/level_loader.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_loader.gd) - Spawns nodes, player, and boundaries into scene tree.

- **Gameplay & Player**:
  - [`Scripts/character_body_2d.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/character_body_2d.gd) - Player movement, obstacle collision, Game Over, and Win UI with Level 1 -> Level 2 transition.
  - [`Scripts/game_play.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/game_play.gd) - Gameplay scene manager with Level HUD.
  - [`Scenes/game_play.tscn`](file:///e:/Zumpa%20Jump/zumpa-editor/Scenes/game_play.tscn) - Main game play scene.

- **Editor Addon**:
  - [`addons/zumpa_level_editor/level_editor.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/addons/zumpa_level_editor/level_editor.gd) - Editor plugin main UI script.
  - [`addons/zumpa_level_editor/level_editor.tscn`](file:///e:/Zumpa%20Jump/zumpa-editor/addons/zumpa_level_editor/level_editor.tscn) - Editor scene layout.
  - [`addons/zumpa_level_editor/level_canvas.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/addons/zumpa_level_editor/level_canvas.gd) - Drag & drop level editing canvas.

- **Obstacles**:
  - [`Obstacle/obs_1.tscn`](file:///e:/Zumpa%20Jump/zumpa-editor/Obstacle/obs_1.tscn) & [`Scripts/obs_1.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/obs_1.gd)
  - [`Obstacle/obs_2.tscn`](file:///e:/Zumpa%20Jump/zumpa-editor/Obstacle/obs_2.tscn) & [`obs_2.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/obs_2.gd)

---

## 5. Instructions for Antigravity AI in New Context

When opening this workspace or pasting context in a new session:
1. Refer to this `PROGRESS_CONTEXT.md` file and `EDITOR_GUIDE.md`.
2. All level `.tres` files reside in `res://Levels/`.
3. To add a new obstacle:
   - Create `.tscn` in `res://Obstacle/` with root node in `"obstacle"` group.
   - Attach script with `@export` properties.
   - Register entry in [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_registry.gd).
