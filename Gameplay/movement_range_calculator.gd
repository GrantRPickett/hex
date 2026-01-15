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
