class_name ReachableStateCalculator
extends RefCounted

static func calculate(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int = -1, movement_origin: Vector2i = Vector2i.MAX, action_origin: Vector2i = Vector2i.MAX) -> Dictionary:
	if not is_instance_valid(unit):
		return {
			"movement_origin": Vector2i(-999, -999),
			"action_origin": Vector2i(-999, -999),
			"coords": [],
			"lookup": {},
			"move_spaces": 0,
			"unit_index": -1
		}

	var resolved_index := unit_index
	if resolved_index < 0 and unit_manager:
		resolved_index = unit_manager.get_unit_index(unit)

	var resolved_movement_origin := movement_origin
	if resolved_movement_origin == Vector2i.MAX:
		resolved_movement_origin = unit.get_grid_location()
		if unit_manager and resolved_index >= 0:
			var manager_coord = unit_manager.get_coord(resolved_index)
			if manager_coord != Vector2i(-999, -999):
				resolved_movement_origin = manager_coord

	var resolved_action_origin := action_origin
	if resolved_action_origin == Vector2i.MAX:
		resolved_action_origin = resolved_movement_origin
		if unit.has_tentative_move():
			resolved_action_origin = unit.get_tentative_grid_coord()

	var reachable_coords: Array[Vector2i] = []
	var reachable_lookup := {}
	if resolved_action_origin != Vector2i.MAX:
		reachable_coords.append(resolved_action_origin)
		reachable_lookup[resolved_action_origin] = true

	var reachable_move_spaces := 0
	if unit.has_move_available() and terrain_map:
		var movement_range = unit.compute_movement_range(resolved_movement_origin, terrain_map)
		if not movement_range.is_empty():
			for coord in movement_range.keys():
				var coord_v2: Vector2i = coord
				if not reachable_lookup.has(coord_v2):
					reachable_coords.append(coord_v2)
					reachable_lookup[coord_v2] = true
				if unit_manager == null or resolved_index < 0 or not unit_manager.is_occupied(coord_v2, resolved_index):
					reachable_move_spaces += 1

	return {
		"movement_origin": resolved_movement_origin,
		"action_origin": resolved_action_origin,
		"coords": reachable_coords,
		"lookup": reachable_lookup,
		"move_spaces": reachable_move_spaces,
		"unit_index": resolved_index
	}
