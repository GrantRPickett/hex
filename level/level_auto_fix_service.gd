extends RefCounted

const DIALOGUE_BLOCKED_TYPES: Array[String] = ["enemy_spawn", "player_start", "neutral_start", "location"]

func apply(level: Level, level_id: StringName, _roster_rows: Array, location_rows: Array, start_rows: Array, dialogue_rows: Array, options: LevelAutoFixOptions) -> Dictionary:
	if not options.enabled:
		return {}

	var level_name := String(level_id)
	var report: Dictionary = {
		"applied": [], # List of successful repairs: {type, row_path, from, to, reason}
		"failed": [],  # List of failed repairs: {type, row_path, from, reason}
		"messages": [], # Human-readable log
		"summary": "",
		"report_path": "",
	}

	var context := _build_context(level, level_id)

	# Split start rows by faction
	var player_rows: Array[LevelUnitSpawnEntry] = []
	var neutral_rows: Array[LevelUnitSpawnEntry] = []
	for row in start_rows:
		if row == null: continue
		if row.faction == GameConstants.Faction.PLAYER or row.faction == GameConstants.INVALID_INDEX:
			player_rows.append(row)
		elif row.faction == GameConstants.Faction.NEUTRAL:
			neutral_rows.append(row)

	# Delegated repairs
	LocationRepairer.new().repair(level, location_rows, report, context, options)

	var spawn_repairer := UnitSpawnRepairer.new()
	spawn_repairer.repair_player_starts(level, player_rows, report, context, options)
	spawn_repairer.repair_neutral_starts(level, neutral_rows, report, context, options)

	DialogueRepairer.new().repair(level, dialogue_rows, report, context, options)
	TaskRepairer.new().repair(level, report, context, options)

	# Generate summary
	var applied_count: int = report["applied"].size()
	var failed_count: int = report["failed"].size()
	report["summary"] = "AutoFix Complete: %d applied, %d failed." % [applied_count, failed_count]

	if options.write_report:
		_write_report_file(level_id, report)

	return report

func _build_context(level: Level, level_id: StringName) -> Dictionary:
	var dims := HexLib.dims_of(level)
	var terrain_map := TerrainMap.new()
	terrain_map.set_offset_axis(int(dims.axis))
	terrain_map.load_from_rows(level.terrain_data.terrain_rows, int(dims.width), int(dims.height))

	var occupancy := {} # key (string) -> type (string)

	return {
		"level_id": level_id,
		"level_name": String(level_id),
		"width": int(dims.width),
		"height": int(dims.height),
		"axis": int(dims.axis),
		"terrain": terrain_map,
		"occupancy": occupancy,
		"validate_coord": _validate_coord_in_context.bind(dims, terrain_map, occupancy),
		"find_replacement": _find_replacement_in_context.bind(dims, terrain_map, occupancy),
		"add_occupancy": func(coord: Vector2i, type: String):
			occupancy[HexLib.key_of(coord)] = type,
		"reason_label": _get_reason_label
	}

func _validate_coord_in_context(coord: Vector2i, blocked_types: Array[String], dims: Dictionary, terrain_map: TerrainMap, occupancy: Dictionary) -> Dictionary:
	if not HexLib.is_in_bounds(coord, int(dims.width), int(dims.height)):
		return {"reason": "out_of_bounds"}
	if not terrain_map.is_passable(coord):
		return {"reason": "impassable"}
	var key = HexLib.key_of(coord)
	if occupancy.has(key):
		var type = occupancy[key]
		if blocked_types.has(type):
			return {"reason": "occupied_" + type}
	return {"reason": ""}

func _find_replacement_in_context(original: Vector2i, blocked_types: Array[String], dims: Dictionary, terrain_map: TerrainMap, occupancy: Dictionary) -> Vector2i:
	var queue: Array[Vector2i] = [original]
	var visited := {HexLib.key_of(original): true}
	var max_attempts: int = 100
	var attempts: int = 0

	while not queue.is_empty() and attempts < max_attempts:
		attempts += 1
		var current = queue.pop_front()

		# Check if current is valid
		var is_valid: bool = true
		if not HexLib.is_in_bounds(current, int(dims.width), int(dims.height)):
			is_valid = false
		elif not terrain_map.is_passable(current):
			is_valid = false
		else:
			var key = HexLib.key_of(current)
			if occupancy.has(key):
				if blocked_types.has(occupancy[key]):
					is_valid = false

		if is_valid:
			return current

		# Add neighbors
		var neighbors := HexLib.get_neighbor_offsets(current, int(dims.axis))
		for offset in neighbors:
			var next = current + offset
			var next_key = HexLib.key_of(next)
			if not visited.has(next_key):
				visited[next_key] = true
				queue.append(next)
	return GameConstants.INVALID_COORD

func _get_reason_label(reason: String) -> String:
	match reason:
		"out_of_bounds": return "out of bounds"
		"impassable": return "impassable terrain"
		"occupied_location": return "location overlap"
		"occupied_enemy_spawn": return "enemy spawn overlap"
		"occupied_player_start": return "player start overlap"
		"occupied_neutral_start": return "neutral start overlap"
		"occupied_neutral_roster": return "neutral roster overlap"
		_: return reason

func _repair_locations(level: Level, location_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void:
	LocationRepairer.new().repair(level, location_rows, report, context, options)

func _repair_player_starts(level: Level, player_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void:
	var typed_rows: Array[LevelUnitSpawnEntry] = []
	typed_rows.assign(player_rows)
	UnitSpawnRepairer.new().repair_player_starts(level, typed_rows, report, context, options)

func _repair_neutral_starts(level: Level, neutral_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void:
	var typed_rows: Array[LevelUnitSpawnEntry] = []
	typed_rows.assign(neutral_rows)
	UnitSpawnRepairer.new().repair_neutral_starts(level, typed_rows, report, context, options)

func _repair_tasks(level: Level, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void:
	TaskRepairer.new().repair(level, report, context, options)

func _write_report_file(level_id: StringName, report: Dictionary) -> void:
	var path: String = "user://autofix_report_%s.json" % level_id
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		report["report_path"] = path
		LevelLog.debug("[LevelAutoFix] Report written to %s" % path)
		
	if report.get("applied", []).size() > 0 or report.get("failed", []).size() > 0:
		var warning_msg: String = "[LevelAutoFix] Modifications applied to level '%s'. Please fix the source JSON.\n" % level_id
		for applied in report.get("applied", []):
			warning_msg += "- Fixed %s at %s: moved from %s to %s (%s)\n" % [applied.get("type", "entity"), applied.get("row_path", "unknown"), applied.get("from", "unknown"), applied.get("to", "unknown"), applied.get("reason", "unknown")]
		for failed in report.get("failed", []):
			warning_msg += "- FAILED %s at %s: from %s (%s)\n" % [failed.get("type", "entity"), failed.get("row_path", "unknown"), failed.get("from", "unknown"), failed.get("reason", "unknown")]
		LevelLog.warn(warning_msg)
