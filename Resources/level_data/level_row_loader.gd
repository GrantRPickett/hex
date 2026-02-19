extends RefCounted
class_name LevelRowLoader

const LevelTerrainData := preload("res://Resources/level_data/level_terrain_data.gd")
const LevelTerrainRow := preload("res://Resources/level_data/level_terrain_row.gd")
const LevelStartRow := preload("res://Resources/level_data/level_start_row.gd")
const LevelDialogueRow := preload("res://Resources/level_data/level_dialogue_row.gd")
const LevelMetaRow := preload("res://Resources/level_data/level_meta_row.gd")
const LevelRosterRow := preload("res://Resources/level_data/level_roster_row.gd")
const LevelLootRow := preload("res://Resources/level_data/level_loot_row.gd")
const LevelTaskRow := preload("res://Resources/level_data/level_task_row.gd")
const LevelUnitSpawnEntry := preload("res://Resources/level_data/level_unit_spawn_entry.gd")
const LevelLootEntry := preload("res://Resources/level_data/level_loot_entry.gd")
const LevelTaskEntry := preload("res://Resources/level_data/level_task_entry.gd")
const UnitRosterDefinition := preload("res://Resources/rosters/unit_roster_definition.gd")
const LevelRowValidator := preload("res://Resources/level_data/level_row_validator.gd")
const LevelJournalEntry := preload("res://Resources/level_data/level_journal_entry.gd")
const LevelAutoFixOptions := preload("res://Resources/level_data/level_auto_fix_options.gd")
const LevelAutoFixService := preload("res://Resources/level_data/level_auto_fix_service.gd")

const DEFAULT_ROSTER_ROWS_PATH := "res://Resources/level_data/roster_rows"
const DEFAULT_LOOT_ROWS_PATH := "res://Resources/level_data/loot_rows"
const DEFAULT_LOCATION_ROWS_PATH := "res://Resources/level_data/location_rows"
const DEFAULT_TERRAIN_ROWS_PATH := "res://Resources/level_data/terrain_rows"
const DEFAULT_START_ROWS_PATH := "res://Resources/level_data/start_rows"
const DEFAULT_DIALOGUE_ROWS_PATH := "res://Resources/level_data/dialogue_rows"
const DEFAULT_META_ROWS_PATH := "res://Resources/level_data/meta_rows"
const DEFAULT_JOURNAL_ROWS_PATH := "res://Resources/level_data/journal_entry_rows"

var _roster_rows_path: String
var _loot_rows_path: String
var _location_rows_path: String
var _terrain_rows_path: String
var _start_rows_path: String
var _dialogue_rows_path: String
var _meta_rows_path: String
var _journal_rows_path: String

var _roster_rows_by_level: Dictionary = {}
var _loot_rows_by_level: Dictionary = {}
var _location_rows_by_level: Dictionary = {}
var _terrain_rows_by_level: Dictionary = {}
var _start_rows_by_level: Dictionary = {}
var _dialogue_rows_by_level: Dictionary = {}
var _meta_rows_by_level: Dictionary = {}
var _journal_rows_by_level: Dictionary = {} # Added this line

var _validator: LevelRowValidator

var _auto_fix_options: LevelAutoFixOptions
var _auto_fix_service: LevelAutoFixService

func _init(roster_rows_path := DEFAULT_ROSTER_ROWS_PATH, loot_rows_path := DEFAULT_LOOT_ROWS_PATH, location_rows_path := DEFAULT_LOCATION_ROWS_PATH, terrain_rows_path := DEFAULT_TERRAIN_ROWS_PATH, start_rows_path := DEFAULT_START_ROWS_PATH, dialogue_rows_path := DEFAULT_DIALOGUE_ROWS_PATH, journal_rows_path := DEFAULT_JOURNAL_ROWS_PATH, meta_rows_path := DEFAULT_META_ROWS_PATH) -> void:
	_roster_rows_path = roster_rows_path
	_loot_rows_path = loot_rows_path
	_location_rows_path = location_rows_path
	_terrain_rows_path = terrain_rows_path
	_start_rows_path = start_rows_path
	_dialogue_rows_path = dialogue_rows_path
	_meta_rows_path = meta_rows_path
	_journal_rows_path = journal_rows_path
	_validator = LevelRowValidator.new()
	_auto_fix_options = LevelAutoFixOptions.new()
	_auto_fix_service = null
	refresh()

func refresh() -> void:
	print_debug("[LevelRowLoader] Refreshing row data...")
	_roster_rows_by_level.clear()
	_loot_rows_by_level.clear()
	_location_rows_by_level.clear()
	_terrain_rows_by_level.clear()
	_start_rows_by_level.clear()
	_dialogue_rows_by_level.clear()
	_meta_rows_by_level.clear()
	_journal_rows_by_level.clear()

	_load_all_rows()
	print_debug("[LevelRowLoader] Refresh complete.")

func _load_all_rows() -> void:
	var configs := [
		{"path": _roster_rows_path, "type": LevelRosterRow, "target": _roster_rows_by_level},
		{"path": _loot_rows_path, "type": LevelLootRow, "target": _loot_rows_by_level},
		{"path": _location_rows_path, "type": LevelTaskRow, "target": _location_rows_by_level},
		{"path": _terrain_rows_path, "type": LevelTerrainRow, "target": _terrain_rows_by_level},
		{"path": _start_rows_path, "type": LevelStartRow, "target": _start_rows_by_level},
		{"path": _dialogue_rows_path, "type": LevelDialogueRow, "target": _dialogue_rows_by_level},
		{"path": _meta_rows_path, "type": LevelMetaRow, "target": _meta_rows_by_level},
		{"path": _journal_rows_path, "type": LevelJournalEntry, "target": _journal_rows_by_level},
	]

	for config in configs:
		var path: String = config["path"]
		var type: Script = config["type"]
		var target: Dictionary = config["target"]
		var rows := _load_rows_by_level(path, type)
		for level_key in rows:
			if not target.has(level_key):
				target[level_key] = []
			target[level_key].append_array(rows[level_key])

func set_row_sources(roster_rows: Array = [], loot_rows: Array = [], location_rows: Array = [], terrain_rows: Array = [], start_rows: Array = [], dialogue_rows: Array = [], meta_rows: Array = []) -> void:
	_roster_rows_by_level = _group_rows_by_level(roster_rows)
	_loot_rows_by_level = _group_rows_by_level(loot_rows)
	_location_rows_by_level = _group_rows_by_level(location_rows)
	_terrain_rows_by_level = _group_rows_by_level(terrain_rows)
	_start_rows_by_level = _group_rows_by_level(start_rows)
	_dialogue_rows_by_level = _group_rows_by_level(dialogue_rows)
	_meta_rows_by_level = _group_rows_by_level(meta_rows)

func set_auto_fix_options(options: LevelAutoFixOptions) -> void:
	_auto_fix_options = options if options != null else LevelAutoFixOptions.new()
	if _auto_fix_service == null and _auto_fix_options.enabled:
		_auto_fix_service = LevelAutoFixService.new()

func apply_rows_to_level(level: Level, level_id: StringName) -> Dictionary:
	if level == null:
		print_debug("[LevelRowLoader] apply_rows_to_level called with null level")
		return {"errors": []}
	var level_key := String(level_id)
	print_debug("[LevelRowLoader] Applying rows to level: %s" % level_key)
	if level_key.is_empty():
		print_debug("[LevelRowLoader] Level ID is empty")
		return {"errors": []}

	var rows := _rows_for_level(level_key)
	var roster_rows: Array = rows["roster"]
	var loot_rows: Array = rows["loot"]
	var location_rows: Array = rows["locations"]
	var terrain_rows: Array = rows["terrain"]
	var start_rows: Array = rows["start"]
	var dialogue_rows: Array = rows["dialogue"]
	var journal_rows: Array = rows["journal"]
	var meta_rows: Array = rows["meta"]

	print_debug("[LevelRowLoader] Found rows for %s: Roster=%d, Loot=%d, Locations=%d, Terrain=%d, Start=%d, Dialogue=%d, Journal=%d, Meta=%d" % [level_key, roster_rows.size(), loot_rows.size(), location_rows.size(), terrain_rows.size(), start_rows.size(), dialogue_rows.size(), journal_rows.size(), meta_rows.size()])

	_apply_meta_rows(level, meta_rows)
	_apply_terrain_rows(level, terrain_rows)
	_apply_start_rows(level, start_rows)
	_apply_dialogue_rows(level, dialogue_rows)
	level.journal_entries = _build_journal_entries(journal_rows) # Added this line

	_apply_combat_rows(level, roster_rows, loot_rows, location_rows)
	return _validate_and_autofix(level, level_id, rows)

func _rows_for_level(level_key: String) -> Dictionary:
	return {
		"roster": _roster_rows_by_level.get(level_key, []),
		"loot": _loot_rows_by_level.get(level_key, []),
		"locations": _location_rows_by_level.get(level_key, []),
		"terrain": _terrain_rows_by_level.get(level_key, []),
		"start": _start_rows_by_level.get(level_key, []),
		"dialogue": _dialogue_rows_by_level.get(level_key, []),
		"meta": _meta_rows_by_level.get(level_key, []),
		"journal": _journal_rows_by_level.get(level_key, []),
	}

func _apply_combat_rows(level: Level, roster_rows: Array, loot_rows: Array, location_rows: Array) -> void:
	var rosters_by_faction := _group_roster_rows_by_faction(roster_rows)
	var existing_enemy := level.enemy_roster_definition
	var existing_neutral := level.neutral_roster_definition
	level.enemy_roster_definition = _build_roster_definition(rosters_by_faction.get(&"enemy", []))
	if level.enemy_roster_definition == null:
		level.enemy_roster_definition = existing_enemy
	level.neutral_roster_definition = _build_roster_definition(rosters_by_faction.get(&"neutral", []))
	if level.neutral_roster_definition == null:
		level.neutral_roster_definition = existing_neutral

	level.loot = _build_loot_definition(loot_rows)
	level.locations = _build_location_entries(location_rows)

func _validate_and_autofix(level: Level, level_id: StringName, rows: Dictionary) -> Dictionary:
	var roster_rows: Array = rows["roster"]
	var loot_rows: Array = rows["loot"]
	var location_rows: Array = rows["locations"]
	var terrain_rows: Array = rows["terrain"]
	var start_rows: Array = rows["start"]
	var dialogue_rows: Array = rows["dialogue"]
	var journal_rows: Array = rows["journal"]
	var meta_rows: Array = rows["meta"]

	var errors := _validator.validate(level, level_id, roster_rows, loot_rows, location_rows, terrain_rows, start_rows, dialogue_rows, journal_rows, meta_rows)
	var result: Dictionary = {"errors": errors}
	var should_fix := _auto_fix_options != null and _auto_fix_options.enabled
	if should_fix:
		if _auto_fix_service == null:
			_auto_fix_service = LevelAutoFixService.new()
		var report: Dictionary = _auto_fix_service.apply(level, level_id, roster_rows, location_rows, start_rows, _auto_fix_options)
		if report:
			result["auto_fix"] = report
	return result

func _apply_meta_rows(level: Level, rows: Array) -> void:
	if rows.is_empty():
		return
	var meta: LevelMetaRow = rows[0]
	level.initial_rotation = meta.initial_rotation
	level.hex_offset_axis = meta.hex_offset_axis

func _apply_terrain_rows(level: Level, rows: Array) -> void:
	if level.terrain_data == null:
		level.terrain_data = LevelTerrainData.new()
	if rows.is_empty():
		print_debug("[LevelRowLoader] No terrain rows to apply.")
		return
	var sorted := rows.duplicate()
	sorted.sort_custom(func(a: LevelTerrainRow, b: LevelTerrainRow): return a.row_index < b.row_index)
	var data: Array[String] = []
	var width := 0
	for row in sorted:
		if row == null:
			continue
		data.append(row.row_data)
		width = max(width, row.row_data.length())
	if width <= 0:
		width = level.terrain_data.grid_width
	if width <= 0:
		width = 1
	level.terrain_data.grid_width = width
	level.terrain_data.grid_height = max(data.size(), 1)
	level.terrain_data.terrain_rows = data

	# Populate terrain colors
	var terrain_map := TerrainMap.new()
	var unique_codes := {}
	for row_str in data:
		for i in range(row_str.length()):
			unique_codes[row_str.substr(i, 1)] = true

	level.terrain_data.terrain_colors = {}
	for code in unique_codes:
		level.terrain_data.terrain_colors[code] = terrain_map.get_color_for_code(code)
	print_debug("[LevelRowLoader] Applied terrain grid: %dx%d" % [level.terrain_data.grid_width, level.terrain_data.grid_height])

func _apply_start_rows(level: Level, rows: Array) -> void:
	if rows.is_empty():
		print_debug("[LevelRowLoader] No start rows to apply.")
		return
	var sorted := rows.duplicate()
	sorted.sort_custom(func(a: LevelStartRow, b: LevelStartRow): return a.slot_index < b.slot_index)
	var player_coords: Array[Vector2i] = []
	var neutral_entries: Array[LevelUnitSpawnEntry] = []
	var enemy_entries: Array[LevelUnitSpawnEntry] = []
	for row in sorted:
		if row == null:
			continue
		var faction: StringName = row.faction if row.faction != StringName("") else &"player"
		if faction == &"player":
			player_coords.append(row.coord)
			continue
		if row.unit_scene == null:
			continue
		var entry := LevelUnitSpawnEntry.new()
		entry.coord = row.coord
		entry.unit_scene = row.unit_scene
		if faction == &"neutral":
			neutral_entries.append(entry)
		elif faction == &"enemy":
			enemy_entries.append(entry)
	level.player_starts = player_coords
	level.set("neutral_spawns", neutral_entries)
	level.set("enemy_spawns", enemy_entries)
	print_debug("[LevelRowLoader] Applied start rows: %d Player, %d Neutral, %d Enemy" % [player_coords.size(), neutral_entries.size(), enemy_entries.size()])

func _apply_dialogue_rows(level: Level, rows: Array) -> void:
	var entries: Array[LevelDialogueEntry] = []
	for row in rows:
		if row == null:
			continue
		var entry := LevelDialogueEntry.new()
		_create_common_level_entry(row, entry)
		entries.append(entry)
	level.dialogue_entries = entries

func _build_journal_entries(rows: Array) -> Array[LevelJournalEntry]:
	var entries: Array[LevelJournalEntry] = []
	for row in rows:
		if row == null:
			continue
		var entry := row.duplicate(true) as LevelJournalEntry
		if entry:
			entries.append(entry)
	return entries


func _create_common_level_entry(row, entry) -> void:
	entry.entry_id = row.entry_id
	entry.initiator_name = row.initiator_name
	entry.partner_name = row.partner_name
	entry.partner_faction = row.partner_faction
	entry.coord = row.coord
	entry.dialogue_resource_path = row.dialogue_resource_path
	entry.flag_name = row.flag_name
	entry.action_label = row.action_label
	entry.action_hint = row.action_hint
	entry.repeatable = row.repeatable
	entry.requires_adjacent = row.requires_adjacent
	entry.consume_action = row.consume_action
	entry.group_id = row.group_id
	entry.allow_partner_initiation = row.allow_partner_initiation

func _load_rows_by_level(path: String, expected_type: Script) -> Dictionary:
	var grouped: Dictionary = {}
	var files := _list_resource_files(path)
	var count := 0
	for resource_path in files:
		if resource_path.find("/templates/") != -1:
			continue
		var row = load(resource_path)
		if row == null:
			push_error("Failed to load resource: %s" % resource_path)
			continue
		var actual_script: Script = row.get_script()
		if not is_instance_of(row, expected_type): # Check if the loaded row is an instance of the expected type
			var skip_dialogue_entry := expected_type == LevelDialogueRow and row is LevelDialogueEntry
			if skip_dialogue_entry:
				continue
			var actual_type_name := "<unknown>"
			if row:
				if row.has_method("get_class"):
					actual_type_name = row.get_class()
				elif row.get_script() != null:
					actual_type_name = row.get_script().resource_path

			var expected_path := "<unknown>" if expected_type == null else expected_type.resource_path
			push_warning("[LevelRowLoader] Resource %s has unexpected type: %s, expected: %s" % [resource_path, actual_type_name, expected_path])
			continue
		var level_key := String(row.level_id)
		if level_key.is_empty():
			continue
		if not grouped.has(level_key):
			grouped[level_key] = []
		grouped[level_key].append(row)
		count += 1
	print_debug("[LevelRowLoader] Loaded %d rows of type %s from %s" % [count, expected_type, path])
	return grouped

func _list_resource_files(path: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return results
	dir.list_dir_begin()
	while true:
		var name = dir.get_next()
		if name == "":
			break
		if name == "." or name == "..":
			continue
		if dir.current_is_dir():
			results += _list_resource_files(path + "/" + name)
		else:
			if name.ends_with(".tres"):
				results.append(path + "/" + name)
	dir.list_dir_end()
	return results

func _group_rows_by_level(rows: Array) -> Dictionary:
	var grouped: Dictionary = {}
	for row in rows:
		if row == null:
			continue
		var level_key := String(row.level_id)
		if level_key.is_empty():
			continue
		if not grouped.has(level_key):
			grouped[level_key] = []
		grouped[level_key].append(row)
	return grouped

func _group_roster_rows_by_faction(rows: Array) -> Dictionary:
	var grouped: Dictionary = {}
	for row in rows:
		if row == null:
			continue
		var faction_key: StringName = row.faction if row.faction != StringName("") else &"enemy"
		if not grouped.has(faction_key):
			grouped[faction_key] = []
		grouped[faction_key].append(row)
	return grouped

func _build_roster_definition(rows: Array) -> UnitRosterDefinition:
	if rows.is_empty():
		return null
	var definition := UnitRosterDefinition.new()
	definition.spawn_entries = []
	for row in rows:
		if row == null or row.unit_scene == null:
			continue
		var entry := LevelUnitSpawnEntry.new()
		entry.coord = row.coord
		entry.unit_scene = row.unit_scene
		definition.spawn_entries.append(entry)
	return definition if not definition.spawn_entries.is_empty() else null

func _build_loot_definition(rows: Array) -> Array[LevelLootEntry]:
	var entries: Array[LevelLootEntry] = []
	for row in rows:
		if row == null or row.items.is_empty():
			continue
		var loot_entry := LevelLootEntry.new()
		loot_entry.coord = row.coord
		loot_entry.items = row.items.duplicate()
		entries.append(loot_entry)
	return entries

func _build_location_entries(rows: Array) -> Array[LevelTaskEntry]:
	var locations: Array[LevelTaskEntry] = []
	for row in rows:
		if row == null or row.location_scene == null:
			continue
		var entry := LevelTaskEntry.new()
		entry.coord = row.coord
		entry.location_scene = row.location_scene
		locations.append(entry)
	return locations
