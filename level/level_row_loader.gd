extends RefCounted
class_name LevelRowLoader

var _roster_rows_by_level: Dictionary = {}
var _loot_rows_by_level: Dictionary = {}
var _location_rows_by_level: Dictionary = {}
var _terrain_rows_by_level: Dictionary = {}
var _start_rows_by_level: Dictionary = {}
var _dialogue_rows_by_level: Dictionary = {}
var _meta_rows_by_level: Dictionary = {}
var _journal_rows_by_level: Dictionary = {}

var _validator: LevelRowValidator

var _auto_fix_options: LevelAutoFixOptions
var _auto_fix_service: RefCounted

func _init() -> void:
	_validator = LevelRowValidator.new()
	_auto_fix_options = LevelAutoFixOptions.new()
	_auto_fix_service = (load(FilePaths.Resources.LEVEL_AUTO_FIX_SERVICE) as GDScript).new()

func refresh_for_level(level_id: StringName) -> void:
	var level_key := String(level_id)
	if level_key.is_empty():
		return

	print_debug("[LevelRowLoader] Loading row data for level: %s" % level_key)

	# Clear existing data for this level
	_roster_rows_by_level.erase(level_key)
	_loot_rows_by_level.erase(level_key)
	_location_rows_by_level.erase(level_key)
	_terrain_rows_by_level.erase(level_key)
	_start_rows_by_level.erase(level_key)
	_dialogue_rows_by_level.erase(level_key)
	_meta_rows_by_level.erase(level_key)
	_journal_rows_by_level.erase(level_key)

	_load_rows_for_level(level_key)
	print_debug("[LevelRowLoader] Load complete for %s." % level_key)

func set_auto_fix_options(options: LevelAutoFixOptions) -> void:
	_auto_fix_options = options

func _load_rows_for_level(level_id: String) -> void:
	var level_base_path := FilePaths.join_path(FilePaths.Directories.LEVEL_DATA, level_id)

	var configs := [
		{"subdir": "roster_rows", "type": LevelRosterRow, "target": _roster_rows_by_level},
		{"subdir": "loot_rows", "type": LevelLootRow, "target": _loot_rows_by_level},
		{"subdir": "location_rows", "type": LevelTaskRow, "target": _location_rows_by_level},
		{"subdir": "terrain_rows", "type": LevelTerrainRow, "target": _terrain_rows_by_level},
		{"subdir": "start_rows", "type": LevelStartRow, "target": _start_rows_by_level},
		{"subdir": "dialogue_rows", "type": LevelDialogueRow, "target": _dialogue_rows_by_level},
		{"subdir": "meta_rows", "type": LevelMetaRow, "target": _meta_rows_by_level},
		{"subdir": "journal_entry_rows", "type": LevelJournalEntry, "target": _journal_rows_by_level},
	]

	for config in configs:
		var path: String = FilePaths.join_path(level_base_path, config["subdir"])
		var type: Script = config["type"]
		var target: Dictionary = config["target"]

		if not DirAccess.dir_exists_absolute(path):
			continue

		var rows := _load_rows_from_path(path, type)
		if not target.has(level_id):
			target[level_id] = []
		target[level_id].append_array(rows)

func apply_rows_to_level(level: Level, level_id: StringName) -> Dictionary:
	if level == null:
		print_debug("[LevelRowLoader] apply_rows_to_level called with null level")
		return {"errors": []}

	var level_key := String(level_id)

	# Ensure we have data for this level
	if not _meta_rows_by_level.has(level_key):
		refresh_for_level(level_id)

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
	level.journal_entries = _build_journal_entries(journal_rows)

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
			_auto_fix_service = (load(FilePaths.Resources.LEVEL_AUTO_FIX_SERVICE) as GDScript).new()
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

func _load_rows_from_path(path: String, expected_type: Script) -> Array:
	var rows: Array = []
	var files := _list_resource_files(path)
	for resource_path in files:
		if resource_path.find("/templates/") != -1:
			continue
		var row = load(resource_path)
		if row == null:
			push_error("Failed to load resource: %s" % resource_path)
			continue
		if not is_instance_of(row, expected_type):
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
		rows.append(row)
	return rows

func _list_resource_files(path: String) -> Array[String]:
	var results: Array[String] = []
	if not DirAccess.dir_exists_absolute(path):
		return results

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
			results += _list_resource_files(FilePaths.join_path(path, name))
		else:
			if name.endswith(".tres"):
				results.append(FilePaths.join_path(path, name))
	dir.list_dir_end()
	return results

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
