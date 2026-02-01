extends Resource
class_name LevelMetaRow

@export var level_id: StringName = StringName("")
@export var require_all_units: bool = false
@export var require_units_match_goals: bool = false
@export var initial_rotation: float = 0.0
@export var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
@export var next_level_path: String = ""
@export var notes: String = ""
