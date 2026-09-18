# Zumpa Editor Guide & Documentation

This document explains the architecture of the **Zumpa Jump Level Editor** system, how levels and objects are structured, and step-by-step instructions on how to add a new obstacle to the editor.

---

## 1. How the Editor Works

The Zumpa Editor is built around a data-driven node instantiation architecture in Godot 4. Instead of manually placing scene nodes in every level, levels are saved as lightweight data resources (`.tres`) and constructed dynamically at runtime.

### Key Architecture Components

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

1. **[`ObjectData`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_data.gd)**
   - Represents a single object instance placed in a level.
   - Stores: `object_id`, `position`, `rotation`, `scale`, and a `properties` dictionary (for custom runtime properties like `rotation_speed`).

2. **[`LevelData`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_data.gd)**
   - The primary resource holding level configurations (`level_id`, `level_name`, `player_start`, `level_size`, and an array of `ObjectData` entries).

3. **[`ObjectRegistry`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_registry.gd)**
   - Central dictionary mapping `object_id` strings (e.g. `"obs_1"`, `"platform"`, `"win_area"`) to:
	 - `name`: Display Name
	 - `scene_path`: Path to Godot scene (`res://Obstacle/...`)
	 - `category`: Group classification (`Obstacles`, `Platforms`, `Triggers`)
	 - `default_properties`: Dictionary of default property values
	 - `default_scale`: Base scale `Vector2`
   - Supplies `instantiate_object(id)` to load and instantiate packed scenes.

4. **[`LevelLoader`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_loader.gd)**
   - Takes a `LevelData` resource and a parent container node (`$LevelRoot`).
   - Clears existing nodes, spawns the player at `player_start`, generates side wall boundaries, instantiates each `ObjectData` using `ObjectRegistry`, and applies overrides (position, rotation, scale, custom properties).

5. **[`LevelManager`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_manager.gd)**
   - Manages saving and loading of `.tres` level files via Godot's `ResourceSaver` and `ResourceLoader`.

---

## 2. How to Add a New Obstacle to the Editor

Follow these **4 steps** to create and register a new obstacle in the Zumpa Editor.

---

### Step 1: Create the Obstacle Scene & Script

1. **Create Scene**: Create a new PackedScene in Godot and save it in `res://Obstacle/` (e.g. `res://Obstacle/obs_2.tscn`).
2. **Node Hierarchy Example**:
   ```
   StaticBody2D (or Area2D)  <-- Add to group "obstacle"
   ├── Sprite2D (or AnimatedSprite2D)
   └── CollisionShape2D
   ```
3. **Assign to Group**: In Godot's Node inspector tab, add the root node to the `"obstacle"` group (or assign in script `add_to_group("obstacle")`) so the player detects collision and triggers game over.
4. **Attach Script**: Create a script (e.g. `res://Scripts/obs_2.gd`) and attach it to the root node. Define any customizable parameters using `@export`:

```gdscript
extends StaticBody2D

@export var move_speed: float = 100.0
@export var move_distance: float = 200.0

var start_x: float = 0.0
var direction: int = 1

func _ready() -> void:
	start_x = position.x
	add_to_group("obstacle")

func _physics_process(delta: float) -> void:
	position.x += direction * move_speed * delta
	if abs(position.x - start_x) >= move_distance:
		direction *= -1
```

---

### Step 2: Register the Obstacle in `ObjectRegistry`

Open [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_registry.gd) and add your new obstacle entry to the `_registry` dictionary:

```gdscript
static var _registry: Dictionary = {
	"obs_1": {
		"id": "obs_1",
		"name": "Rotating Obstacle 1",
		"scene_path": "res://Obstacle/obs_1.tscn",
		"category": "Obstacles",
		"default_properties": {"rotation_speed": 2.0},
		"default_scale": Vector2(1, 1)
	},
	"obs_2": {
		"id": "obs_2",
		"name": "Moving Obstacle 2",
		"scene_path": "res://Obstacle/obs_2.tscn",
		"category": "Obstacles",
		"default_properties": {"move_speed": 100.0, "move_distance": 200.0},
		"default_scale": Vector2(1, 1)
	},
	"platform": {
		"id": "platform",
		"name": "Ground Platform",
		"scene_path": "res://Obstacle/platform.tscn",
		"category": "Platforms",
		"default_properties": {},
		"default_scale": Vector2(1, 1)
	},
	"win_area": {
		"id": "win_area",
		"name": "Win Area",
		"scene_path": "res://Scenes/win_area_node.tscn",
		"category": "Triggers",
		"default_properties": {},
		"default_scale": Vector2(1, 1)
	}
}
```

*Alternative*: You can also call `ObjectRegistry.register_object()` dynamically at runtime if registered from an plugin or external script:

```gdscript
ObjectRegistry.register_object(
	"obs_2",
	"Moving Obstacle 2",
	"res://Obstacle/obs_2.tscn",
	"Obstacles",
	{"move_speed": 100.0, "move_distance": 200.0},
	Vector2(1, 1)
)
```

---

### Step 3: Add the Obstacle to a Level

You can add the new obstacle to a level either in GDScript or by adding it inside level resource files (`.tres`).

#### In GDScript:
```gdscript
var new_obstacle = ObjectData.new(
	"obs_2",                            # object_id matching registry
	Vector2(500, 800),                  # Position
	0.0,                                # Rotation in degrees
	Vector2(1, 1),                      # Scale
	{"move_speed": 150.0, "move_distance": 300.0} # Custom property overrides
)

level_data.add_object(new_obstacle)
LevelManager.save_level_data(level_data, "res://Levels/level_001.tres")
```

#### In Level `.tres` Files:
```ini
[sub_resource type="Resource" id="Resource_obs2"]
script = ExtResource("2_obj")
object_id = "obs_2"
position = Vector2(500, 800)
properties = {
"move_distance": 300.0,
"move_speed": 150.0
}
```

---

### Step 4: Verify and Load

When [`LevelLoader.load_level()`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_loader.gd) runs:
1. `ObjectRegistry.instantiate_object("obs_2")` creates an instance of `res://Obstacle/obs_2.tscn`.
2. `LevelLoader` assigns `position`, `rotation_degrees`, and `scale`.
3. `LevelLoader` iterates over `properties` dictionary (`move_speed`, `move_distance`) and sets `node.set(prop_name, prop_value)`.
4. The node is added to the level container tree automatically!

---

## Summary Checklist for Adding Obstacles

- [ ] Save scene to `res://Obstacle/your_obstacle.tscn`
- [ ] Add root node to group `"obstacle"` for player collision handling
- [ ] Script with exported property variables (`@export`)
- [ ] Add entry in [`Scripts/object_registry.gd`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/object_registry.gd)
- [ ] Instantiated automatically via [`LevelLoader`](file:///e:/Zumpa%20Jump/zumpa-editor/Scripts/level_loader.gd)
