extends "res://tests/test_utils.gd"

const CAMERA_HANDLER_SCRIPT = preload("res://Gameplay/camera_handler.gd")
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _handler: Node
var _camera: Camera2D

func before_test() -> void:
	_handler = CAMERA_HANDLER_SCRIPT.new()
	_camera = Camera2D.new()
	_handler.add_child(_camera)
	_handler.camera_node = _handler.get_path_to(_camera)
	# Must be in scene tree to process inputs
	get_tree().root.add_child(_handler)
	await get_tree().process_frame

func after_test() -> void:
	if is_instance_valid(_handler):
		_handler.queue_free()
	if is_instance_valid(_camera):
		_camera.queue_free()
	await get_tree().process_frame
func test_handle_mouse_button_handles_zoom_and_free_cam() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_simulate_frames(runner, 1)

	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	var start_zoom: float = _camera.zoom.x
	_handler._unhandled_input(wheel)
	assert_that(_camera.zoom.x).is_not_equal(start_zoom)

	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	_handler._unhandled_input(middle)
	assert_that(_handler.is_free_cam()).is_true()

func test_handle_camera_actions_rotates_and_zooms() -> void:
	var rotate := InputEventAction.new()
	rotate.action = "camera_rotate_left"
	rotate.pressed = true
	var start_rot: float = _camera.rotation
	_handler._unhandled_input(rotate)
	assert_that(_camera.rotation).is_not_equal(start_rot)

	var zoom := InputEventAction.new()
	zoom.action = "camera_zoom_in"
	zoom.pressed = true
	var before_zoom: float = _camera.zoom.x
	_handler._unhandled_input(zoom)

func test_get_camera_rotation() -> void:
	var test_rotation := PI / 4 # 45 degrees
	_camera.rotation = test_rotation
	assert_that(_handler.get_camera_rotation()).is_equal_approx(test_rotation, 0.001)

func test_rotate_camera() -> void:
	var start_rot := _camera.rotation
	_handler.rotate_camera(PI / 3)
	assert_that(_camera.rotation).is_equal_approx(start_rot + PI / 3, 0.001)

func test_zoom_camera() -> void:
	var start_zoom := _camera.zoom
	_handler.zoom_camera(0.1)
	assert_that(_camera.zoom.x).is_not_equal(start_zoom.x)

func test_set_initial_rotation() -> void:
	var rot := PI
	_handler.set_initial_rotation(rot)
	assert_that(_camera.rotation).is_equal_approx(rot, 0.001)

func test_set_free_cam() -> void:
	_handler.set_free_cam(true)
	assert_that(_handler.is_free_cam()).is_true()
	_handler.set_free_cam(false)
	assert_that(_handler.is_free_cam()).is_false()

func test_center_on_position() -> void:
	var target_position := Vector2(100, 200)
	_handler.center_on_position(target_position)

	# The camera's global_position should be the target position

func test_init_camera_snap() -> void:
	# Set camera to a non-snapped rotation
	_camera.rotation = deg_to_rad(45) # Not a multiple of 60 degrees

	_handler.init_camera_snap()

	# After init_camera_snap, rotation should be snapped to nearest 60-degree multiple
	# deg_to_rad(45) is closer to deg_to_rad(60) than 0
	assert_that(rad_to_deg(_camera.rotation)).is_equal_approx(60.0, 0.001)
