extends Node2D

signal level_complete(next_level_path)
signal quit_to_title
signal quit_to_level_select

const TITLE_SCENE_PATH := "res://Menus/title_screen.tscn"
const CREDITS_SCENE_PATH := "res://Menus/credits.tscn"
const GameSessionBuilderScript := preload("res://Gameplay/game_session_builder.gd")
const LevelLoader := preload("res://Gameplay/level_loader.gd")
const InputMapperScript := preload("res://Autoloads/input_mapper.gd")
const InputActions := preload("res://Resources/input_actions.gd")

const GRID_WIDTH := 7
const GRID_HEIGHT := 7

@onready var _grid = $Grid
@onready var _player: Sprite2D = $Player
@onready var _goal: Sprite2D = $Goal
@onready var _goal2: Sprite2D = $Goal2
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_handler: CameraHandler = $CameraHandler
@onready var _pause_handler: PauseHandler = $PauseHandler
@onready var _input_handler: InputHandler = $InputHandler

var _game_state: GameState
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _hex_navigator: HexNavigator
var _move_controller: MoveController
var _goal_controller: GoalController
var _camera_controller: CameraController
var _input_controller: InputController
var _turn_system: TurnSystem
var _require_all_units_state := false
var _goal_reached_state := false

var _grid_width: int = GRID_WIDTH
var _grid_height: int = GRID_HEIGHT

var _controls: Node
@export var level_resource: Resource

func _ready() -> void:
	_controls = get_tree().root.get_node_or_null("ControlSettings")
	if _controls == null:
		push_warning("ControlSettings autoload not found in Gameplay.gd!")

	var builder := GameSessionBuilderScript.new()
	var build_config := GameSessionBuilderScript.Config.new()
	build_config.grid = _grid
	build_config.camera = _camera
	build_config.camera_handler = _camera_handler
	build_config.input_handler = _input_handler
	build_config.controls = _controls
	build_config.input_mapper = get_tree().root.get_node_or_null("InputMapper")
	_game_state = builder.build(build_config)
	_attach_game_state_nodes()
	_cache_context_references()
	_ensure_input_actions_registered()

	_game_state.grid_controller.configure_tileset()

	var goal_texture_primary = _game_state.goal_controller.create_target_texture(Color(1, 0.2, 0.2), Color(1, 1, 1))
	if is_instance_valid(_goal):
		_goal.texture = goal_texture_primary

	_game_state.unit_manager.unit_moved.connect(_on_unit_moved)
	_game_state.unit_manager.selection_changed.connect(_on_selection_changed)

	if is_instance_valid(_pause_handler):
		_pause_handler.quit_requested.connect(_on_quit_requested)

	_game_state.goal_controller.reset_goal_state()
	set_physics_process(true)
	set_process(true)
	_apply_level_if_available()

	_game_state.grid_controller.build_grid(_grid_width, _grid_height)
	_game_state.hex_navigator.cache_analog_vectors(_grid)

	_game_state.grid_visuals.setup_hex_shape(Vector2(_grid.tile_set.tile_size))

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
	_goal_manager = _game_state.goal_manager
	_hex_navigator = _game_state.hex_navigator
	_move_controller = _game_state.move_controller
	_goal_controller = _game_state.goal_controller
	_camera_controller = _game_state.camera_controller
	_input_controller = _game_state.input_controller
	_turn_system = _game_state.turn_controller.get_turn_system()
	_goal_reached_state = _game_state.goal_controller.is_goal_reached()
	if _controls:
		_require_all_units_state = _controls.require_all_units_to_goal

func _set_require_all_units_state(value: bool) -> void:
	_require_all_units_state = value
	if _controls:
		_controls.require_all_units_to_goal = value
	if _game_state:
		_game_state.goal_controller.set_require_all_units(value)

func _get_require_all_units_state() -> bool:
	return _require_all_units_state

func _set_goal_reached_state(value: bool) -> void:
	_goal_reached_state = value
	if not _game_state:
		return
	if value:
		return
	_game_state.goal_controller.reset_goal_state()

func _get_goal_reached_state() -> bool:
	if _game_state:
		_goal_reached_state = _game_state.goal_controller.is_goal_reached()
	return _goal_reached_state

func _ensure_input_actions_registered() -> void:
	var mapper: Node = get_tree().root.get_node_or_null("InputMapper")
	if mapper == null:
		mapper = InputMapperScript.new()
	var groups = [
		InputActions.MOVEMENT_DEFAULTS,
		InputActions.INTERACTION_DEFAULTS,
		InputActions.CAMERA_DEFAULTS,
		InputActions.SELECTION_DEFAULTS,
		InputActions.PAUSE_DEFAULTS,
	]
	for group in groups:
		var missing: Array = []
		for entry in group:
			var action_name: String = entry.get("action", "")
			if action_name == "":
				continue
			if not InputMap.has_action(action_name):
				missing.append(entry)
		if not missing.is_empty():
			mapper.apply_configs(missing, missing)

func _set(property: StringName, value) -> bool:
	var property_name := String(property)
	match property_name:
		"_require_all_units":
			_set_require_all_units_state(bool(value))
			return true
		"_goal_reached":
			_set_goal_reached_state(bool(value))
			return true
	return false

func _get(property: StringName):
	var property_name := String(property)
	match property_name:
		"_require_all_units":
			return _get_require_all_units_state()
		"_goal_reached":
			return _get_goal_reached_state()
	return null

func _on_quit_requested() -> void:
	_disable_gameplay()
	quit_to_title.emit()

func _process(_delta: float) -> void:
	if is_instance_valid(_game_state.grid_visuals):
		var mouse_pos = get_global_mouse_position()
		_game_state.grid_visuals.update_hover_indicator(mouse_pos, _grid, _game_state.unit_manager)
		_game_state.grid_visuals.update_path_preview(mouse_pos, _grid, _game_state.unit_manager, _game_state.map_controller.get_terrain_map())

func set_joy_axis(axis: Vector2) -> void:
	# Legacy support for tests if they call this directly
	if _input_handler:
		_input_handler._joy_axis = axis
		_input_handler._joy_repeat_timer = 0.0

func _on_unit_moved(index: int, coord: Vector2i) -> void:
	var sprite: Sprite2D = _game_state.unit_manager.get_unit_sprite(index)
	if sprite:
		sprite.position = _grid.map_to_local(coord)
	if index == _game_state.unit_manager.get_selected_index():
		_update_selection_visuals()

func _on_selection_changed(_index: int) -> void:
	_update_selection_visuals()

func _update_selection_visuals() -> void:
	_game_state.camera_controller.center_on_selected()
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_range_indicator(_grid, _game_state.unit_manager, _game_state.map_controller.get_terrain_map())

func _register_input_actions() -> void:
	if _input_controller:
		_input_controller.call("_register_input_actions")
	_ensure_input_actions_registered()

func _on_select_index_requested(index: int) -> void:
	if _input_controller:
		_input_controller._on_select_index_requested(index)

func _on_selection_cycle_requested(direction: int) -> void:
	if _input_controller:
		_input_controller._on_selection_cycle_requested(direction)

func request_move(action: String) -> void:
	if _move_controller:
		_move_controller.request_move(action)

func _on_wait_requested() -> void:
	if _input_controller:
		_input_controller._on_wait_requested()

func _center_camera_on_selected() -> void:
	if _camera_controller:
		_camera_controller.center_on_selected()

func _axial_to_pixel(coord: Vector2i) -> Vector2:
	return _grid.map_to_local(coord)

func update_goal_progress_for_selected() -> void:
	_update_goal_progress_for_selected()

func _update_goal_progress_for_selected() -> void:
	if _goal_controller:
		_goal_controller.check_goal_progress()
		_goal_reached_state = _goal_controller.is_goal_reached()

func _apply_level_dimensions_and_positions(level: Resource) -> void:
	level_resource = level
	_apply_level_if_available()

func _setup_units_and_goals(level: Resource) -> void:
	level_resource = level
	_apply_level_if_available()

func _apply_level_options(level: Resource) -> void:
	var data := LevelLoader.load_level_data(level)
	_set_require_all_units_state(data.require_all_units)
	if is_instance_valid(_grid.tile_set):
		var duplicate_tiles: TileSet = _grid.tile_set.duplicate(true)
		duplicate_tiles.tile_offset_axis = data.hex_offset_axis
		_grid.tile_set = duplicate_tiles


func _apply_level_if_available() -> void:
	if not level_resource:
		return

	_set_goal_reached_state(false)
	var result = _game_state.map_controller.load_level(level_resource, self, _game_state.unit_manager, _game_state.goal_manager, _camera, _controls, _player, [_goal, _goal2])
	_grid_width = result.grid_width
	_grid_height = result.grid_height
	_set_require_all_units_state(result.require_all_units)
	_game_state.move_controller.update_grid_dimensions(_grid_width, _grid_height)

	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_level_and_rebuild(level: Resource) -> void:
	level_resource = level
	_apply_level_if_available()
	# Reset goal progress when loading a level
	_game_state.goal_controller.reset_goal_state()
	_game_state.grid_controller.build_grid(_grid_width, _grid_height)
	_game_state.hex_navigator.cache_analog_vectors(_grid)

	_game_state.camera_controller.init_camera_snap()
	_game_state.camera_controller.center_on_selected()

func add_unit(sprite: Sprite2D, coord: Vector2i, is_player: bool) -> void:
	_game_state.unit_controller.add_unit(sprite, coord, is_player)
	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_unit_controlled_by_player(index: int, is_player: bool) -> void:
	_game_state.unit_controller.set_player_controlled(index, is_player)
	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

# Legacy helpers for tests
var player_coord: Vector2i:
	get: return _game_state.unit_manager.get_coord(0)
var goal_coord: Vector2i:
	get: return _game_state.goal_manager.get_target(0)
var goal2_coord: Vector2i:
	get: return _game_state.goal_manager.get_target(1)

func set_player_coord(coord: Vector2i) -> void:
	_game_state.unit_controller.set_coord(0, coord)

func set_goal_coord(coord: Vector2i) -> void:
	_game_state.goal_manager.set_target(0, coord)

func set_turn_system_enabled(enabled: bool) -> void:
	_game_state.turn_controller.set_enabled(enabled)
	_update_terrain_overlay()

func _update_terrain_overlay() -> void:
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_terrain_overlay(_grid, _game_state.map_controller.get_terrain_map())

func _on_goal_reached() -> void:
	_disable_gameplay()
	var next_level_path: String = ""
	if level_resource and "next_level_path" in level_resource and level_resource.next_level_path != null:
		next_level_path = level_resource.next_level_path
	if next_level_path.is_empty():
		quit_to_level_select.emit()
	else:
		level_complete.emit(next_level_path)

func _disable_gameplay() -> void:
	if _input_handler:
		_input_handler.reset_joy_state()
		_input_handler.set_process_unhandled_input(false)
	set_physics_process(false)
	_game_state.move_controller.set_physics_process(false)
	set_process(false)
