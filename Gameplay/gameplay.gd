extends Node2D

signal level_complete
signal quit_to_title

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

var _goal_reached := false
var _controls: Node = null
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _hex_navigator: HexNavigator

var _move_lock := false
var _move_lock_release_queued := false

var _grid_width: int = GRID_WIDTH
var _grid_height: int = GRID_HEIGHT
var _require_all_units := false

@export var level_resource: Resource

func _ready() -> void:
	_controls = get_tree().root.get_node_or_null("ControlSettings")
	if _controls == null:
		push_warning("ControlSettings autoload not found in Gameplay.gd!")

	_unit_manager = UnitManager.new()
	add_child(_unit_manager)
	_goal_manager = GoalManager.new()
	add_child(_goal_manager)
	_hex_navigator = HexNavigator.new()
	add_child(_hex_navigator)

	_input_handler.move_requested.connect(_on_move_requested)
	_input_handler.selection_cycle_requested.connect(_on_selection_cycle_requested)
	_input_handler.select_index_requested.connect(_on_select_index_requested)
	_input_handler.primary_action_at.connect(_on_primary_action_at)
	_input_handler.free_cam_toggle_requested.connect(_on_free_cam_toggle_requested)
	_input_handler.joy_axis_held.connect(_on_joy_axis_held)
	_input_handler.zoom_requested.connect(_on_zoom_requested)
	if is_instance_valid(_camera_handler):
		_input_handler.camera_input_requested.connect(Callable(_camera_handler, "handle_camera_input"))

	_unit_manager.unit_moved.connect(_on_unit_moved)
	_unit_manager.selection_changed.connect(_on_selection_changed)

	if is_instance_valid(_pause_handler):
		_pause_handler.quit_requested.connect(_on_quit_requested)

	_goal_reached = false
	set_physics_process(true)
	_register_input_actions()
	if is_instance_valid(_input_handler):
		_input_handler.refresh_action_cache()
	_apply_level_if_available()

	if _grid.tile_set == null:
		var new_ts = TileSet.new()
		new_ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
		new_ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		new_ts.tile_size = Vector2i(64, 64)
		_grid.tile_set = new_ts
	elif _grid.tile_set.tile_shape != TileSet.TILE_SHAPE_HEXAGON:
		var new_ts = _grid.tile_set.duplicate(true)
		new_ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
		new_ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
		if new_ts.tile_size == Vector2i.ZERO:
			new_ts.tile_size = Vector2i(64, 64)
		_grid.tile_set = new_ts

	_build_grid()
	_hex_navigator.cache_analog_vectors(_grid)

	_center_camera_on_selected()
	# Initialize camera snap base to nearest 60° and avoid drift
	if is_instance_valid(_camera_handler):
		_camera_handler.init_camera_snap()

func _physics_process(_delta: float) -> void:
	# Release move lock if queued (deterministic release during physics frame)
	if _move_lock_release_queued:
		_move_lock_release_queued = false
		_release_move_lock()


func set_joy_axis(axis: Vector2) -> void:
	# Legacy support for tests if they call this directly
	if _input_handler:
		_input_handler._joy_axis = axis
		_input_handler._joy_repeat_timer = 0.0

func _on_move_requested(action: String) -> void:
	print_debug("DBG _on_move_requested action=", action)
	var from_coord := _unit_manager.get_selected_coord()
	var mapped: String = _hex_navigator.map_action_by_camera(action, from_coord, _camera.rotation, _grid)
	request_move(mapped)

func _on_selection_cycle_requested(direction: int) -> void:
	_unit_manager.cycle_selection(direction)

func _on_select_index_requested(index: int) -> void:
	print_debug("DBG _on_select_index_requested index=", index)
	_unit_manager.select_index(index)

func _on_free_cam_toggle_requested() -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.call("set_free_cam", not _camera_handler.call("is_free_cam"))
		if not _camera_handler.get("free_cam"):
			_center_camera_on_selected()

func _on_zoom_requested(direction: int) -> void:
	if is_instance_valid(_camera_handler):
		# We let the camera handler determine the zoom amount from the direction.
		_camera_handler.zoom(direction)

func _on_joy_axis_held(axis: Vector2, _delta: float) -> void:
	var action :String= _hex_navigator.get_action_from_joy_axis(axis, _camera.rotation, _unit_manager.get_selected_coord(), _grid)
	if action != "":
		request_move(action)

func _on_primary_action_at(screen_pos: Vector2) -> void:
	print_debug("DBG _on_primary_action_at screen_pos=", screen_pos)
	# Convert screen position to grid cell.
	var cell: Vector2i = _grid.local_to_map(_grid.to_local(screen_pos))

	# Now perform the logic that used to be in _on_cell_clicked.
	var idx := _unit_manager.index_of_unit_at(cell)
	if idx != -1:
		if _unit_manager.is_player_controlled(idx):
			_unit_manager.select_index(idx)
	else:
		var from: Vector2i = _unit_manager.get_selected_coord()
		var dir_map :Dictionary= _hex_navigator.get_direction_map(from, _grid)
		var diff: Vector2i = cell - from
		for action in dir_map.keys():
			if dir_map[action] == diff:
				request_move(action)
				break

func _on_unit_moved(index: int, coord: Vector2i) -> void:
	var sprite := _unit_manager.get_unit_sprite(index)
	if sprite:
		sprite.position = _axial_to_pixel(coord)
	if index == _unit_manager.get_selected_index():
		_center_camera_on_selected()

func _on_selection_changed(_index: int) -> void:
	_center_camera_on_selected()



func request_move(action: String) -> void:
	# Debug: log move attempts for flaky tests
	print_debug("DBG request_move, action=", action)
	# Prevent concurrent move requests from racing (tests may call rapidly)
	if _move_lock:
		print_debug("DBG request_move ignored: move_lock active")
		return
	_move_lock = true
	if _goal_reached:
		_release_move_lock()
		return
	var selected_idx := _unit_manager.get_selected_index()
	var current: Vector2i = _unit_manager.get_coord(selected_idx)
	var direction_map: Dictionary = _hex_navigator.get_direction_map(current, _grid)
	if not direction_map.has(action):
		_release_move_lock_deferred()
		return
	var next: Vector2i = current + direction_map[action]
	if not _is_within_bounds(next):
		_release_move_lock_deferred()
		return
	if _unit_manager.is_occupied(next, selected_idx):
		_release_move_lock_deferred()
		return
	_set_player_coord_at(selected_idx, next)

	update_goal_progress_for_selected()

		# TEMP DEBUG: log authoritative player coord(s) for failing tests


	print_debug("DBG POST_MOVE player_coord=", _unit_manager.get_coord(0))
	# Release lock next frame so multiple immediate calls are ignored
	_release_move_lock_deferred()

func _update_goal_progress_for_selected() -> void:
	if _goal_reached:
		return
	var idx := _unit_manager.get_selected_index()
	var target: Vector2i = _goal_manager.get_target(idx)

	if _unit_manager.get_coord(idx) != target:
		return
	_unit_manager.set_goal_reached(idx, true)
	if _require_all_units:
		if _unit_manager.are_all_goals_reached():
			_goal_reached = true
			_handle_goal_reached()
		return
	_goal_reached = true
	_handle_goal_reached()


func _set_player_coord_at(index: int, coord: Vector2i) -> void:
	print_debug("DBG _set_player_coord_at index=", index, " coord=", coord)
	_unit_manager.set_coord(index, coord)

func _is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < _grid_width and coord.y < _grid_height


func _axial_to_pixel(coord: Vector2i) -> Vector2:
	return _grid.map_to_local(coord)

func _build_grid() -> void:
	_grid.clear()
	for q in _grid_width:
		for r in _grid_height:
			_grid.set_cell(Vector2i(q, r), 0, Vector2i.ZERO)

func _handle_goal_reached() -> void:
	if not _goal_reached:
		return
	_disable_gameplay()
	#print_debug("DBG gameplay goal reached emitting level_complete signal.")
	level_complete.emit()

func _on_quit_requested() -> void:
	_disable_gameplay()
	quit_to_title.emit()

func _disable_gameplay() -> void:
	_input_handler.reset_joy_state()
	set_physics_process(false)
	_input_handler.set_process_unhandled_input(false)

func _register_input_actions() -> void:
	var input_mapper = get_tree().root.get_node_or_null("InputMapper")
	if input_mapper == null:
		push_warning("InputMapper autoload not found in Gameplay.gd _register_input_actions!")
		return
	input_mapper.apply_configs(_movement_actions(), InputActions.MOVEMENT_DEFAULTS)
	var interaction_configs: Array = []
	if _controls and not _controls.interaction_actions.is_empty():
		interaction_configs = _controls.interaction_actions
	input_mapper.apply_configs(interaction_configs, InputActions.INTERACTION_DEFAULTS)
	var camera_configs: Array = []
	if _controls and not _controls.camera_actions.is_empty():
		camera_configs = _controls.camera_actions
	input_mapper.apply_configs(camera_configs, InputActions.CAMERA_DEFAULTS)
	var selection_configs: Array = []
	if _controls and not _controls.selection_actions.is_empty():
		selection_configs = _controls.selection_actions
	input_mapper.apply_configs(selection_configs, InputActions.SELECTION_DEFAULTS)
	var pause_configs: Array = []
	if _controls and not _controls.pause_actions.is_empty():
		pause_configs = _controls.pause_actions
	input_mapper.apply_configs(pause_configs, InputActions.PAUSE_DEFAULTS)

func _movement_actions() -> Array:
	print_debug("DBG _movement_actions fetching from _controls")
	if _controls and not _controls.move_actions.is_empty():
		print_debug("DBG _movement_actions returning from _controls")
		return _controls.move_actions
	return []

func _center_camera_on_selected() -> void:
	if is_instance_valid(_camera_handler):
		var sprite := _unit_manager.get_selected_sprite()
		if sprite:
			_camera_handler.call("center_on_position", sprite.position)
	# Ensure a frame can settle if callers expect immediate camera position
	# (kept synchronous to avoid breaking tests that assert immediately)
	return

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
	_apply_level_dimensions_and_positions(level_resource)
	_apply_level_options(level_resource)
	_setup_units_and_goals(level_resource)

func _ensure_level_resource() -> bool:
	if level_resource != null:
		return true
	var level_manager_instance = get_tree().root.get_node_or_null("LevelManager")
	if level_manager_instance == null:
		return false
	var path: String = level_manager_instance._current_level_path
	if typeof(path) != TYPE_STRING or path.is_empty():
		return false
	var res: Resource = load(path)
	if res:
		level_resource = res
		return true
	return false

func _apply_level_dimensions_and_positions(level: Resource) -> void:
	var data = LevelLoader.load_level_data(level)
	_grid_width = data.grid_width
	_grid_height = data.grid_height

func _setup_units_and_goals(level: Resource) -> void:
	var data = LevelLoader.load_level_data(level)
	_unit_manager.reset()

	# Setup Units
	for i in range(data.player_starts.size()):
		var coord = data.player_starts[i]
		var sprite: Sprite2D
		if i == 0:
			sprite = _player
		else:
			sprite = _player.duplicate()
			add_child(sprite)

		_unit_manager.add_unit(sprite, coord, true)
		_set_player_coord_at(i, coord)

	# Setup Enemies
	if "enemy_starts" in data:
		for coord in data.enemy_starts:
			var sprite = _player.duplicate()
			sprite.modulate = Color.TOMATO
			add_child(sprite)
			_unit_manager.add_unit(sprite, coord, false)

	# Setup Goals
	var goals: Array[Vector2i] = []
	goals.assign(data.goal_coords)
	_goal_manager.setup(goals, [_goal, _goal2], _grid)

func _apply_level_options(level: Resource) -> void:
	var data = LevelLoader.load_level_data(level)
	_require_all_units = data.require_all_units
	if _controls:
		_controls.require_all_units_to_goal = data.require_all_units
	_camera.rotation = data.initial_rotation
	if is_instance_valid(_grid.tile_set):
		var ts: TileSet = _grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = data.hex_offset_axis
			_grid.tile_set = dup

func set_level_and_rebuild(level: Resource) -> void:
	level_resource = level
	_apply_level_if_available()
	# Reset goal progress when loading a level
	_goal_reached = false
	_build_grid()
	_hex_navigator.cache_analog_vectors(_grid)

	if is_instance_valid(_camera_handler):
		_camera_handler.init_camera_snap()
	_center_camera_on_selected()

func add_unit(sprite: Sprite2D, coord: Vector2i, is_player: bool) -> void:
	_unit_manager.add_unit(sprite, coord, is_player)
	_set_player_coord_at(_unit_manager.get_unit_count() - 1, coord)

func set_unit_controlled_by_player(index: int, is_player: bool) -> void:
	_unit_manager.set_player_controlled(index, is_player)
	if index == _unit_manager.get_selected_index() and not is_player:
		_unit_manager.cycle_selection(1)

# Legacy helpers for tests
var player_coord: Vector2i:
	get: return _unit_manager.get_coord(0)
var goal_coord: Vector2i:
	get: return _goal_manager.get_target(0)
var goal2_coord: Vector2i:
	get: return _goal_manager.get_target(1)

func set_player_coord(coord: Vector2i) -> void:
	_set_player_coord_at(0, coord)

func set_goal_coord(coord: Vector2i) -> void:
	_goal_manager.set_target(0, coord)

func update_goal_progress_for_selected() -> void:
	_update_goal_progress_for_selected()
