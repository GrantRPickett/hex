class_name MoveController
extends Node

var _unit_manager: UnitManager
var _unit_controller: UnitController
var _hex_navigator: HexNavigator
var _turn_controller: TurnController
var _goal_controller: GoalController
var _map_controller: MapController
var _grid: Node2D

var _move_lock: bool = false
var _move_lock_release_queued: bool = false
var _grid_width: int = 0
var _grid_height: int = 0

func setup(unit_manager: UnitManager, unit_controller: UnitController, hex_navigator: HexNavigator, turn_controller: TurnController, goal_controller: GoalController, map_controller: MapController, grid: Node2D) -> void:
	_unit_manager = unit_manager
	_unit_controller = unit_controller
	_hex_navigator = hex_navigator
	_turn_controller = turn_controller
	_goal_controller = goal_controller
	_map_controller = map_controller
	_grid = grid

func update_grid_dimensions(width: int, height: int) -> void:
	_grid_width = width
	_grid_height = height

func _physics_process(_delta: float) -> void:
	if _move_lock_release_queued:
		_move_lock_release_queued = false
		_move_lock = false

func request_move(action: String) -> void:
	print_debug("DBG request_move, action=", action)
	if _move_lock:
		print_debug("DBG request_move ignored: move_lock active")
		return
	_move_lock = true

	if _goal_controller.is_goal_reached():
		_release_move_lock()
		return

	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)
	if not _turn_controller.can_act_on_index(selected_idx):
		_release_move_lock_deferred()
		return

	var current: Vector2i = _unit_manager.get_coord(selected_idx)
	var direction_map: Dictionary = _hex_navigator.get_direction_map(current, _grid)

	if not direction_map.has(action):
		_release_move_lock_deferred()
		return

	var next: Vector2i = current + direction_map[action]
	if not _is_within_bounds(next) or _unit_manager.is_occupied(next, selected_idx):
		_release_move_lock_deferred()
		return

	# Check terrain passability
	var terrain_map = _map_controller.get_terrain_map()
	if terrain_map and not terrain_map.is_passable(next):
		_release_move_lock_deferred()
		return

	# Check and consume AP
	var cost = terrain_map.get_movement_cost(next) if terrain_map else 1
	if unit and unit.get_remaining_movement_points() < cost:
		_release_move_lock_deferred()
		return

	_unit_controller.set_coord(selected_idx, next)
	_goal_controller.check_goal_progress()

	if unit:
		unit.consume_move(cost)
	_turn_controller.complete_player_activation(selected_idx)

	print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0))
	_release_move_lock_deferred()

func is_move_locked() -> bool:
	return _move_lock

func _is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < _grid_width and coord.y < _grid_height

func _release_move_lock_deferred() -> void:
	_move_lock_release_queued = true

func _release_move_lock() -> void:
	_move_lock = false