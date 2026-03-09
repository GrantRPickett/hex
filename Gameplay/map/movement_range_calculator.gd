class_name MovementRangeCalculator
extends RefCounted

func compute(start: Vector2i, movement_points: int, terrain_map) -> Dictionary:
	if not _validate_compute_inputs(start, movement_points, terrain_map):
		return {}

	var best_cost: Dictionary = {}
	var frontier: Array[Vector2i] = []
	best_cost[start] = 0
	frontier.append(start)

	while not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for coord in frontier:
			_process_compute_node(coord, terrain_map, movement_points, best_cost, next_frontier)
		if next_frontier.is_empty():
			break
		frontier = next_frontier

	best_cost.erase(start)
	return best_cost

func _validate_compute_inputs(start: Vector2i, movement_points: int, terrain_map) -> bool:
	return movement_points > 0 and terrain_map != null and terrain_map.is_within_bounds(start)

func _process_compute_node(coord: Vector2i, terrain_map, movement_points: int, best_cost: Dictionary, next_frontier: Array[Vector2i]) -> void:
	var current_cost: int = best_cost.get(coord, -1)
	if current_cost < 0:
		return

	for neighbor in terrain_map.get_neighbors(coord):
		if not _can_enter_neighbor_compute(neighbor, terrain_map):
			continue

		var step_cost: int = terrain_map.get_movement_cost(neighbor)
		var new_cost: int = current_cost + step_cost
		if new_cost > movement_points:
			continue

		var should_update: bool = not best_cost.has(neighbor) or new_cost < best_cost[neighbor]
		if should_update:
			best_cost[neighbor] = new_cost
			next_frontier.append(neighbor)

func _can_enter_neighbor_compute(neighbor: Vector2i, terrain_map) -> bool:
	return terrain_map.is_within_bounds(neighbor) and terrain_map.is_passable(neighbor)

func find_path(target_coord: Vector2i, start_coord: Vector2i, reachable: Dictionary, terrain_map, movement_budget: int = -1, threatened_hexes: Dictionary = {}, blocked_hexes: Dictionary = {}) -> Array[Vector2i]:
	if start_coord == target_coord:
		return []

	if not reachable.has(target_coord):
		return []

	var budget_limit := movement_budget
	var start_threat: int = 1 if threatened_hexes.has(start_coord) else 0

	var frontier: Array = []
	frontier.append({"coord": start_coord, "cost": 0, "steps": 0, "threat": start_threat})

	var came_from: Dictionary = {start_coord: null}
	var cost_so_far: Dictionary = {start_coord: 0}
	var steps_so_far: Dictionary = {start_coord: 0}
	var threat_so_far: Dictionary = {start_coord: start_threat}

	while not frontier.is_empty():
		var current_entry = _pop_best_frontier_entry(frontier)
		var current_coord: Vector2i = current_entry["coord"]

		if current_coord == target_coord:
			break

		for neighbor in terrain_map.get_neighbors(current_coord):
			if not _is_valid_neighbor_for_path(neighbor, target_coord, reachable, terrain_map, blocked_hexes):
				continue

			_process_path_neighbor(neighbor, current_coord, current_entry, terrain_map, threatened_hexes, budget_limit, came_from, cost_so_far, steps_so_far, threat_so_far, frontier)

	return _reconstruct_path(came_from, start_coord, target_coord)

func _pop_best_frontier_entry(frontier: Array) -> Dictionary:
	var best_index := 0
	var best_cost: int = frontier[0]["cost"]
	var best_steps: int = frontier[0]["steps"]
	var best_threat: int = frontier[0]["threat"]

	for i in range(1, frontier.size()):
		var entry = frontier[i]
		var entry_cost: int = entry["cost"]
		var entry_steps: int = entry["steps"]
		var entry_threat: int = entry["threat"]

		if entry_cost < best_cost or (entry_cost == best_cost and entry_threat < best_threat) or (entry_cost == best_cost and entry_threat == best_threat and entry_steps < best_steps):
			best_cost = entry_cost
			best_steps = entry_steps
			best_threat = entry_threat
			best_index = i

	var current_entry = frontier[best_index]
	frontier[best_index] = frontier.back()
	frontier.pop_back()
	return current_entry

func _is_valid_neighbor_for_path(neighbor: Vector2i, _target_coord: Vector2i, reachable: Dictionary, terrain_map, blocked_hexes: Dictionary) -> bool:
	if blocked_hexes.has(neighbor):
		return false
	if not reachable.has(neighbor):
		return false
	if not terrain_map.is_within_bounds(neighbor):
		return false
	if not terrain_map.is_passable(neighbor):
		return false
	return true

func _process_path_neighbor(neighbor: Vector2i, current_coord: Vector2i, current_entry: Dictionary, terrain_map, threatened_hexes: Dictionary, budget_limit: int, came_from: Dictionary, cost_so_far: Dictionary, steps_so_far: Dictionary, threat_so_far: Dictionary, frontier: Array) -> void:
	var step_cost: int = max(terrain_map.get_movement_cost(neighbor), 0)
	if step_cost <= 0:
		step_cost = 1

	var new_cost: int = cost_so_far[current_coord] + step_cost
	var new_steps: int = current_entry["steps"] + 1
	var additional_threat: int = 1 if threatened_hexes.has(neighbor) else 0
	var new_threat: int = current_entry["threat"] + additional_threat

	if budget_limit >= 0 and new_cost > budget_limit:
		return

	var best_known_cost = cost_so_far.get(neighbor, INF)
	var best_known_steps = steps_so_far.get(neighbor, INF)
	var best_known_threat = threat_so_far.get(neighbor, INF)

	if new_cost < best_known_cost or (new_cost == best_known_cost and new_threat < best_known_threat) or (new_cost == best_known_cost and new_threat == best_known_threat and new_steps < best_known_steps):
		cost_so_far[neighbor] = new_cost
		steps_so_far[neighbor] = new_steps
		threat_so_far[neighbor] = new_threat
		came_from[neighbor] = current_coord
		frontier.append({"coord": neighbor, "cost": new_cost, "steps": new_steps, "threat": new_threat})

func _reconstruct_path(came_from: Dictionary, start_coord: Vector2i, target_coord: Vector2i) -> Array[Vector2i]:
	if not came_from.has(target_coord):
		return []

	var path: Array[Vector2i] = []
	var backtrack: Vector2i = target_coord
	while backtrack != start_coord:
		path.append(backtrack)
		if not came_from.has(backtrack):
			return []
		backtrack = came_from[backtrack]

	path.reverse()
	return path
