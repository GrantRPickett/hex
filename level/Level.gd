extends Resource
class_name Level

const DEFAULT_LOCATION_SCENE := preload("res://Gameplay/scene_templates/location.tscn")

@export var display_name: String = "Level"
@export var level_id: String = ""
@export var terrain_data: LevelTerrainData
@export var player_starts: Array[Vector2i] = []
@export var enemy_roster_definition: UnitRosterDefinition
@export var neutral_roster_definition: UnitRosterDefinition
@export var locations: Array[LevelTaskEntry] = []
@export var global_tasks: Array[TaskDefinition] = []
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


var location_coords: Array[Vector2i]:
	set(value):
		_set_location_coords(value)
	get:
		return _legacy_location_coords.duplicate()

@export var initial_rotation: float = 0.0
@export var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL

var _legacy_location_coords: Array[Vector2i] = []

func _init() -> void:
	_ensure_default_terrain_data()

func _set_location_coords(value: Array[Vector2i]) -> void:
	_legacy_location_coords.clear()
	if value:
		_legacy_location_coords.assign(value)
	_regenerate_location_entries_from_coords()

func _ensure_default_terrain_data() -> void:
	if terrain_data == null:
		terrain_data = LevelTerrainData.new()
	if terrain_data.grid_width <= 0:
		terrain_data.grid_width = 7
	if terrain_data.grid_height <= 0:
		terrain_data.grid_height = 7
	if terrain_data.terrain_rows.is_empty():
		var safe_width: int = max(terrain_data.grid_width, 1)
		var safe_height: int = max(terrain_data.grid_height, 1)
		var row: String = "G".repeat(safe_width)
		terrain_data.terrain_rows = []
		for _i in range(safe_height):
			terrain_data.terrain_rows.append(row)

func _regenerate_location_entries_from_coords() -> void:
	locations.clear()
	if _legacy_location_coords.is_empty():
		return
	for coord in _legacy_location_coords:
		var entry := LevelTaskEntry.new()
		entry.coord = coord
		entry.location_scene = DEFAULT_LOCATION_SCENE
		locations.append(entry)
