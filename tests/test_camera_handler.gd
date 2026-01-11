extends "res://tests/test_utils.gd"

const CAMERA_HANDLER_SCRIPT = preload("res://Gameplay/camera_handler.gd")

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
func test_handle_mouse_button_handles_zoom_and_free_cam() -> void:
	var handler = CAMERA_HANDLER_SCRIPT.new()
	var camera = Camera2D.new()
	handler.add_child(camera)
	handler.camera_node = handler.get_path_to(camera)
	# Must be in scene tree to process inputs
	get_tree().root.add_child(handler)
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_simulate_frames(runner, 1)

	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	var start_zoom: float = camera.zoom.x
	handler._unhandled_input(wheel)
	assert_that(camera.zoom.x).is_not_equal(start_zoom)

	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	handler._unhandled_input(middle)
	assert_that(handler.is_free_cam()).is_true()

	handler.queue_free()

func test_handle_camera_actions_rotates_and_zooms() -> void:
	var handler = CAMERA_HANDLER_SCRIPT.new()
	var camera = Camera2D.new()
	handler.add_child(camera)
	handler.camera_node = handler.get_path_to(camera)
	get_tree().root.add_child(handler)

	var rotate := InputEventAction.new()
	rotate.action = "camera_rotate_left"
	rotate.pressed = true
	var start_rot: float = camera.rotation
	handler._unhandled_input(rotate)
	assert_that(camera.rotation).is_not_equal(start_rot)

	var zoom := InputEventAction.new()
	zoom.action = "camera_zoom_in"
	zoom.pressed = true
	var before_zoom: float = camera.zoom.x
	handler._unhandled_input(zoom)
	assert_that(camera.zoom.x).is_not_equal(before_zoom)

	handler.queue_free()
