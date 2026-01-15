extends Node2D

signal level_complete(next_level_path)
signal quit_to_title
signal quit_to_level_select

const TITLE_SCENE_PATH := "res://Menus/title_screen.tscn"
const CREDITS_SCENE_PATH := "res://Menus/credits.tscn"

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

var _grid_width: int = GRID_WIDTH
var _grid_height: int = GRID_HEIGHT

var _controls: Node
var _move_lock: bool = false
var _move_lock_release_queued: bool = false
@export var level_resource: Resource

func _ready() -> void:
	_controls = get_tree().root.get_node_or_null("ControlSettings")
	if _controls == null:
		push_warning("ControlSettings autoload not found in Gameplay.gd!")

	_game_state = GameState.new()
	add_child(_game_state)
	_game_state.grid_controller.setup(_grid)
	_game_state.map_controller.setup(_grid)
	_game_state.turn_controller.setup(_game_state.unit_manager)
	_game_state.camera_controller.setup(_camera, _camera_handler, _game_state.unit_manager)
	_game_state.goal_controller.setup(_game_state.goal_manager, _game_state.unit_manager)

	_game_state.hud_controller.setup(_game_state.hud, _game_state.turn_controller.get_turn_system(), _game_state.unit_manager, _grid)
	var input_mapper = get_tree().root.get_node_or_null("InputMapper")
	_game_state.input_controller.setup(self, _input_handler, _game_state.unit_manager, _game_state.hex_navigator, _game_state.camera_controller, _grid, _game_state.turn_controller.get_turn_system(), _controls, input_mapper)

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

func _on_quit_requested() -> void:
	_disable_gameplay()
	quit_to_title.emit()

func _physics_process(_delta: float) -> void:
	# Release move lock if queued (deterministic release during physics frame)
	if _move_lock_release_queued:
		_move_lock_release_queued = false
		_release_move_lock()

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


func request_move(action: String) -> void:
	# Debug: log move attempts for flaky tests
	print_debug("DBG request_move, action=", action)
	# Prevent concurrent move requests from racing (tests may call rapidly)
	if _move_lock:
		print_debug("DBG request_move ignored: move_lock active")
		return
	_move_lock = true
	if _game_state.goal_controller.is_goal_reached():
		_release_move_lock()
		return
	var selected_idx : int= _game_state.unit_manager.get_selected_index()
	if not _game_state.turn_controller.can_act_on_index(selected_idx):
		_release_move_lock_deferred()
		return
	var current: Vector2i = _game_state.unit_manager.get_coord(selected_idx)
	var direction_map: Dictionary = _game_state.hex_navigator.get_direction_map(current, _grid)
	if not direction_map.has(action):
		_release_move_lock_deferred()
		return
	var next: Vector2i = current + direction_map[action]
	if not _is_within_bounds(next):
		_release_move_lock_deferred()
		return
	if _game_state.unit_manager.is_occupied(next, selected_idx):
		_release_move_lock_deferred()
		return
	_game_state.unit_controller.set_coord(selected_idx, next)

	_game_state.goal_controller.check_goal_progress()
	_game_state.turn_controller.complete_player_activation(selected_idx)

		# TEMP DEBUG: log authoritative player coord(s) for failing tests


	print_debug("DBG POST_MOVE player_coord=", _game_state.unit_manager.get_coord(0))
	# Release lock next frame so multiple immediate calls are ignored
	_release_move_lock_deferred()

func _is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < _grid_width and coord.y < _grid_height

func _release_move_lock_deferred() -> void:
	# Queue release for the next physics frame instead of deferring to idle.
	# This makes lock behavior deterministic for tests that advance physics.
	_move_lock_release_queued = true

func _release_move_lock() -> void:
	_move_lock = false

func _apply_level_if_available() -> void:
	if not _ensure_level_resource():
		return
	if not level_resource:
		return

	var result = _game_state.map_controller.load_level(level_resource, self, _game_state.unit_manager, _game_state.goal_manager, _camera, _controls, _player, [_goal, _goal2])
	_grid_width = result.grid_width
	_grid_height = result.grid_height
	_game_state.goal_controller.set_require_all_units(result.require_all_units)

	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func _ensure_level_resource() -> bool:
	if level_resource != null:
		return true
	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	if level_manager_instance == null:
		return false
	var path: String = level_manager_instance.get_current_level_path()
	if typeof(path) != TYPE_STRING or path.is_empty():
		return false
	var res: Resource = load(path)
	if res:
		level_resource = res
		return true
	return false

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

func complete_player_activation(unit_index: int) -> void:
	_game_state.turn_controller.complete_player_activation(unit_index)

func can_act_on_index(index: int) -> bool:
	return _game_state.turn_controller.can_act_on_index(index)

func _update_terrain_overlay() -> void:
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_terrain_overlay(_grid, _game_state.map_controller.get_terrain_map())

func is_turn_system_enabled() -> bool:
	return _game_state.turn_controller.is_enabled()

func is_interaction_allowed() -> bool:
	if _game_state.goal_controller.is_goal_reached() or _move_lock:
		return false
	return true

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
	set_process(false)
