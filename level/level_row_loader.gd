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

	LevelLog.debug("[LevelRowLoader] Loading row data for level: %s" % level_key)

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
	LevelLog.debug("[LevelRowLoader] Load complete for %s." % level_key)

func set_auto_fix_options(options: LevelAutoFixOptions) -> void:
	_auto_fix_options = options

func _load_rows_for_level(level_id: String) -> void:
	var level_base_path := FilePaths.Directories.LEVEL_DATA.path_join(level_id)

	var configs := [
		{"subdir": "roster_rows", "type": LevelUnitSpawnEntry, "target": _roster_rows_by_level},
		{"subdir": "loot_rows", "type": LevelLootEntry, "target": _loot_rows_by_level},
		{"subdir": "location_rows", "type": LevelTaskEntry, "target": _location_rows_by_level},
		{"subdir": "start_rows", "type": LevelUnitSpawnEntry, "target": _start_rows_by_level},
		{"subdir": "dialogue_rows", "type": LevelDialogueEntry, "target": _dialogue_rows_by_level},
		{"subdir": "journal_entry_rows", "type": LevelJournalEntry, "target": _journal_rows_by_level},
	]

	for config in configs:
		var path: String = level_base_path.path_join(config["subdir"])
		var type: Script = config["type"]
		var target: Dictionary = config["target"]

		var dir := DirAccess.open(path)
		if dir == null:
			continue

		var rows := _load_rows_from_path(path, type)
		if not target.has(level_id):
			target[level_id] = []
		target[level_id].append_array(rows)

func apply_rows_to_level(level: Level, level_id: StringName) -> Dictionary:
	if level == null:
		LevelLog.warn("[LevelRowLoader] apply_rows_to_level called with null level")
		return {"errors": []}

	var level_key := String(level_id)

	# Ensure we have data for this level
	if not _meta_rows_by_level.has(level_key):
		refresh_for_level(level_id)

	LevelLog.debug("[LevelRowLoader] Applying rows to level: %s" % level_key)
	if level_key.is_empty():
		LevelLog.warn("[LevelRowLoader] Level ID is empty")
		return {"errors": []}

	var rows := _rows_for_level(level_key)
	var roster_rows: Array = rows["roster"]
	var loot_rows: Array = rows["loot"]
	var location_rows: Array = rows["locations"]
	var start_rows: Array = rows["start"]
	var dialogue_rows: Array = rows["dialogue"]
	var journal_rows: Array = rows["journal"]

	LevelLog.debug("[LevelRowLoader] Found rows for %s: Roster=%d, Loot=%d, Locations=%d, Start=%d, Dialogue=%d, Journal=%d" % [level_key, roster_rows.size(), loot_rows.size(), location_rows.size(), start_rows.size(), dialogue_rows.size(), journal_rows.size()])
	_apply_combat_rows(level, roster_rows, loot_rows, location_rows)
	_apply_start_rows(level, start_rows)
	_apply_dialogue_rows(level, dialogue_rows)
	level.journal_entries = _build_journal_entries(journal_rows)

	_inject_into_first_stage(level)
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
	var enemy_spawns: Array[LevelUnitSpawnEntry] = []
	var neutral_spawns: Array[LevelUnitSpawnEntry] = []

	for spawn in roster_rows:
		if spawn == null:
			continue
		var entry := spawn as LevelUnitSpawnEntry
		if entry.unit_scene == null:
			LevelLog.warn("[LevelRowLoader] Skipping spawn at %s: unit_scene is null" % entry.coord)
			continue
		if entry.faction == Unit.Faction.ENEMY:
			enemy_spawns.append(entry)
		elif entry.faction == Unit.Faction.NEUTRAL:
			neutral_spawns.append(entry)
	level.enemy_spawns = enemy_spawns
	level.neutral_spawns = neutral_spawns
	_sync_roster_definitions(level)

	var typed_loot: Array[LevelLootEntry] = []
	for r in loot_rows:
		if r: typed_loot.append(r as LevelLootEntry)
	level.loot = typed_loot

	var typed_locations: Array[LevelTaskEntry] = []
	for r in location_rows:
		if r: typed_locations.append(r as LevelTaskEntry)
	level.locations = typed_locations

func _validate_and_autofix(level: Level, level_id: StringName, rows: Dictionary) -> Dictionary:
	var roster_rows: Array = rows["roster"]
	var loot_rows: Array = rows["loot"]
	var location_rows: Array = rows["locations"]
	var start_rows: Array = rows["start"]
	var dialogue_rows: Array = rows["dialogue"]
	var journal_rows: Array = rows["journal"]

	var errors := _validator.validate(level, level_id, roster_rows, loot_rows, location_rows, start_rows, dialogue_rows, journal_rows)
	var result: Dictionary = {"errors": errors}
	var should_fix := _auto_fix_options != null and _auto_fix_options.enabled
	if should_fix:
		if _auto_fix_service == null:
			_auto_fix_service = (load(FilePaths.Resources.LEVEL_AUTO_FIX_SERVICE) as GDScript).new()
		var report: Dictionary = _auto_fix_service.apply(level, level_id, roster_rows, location_rows, start_rows, dialogue_rows, _auto_fix_options) # Modified line
		if report:
			result["auto_fix"] = report
	return result


func _apply_start_rows(level: Level, rows: Array) -> void:
	if rows.is_empty():
		return

	level.player_starts.clear()
	var sorted := rows.duplicate()
	sorted.sort_custom(func(a: LevelUnitSpawnEntry, b: LevelUnitSpawnEntry): return a.slot_index < b.slot_index)
	var player_coords: Array[Vector2i] = []
	var player_entries: Array[LevelUnitSpawnEntry] = []
	var neutral_entries: Array[LevelUnitSpawnEntry] = []
	var enemy_entries: Array[LevelUnitSpawnEntry] = []
	for entry in sorted:
		if entry == null:
			continue
		var faction: int = entry.faction
		if faction == Unit.Faction.PLAYER or faction == -1:
			player_coords.append(entry.coord)
			player_entries.append(entry)
			continue
		if entry.unit_scene == null:
			continue
		if faction == Unit.Faction.NEUTRAL:
			neutral_entries.append(entry)
		elif faction == Unit.Faction.ENEMY:
			enemy_entries.append(entry)
	level.player_starts = player_coords
	level.player_spawns = player_entries
	# For starts, they append to the rosters built from roster_rows (if any) or existing arrays.
	var cur_neutral: Array[LevelUnitSpawnEntry] = level.neutral_spawns
	var cur_enemy: Array[LevelUnitSpawnEntry] = level.enemy_spawns
	cur_neutral.append_array(neutral_entries)
	cur_enemy.append_array(enemy_entries)
	level.neutral_spawns = cur_neutral
	level.enemy_spawns = cur_enemy
	_sync_roster_definitions(level)
	print_debug("[LevelRowLoader] Applied start rows: %d Player (unified), %d Neutral, %d Enemy" % [player_entries.size(), neutral_entries.size(), enemy_entries.size()])

func _apply_dialogue_rows(level: Level, rows: Array) -> void:
	var entries: Array[LevelDialogueEntry] = []
	for entry in rows:
		if entry == null:
			continue
		entries.append(entry as LevelDialogueEntry)
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


func _load_rows_from_path(path: String, expected_type: Script) -> Array:
	var rows: Array = []
	var files := _list_resource_files(path)
	for resource_path in files:
		if resource_path.find("/templates/") != -1:
			continue
		if not ResourceLoader.exists(resource_path):
			LevelLog.error("Failed to load resource (missing): %s" % resource_path)
			return []
		var row = load(resource_path)
		if row == null:
			LevelLog.error("Failed to load resource: %s" % resource_path)
			return []
		if not is_instance_of(row, expected_type):
			var actual_type_name := "<unknown>"
			if row:
				if row.has_method("get_class"):
					actual_type_name = row.get_class()
				elif row.get_script() != null:
					actual_type_name = row.get_script().resource_path

			var expected_path := "<unknown>" if expected_type == null else expected_type.resource_path
			LevelLog.warn("[LevelRowLoader] Resource %s has unexpected type: %s, expected: %s" % [resource_path, actual_type_name, expected_path])
			continue
		rows.append(row)
	return rows

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
			results += _list_resource_files(path.path_join(name))
		else:
			var full := path.path_join(name)
			var ext := full.get_extension().to_lower()
			if ext == "tres" or ext == "res":
				results.append(full)
	dir.list_dir_end()
	# Deduplicate and sort deterministically
	var unique: Dictionary = {}
	var dedup: Array[String] = []
	for f in results:
		if not unique.has(f):
			unique[f] = true
			dedup.append(f)
	dedup.sort()
	return dedup

func _sync_roster_definitions(level: Level) -> void:
	if level.enemy_roster_definition == null:
		level.enemy_roster_definition = UnitRosterDefinition.new()
	level.enemy_roster_definition.spawn_entries = level.enemy_spawns

	if level.neutral_roster_definition == null:
		level.neutral_roster_definition = UnitRosterDefinition.new()
	level.neutral_roster_definition.spawn_entries = level.neutral_spawns

func _inject_into_first_stage(level: Level) -> void:
	if level.objective == null:
		return
	var stages_to_inject: Array[Stage] = []
	if level.objective.starting_stage:
		stages_to_inject.append(level.objective.starting_stage)
	if not level.objective.stages.is_empty() and not stages_to_inject.has(level.objective.stages[0]):
		stages_to_inject.append(level.objective.stages[0])

	if stages_to_inject.is_empty():
		return

	for stage in stages_to_inject:
		if stage == null: continue
		# Inject spawns
		for es in level.enemy_spawns:
			if es and not stage.enemy_spawns.has(es):
				stage.enemy_spawns.append(es)

		for ns in level.neutral_spawns:
			if ns and not stage.neutral_spawns.has(ns):
				stage.neutral_spawns.append(ns)

		# Inject loot
		for l in level.loot:
			if l and not stage.loot_spawns.has(l):
				stage.loot_spawns.append(l)

		# Inject locations
		for loc in level.locations:
			if loc and not stage.location_spawns.has(loc):
				stage.location_spawns.append(loc)

		# Inject dialogues
		for d in level.dialogue_entries:
			if d and not stage.dialogue_entries.has(d):
				stage.dialogue_entries.append(d)

	# Note: We no longer clear global collections here.
	# They are needed by LevelBuilder for initial unit setup.
	level.dialogue_entries.clear()

	LevelLog.debug("[LevelRowLoader] Injected and cleared global rows for %d stages" % stages_to_inject.size())
