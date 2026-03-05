const DIALOGUE_BLOCKED_TYPES: Array[String] = ["enemy_spawn", "player_start", "neutral_start", "location"]

func apply(level: Level, level_id: StringName, _roster_rows: Array, location_rows: Array, start_rows: Array, dialogue_rows: Array, options: LevelAutoFixOptions) -> Dictionary:
	if level == null or options == null or not options.enabled:
		return {}
	var context := _build_context(level, level_id)
	if context.is_empty():
		return {}

	# Seed occupancy upfront to avoid order-dependent overlaps
	_seed_occupancy(level, context)

	var report: Dictionary = {
		"applied": [],
		"failed": [],
		"messages": [],
		"summary": "",
		"report_path": "",
	}
	var player_rows: Array[LevelUnitSpawnEntry] = []
	var neutral_rows: Array[LevelUnitSpawnEntry] = []
	for row: LevelUnitSpawnEntry in start_rows:
		if row == null:
			continue
		var faction: int = row.faction
		if faction == Unit.Faction.PLAYER or faction == -1:
			player_rows.append(row)
		elif faction == Unit.Faction.NEUTRAL and row.unit_scene != null:
			neutral_rows.append(row)
	player_rows.sort_custom(func(a: LevelUnitSpawnEntry, b: LevelUnitSpawnEntry): return a.slot_index < b.slot_index)
	neutral_rows.sort_custom(func(a: LevelUnitSpawnEntry, b: LevelUnitSpawnEntry): return a.slot_index < b.slot_index)

	if options.fix_locations:
		_repair_locations(level, location_rows, report, context)
	if options.fix_player_starts:
		_repair_player_starts(level, player_rows, report, context)
	if options.fix_neutral_starts:
		_repair_neutral_starts(level, neutral_rows, report, context)
	if options.fix_dialogues:
		_repair_dialogue_rows(level, dialogue_rows, report, context)
	if options.fix_tasks:
		_repair_tasks(level, report, context)

	var has_activity: bool = not report["applied"].is_empty() or not report["failed"].is_empty()
	if not has_activity:
		return {}

	var level_name: String = context["level_name"]
	if options.write_report and not String(options.report_path).is_empty():
		var dir_path: String = String(options.report_path).get_base_dir()
		if not dir_path.is_empty():
			var make_err: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
			if make_err != OK:
				report["messages"].append("[LevelAutoFix] Failed to create report directory %s (error %s)." % [dir_path, make_err])
		var file: FileAccess = FileAccess.open(options.report_path, FileAccess.WRITE)
		if file:
			var json_data: Dictionary = {
				"level_id": level_name,
				"applied": report["applied"],
				"failed": report["failed"],
			}
			file.store_string(JSON.stringify(json_data, "	"))
			report["report_path"] = options.report_path
		else:
			report["messages"].append("[LevelAutoFix] Failed to write report to %s." % options.report_path)

	var summary: String = "[LevelAutoFix] Applied %s repair%s" % [report["applied"].size(), "" if report["applied"].size() == 1 else "s"]
	if report["failed"].size() > 0:
		summary += ", %s unresolved" % report["failed"].size()
	if not String(report["report_path"]).is_empty():
		summary += " (details in %s)" % report["report_path"]
	report["summary"] = summary
	LevelLog.debug(summary)
	return report

func _build_context(level: Level, level_id: StringName) -> Dictionary:
	if level.terrain_data == null:
		return {}
	var dims := GridUtils.dims_of(level)
	var width: int = dims.width
	var height: int = dims.height
	var terrain_map: TerrainMap = TerrainMap.new()
	terrain_map.set_offset_axis(level.hex_offset_axis)
	terrain_map.load_from_rows(level.terrain_data.terrain_rows, width, height)
	var occupancy: Dictionary = {}
	var context: Dictionary = {
		"width": width,
		"height": height,
		"axis": level.hex_offset_axis,
		"terrain_map": terrain_map,
		"occupancy": occupancy,
		"level_name": String(level_id),
	}
	context["is_in_bounds"] = func(coord: Vector2i) -> bool:
		return CoordValidator.is_in_bounds(coord, width, height)
	context["is_passable"] = func(coord: Vector2i) -> bool:
		return GridUtils.is_passable(terrain_map, coord, level)
	context["add_occupancy"] = func(coord: Vector2i, type_label: String) -> void:
		occupancy[CoordValidator.key_of(coord)] = type_label
	context["reason_label"] = func(reason: String) -> String:
		return "impassable tile" if reason == "impassable" else ("out of bounds" if reason == "out_of_bounds" else ("overlaps %s" % reason.split(":")[1]))
	context["validate_coord"] = func(coord: Vector2i, blocked: Array[String]) -> Dictionary:
		var key := CoordValidator.key_of(coord)
		if not CoordValidator.is_in_bounds(coord, width, height):
			return {"ok": false, "reason": "out_of_bounds", "occ": ""}
		if not terrain_map.is_passable(coord):
			return {"ok": false, "reason": "impassable", "occ": ""}
		var occ: String = occupancy.get(key, "")
		if occ != "" and blocked.has(occ):
			return {"ok": false, "reason": "overlap:%s" % occ, "occ": occ}
		return {"ok": true, "reason": "", "occ": occ}
	context["find_replacement"] = func(origin: Vector2i, blocked: Array[String]) -> Vector2i:
		return GridUtils.find_replacement_coord(origin, terrain_map, level, occupancy, blocked)
	return context

func _seed_occupancy(level: Level, context: Dictionary) -> void:
	var add_occupancy: Callable = context["add_occupancy"] as Callable
	# Enemy roster definitions
	if level.enemy_roster_definition:
		for entry: LevelUnitSpawnEntry in level.enemy_roster_definition.spawn_entries:
			add_occupancy.call(entry.coord, "enemy_spawn")
	# Neutral roster definitions
	if level.neutral_roster_definition:
		for entry: LevelUnitSpawnEntry in level.neutral_roster_definition.spawn_entries:
			add_occupancy.call(entry.coord, "neutral_roster")
	# Explicit enemy spawns array
	for entry in level.enemy_spawns:
		if entry:
			add_occupancy.call(entry.coord, "enemy_spawn")
	# Existing player starts
	for coord: Vector2i in level.player_starts:
		add_occupancy.call(coord, "player_start")
	# Existing neutral spawns
	for entry in level.neutral_spawns:
		if entry:
			add_occupancy.call(entry.coord, "neutral_start")
	# Existing locations
	if level.locations:
		for loc: LevelTaskEntry in level.locations:
			if loc:
				add_occupancy.call(loc.coord, "location")

func _repair_locations(level: Level, _location_rows: Array, report: Dictionary, context: Dictionary) -> void:
	var location_entries: Array[LevelTaskEntry] = []
	if level.locations:
		location_entries.assign(level.locations)
	var blocked_for_locations: Array[String] = ["location", "enemy_spawn", "player_start", "neutral_start", "neutral_roster"]
	var validate_coord: Callable = context["validate_coord"] as Callable
	var reason_label_of: Callable = context["reason_label"] as Callable
	var find_replacement: Callable = context["find_replacement"] as Callable
	var add_occupancy: Callable = context["add_occupancy"] as Callable
	var level_name: String = context["level_name"]
	for i in range(location_entries.size()):
		var location_entry: LevelTaskEntry = location_entries[i]
		if location_entry == null:
			continue
		# Use the entry itself as the source-of-truth for the coord label (no separate row)
		var row_label: String = location_entry.resource_path if not String(location_entry.resource_path).is_empty() else "location #%s" % i
		var original: Vector2i = location_entry.coord
		var check = validate_coord.call(original, blocked_for_locations)
		var reason: String = check.reason
		if reason == "":
			add_occupancy.call(original, "location")
			continue
		var origin: Vector2i = location_entry.coord
		var replacement: Vector2i = find_replacement.call(origin, blocked_for_locations)
		var reason_label: String = reason_label_of.call(reason)
		if replacement == Vector2i(-1, -1):
			report["failed"].append({
				"type": "location",
				"row_path": location_entry.resource_path,
				"level_id": level_name,
				"from": {"x": original.x, "y": original.y},
				"to": null,
				"reason": reason_label,
			})
			report["messages"].append("[LevelAutoFix] Unable to repair location %s at (%s,%s): %s." % [row_label, original.x, original.y, reason_label])
			continue
		location_entry.coord = replacement
		add_occupancy.call(replacement, "location")
		report["applied"].append({
			"type": "location",
			"row_path": location_entry.resource_path,
			"level_id": level_name,
			"from": {"x": original.x, "y": original.y},
			"to": {"x": replacement.x, "y": replacement.y},
			"reason": reason_label,
		})
		report["messages"].append("[LevelAutoFix] %s moved from (%s,%s) to (%s,%s) due to %s." % [row_label, original.x, original.y, replacement.x, replacement.y, reason_label])

func _repair_player_starts(level: Level, player_rows: Array[LevelUnitSpawnEntry], report: Dictionary, context: Dictionary) -> void:
	if player_rows.is_empty():
		return
	var validate_coord: Callable = context["validate_coord"] as Callable
	var reason_label_of: Callable = context["reason_label"] as Callable
	var find_replacement: Callable = context["find_replacement"] as Callable
	var add_occupancy: Callable = context["add_occupancy"] as Callable
	var level_name: String = context["level_name"]
	var blocked_for_starts: Array[String] = ["location", "enemy_spawn", "player_start", "neutral_start", "neutral_roster"]
	var player_coords: Array[Vector2i] = []
	player_coords.assign(level.player_starts)
	while player_coords.size() < player_rows.size():
		player_coords.append(player_rows[player_coords.size()].coord)
	for i in range(player_rows.size()):
		var row: LevelUnitSpawnEntry = player_rows[i]
		var label: String = row.resource_path if not String(row.resource_path).is_empty() else "player start #%s" % i
		var coord: Vector2i = player_coords[i]
		var check: Dictionary = validate_coord.call(coord, blocked_for_starts)
		var reason: String = check.reason
		if reason == "":
			add_occupancy.call(coord, "player_start")
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
		player_coords[i] = replacement
		add_occupancy.call(replacement, "player_start")
		report["applied"].append({
			"type": "player_start",
			"row_path": row.resource_path,
			"level_id": level_name,
			"from": {"x": coord.x, "y": coord.y},
			"to": {"x": replacement.x, "y": replacement.y},
			"reason": reason_label,
		})
		report["messages"].append("[LevelAutoFix] %s moved from (%s,%s) to (%s,%s) due to %s." % [label, coord.x, coord.y, replacement.x, replacement.y, reason_label])
	level.player_starts = player_coords

func _repair_neutral_starts(level: Level, neutral_rows: Array[LevelUnitSpawnEntry], report: Dictionary, context: Dictionary) -> void:
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

func _repair_dialogue_rows(_level: Level, dialogue_rows: Array, report: Dictionary, context: Dictionary) -> void:
	if dialogue_rows.is_empty():
		return
	var blocked_for_dialogues := DIALOGUE_BLOCKED_TYPES
	var validate_coord: Callable = context["validate_coord"] as Callable
	var reason_label_of: Callable = context["reason_label"] as Callable
	var find_replacement: Callable = context["find_replacement"] as Callable
	var level_name: String = context["level_name"]

	for row: LevelDialogueEntry in dialogue_rows:
		if row == null:
			continue
		var row_label: String = row.resource_path if not String(row.resource_path).is_empty() else "dialogue #%s" % row.entry_id
		var original: Vector2i = row.coord

		# If the dialogue does not require adjacency, it is likely triggered logically (e.g. on_enter)
		# and does not need a valid physical coordinate.
		if not row.requires_adjacent:
			continue

		var check: Dictionary = validate_coord.call(original, blocked_for_dialogues)
		var reason: String = check.reason

		if reason == "": # No fix needed, record its occupancy for subsequent checks
			# Dialogues don't physically occupy space in the same way units do,
			# so we might not need to add to occupancy if they can stack.
			# For now, I will not add to occupancy for dialogues to allow them to stack.
			continue

		var replacement: Vector2i = find_replacement.call(original, blocked_for_dialogues)
		var reason_label: String = reason_label_of.call(reason)

		if replacement == Vector2i(-1, -1):
			report["failed"].append({
				"type": "dialogue",
				"row_path": row.resource_path if row else "",
				"level_id": level_name,
				"from": {"x": original.x, "y": original.y},
				"to": null,
				"reason": reason_label,
			})
			report["messages"].append("[LevelAutoFix] Unable to repair dialogue %s at (%s,%s): %s." % [row_label, original.x, original.y, reason_label])
			continue

		row.coord = replacement
		report["applied"].append({
			"type": "dialogue",
			"row_path": row.resource_path if row else "",
			"level_id": level_name,
			"from": {"x": original.x, "y": original.y},
			"to": {"x": replacement.x, "y": replacement.y},
			"reason": reason_label,
		})
		report["messages"].append("[LevelAutoFix] %s moved from (%s,%s) to (%s,%s) due to %s." % [row_label, original.x, original.y, replacement.x, replacement.y, reason_label])

func _repair_tasks(level: Level, report: Dictionary, context: Dictionary) -> void:
	if level.objective == null or level.objective.stages.is_empty():
		return
	
	var level_name: String = context["level_name"]
	
	# Build lookups for stage elements
	var location_willpowers_by_id := {}
	var location_willpowers_by_coord := {}
	var location_coords_by_id := {}
	var loot_willpowers_by_coord := {}
	
	if level.locations:
		for loc: LevelTaskEntry in level.locations:
			if loc:
				var lid := String(loc.loc_id) if "loc_id" in loc else String(loc.loc_name) if "loc_name" in loc else ""
				if not lid.is_empty():
					if loc.stats:
						location_willpowers_by_id[lid] = loc.stats.willpower
					location_coords_by_id[lid] = loc.coord
				if loc.stats:
					location_willpowers_by_coord[CoordValidator.key_of(loc.coord)] = loc.stats.willpower
					
	# For simplicity in Godot side, we assume loot spawns are accessible if needed
	# But level.objective.stages might have loot_spawns embedded too
	
	for stage: Stage in level.objective.stages:
		if stage == null:
			continue
			
		# Stage-specific loot spawns
		var stage_loot_willpowers := {}
		var stage_loot_coords := {}
		if "loot_spawns" in stage:
			for lr: LevelLootEntry in stage.get("loot_spawns"):
				if lr and lr.stats:
					stage_loot_willpowers[CoordValidator.key_of(lr.coord)] = lr.stats.willpower
					
		for task: Task in stage.tasks:
			if task == null:
				continue
				
			var kind := String(task.target_kind)
			var target_id := String(task.target_id)
			var target_coord := task.target_coord
			
			if kind == "location":
				var id_exists = not target_id.is_empty() and location_willpowers_by_id.has(target_id)
				
				# Repair missing coord if ID exists
				if id_exists and target_coord == Vector2i(-999, -999):
					var new_coord = location_coords_by_id[target_id]
					task.target_coord = new_coord
					report["applied"].append({
						"type": "task_coord",
						"row_path": task.resource_path,
						"level_id": level_name,
						"task_id": String(task.id),
						"to": {"x": new_coord.x, "y": new_coord.y},
						"reason": "missing target_coord synced to target_id"
					})
					report["messages"].append("[LevelAutoFix] Task %s coord synced to location '%s' at %s." % [String(task.id), target_id, new_coord])
					target_coord = new_coord
				
				# Repair willpower misalignment
				var target_willpower = -1
				if id_exists:
					target_willpower = location_willpowers_by_id[target_id]
				elif target_coord != Vector2i(-999, -999):
					target_willpower = location_willpowers_by_coord.get(CoordValidator.key_of(target_coord), -1)
					
				if target_willpower != -1 and task.effort_required != target_willpower:
					var old_effort = task.effort_required
					task.effort_required = target_willpower
					report["applied"].append({
						"type": "task_effort",
						"row_path": task.resource_path,
						"level_id": level_name,
						"task_id": String(task.id),
						"from": old_effort,
						"to": target_willpower,
						"reason": "misaligned effort synchronized to target willpower"
					})
					report["messages"].append("[LevelAutoFix] Task %s effort (%d) synced to location willpower (%d)." % [String(task.id), old_effort, target_willpower])

			elif kind == "item":
				# Check loot willpower misalignment if coordinate is known
				if target_coord != Vector2i(-999, -999):
					var target_willpower = stage_loot_willpowers.get(CoordValidator.key_of(target_coord), -1)
					if target_willpower != -1 and task.effort_required != target_willpower:
						var old_effort = task.effort_required
						task.effort_required = target_willpower
						report["applied"].append({
							"type": "task_effort",
							"row_path": task.resource_path,
							"level_id": level_name,
							"task_id": String(task.id),
							"from": old_effort,
							"to": target_willpower,
							"reason": "misaligned effort synchronized to loot willpower"
						})
						report["messages"].append("[LevelAutoFix] Task %s effort (%d) synced to loot willpower (%d)." % [String(task.id), old_effort, target_willpower])
