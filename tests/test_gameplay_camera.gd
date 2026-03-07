extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",

}

var _control_settings: Node
var _input_mapper: Node
var _runner: GdUnitSceneRunner
var _scene: Node

func _action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = StringName(action)
	ev.pressed = true
	return ev

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]
	_input_mapper.apply_configs(_control_settings.camera_actions)

	_runner = _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_scene = _runner.scene()
	_scene.set_turn_system_enabled(false)
	var input_handler := _scene.get_node("InputHandler")
	var camera_handler := _scene.get_node("CameraHandler")
	if camera_handler and input_handler and not input_handler.camera_input_requested.is_connected(Callable(camera_handler, "handle_camera_input")):
		input_handler.camera_input_requested.connect(Callable(camera_handler, "handle_camera_input"))

	if _scene.has_method("_register_input_actions"):
		_scene.call("_register_input_actions")


	# The InputHandler was refactored to use a signal for camera input.
	# We must connect it here for all tests in this suite to work correctly.

	await _simulate_frames(_runner, 1)

	var scene_tree := _scene.get_tree()
	if scene_tree:
		scene_tree.paused = false
		assert_that(scene_tree.paused).is_false()

func after_test() -> void:
	_runner = null
	await teardown_autoloads()

func test_camera_is_current_on_ready() -> void:
	var handler := _scene.get_node("CameraHandler")
	assert_that(handler).is_not_null()
	var cam := handler.get_node(handler.camera_node) as Camera2D
	assert_that(cam).is_not_null()
	assert_that(cam.is_current()).is_true()

func test_camera_rotate_and_zoom_do_not_affect_movement() -> void:
	var handler := _scene.get_node("CameraHandler")
	assert_that(handler).is_not_null()
	var cam := handler.get_node(handler.camera_node) as Camera2D
	assert_that(cam).is_not_null()

	var level = _make_level([Vector2i(0, 0)], [Vector2i(5, 5)])
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	# Record starting state
	var start_rot: float = _scene.rotation
	var start_zoom := cam.zoom.x

	# Rotate left and right using actions
	_scene._input_handler._unhandled_input(_action_event("camera_rotate_left"))
	await _simulate_frames(_runner, 1)
	assert_that(_scene.rotation).is_not_equal(start_rot)
	assert_that(cam.rotation).is_equal(0.0) # Should stay zero due to ignore_rotation

	var rot_after_left: float = _scene.rotation
	_scene._input_handler._unhandled_input(_action_event("camera_rotate_right"))
	await _simulate_frames(_runner, 1)
	assert_that(_scene.rotation).is_not_equal(rot_after_left)

	# Zoom in then out using actions
	_scene._input_handler._unhandled_input(_action_event("camera_zoom_in"))
	await _simulate_frames(_runner, 1)
	assert_that(cam.zoom.x).is_not_equal(start_zoom)

	var zoom_after_in := cam.zoom.x
	_scene._input_handler._unhandled_input(_action_event("camera_zoom_out"))
	await _simulate_frames(_runner, 1)
	assert_that(cam.zoom.x).is_not_equal(zoom_after_in)

	# Ensure movement still functions as expected
	_scene._game_state.unit_manager.set_coord(0, Vector2i(1, 1))
	await _simulate_frames(_runner, 1)
	var start_coord: Vector2i = _scene._game_state.unit_manager.get_coord(0)

	# Pass correct screen coordinates by accounting for the camera's canvas transform
	var target_local: Vector2 = _scene._grid.map_to_local(Vector2i(2, 1))
	var target_global: Vector2 = _scene._grid.to_global(target_local)
	var target_screen: Vector2 = _scene.get_viewport().get_canvas_transform() * target_global

	_scene._game_state.input_controller._on_primary_action_at(target_screen)
	await _simulate_frames(_runner, 1)
	assert_that(_scene._game_state.unit_manager.get_coord(0)).is_not_equal(start_coord)

func _make_level(player_starts: Array[Vector2i], location_coords: Array[Vector2i]) -> Level:
	var level := Level.new()
	var starts: Array[Vector2i] = []
	starts.assign(player_starts)
	level.player_starts = starts
	for coord in location_coords:
		var entry := LevelTaskEntry.new()
		entry.coord = coord
		level.locations.append(entry)
	return level
