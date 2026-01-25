class_name MoveRequestValidator
extends RefCounted

func validate_direction_move(unit_manager, hex_navigator, map_controller, grid: Node2D, selected_idx: int, unit, action: String, grid_width: int, grid_height: int, wind_direction: Vector2, wind_intensity: float) -> Dictionary:
	var result := {
		"success": false,
		"next": Vector2i.MAX,
		"cost": 0,
		"terrain_map": null,
		"error_message": ""
	}
	if selected_idx == -1 or unit == null or action.is_empty():
		return result

	var current: Vector2i = unit_manager.get_coord(selected_idx)
	var direction_map: Dictionary = hex_navigator.get_direction_map(current, grid) if hex_navigator else {}
	if direction_map.is_empty() or not direction_map.has(action):
		result.error_message = "direction not in map"
		return result

	var next: Vector2i = current + direction_map[action]
	if next.x < 1 or next.y < 1 or next.x > grid_width or next.y > grid_height:
		result.error_message = "target out of bounds"
		return result

	if unit_manager.is_occupied(next, selected_idx):
		result.error_message = "target occupied"
		return result

	var terrain_map = map_controller.get_terrain_map() if map_controller else null
	if terrain_map and not terrain_map.is_passable(next):
		result.error_message = "terrain impassable"
		return result

	var cost = terrain_map.get_movement_cost(next) if terrain_map else 1

	# Apply wind effects
	if wind_intensity > 0.0:
		var current_world_pos = grid.map_to_local(current)
		var next_world_pos = grid.map_to_local(next)
		var move_direction = (next_world_pos - current_world_pos).normalized()

		var dot_product = move_direction.dot(wind_direction)

		# Adjust cost based on dot product and wind intensity
		# Moving directly against wind (dot_product = -1) increases cost significantly
		# Moving directly with wind (dot_product = 1) decreases cost significantly
		# Cross wind (dot_product = 0) has no direct cost impact
		var wind_cost_adjustment = roundi(-dot_product * wind_intensity * 2) # Arbitrary multiplier for effect intensity
		cost = max(1, cost + wind_cost_adjustment) # Ensure cost doesn't go below 1


	if unit.has_method("get_remaining_movement_points") and unit.get_remaining_movement_points() < cost:
		result.error_message = "insufficient AP"
		return result

	result.success = true
	result.next = next
	result.cost = cost
	result.terrain_map = terrain_map
	return result

func validate_coordinate_move(unit, unit_manager, map_controller, selected_idx: int, target_coord: Vector2i, grid_width: int, grid_height: int, wind_direction: Vector2, wind_intensity: float) -> Dictionary:
	# Wind effects for coordinate move are more complex as it involves a path.
	# For now, we'll keep it simple and just ensure the path calculation
	# uses the potentially wind-modified terrain costs (which it already does
	# via terrain_map.get_movement_cost).
	# A more advanced implementation might re-evaluate pathfinding with wind effects.

	var result := {
		"success": false,
		"path": [],
		"cost": 0,
		"budget": 0,
		"origin": Vector2i.ZERO,
		"terrain_map": null,
		"error_message": ""
	}
	if unit == null or selected_idx == -1:
		return result

	if target_coord.x < 1 or target_coord.y < 1 or target_coord.x > grid_width or target_coord.y > grid_height:
		result.error_message = "target out of bounds"
		return result
	if unit_manager.is_occupied(target_coord, selected_idx):
		result.error_message = "target occupied by another unit"
		return result

	var terrain_map = map_controller.get_terrain_map() if map_controller else null
	if terrain_map == null:
		result.error_message = "terrain map missing"
		return result

	var committed_coord: Vector2i = unit.get_start_of_turn_grid_coord()
	if committed_coord == Vector2i.MAX:
		committed_coord = unit_manager.get_coord(selected_idx)
	var current_coord: Vector2i = unit_manager.get_coord(selected_idx)
	var path_origin: Vector2i = committed_coord if unit.has_tentative_move() else current_coord

	var budget = unit.get_remaining_movement_points()
	var path: Array[Vector2i] = unit.get_path_to_coord(target_coord, terrain_map, path_origin, budget)

	var total_cost: int = 0
	for cell in path:
		total_cost += terrain_map.get_movement_cost(cell)
		# TODO: For coordinate moves, wind effect should be applied per step in the path.
		# This currently relies only on terrain_map.get_movement_cost, which only
		# includes generic movement_cost_modifier, humidity, and temperature.
		# Directional wind needs to be applied here if pathfinding itself
		# doesn't account for it (which it doesn't currently for directional wind).
		# This might require passing wind_direction/intensity to get_path_to_coord
		# or modifying the pathfinding algorithm.

	if path.is_empty() or total_cost > budget:
		result.error_message = "invalid path or cost"
		return result

	result.success = true
	result.path = path
	result.cost = total_cost
	result.budget = budget
	result.origin = path_origin
	result.terrain_map = terrain_map
	return result