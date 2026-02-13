class_name InputController
extends Node

const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")
const DialogueActionService := preload("res://Gameplay/dialogue_action_service.gd") # NEW
const InputActions := preload("res://Resources/input_actions.gd") # NEW

signal checkpoint_requested
signal undo_requested
signal redo_requested
signal command_executed(command_name: String, result: CommandResult)

var _input_handler: InputHandler
var _unit_manager: UnitManager
var _hex_navigator: HexNavigator
var _camera_controller: CameraController
var _move_controller: MoveController
var _turn_controller: TurnController
var _task_controller: TaskController
var _grid: Node2D
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

func setup(services: GameSessionServices, config: GameSessionBuilder.Config, command_set: Dictionary = {}) -> void:
	_input_handler = config.input_handler
	_unit_manager = services.unit_manager
	_hex_navigator = services.hex_navigator
	_camera_controller = services.camera_controller
	_move_controller = services.move_controller
	_turn_controller = services.turn_controller
	_task_controller = services.task_controller
	_grid = config.grid
	_controls = config.controls
	_input_mapper = config.input_mapper
	assert(services.binding_service != null, "InputController requires a binding service")
	assert(services.command_context != null, "InputController requires a command context")
	assert(services.command_router != null, "InputController requires a command router")
	_binding_service = services.binding_service
	_dialogue_service = services.dialogue_action_service # NEW
	_grid_visuals = services.grid_visuals
	_terrain_map = services.terrain_map
	_hud = services.hud
	_hud_controller = services.hud_controller
	_command_context = services.command_context
	_command_router = services.command_router
	_command_router.set_context(_command_context)
	apply_command_set(command_set)
	print_debug("InputController: command router initialized; commands=", str(_command_router != null and _command_router._commands.keys() or []))

	_register_input_actions()
	_connect_signals()
	if is_instance_valid(_input_handler):
		_input_handler.refresh_action_cache()

func apply_command_set(command_set: Dictionary = {}) -> void:
	if _command_router == null:
		return
	var commands := _default_command_set()
	if not command_set.is_empty():
		for key in command_set.keys():
			commands[key] = command_set[key]
	_command_router.set_commands(commands)

func _connect_signals() -> void:
	_input_handler.move_requested.connect(_on_move_requested)
	_input_handler.selection_cycle_requested.connect(_on_selection_cycle_requested)
	_input_handler.select_index_requested.connect(_on_select_index_requested)
	_input_handler.primary_action_at.connect(_on_primary_action_at)
	_input_handler.secondary_action_at.connect(_on_secondary_action_at)
	_input_handler.free_cam_toggle_requested.connect(_on_free_cam_toggle_requested)
	_input_handler.toggle_enemy_range_requested.connect(_on_toggle_enemy_range_requested)
	_input_handler.joy_axis_held.connect(_on_joy_axis_held)
	_input_handler.zoom_requested.connect(_on_zoom_requested)
	_input_handler.wait_requested.connect(_on_wait_requested)
	_input_handler.confirm_move_requested.connect(_on_confirm_move_requested)
	_input_handler.cancel_move_requested.connect(func(): _execute_command("cancel_move"))
	_input_handler.ui_nav_toggle_requested.connect(_on_ui_nav_toggle_requested)
	if is_instance_valid(_camera_controller):
		_input_handler.camera_input_requested.connect(_camera_controller.handle_camera_input)

func _unhandled_input(event: InputEvent) -> void:
	print_debug("InputController: _unhandled_input() received event: %s" % event)
	if _dialogue_service and _dialogue_service.is_dialogue_active():
		print_debug("InputController: Dialogue active. Checking for dialogue-related input.")
		if event.is_action_pressed(InputActions.DIALOGUE_SKIP_ACTION):
			print_debug("InputController: DIALOGUE_SKIP_ACTION pressed. Skipping dialogue.")
			# Don't _mark_input_handled(). Let Dialogic handle it.
			_dialogue_service.skip_active_dialogue()
			return # Exit to prevent further InputController processing, but don't mark as handled.
		
		# NEW: Log dialogic_default_action
		if event.is_action_pressed("dialogic_default_action"):
			print_debug("InputController: 'dialogic_default_action' pressed during active dialogue.")

	if event.is_action_pressed("ui_undo"):
		if _turn_controller and _turn_controller.is_player_auto_control_locked():
			var reason := "Auto battle resolving action"
			if _hud and _hud.has_method("show_warning_message"):
				_hud.show_warning_message(reason)
			return
		undo_requested.emit()
	elif event.is_action_pressed("ui_redo"):
		if _turn_controller and _turn_controller.is_player_auto_control_locked():
			var reason := "Auto battle resolving action"
			if _hud and _hud.has_method("show_warning_message"):
				_hud.show_warning_message(reason)
			return
		redo_requested.emit()
	
	print_debug("InputController: _unhandled_input() finished processing event: %s. Handled: %s" % [event, get_viewport().is_input_handled()])

func _on_move_requested(action: String) -> void:
	_execute_command("move_action", action)

func _on_selection_cycle_requested(direction: int) -> void:
	_execute_command("selection_cycle", direction)

func _on_select_index_requested(index: int) -> void:
	_execute_command("select_index", index)

func _on_free_cam_toggle_requested() -> void:
	_execute_command("toggle_free_cam")

func _on_toggle_enemy_range_requested() -> void:
	_execute_command("toggle_enemy_range")

func _on_zoom_requested(direction: int) -> void:
	_execute_command("zoom_camera", direction)

func _on_joy_axis_held(axis: Vector2, _delta: float) -> void:
	_execute_command("joy_move", {"axis": axis})

func _on_primary_action_at(screen_pos: Vector2) -> void:
	var global_pos = screen_pos
	if is_instance_valid(_grid):
		global_pos = _grid.get_viewport().get_canvas_transform().affine_inverse() * screen_pos

	if is_instance_valid(_grid) and is_instance_valid(_unit_manager):
		var local_pos = _grid.to_local(global_pos)
		var coord = _grid.local_to_map(local_pos)
		var unit_idx = _unit_manager.index_of_unit_at(coord)
		if unit_idx != -1:
			_execute_command("select_index", unit_idx)
			return

	print_debug("DBG _on_primary_action_at screen=", screen_pos, " global=", global_pos)
	_execute_command("primary_action", global_pos)

func _on_secondary_action_at(screen_pos: Vector2) -> void:
	var selected_idx: int = _unit_manager.get_selected_index()
	var unit: Unit = _unit_manager.get_unit(selected_idx)
	if unit and unit.has_tentative_move():
		_execute_command("cancel_move")
	else:
		# Potentially handle other secondary actions here if needed
		pass

func _on_wait_requested() -> void:
	_execute_command("wait")

func _on_confirm_move_requested() -> void:
	_execute_command("confirm_move")

func _on_ui_nav_toggle_requested() -> void:
	set_ui_navigation_mode(not _ui_nav_active)


func _execute_command(command_name: String, payload = null) -> CommandResult:
	var result: CommandResult = null
	if _command_router == null:
		print_debug("InputController: no command router; skipping ", command_name)
		result = CommandResult.invalid_context(["router"])
		command_executed.emit(command_name, result)
		return result

	# Bypass checks for camera controls
	var camera_commands = ["toggle_free_cam", "zoom_camera", "joy_move", "toggle_enemy_range"]
	if command_name in camera_commands:
		print_debug("InputController: executing camera command '", command_name, "' with payload=", str(payload))
		result = _command_router.execute(command_name, payload)
		command_executed.emit(command_name, result)
		return result

	var selection_commands = ["select_index", "selection_cycle"]
	if command_name in selection_commands:
		print_debug("InputController: executing selection command '", command_name, "'")
		result = _command_router.execute(command_name, payload)
		command_executed.emit(command_name, result)
		return result

	var selected_index: int = _unit_manager.get_selected_index()
	var is_player_unit: bool = _unit_manager.is_player_controlled(selected_index)
	var is_player_turn: bool = _turn_controller.can_act_on_index(selected_index)
	print_debug("InputController: cmd=", command_name, " sel=", selected_index, " player_unit=", is_player_unit, " player_turn=", is_player_turn)
	var auto_battle_enabled := _turn_controller and _turn_controller.is_player_auto_battle_enabled()
	var auto_battle_locked := _turn_controller and _turn_controller.is_player_auto_control_locked()
	if auto_battle_enabled or auto_battle_locked:
		var reason := "Auto battle resolving action" if auto_battle_locked and not auto_battle_enabled else "Auto battle active"
		print_debug("InputController: blocked command '", command_name, "' (reason=", reason, ")")
		if _hud and _hud.has_method("show_warning_message"):
			_hud.show_warning_message(reason)
		result = CommandResult.precondition_failed(reason)
		command_executed.emit(command_name, result)
		return result

	# Trigger checkpoint for state-changing commands
	if command_name in ["move_action", "primary_action", "wait", "confirm_move", "cancel_move", "use_skill", "talk_to_unit"]:
		print_debug("InputController: checkpoint requested for ", command_name)
		checkpoint_requested.emit()

	var actor_index := selected_index
	if is_player_unit and is_player_turn:
		var should_lock_turn := _turn_controller != null and _should_lock_turn_for_command(command_name)
		print_debug("InputController: executing player command '", command_name, "'")
		result = _command_router.execute(command_name, payload)
		if should_lock_turn and result is CommandResult and result.is_success():
			_turn_controller.lock_active_player_unit(actor_index)
	else:
		print_debug("InputController: blocked command '", command_name, "' (is_player_unit=", is_player_unit, ", is_player_turn=", is_player_turn, ")")
		result = CommandResult.precondition_failed("Unit cannot act")

	command_executed.emit(command_name, result)
	return result

func _should_lock_turn_for_command(command_name: String) -> bool:
	var non_locking := {
		"move_to_coord": true,
		"primary_action": true,
		"cancel_move": true,
		"undo": true,
	}
	return not non_locking.get(command_name, false)
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
		_hud.set_ui_navigation_mode(enabled)

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
