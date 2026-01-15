class_name InputController
extends Node

const CameraController := preload("res://Gameplay/camera_controller.gd")

var _gameplay: Node
var _input_handler: InputHandler
var _unit_manager: UnitManager
var _hex_navigator: HexNavigator
var _camera_controller: CameraController
var _grid: Node2D
var _turn_system: TurnSystem
var _controls: Node
var _input_mapper: Node

func setup(gameplay: Node, input_handler: InputHandler, unit_manager: UnitManager, hex_navigator: HexNavigator, camera_controller: CameraController, grid: Node2D, turn_system: TurnSystem, controls: Node, input_mapper: Node) -> void:
	_gameplay = gameplay
	_input_handler = input_handler
	_unit_manager = unit_manager
	_hex_navigator = hex_navigator
	_camera_controller = camera_controller
	_grid = grid
	_turn_system = turn_system
	_controls = controls
	_input_mapper = input_mapper

	_register_input_actions()
	_connect_signals()
	if is_instance_valid(_input_handler):
		_input_handler.refresh_action_cache()

func _connect_signals() -> void:
	_input_handler.move_requested.connect(_on_move_requested)
	_input_handler.selection_cycle_requested.connect(_on_selection_cycle_requested)
	_input_handler.select_index_requested.connect(_on_select_index_requested)
	_input_handler.primary_action_at.connect(_on_primary_action_at)
	_input_handler.free_cam_toggle_requested.connect(_on_free_cam_toggle_requested)
	_input_handler.joy_axis_held.connect(_on_joy_axis_held)
	_input_handler.zoom_requested.connect(_on_zoom_requested)
	_input_handler.wait_requested.connect(_on_wait_requested)
	if is_instance_valid(_camera_controller):
		_input_handler.camera_input_requested.connect(_camera_controller.handle_camera_input)

func _on_move_requested(action: String) -> void:
	var from_coord := _unit_manager.get_selected_coord()
	var mapped: String = _hex_navigator.map_action_by_camera(action, from_coord, _camera_controller.get_rotation(), _grid)
	_gameplay.request_move(mapped)

func _on_selection_cycle_requested(direction: int) -> void:
	if not is_instance_valid(_turn_system):
		_unit_manager.cycle_selection(direction)
		return
	var count := _unit_manager.get_unit_count()
	if count <= 1:
		return
	var start := _unit_manager.get_selected_index()
	var current := start
	for i in range(count):
		current = int((current + direction) % count)
		if current < 0:
			current = count - 1
		var can_act := true
		if _gameplay.is_turn_system_enabled():
			can_act = _turn_system.can_unit_act(current)
		if _unit_manager.is_player_controlled(current) and can_act:
			_unit_manager.select_index(current)
			return

func _on_select_index_requested(index: int) -> void:
	if not _gameplay.can_act_on_index(index):
		return
	_unit_manager.select_index(index)

func _on_free_cam_toggle_requested() -> void:
	if is_instance_valid(_camera_controller):
		_camera_controller.toggle_free_cam()

func _on_zoom_requested(direction: int) -> void:
	if is_instance_valid(_camera_controller):
		_camera_controller.zoom(direction)

func _on_joy_axis_held(axis: Vector2, _delta: float) -> void:
	var action :String= _hex_navigator.get_action_from_joy_axis(axis, _camera_controller.get_rotation(), _unit_manager.get_selected_coord(), _grid)
	if action != "":
		_gameplay.request_move(action)

func _on_primary_action_at(screen_pos: Vector2) -> void:
	var cell: Vector2i = _grid.local_to_map(_grid.to_local(screen_pos))
	var idx := _unit_manager.index_of_unit_at(cell)
	if idx != -1:
		if _unit_manager.is_player_controlled(idx):
			if _gameplay.can_act_on_index(idx):
				_unit_manager.select_index(idx)
	else:
		var from: Vector2i = _unit_manager.get_selected_coord()
		var dir_map :Dictionary= _hex_navigator.get_direction_map(from, _grid)
		var diff: Vector2i = cell - from
		for action in dir_map.keys():
			if dir_map[action] == diff:
				_gameplay.request_move(action)
				break

func _on_wait_requested() -> void:
	if not _gameplay.is_interaction_allowed():
		return
	var selected_idx := _unit_manager.get_selected_index()
	if not _gameplay.can_act_on_index(selected_idx):
		return
	_gameplay.complete_player_activation(selected_idx)

func _register_input_actions() -> void:
	if _input_mapper == null:
		return
	_input_mapper.apply_configs(_movement_actions(), InputActions.MOVEMENT_DEFAULTS)
	var interaction_configs: Array = []
	if _controls and not _controls.interaction_actions.is_empty():
		interaction_configs = _controls.interaction_actions
	_input_mapper.apply_configs(interaction_configs, InputActions.INTERACTION_DEFAULTS)
	var camera_configs: Array = []
	if _controls and not _controls.camera_actions.is_empty():
		camera_configs = _controls.camera_actions
	_input_mapper.apply_configs(camera_configs, InputActions.CAMERA_DEFAULTS)
	var selection_configs: Array = []
	if _controls and not _controls.selection_actions.is_empty():
		selection_configs = _controls.selection_actions
	_input_mapper.apply_configs(selection_configs, InputActions.SELECTION_DEFAULTS)
	var pause_configs: Array = []
	if _controls and not _controls.pause_actions.is_empty():
		pause_configs = _controls.pause_actions
	_input_mapper.apply_configs(pause_configs, InputActions.PAUSE_DEFAULTS)

func _movement_actions() -> Array:
	if _controls and not _controls.move_actions.is_empty():
		return _controls.move_actions
	return []