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

	var path: Array[Vector2i] = [target_coord]
	var current := target_coord
	var max_movement_points: int = reachable.get(start_coord, 999) # Fallback if start not in reachable, though it usually is excluded

	var axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	if terrain_map:
		if terrain_map.has_method("get_offset_axis"):
			axis = terrain_map.get_offset_axis()
		elif "offset_axis" in terrain_map:
			axis = terrain_map.offset_axis
	var dist = HexNavigator.get_hex_distance(start_coord, target_coord, axis)
	var max_steps = max(100, dist * 3)

	# Backtrack from target to start
	var steps := 0
	while current != start_coord and steps < max_steps:
		steps += 1
		var neighbors: Array[Vector2i] = terrain_map.get_neighbors(current)
		var found := false
		var current_rem: int = reachable[current]
		var cost : int = terrain_map.get_movement_cost(current)

		for n in neighbors:
			# Check if neighbor is valid and has the correct remaining AP (current + cost to enter current)
			# For the start node, we might not have it in reachable, so we check against max points or special case
			var n_rem: int = reachable.get(n, -1)
			if n == start_coord:
				found = true
				break

			if n_rem != -1 and n_rem == current_rem + cost:
				current = n
				path.append(current)
				found = true
				break

		if not found and current != start_coord:
			# Path broken
			return []

	path.reverse()
	return path
