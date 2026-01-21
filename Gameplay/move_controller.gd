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
var _move_lock_release_queued: bool = false
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
		# Check if unit should end turn: only if no movement AND no actions available
		if not unit.has_move_available():
			var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, _unit_manager)

			if available_actions.is_empty() or not unit.has_action_available():
				# No actions available, end turn
				_turn_controller.complete_player_activation(selected_idx)
				_release_move_lock_deferred()
				print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0), " - turn ended (no movement, no actions)")
				return
			else:
				# Actions available, show action menu
				if _info:
					_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)
				print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0), " - actions available, waiting for action")
				_release_move_lock_deferred()
				return

	_turn_controller.complete_player_activation(selected_idx)

	print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0))
	_release_move_lock_deferred()

func request_move_to_coord(target_coord: Vector2i) -> void:
	print_debug("DBG request_move_to_coord, target=", target_coord)
	if _move_lock:
		print_debug("DBG request_move_to_coord ignored: move_lock active")
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

	# If the unit already has a tentative move, and the target is the same, confirm it.
	# This needs to be handled by the command system later, not directly here.
	if unit.has_tentative_move() and unit.get_tentative_grid_coord() == target_coord:
		confirm_move()
		return

	var start_of_turn_coord: Vector2i = unit.get_start_of_turn_grid_coord()

	# Can't move to current position
	if target_coord == start_of_turn_coord:
		_release_move_lock_deferred()
		return

	# Check bounds
	if not _is_within_bounds(target_coord):
		_release_move_lock_deferred()
		return

	# Check occupation (ensure it's not occupied by another unit, but can be occupied by self)
	if _unit_manager.is_occupied(target_coord, selected_idx):
		if _unit_manager.get_coord(selected_idx) != target_coord: # Allow moving to self current spot
			_release_move_lock_deferred()
			return

	var terrain_map = _map_controller.get_terrain_map()

	# Get the path to the target coordinate from the START OF THE TURN
	var path = unit.get_path_to_coord(target_coord, terrain_map, start_of_turn_coord)
	if path.is_empty():
		print_debug("DBG request_move_to_coord: no valid path found")
		_release_move_lock_deferred()
		return

	var total_cost: int = 0
	# Calculate total cost from start_of_turn_coord to target_coord
	var _previous_coord: Vector2i = start_of_turn_coord
	for next_coord in path:
		var cost_to_step = terrain_map.get_movement_cost(next_coord) if terrain_map else 1
		total_cost += cost_to_step
		_previous_coord = next_coord # This is important if costs vary per step

	print_debug("DBG request_move_to_coord: path=", path, " total_cost=", total_cost)

	# Check if unit can afford the total move from its original position
	# Use get_max_movement_points() for the total available movement for the turn
	if unit.get_max_movement_points() < total_cost:
		print_debug("DBG request_move_to_coord: not enough movement points for total cost. Max: ", unit.get_max_movement_points(), " Cost: ", total_cost)
		_release_move_lock_deferred()
		return

	# Set the tentative move on the unit
	unit.set_tentative_move(target_coord, path, total_cost)

	# Visually move the unit to the tentative coordinate WITHOUT consuming movement points
	# This triggers the unit_moved signal which animates the unit.
	_unit_controller.set_coord(selected_idx, unit.get_tentative_grid_coord())
	_goal_controller.check_goal_progress() # Check goals based on tentative position

	print_debug("DBG request_move_to_coord: tentative move set to ", unit.get_tentative_grid_coord())
	_release_move_lock_deferred()

func confirm_move() -> void:
	print_debug("DBG confirm_move")
	if _move_lock:
		print_debug("DBG confirm_move ignored: move_lock active")
		return
	_move_lock = true

	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)

	if not unit.has_tentative_move():
		print_debug("DBG confirm_move: No tentative move to confirm")
		_release_move_lock_deferred()
		return

	var tentative_coord = unit.get_tentative_grid_coord()
	var tentative_cost = unit.get_tentative_cost()

	# Apply the actual move and consume points
	_unit_controller.set_coord(selected_idx, tentative_coord)
	unit.consume_move(tentative_cost)
	unit.clear_tentative_move() # Clear tentative state after confirming

	_goal_controller.check_goal_progress() # Check goals again for final position

	# Check if unit should end turn: only if no movement AND no actions available
	var terrain_map = _map_controller.get_terrain_map()
	if not unit.has_move_available():
		var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, _unit_manager)

		if available_actions.is_empty() or not unit.has_action_available():
			# No actions available, end turn
			_turn_controller.complete_player_activation(selected_idx)
			print_debug("DBG POST_CONFIRM_MOVE: turn ended (no movement, no actions)")
		else:
			# Actions available, show action menu
			if _info:
				_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)
			print_debug("DBG POST_CONFIRM_MOVE: actions available, waiting for action")
	else:
		print_debug("DBG POST_CONFIRM_MOVE: movement still available")

	_release_move_lock_deferred()

func cancel_move() -> void:
	print_debug("DBG cancel_move")
	if _move_lock:
		print_debug("DBG cancel_move ignored: move_lock active")
		return
	_move_lock = true

	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)

	if not unit.has_tentative_move():
		print_debug("DBG cancel_move: No tentative move to cancel")
		_release_move_lock_deferred()
		return

	# Move the unit visually back to its start-of-turn position
	_unit_controller.set_coord(selected_idx, unit.get_start_of_turn_grid_coord())
	unit.clear_tentative_move()

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