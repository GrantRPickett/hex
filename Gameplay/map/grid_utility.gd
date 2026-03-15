## Utility for grid-based algorithms.
class_name GridUtility
extends RefCounted

## Finds the nearest coordinate that satisfies the given predicate.
## uses BFS for hexagonal grid.
static func find_nearest(origin: Vector2i, max_radius: int, predicate: Callable, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> Vector2i:
	if predicate.call(origin):
		return origin

	var visited := {origin: true}
	var queue: Array[Vector2i] = [origin]
	var current_radius := 0

	while not queue.is_empty() and current_radius < max_radius:
		var layer_size: int = queue.size()
		for i in range(layer_size):
			var current = queue.pop_front()
			
			for offset in HexLib.get_neighbor_offsets(current, axis):
				var neighbor = current + offset
				if neighbor.x < 0 or neighbor.y < 0:
					continue
				
				if not visited.has(neighbor):
					visited[neighbor] = true
					if predicate.call(neighbor):
						return neighbor
					queue.append(neighbor)
		current_radius += 1

	return GameConstants.INVALID_COORD
