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
	if level_id == &"":
		return

	LevelLog.debug("[LevelRowLoader] Loading row data for level: %s" % level_id)

	# Clear existing data for this level
	_roster_rows_by_level.erase(level_id)
	_loot_rows_by_level.erase(level_id)
	_location_rows_by_level.erase(level_id)
	_terrain_rows_by_level.erase(level_id)
	_start_rows_by_level.erase(level_id)
	_dialogue_rows_by_level.erase(level_id)
	_meta_rows_by_level.erase(level_id)
	_journal_rows_by_level.erase(level_id)

	_load_rows_for_level(level_id)
	LevelLog.debug("[LevelRowLoader] Load complete for %s." % level_id)

func set_auto_fix_options(options: LevelAutoFixOptions) -> void:
	_auto_fix_options = options

func _load_rows_for_level(level_id: StringName) -> void:
	var level_base_path := FilePaths.Directories.LEVEL_DATA.path_join(level_id)

	var configs := [
		{"subdir": "roster_rows", "type": LevelUnitSpawnEntry, "target": _roster_rows_by_level},
		{"subdir": "loot_rows", "type": LevelLootEntry, "target": _loot_rows_by_level},
		{"subdir": "location_rows", "type": LevelTaskEntry, "target": _location_rows_by_level},
		{"subdir": "start_rows", "type": LevelUnitSpawnEntry, "target": _start_rows_by_level},
		{"subdir": "dialogue_rows", "type": LevelDialogueEntry, "target": _dialogue_rows_by_level},
		{"subdir": "journal_entry_rows", "type": JournalEntry, "target": _journal_rows_by_level},
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

	_meta_rows_by_level[level_id] = []

func apply_rows_to_level(level: Level, level_id: StringName) -> Dictionary:
	if level == null:
		LevelLog.warn("[LevelRowLoader] apply_rows_to_level called with null level")
		return {"errors": []}

	# Ensure we have data for this level
	if not _meta_rows_by_level.has(level_id):
		refresh_for_level(level_id)

	LevelLog.debug("[LevelRowLoader] Applying rows to level: %s" % level_id)
	if level_id.is_empty():
		LevelLog.warn("[LevelRowLoader] Level ID is empty")
		return {"errors": []}

	var rows := _rows_for_level(level_id)
	var roster_rows: Array = rows["roster"]
	var loot_rows: Array = rows["loot"]
	var location_rows: Array = rows["locations"]
	var start_rows: Array = rows["start"]
	var dialogue_rows: Array = rows["dialogue"]
	var journal_rows: Array = rows["journal"]

	LevelLog.debug("[LevelRowLoader] Found rows for %s: Roster=%d, Loot=%d, Locations=%d, Start=%d, Dialogue=%d, Journal=%d" % \
		[level_id, roster_rows.size(), loot_rows.size(), location_rows.size(), start_rows.size(), dialogue_rows.size(), journal_rows.size()])
	_apply_combat_rows(level, roster_rows, loot_rows, location_rows)
	_apply_start_rows(level, start_rows)
	_apply_dialogue_rows(level, dialogue_rows)
	level.journal_entries = _build_journal_entries(journal_rows)

	_distribute_rows_to_stages(level)
	return _validate_and_autofix(level, level_id, rows)

func _rows_for_level(level_id: StringName) -> Dictionary:
	return {
		"roster": _roster_rows_by_level.get(level_id, []),
		"loot": _loot_rows_by_level.get(level_id, []),
		"locations": _location_rows_by_level.get(level_id, []),
		"terrain": _terrain_rows_by_level.get(level_id, []),
		"start": _start_rows_by_level.get(level_id, []),
		"dialogue": _dialogue_rows_by_level.get(level_id, []),
		"meta": _meta_rows_by_level.get(level_id, []),
		"journal": _journal_rows_by_level.get(level_id, []),
	}

func _apply_combat_rows(level: Level, roster_rows: Array, loot_rows: Array, location_rows: Array) -> void:
	if not roster_rows.is_empty():
		var enemy_spawns: Array[LevelUnitSpawnEntry] = []
		var neutral_spawns: Array[LevelUnitSpawnEntry] = []

		for spawn in roster_rows:
			if spawn == null:
				continue
			var entry := spawn as LevelUnitSpawnEntry
			if entry.unit_scene == null:
				LevelLog.warn("[LevelRowLoader] Skipping spawn at %s: unit_scene is null" % entry.coord)
				continue
			if entry.faction == GameConstants.Faction.ENEMY:
				enemy_spawns.append(entry)
			elif entry.faction == GameConstants.Faction.NEUTRAL:
				neutral_spawns.append(entry)
		level.enemy_spawns = enemy_spawns
		level.neutral_spawns = neutral_spawns
		_sync_roster_definitions(level)

	if not loot_rows.is_empty():
		var typed_loot: Array[LevelLootEntry] = []
		for r in loot_rows:
			if r: typed_loot.append(r as LevelLootEntry)
		level.loot = typed_loot

	if not location_rows.is_empty():
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
		if faction == GameConstants.Faction.PLAYER or faction == GameConstants.INVALID_INDEX:
			player_coords.append(entry.coord)
			player_entries.append(entry)
			continue
		if entry.unit_scene == null:
			continue
		if faction == GameConstants.Faction.NEUTRAL:
			neutral_entries.append(entry)
		elif faction == GameConstants.Faction.ENEMY:
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

func _build_journal_entries(rows: Array) -> Array[JournalEntry]:
	var entries: Array[JournalEntry] = []
	for row in rows:
		if row == null:
			continue
		var entry := row.duplicate(true) as JournalEntry
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
		var row: Resource = load(resource_path)
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
		var name: String = dir.get_next()
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

func _distribute_rows_to_stages(level: Level) -> void:
	if level.objective == null:
		return

	var all_stages: Array[Stage] = []
	if level.objective.starting_stage:
		all_stages.append(level.objective.starting_stage)
	for s in level.objective.stages:
		if s and not all_stages.has(s):
			all_stages.append(s)

	if all_stages.is_empty():
		return

	var stage_ids := all_stages.map(func(s): return String(s.id))

	# 1. Distribute stage-specific rows based on 'stage_id' matching stage ID
	for stage in all_stages:
		var stage_id: String = String(stage.id)
		if stage_id.is_empty(): continue
		
		var stage_enemy = level.enemy_spawns.filter(func(r): return r.stage_id == stage_id)
		var stage_neutral = level.neutral_spawns.filter(func(r): return r.stage_id == stage_id)
		var stage_loot = level.loot.filter(func(r): return r.stage_id == stage_id)
		var stage_locs = level.locations.filter(func(r): return r.notes == stage_id or r.stage_id == stage_id) # Support notes fallback for locs during migration
		var stage_dialogue = level.dialogue_entries.filter(func(r): return r.stage_id == stage_id)
		
		_inject_collection_to_target(stage_enemy, stage.enemy_spawns)
		_inject_collection_to_target(stage_neutral, stage.neutral_spawns)
		_inject_collection_to_target(stage_loot, stage.loot_spawns)
		_inject_collection_to_target(stage_locs, stage.location_spawns)
		_inject_collection_to_target(stage_dialogue, stage.dialogue_entries)

	# 2. Global rows (no stage_id or stage_id not matching any stage)
	# go to the first stage by default.
	var first_stage = all_stages[0]
	var global_enemy = level.enemy_spawns.filter(func(r): return r.stage_id == "" or not stage_ids.has(r.stage_id))
	var global_neutral = level.neutral_spawns.filter(func(r): return r.stage_id == "" or not stage_ids.has(r.stage_id))
	var global_loot = level.loot.filter(func(r): return r.stage_id == "" or not stage_ids.has(r.stage_id))
	var global_locs = level.locations.filter(func(r): return (r.stage_id == "" and r.notes == "") or (not stage_ids.has(r.stage_id) and not stage_ids.has(r.notes)))
	var global_dialogue = level.dialogue_entries.filter(func(r): return r.stage_id == "" or not stage_ids.has(r.stage_id))
	
	_inject_collection_to_target(global_enemy, first_stage.enemy_spawns)
	_inject_collection_to_target(global_neutral, first_stage.neutral_spawns)
	_inject_collection_to_target(global_loot, first_stage.loot_spawns)
	_inject_collection_to_target(global_locs, first_stage.location_spawns)
	_inject_collection_to_target(global_dialogue, first_stage.dialogue_entries)

	level.dialogue_entries.clear()
	LevelLog.debug("[LevelRowLoader] Distributed rows to %d stages" % all_stages.size())

func _inject_collection_to_target(collection: Array, target: Array) -> void:
	for item in collection:
		if item and not target.has(item):
			target.append(item)
