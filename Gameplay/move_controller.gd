class_name MoveController
extends Node

signal actions_updated(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int)
signal threat_warning_requested(message: String)

const MoveRequestValidatorScript := preload("res://Gameplay/move_request_validator.gd")
const MoveExecutionServiceScript := preload("res://Gameplay/move_execution_service.gd")
const ThreatWarningServiceScript := preload("res://Gameplay/threat_warning_service.gd")

var _unit_manager: UnitManager
var _unit_controller: UnitController
var _hex_navigator: HexNavigator
var _turn_controller: TurnController
var _goal_controller: GoalController
var _map_controller: MapController
var _grid: Node2D

var _move_lock: bool = false
var _grid_width: int = 0
var _grid_height: int = 0

var _request_validator: MoveRequestValidator = MoveRequestValidatorScript.new()
var _execution_service: MoveExecutionService = MoveExecutionServiceScript.new()
var _threat_warning_service: ThreatWarningService = ThreatWarningServiceScript.new()

@onready var weather_manager = get_node("/root/WeatherManager") # Added WeatherManager reference

var _current_wind_direction: Vector2 = Vector2.ZERO # New
var _current_wind_intensity: float = 0.0 # New

func _ready(): # Added _ready function
	if weather_manager:
		weather_manager.weather_effect_applied.connect(_on_weather_effect_applied)

func setup(unit_manager: UnitManager, unit_controller: UnitController, hex_navigator: HexNavigator, turn_controller: TurnController, goal_controller: GoalController, map_controller: MapController, grid: Node2D, request_validator: MoveRequestValidator = null, execution_service: MoveExecutionService = null, threat_warning_service: ThreatWarningService = null) -> void:
	_unit_manager = unit_manager
	_unit_controller = unit_controller
	_hex_navigator = hex_navigator
	_turn_controller = turn_controller
	_goal_controller = goal_controller
	_map_controller = map_controller
	_grid = grid
	if request_validator:
		_request_validator = request_validator
	if execution_service:
		_execution_service = execution_service
	if threat_warning_service:
		_threat_warning_service = threat_warning_service

func update_grid_dimensions(width: int, height: int) -> void:
	_grid_width = width
	_grid_height = height

func request_move(action: String) -> void:
	print_debug("DBG request_move, action=", action)
	if _is_move_blocked():
		return
	_move_lock = true
	_reset_warnings()

	if _should_abort_move():
		_release_move_lock()
		return

	var context = _get_active_unit_context()
	if not context.valid:
		_release_move_lock_deferred()
		return

	# TODO: Use _current_wind_direction and _current_wind_intensity to potentially modify move
	_execute_direction_move(context.unit, context.index, action)

func request_move_tentative(action: String) -> void:
	print_debug("DBG request_move_tentative, action=", action)
	if _is_move_blocked():
		return
	_move_lock = true

	if _should_abort_move():
		_release_move_lock()
		return

	var context = _get_active_unit_context()
	if not context.valid:
		_release_move_lock_deferred()
		return

	_execute_tentative_direction_move(context.unit, context.index, action)

func request_move_to_coord(target_coord: Vector2i) -> void:
	print_debug("DBG request_move_to_coord start, target=", target_coord)

	if _is_move_blocked():
		return

	if not _validate_manager_state():
		_move_lock = false
		return

	var context = _get_active_unit_context()
	if not context.valid:
		_move_lock = false
		return

	_move_lock = true
	_reset_warnings()

	if _should_abort_move():
		_release_move_lock()
		return

	if _handle_existing_tentative_move(context.unit, target_coord, context.index):
		return

	_execute_coordinate_move(context.unit, context.index, target_coord)

func confirm_move() -> void:
	print_debug("DBG confirm_move")
	if _is_move_blocked():
		return
	_move_lock = true

	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)

	if not _validate_tentative_move_exists(unit, "confirm"):
		_release_move_lock_deferred()
		return

	if _handle_threat_confirmation():
		_release_move_lock_deferred()
		return

	_finalize_move(unit, selected_idx)
	_release_move_lock_deferred()

func cancel_move() -> void:
	print_debug("DBG cancel_move")
	if _is_move_blocked():
		return
	_move_lock = true

	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)

	if not _validate_tentative_move_exists(unit, "cancel"):
		_release_move_lock_deferred()
		return

	_perform_cancellation(unit, selected_idx)
	_release_move_lock_deferred()

func cancel_tentative_move_for_index(index: int) -> void:
	if index < 0 or not is_instance_valid(_unit_manager):
		return
	var unit: Unit = _unit_manager.get_unit(index)
	if unit == null or not unit.has_tentative_move():
		return
	_perform_cancellation(unit, index)


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
	actions_updated.emit(unit, terrain_map, _unit_manager, selected_idx)

func is_move_locked() -> bool:
	return _move_lock

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
	_threat_warning_service.reset()

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

func _check_post_move_actions(selected_idx: int, unit: Unit, terrain_map) -> void:
	var result := _execution_service.evaluate_post_move(unit, terrain_map, _unit_manager, selected_idx)
	if result.emit_actions:
		actions_updated.emit(unit, terrain_map, _unit_manager, selected_idx)
	if result.complete_turn:
		_turn_controller.complete_player_activation(selected_idx)
	if not result.log_message.is_empty():
		print_debug(result.log_message)

func _should_abort_move() -> bool:
	return _goal_controller.is_goal_reached()

func _get_active_unit_context() -> Dictionary:
	var selected_idx: int = _unit_manager.get_selected_index()
	if selected_idx == -1:
		return {"valid": false}
	var unit: Unit = _unit_manager.get_unit(selected_idx)
	if not unit or not _turn_controller.can_act_on_index(selected_idx):
		return {"valid": false}
	return {"valid": true, "index": selected_idx, "unit": unit}

func _execute_direction_move(unit: Unit, index: int, action: String) -> void:
	var validation := _request_validator.validate_direction_move(
		_unit_manager,
		_hex_navigator,
		_map_controller,
		_grid,
		index,
		unit,
		action,
		_grid_width,
		_grid_height,
		_current_wind_direction, # New parameter
		_current_wind_intensity # New parameter
	)
	if not validation.success:
		_release_move_lock_deferred()
		return

	_execution_service.execute_move(_unit_controller, _goal_controller, unit, index, validation.next, validation.cost)
	_check_post_move_actions(index, unit, validation.terrain_map)
	_release_move_lock_deferred()

func _execute_tentative_direction_move(unit: Unit, index: int, action: String) -> void:
	var validation := _request_validator.validate_direction_move(
		_unit_manager,
		_hex_navigator,
		_map_controller,
		_grid,
		index,
		unit,
		action,
		_grid_width,
		_grid_height,
		_current_wind_direction, # New parameter
		_current_wind_intensity # New parameter
	)
	if not validation.success:
		if not validation.error_message.is_empty():
			print_debug("DBG request_move_tentative: ", validation.error_message)
		_release_move_lock_deferred()
		return

	unit.set_tentative_move(validation.next, [validation.next], validation.cost)
	_unit_controller.set_coord(index, validation.next)
	actions_updated.emit(unit, validation.terrain_map, _unit_manager, index)
	_release_move_lock_deferred()

func _execute_coordinate_move(unit: Unit, index: int, target_coord: Vector2i) -> void:
	var validation := _request_validator.validate_coordinate_move(
		unit,
		_unit_manager,
		_map_controller,
		index,
		target_coord,
		_grid_width,
		_grid_height,
		_current_wind_direction, # New parameter
		_current_wind_intensity # New parameter
	)
	if not validation.success:
		if not validation.error_message.is_empty():
			print_debug("DBG request_move_to_coord: ", validation.error_message)
		_release_move_lock_deferred()
		return

	var warning_message := _threat_warning_service.evaluate(unit, validation.origin, _unit_manager, validation.terrain_map)
	if not warning_message.is_empty():
		threat_warning_requested.emit(warning_message)

	unit.set_tentative_move(target_coord, validation.path, validation.cost)
	_unit_controller.set_coord(index, target_coord)

	var terrain_map = _map_controller.get_terrain_map()
	actions_updated.emit(unit, terrain_map, _unit_manager, index)

	print_debug("DBG request_move_to_coord: success, tentative destination set to ", target_coord, " (cost: ", validation.cost, ")")
	_release_move_lock_deferred()

func _validate_tentative_move_exists(unit: Unit, action_name: String) -> bool:
	if not unit or not unit.has_tentative_move():
		print_debug("DBG %s_move: No tentative move to %s" % [action_name, action_name])
		return false
	return true

func _handle_threat_confirmation() -> bool:
	if _threat_warning_service.needs_confirmation():
		var warning_message := _threat_warning_service.acknowledge_warning()
		if not warning_message.is_empty():
			threat_warning_requested.emit(warning_message)
		return true
	return false

func _finalize_move(unit: Unit, index: int) -> void:
	_execution_service.finalize_tentative_move(_unit_controller, _goal_controller, unit, index)
	_reset_warnings()
	var terrain_map = _map_controller.get_terrain_map()
	_check_post_move_actions(index, unit, terrain_map)

func _perform_cancellation(unit: Unit, index: int) -> void:
	_reset_warnings()
	_unit_controller.set_coord(index, unit.get_start_of_turn_grid_coord())
	unit.clear_tentative_move()
	var terrain_map = _map_controller.get_terrain_map()
	actions_updated.emit(unit, terrain_map, _unit_manager, index)

func _on_weather_effect_applied(weather_info: Dictionary): # Changed from WeatherAttribute
	if weather_info.has("wind_direction"):
		_current_wind_direction = weather_info.wind_direction
	if weather_info.has("wind_intensity"):
		_current_wind_intensity = weather_info.wind_intensity

	print("MoveController received weather effect: ", weather_info.get("name", "Unknown"), ". Wind: ", _current_wind_direction, " (", _current_wind_intensity, ")")

