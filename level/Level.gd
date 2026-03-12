extends Resource
class_name Level

const DEFAULT_LOCATION_SCENE := preload(FilePaths.Scenes.LOCATION_TEMPLATE)

@export var display_name: String = "Level"
@export var level_id: String = ""
@export var terrain_data: LevelTerrainData
@export var player_starts: Array[Vector2i] = [] # Legacy: Use player_spawns instead
@export var player_spawns: Array[LevelUnitSpawnEntry] = [] # Source of truth for player spawning
@export var enemy_roster_definition: UnitRosterDefinition
@export var neutral_roster_definition: UnitRosterDefinition
@export var enemy_spawns: Array[LevelUnitSpawnEntry] = []
@export var neutral_spawns: Array[LevelUnitSpawnEntry] = []
@export var locations: Array[LevelTaskEntry] = []
@export var objective: Objective
@export var loot: Array[LevelLootEntry] = []
@export var dialogue_entries: Array[LevelDialogueEntry] = []
@export var journal_entries: Array[LevelJournalEntry] = []
@export var dialogue_journal_entries: Array[LevelDialogueJournalEntry] = []
@export var _level_prefix_override: String = ""

var dialogue_prefix: String:
	get:
		# Try to use level_id first
		if not level_id.is_empty():
			return level_id
		# Fall back to resource path
		if resource_path.is_empty():
			return ""
		var level_name = resource_path.get_file().trim_suffix(".tres")
		return level_name


var level_prefix: String:
	get:
		# If an override is set, use it
		if not _level_prefix_override.is_empty():
			return _level_prefix_override
		# Otherwise, try to use level_id
		if not level_id.is_empty():
			return level_id
		# Fall back to resource path
		if resource_path.is_empty():
			return ""
		var level_name = resource_path.get_file().trim_suffix(".tres")
		return level_name
	set(value):
		_level_prefix_override = value

@export var initial_rotation: float = 0.0
@export var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL


func _init() -> void:
	_ensure_default_terrain_data()

func _ensure_default_terrain_data() -> void:
	if terrain_data == null:
		terrain_data = LevelTerrainData.new()
	if terrain_data.grid_width <= 0:
		terrain_data.grid_width = GameConfig.DEFAULT_GRID_WIDTH
	if terrain_data.grid_height <= 0:
		terrain_data.grid_height = GameConfig.DEFAULT_GRID_HEIGHT
	if terrain_data.terrain_rows.is_empty():
		var safe_width: int = max(terrain_data.grid_width, 1)
		var safe_height: int = max(terrain_data.grid_height, 1)
		var row: String = "G".repeat(safe_width)
		terrain_data.terrain_rows = []
		for _i in range(safe_height):
			terrain_data.terrain_rows.append(row)

func _regenerate_location_entries_from_coords() -> void:
	locations.clear()
	var entry := LevelTaskEntry.new()
	entry.location_scene = DEFAULT_LOCATION_SCENE
	locations.append(entry)
