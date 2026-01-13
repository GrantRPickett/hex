class_name Level
extends Resource

@export var display_name: String = ""
@export var grid_width: int = 7
@export var grid_height: int = 7
@export var player_starts: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
@export var goal_coords: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 3)]
@export var require_all_units: bool = false
@export var initial_camera_rotation: float = 0.0 # radians
@export var hex_offset_axis: int = 1 # 0 or 1; flips flat-top/point-top
@export var require_units_match_goals: bool = false
