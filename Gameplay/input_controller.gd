class_name InputController
extends Node


signal checkpoint_requested
signal undo_requested
signal redo_requested

var _input_handler: InputHandler
var _unit_manager: UnitManager
var _hex_navigator: HexNavigator
var _camera_controller: CameraController
var _move_controller: MoveController
var _turn_controller: TurnController
var _goal_controller: GoalController
var _grid: Node2D
var _controls: Node
var _input_mapper: Node
var _grid_visuals: GridVisuals
var _terrain_map: TerrainMap
var _command_context: GameCommandContext
var _command_router: InputCommandRouter
var _binding_service: InputBindingService = InputBindingService.new()

func setup(input_handler: InputHandler, unit_manager: UnitManager, hex_navigator: HexNavigator, camera_controller: CameraController, move_controller: MoveController, turn_controller: TurnController, goal_controller: GoalController, grid: Node2D, controls: Node, input_mapper: Node, grid_visuals: GridVisuals = null, terrain_map: TerrainMap = null, command_set: Dictionary = {}) -> void:
	_input_handler = input_handler
	_unit_manager = unit_manager
	_hex_navigator = hex_navigator
	_camera_controller = camera_controller
	_move_controller = move_controller
	_turn_controller = turn_controller
	_goal_controller = goal_controller
	_grid = grid
	_controls = controls
	_input_mapper = input_mapper
	_grid_visuals = grid_visuals
	_terrain_map = terrain_map
	_command_context = GameCommandContext.new(_unit_manager, _hex_navigator, _camera_controller, _move_controller, _turn_controller, _goal_controller, _grid, _grid_visuals, _terrain_map)
	_command_router = InputCommandRouter.new(_command_context)
	apply_command_set(command_set)

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
	if is_instance_valid(_camera_controller):
		_input_handler.camera_input_requested.connect(_camera_controller.handle_camera_input)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo"):
		undo_requested.emit()
	elif event.is_action_pressed("ui_redo"):
		redo_requested.emit()

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
	_execute_command("primary_action", screen_pos)

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

func _execute_command(command_name: String, payload = null) -> void:
	if _command_router == null:
		return

	# Bypass checks for camera controls
	var camera_commands = ["toggle_free_cam", "zoom_camera", "joy_move", "toggle_enemy_range"]
	if command_name in camera_commands:
		_command_router.execute(command_name, payload)
		return

	var selected_index: int = _unit_manager.get_selected_index()
	var is_player_unit: bool = _unit_manager.is_player_controlled(selected_index)
	var is_player_turn: bool = _turn_controller.can_act_on_index(selected_index)

	# Trigger checkpoint for state-changing commands
	if command_name in ["move_action", "primary_action", "wait", "confirm_move", "cancel_move"]:
		checkpoint_requested.emit()

	if is_player_unit and is_player_turn:
		_command_router.execute(command_name, payload)


func _register_input_actions() -> void:
	if _binding_service and _input_mapper:
		_binding_service.apply_bindings(_controls, _input_mapper)

func _default_command_set() -> Dictionary:
	return CommandFactory.create_default_command_set()
