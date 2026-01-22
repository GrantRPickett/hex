class_name MovementRangeCalculator
extends RefCounted

const _TerrainMapScript := preload("res://Gameplay/terrain_map.gd")

func compute(start: Vector2i, movement_points: int, terrain_map) -> Dictionary:
	var reachable: Dictionary = {}
	if movement_points <= 0 or terrain_map == null or not terrain_map.is_within_bounds(start):
		return reachable
	var best_remaining: Dictionary = {}
	var frontier: Array[Vector2i] = []
	best_remaining[start] = movement_points
	frontier.append(start)
	while not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for coord in frontier:
			var remaining: int = best_remaining.get(coord, -1)
			if remaining < 0:
				continue
			for neighbor in terrain_map.get_neighbors(coord):
				if not terrain_map.is_within_bounds(neighbor):
					continue
				if not terrain_map.is_passable(neighbor):
					continue
				var cost: int = terrain_map.get_movement_cost(neighbor)
				var new_remaining: int = remaining - cost
				if new_remaining < 0:
					continue
				var should_update: bool = not best_remaining.has(neighbor) or new_remaining > best_remaining[neighbor]
				if should_update:
					best_remaining[neighbor] = new_remaining
					next_frontier.append(neighbor)
		if next_frontier.is_empty():
			break
		frontier = next_frontier
	best_remaining.erase(start)
	return best_remaining

func find_path(target_coord: Vector2i, start_coord: Vector2i, reachable: Dictionary, terrain_map, movement_budget: int = -1, threatened_hexes: Dictionary = {}, blocked_hexes: Dictionary = {}) -> Array[Vector2i]:
	if start_coord == target_coord:
		return []

	if not reachable.has(target_coord):
		return []

	var budget_limit := movement_budget
	var frontier: Array = []
	var start_threat: int = 1 if threatened_hexes.has(start_coord) else 0
	frontier.append({"coord": start_coord, "cost": 0, "steps": 0, "threat": start_threat})
	var came_from: Dictionary = {start_coord: null}
	var cost_so_far: Dictionary = {start_coord: 0}
	var steps_so_far: Dictionary = {start_coord: 0}
	var threat_so_far: Dictionary = {start_coord: start_threat}

	while not frontier.is_empty():
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
		var current_coord: Vector2i = current_entry["coord"]
		var current_steps: int = current_entry["steps"]
		var current_threat: int = current_entry["threat"]
		steps_so_far[current_coord] = current_steps
		threat_so_far[current_coord] = current_threat

		if current_coord == target_coord:
			break

		for neighbor in terrain_map.get_neighbors(current_coord):
			if neighbor != target_coord and blocked_hexes.has(neighbor):
				continue
			if neighbor != target_coord and not reachable.has(neighbor):
				continue
			if not terrain_map.is_within_bounds(neighbor):
				continue
			if not terrain_map.is_passable(neighbor):
				continue
			var step_cost: int = max(terrain_map.get_movement_cost(neighbor), 0)
			if step_cost <= 0:
				step_cost = 1
			var new_cost: int = cost_so_far[current_coord] + step_cost
			var new_steps: int = current_steps + 1
			var additional_threat: int = 1 if threatened_hexes.has(neighbor) else 0
			var new_threat: int = current_threat + additional_threat
			if budget_limit >= 0 and new_cost > budget_limit:
				continue
			var best_known_cost = cost_so_far.get(neighbor, INF)
			var best_known_steps = steps_so_far.get(neighbor, INF)
			var best_known_threat = threat_so_far.get(neighbor, INF)
			if new_cost < best_known_cost or (new_cost == best_known_cost and new_threat < best_known_threat) or (new_cost == best_known_cost and new_threat == best_known_threat and new_steps < best_known_steps):
				cost_so_far[neighbor] = new_cost
				steps_so_far[neighbor] = new_steps
				threat_so_far[neighbor] = new_threat
				came_from[neighbor] = current_coord
				frontier.append({"coord": neighbor, "cost": new_cost, "steps": new_steps, "threat": new_threat})

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
