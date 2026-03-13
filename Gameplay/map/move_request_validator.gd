class_name MoveRequestValidator
extends RefCounted


func validate_direction_move(unit_manager, hex_navigator, map_controller, grid: Node2D, selected_idx: int, unit, action: String, _grid_width: int, _grid_height: int, wind_direction: Vector2, wind_intensity: float) -> Dictionary:
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
	var next = _resolve_next_coord(current, action, hex_navigator, grid)
	if next == Vector2i.MAX:
		result.error_message = "direction not in map"
		return result

	var terrain_map = map_controller.get_terrain_map() if map_controller else null
	var validation_error = _validate_basic_movement(next, selected_idx, terrain_map, unit_manager)
	if not validation_error.is_empty():
		result.error_message = validation_error
		return result

	var cost = _calculate_move_cost(current, next, terrain_map, grid, wind_direction, wind_intensity)
	if unit.movement and unit.movement.get_remaining_movement_points() < cost:
		result.error_message = "insufficient AP"
		return result

	result.success = true
	result.next = next
	result.cost = cost
	result.terrain_map = terrain_map
	return result

func _resolve_next_coord(current: Vector2i, action: String, hex_navigator, grid: Node2D) -> Vector2i:
	var direction_map: Dictionary = hex_navigator.get_direction_map(current, grid) if hex_navigator else {}
	if direction_map.is_empty() or not direction_map.has(action):
		return Vector2i.MAX
	return current + direction_map[action]

func _validate_basic_movement(next: Vector2i, selected_idx: int, terrain_map, unit_manager) -> String:
	if not terrain_map or not terrain_map.is_within_bounds(next):
		return "target out of bounds"

	if unit_manager.is_occupied(next, selected_idx):
		return "target occupied"

	if not terrain_map.is_passable(next):
		return "terrain impassable"
		
	return ""

func _calculate_move_cost(current: Vector2i, next: Vector2i, terrain_map, grid: Node2D, wind_direction: Vector2, wind_intensity: float) -> int:
	var cost = terrain_map.get_movement_cost(next) if terrain_map else 1

	if wind_intensity > 0.0 and grid:
		var current_world_pos = grid.map_to_local(current)
		var next_world_pos = grid.map_to_local(next)
		var move_direction = (next_world_pos - current_world_pos).normalized()

		var dot_product = move_direction.dot(wind_direction)
		var wind_cost_adjustment = roundi(-dot_product * wind_intensity * 2)
		cost = max(1, cost + wind_cost_adjustment)
		
	return cost


func validate_coordinate_move(unit, unit_manager, map_controller, selected_idx: int, target_coord: Vector2i, grid_width: int, grid_height: int, wind_direction: Vector2, wind_intensity: float) -> Dictionary:
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

	var terrain_map = map_controller.get_terrain_map() if map_controller else null
	if terrain_map == null:
		result.error_message = "terrain map missing"
		return result

	if not terrain_map.is_within_bounds(target_coord):
		result.error_message = "target out of bounds"
		return result

	if unit_manager.is_occupied(target_coord, selected_idx):
		result.error_message = "target occupied by another unit"
		return result

	var committed_coord: Vector2i = unit.movement.get_start_of_turn_grid_coord()
	if committed_coord == Vector2i.MAX:
		committed_coord = unit_manager.get_coord(selected_idx)
	var current_coord: Vector2i = unit_manager.get_coord(selected_idx)
	var path_origin: Vector2i = committed_coord if unit.movement.has_tentative_move() else current_coord

	var budget = unit.movement.get_remaining_movement_points()
	var path: Array[Vector2i] = unit.movement.get_path_to_coord(target_coord, terrain_map, path_origin, budget)

	var total_cost: int = 0
	var current_cell := path_origin
	for cell in path:
		var step_cost = terrain_map.get_movement_cost(cell)

		# Apply wind effects to each step of the path
		if wind_intensity > 0.0:
			var current_world_pos = map_controller.get_grid().map_to_local(current_cell)
			var next_world_pos = map_controller.get_grid().map_to_local(cell)
			var move_direction = (next_world_pos - current_world_pos).normalized()
			var dot_product = move_direction.dot(wind_direction)
			var wind_cost_adjustment = roundi(-dot_product * wind_intensity * 2)
			step_cost = max(1, step_cost + wind_cost_adjustment)

		total_cost += step_cost
		current_cell = cell

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
