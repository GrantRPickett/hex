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
	
	# Delegated to specialized validators
	errors += DialogueValidator.validate_rows(dialogue_rows, level_id, width, height)
	errors += _validate_journal_entry_rows(journal_entry_rows, level_id)
	
	# Task target/duration validation using only level row data (no runtime snapshot)
	errors += TaskRowValidator.validate(level, level_id, roster_rows, loot_rows, location_rows)
	
	# Cross-validate dialogue/journal linkage by entry_id <-> related_id
	errors += DialogueValidator.validate_journal_links(dialogue_rows, journal_entry_rows, level_id, level.objective)

	# Connectivity validation
	errors += ConnectivityValidator.validate(level, level_id, roster_rows, loot_rows, location_rows, start_rows)

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
				GameConstants.Loyalty.Type.PLAYER,
				GameConstants.Loyalty.Type.ENEMY,
				GameConstants.Loyalty.Type.NEUTRAL,
				GameConstants.Loyalty.Type.STATIC
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
				GameConstants.Loyalty.Type.PLAYER,
				GameConstants.Loyalty.Type.ENEMY,
				GameConstants.Loyalty.Type.NEUTRAL,
				GameConstants.Loyalty.Type.STATIC
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

func _is_in_bounds(coord: Vector2i, width: int, height: int) -> bool:
	return GridService.is_in_bounds(coord, width, height)

func _coord_key(coord: Vector2i) -> String:
	return GridService.key_of(coord)
