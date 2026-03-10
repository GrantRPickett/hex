class_name ReachableStateCalculator
extends RefCounted

const MapDiscovery = preload("res://Gameplay/targets/discovery/map_discovery.gd")

static func calculate(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int = -1, movement_origin: Vector2i = Vector2i.MAX, action_origin: Vector2i = Vector2i.MAX) -> ReachableState:
	if not is_instance_valid(unit):
		return ReachableState.create_empty()

	var resolved_index : int = unit_index
	if resolved_index < 0 and unit_manager:
		resolved_index = unit_manager.get_unit_index(unit)

	var origins = _resolve_origins(unit, unit_manager, resolved_index, movement_origin, action_origin)
	var resolved_movement_origin: Vector2i = origins.movement
	var resolved_action_origin: Vector2i = origins.action

	var move_budget : int = unit.movement.get_remaining_movement_points() if unit.movement else 0
	if move_budget <= 0:
		move_budget = unit.movement.get_max_movement_points() if unit.movement else 0

	var move_data = _compute_reachable_move_data(
		unit,
		terrain_map,
		unit_manager,
		resolved_index,
		resolved_movement_origin,
		resolved_action_origin,
		move_budget
	)

	var state = ReachableState.new()
	state.movement_origin = resolved_movement_origin
	state.action_origin = resolved_action_origin
	state.coords = move_data.coords
	state.lookup = move_data.lookup
	state.move_spaces = move_data.move_spaces
	state.unit_index = resolved_index
	return state

static func _resolve_origins(unit: Unit, unit_manager: UnitManager, unit_index: int, movement_origin: Vector2i, action_origin: Vector2i) -> Dictionary:
	var resolved_movement_origin : Vector2i = movement_origin
	if resolved_movement_origin == Vector2i.MAX:
		resolved_movement_origin = unit.get_grid_location()
		if unit_manager and unit_index >= 0:
			var manager_coord = unit_manager.get_coord(unit_index)
			if manager_coord != Vector2i(-999, -999):
				resolved_movement_origin = manager_coord

	var resolved_action_origin : Vector2i = action_origin
	if resolved_action_origin == Vector2i.MAX:
		resolved_action_origin = resolved_movement_origin
		if unit.movement and unit.movement.has_tentative_move():
			resolved_action_origin = unit.movement.get_tentative_grid_coord()

	return {"movement": resolved_movement_origin, "action": resolved_action_origin}

static func _compute_reachable_move_data(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, movement_origin: Vector2i, action_origin: Vector2i, move_budget: int) -> Dictionary:
	var reachable_coords: Array[Vector2i] = []
	var reachable_lookup : Dictionary = {}
	var reachable_move_spaces := 0

	if action_origin != Vector2i.MAX:
		reachable_coords.append(action_origin)
		reachable_lookup[action_origin] = {"remaining": move_budget, "cost": 0}

	if unit.movement and unit.movement.has_move_available() and terrain_map:
		var movement_range = unit.movement.compute_movement_range(movement_origin, terrain_map)
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

				if (not already_present) and (unit_manager == null or unit_index < 0 or not MapDiscovery.is_occupied(unit_manager, coord_v2, unit_index)):
					reachable_move_spaces += 1

	return {
		"coords": reachable_coords,
		"lookup": reachable_lookup,
		"move_spaces": reachable_move_spaces
	}
