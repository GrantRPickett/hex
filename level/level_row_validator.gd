extends RefCounted
class_name LevelRowValidator

func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array, terrain_rows: Array, start_rows: Array, dialogue_rows: Array, journal_entry_rows: Array, meta_rows: Array) -> Array[String]:
	LevelLog.debug("[LevelRowValidator] Validating level: %s" % level_id)
	var errors: Array[String] = []
	var dims := GridUtils.dims_of(level)
	var width := int(dims.width)
	var height := int(dims.height)

	errors += _validate_meta_rows(meta_rows, level_id)
	errors += _validate_terrain_rows(terrain_rows, level_id, width, height)
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
	errors += _validate_dialogue_journal_links(dialogue_rows, journal_entry_rows, level_id)
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

func _validate_meta_rows(rows: Array, level_id: String) -> Array[String]:
	var errors: Array[String] = []
	if rows.size() > 1:
		errors.append("[LevelRows] Multiple meta rows defined for %s" % [level_id])
	return errors

func _validate_terrain_rows(rows: Array, level_id: String, width: int, height: int) -> Array[String]:
	var errors: Array[String] = []
	if rows.is_empty():
		return errors
	var seen := {}
	for row in rows:
		if row == null:
			continue
		if seen.has(row.row_index):
			errors.append("[LevelRows] Duplicate terrain row index %s for %s" % [row.row_index, level_id])
		else:
			seen[row.row_index] = true
		if row.row_data.length() != width:
			errors.append("[LevelRows] Terrain row %s has length %s but width is %s" % [row.resource_path, row.row_data.length(), width])
	if height > 0 and seen.size() != height:
		errors.append("[LevelRows] Terrain row count %s does not match grid height %s for %s" % [seen.size(), height, level_id])
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
		var faction_key: StringName = row.faction if row.faction != StringName("") else &"player"
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
	# Build quick coord maps from other row types if available via previous validators
	# Note: This validator receives only dialogue rows here; overlap checks against
	# gameplay-critical elements belong to runtime autofix. We only ensure bounds.
	for row in rows:
		if row == null:
			continue
		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Dialogue row %s is out of bounds for %s" % [row.resource_path, level_id])
	return errors

func _validate_task_rows(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array) -> Array[String]:
	var errors: Array[String] = []
	if level == null or level.objective == null:
		return errors
	# Build row-scoped sets
	var loot_item_ids := {}
	for lr in loot_rows:
		if lr == null:
			continue
		for it in lr.items:
			if it and it is InventoryItem:
				loot_item_ids[(it as InventoryItem).origin_id] = true
	var npc_unit_ids := {}
	var npc_item_ids := {}
	for rr in roster_rows:
		if rr == null:
			continue
		# Non-player spawns are enemy/neutral according to row API (assumed)
		var uid := String(rr.unit_id) if "unit_id" in rr else ""
		if not uid.is_empty():
			npc_unit_ids[uid] = true
		if "inventory" in rr:
			for it in rr.inventory:
				if it and it is InventoryItem:
					npc_item_ids[(it as InventoryItem).origin_id] = true
	var location_ids := {}
	var location_coords := {}
	for loc in location_rows:
		if loc == null:
			continue
		var lid := String(loc.loc_id) if "loc_id" in loc else String(loc.loc_name) if "loc_name" in loc else ""
		if not lid.is_empty():
			location_ids[lid] = true
		location_coords[_coord_key(loc.coord)] = true
	# Iterate tasks in stages
	var obj := level.objective
	if not obj or not obj.stages:
		return errors
	for st in obj.stages:
		if st == null:
			continue
		var to_remove: Array = []
		for t in st.tasks:
			if t == null:
				continue
			# Enforce duration/effort exclusivity
			if t.duration_turns > 0 and t.effort_required > 0:
				push_warning("[LevelRows] Task %s has both duration and effort; preferring duration for %s" % [String(t.id), level_id])
				t.effort_required = 0
			# Validate target when target_kind is set
			var kind := String(t.target_kind)
			if kind == "item":
				var ok := loot_item_ids.has(t.target_id) or npc_item_ids.has(t.target_id)
				if not ok:
					errors.append("[LevelRows] Task %s item target '%s' not found in loot/NPC inventories for %s" % [String(t.id), t.target_id, level_id])
					to_remove.append(t)
			elif kind == "location":
				var id_ok := not String(t.target_id).is_empty() and location_ids.has(t.target_id)
				var coord_ok := (t.target_coord != Vector2i(-999, -999)) and location_coords.has(_coord_key(t.target_coord))
				if not (id_ok or coord_ok):
					errors.append("[LevelRows] Task %s location target not found (id '%s', coord %s) for %s" % [String(t.id), t.target_id, t.target_coord, level_id])
					to_remove.append(t)
			elif kind == "unit":
				if String(t.target_id).is_empty() or not npc_unit_ids.has(t.target_id):
					errors.append("[LevelRows] Task %s unit target '%s' not found among non-player spawns for %s" % [String(t.id), t.target_id, level_id])
					to_remove.append(t)
		# Remove invalid tasks from the stage
		for rem in to_remove:
			st.tasks.erase(rem)
	return errors

func _validate_dialogue_journal_links(dialogue_rows: Array, journal_rows: Array, level_id: String) -> Array[String]:
	var errors: Array[String] = []
	# Build lookup of dialogue entry_ids
	var dialogue_ids := {}
	for row in dialogue_rows:
		if row == null:
			continue
		var id := String(row.entry_id)
		if not id.is_empty():
			dialogue_ids[id] = row
	# Build lookup of journal entries by related_id (only non-empty)
	var journal_by_related := {}
	for j in journal_rows:
		if j == null:
			continue
		var rel := String(j.related_id)
		if rel.is_empty():
			continue
		if journal_by_related.has(rel):
			errors.append("[LevelRows] Duplicate journal related_id %s for %s" % [rel, level_id])
		journal_by_related[rel] = j
	# Ensure every dialogue has a corresponding journal (by related_id)
	for id in dialogue_ids.keys():
		if not journal_by_related.has(id):
			errors.append("[LevelRows] Dialogue entry_id %s missing related journal entry for %s" % [id, level_id])
	# Ensure every journal with a related_id points to an existing dialogue
	for rel in journal_by_related.keys():
		if not dialogue_ids.has(rel):
			var jrow = journal_by_related[rel]
			errors.append("[LevelRows] Journal entry %s related_id %s has no matching dialogue for %s" % [jrow.id, rel, level_id])
	return errors

func _is_in_bounds(coord: Vector2i, width: int, height: int) -> bool:
	return CoordValidator.is_in_bounds(coord, width, height)

func _coord_key(coord: Vector2i) -> String:
	return CoordValidator.key_of(coord)
