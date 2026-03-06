extends RefCounted
class_name LevelRowValidator

func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array, start_rows: Array, dialogue_rows: Array, journal_entry_rows: Array) -> Array[String]:
	LevelLog.debug("[LevelRowValidator] Validating level: %s" % level_id)
	var errors: Array[String] = []
	var dims := GridUtils.dims_of(level)
	var width := int(dims.width)
	var height := int(dims.height)
	var roster_coord_map := {}
	errors += _validate_roster_rows(roster_rows, level_id, width, height, roster_coord_map)
	errors += _validate_loot_rows(loot_rows, level_id, width, height)
	var location_coord_map := {}
	errors += _validate_location_rows(location_rows, level_id, width, height, location_coord_map)
	errors += _validate_start_rows(start_rows, level_id, width, height, roster_coord_map, location_coord_map)
	errors += _validate_dialogue_rows(dialogue_rows, level_id, width, height)
	errors += _validate_journal_entry_rows(journal_entry_rows, level_id)
	# Task target/duration validation using only level row data (no runtime snapshot)
	errors += _validate_task_rows(level, level_id, roster_rows, loot_rows, location_rows)
	# Cross-validate dialogue/journal linkage by entry_id <-> related_id
	errors += _validate_dialogue_journal_links(dialogue_rows, journal_entry_rows, level_id, level.objective)

	# Connectivity validation
	errors += _validate_connectivity(level, level_id, roster_rows, loot_rows, location_rows, start_rows)

	if errors.size() > 0:
		LevelLog.debug("[LevelRowValidator] Validation failed for %s with %d errors." % [level_id, errors.size()])
		for err in errors:
			LevelLog.debug("  - " + err)
			LevelLog.warn(err)
	else:
		LevelLog.debug("[LevelRowValidator] Validation passed for %s." % level_id)
	return errors

func _validate_journal_entry_rows(journals: Array, level_id: String) -> Array[String]:
	var errors: Array[String] = []
	var seen_entry_ids := {}
	for row in journals:
		if row == null:
			continue

		if seen_entry_ids.has(row.id):
			errors.append("[LevelRows] Duplicate journal entry ID %s for %s" % [row.id, level_id])
		else:
			seen_entry_ids[row.id] = true
	return errors


func _validate_roster_rows(rows: Array, level_id: String, width: int, height: int, coord_map: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for row in rows:
		if row == null:
			continue
		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Roster row %s is out of bounds for %s" % [row.resource_path, level_id])
		var key := _coord_key(row.coord)
		if coord_map.has(key):
			var existing_row = coord_map[key]
			errors.append("[LevelRows] Duplicate roster coordinate %s found at %s (first defined in %s, then in %s) for %s" % [row.coord, key, existing_row.resource_path, row.resource_path, level_id])
		else:
			coord_map[key] = row

		# Validate loyalty if specified
		if "loyalty_type" in row:
			var valid_loyalties = [
				GameConstants.Loyalty.FRIENDLY,
				GameConstants.Loyalty.NEUTRAL,
				GameConstants.Loyalty.ENEMY,
				GameConstants.Loyalty.STATIC
			]
			if not row.loyalty_type in valid_loyalties:
				errors.append("[LevelRows] roster row %s has invalid loyalty value: %s for %s" % [row.resource_path, row.loyalty_type, level_id])

	return errors

func _validate_loot_rows(rows: Array, level_id: String, width: int, height: int) -> Array[String]:
	var errors: Array[String] = []
	var coords := {}
	for row in rows:
		if row == null:
			continue
		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Loot row %s is out of bounds for %s" % [row.resource_path, level_id])
		var key := _coord_key(row.coord)
		if coords.has(key):
			var existing_row = coords[key]
			errors.append("[LevelRows] Duplicate loot coordinate %s found at %s (first defined in %s, then in %s) for %s" % [row.coord, key, existing_row.resource_path, row.resource_path, level_id])
		else:
			coords[key] = row
	return errors

func _validate_location_rows(rows: Array, level_id: String, width: int, height: int, coord_map: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for row in rows:
		if row == null:
			continue

		# Validate loyalty if specified
		if "loyalty" in row:
			var valid_loyalties = [
				GameConstants.Loyalty.FRIENDLY,
				GameConstants.Loyalty.NEUTRAL,
				GameConstants.Loyalty.ENEMY,
				GameConstants.Loyalty.STATIC
			]
			if not row.loyalty in valid_loyalties:
				errors.append("[LevelRows] location row %s has invalid loyalty value: %s for %s" % [row.resource_path, row.loyalty, level_id])


		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] location row %s is out of bounds for %s" % [row.resource_path, level_id])

		var key := _coord_key(row.coord)
		if coord_map.has(key):
			var existing_row = coord_map[key]
			errors.append("[LevelRows] Duplicate location coordinate %s found at %s (first defined in %s, then in %s) for %s" % [row.coord, key, existing_row.resource_path, row.resource_path, level_id])
		else:
			coord_map[key] = row
	return errors

func _validate_start_rows(rows: Array, level_id: String, width: int, height: int, roster_coords: Dictionary, location_coords: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var player_slots := {}
	var start_coords := {}
	var allowed_factions := {&"player": true, &"neutral": true, &"enemy": true}
	for row in rows:
		if row == null:
			continue
		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Start row %s is out of bounds for %s" % [row.resource_path, level_id])
		var faction_key: StringName
		match row.faction:
			Unit.Faction.PLAYER: faction_key = &"player"
			Unit.Faction.ENEMY: faction_key = &"enemy"
			Unit.Faction.NEUTRAL: faction_key = &"neutral"
			_: faction_key = &"player" # Default to player if unspecified or invalid
		var slot_index := int(row.slot_index)
		var slot_id := "%s:%s" % [faction_key, slot_index]
		if player_slots.has(slot_id):
			var existing_row = player_slots[slot_id]
			errors.append("[LevelRows] Duplicate start slot %s found at %s (first defined in %s, then in %s) for %s" % [slot_id, row.coord, existing_row.resource_path, row.resource_path, level_id])
		else:
			player_slots[slot_id] = row
		var coord_key := _coord_key(row.coord)
		if start_coords.has(coord_key):
			var existing_row = start_coords[coord_key]
			errors.append("[LevelRows] Duplicate start coordinate %s found at %s (first defined in %s, then in %s) for %s" % [row.coord, coord_key, existing_row.resource_path, row.resource_path, level_id])
		else:
			start_coords[coord_key] = row
		if roster_coords.has(coord_key):
			var overlapping_roster_row = roster_coords[coord_key]
			errors.append("[LevelRows] Start coordinate %s (%s) overlaps enemy spawn (%s) for %s" % [row.resource_path, row.coord, overlapping_roster_row.resource_path, level_id])
		if location_coords.has(coord_key):
			var overlapping_location_row = location_coords[coord_key]
			errors.append("[LevelRows] Start coordinate %s (%s) overlaps location (%s) for %s" % [row.resource_path, row.coord, overlapping_location_row.resource_path, level_id])
		if not allowed_factions.has(faction_key):
			errors.append("[LevelRows] Unknown start faction %s (defined in %s) for %s" % [faction_key, row.resource_path, level_id])
		elif faction_key != &"player" and row.unit_scene == null:
			errors.append("[LevelRows] %s start row %s missing unit scene" % [faction_key, row.resource_path])
	return errors

const DIALOGUE_BLOCKED_TYPES: Array[String] = ["enemy_spawn", "player_start", "neutral_start", "location"]

func _validate_dialogue_rows(rows: Array, level_id: String, width: int, height: int) -> Array[String]:
	var errors: Array[String] = []
	for row in rows:
		if row == null:
			continue
		# Allow (-999, -999) for dialogues that aren't triggers in the world
		if row.coord != Vector2i(-999, -999) and not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Dialogue row %s is out of bounds for %s" % [row.resource_path, level_id])
	return errors

func _validate_task_rows(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array) -> Array[String]:
	var errors: Array[String] = []
	if level == null or level.objective == null:
		return errors
	# Build row-scoped sets and willpower lookups
	var loot_item_ids := {}
	var loot_willpowers_by_coord := {}
	for lr in loot_rows:
		if lr == null:
			continue
		for it in lr.items:
			if it and it is InventoryItem:
				loot_item_ids[(it as InventoryItem).origin_id] = true
		if lr.stats:
			loot_willpowers_by_coord[_coord_key(lr.coord)] = lr.stats.willpower

	var npc_unit_ids := {}
	var npc_item_ids := {}
	for rr in roster_rows:
		if rr == null:
			continue
		var uid := String(rr.unit_id) if "unit_id" in rr else ""
		if not uid.is_empty():
			npc_unit_ids[uid] = true
		if "inventory" in rr:
			for it in rr.inventory:
				if it and it is InventoryItem:
					npc_item_ids[(it as InventoryItem).origin_id] = true

	var location_ids := {}
	var location_coords := {}
	var location_willpowers_by_id := {}
	var location_willpowers_by_coord := {}
	var location_coords_by_id := {}
	for loc in location_rows:
		if loc == null:
			continue
		var lid := String(loc.loc_id) if "loc_id" in loc else String(loc.loc_name) if "loc_name" in loc else ""
		if not lid.is_empty():
			location_ids[lid] = true
			if loc.stats:
				location_willpowers_by_id[lid] = loc.stats.willpower
			location_coords_by_id[lid] = loc.coord

		location_coords[_coord_key(loc.coord)] = true
		if loc.stats:
			location_willpowers_by_coord[_coord_key(loc.coord)] = loc.stats.willpower

	# Iterate tasks in stages
	var obj := level.objective
	if not obj or not obj.stages:
		return errors
	for st in obj.stages:
		if st == null:
			continue
		for t in st.tasks:
			if t == null:
				continue
			# Enforce duration/effort exclusivity
			if t.duration_turns > 0 and t.effort_required > 0:
				push_warning("[LevelRows] Task %s has both duration and effort; preferring duration for %s" % [String(t.id), level_id])
				t.effort_required = 0

			# Validate target when target_kind is set
			var kind := String(t.target_kind)
			var target_id := String(t.target_id)
			var target_coord := t.target_coord

			if kind == "item":
				var ok := loot_item_ids.has(target_id) or npc_item_ids.has(target_id)
				if not ok:
					errors.append("[LevelRows] Task %s item target '%s' not found in loot/NPC inventories for %s" % [String(t.id), target_id, level_id])

				# Check willpower sync if coordinate is known
				if target_coord != Vector2i(-999, -999):
					var key = _coord_key(target_coord)
					if loot_willpowers_by_coord.has(key):
						var wp = loot_willpowers_by_coord[key]
						if t.effort_required != wp:
							errors.append("[LevelRows] Task %s effort_required (%d) misaligned with loot willpower (%d) for %s" % [String(t.id), t.effort_required, wp, level_id])

			elif kind == "location":
				var id_ok := not target_id.is_empty() and location_ids.has(target_id)
				var coord_ok := (target_coord != Vector2i(-999, -999)) and location_coords.has(_coord_key(target_coord))

				if not (id_ok or coord_ok):
					errors.append("[LevelRows] Task %s location target not found (id '%s', coord %s) for %s" % [String(t.id), target_id, target_coord, level_id])
				else:
					# Check for coordinate sync
					if id_ok and target_coord == Vector2i(-999, -999):
						errors.append("[LevelRows] Task %s is missing target_coord but has target_id '%s' for %s" % [String(t.id), target_id, level_id])
					elif id_ok and coord_ok:
						var expected_coord = location_coords_by_id[target_id]
						if target_coord != expected_coord:
							errors.append("[LevelRows] Task %s target_coord %s does not match location '%s' at %s for %s" % [String(t.id), target_coord, target_id, expected_coord, level_id])

					# Check willpower sync
					var target_willpower = -1
					if id_ok:
						target_willpower = location_willpowers_by_id.get(target_id, -1)
					elif coord_ok:
						target_willpower = location_willpowers_by_coord.get(_coord_key(target_coord), -1)

					if target_willpower != -1 and t.effort_required != target_willpower:
						errors.append("[LevelRows] Task %s effort_required (%d) misaligned with location willpower (%d) for %s" % [String(t.id), t.effort_required, target_willpower, level_id])

			elif kind == "unit":
				if target_id.is_empty() or not npc_unit_ids.has(target_id):
					errors.append("[LevelRows] Task %s unit target '%s' not found among non-player spawns for %s" % [String(t.id), target_id, level_id])
	return errors

func _validate_dialogue_journal_links(dialogue_rows: Array, journal_rows: Array, level_id: String, objective: Objective = null) -> Array[String]:
	var errors: Array[String] = []

	# Build lookup of dialogue entry_ids
	var dialogue_ids := {}
	for row in dialogue_rows:
		if row == null:
			continue
		var id := String(row.entry_id)
		if not id.is_empty():
			dialogue_ids[id] = row

	# Build lookup of journal entries by ID and related_id
	var journal_ids := {}
	var journal_by_related := {}
	for j in journal_rows:
		if j == null:
			continue
		var jid := String(j.id)
		if not jid.is_empty():
			journal_ids[jid] = j

		var rel := String(j.related_id)
		if not rel.is_empty():
			if journal_by_related.has(rel):
				errors.append("[LevelRows] Duplicate journal related_id %s for %s" % [rel, level_id])
			journal_by_related[rel] = j

	# Collect explicit links from objective/stages/tasks
	var explicit_dialogue_whitelists := {}
	var explicit_journal_whitelists := {}
	if objective:
		for stage in objective.stages:
			if stage:
				# Stage level
				_add_explicit_links(stage, explicit_dialogue_whitelists, explicit_journal_whitelists)
				# Task level
				for task in stage.tasks:
					if task:
						_add_explicit_links(task, explicit_dialogue_whitelists, explicit_journal_whitelists)

	# Ensure every dialogue has a corresponding journal (either by related_id or explicit whitelist)
	for id in dialogue_ids.keys():
		if not journal_by_related.has(id) and not explicit_dialogue_whitelists.has(id):
			errors.append("[LevelRows] Dialogue entry_id %s missing related journal entry for %s" % [id, level_id])

	# Ensure every journal with a related_id points to an existing dialogue
	for rel in journal_by_related.keys():
		if not dialogue_ids.has(rel) and not explicit_journal_whitelists.has(rel):
			var jrow = journal_by_related[rel]
			errors.append("[LevelRows] Journal entry %s related_id %s has no matching dialogue for %s" % [jrow.id, rel, level_id])

	return errors

func _add_explicit_links(obj: Resource, d_white: Dictionary, j_white: Dictionary) -> void:
	if "enter_dialogue_id" in obj and not String(obj.enter_dialogue_id).is_empty():
		d_white[String(obj.enter_dialogue_id)] = true
	if "enter_journal_id" in obj and not String(obj.enter_journal_id).is_empty():
		j_white[String(obj.enter_journal_id)] = true
	if "exit_dialogue_id" in obj and not String(obj.exit_dialogue_id).is_empty():
		d_white[String(obj.exit_dialogue_id)] = true
	if "exit_journal_id" in obj and not String(obj.exit_journal_id).is_empty():
		j_white[String(obj.exit_journal_id)] = true

func _is_in_bounds(coord: Vector2i, width: int, height: int) -> bool:
	return CoordValidator.is_in_bounds(coord, width, height)

func _coord_key(coord: Vector2i) -> String:
	return CoordValidator.key_of(coord)

func _validate_connectivity(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array, start_rows: Array) -> Array[String]:
	if level.terrain_data == null or level.terrain_data.terrain_rows.is_empty(): return []

	var dims := GridUtils.dims_of(level)
	var player_starts: Array[Vector2i] = []
	for row in start_rows:
		if row and row.faction == Unit.Faction.PLAYER: player_starts.append(row.coord)
	if player_starts.is_empty(): return []

	var poi_map := _collect_pois(level, roster_rows, loot_rows, location_rows, int(dims.width), int(dims.height))

	var terrain_map := TerrainMap.new()
	terrain_map.set_offset_axis(int(dims.axis))
	terrain_map.load_from_rows(level.terrain_data.terrain_rows, int(dims.width), int(dims.height))

	var start_coord = player_starts[0]
	if not terrain_map.is_passable(start_coord):
		return ["[Connectivity] Primary player start at %s is on impassable terrain for %s" % [start_coord, level_id]]

	var reachable := _perform_reachability_scan(start_coord, terrain_map, int(dims.width), int(dims.height), int(dims.axis))
	return _report_connectivity_errors(poi_map, player_starts, reachable, level_id)

func _collect_pois(level: Level, roster_rows: Array, loot_rows: Array, location_rows: Array, width: int, height: int) -> Dictionary:
	var poi_map := {}
	var add_poi = func(p_coord: Vector2i, label: String):
		if not CoordValidator.is_in_bounds(p_coord, width, height): return
		var key = CoordValidator.key_of(p_coord)
		if not poi_map.has(key): poi_map[key] = []
		poi_map[key].append(label)

	for row in roster_rows:
		if row: add_poi.call(row.coord, "Roster entry (%s)" % row.resource_path.get_file())
	for row in loot_rows:
		if row: add_poi.call(row.coord, "Loot entry (%s)" % row.resource_path.get_file())
	for row in location_rows:
		if row: add_poi.call(row.coord, "Location entry (%s)" % row.resource_path.get_file())

	if level.objective:
		for stage in level.objective.stages:
			if stage:
				for task in stage.tasks:
					if task and task.target_coord != Vector2i(-999, -999):
						add_poi.call(task.target_coord, "Task target '%s'" % task.title)
	return poi_map

func _perform_reachability_scan(start_coord: Vector2i, terrain_map: TerrainMap, width: int, height: int, axis: int) -> Dictionary:
	var reachable := {}
	var queue: Array[Vector2i] = [start_coord]
	reachable[CoordValidator.key_of(start_coord)] = true

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var neighbors = HexNavigator.get_neighbor_offsets(current, axis)
		for offset: Vector2i in neighbors:
			var next = current + offset
			if not CoordValidator.is_in_bounds(next, width, height): continue
			var key = CoordValidator.key_of(next)
			if reachable.has(key) or not terrain_map.is_passable(next): continue
			reachable[key] = true
			queue.append(next)
	return reachable

func _report_connectivity_errors(poi_map: Dictionary, player_starts: Array[Vector2i], reachable: Dictionary, level_id: String) -> Array[String]:
	var errors: Array[String] = []
	for key in poi_map.keys():
		if not reachable.has(key):
			for desc in poi_map[key]:
				errors.append("[Connectivity] %s at %s is unreachable from player start for %s" % [desc, key, level_id])

	for i in range(1, player_starts.size()):
		var ps = player_starts[i]
		if not reachable.has(CoordValidator.key_of(ps)):
			errors.append("[Connectivity] Player start at %s is unreachable from primary player start for %s" % [ps, level_id])
	return errors
