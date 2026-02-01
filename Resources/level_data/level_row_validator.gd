extends RefCounted
class_name LevelRowValidator

func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, goal_rows: Array, terrain_rows: Array, start_rows: Array, dialogue_rows: Array, meta_rows: Array, had_existing_loot: bool) -> Array[String]:
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
	errors += _validate_loot_rows(loot_rows, level_id, width, height, had_existing_loot)
	var goal_coord_map := {}
	errors += _validate_goal_rows(goal_rows, level_id, width, height, goal_coord_map)
	errors += _validate_start_rows(start_rows, level_id, width, height, roster_coord_map, goal_coord_map)
	errors += _validate_dialogue_rows(dialogue_rows, level_id, width, height)
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

func _validate_loot_rows(rows: Array, level_id: String, width: int, height: int, had_existing_loot: bool) -> Array[String]:
	var errors: Array[String] = []
	if had_existing_loot and rows.is_empty():
		errors.append("[LevelRows] Missing loot rows for %s" % [level_id])
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

func _validate_goal_rows(rows: Array, level_id: String, width: int, height: int, coord_map: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for row in rows:
		if row == null:
			continue
		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Goal row %s is out of bounds for %s" % [row.resource_path, level_id])
		var key := _coord_key(row.coord)
		if coord_map.has(key):
			errors.append("[LevelRows] Duplicate goal coordinate %s for %s" % [row.coord, level_id])
		else:
			coord_map[key] = row
	return errors

func _validate_start_rows(rows: Array, level_id: String, width: int, height: int, roster_coords: Dictionary, goal_coords: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var player_slots := {}
	var start_coords := {}
	for row in rows:
		if row == null:
			continue
		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Start row %s is out of bounds for %s" % [row.resource_path, level_id])
		var slot_key: StringName = row.faction if row.faction != StringName("") else &"player"
		var slot_index := int(row.slot_index)
		var slot_id := "%s:%s" % [slot_key, slot_index]
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
		if goal_coords.has(coord_key):
			errors.append("[LevelRows] Start coordinate %s overlaps goal for %s" % [row.coord, level_id])
		if row.faction != StringName("") and row.faction != StringName("player") and row.faction != StringName("neutral"):
			errors.append("[LevelRows] Unknown start faction %s for %s" % [row.faction, level_id])
		if row.faction == StringName("neutral") and row.unit_scene == null:
			errors.append("[LevelRows] Neutral start row %s missing unit scene" % [row.resource_path])
	return errors

func _validate_dialogue_rows(rows: Array, level_id: String, width: int, height: int) -> Array[String]:
	var errors: Array[String] = []
	for row in rows:
		if row == null:
			continue
		if row.timeline == null and row.timeline_path.is_empty():
			errors.append("[LevelRows] Dialogue row %s missing timeline reference" % [row.resource_path])
		if not _is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Dialogue row %s is out of bounds for %s" % [row.resource_path, level_id])
	return errors

func _is_in_bounds(coord: Vector2i, width: int, height: int) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < width and coord.y < height

func _coord_key(coord: Vector2i) -> String:
	return "%s,%s" % [coord.x, coord.y]
