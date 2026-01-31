extends Resource
class_name Level

const LevelTerrainData = preload("res://Resources/level_data/level_terrain_data.gd")
const EnemyRosterDefinition = preload("res://Resources/rosters/enemy_roster_definition.gd")
const LootListDefinition = preload("res://Resources/loot_lists/loot_list_definition.gd")
const UnitRosterDefinition = preload("res://Resources/rosters/unit_roster_definition.gd")


@export var display_name: String = "Level"
@export var terrain_data: LevelTerrainData
@export var player_starts: Array[Vector2i] = []
@export var enemy_roster_definition: UnitRosterDefinition
@export var neutral_roster_definition: UnitRosterDefinition
@export var goals: Array[LevelGoalEntry] = []
@export var loot_list_definition: LootListDefinition

@export var require_all_units: bool = false
@export var require_units_match_goals: bool = false
@export var initial_rotation: float = 0.0
@export var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
@export var next_level_path: String = ""
