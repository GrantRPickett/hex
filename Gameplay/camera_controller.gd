class_name CameraController
extends Node

var _camera: Camera2D
var _camera_handler: CameraHandler
var _unit_manager: UnitManager

func setup(camera: Camera2D, camera_handler: CameraHandler, unit_manager: UnitManager) -> void:
	_camera = camera
	_camera_handler = camera_handler
	_unit_manager = unit_manager

func init_camera_snap() -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.init_camera_snap()

func center_on_selected() -> void:
	if is_instance_valid(_camera_handler):
		var sprite := _unit_manager.get_selected_sprite()
		if sprite:
			_camera_handler.call("center_on_position", sprite.position)

func get_rotation() -> float:
	if is_instance_valid(_camera):
		return _camera.rotation
	return 0.0

func toggle_free_cam() -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.call("set_free_cam", not _camera_handler.call("is_free_cam"))
		if not _camera_handler.get("free_cam"):
			center_on_selected()

func zoom(direction: int) -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.zoom(direction)

func handle_camera_input(event: InputEvent) -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.call("handle_camera_input", event)