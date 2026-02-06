extends RefCounted
class_name LevelRowLoader

const LevelTerrainData := preload("res://Resources/level_data/level_terrain_data.gd")
const LevelTerrainRow := preload("res://Resources/level_data/level_terrain_row.gd")
const LevelStartRow := preload("res://Resources/level_data/level_start_row.gd")
const LevelDialogueRow := preload("res://Resources/level_data/level_dialogue_row.gd")
const LevelMetaRow := preload("res://Resources/level_data/level_meta_row.gd")
const LevelRosterRow := preload("res://Resources/level_data/level_roster_row.gd")
const LevelLootRow := preload("res://Resources/level_data/level_loot_row.gd")
const LevelGoalRow := preload("res://Resources/level_data/level_goal_row.gd")
const LevelUnitSpawnEntry := preload("res://Resources/level_data/level_unit_spawn_entry.gd")
const LevelLootEntry := preload("res://Resources/level_data/level_loot_entry.gd")
const LevelGoalEntry := preload("res://Resources/level_data/level_goal_entry.gd")
const LevelDialogueEntry := preload("res://Resources/level_data/level_dialogue_entry.gd")
const UnitRosterDefinition := preload("res://Resources/rosters/unit_roster_definition.gd")
const LootListDefinition := preload("res://Resources/loot_lists/loot_list_definition.gd")
const LevelRowValidator := preload("res://Resources/level_data/level_row_validator.gd")

const LevelAutoFixOptions := preload("res://Resources/level_data/level_auto_fix_options.gd")
const LevelAutoFixService := preload("res://Resources/level_data/level_auto_fix_service.gd")

const DEFAULT_ROSTER_ROWS_PATH := "res://Resources/level_data/roster_rows"
const DEFAULT_LOOT_ROWS_PATH := "res://Resources/level_data/loot_rows"
const DEFAULT_GOAL_ROWS_PATH := "res://Resources/level_data/goal_rows"
const DEFAULT_TERRAIN_ROWS_PATH := "res://Resources/level_data/terrain_rows"
const DEFAULT_START_ROWS_PATH := "res://Resources/level_data/start_rows"
const DEFAULT_DIALOGUE_ROWS_PATH := "res://Resources/level_data/dialogue_rows"
const DEFAULT_META_ROWS_PATH := "res://Resources/level_data/meta_rows"

var _roster_rows_path: String
var _loot_rows_path: String
var _goal_rows_path: String
var _terrain_rows_path: String
var _start_rows_path: String
var _dialogue_rows_path: String
var _meta_rows_path: String

var _roster_rows_by_level: Dictionary = {}
var _loot_rows_by_level: Dictionary = {}
var _goal_rows_by_level: Dictionary = {}
var _terrain_rows_by_level: Dictionary = {}
var _start_rows_by_level: Dictionary = {}
var _dialogue_rows_by_level: Dictionary = {}
var _meta_rows_by_level: Dictionary = {}

var _validator: LevelRowValidator

var _auto_fix_options: LevelAutoFixOptions
var _auto_fix_service: LevelAutoFixService

func _init(roster_rows_path := DEFAULT_ROSTER_ROWS_PATH, loot_rows_path := DEFAULT_LOOT_ROWS_PATH, goal_rows_path := DEFAULT_GOAL_ROWS_PATH, terrain_rows_path := DEFAULT_TERRAIN_ROWS_PATH, start_rows_path := DEFAULT_START_ROWS_PATH, dialogue_rows_path := DEFAULT_DIALOGUE_ROWS_PATH, meta_rows_path := DEFAULT_META_ROWS_PATH) -> void:
	_roster_rows_path = roster_rows_path
	_loot_rows_path = loot_rows_path
	_goal_rows_path = goal_rows_path
	_terrain_rows_path = terrain_rows_path
	_start_rows_path = start_rows_path
	_dialogue_rows_path = dialogue_rows_path
	_meta_rows_path = meta_rows_path
	_validator = LevelRowValidator.new()
	_auto_fix_options = LevelAutoFixOptions.new()
	_auto_fix_service = null
	refresh()

func refresh() -> void:
	_roster_rows_by_level = _load_rows_by_level(_roster_rows_path, LevelRosterRow)
	_loot_rows_by_level = _load_rows_by_level(_loot_rows_path, LevelLootRow)
	_goal_rows_by_level = _load_rows_by_level(_goal_rows_path, LevelGoalRow)
	_terrain_rows_by_level = _load_rows_by_level(_terrain_rows_path, LevelTerrainRow)
	_start_rows_by_level = _load_rows_by_level(_start_rows_path, LevelStartRow)
	_dialogue_rows_by_level = _load_rows_by_level(_dialogue_rows_path, LevelDialogueRow)
	_meta_rows_by_level = _load_rows_by_level(_meta_rows_path, LevelMetaRow)

func set_row_sources(roster_rows: Array = [], loot_rows: Array = [], goal_rows: Array = [], terrain_rows: Array = [], start_rows: Array = [], dialogue_rows: Array = [], meta_rows: Array = []) -> void:
	_roster_rows_by_level = _group_rows_by_level(roster_rows)
	_loot_rows_by_level = _group_rows_by_level(loot_rows)
	_goal_rows_by_level = _group_rows_by_level(goal_rows)
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
		return {"errors": []}
	var level_key := String(level_id)
	if level_key.is_empty():
		return {"errors": []}

	var rows := _rows_for_level(level_key)
	var roster_rows: Array = rows["roster"]
	var loot_rows: Array = rows["loot"]
	var goal_rows: Array = rows["goals"]
	var terrain_rows: Array = rows["terrain"]
	var start_rows: Array = rows["start"]
	var dialogue_rows: Array = rows["dialogue"]
	var meta_rows: Array = rows["meta"]

	_apply_meta_rows(level, meta_rows)
	_apply_terrain_rows(level, terrain_rows)
	_apply_start_rows(level, start_rows)
	_apply_dialogue_rows(level, dialogue_rows)

	var had_existing_loot := _apply_combat_rows(level, roster_rows, loot_rows, goal_rows)
	return _validate_and_autofix(level, level_id, rows, had_existing_loot)

func _rows_for_level(level_key: String) -> Dictionary:
	return {
		"roster": _roster_rows_by_level.get(level_key, []),
		"loot": _loot_rows_by_level.get(level_key, []),
		"goals": _goal_rows_by_level.get(level_key, []),
		"terrain": _terrain_rows_by_level.get(level_key, []),
		"start": _start_rows_by_level.get(level_key, []),
		"dialogue": _dialogue_rows_by_level.get(level_key, []),
		"meta": _meta_rows_by_level.get(level_key, []),
	}

func _apply_combat_rows(level: Level, roster_rows: Array, loot_rows: Array, goal_rows: Array) -> bool:
	var rosters_by_faction := _group_roster_rows_by_faction(roster_rows)
	var existing_enemy := level.enemy_roster_definition
	var existing_neutral := level.neutral_roster_definition
	level.enemy_roster_definition = _build_roster_definition(rosters_by_faction.get(&"enemy", []))
	if level.enemy_roster_definition == null:
		level.enemy_roster_definition = existing_enemy
	level.neutral_roster_definition = _build_roster_definition(rosters_by_faction.get(&"neutral", []))
	if level.neutral_roster_definition == null:
		level.neutral_roster_definition = existing_neutral

	var had_existing_loot := level.loot_list_definition != null and level.loot_list_definition.loot_entries.size() > 0
	level.loot_list_definition = _build_loot_definition(loot_rows)
	level.goals = _build_goal_entries(goal_rows)
	return had_existing_loot

func _validate_and_autofix(level: Level, level_id: StringName, rows: Dictionary, had_existing_loot: bool) -> Dictionary:
	var roster_rows: Array = rows["roster"]
	var loot_rows: Array = rows["loot"]
	var goal_rows: Array = rows["goals"]
	var terrain_rows: Array = rows["terrain"]
	var start_rows: Array = rows["start"]
	var dialogue_rows: Array = rows["dialogue"]
	var meta_rows: Array = rows["meta"]

	var errors := _validator.validate(level, level_id, roster_rows, loot_rows, goal_rows, terrain_rows, start_rows, dialogue_rows, meta_rows, had_existing_loot)
	var result: Dictionary = {"errors": errors}
	var should_fix := _auto_fix_options != null and _auto_fix_options.enabled
	if should_fix:
		if _auto_fix_service == null:
			_auto_fix_service = LevelAutoFixService.new()
		var report: Dictionary = _auto_fix_service.apply(level, level_id, roster_rows, goal_rows, start_rows, _auto_fix_options)
		if report:
			result["auto_fix"] = report
	return result

func _apply_meta_rows(level: Level, rows: Array) -> void:
	if rows.is_empty():
		return
	var meta: LevelMetaRow = rows[0]
	level.require_all_units = meta.require_all_units
	level.require_units_match_goals = meta.require_units_match_goals
	level.initial_rotation = meta.initial_rotation
	level.hex_offset_axis = meta.hex_offset_axis

func _apply_terrain_rows(level: Level, rows: Array) -> void:
	if level.terrain_data == null:
		level.terrain_data = LevelTerrainData.new()
	if rows.is_empty():
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

func _apply_start_rows(level: Level, rows: Array) -> void:
	var sorted := rows.duplicate()
	sorted.sort_custom(func(a: LevelStartRow, b: LevelStartRow): return a.slot_index < b.slot_index)
	var player_coords: Array[Vector2i] = []
	var neutral_entries: Array = []
	for row in sorted:
		if row == null:
			continue
		var faction := String(row.faction)
		if faction.is_empty() or faction == "player":
			player_coords.append(row.coord)
		elif faction == "neutral" and row.unit_scene != null:
			var entry := LevelUnitSpawnEntry.new()
			entry.coord = row.coord
			entry.unit_scene = row.unit_scene
			neutral_entries.append(entry)
	level.player_starts = player_coords
	level.set("neutral_spawns", neutral_entries)

func _apply_dialogue_rows(level: Level, rows: Array) -> void:
	var entries: Array[LevelDialogueEntry] = []
	for row in rows:
		if row == null:
			continue
		var entry := LevelDialogueEntry.new()
		entry.id = row.entry_id
		entry.initiator_name = row.initiator_name
		entry.partner_name = row.partner_name
		entry.partner_faction = row.partner_faction
		entry.coord = row.coord
		entry.flag_name = row.flag_name
		entry.action_label = row.action_label
		entry.action_hint = row.action_hint
		entry.repeatable = row.repeatable
		entry.requires_adjacent = row.requires_adjacent
		entry.consume_action = row.consume_action
		entry.group_id = row.group_id
		entry.timeline = row.timeline
		entry.timeline_path = row.timeline_path
		entry.allow_partner_initiation = row.allow_partner_initiation
		entries.append(entry)
	level.dialogue_entries = entries

func _load_rows_by_level(path: String, expected_type: Script) -> Dictionary:
	var grouped: Dictionary = {}
	var files := _list_resource_files(path)
	for resource_path in files:
		if resource_path.find("/templates/") != -1:
			continue
		var row = load(resource_path)
		if row == null or row.get_script() != expected_type:
			continue
		var level_key := String(row.level_id)
		if level_key.is_empty():
			continue
		if not grouped.has(level_key):
			grouped[level_key] = []
		grouped[level_key].append(row)
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

func _build_loot_definition(rows: Array) -> LootListDefinition:
	if rows.is_empty():
		return null
	var entries: Array[LevelLootEntry] = []
	for row in rows:
		if row == null or row.items.is_empty():
			continue
		var loot_entry := LevelLootEntry.new()
		loot_entry.coord = row.coord
		loot_entry.items = row.items.duplicate()
		entries.append(loot_entry)
	if entries.is_empty():
		return null
	var definition := LootListDefinition.new()
	definition.loot_entries = entries
	return definition

func _build_goal_entries(rows: Array) -> Array[LevelGoalEntry]:
	var goals: Array[LevelGoalEntry] = []
	for row in rows:
		if row == null or row.goal_scene == null:
			continue
		var entry := LevelGoalEntry.new()
		entry.coord = row.coord
		entry.goal_scene = row.goal_scene
		goals.append(entry)
	return goals
