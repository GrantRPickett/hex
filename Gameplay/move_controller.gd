class_name MoveController
extends Node


var _unit_manager: UnitManager
var _unit_controller: UnitController
var _hex_navigator: HexNavigator
var _turn_controller: TurnController
var _goal_controller: GoalController
var _map_controller: MapController
var _grid: Node2D
var _info: Info

var _move_lock: bool = false
var _attack_warning_pending: bool = false
var _attack_warning_acknowledged: bool = false
var _grid_width: int = 0
var _grid_height: int = 0

func setup(unit_manager: UnitManager, unit_controller: UnitController, hex_navigator: HexNavigator, turn_controller: TurnController, goal_controller: GoalController, map_controller: MapController, grid: Node2D, info: Info = null) -> void:
	_unit_manager = unit_manager
	_unit_controller = unit_controller
	_hex_navigator = hex_navigator
	_turn_controller = turn_controller
	_goal_controller = goal_controller
	_map_controller = map_controller
	_grid = grid
	_info = info

func update_grid_dimensions(width: int, height: int) -> void:
	_grid_width = width
	_grid_height = height

func request_move(action: String) -> void:
	print_debug("DBG request_move, action=", action)
	if _is_move_blocked():
		return
	_move_lock = true
	_reset_warnings()

	if _goal_controller.is_goal_reached():
		_release_move_lock()
		return

	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)
	if not _turn_controller.can_act_on_index(selected_idx):
		_release_move_lock_deferred()
		return

	var current: Vector2i = _unit_manager.get_coord(selected_idx)
	var next: Vector2i = _get_next_coord_from_action(current, action)
	if next == Vector2i.MAX:
		_release_move_lock_deferred()
		return

	if not _is_valid_move_target(next, selected_idx):
		_release_move_lock_deferred()
		return

	var terrain_map = _map_controller.get_terrain_map()
	var cost = _get_move_cost(next, terrain_map)
	if unit and unit.get_remaining_movement_points() < cost:
		_release_move_lock_deferred()
		return

	_execute_move(selected_idx, unit, next, cost)
	_check_post_move_actions(selected_idx, unit, terrain_map)

	_release_move_lock_deferred()

func request_move_tentative(action: String) -> void:
	print_debug("DBG request_move_tentative, action=", action)
	if _is_move_blocked():
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
	var next: Vector2i = _get_next_coord_from_action(current, action)
	if next == Vector2i.MAX:
		print_debug("DBG request_move_tentative: direction not in map")
		_release_move_lock_deferred()
		return

	if not _is_valid_move_target(next, selected_idx):
		print_debug("DBG request_move_tentative: next invalid or occupied -> ", next)
		_release_move_lock_deferred()
		return

	var terrain_map = _map_controller.get_terrain_map()
	var cost = _get_move_cost(next, terrain_map)
	if unit and unit.get_remaining_movement_points() < cost:
		print_debug("DBG request_move_tentative: insufficient AP (have=", unit.get_remaining_movement_points(), " need=", cost, ")")
		_release_move_lock_deferred()
		return

	# Set tentative state and visually move without consuming points
	unit.set_tentative_move(next, [next], cost)
	_unit_controller.set_coord(selected_idx, next)
	# Update actions based on tentative position
	if _info:
		_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)
	else:
		print_debug("DBG request_move_tentative: no Info HUD; skipping action UI update")
	_release_move_lock_deferred()

func request_move_to_coord(target_coord: Vector2i) -> void:
	print_debug("DBG request_move_to_coord start, target=", target_coord)

	if _is_move_blocked():
		return

	if not _validate_manager_state():
		_move_lock = false
		return

	var selected_idx: int = _unit_manager.get_selected_index()
	if selected_idx == -1:
		_move_lock = false
		return

	var unit: Unit = _unit_manager.get_unit(selected_idx)
	if not unit or not _turn_controller.can_act_on_index(selected_idx):
		_move_lock = false
		return

	_move_lock = true
	_reset_warnings()

	# Success state check
	if _goal_controller.is_goal_reached():
		_release_move_lock()
		return

	if _handle_existing_tentative_move(unit, target_coord, selected_idx):
		return

	if not _is_valid_move_target_basic(target_coord, selected_idx):
		_release_move_lock_deferred()
		return

	var terrain_map = _map_controller.get_terrain_map()
	if not terrain_map:
		_release_move_lock_deferred()
		return

	var path_data = _calculate_path_data(unit, selected_idx, target_coord, terrain_map)
	if path_data.path.is_empty() or path_data.cost > path_data.budget:
		print_debug("DBG request_move_to_coord: invalid path or cost")
		_release_move_lock_deferred()
		return

	_check_and_warn_threats(unit, path_data.origin, terrain_map)

	# Set tentative state and physically move visual position
	unit.set_tentative_move(target_coord, path_data.path, path_data.cost)
	_unit_controller.set_coord(selected_idx, target_coord)

	# Verify goal state at the new potential destination
	# Goal progress is evaluated when the move is confirmed

	# Update actions based on tentative position
	if _info:
		var terrain_map2 = _map_controller.get_terrain_map()
		_info.update_available_actions(unit, terrain_map2, _unit_manager, selected_idx)

	print_debug("DBG request_move_to_coord: success, tentative destination set to ", target_coord, " (cost: ", path_data.cost, ")")
	_release_move_lock_deferred()

func confirm_move() -> void:
	print_debug("DBG confirm_move")
	if _is_move_blocked():
		return
	_move_lock = true

	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)

	if not unit.has_tentative_move():
		print_debug("DBG confirm_move: No tentative move to confirm")
		_release_move_lock_deferred()
		return

	if _attack_warning_pending and not _attack_warning_acknowledged:
		_acknowledge_warning()
		_release_move_lock_deferred()
		return

	_finalize_move(selected_idx, unit)
	_reset_warnings()

	var terrain_map = _map_controller.get_terrain_map()
	_check_post_move_actions(selected_idx, unit, terrain_map)

	_release_move_lock_deferred()

func cancel_move() -> void:
	print_debug("DBG cancel_move")
	if _is_move_blocked():
		return
	_move_lock = true

	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)

	if not unit.has_tentative_move():
		print_debug("DBG cancel_move: No tentative move to cancel")
		_release_move_lock_deferred()
		return

	_reset_warnings()

	# Move the unit visually back to its start-of-turn position
	_unit_controller.set_coord(selected_idx, unit.get_start_of_turn_grid_coord())
	unit.clear_tentative_move()

	# Refresh actions for original position
	if _info:
		var terrain_map = _map_controller.get_terrain_map()
		_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)

	_release_move_lock_deferred()

func force_action_menu_update() -> void:
	if not is_instance_valid(_unit_manager) or not is_instance_valid(_map_controller):
		return

	var selected_idx: int = _unit_manager.get_selected_index()
	if selected_idx == -1:
		return

	var unit: Unit = _unit_manager.get_unit(selected_idx)
	if not unit:
		return

	var terrain_map = _map_controller.get_terrain_map()
	if _info:
		_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)

func is_move_locked() -> bool:
	return _move_lock

func _is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 1 and coord.y >= 1 and coord.x <= _grid_width and coord.y <= _grid_height

func _release_move_lock_deferred() -> void:
	_release_move_lock()

func _release_move_lock() -> void:
	_move_lock = false

func _is_move_blocked() -> bool:
	if _move_lock:
		print_debug("DBG move ignored: move_lock active")
		return true
	return false

func _reset_warnings() -> void:
	_attack_warning_pending = false
	_attack_warning_acknowledged = false

func _get_next_coord_from_action(current: Vector2i, action: String) -> Vector2i:
	var direction_map: Dictionary = _hex_navigator.get_direction_map(current, _grid)
	if not direction_map.has(action):
		return Vector2i.MAX
	return current + direction_map[action]

func _is_valid_move_target(target: Vector2i, selected_idx: int) -> bool:
	if not _is_within_bounds(target):
		return false
	if _unit_manager.is_occupied(target, selected_idx):
		return false
	var terrain_map = _map_controller.get_terrain_map()
	if terrain_map and not terrain_map.is_passable(target):
		return false
	return true

func _is_valid_move_target_basic(target: Vector2i, selected_idx: int) -> bool:
	if not _is_within_bounds(target):
		print_debug("DBG request_move_to_coord: target out of bounds: ", target)
		return false
	if _unit_manager.is_occupied(target, selected_idx):
		print_debug("DBG request_move_to_coord: target occupied by another unit")
		return false
	return true

func _get_move_cost(target: Vector2i, terrain_map) -> int:
	return terrain_map.get_movement_cost(target) if terrain_map else 1

func _execute_move(selected_idx: int, unit: Unit, next: Vector2i, cost: int) -> void:
	_unit_controller.set_coord(selected_idx, next)
	_goal_controller.check_goal_progress()
	if unit:
		unit.consume_move(cost)
		if unit.movement_behavior:
			unit.movement_behavior.set_start_of_turn_grid_coord(next)

func _check_post_move_actions(selected_idx: int, unit: Unit, terrain_map) -> void:
	if not unit:
		_turn_controller.complete_player_activation(selected_idx)
		return

	var available_actions: Array = UnitActionManager.get_available_actions(unit, terrain_map, _unit_manager)
	var can_perform_action: bool = unit.has_action_available() and not available_actions.is_empty()

	if can_perform_action and _info:
		_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)

	if not unit.has_move_available():
		if not can_perform_action:
			_turn_controller.complete_player_activation(selected_idx)
			print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0), " - turn ended (no movement, no actions)")
		else:
			print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0), " - actions available, waiting for action")
	else:
		print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0))

func _validate_manager_state() -> bool:
	return is_instance_valid(_unit_manager) and is_instance_valid(_turn_controller)

func _handle_existing_tentative_move(unit: Unit, target_coord: Vector2i, selected_idx: int) -> bool:
	if unit.has_tentative_move() and unit.get_tentative_grid_coord() == target_coord:
		_release_move_lock()
		confirm_move()
		return true

	var committed_coord: Vector2i = unit.get_start_of_turn_grid_coord()
	if committed_coord == Vector2i.MAX:
		committed_coord = _unit_manager.get_coord(selected_idx)

	if target_coord == committed_coord:
		if unit.has_tentative_move():
			_release_move_lock()
			cancel_move()
		else:
			_release_move_lock()
		return true
	return false

func _calculate_path_data(unit: Unit, selected_idx: int, target_coord: Vector2i, terrain_map) -> Dictionary:
	var committed_coord: Vector2i = unit.get_start_of_turn_grid_coord()
	if committed_coord == Vector2i.MAX:
		committed_coord = _unit_manager.get_coord(selected_idx)
	var current_coord: Vector2i = _unit_manager.get_coord(selected_idx)
	var path_origin: Vector2i = committed_coord if unit.has_tentative_move() else current_coord

	var budget = unit.get_remaining_movement_points()
	var path: Array[Vector2i] = unit.get_path_to_coord(target_coord, terrain_map, path_origin, budget)

	var total_cost: int = 0
	for cell in path:
		total_cost += terrain_map.get_movement_cost(cell)

	return { "path": path, "cost": total_cost, "budget": budget, "origin": path_origin }

func _check_and_warn_threats(unit: Unit, origin: Vector2i, terrain_map) -> void:
	var threat_warning_required := false
	if terrain_map and unit and is_instance_valid(_unit_manager):
		if unit.movement_behavior:
			var threatened_hexes = unit.movement_behavior.get_threatened_hexes(_unit_manager, terrain_map)
			if threatened_hexes.has(origin):
				threat_warning_required = true

	_attack_warning_pending = threat_warning_required
	_attack_warning_acknowledged = false
	if threat_warning_required and _info:
		_info.show_warning_message("Leaving a threatened hex may provoke an attack of opportunity. Press confirm again to accept.")

func _acknowledge_warning() -> void:
	_attack_warning_acknowledged = true
	if _info:
		_info.show_warning_message("Attack of opportunity risk! Confirm again to move.")

func _finalize_move(selected_idx: int, unit: Unit) -> void:
	var tentative_coord = unit.get_tentative_grid_coord()
	var tentative_cost = unit.get_tentative_cost()

	_unit_controller.set_coord(selected_idx, tentative_coord)
	unit.consume_move(tentative_cost)
	if unit.movement_behavior:
		unit.movement_behavior.set_start_of_turn_grid_coord(tentative_coord)
	unit.clear_tentative_move()
	_goal_controller.check_goal_progress()
