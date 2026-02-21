class_name MovementRangeCache
extends Resource

const INVALID_COORD := Vector2i(-999, -999)

@export var invalidate_distance: float = 10.0

var _cached_coord: Vector2i = INVALID_COORD
var _cached_points: int = -1
var _cached_version: int = -1
var _cached_result: Dictionary = {}
var _get_movement_points: Callable
var _unit_manager: UnitManager
var _unit_manager_callable: Callable
var _calculator

func setup(get_movement_points: Callable, unit_manager: UnitManager = null) -> void:
	_get_movement_points = get_movement_points
	_calculator = MovementRangeCalculator.new()
	set_unit_manager(unit_manager)
	invalidate()

func set_unit_manager(unit_manager: UnitManager) -> void:
	if _unit_manager and _unit_manager_callable and _unit_manager.unit_moved.is_connected(_unit_manager_callable):
		_unit_manager.unit_moved.disconnect(_unit_manager_callable)
	_unit_manager = unit_manager
	_unit_manager_callable = Callable()
	if _unit_manager:
		var handler := func(_index: int, coord: Vector2i) -> void:
			if _cached_coord == INVALID_COORD:
				return
			if _cached_coord.distance_to(coord) <= invalidate_distance:
				invalidate()
		_unit_manager_callable = handler
		_unit_manager.unit_moved.connect(_unit_manager_callable)

func compute_range(start_coord: Vector2i, terrain_map, movement_budget: int = -1) -> Dictionary:
	if terrain_map == null:
		return {}
	var map_version := 0
	if terrain_map.has_method("get_version"):
		map_version = terrain_map.get_version()
	var points := 0
	if movement_budget != -1:
		points = movement_budget
	elif _get_movement_points and _get_movement_points.is_valid():
		points = _get_movement_points.call()
	
	if _cached_coord == start_coord and _cached_points == points and _cached_version == map_version:
		return _cached_result
	if _calculator == null:
		_calculator = MovementRangeCalculator.new()
	var result: Dictionary = _calculator.compute(start_coord, points, terrain_map)
	_cached_coord = start_coord
	_cached_points = points
	_cached_version = map_version
	_cached_result = result
	return result

func invalidate() -> void:
	_cached_coord = INVALID_COORD
	_cached_points = -1
	_cached_version = -1
	_cached_result.clear()

func cleanup() -> void:
	set_unit_manager(null)
	invalidate()

