extends Resource
class_name Level

@export var display_name: String = "Level"
@export var grid_width: int = 7
@export var grid_height: int = 7
@export var player_starts: Array[Vector2i] = []
@export var enemy_starts: Array[Vector2i] = []
@export var goal_coords: Array[Vector2i] = []
@export var require_all_units: bool = false
@export var require_units_match_goals: bool = false
@export var initial_rotation: float = 0.0
@export var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
@export var next_level_path: String = ""
