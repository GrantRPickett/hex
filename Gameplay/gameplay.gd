extends Node2D

signal level_complete(next_level_path: String)
signal quit_to_title

const TITLE_SCENE_PATH := "res://Menus/title_screen.tscn"
const CREDITS_SCENE_PATH := "res://Menus/credits.tscn"
const PAUSE_MENU_SCENE_PATH := "res://Menus/pause_menu.tscn"
const CONTROLS_MENU_SCENE_PATH := "res://Menus/controls_menu.tscn"

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
@onready var _player2: Sprite2D = $Player2
@onready var _goal: Sprite2D = $Goal
@onready var _goal2: Sprite2D = $Goal2
@onready var _camera: Camera2D = $Camera2D

const JOY_DEADZONE := 0.4
const JOY_REPEAT_DELAY := 0.2
const CAMERA_ROTATE_STEP := TAU / 6.0 # 60 degrees, aligns to hex grid
const CAMERA_ZOOM_STEP := 0.1
const CAMERA_ZOOM_MIN := 0.5
const CAMERA_ZOOM_MAX := 3.0

var _analog_vectors_even: Dictionary = {}
var _analog_vectors_odd: Dictionary = {}
var _joy_axis := Vector2.ZERO
var _joy_repeat_timer := 0.0
var _goal_reached := false
var _controls = ControlSettings

var _players: Array[Sprite2D] = [] as Array[Sprite2D]
var _player_coords: Array[Vector2i] = [] as Array[Vector2i]
var _players_goal_reached: Array[bool] = [] as Array[bool]
var _selected_index := 0
var _lmb_down := false
var _rmb_down := false
var _free_cam := false
var _camera_base_rotation: float = 0.0
var _camera_step_index: int = 0
var _paused := false
var _pause_menu: Control
var _controls_menu: Control
var _move_lock := false
var _move_lock_release_queued := false

var player_coord := Vector2i(0, 0)
var goal_coord := Vector2i(3, 3)
var player2_coord := Vector2i(0, 1)
var _grid_width: int = GRID_WIDTH
var _grid_height: int = GRID_HEIGHT

@export var level_resource: Resource
var goal2_coord := Vector2i(4, 3)
var _use_dual_goals := false
var _goal_targets: Array[Vector2i] = [] as Array[Vector2i]

func _ready() -> void:
	_goal_reached = false
	if is_instance_valid(_camera):
		_camera.make_current()
	set_physics_process(true)
	set_process_unhandled_input(true)
	_register_input_actions()
	_apply_level_if_available()
	_build_grid()
	_cache_analog_vectors()
	# Initialize players
	_players = [_player, _player2]
	_player_coords = [player_coord, player2_coord]
	_players_goal_reached = [false, false]
	_selected_index = 0
	_set_player_coord_at(0, _player_coords[0])
	_set_player_coord_at(1, _player_coords[1])
	_set_goal_coord(goal_coord)
	_set_goal2_coord(goal2_coord)
	_center_camera_on_selected()
	# Initialize camera snap base to nearest 60° and avoid drift
	_init_camera_snap()

func _physics_process(delta: float) -> void:
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
	if _handle_pause_input(event):
		return

	if _paused:
		return

	if event is InputEventMouseButton:
		if _handle_mouse_button(event as InputEventMouseButton):
			return

	if _handle_selection_actions(event):
		return

	if _handle_camera_actions(event):
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
			_joy_repeat_timer = 0.0

func _handle_pause_input(event: InputEvent) -> bool:
	if not event.is_action_pressed("pause_game"):
		return false
	if _paused:
		_hide_pause_menu()
	else:
		_show_pause_menu()
	var vp_pause := get_viewport()
	if vp_pause:
		vp_pause.set_input_as_handled()
	return true

func _handle_mouse_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_lmb_down = event.pressed
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_rmb_down = event.pressed

	if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var dir := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
		if _rmb_down:
			_camera_step_index += dir
			_apply_camera_rotation_from_step()
		elif _lmb_down:
			_cycle_selection(dir)
		else:
			var nz: float = clampf(_camera.zoom.x + float(dir) * CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
			_camera.zoom = Vector2(nz, nz)
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
		return true

	if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		_free_cam = not _free_cam
		if not _free_cam:
			_center_camera_on_selected()
		var vp_mid := get_viewport()
		if vp_mid:
			vp_mid.set_input_as_handled()
		return true

	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.double_click:
		if not is_instance_valid(_grid):
			return false
		var inv: Transform2D = _grid.get_global_transform_with_canvas().affine_inverse()
		var click_pos: Vector2 = inv * event.position
		var cell: Vector2i = _grid.local_to_map(click_pos)
		var idx := _index_of_player_at_cell(cell)
		if idx != -1:
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
	if event.is_action_pressed("select_unit_2"):
		_selected_index = 1
		_center_camera_on_selected()
		var vp_sel2 := get_viewport()
		if vp_sel2:
			vp_sel2.set_input_as_handled()
		return true
	if event.is_action_pressed("select_next"):
		_cycle_selection(1)
		var vp_sel3 := get_viewport()
		if vp_sel3:
			vp_sel3.set_input_as_handled()
		return true
	if event.is_action_pressed("toggle_free_cam"):
		_free_cam = not _free_cam
		if not _free_cam:
			_center_camera_on_selected()
		var vp_fc := get_viewport()
		if vp_fc:
			vp_fc.set_input_as_handled()
		return true
	return false

func _handle_camera_actions(event: InputEvent) -> bool:
	if event.is_action_pressed("camera_rotate_left"):
		_camera_step_index -= 1
		_apply_camera_rotation_from_step()
		var viewport := get_viewport()
		if viewport:
			viewport.set_input_as_handled()
		return true
	if event.is_action_pressed("camera_rotate_right"):
		_camera_step_index += 1
		_apply_camera_rotation_from_step()
		var viewport2 := get_viewport()
		if viewport2:
			viewport2.set_input_as_handled()
		return true
	if event.is_action_pressed("camera_zoom_in"):
		var nz: float = clampf(_camera.zoom.x + CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
		_camera.zoom = Vector2(nz, nz)
		var viewport3 := get_viewport()
		if viewport3:
			viewport3.set_input_as_handled()
		return true
	if event.is_action_pressed("camera_zoom_out"):
		var nz2: float = clampf(_camera.zoom.x - CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
		_camera.zoom = Vector2(nz2, nz2)
		var viewport4 := get_viewport()
		if viewport4:
			viewport4.set_input_as_handled()
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
	print_debug("DBG request_move goal_reached=", _goal_reached, " sel=", _selected_index, " action=", action)
	# Prevent concurrent move requests from racing (tests may call rapidly)
	if _move_lock:
		print_debug("DBG request_move ignored: move_lock active")
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
	_set_player_coord_at(_selected_index, next)
	_update_goal_progress_for_selected()
	# TEMP DEBUG: log authoritative player coord(s) for failing tests
	print_debug("DBG POST_MOVE player_coord=", player_coord, " _player_coords[0]=" , _player_coords[0])
	# Release lock next frame so multiple immediate calls are ignored
	_release_move_lock_deferred()

func _update_goal_progress_for_selected() -> void:
	if _use_dual_goals:
		var target := _goal_targets[_selected_index]
		if _player_coords[_selected_index] == target:
			# Debug: log players_goal_reached before and after change
			print_debug("DBG goals before=", _players_goal_reached)
			_players_goal_reached[_selected_index] = true
			print_debug("DBG goals after=", _players_goal_reached)
			var all_done := _players_goal_reached.all(func(v): return v)
			print_debug("DBG goals all_done=", all_done)
			if all_done:
				_goal_reached = true
				_handle_goal_reached()
		return

	if _player_coords[_selected_index] != goal_coord:
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

func _set_player_coord_at(index: int, coord: Vector2i) -> void:
	print_debug("DBG _set_player_coord_at index=", index, " coord=", coord)
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
	var cached := HexUtils.cache_analog_vectors(_grid, DIRECTIONS_EVEN, DIRECTIONS_ODD)
	_analog_vectors_even = cached["even"]
	_analog_vectors_odd = cached["odd"]

func _action_from_joy_axis(axis: Vector2) -> String:
	if axis == Vector2.ZERO:
		return ""
	var normalized := axis.normalized().rotated(_camera.rotation)
	var vectors := _analog_vectors_for(_player_coords[_selected_index])
	var action := HexUtils.closest_action(vectors, normalized, 0.10)
	# DEBUG: log analog mapping for tests
	print_debug("DBG _action_from_joy_axis normalized=", normalized, " action=", action)
	if action == "":
		# Fallback to a permissive match to avoid missing near-threshold inputs
		action = HexUtils.closest_action(vectors, normalized, 0.0)
		print_debug("DBG _action_from_joy_axis fallback action=", action)
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
	return HexUtils.analog_vectors_for_x(coord.x, _analog_vectors_even, _analog_vectors_odd)

func _direction_map(coord: Vector2i) -> Dictionary:
	return HexUtils.direction_map_for_x(coord.x, DIRECTIONS_EVEN, DIRECTIONS_ODD)

func _handle_goal_reached() -> void:
	if not _goal_reached:
		return
	_joy_axis = Vector2.ZERO
	_joy_repeat_timer = 0.0
	set_physics_process(false)
	set_process_unhandled_input(false)
	var next_path := ""
	if level_resource and level_resource.has_method("get"):
		next_path = String(level_resource.get("next_level_path")).strip_edges()
	print_debug("DBG gameplay goal reached emitting next_path=", next_path)
	level_complete.emit(next_path)

func _register_input_actions() -> void:
	InputMapper.apply_configs(_movement_actions(), DEFAULT_MOVE_ACTIONS)
	if _controls and not _controls.camera_actions.is_empty():
		InputMapper.apply_configs(_controls.camera_actions)
	if _controls and not _controls.selection_actions.is_empty():
		InputMapper.apply_configs(_controls.selection_actions)
	if _controls and not _controls.pause_actions.is_empty():
		InputMapper.apply_configs(_controls.pause_actions)

func _movement_actions() -> Array:
	if _controls and not _controls.move_actions.is_empty():
		return _controls.move_actions
	return []

func _center_camera_on_selected() -> void:
	if _free_cam:
		return
	var pos := _players[_selected_index].position
	# Normalize to integral pixel grid to make tests deterministic
	_camera.position = Vector2(round(pos.x), round(pos.y))
	_camera.make_current()
	# Ensure a frame can settle if callers expect immediate camera position
	# (kept synchronous to avoid breaking tests that assert immediately)
	return

func _release_move_lock_deferred() -> void:
	# Queue release for the next physics frame instead of deferring to idle.
	# This makes lock behavior deterministic for tests that advance physics.
	_move_lock_release_queued = true

func _release_move_lock() -> void:
	_move_lock = false

func _apply_camera_rotation_from_step() -> void:
	var step := int((_camera_step_index % 6 + 6) % 6)
	_camera.rotation = _camera_base_rotation + float(step) * CAMERA_ROTATE_STEP

func _init_camera_snap() -> void:
	# Snap current rotation to nearest 60° and set as base
	var n: int = int(round(_camera.rotation / CAMERA_ROTATE_STEP))
	_camera_step_index = 0
	_camera_base_rotation = float(n) * CAMERA_ROTATE_STEP
	_apply_camera_rotation_from_step()

func _apply_level_if_available() -> void:
	if not _ensure_level_resource():
		return
	if not level_resource or not level_resource.has_method("get"):
		return
	_apply_level_dimensions_and_positions(level_resource)
	_apply_level_options(level_resource)

func _ensure_level_resource() -> bool:
	if level_resource != null:
		return true
	if not Engine.has_singleton("LevelManager"):
		return false
	var path: String = LevelManager.get_current_level_path() if LevelManager.has_method("get_current_level_path") else ""
	if typeof(path) != TYPE_STRING or path == "":
		return false
	var res := load(path)
	if res:
		level_resource = res
		return true
	return false

func _apply_level_dimensions_and_positions(level: Resource) -> void:
	var w: int = int(level.get("grid_width"))
	var h: int = int(level.get("grid_height"))
	if w > 0 and h > 0:
		_grid_width = w
		_grid_height = h
	var p1: Variant = level.get("player1_start")
	var p2: Variant = level.get("player2_start")
	var goal: Variant = level.get("goal_coord")
	var goal_b: Variant = level.get("goal2_coord")
	if p1 is Vector2i:
		player_coord = p1
	if p2 is Vector2i:
		player2_coord = p2
	if goal is Vector2i:
		goal_coord = goal
	if goal_b is Vector2i:
		goal2_coord = goal_b

func _apply_level_options(level: Resource) -> void:
	var req_all: Variant = level.get("require_all_units")
	if typeof(req_all) == TYPE_BOOL and _controls:
		_controls.require_all_units_to_goal = bool(req_all)
	var cam_rot_val: Variant = level.get("initial_camera_rotation")
	if typeof(cam_rot_val) == TYPE_FLOAT or typeof(cam_rot_val) == TYPE_INT:
		_camera.rotation = float(cam_rot_val)
	var axis: Variant = level.get("hex_offset_axis")
	if typeof(axis) == TYPE_INT and is_instance_valid(_grid.tile_set):
		var ts: TileSet = _grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = int(axis)
			_grid.tile_set = dup
	var require_match: Variant = level.get("require_units_match_goals")
	_use_dual_goals = typeof(require_match) == TYPE_BOOL and bool(require_match)
	_goal_targets = [goal_coord, goal2_coord]

func set_level_and_rebuild(level: Resource) -> void:
	level_resource = level
	_apply_level_if_available()
	# Reset goal progress when loading a level
	_goal_reached = false
	_players_goal_reached = [false, false]
	print_debug("DBG set_level_and_rebuild _use_dual_goals=", _use_dual_goals, " _goal_targets=", _goal_targets, " _players_goal_reached=", _players_goal_reached)
	_build_grid()
	_cache_analog_vectors()
	_set_player_coord_at(0, player_coord)
	_set_player_coord_at(1, player2_coord)
	_set_goal_coord(goal_coord)
	_set_goal2_coord(goal2_coord)
	_init_camera_snap()
	_center_camera_on_selected()

func set_player2_coord(coord: Vector2i) -> void:
	_set_player_coord_at(1, coord)

func _show_pause_menu() -> void:
	if _paused:
		return
	_paused = true
	var packed: PackedScene = load(PAUSE_MENU_SCENE_PATH)
	_pause_menu = packed.instantiate() as Control
	_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.controls_requested.connect(_on_pause_controls)
	_pause_menu.quit_requested.connect(_on_pause_quit)
	get_tree().paused = true

func _hide_pause_menu() -> void:
	if not _paused:
		return
	if is_instance_valid(_controls_menu):
		_controls_menu.queue_free()
		_controls_menu = null
	if is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
		_pause_menu = null
	_paused = false
	get_tree().paused = false

func _on_pause_resume() -> void:
	_hide_pause_menu()

func _on_pause_controls() -> void:
	if not is_instance_valid(_pause_menu):
		return
	if is_instance_valid(_controls_menu):
		_controls_menu.queue_free()
	var packed: PackedScene = load(CONTROLS_MENU_SCENE_PATH)
	_controls_menu = packed.instantiate() as Control
	_controls_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_controls_menu)
	_controls_menu.back_requested.connect(_on_controls_back)

func _on_controls_back() -> void:
	if is_instance_valid(_controls_menu):
		_controls_menu.queue_free()
		_controls_menu = null

func _on_pause_quit() -> void:
	_hide_pause_menu()
	quit_to_title.emit()

func _index_of_player_at_cell(cell: Vector2i) -> int:
	for i in _player_coords.size():
		if _player_coords[i] == cell:
			return i
	return -1

func _cycle_selection(dir: int) -> void:
	var count := _players.size()
	if count <= 1:
		return
	_selected_index = int((_selected_index + dir) % count)
	if _selected_index < 0:
		_selected_index = count - 1
	_center_camera_on_selected()
