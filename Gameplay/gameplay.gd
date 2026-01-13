class_name Gameplay
extends Node2D

signal level_complete
signal quit_to_title

const TITLE_SCENE_PATH := "res://Menus/title_screen.tscn"
const CREDITS_SCENE_PATH := "res://Menus/credits.tscn"

const GRID_WIDTH := 7
const GRID_HEIGHT := 7
const DIRECTIONS_EVEN := {
	"move_q": Vector2i(-1, -1),
	"move_w": Vector2i(0, -1),
	"move_e": Vector2i(1, -1),
	"move_a": Vector2i(-1, 0),
	"move_s": Vector2i(0, 1),
	"move_d": Vector2i(1, 0),
}

const DIRECTIONS_ODD := {
	"move_q": Vector2i(-1, 0),
	"move_w": Vector2i(0, -1),
	"move_e": Vector2i(1, 0),
	"move_a": Vector2i(-1, 1),
	"move_s": Vector2i(0, 1),
	"move_d": Vector2i(1, 1),
}

const DEFAULT_MOVE_ACTIONS := [
	{"action": "move_q", "keys": [KEY_Q], "joy_buttons": [JOY_BUTTON_DPAD_LEFT]},
	{"action": "move_w", "keys": [KEY_W], "joy_buttons": [JOY_BUTTON_DPAD_UP]},
	{"action": "move_e", "keys": [KEY_E], "joy_buttons": [JOY_BUTTON_DPAD_RIGHT]},
	{"action": "move_a", "keys": [KEY_A], "joy_buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	{"action": "move_s", "keys": [KEY_S], "joy_buttons": [JOY_BUTTON_DPAD_DOWN]},
	{"action": "move_d", "keys": [KEY_D], "joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
]

@onready var _grid: TileMapLayer = $Grid
@onready var _player: Sprite2D = $Player
@onready var _goal: Sprite2D = $Goal
@onready var _goal2: Sprite2D = $Goal2
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_handler: Node = $CameraHandler
@onready var _pause_handler: Node = $PauseHandler

const JOY_DEADZONE := 0.4
const JOY_REPEAT_DELAY := 0.2


var _analog_vectors_even: Dictionary = {}
var _analog_vectors_odd: Dictionary = {}
var _joy_axis := Vector2.ZERO
var _joy_repeat_timer := 0.0
var _goal_reached := false
var _controls: Node = null

var _players: Array[Sprite2D] = [] as Array[Sprite2D]
var _player_coords: Array[Vector2i] = [] as Array[Vector2i]
var _players_goal_reached: Array[bool] = [] as Array[bool]
var _units_player_controlled: Array[bool] = [] as Array[bool]
var _selected_index := 0
var _lmb_down := false
var _rmb_down := false
var _move_lock := false
var _move_lock_release_queued := false

var player_coord := Vector2i(0, 0)
var goal_coord := Vector2i(3, 3)
var _grid_width: int = GRID_WIDTH
var _grid_height: int = GRID_HEIGHT

@export var level_resource: Resource
var goal2_coord := Vector2i(4, 3)
var _goal_targets: Array[Vector2i] = [] as Array[Vector2i]

func _ready() -> void:
	_controls = get_tree().root.get_node_or_null("ControlSettings")
	if _controls == null:
		push_error("ControlSettings autoload not found in Gameplay.gd!")
		# Optionally, handle gracefully or disable features relying on it
		return

	if is_instance_valid(_pause_handler):
		_pause_handler.quit_requested.connect(func(): quit_to_title.emit())

	_goal_reached = false
	set_physics_process(true)
	set_process_unhandled_input(true)
	_register_input_actions()
	_apply_level_if_available()
	_build_grid()
	_cache_analog_vectors()
	# Initialize players
	_players.clear()
	_player_coords.clear()
	_players_goal_reached.clear()
	_units_player_controlled.clear()
	add_unit(_player, player_coord, true)
	_selected_index = 0
	_set_goal_coord(goal_coord)
	_set_goal2_coord(goal2_coord)
	_center_camera_on_selected()
	# Initialize camera snap base to nearest 60° and avoid drift
	if is_instance_valid(_camera_handler):
		_camera_handler.init_camera_snap()

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return

	# Release move lock if queued (deterministic release during physics frame)
	if _move_lock_release_queued:
		_move_lock_release_queued = false
		_release_move_lock()

	if _joy_repeat_timer > 0.0:
		_joy_repeat_timer = max(_joy_repeat_timer - delta, 0.0)

	var joy_strength := _joy_axis.length()
	if joy_strength >= JOY_DEADZONE and _joy_repeat_timer <= 0.0:
		var action := _action_from_joy_axis(_joy_axis)
		if action != "":
			request_move(action)
			_joy_repeat_timer = JOY_REPEAT_DELAY
	elif joy_strength < JOY_DEADZONE:
		_joy_repeat_timer = 0.0

func _unhandled_input(event: InputEvent) -> void:
	# Stop processing if paused
	if get_tree().paused:
		return

	# Camera handler processes input and may consume it
	if is_instance_valid(_camera_handler):
		_camera_handler.call("_unhandled_input", event)
		if get_viewport().is_input_handled():
			return

	if event is InputEventMouseButton:
		if _handle_mouse_button(event as InputEventMouseButton):
			return

	if _handle_selection_actions(event):
		return

	if _handle_move_actions(event):
		return

	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		if event.axis == JOY_AXIS_LEFT_X:
			_joy_axis.x = event.axis_value
		else:
			_joy_axis.y = event.axis_value
		if _joy_axis.length() < JOY_DEADZONE:
			_joy_axis = Vector2.ZERO

func set_joy_axis(axis: Vector2) -> void:
	_joy_axis = axis
	#reset joy_repeat_timer so it can work properly
	_joy_repeat_timer = 0.0

func _handle_mouse_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_lmb_down = event.pressed
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_rmb_down = event.pressed

	if _handle_mouse_wheel_input(event):
		return true

	if _handle_middle_mouse_button_click(event):
		return true

	if _handle_left_mouse_button_click(event):
		return true

	return false

func _handle_mouse_wheel_input(event: InputEventMouseButton) -> bool:
	if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var dir := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
		if _lmb_down:
			_cycle_selection(dir)
		else:
			# This is now handled by camera_handler, but we let it fall through
			# so we don't need to duplicate all the camera handler logic here.
			# The camera handler will consume the input if it uses it.
			pass
		var vp := get_viewport()
		if vp and vp.is_input_handled():
			return true
	return false

func _handle_middle_mouse_button_click(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		if is_instance_valid(_camera_handler):
			_camera_handler.call("free_cam_toggled")
			if not _camera_handler.get("free_cam"):
				_center_camera_on_selected()
		var vp_mid := get_viewport()
		if vp_mid:
			vp_mid.set_input_as_handled()
		return true
	return false

func _handle_left_mouse_button_click(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.double_click:
		if not is_instance_valid(_grid):
			return false
		var inv: Transform2D = _grid.get_global_transform_with_canvas().affine_inverse()
		var click_pos: Vector2 = inv * event.position
		var cell: Vector2i = _grid.local_to_map(click_pos)
		var idx := _index_of_player_at_cell(cell)
		if idx != -1:
			if _units_player_controlled[idx]:
				_selected_index = idx
				_center_camera_on_selected()
		else:
			var from: Vector2i = _player_coords[_selected_index]
			var dir_map := _direction_map(from)
			var diff: Vector2i = cell - from
			for action in dir_map.keys():
				if dir_map[action] == diff:
					request_move(action)
					break
		var vp_click := get_viewport()
		if vp_click:
			vp_click.set_input_as_handled()
		return true
	return false

func _handle_selection_actions(event: InputEvent) -> bool:
	if event.is_action_pressed("select_unit_1"):
		_selected_index = 0
		_center_camera_on_selected()
		var vp_sel := get_viewport()
		if vp_sel:
			vp_sel.set_input_as_handled()
		return true
	if event.is_action_pressed("select_next"):
		_cycle_selection(1)
		var vp_sel3 := get_viewport()
		if vp_sel3:
			vp_sel3.set_input_as_handled()
		return true
	if event.is_action_pressed("toggle_free_cam"):
		if is_instance_valid(_camera_handler):
			_camera_handler.call("free_cam_toggled")
			if not _camera_handler.get("free_cam"):
				_center_camera_on_selected()
		var vp_fc := get_viewport()
		if vp_fc:
			vp_fc.set_input_as_handled()
		return true
	return false

func _handle_move_actions(event: InputEvent) -> bool:
	var from_coord := _player_coords[_selected_index]
	var direction_map := _direction_map(from_coord)
	for action in direction_map.keys():
		if event.is_action_pressed(action):
			var mapped := _map_action_by_camera(action, from_coord)
			request_move(mapped)
			var viewport := get_viewport()
			if viewport:
				viewport.set_input_as_handled()
			return true
	return false


func request_move(action: String) -> void:
	# Debug: log move attempts for flaky tests
	##print_debug("DBG request_move goal_reached=", _goal_reached, " sel=", _selected_index, " action=", action)
	# Prevent concurrent move requests from racing (tests may call rapidly)
	if _move_lock:
		##print_debug("DBG request_move ignored: move_lock active")
		return
	_move_lock = true
	if _goal_reached:
		_release_move_lock()
		return
	var current: Vector2i = _player_coords[_selected_index]
	var direction_map := _direction_map(current)
	if not direction_map.has(action):
		_release_move_lock_deferred()
		return
	var next: Vector2i = current + direction_map[action]
	if not _is_within_bounds(next):
		_release_move_lock_deferred()
		return
	if _is_occupied(next, _selected_index):
		_release_move_lock_deferred()
		return
	_set_player_coord_at(_selected_index, next)

	update_goal_progress_for_selected()

		# TEMP DEBUG: log authoritative player coord(s) for failing tests


	#print_debug("DBG POST_MOVE player_coord=", player_coord, " _player_coords[0]=" , _player_coords[0])
	# Release lock next frame so multiple immediate calls are ignored
	_release_move_lock_deferred()

func _update_goal_progress_for_selected() -> void:
	var target: Vector2i = goal_coord
	if _selected_index < _goal_targets.size():
		target = _goal_targets[_selected_index]

	if _player_coords[_selected_index] != target:
		return
	_players_goal_reached[_selected_index] = true
	if _controls and _controls.require_all_units_to_goal:
		if _players_goal_reached.all(func(v): return v):
			_goal_reached = true
			_handle_goal_reached()
		return
	_goal_reached = true
	_handle_goal_reached()

func set_player_coord(coord: Vector2i) -> void:
	_set_player_coord_at(0, coord)

func set_goal_coord(coord: Vector2i) -> void:
	_set_goal_coord(coord)

func update_goal_progress_for_selected() -> void:
		_update_goal_progress_for_selected()


func _set_player_coord_at(index: int, coord: Vector2i) -> void:
	#print_debug("DBG _set_player_coord_at index=", index, " coord=", coord)
	_player_coords[index] = coord
	if index == 0:
		player_coord = coord
	var sprite := _players[index]
	sprite.position = _axial_to_pixel(coord)
	if index == _selected_index:
		_center_camera_on_selected()

func _set_goal_coord(coord: Vector2i) -> void:
	goal_coord = coord
	_goal.position = _axial_to_pixel(goal_coord)

func _set_goal2_coord(coord: Vector2i) -> void:
	goal2_coord = coord
	if is_instance_valid(_goal2):
		_goal2.position = _axial_to_pixel(goal2_coord)

func _is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < _grid_width and coord.y < _grid_height

func _is_occupied(coord: Vector2i, ignore_index: int = -1) -> bool:
	for i in _player_coords.size():
		if i == ignore_index:
			continue
		if _player_coords[i] == coord:
			return true
	return false

func _axial_to_pixel(coord: Vector2i) -> Vector2:
	return _grid.map_to_local(coord)

func _build_grid() -> void:
	_grid.clear()
	for q in _grid_width:
		for r in _grid_height:
			_grid.set_cell(Vector2i(q, r), 0, Vector2i.ZERO)

func _cache_analog_vectors() -> void:
	_analog_vectors_even.clear()
	_analog_vectors_odd.clear()
	var offset_axis := 0 # Default to column offset
	if is_instance_valid(_grid) and is_instance_valid(_grid.tile_set):
		offset_axis = _grid.tile_set.tile_offset_axis
	var cached := HexUtils.cache_analog_vectors(_grid, offset_axis, DIRECTIONS_EVEN, DIRECTIONS_ODD)
	_analog_vectors_even = cached["even"]
	_analog_vectors_odd = cached["odd"]

func _action_from_joy_axis(axis: Vector2) -> String:
	if axis == Vector2.ZERO:
		return ""
	var normalized := axis.normalized().rotated(_camera.rotation)
	var vectors := _analog_vectors_for(_player_coords[_selected_index])
	var action := HexUtils.closest_action(vectors, normalized, 0.10)
	# DEBUG: log analog mapping for tests
	#print_debug("DBG _action_from_joy_axis normalized=", normalized, " action=", action)
	if action == "":
		# Fallback to a permissive match to avoid missing near-threshold inputs
		action = HexUtils.closest_action(vectors, normalized, 0.0)
		#print_debug("DBG _action_from_joy_axis fallback action=", action)
	return action

func _map_action_by_camera(action: String, from_coord: Vector2i) -> String:
	var vectors := _analog_vectors_for(from_coord)
	if not vectors.has(action):
		return action
	var base_vec: Vector2 = vectors[action]
	var desired_world: Vector2 = base_vec.rotated(_camera.rotation)
	var best_action := action
	var best_dot := -1.0
	for a in vectors.keys():
		var dot := desired_world.dot(vectors[a])
		if dot > best_dot:
			best_dot = dot
			best_action = a
	return best_action

func _analog_vectors_for(coord: Vector2i) -> Dictionary:
	var offset_axis := 0
	if is_instance_valid(_grid) and is_instance_valid(_grid.tile_set):
		offset_axis = _grid.tile_set.tile_offset_axis
	return HexUtils.analog_vectors_for_x(coord.x, coord.y, offset_axis, _analog_vectors_even, _analog_vectors_odd)

func _direction_map(coord: Vector2i) -> Dictionary:
	var offset_axis := 0
	if is_instance_valid(_grid) and is_instance_valid(_grid.tile_set):
		offset_axis = _grid.tile_set.tile_offset_axis
	return HexUtils.direction_map_for_x(coord.x, coord.y, offset_axis, DIRECTIONS_EVEN, DIRECTIONS_ODD)

func _handle_goal_reached() -> void:
	if not _goal_reached:
		return
	_joy_axis = Vector2.ZERO
	_joy_repeat_timer = 0.0
	set_physics_process(false)
	set_process_unhandled_input(false)
	#print_debug("DBG gameplay goal reached emitting level_complete signal.")
	level_complete.emit()

func _register_input_actions() -> void:
	var input_mapper = get_tree().root.get_node_or_null("InputMapper")
	if input_mapper == null:
		push_error("InputMapper autoload not found in Gameplay.gd _register_input_actions!")
		return
	input_mapper.apply_configs(_movement_actions(), DEFAULT_MOVE_ACTIONS)
	if _controls and not _controls.camera_actions.is_empty():
		input_mapper.apply_configs(_controls.camera_actions)
	if _controls and not _controls.selection_actions.is_empty():
		input_mapper.apply_configs(_controls.selection_actions)
	if _controls and not _controls.pause_actions.is_empty():
		input_mapper.apply_configs(_controls.pause_actions)

func _movement_actions() -> Array:
	if _controls and not _controls.move_actions.is_empty():
		return _controls.move_actions
	return []

func _center_camera_on_selected() -> void:
	if is_instance_valid(_camera_handler):
		var pos := _players[_selected_index].position
		_camera_handler.call("center_on_position", pos)
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
	if level.grid_width > 0 and level.grid_height > 0:
		_grid_width = level.grid_width
		_grid_height = level.grid_height
	player_coord = level.player1_start
	goal_coord = level.goal_coord
	goal2_coord = level.goal2_coord

func _apply_level_options(level: Resource) -> void:
	if _controls:
		_controls.require_all_units_to_goal = level.require_all_units
	_camera.rotation = level.initial_camera_rotation
	if is_instance_valid(_grid.tile_set):
		var ts: TileSet = _grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = level.hex_offset_axis
			_grid.tile_set = dup
	_goal_targets = [goal_coord, goal2_coord]

func set_level_and_rebuild(level: Resource) -> void:
	level_resource = level
	_apply_level_if_available()
	# Reset goal progress when loading a level
	_goal_reached = false
	_players_goal_reached.fill(false)
	#print_debug("DBG set_level_and_rebuild _use_dual_goals=", _use_dual_goals, " _goal_targets=", _goal_targets, " _players_goal_reached=", _players_goal_reached)
	_build_grid()
	_cache_analog_vectors()
	if _players.size() > 0:
		_set_player_coord_at(0, player_coord)
	_set_goal_coord(goal_coord)
	_set_goal2_coord(goal2_coord)
	if is_instance_valid(_camera_handler):
		_camera_handler.init_camera_snap()
	_center_camera_on_selected()

func _index_of_player_at_cell(cell: Vector2i) -> int:
	for i in _player_coords.size():
		if _player_coords[i] == cell:
			return i
	return -1

func _cycle_selection(dir: int) -> void:
	var count := _players.size()
	if count <= 1:
		return

	var start := _selected_index
	var current := _selected_index

	for i in range(count):
		current = int((current + dir) % count)
		if current < 0:
			current = count - 1

		if _units_player_controlled[current]:
			_selected_index = current
			_center_camera_on_selected()
			return

		if current == start:
			break

func add_unit(sprite: Sprite2D, coord: Vector2i, is_player: bool) -> void:
	_players.append(sprite)
	_player_coords.append(coord)
	_players_goal_reached.append(false)
	_units_player_controlled.append(is_player)
	_set_player_coord_at(_players.size() - 1, coord)

func set_unit_controlled_by_player(index: int, is_player: bool) -> void:
	if index >= 0 and index < _units_player_controlled.size():
		_units_player_controlled[index] = is_player
		if index == _selected_index and not is_player:
			_cycle_selection(1)
