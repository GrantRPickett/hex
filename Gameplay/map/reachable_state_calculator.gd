class_name ReachableStateCalculator
extends RefCounted

const MapDiscovery = preload("res://Gameplay/targets/discovery/map_discovery.gd")

static func calculate(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int = -1, movement_origin: Vector2i = Vector2i.MAX, action_origin: Vector2i = Vector2i.MAX) -> Dictionary:
	if not is_instance_valid(unit):
		return {
			"movement_origin": Vector2i(-999, -999),
			"action_origin": Vector2i(-999, -999),
			"coords": [],
			"lookup": {},
			"move_spaces": 0,
			"unit_index": - 1
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
		if unit.movement.has_tentative_move():
			resolved_action_origin = unit.movement.get_tentative_grid_coord()

	var reachable_coords: Array[Vector2i] = []
	var reachable_lookup := {}
	var move_budget := unit.movement.get_remaining_movement_points() if unit.movement else 0
	if move_budget <= 0:
		move_budget = unit.movement.get_max_movement_points() if unit.movement else 0
	if resolved_action_origin != Vector2i.MAX:
		reachable_coords.append(resolved_action_origin)
		reachable_lookup[resolved_action_origin] = {"remaining": move_budget, "cost": 0}

	var reachable_move_spaces := 0
	if unit.movement.has_move_available() and terrain_map:
		var movement_range = unit.movement.compute_movement_range(resolved_movement_origin, terrain_map)
		if not movement_range.is_empty():
			for coord in movement_range.keys():
				var coord_v2: Vector2i = coord
				var already_present := reachable_lookup.has(coord_v2)
				if not already_present:
					reachable_coords.append(coord_v2)
				var move_cost = int(movement_range.get(coord_v2, move_budget))
				var remaining_points = move_budget - move_cost
				if remaining_points < 0:
					remaining_points = 0
				var should_update := true
				if already_present:
					var existing = reachable_lookup[coord_v2]
					var existing_cost := INF
					if existing is Dictionary:
						existing_cost = int(existing.get("cost", INF))
					elif existing is int or existing is float:
						existing_cost = int(existing)
					if move_cost >= existing_cost:
						should_update = false
				if should_update:
					reachable_lookup[coord_v2] = {"remaining": remaining_points, "cost": move_cost}
				if (not already_present) and (unit_manager == null or resolved_index < 0 or not MapDiscovery.is_occupied(unit_manager, coord_v2, resolved_index)):
					reachable_move_spaces += 1

	return {
		"movement_origin": resolved_movement_origin,
		"action_origin": resolved_action_origin,
		"coords": reachable_coords,
		"lookup": reachable_lookup,
		"move_spaces": reachable_move_spaces,
		"unit_index": resolved_index
	}
