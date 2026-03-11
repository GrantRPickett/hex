extends GdUnitTestSuite

# FORCE_IMPORT_TIMESTAMP: 2026-03-11 16:20:00

const CAMERA_HANDLER_SCRIPT = preload("res://Gameplay/camera_handler.gd")

var _handler: Node
var _camera: Camera2D
var _game_root: Node2D

func before_test() -> void:
	# Set up a new handler and camera for each test to ensure isolation.
	_handler = CAMERA_HANDLER_SCRIPT.new()
	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	_game_root = Node2D.new()
	_game_root.name = "GameRoot"

	_handler.add_child(_camera)
	_handler.camera_node = _handler.get_path_to(_camera)

	# Add to scene tree so it can be processed.
	var root = get_tree().root
	if not _game_root.is_inside_tree():
		root.add_child(_game_root)
	if not _handler.is_inside_tree():
		_game_root.add_child(_handler)

	_handler.setup(_game_root)
	# Force internal camera reference since @onready might not have fired yet
	_handler._camera = _camera
	_game_root.rotation = 0.0
	await get_tree().process_frame

func after_test() -> void:
	if is_instance_valid(_handler):
		_handler.queue_free()
	if is_instance_valid(_game_root):
		_game_root.queue_free()
	await get_tree().process_frame

# --- Tests ---

func test_get_camera_rotation() -> void:
	var test_rotation := PI / 4.0 # 45 degrees
	_game_root.rotation = test_rotation
	# CameraHandler.get_camera_rotation() returns _game_root.rotation
	assert_float(_handler.get_camera_rotation()).is_approximately(test_rotation, 0.05)

func test_rotate_camera() -> void:
	var start_rot := _game_root.rotation
	_handler.rotate_camera(1) # Rotate one step (60 degrees)
	# It should change from 0.0 to ~1.047
	assert_float(_game_root.rotation).is_not_approximately(start_rot, 0.05)

func test_zoom_method() -> void:
	var start_zoom := _camera.zoom.x
	_handler.zoom(1) # Zoom in
	assert_float(_camera.zoom.x).is_greater_than(start_zoom)
	_handler.zoom(-1) # Zoom out
	assert_float(_camera.zoom.x).is_approximately(start_zoom, 0.05)

func test_zoom_clamping() -> void:
	for i in range(50):
		_handler.zoom(1)
	assert_float(_camera.zoom.x).is_less_equal(2.55)

	for i in range(50):
		_handler.zoom(-1)
	assert_float(_camera.zoom.x).is_greater_equal(0.25)

func test_set_initial_rotation() -> void:
	var rot := PI # 180 degrees
	_handler.set_initial_rotation(rot)
	# Snap 180 to nearest 60 -> it is exactly 180 (3 * 60)
	assert_float(_game_root.rotation).is_approximately(PI, 0.05)

func test_set_free_cam() -> void:
	_handler.set_free_cam(true)
	assert_bool(_handler.is_free_cam()).is_true()
	_handler.set_free_cam(false)
	assert_bool(_handler.is_free_cam()).is_false()

func test_init_camera_snap() -> void:
	_game_root.rotation = deg_to_rad(45.0)
	_handler.init_camera_snap()
	# 45 snaps to 60 (PI/3)
	assert_float(_game_root.rotation).is_approximately(PI / 3.0, 0.05)

func test_rotation_snapping_and_wrapping() -> void:
	var target_rad := PI / 3.0 # 60 degrees
	_game_root.rotation = target_rad + 0.1
	_handler.init_camera_snap()
	assert_float(_game_root.rotation).is_approximately(target_rad, 0.05)

	# Rotate 6 times (360 degrees)
	for i in range(6):
		_handler.rotate_camera(1)
	
	# Should wrap and be back to ~target_rad or target_rad + TAU
	# fposmod handles wrapping
	assert_float(fposmod(_game_root.rotation, TAU)).is_approximately(fposmod(target_rad, TAU), 0.05)
