class_name MovementRangeCalculator
extends RefCounted

var _astar: AStar2D = AStar2D.new()
var _last_map_id: int = -1
var _last_map_version: int = -1

func compute(start: Vector2i, movement_points: int, terrain_map: TerrainMap, pass_through_blockers: Dictionary = {}) -> Dictionary:
	if not _validate_compute_inputs(start, movement_points, terrain_map):
		return {}

	var best_cost: Dictionary = {}
	var frontier: Array[Vector2i] = []
	best_cost[start] = 0
	frontier.append(start)

	while not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for coord: Vector2i in frontier:
			_process_compute_node(coord, terrain_map, movement_points, best_cost, next_frontier, pass_through_blockers)
		if next_frontier.is_empty():
			break
		frontier = next_frontier

	best_cost.erase(start)
	return best_cost

func _validate_compute_inputs(start: Vector2i, movement_points: int, terrain_map: TerrainMap) -> bool:
	return movement_points > 0 and terrain_map != null and terrain_map.is_within_bounds(start)

func _process_compute_node(coord: Vector2i, terrain_map: TerrainMap, movement_points: int, best_cost: Dictionary, next_frontier: Array[Vector2i], pass_through_blockers: Dictionary = {}) -> void:
	var current_cost: int = best_cost.get(coord, -1)
	if current_cost < 0:
		return

	# If this coord is a blocker, we can't move PAST it (but we might be able to stay on it,
	# although that's handled by ending on it).
	# Dijkstra: if we are at a blocker, we don't explore its neighbors.
	if pass_through_blockers.has(coord):
		return

	for neighbor: Vector2i in terrain_map.get_neighbors(coord):
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

func _can_enter_neighbor_compute(neighbor: Vector2i, terrain_map: TerrainMap) -> bool:
	return terrain_map.is_within_bounds(neighbor) and terrain_map.is_passable(neighbor)

func find_path(target_coord: Vector2i, start_coord: Vector2i, reachable: Dictionary, terrain_map: TerrainMap, movement_budget: int = -1, threatened_hexes: Dictionary = {}, blocked_hexes: Dictionary = {}) -> Array[Vector2i]:
	if start_coord == target_coord:
		return []

	if not reachable.has(target_coord):
		return []

	_ensure_astar_ready(terrain_map)

	var width = terrain_map.grid_width
	var target_id = _get_point_id(target_coord, width)
	var start_id = _get_point_id(start_coord, width)

	# Update dynamic state: blockers and threatened hexes
	var modified_points: Array[int] = []
	
	# Disable blocked hexes (except target)
	for blocked in blocked_hexes:
		if blocked == target_coord: continue
		var id = _get_point_id(blocked, width)
		if _astar.has_point(id) and not _astar.is_point_disabled(id):
			_astar.set_point_disabled(id, true)
			modified_points.append(id)

	# Increase weight for threatened hexes
	var threat_modified: Array[int] = []
	for threatened in threatened_hexes:
		var id = _get_point_id(threatened, width)
		if _astar.has_point(id):
			var original_weight = _astar.get_point_weight_scale(id)
			_astar.set_point_weight_scale(id, original_weight + 5.0)
			threat_modified.append(id)

	var id_path = _astar.get_id_path(start_id, target_id)
	var path: Array[Vector2i] = []
	
	# Convert back to Vector2i, excluding start
	for i in range(1, id_path.size()):
		var id = id_path[i]
		path.append(Vector2i(id % width, id / width))

	# Restore modified points
	for id in modified_points:
		_astar.set_point_disabled(id, false)
	for id in threat_modified:
		var coord = Vector2i(id % width, id / width)
		_astar.set_point_weight_scale(id, terrain_map.get_movement_cost(coord))

	return path

func _ensure_astar_ready(terrain_map: TerrainMap) -> void:
	var map_id = terrain_map.get_instance_id()
	var map_version = terrain_map.get_version()
	
	if _last_map_id == map_id and _last_map_version == map_version:
		return
		
	_astar.clear()
	var width = terrain_map.grid_width
	var height = terrain_map.grid_height
	
	# Add points for all passable tiles
	for y in range(height):
		for x in range(width):
			var coord = Vector2i(x, y)
			if terrain_map.is_passable(coord):
				var id = _get_point_id(coord, width)
				_astar.add_point(id, Vector2(x, y), float(terrain_map.get_movement_cost(coord)))
	
	# Connect neighbors with bound checks
	for y in range(height):
		for x in range(width):
			var coord = Vector2i(x, y)
			var id = _get_point_id(coord, width)
			if not _astar.has_point(id): continue
			
			for neighbor in terrain_map.get_neighbors(coord):
				if not terrain_map.is_within_bounds(neighbor):
					continue
				var n_id = _get_point_id(neighbor, width)
				if id != n_id and _astar.has_point(n_id):
					_astar.connect_points(id, n_id)
					
	_last_map_id = map_id
	_last_map_version = map_version

func _get_point_id(coord: Vector2i, width: int) -> int:
	return coord.y * width + coord.x
