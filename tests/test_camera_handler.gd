extends "res://tests/test_utils.gd"

const CAMERA_HANDLER_SCRIPT = preload("res://Gameplay/camera_handler.gd")

var _handler: Node
var _camera: Camera2D

func before_test() -> void:
	# Set up a new handler and camera for each test to ensure isolation.
	_handler = CAMERA_HANDLER_SCRIPT.new()
	_camera = Camera2D.new()
	_handler.add_child(_camera)
	_handler.camera_node = _handler.get_path_to(_camera)
	# Add to scene tree so it can be processed.
	get_tree().root.add_child(_handler)
	await get_tree().process_frame

func after_test() -> void:
	if is_instance_valid(_handler):
		_handler.queue_free()
	# The camera is a child of the handler, so it's freed with its parent.
	await get_tree().process_frame

# --- Tests for Public Methods ---

func test_get_camera_rotation() -> void:
	var test_rotation := PI / 4 # 45 degrees
	_camera.rotation = test_rotation
	assert_that(_handler.get_camera_rotation()).is_equal_approx(test_rotation, 0.001)

func test_rotate_camera() -> void:
	var start_rot := _camera.rotation
	# rotate_camera now takes an integer step direction.
	_handler.rotate_camera(1) # Rotate one step (60 degrees)
	# The exact rotation depends on the initial snap, but it should not be the same.
	assert_that(_camera.rotation).is_not_equal(start_rot)


func test_zoom_method() -> void:
	var start_zoom := _camera.zoom.x
	# The new 'zoom' method takes an integer direction.
	_handler.zoom(1) # Zoom in
	assert_that(_camera.zoom.x > start_zoom).is_true()
	_handler.zoom(-1) # Zoom out
	assert_that(_camera.zoom.x).is_equal_approx(start_zoom, 0.001)

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
	_handler.set_free_cam(false) # Ensure free cam is off
	_handler.center_on_position(target_position)
	assert_that(_camera.position).is_equal(target_position)

func test_center_on_position_is_ignored_in_free_cam() -> void:
	var initial_pos := _camera.position
	var target_position := Vector2(100, 200)
	_handler.set_free_cam(true) # Ensure free cam is on
	_handler.center_on_position(target_position)
	assert_that(_camera.position).is_equal(initial_pos)

func test_init_camera_snap() -> void:
	# Set camera to a non-snapped rotation
	_camera.rotation = deg_to_rad(45) # Not a multiple of 60 degrees

	_handler.init_camera_snap()

	# After init_camera_snap, rotation should be snapped to nearest 60-degree multiple.
	# deg_to_rad(45) is closer to deg_to_rad(60) than 0.
	assert_that(rad_to_deg(_camera.rotation)).is_equal_approx(60.0, 0.001)

func test_handle_camera_input_callable() -> void:
	var start_rot := _camera.rotation
	var event := InputEventAction.new()
	event.action = "camera_rotate_left"
	event.pressed = true
	_handler.handle_camera_input(event)
	assert_that(_camera.rotation).is_not_equal(start_rot)
