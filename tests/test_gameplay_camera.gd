extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LevelScript := preload("res://Resources/Level.gd")

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
	var start_rot := cam.rotation
	var start_zoom := cam.zoom.x

	# Rotate left and right using actions
	_scene._input_handler._unhandled_input(_action_event("camera_rotate_left"))
	await _simulate_frames(_runner, 1)
	assert_that(cam.rotation).is_not_equal(start_rot)

	var rot_after_left := cam.rotation
	_scene._input_handler._unhandled_input(_action_event("camera_rotate_right"))
	await _simulate_frames(_runner, 1)
	assert_that(cam.rotation).is_not_equal(rot_after_left)

	# Zoom in then out using actions
	_scene._input_handler._unhandled_input(_action_event("camera_zoom_in"))
	await _simulate_frames(_runner, 1)
	assert_that(cam.zoom.x).is_not_equal(start_zoom)

	var zoom_after_in := cam.zoom.x
	_scene._input_handler._unhandled_input(_action_event("camera_zoom_out"))
	await _simulate_frames(_runner, 1)
	assert_that(cam.zoom.x).is_not_equal(zoom_after_in)

	# Ensure movement still functions as expected
	_scene.set_player_coord(Vector2i(1, 1))
	await _simulate_frames(_runner, 1)
	var start_coord: Vector2i = _scene.player_coord
	_scene.request_move("move_w")
	await _simulate_frames(_runner, 1)
	assert_that(_scene.player_coord).is_not_equal(start_coord)

func _make_level(player_starts: Array[Vector2i], goal_coords: Array[Vector2i]) -> Level:
	var level := LevelScript.new()
	var starts: Array[Vector2i] = []
	starts.assign(player_starts)
	level.player_starts = starts
	var goals: Array[Vector2i] = []
	goals.assign(goal_coords)
	level.goal_coords = goals
	return level
