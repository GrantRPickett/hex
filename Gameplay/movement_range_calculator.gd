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

func find_path(target_coord: Vector2i, start_coord: Vector2i, reachable: Dictionary, terrain_map) -> Array[Vector2i]:
	if start_coord == target_coord:
		return []

	if not reachable.has(target_coord):
		return []

	# Use BFS to find the shortest path within the reachable set
	var queue: Array[Vector2i] = [start_coord]
	var came_from: Dictionary = {start_coord: null}
	var found := false

	while not queue.is_empty():
		var current = queue.pop_front()
		if current == target_coord:
			found = true
			break

		for neighbor in terrain_map.get_neighbors(current):
			if not reachable.has(neighbor):
				continue
			if not came_from.has(neighbor):
				came_from[neighbor] = current
				queue.append(neighbor)

	if not found:
		return []

	# Reconstruct path
	var path: Array[Vector2i] = []
	var backtrack = target_coord
	while backtrack != null and backtrack != start_coord:
		path.append(backtrack)
		backtrack = came_from[backtrack]

	path.reverse()
	return path
