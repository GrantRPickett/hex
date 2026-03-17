class_name InputController
extends Node

signal checkpoint_requested
signal undo_requested
signal redo_requested
signal command_executed(command_id: GameConstants.Commands.CommandID, result: CommandResult)

var _input_handler: InputHandler
var _unit_manager: UnitManager
var _hex_navigator: HexNavigator
var _camera_controller: CameraController
var _move_controller: MoveController
var _turn_controller: TurnController
var _task_controller: TaskController
var _grid: TileMapLayer
var _controls: Node
var _input_mapper: Node
var _grid_visuals: GridVisuals
var _terrain_map: TerrainMap
var _hud: Hud
var _hud_controller: HUDController
var _ui_nav_active := false
var _command_context: GameCommandContext
var _command_router: InputCommandRouter
var _binding_service: InputBindingService
var _dialogue_service: DialogueActionService # NEW

var _current_state: InputState
var _combat_state: CombatInputState

func setup(state: GameState, config: GameSessionBuilder.Config, command_set: Dictionary = {}) -> void:
	_input_handler = config.input_handler
	_unit_manager = state.unit_manager
	_hex_navigator = state.hex_navigator
	_camera_controller = state.camera_controller
	_move_controller = state.move_controller
	_turn_controller = state.turn_controller
	_task_controller = state.task_controller
	_grid = config.grid
	_controls = config.controls
	_input_mapper = config.input_mapper
	assert(state.binding_service != null, "InputController requires a binding service")
	assert(state.command_context != null, "InputController requires a command context")
	assert(state.command_router != null, "InputController requires a command router")
	_binding_service = state.binding_service
	_dialogue_service = state.dialogue_action_service # NEW
	_grid_visuals = state.grid_visuals
	_terrain_map = state.terrain_map
	_hud = state.hud
	_hud_controller = state.hud_controller
	_command_context = state.command_context
	_command_router = state.command_router
	_command_router.set_context(_command_context)
	apply_command_set(command_set)
	
	_combat_state = CombatInputState.new(self, _command_context, _command_router)
	_current_state = _combat_state

	_register_input_actions()
	_connect_signals()
	if is_instance_valid(_input_handler):
		_input_handler.refresh_action_cache()

func apply_command_set(command_set: Dictionary = {}) -> void:
	if _command_router == null:
		return
	var commands: Dictionary = _default_command_set()
	if not command_set.is_empty():
		for key: String in command_set.keys():
			commands[key] = command_set[key]
	_command_router.set_commands(commands)

func _connect_signals() -> void:
	var _e: int = 0
	_e = _input_handler.move_requested.connect(_on_move_requested)
	_e = _input_handler.selection_cycle_requested.connect(_on_selection_cycle_requested)
	_e = _input_handler.select_index_requested.connect(_on_select_index_requested)
	_e = _input_handler.primary_action_at.connect(_on_primary_action_at)
	_e = _input_handler.secondary_action_at.connect(_on_secondary_action_at)
	_e = _input_handler.free_cam_toggle_requested.connect(_on_free_cam_toggle_requested)
	_e = _input_handler.toggle_enemy_range_requested.connect(_on_toggle_enemy_range_requested)
	_e = _input_handler.joy_axis_held.connect(_on_joy_axis_held)
	_e = _input_handler.zoom_requested.connect(_on_zoom_requested)
	_e = _input_handler.wait_requested.connect(_on_wait_requested)
	_e = _input_handler.confirm_move_requested.connect(_on_confirm_move_requested)
	_e = _input_handler.cancel_move_requested.connect(func() -> void: var _res: CommandResult = _execute_command(GameConstants.Commands.CommandID.CANCEL_MOVE))
	_e = _input_handler.ui_nav_toggle_requested.connect(_on_ui_nav_toggle_requested)
	if is_instance_valid(_camera_controller):
		_e = _input_handler.camera_input_requested.connect(_camera_controller.handle_camera_input)

func _unhandled_input(event: InputEvent) -> void:
	if _dialogue_service and _dialogue_service.is_dialogue_active():
		if event.is_action_pressed(InputActions.DIALOGUE_SKIP_ACTION):
			_dialogue_service.skip_active_dialogue()
			get_viewport().set_input_as_handled()
		return

	if _current_state:
		_current_state.handle_input(event)

func _on_move_requested(action: String) -> void:
	var _res: CommandResult = _execute_command(GameConstants.Commands.CommandID.MOVE_ACTION, action)

func _on_selection_cycle_requested(direction: int) -> void:
	var _res: CommandResult = _execute_command(GameConstants.Commands.CommandID.SELECTION_CYCLE, direction)

func _on_select_index_requested(index: int) -> void:
	var _res_select: CommandResult = _execute_command(GameConstants.Commands.CommandID.SELECT_INDEX, index)

func _on_free_cam_toggle_requested() -> void:
	var _res_cam: CommandResult = _execute_command(GameConstants.Commands.CommandID.TOGGLE_FREE_CAM)

func _on_toggle_enemy_range_requested() -> void:
	var _res_range: CommandResult = _execute_command(GameConstants.Commands.CommandID.TOGGLE_ENEMY_RANGE)

func _on_joy_axis_held(axis: Vector2, _delta: float) -> void:
	var _res: CommandResult = _execute_command(GameConstants.Commands.CommandID.JOY_MOVE, {"axis": axis})

func _on_zoom_requested(direction: int) -> void:
	var _res: CommandResult = _execute_command(GameConstants.Commands.CommandID.ZOOM_CAMERA, direction)

func _on_primary_action_at(screen_pos: Vector2) -> void:
	var global_pos: Vector2 = screen_pos
	if is_instance_valid(_grid):
		global_pos = _grid.get_viewport().get_canvas_transform().affine_inverse() * screen_pos

	var coord: Vector2i = Vector2i.ZERO
	if is_instance_valid(_grid) and is_instance_valid(_unit_manager):
		var local_pos: Vector2 = _grid.to_local(global_pos)
		coord = _grid.local_to_map(local_pos)

	# Check for dialogue trigger at clicked coordinate
	if _dialogue_service:
		var result: CommandResult = _dialogue_service.trigger_at_coord(coord)
		if result.is_success():
			_mark_input_handled()
			return

	if is_instance_valid(_grid) and is_instance_valid(_unit_manager):
		var unit_idx: int = _unit_manager.index_of_unit_at(coord)
		if unit_idx != -1:
			var _result_select: CommandResult = _execute_command(GameConstants.Commands.CommandID.SELECT_INDEX, unit_idx)
			return

	print_debug("DBG _on_primary_action_at screen=", screen_pos, " global=", global_pos)
	var _result_primary: CommandResult = _execute_command(GameConstants.Commands.CommandID.PRIMARY_ACTION, global_pos)

func _on_secondary_action_at(_screen_pos: Vector2) -> void:
	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)
	if unit and unit.movement.has_tentative_move():
		var _res: CommandResult = _execute_command(GameConstants.Commands.CommandID.CANCEL_MOVE)
	else:
		# Potentially handle other secondary actions here if needed
		pass

func _on_wait_requested() -> void:
	var _result_wait: CommandResult = _execute_command(GameConstants.Commands.CommandID.WAIT)

func _on_confirm_move_requested() -> void:
	var _result_confirm: CommandResult = _execute_command(GameConstants.Commands.CommandID.CONFIRM_MOVE)

func _on_ui_nav_toggle_requested() -> void:
	set_ui_navigation_mode(not _ui_nav_active)


func execute_command(command_id: GameConstants.Commands.CommandID, payload: Variant = null) -> CommandResult:
	return _execute_command(command_id, payload)

func _execute_command(command_id: GameConstants.Commands.CommandID, payload: Variant = null) -> CommandResult:
	if _command_router == null:
		print_debug("InputController: no command router; skipping %d" % command_id)
		return CommandResult.invalid_context(["router"])

	# Context-aware checkpoint triggering
	if command_id in [
		GameConstants.Commands.CommandID.MOVE_ACTION,
		GameConstants.Commands.CommandID.PRIMARY_ACTION,
		GameConstants.Commands.CommandID.WAIT,
		GameConstants.Commands.CommandID.CONFIRM_MOVE,
		GameConstants.Commands.CommandID.CANCEL_MOVE,
		GameConstants.Commands.CommandID.USE_SKILL,
		GameConstants.Commands.CommandID.TALK
	]:
		checkpoint_requested.emit()

	if _current_state:
		var state_result: CommandResult = _current_state.handle_action(command_id, payload)
		command_executed.emit(command_id, state_result)
		return state_result

	var result: CommandResult = _command_router.execute(command_id, payload)
	command_executed.emit(command_id, result)
	return result
func _register_input_actions() -> void:
	if _binding_service and _input_mapper:
		_binding_service.apply_bindings(_controls, _input_mapper)

func _default_command_set() -> Dictionary:
	return CommandFactory.create_default_command_set()

func set_ui_navigation_mode(enabled: bool) -> void:
	if _ui_nav_active == enabled:
		return
	_ui_nav_active = enabled
	if is_instance_valid(_input_handler):
		_input_handler.set_ui_navigation_mode(enabled)
	if is_instance_valid(_hud_controller) and _hud_controller.has_method("set_ui_navigation_mode"):
		_hud_controller.set_ui_navigation_mode(enabled)
	elif is_instance_valid(_hud) and _hud.has_method("set_ui_navigation_mode"):
		_hud.call("set_ui_navigation_mode", enabled)

func request_select_index(index: int) -> void:
	_on_select_index_requested(index)

func request_selection_cycle(direction: int) -> void:
	_on_selection_cycle_requested(direction)

func request_wait() -> void:
	_on_wait_requested()

func register_input_actions() -> void:
	_register_input_actions()

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.set_input_as_handled()
