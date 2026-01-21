class_name UnitMovementBehavior
extends RefCounted

## Component responsible for unit movement logic and pathfinding.
##
## This component handles:
## - Movement point management
## - Path calculation and validation
## - Movement range computation
## - Tentative move state tracking

var _unit # Unit (type hint removed to avoid circular dependency)
var _start_of_turn_grid_coord: Vector2i = Vector2i.MAX
var _tentative_grid_coord: Vector2i = Vector2i.MAX
var _tentative_path: Array[Vector2i] = []
var _tentative_cost: int = 0

func _init(unit: Unit) -> void:
	_unit = unit

## Checks if the unit has movement available this turn
func has_move_available() -> bool:
	var action_points = _unit._action_points
	if action_points == null:
		return false
	return action_points.has_move_available()

## Consumes movement points
func consume_move(cost: int = 1) -> void:
	var action_points = _unit._action_points
	if action_points == null:
		return
	action_points.consume_move(cost)
	if _unit._movement_cache:
		_unit._movement_cache.invalidate()

## Adjusts remaining movement points by delta
func adjust_remaining_movement(delta: int) -> void:
	var action_points = _unit._action_points
	if action_points == null:
		return
	action_points.adjust_remaining_movement(delta)
	if _unit._movement_cache:
		_unit._movement_cache.invalidate()

## Blocks movement for the remainder of this turn
func block_movement_this_turn() -> void:
	var action_points = _unit._action_points
	if action_points == null:
		return
	action_points.block_movement_this_turn()
	if _unit._movement_cache:
		_unit._movement_cache.invalidate()

## Gets remaining movement points for this turn
func get_remaining_movement_points() -> int:
	var action_points = _unit._action_points
	if action_points == null:
		return 0
	return action_points.get_remaining_movement_points()

## Gets maximum movement points
func get_max_movement_points() -> int:
	return _unit.movement_points

## Computes the movement range from a starting coordinate
func compute_movement_range(start_coord: Vector2i, terrain_map, movement_budget: int = -1) -> Dictionary:
	if _unit._movement_cache == null:
		return {}
	return _unit._movement_cache.compute_range(start_coord, terrain_map, movement_budget)

## Gets the path to a target coordinate
func get_path_to_coord(target_coord: Vector2i, terrain_map, start_coord: Vector2i = Vector2i.MAX, movement_budget: int = -1) -> Array[Vector2i]:
	if terrain_map.has_method("is_within_bounds") and not terrain_map.is_within_bounds(target_coord):
		return []

	var start_cell := start_coord
	if start_cell == Vector2i.MAX:
		start_cell = _unit.get_grid_location()

	var reachable := compute_movement_range(start_cell, terrain_map, movement_budget)
	var calculator := MovementRangeCalculator.new()
	return calculator.find_path(target_coord, start_cell, reachable, terrain_map)

## Refreshes movement state at the start of a turn
func refresh_turn() -> void:
	var current_coord = _unit.get_grid_location()
	if current_coord != Vector2i.ZERO:
		_start_of_turn_grid_coord = current_coord
	else:
		_start_of_turn_grid_coord = Vector2i.MAX
	_tentative_grid_coord = Vector2i.MAX
	_tentative_path = []
	_tentative_cost = 0

## Gets the unit's position at the start of its turn
func get_start_of_turn_grid_coord() -> Vector2i:
	if _start_of_turn_grid_coord == Vector2i.MAX:
		return _unit.get_grid_location()
	return _start_of_turn_grid_coord

## Sets a tentative move for preview purposes
func set_tentative_move(coord: Vector2i, path: Array[Vector2i], cost: int) -> void:
	_tentative_grid_coord = coord
	_tentative_path = path
	_tentative_cost = cost

## Clears the tentative move
func clear_tentative_move() -> void:
	_tentative_grid_coord = Vector2i.MAX
	_tentative_path = []
	_tentative_cost = 0

## Gets the tentative grid coordinate
func get_tentative_grid_coord() -> Vector2i:
	return _tentative_grid_coord

## Checks if there's a tentative move set
func has_tentative_move() -> bool:
	return _tentative_grid_coord != Vector2i.MAX

## Gets the tentative path
func get_tentative_path() -> Array[Vector2i]:
	return _tentative_path

## Gets the tentative move cost
func get_tentative_cost() -> int:
	return _tentative_cost
