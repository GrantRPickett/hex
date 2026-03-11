class_name MapDiscovery
extends RefCounted

## Unified spatial discovery for units, loot, and locations.

## Returns the grid location for any Node2D (Target or otherwise).
static func get_grid_location(node: Node2D, grid_map: TileMapLayer = null, external_coord: Vector2i = GameConstants.INVALID_COORD) -> Vector2i:
	if external_coord != GameConstants.INVALID_COORD:
		return external_coord
	
	if is_instance_valid(grid_map):
		return grid_map.local_to_map(node.position)

	var parent = node.get_parent()
	if parent is TileMapLayer:
		return parent.local_to_map(node.position)
	
	# If context provides a Target but no grid_map reference, check the node's own properties
	if "grid_map" in node and is_instance_valid(node.get("grid_map")):
		return node.get("grid_map").local_to_map(node.position)

	return GameConstants.INVALID_COORD

## Returns the hex distance between two Targets.
static func get_distance(from: Node2D, to: Node2D) -> int:
	if not is_instance_valid(from) or not is_instance_valid(to):
		return GameConstants.INFINITY_DISTANCE

	var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
	var from_grid = _get_grid_for_node(from)
	if from_grid and from_grid.tile_set:
		axis = from_grid.tile_set.tile_offset_axis
	else:
		var to_grid = _get_grid_for_node(to)
		if to_grid and to_grid.tile_set:
			axis = to_grid.tile_set.tile_offset_axis

	return HexNavigator.get_hex_distance(from.get_grid_location(), to.get_grid_location(), axis)

## Snaps a Node2D to the grid.
static func snap_to_grid(node: Node2D, grid_map: TileMapLayer = null) -> Vector2i:
	var grid: TileMapLayer = grid_map
	if not is_instance_valid(grid) and node.get_parent() is TileMapLayer:
		grid = node.get_parent()
	
	if is_instance_valid(grid) and grid.tile_set:
		var coord := grid.local_to_map(node.position)
		node.position = grid.map_to_local(coord)
		return coord
	return GameConstants.INVALID_COORD

## Returns true if the world position is inside the node's visual bounds.
static func is_pixel_inside(node: Node2D, world_pos: Vector2, sprite: Sprite2D = null) -> bool:
	if is_instance_valid(sprite):
		var rect = sprite.get_global_rect()
		return rect.has_point(world_pos)
	else:
		var default_radius = 32.0
		return world_pos.distance_to(node.global_position) <= default_radius

static func _get_grid_for_node(node: Node2D) -> TileMapLayer:
	if "grid_map" in node and is_instance_valid(node.get("grid_map")):
		return node.get("grid_map")
	if node.get_parent() is TileMapLayer:
		return node.get_parent()
	return null

## Returns the unit at the given coordinate, if any.
static func get_unit_at(unit_manager: Node, coord: Vector2i) -> Unit:
	if not is_instance_valid(unit_manager):
		return null
	return unit_manager.get_unit_at_coord(coord) if unit_manager.has_method("get_unit_at_coord") else null

## Returns true if the coordinate is occupied by a unit (optionally ignoring one).
static func is_occupied(unit_manager: Node, coord: Vector2i, ignore_index: int = -1) -> bool:
	if not is_instance_valid(unit_manager):
		return false
	return unit_manager.is_occupied(coord, ignore_index) if unit_manager.has_method("is_occupied") else false

## Returns the loot at the given coordinate, if any.
static func get_loot_at(loot_manager: Node, coord: Vector2i) -> Node:
	if not is_instance_valid(loot_manager):
		return null
	return loot_manager.get_loot_at(coord) if loot_manager.has_method("get_loot_at") else null

## Returns the location at the given coordinate, if any.
static func get_location_at(task_manager: Node, coord: Vector2i) -> Node:
	if not is_instance_valid(task_manager):
		return null
	return task_manager.get_location_at(coord) if task_manager.has_method("get_location_at") else null

## Returns true if the coordinate is passable (terrain + bounds check).
static func is_passable(terrain_map: RefCounted, coord: Vector2i) -> bool:
	if not is_instance_valid(terrain_map):
		return true # Assume passable if map missing? Or false for safety?
	return terrain_map.is_within_bounds(coord) and terrain_map.is_passable(coord)

## Returns the movement cost for a coordinate.
static func get_movement_cost(terrain_map: RefCounted, coord: Vector2i) -> int:
	if not is_instance_valid(terrain_map):
		return 1
	return terrain_map.get_movement_cost(coord)

## Finds the nearest empty coordinate around a requested point.
static func get_nearest_empty_coord(requested_coord: Vector2i, unit_manager: Node, max_radius: int = 5) -> Vector2i:
	if not is_instance_valid(unit_manager):
		return requested_coord
	
	if not unit_manager.is_occupied(requested_coord):
		return requested_coord

	var visited := {requested_coord: true}
	var queue := [requested_coord]
	var current_radius := 0

	# Determine axis from the manager's context (looking at first unit's map if available)
	var axis = 1
	var units = unit_manager.get_units()
	if not units.is_empty() and is_instance_valid(units[0].grid_map) and units[0].grid_map.tile_set:
		axis = units[0].grid_map.tile_set.tile_offset_axis

	while not queue.is_empty():
		var layer_size = queue.size()
		for i in range(layer_size):
			var current = queue.pop_front()
			if not unit_manager.is_occupied(current):
				return current

			var offsets = HexNavigator.get_neighbor_offsets(current, axis)
			for offset in offsets:
				var neighbor = current + offset
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)

		current_radius += 1
		if current_radius > max_radius:
			break

	return GameConstants.INVALID_COORD

## Returns the best path to any unblocked neighbor of the target_pos.
static func find_path_to_adjacent(unit: Node2D, target_pos: Vector2i, terrain_map: RefCounted, unit_manager: Node) -> Array:
	var best_path: Array = []
	var best_score: int = 9999
	if not is_instance_valid(terrain_map) or not is_instance_valid(unit) or not is_instance_valid(unit_manager):
		return best_path

	for neighbor in terrain_map.get_neighbors(target_pos):
		if unit_manager.is_occupied(neighbor):
			continue
		var path = unit.movement.get_path_to_coord(neighbor, terrain_map)
		if not path.is_empty():
			var score = path.size()
			if best_path.is_empty() or score < best_score:
				best_path = path
				best_score = score
	return best_path
