extends Node2D

signal level_complete()
signal quit_to_title
signal quit_to_level_select

# InputActions class is auto-global in Godot 4

@onready var _grid: TileMapLayer = $Grid
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_handler: CameraHandler = $CameraHandler
@onready var _pause_handler: PauseHandler = $PauseHandler
@onready var _input_handler: InputHandler = $InputHandler

var _game_state: GameState
var _unit_manager: UnitManager
var _loot_manager: LootManager
var _hex_navigator: HexNavigator
var _move_controller: MoveController
var _animation_service
var _task_controller: TaskController
var _camera_controller: CameraController
var _input_controller: InputController
var _turn_controller: TurnController
var _turn_system: TurnSystem


var _map_controller: MapController
var _terrain_map
var _hud_controller: HUDController
var _hud: Hud

var _level_manager_gameplay: LevelManagerGameplay

var _controls: Node
var _input_mapper: Node
var _save_manager: Node
@export var player_roster: PlayerRoster
@export var control_settings_path := NodePath("/root/ControlSettings")
@export var input_mapper_path := NodePath("/root/InputMapper")
@export var save_manager_path := NodePath("/root/SaveManager")
@export var enable_level_auto_fix := true

func _ready() -> void:
	_init_dependencies()
	_init_session()
	_setup_level_manager()
	_connect_game_signals()
	_finish_setup()


func _init_dependencies() -> void:
	_controls = _resolve_dependency(control_settings_path, "ControlSettings")
	_input_mapper = _resolve_dependency(input_mapper_path, "InputMapper")
	_save_manager = _resolve_dependency(save_manager_path, "SaveManager")


func _init_session() -> void:
	var builder: GameSessionBuilder = GameSessionBuilder.new()
	player_roster = builder.load_player_roster(player_roster, _save_manager)

	var build_config := GameSessionBuilder.Config.new()
	build_config.grid = _grid
	build_config.camera = _camera
	build_config.camera_handler = _camera_handler
	build_config.input_handler = _input_handler
	build_config.pause_handler = _pause_handler
	build_config.controls = _controls
	build_config.input_mapper = _input_mapper
	_game_state = builder.build(build_config)
	_attach_game_state_nodes()
	_cache_context_references()
	_register_input_actions()


func _setup_level_manager() -> void:
	_level_manager_gameplay = LevelManagerGameplay.new(_game_state, self, _controls)
	var allow_auto_fix := enable_level_auto_fix and OS.is_debug_build()
	_level_manager_gameplay.set_auto_fix_enabled(allow_auto_fix)
	if _game_state.dialogue_action_service:
		_level_manager_gameplay.set_dialogue_service(_game_state.dialogue_action_service)
	_level_manager_gameplay.set_save_manager(_save_manager)
	_level_manager_gameplay.level_complete.connect(func(path): level_complete.emit(path))
	_level_manager_gameplay.quit_to_title.connect(func(): quit_to_title.emit())
	_level_manager_gameplay.quit_to_level_select.connect(func(): quit_to_level_select.emit())
	if _game_state.unit_manager:
		_game_state.unit_manager.unit_moved.connect(_level_manager_gameplay.on_unit_moved)


func _connect_game_signals() -> void:
	_game_state.grid_controller.configure_tileset()

	if is_instance_valid(_pause_handler):
		if not _pause_handler.pause_state_changed.is_connected(_on_pause_state_changed):
			_pause_handler.pause_state_changed.connect(_on_pause_state_changed)
		if not _pause_handler.quit_requested.is_connected(_on_quit_requested):
			_pause_handler.quit_requested.connect(_on_quit_requested)

	_game_state.task_controller.task_reached.connect(_level_manager_gameplay.on_task_reached)
	_game_state.task_controller.game_over.connect(_level_manager_gameplay.on_task_failed)
	_game_state.task_controller.dialogue_requested.connect(_game_state.dialogue_action_service.handle_dialogue_request)


func _finish_setup() -> void:
	_game_state.task_controller.reset_task_state()
	set_physics_process(true)
	_level_manager_gameplay.apply_level_if_available()

	_game_state.hex_navigator.cache_analog_vectors(_grid)
	_game_state.grid_visuals.setup_hex_shape(Vector2(_grid.tile_set.tile_size), _grid)

	_game_state.camera_controller.center_on_selected()
	# Initialize camera snap base to nearest 60° and avoid drift
	_game_state.camera_controller.init_camera_snap()

func _attach_game_state_nodes() -> void:
	if _game_state == null:
		return
	for node in _game_state.get_tree_nodes():
		if node == null:
			continue
		add_child(node)

func _cache_context_references() -> void:
	if _game_state == null:
		return
	_unit_manager = _game_state.unit_manager
	_loot_manager = _game_state.loot_manager
	_hex_navigator = _game_state.hex_navigator
	_move_controller = _game_state.move_controller
	_animation_service = _game_state.animation_service
	_task_controller = _game_state.task_controller
	_camera_controller = _game_state.camera_controller
	_input_controller = _game_state.input_controller
	_turn_controller = _game_state.turn_controller
	_turn_system = _game_state.turn_controller.get_turn_system()
	_map_controller = _game_state.map_controller
	if _map_controller:
		_terrain_map = _map_controller.get_terrain_map()
	_hud_controller = _game_state.hud_controller
	_hud = _game_state.hud


func _resolve_dependency(path: NodePath, label: String) -> Node:
	if path.is_empty():
		return null
	var node := get_node_or_null(path)
	if node == null:
		push_warning("Gameplay: Missing %s at %s" % [label, path])
	return node

func _on_quit_requested() -> void:
	_disable_gameplay()
	quit_to_title.emit()

func _on_pause_state_changed(paused: bool) -> void:
	if not is_instance_valid(_turn_controller):
		return
	_turn_controller.set_enabled(not paused)
	if not paused and _turn_controller.get_current_side() == TurnSystem.Side.NEUTRAL:
		_turn_controller.start_next_turn()

func _register_input_actions() -> void:
	if _input_controller:
		_input_controller.register_input_actions()


func _on_select_index_requested(index: int) -> void:
	if _input_controller:
		_input_controller.request_select_index(index)

func _on_selection_cycle_requested(direction: int) -> void:
	if _input_controller:
		_input_controller.request_selection_cycle(direction)

func request_move(action: String) -> void:
	if _move_controller:
		_move_controller.request_move(action)

func _on_wait_requested() -> void:
	if _input_controller:
		_input_controller.request_wait()

func _center_camera_on_selected() -> void:
	if _camera_controller:
		_camera_controller.center_on_selected()

func _axial_to_pixel(coord: Vector2i) -> Vector2:
	return _grid.map_to_local(coord)

func update_task_progress_for_selected() -> void:
	_update_task_progress_for_selected()

func _update_task_progress_for_selected() -> void:
	if _level_manager_gameplay:
		_level_manager_gameplay.update_task_progress()

func _apply_level_if_available() -> void:
	if _level_manager_gameplay:
		_level_manager_gameplay.apply_level_if_available()

func set_level_and_rebuild(level: Resource) -> void:
	if _game_state:
		if _game_state.location_service:
			_game_state.location_service.level = level
	if _level_manager_gameplay:
		_level_manager_gameplay.set_level_and_rebuild(level)

func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void:
	if not _game_state or not is_instance_valid(_game_state.unit_controller):
		return
	_game_state.unit_controller.add_unit(unit, coord, is_player)
	if _loot_manager:
		unit.set_loot_manager(_loot_manager)
	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_unit_controlled_by_player(index: int, is_player: bool) -> void:
	if not _game_state or not is_instance_valid(_game_state.unit_controller):
		return
	_game_state.unit_controller.set_player_controlled(index, is_player)
	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_turn_system_enabled(enabled: bool) -> void:
	if not _game_state or not is_instance_valid(_game_state.turn_controller):
		return
	_game_state.turn_controller.set_enabled(enabled)
	_update_terrain_overlay()

func _update_terrain_overlay() -> void:
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_terrain_overlay(_grid, _game_state.map_controller.get_terrain_map())

func _on_task_reached() -> void:
	# Handled by LevelManagerGameplay
	pass

func _disable_gameplay() -> void:
	if _input_handler:
		_input_handler.reset_joy_state()
		_input_handler.set_process_unhandled_input(false)
	set_physics_process(false)
	_game_state.move_controller.set_physics_process(false)
	set_process(false)

func _exit_tree() -> void:
	# Disconnect all signals to prevent memory leaks and stale connections
	if _game_state:
		if _game_state.task_controller and _game_state.task_controller.task_reached.is_connected(_level_manager_gameplay.on_task_reached):
			_game_state.task_controller.task_reached.disconnect(_level_manager_gameplay.on_task_reached)
		if _game_state.task_controller and _game_state.task_controller.game_over.is_connected(_level_manager_gameplay.on_task_failed):
			_game_state.task_controller.game_over.disconnect(_level_manager_gameplay.on_task_failed)

	if is_instance_valid(_pause_handler):
		if _pause_handler.quit_requested.is_connected(_on_quit_requested):
			_pause_handler.quit_requested.disconnect(_on_quit_requested)
		if _pause_handler.pause_state_changed.is_connected(_on_pause_state_changed):
			_pause_handler.pause_state_changed.disconnect(_on_pause_state_changed)
