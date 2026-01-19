class_name MoveController
extends Node

const UnitActionManager := preload("res://Gameplay/unit_action_manager.gd")

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

	var current: Vector2i = _unit_manager.get_coord(selected_idx)

	# Can't move to current position
	if target_coord == current:
		_release_move_lock_deferred()
		return

	# Check bounds
	if not _is_within_bounds(target_coord):
		_release_move_lock_deferred()
		return

	# Check occupation
	if _unit_manager.is_occupied(target_coord, selected_idx):
		_release_move_lock_deferred()
		return

	var terrain_map = _map_controller.get_terrain_map()

	# Get the path to the target coordinate
	var path = unit.get_path_to_coord(target_coord, terrain_map, current)
	if path.is_empty():
		print_debug("DBG request_move_to_coord: no valid path found")
		_release_move_lock_deferred()
		return

	print_debug("DBG request_move_to_coord: path=", path)

	# Execute all moves in the path
	for next in path:
		# Check terrain passability
		if terrain_map and not terrain_map.is_passable(next):
			print_debug("DBG request_move_to_coord: terrain not passable at ", next)
			break

		# Check and consume AP
		var cost = terrain_map.get_movement_cost(next) if terrain_map else 1
		if unit and unit.get_remaining_movement_points() < cost:
			print_debug("DBG request_move_to_coord: not enough movement points at ", next, " cost=", cost)
			break

		print_debug("DBG request_move_to_coord: moving to ", next)

		# Update the coordinate - this will trigger unit_moved signal which animates the unit
		_unit_controller.set_coord(selected_idx, next)
		_goal_controller.check_goal_progress()

		if unit:
			unit.consume_move(cost)
			# If unit has no more movement, check for available actions
			if not unit.has_move_available():
				var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, _unit_manager)
				# Stop path execution if no movement and no actions available
				if available_actions.is_empty() or not unit.has_action_available():
					print_debug("DBG request_move_to_coord: movement exhausted and no actions, stopping path")
					break
				else:
					# Actions available, show action menu
					if _info:
						_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)
					print_debug("DBG request_move_to_coord: movement exhausted but actions available")
					# Don't break, they can still use actions
					break

	# Check if unit still has movement or actions - if neither, end turn
	if unit and not unit.has_move_available():
		var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, _unit_manager)
		if available_actions.is_empty() or not unit.has_action_available():
			# No movement and no actions, end turn
			_turn_controller.complete_player_activation(selected_idx)
			_release_move_lock_deferred()
			print_debug("DBG POST_MOVE_TO_COORD player_coord=", _unit_manager.get_coord(selected_idx), " - turn ended (no movement, no actions)")
			return
		else:
			# Actions available, show action menu but don't end turn yet
			if _info:
				_info.update_available_actions(unit, terrain_map, _unit_manager, selected_idx)
			_release_move_lock_deferred()
			print_debug("DBG POST_MOVE_TO_COORD player_coord=", _unit_manager.get_coord(selected_idx), " - actions available, waiting for action")
			return

	_turn_controller.complete_player_activation(selected_idx)
	print_debug("DBG POST_MOVE_TO_COORD player_coord=", _unit_manager.get_coord(selected_idx))
	_release_move_lock_deferred()

func is_move_locked() -> bool:
	return _move_lock

func _is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < _grid_width and coord.y < _grid_height

func _release_move_lock_deferred() -> void:
	_release_move_lock()

func _release_move_lock() -> void:
	_move_lock = false