extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

class UnitTestLevel extends Resource:
	var player_starts: Array[Vector2i] = []
	var goal_coords: Array[Vector2i] = []
	var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
	var require_all_units: bool = false
	var initial_rotation: float = 0.0
	var grid_width: int = 7
	var grid_height: int = 7

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
	
}

var _control_settings: Node
var _input_mapper: Node
var _runner: GdUnitSceneRunner
var _scene: Node

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]
	_input_mapper.apply_configs(_control_settings.camera_actions)

	_runner = _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_scene = _runner.scene()
	var input_handler := _scene.get_node("InputHandler")
	var camera_handler := _scene.get_node("CameraHandler")
	if camera_handler and input_handler and not input_handler.camera_input_requested.is_connected(Callable(camera_handler, "handle_camera_input")):
		input_handler.camera_input_requested.connect(Callable(camera_handler, "handle_camera_input"))

	if _scene.has_method("_register_input_actions"):
		_scene.call("_register_input_actions")


	# The InputHandler was refactored to use a signal for camera input.
	# We must connect it here for all tests in this suite to work correctly.

	await _simulate_frames(_runner, 1)

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

	var level = UnitTestLevel.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(5, 5)] as Array[Vector2i]
	_scene.set_level_and_rebuild(level)
	await _simulate_frames(_runner, 1)

	# Record starting state
	var start_rot := cam.rotation
	var start_zoom := cam.zoom.x

	# Rotate left and right using actions
	_runner.simulate_action_pressed("camera_rotate_left")
	await _simulate_frames(_runner, 1)
	assert_that(cam.rotation).is_not_equal(start_rot)

	var rot_after_left := cam.rotation
	_runner.simulate_action_pressed("camera_rotate_right")
	await _simulate_frames(_runner, 1)
	assert_that(cam.rotation).is_not_equal(rot_after_left)

	# Zoom in then out using actions
	_runner.simulate_action_pressed("camera_zoom_in")
	await _simulate_frames(_runner, 1)
	assert_that(cam.zoom.x).is_not_equal(start_zoom)

	var zoom_after_in := cam.zoom.x
	_runner.simulate_action_pressed("camera_zoom_out")
	await _simulate_frames(_runner, 1)
	assert_that(cam.zoom.x).is_not_equal(zoom_after_in)

	# Ensure movement still functions as expected
	_scene.set_player_coord(Vector2i(1, 1))
	await _simulate_frames(_runner, 1)
	var start_coord: Vector2i = _scene.player_coord
	_scene.request_move("move_w")
	await _simulate_frames(_runner, 1)
	assert_that(_scene.player_coord).is_not_equal(start_coord)
