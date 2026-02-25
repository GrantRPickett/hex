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

var _level_manager_gameplay: LevelManagerGameplay

var _controls: Node
var _input_mapper: Node
var _save_manager: Node
@export var control_settings_path := NodePath("/root/ControlSettings")
@export var input_mapper_path := NodePath("/root/InputMapper")
@export var save_manager_path := NodePath("/root/SaveManager")
@export var level: Level
@export var enable_level_auto_fix := true

var _session: GameSession

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
	var roster = builder.load_player_roster(null, _save_manager)

	var config := GameSessionBuilder.Config.new()
	config.grid = _grid
	config.camera = _camera
	config.camera_handler = _camera_handler
	config.input_handler = _input_handler
	config.pause_handler = _pause_handler
	config.controls = _controls
	config.input_mapper = _input_mapper
	config.player_roster = roster
	config.level = level
	config.save_manager = _save_manager

	var GameSessionScript := preload("res://Gameplay/game_session.gd")
	_session = GameSessionScript.new(config)
	add_child(_session)
	_game_state = _session.state
	if is_instance_valid(_pause_handler):
		_pause_handler.set_journal_manager(_game_state.journal_manager)


func _setup_level_manager() -> void:
	_level_manager_gameplay = LevelManagerGameplay.new(_game_state, _controls)
	_level_manager_gameplay.set_level_resource(level)
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
	if is_instance_valid(_pause_handler):
		if not _pause_handler.pause_state_changed.is_connected(_session.handle_pause_state_changed):
			_pause_handler.pause_state_changed.connect(_session.handle_pause_state_changed)
		if not _pause_handler.quit_requested.is_connected(_on_quit_requested):
			_pause_handler.quit_requested.connect(_on_quit_requested)

	_game_state.task_controller.task_reached.connect(_level_manager_gameplay.on_task_reached)
	_game_state.task_controller.game_over.connect(_level_manager_gameplay.on_task_failed)


func _finish_setup() -> void:
	_game_state.task_controller.reset_task_state()
	set_physics_process(true)
	_level_manager_gameplay.apply_level_if_available()

	_game_state.camera_controller.center_on_selected()
	_game_state.camera_controller.init_camera_snap()

func _resolve_dependency(path: NodePath, label: String) -> Node:
	if path.is_empty():
		return null
	var node := get_node_or_null(path)
	if node == null:
		push_warning("Gameplay: Missing %s at %s" % [label, path])
	return node

func _on_quit_requested() -> void:
	_session.disable_gameplay()
	quit_to_title.emit()


func set_level_and_rebuild(p_level: Level) -> void:
	self.level = p_level
	if _game_state:
		_game_state.level = p_level
	if _level_manager_gameplay:
		_level_manager_gameplay.set_level_and_rebuild(p_level)

func _update_terrain_overlay() -> void:
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_terrain_overlay(_grid, _game_state.map_controller.get_terrain_map())

func _disable_gameplay() -> void:
	_session.disable_gameplay()
	set_physics_process(false)
	set_process(false)

func _exit_tree() -> void:
	if is_instance_valid(_pause_handler):
		if _pause_handler.quit_requested.is_connected(_on_quit_requested):
			_pause_handler.quit_requested.disconnect(_on_quit_requested)
		if _pause_handler.pause_state_changed.is_connected(_session.handle_pause_state_changed):
			_pause_handler.pause_state_changed.disconnect(_session.handle_pause_state_changed)
