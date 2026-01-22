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
	if _move_lock:
		print_debug("DBG request_move ignored: move_lock active")
		return
	_move_lock = true
	_attack_warning_pending = false
	_attack_warning_acknowledged = false

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

	# For directional request_move (legacy), keep immediate move behavior.
	# Tentative flow is handled by request_move_tentative() and confirm/cancel actions.
	_unit_controller.set_coord(selected_idx, next)
	_goal_controller.check_goal_progress()

	if unit:
		unit.consume_move(cost)
		if unit.movement_behavior:
			unit.movement_behavior.set_start_of_turn_grid_coord(next)

		var available_actions: Array = UnitActionManager.get_available_actions(unit, terrain_map, _unit_manager)
		var can_perform_action: bool = unit.has_action_available() and not available_actions.is_empty()
		if can_perform_action and _info:
			_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)

		# Check if unit should end turn: only if no movement AND no actions available
		if not unit.has_move_available():
			if not can_perform_action:
				# No actions available, end turn
				_turn_controller.complete_player_activation(selected_idx)
				_release_move_lock_deferred()
				print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0), " - turn ended (no movement, no actions)")
				return
			else:
				# Actions available, show action menu and wait for choice
				print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0), " - actions available, waiting for action")
				_release_move_lock_deferred()
				return

	_turn_controller.complete_player_activation(selected_idx)

	print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0))
	_release_move_lock_deferred()

func request_move_tentative(action: String) -> void:
	print_debug("DBG request_move_tentative, action=", action)
	if _move_lock:
		print_debug("DBG request_move_tentative ignored: move_lock active")
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
		print_debug("DBG request_move_tentative: direction not in map")
		_release_move_lock_deferred()
		return

	var next: Vector2i = current + direction_map[action]
	if not _is_within_bounds(next) or _unit_manager.is_occupied(next, selected_idx):
		print_debug("DBG request_move_tentative: next invalid or occupied -> ", next)
		_release_move_lock_deferred()
		return

	var terrain_map = _map_controller.get_terrain_map()
	if terrain_map and not terrain_map.is_passable(next):
		print_debug("DBG request_move_tentative: terrain not passable at ", next)
		_release_move_lock_deferred()
		return

	var cost = terrain_map.get_movement_cost(next) if terrain_map else 1
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

	# Basic safety and lock checks
	if _move_lock:
		print_debug("DBG request_move_to_coord ignored: move_lock active")
		return

	if not is_instance_valid(_unit_manager) or not is_instance_valid(_turn_controller):
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
	_attack_warning_pending = false
	_attack_warning_acknowledged = false

	# Success state check
	if _goal_controller.is_goal_reached():
		_release_move_lock()
		return

	# Handle confirmation if clicking the same tentative destination twice
	if unit.has_tentative_move() and unit.get_tentative_grid_coord() == target_coord:
		_release_move_lock()
		confirm_move()
		return

	# Valid pathing source is the start of the active unit's turn
	var committed_coord: Vector2i = unit.get_start_of_turn_grid_coord()
	if committed_coord == Vector2i.MAX:
		committed_coord = _unit_manager.get_coord(selected_idx)
	var current_coord: Vector2i = _unit_manager.get_coord(selected_idx)
	var path_origin: Vector2i = committed_coord if unit.has_tentative_move() else current_coord

	# Clicking on the origin cancels any tentative state
	if target_coord == committed_coord:
		if unit.has_tentative_move():
			_release_move_lock()
			cancel_move()
		else:
			_release_move_lock()
		return

	# Out of bounds check
	if not _is_within_bounds(target_coord):
		print_debug("DBG request_move_to_coord: target out of bounds: ", target_coord)
		_release_move_lock_deferred()
		return

	# Occupation check (allow self to occupy target if it's already theirs)
	if _unit_manager.is_occupied(target_coord, selected_idx):
		print_debug("DBG request_move_to_coord: target occupied by another unit")
		_release_move_lock_deferred()
		return

	var terrain_map = _map_controller.get_terrain_map()
	if not terrain_map:
		_release_move_lock_deferred()
		return

	# Determine total budget for this turn's movement
	var budget = unit.get_remaining_movement_points()

	# Calculate path from start-of-turn to the target
	var path: Array[Vector2i] = unit.get_path_to_coord(target_coord, terrain_map, path_origin, budget)

	if path.is_empty():
		print_debug("DBG request_move_to_coord: NO VALID PATH from ", path_origin, " to ", target_coord, " budget=", budget)
		_release_move_lock_deferred()
		return

	# Calculate total movement cost along the found path
	var total_cost: int = 0
	for cell in path:
		total_cost += terrain_map.get_movement_cost(cell)

	if total_cost > budget:
		print_debug("DBG request_move_to_coord: cost ", total_cost, " exceeds budget ", budget)
		_release_move_lock_deferred()
		return

	var threat_warning_required := false
	if terrain_map and unit and is_instance_valid(_unit_manager):
		var axis : int = terrain_map.get_offset_axis() if terrain_map.has_method("get_offset_axis") else TileSet.TILE_OFFSET_AXIS_VERTICAL
		var units := _unit_manager.get_units()
		for i in range(units.size()):
			var other = units[i]
			if other == null or not (other is Unit):
				continue
			if other == unit:
				continue
			if other.faction == unit.faction:
				continue
			var enemy_coord: Vector2i = _unit_manager.get_coord(i)
			if enemy_coord == Vector2i(-1, -1):
				enemy_coord = other.get_grid_location()
			if not terrain_map.is_within_bounds(enemy_coord):
				continue
			for offset in HexNavigator.get_neighbor_offsets(enemy_coord, axis):
				var threatened_coord :Vector2i = enemy_coord + offset
				if threatened_coord == path_origin:
					threat_warning_required = true
					break
			if threat_warning_required:
				break

	_attack_warning_pending = threat_warning_required
	_attack_warning_acknowledged = false
	if threat_warning_required and _info:
		_info.show_warning_message("Leaving a threatened hex may provoke an attack of opportunity. Press confirm again to accept.")

	# Set tentative state and physically move visual position
	unit.set_tentative_move(target_coord, path, total_cost)
	_unit_controller.set_coord(selected_idx, target_coord)

	# Verify goal state at the new potential destination
	# Goal progress is evaluated when the move is confirmed

	# Update actions based on tentative position
	if _info:
		var terrain_map2 = _map_controller.get_terrain_map()
		_info.update_available_actions(unit, terrain_map2, _unit_manager, selected_idx)

	print_debug("DBG request_move_to_coord: success, tentative destination set to ", target_coord, " (cost: ", total_cost, ")")
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

	if _attack_warning_pending and not _attack_warning_acknowledged:
		_attack_warning_acknowledged = true
		if _info:
			_info.show_warning_message("Attack of opportunity risk! Confirm again to move.")
		_release_move_lock_deferred()
		return

	var tentative_coord = unit.get_tentative_grid_coord()
	var tentative_cost = unit.get_tentative_cost()

	# Apply the actual move and consume points
	_unit_controller.set_coord(selected_idx, tentative_coord)
	unit.consume_move(tentative_cost)
	if unit.movement_behavior:
		unit.movement_behavior.set_start_of_turn_grid_coord(tentative_coord)
	unit.clear_tentative_move() # Clear tentative state after confirming

	_goal_controller.check_goal_progress() # Check goals again for final position

	_attack_warning_pending = false
	_attack_warning_acknowledged = false

	# Check if unit should end turn: only if no movement AND no actions available
	var terrain_map = _map_controller.get_terrain_map()
	var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, _unit_manager)
	var can_perform_action = unit.has_action_available() and not available_actions.is_empty()
	if can_perform_action and _info:
		_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)
	if not unit.has_move_available():
		if not can_perform_action:
			# No actions available, end turn
			_turn_controller.complete_player_activation(selected_idx)
			print_debug("DBG POST_CONFIRM_MOVE: turn ended (no movement, no actions)")
		else:
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

	_attack_warning_pending = false
	_attack_warning_acknowledged = false

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
