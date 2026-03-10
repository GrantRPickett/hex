extends RefCounted
class_name UnitSpawnRepairer

func repair_player_starts(level: Level, player_rows: Array[LevelUnitSpawnEntry], report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void:
	if player_rows.is_empty():
		return
	var validate_coord: Callable = context["validate_coord"] as Callable
	var reason_label_of: Callable = context["reason_label"] as Callable
	var find_replacement: Callable = context["find_replacement"] as Callable
	var add_occupancy: Callable = context["add_occupancy"] as Callable
	var level_name: String = context["level_name"]
	var blocked_for_starts: Array[String] = ["location", "enemy_spawn", "player_start", "neutral_start", "neutral_roster"]
	for i in range(player_rows.size()):
		var row: LevelUnitSpawnEntry = player_rows[i]
		var label: String = row.resource_path if not String(row.resource_path).is_empty() else "player start #%s" % i
		var coord: Vector2i = row.coord
		var check: Dictionary = validate_coord.call(coord, blocked_for_starts)
		var reason: String = check.reason
		if reason == "":
			add_occupancy.call(coord, "player_start")
			if options.log_missing_params:
				_repair_unit_spawn_metadata(row, i, "player", report, level_name)
			continue
		var replacement: Vector2i = find_replacement.call(row.coord, blocked_for_starts)
		var reason_label: String = reason_label_of.call(reason)
		if replacement == Vector2i(-1, -1):
			report["failed"].append({
				"type": "player_start",
				"row_path": row.resource_path,
				"level_id": level_name,
				"from": {"x": coord.x, "y": coord.y},
				"to": null,
				"reason": reason_label,
			})
			report["messages"].append("[LevelAutoFix] Unable to repair %s at (%s,%s): %s." % [label, coord.x, coord.y, reason_label])
			continue
		row.coord = replacement
		add_occupancy.call(replacement, "player_start")
		if options.log_missing_params:
			_repair_unit_spawn_metadata(row, i, "player", report, level_name)
		report["applied"].append({
			"type": "player_start",
			"row_path": row.resource_path,
			"level_id": level_name,
			"from": {"x": coord.x, "y": coord.y},
			"to": {"x": replacement.x, "y": replacement.y},
			"reason": reason_label,
		})
		report["messages"].append("[LevelAutoFix] %s moved from (%s,%s) to (%s,%s) due to %s." % [label, coord.x, coord.y, replacement.x, replacement.y, reason_label])
	level.player_spawns.assign(player_rows)
	var new_starts: Array[Vector2i] = []
	for p_row in player_rows:
		new_starts.append(p_row.coord)
	level.player_starts = new_starts

func repair_neutral_starts(level: Level, neutral_rows: Array[LevelUnitSpawnEntry], report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void:
	if neutral_rows.is_empty():
		return
	var validate_coord: Callable = context["validate_coord"] as Callable
	var reason_label_of: Callable = context["reason_label"] as Callable
	var find_replacement: Callable = context["find_replacement"] as Callable
	var add_occupancy: Callable = context["add_occupancy"] as Callable
	var level_name: String = context["level_name"]
	var blocked_for_starts: Array[String] = ["location", "enemy_spawn", "player_start", "neutral_start", "neutral_roster"]
	var neutral_entries: Array[LevelUnitSpawnEntry] = level.neutral_spawns
	var neutral_count: int = min(neutral_entries.size(), neutral_rows.size())
	for i in range(neutral_count):
		var row: LevelUnitSpawnEntry = neutral_rows[i]
		var entry: LevelUnitSpawnEntry = neutral_entries[i]
		if entry == null:
			continue
		var label: String = row.resource_path if not String(row.resource_path).is_empty() else "neutral start #%s" % i
		var coord: Vector2i = entry.coord
		var check: Dictionary = validate_coord.call(coord, blocked_for_starts)
		var reason: String = check.reason
		if reason == "":
			add_occupancy.call(coord, "neutral_start")
			if options.log_missing_params:
				_repair_unit_spawn_metadata(row, i, "neutral", report, level_name)
			continue
		var replacement: Vector2i = find_replacement.call(row.coord, blocked_for_starts)
		var reason_label: String = reason_label_of.call(reason)
		if replacement == Vector2i(-1, -1):
			report["failed"].append({
				"type": "neutral_start",
				"row_path": row.resource_path,
				"level_id": level_name,
				"from": {"x": coord.x, "y": coord.y},
				"to": null,
				"reason": reason_label,
			})
			report["messages"].append("[LevelAutoFix] Unable to repair %s at (%s,%s): %s." % [label, coord.x, coord.y, reason_label])
			continue
		entry.coord = replacement
		add_occupancy.call(replacement, "neutral_start")
		if options.log_missing_params:
			_repair_unit_spawn_metadata(row, i, "neutral", report, level_name)
		report["applied"].append({
			"type": "neutral_start",
			"row_path": row.resource_path,
			"level_id": level_name,
			"from": {"x": coord.x, "y": coord.y},
			"to": {"x": replacement.x, "y": replacement.y},
			"reason": reason_label,
		})
		report["messages"].append("[LevelAutoFix] %s moved from (%s,%s) to (%s,%s) due to %s." % [label, coord.x, coord.y, replacement.x, replacement.y, reason_label])
	level.neutral_spawns = neutral_entries

func _repair_unit_spawn_metadata(spawn: LevelUnitSpawnEntry, index: int, type: String, report: Dictionary, level_name: String) -> void:
	if spawn.unit_scene == null:
		report["failed"].append({
			"type": type + "_spawn_metadata",
			"row_path": spawn.resource_path,
			"level_id": level_name,
			"field": "unit_scene",
			"reason": "missing unit scene"
		})
		report["messages"].append("[LevelAutoFix] %s spawn #%d is missing unit_scene." % [type.capitalize(), index])
