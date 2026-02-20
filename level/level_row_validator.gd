extends RefCounted
class_name LevelRowValidator

func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array, terrain_rows: Array, start_rows: Array, dialogue_rows: Array, journal_entry_rows: Array, meta_rows: Array) -> Array[String]:
	print_debug("[LevelRowValidator] Validating level: %s" % level_id)
	var errors: Array[String] = []
	var width := 1
	var height := 1
	if level and level.terrain_data:
		width = max(1, int(level.terrain_data.grid_width))
		height = max(1, int(level.terrain_data.grid_height))

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
	if errors.size() > 0:
		print_debug("[LevelRowValidator] Validation failed for %s with %d errors." % [level_id, errors.size()])
		for err in errors:
			push_warning(err)
	else:
		print_debug("[LevelRowValidator] Validation passed for %s." % level_id)
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
			errors.append("[LevelRows] Duplicate roster coordinate %s for %s" % [row.coord, level_id])
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
			errors.append("[LevelRows] Duplicate loot coordinate %s for %s" % [row.coord, level_id])
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
			errors.append("[LevelRows] Duplicate location coordinate %s for %s" % [row.coord, level_id])
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
			errors.append("[LevelRows] Duplicate start slot %s for %s" % [slot_id, level_id])
		else:
			player_slots[slot_id] = row
		var coord_key := _coord_key(row.coord)
		if start_coords.has(coord_key):
			errors.append("[LevelRows] Duplicate start coordinate %s for %s" % [row.coord, level_id])
		else:
			start_coords[coord_key] = row
		if roster_coords.has(coord_key):
			errors.append("[LevelRows] Start coordinate %s overlaps enemy spawn for %s" % [row.coord, level_id])
		if location_coords.has(coord_key):
			errors.append("[LevelRows] Start coordinate %s overlaps location for %s" % [row.coord, level_id])
		if not allowed_factions.has(faction_key):
			errors.append("[LevelRows] Unknown start faction %s for %s" % [faction_key, level_id])
		elif faction_key != &"player" and row.unit_scene == null:
			errors.append("[LevelRows] %s start row %s missing unit scene" % [faction_key, row.resource_path])
	return errors

func _validate_dialogue_rows(rows: Array, level_id: String, width: int, height: int) -> Array[String]:
	var errors: Array[String] = []
	for row in rows:
		if row == null:
			continue
		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Dialogue row %s is out of bounds for %s" % [row.resource_path, level_id])
	return errors

func _is_in_bounds(coord: Vector2i, width: int, height: int) -> bool:
	return coord.x >= 1 and coord.y >= 1 and coord.x <= width and coord.y <= height

func _coord_key(coord: Vector2i) -> String:
	return "%s,%s" % [coord.x, coord.y]
