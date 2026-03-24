## Service for calculating movement ranges and paths on a hexagonal grid.
##
## This service combines logic from legacy ReachableStateCalculator and MovementRangeCalculator
## to provide a unified entry point for all reachability queries.
class_name MovementRangeService
extends RefCounted

## Calculates the reachable state for a unit.
static func calculate_reachable_state(unit: Unit, terrain_map: TerrainMap, unit_manager: UnitManager, unit_index: int = -1) -> ReachableState:
	if not is_instance_valid(unit):
		return ReachableState.create_empty()

	var resolved_index : int = unit_index
	if resolved_index < 0 and unit_manager:
		resolved_index = unit_manager.get_unit_index(unit)

	var movement_origin: Vector2i = unit.get_grid_location()
	var move_budget : int = unit.movement.get_remaining_movement_points() if unit.movement else 0
	
	# If there's a tentative move, we calculate further reachability from that destination
	# using the remaining points after that move.
	if unit.movement and unit.movement.has_tentative_move():
		movement_origin = unit.movement.get_tentative_grid_coord()
		move_budget = max(0, move_budget - unit.movement.get_tentative_cost())

	var action_origin = movement_origin
	var reachable_coords: Array[Vector2i] = []
	var reachable_lookup : Dictionary = {}
	var reachable_move_spaces := 0

	# Ensure action origin is included
	reachable_coords.append(action_origin)
	reachable_lookup[action_origin] = {"remaining": move_budget, "cost": 0}

	if unit.movement and unit.movement.has_move_available() and terrain_map and move_budget > 0:
		var movement_range: Dictionary = unit.movement.compute_movement_range(movement_origin, terrain_map, move_budget)
		for coord in movement_range.keys():
			var coord_v2: Vector2i = coord
			var move_cost: int = int(movement_range[coord_v2])
			
			if not reachable_lookup.has(coord_v2):
				var is_occupied := unit_manager != null and unit_manager.is_occupied(coord_v2, resolved_index)
				
				# Only valid end spots are considered "reachable" for common visual purposes (coords)
				# and count towards the total number of reachable move spaces.
				if not is_occupied:
					reachable_coords.append(coord_v2)
					reachable_move_spaces += 1
			
				var remaining = move_budget - move_cost
				reachable_lookup[coord_v2] = {"remaining": max(0, remaining), "cost": move_cost}

	var state: ReachableState = ReachableState.new()
	state.movement_origin = movement_origin
	state.action_origin = action_origin
	state.coords = reachable_coords
	state.lookup = reachable_lookup
	state.move_spaces = reachable_move_spaces
	state.unit_index = resolved_index
	return state

## Finds a path between two coordinates using Dijkstra/A* logic.
static func find_path(start: Vector2i, target: Vector2i, budget: int, terrain_map: TerrainMap, unit_manager: UnitManager = null, unit_index: int = -1) -> Array[Vector2i]:
	if start == target: return []
	
	var calculator := MovementRangeCalculator.new()
	
	var pass_through_blockers := {}
	var stop_blockers := {}
	
	if unit_manager:
		var unit: Unit = unit_manager.get_unit(unit_index) if unit_index >= 0 else null
		if is_instance_valid(unit) and unit.movement:
			pass_through_blockers = unit.movement.get_pass_through_blockers(unit_manager)
			stop_blockers = unit.movement.get_stop_blockers(unit_manager, target)
		else:
			# Fallback if no unit behavior available (treat all as stop blockers)
			for i in range(unit_manager.get_unit_count()):
				if i != unit_index:
					var coord: Vector2i = unit_manager.get_coord(i)
					if coord == target:
						stop_blockers[coord] = true
	
	# Compute reachable set with pass-through blockers
	var reachable: Dictionary = calculator.compute(start, budget, terrain_map, pass_through_blockers)
	
	# find_path uses blocked_hexes for both passing and stopping.
	# We already handled passing via 'reachable' set.
	# So blocked_hexes here should be stop_blockers.
	return calculator.find_path(target, start, reachable, terrain_map, budget, {}, stop_blockers)
