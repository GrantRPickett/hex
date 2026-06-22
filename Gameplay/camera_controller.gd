class_name CameraController
extends Node

var _camera: Camera2D
var _camera_handler: CameraHandler
var _unit_manager: UnitManager
var _batch_mode : bool = false

func setup(state: GameState, config: GameSessionBuilder.Config) -> void:
	_camera = config.camera
	_camera_handler = config.camera_handler
	_unit_manager = state.unit_manager
	_camera_handler.setup(config.grid.get_parent())

	if _unit_manager and _unit_manager.has_signal("unit_path_moved"):
		_unit_manager.unit_path_moved.connect(_on_unit_path_moved)
	if _unit_manager and _unit_manager.has_signal("selection_changed"):
		_unit_manager.selection_changed.connect(center_on_selected)

func set_batch_mode(enabled: bool) -> void:
	_batch_mode = enabled

func center_on_selected(_index: int = -1) -> void:
	if _batch_mode:
		return
	if is_instance_valid(_camera_handler) and is_instance_valid(_unit_manager):
		var unit := _unit_manager.get_selected_unit()
		if unit:
			_camera_handler.call("center_on_position", unit.position)

func center_on(pos: Vector2) -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.call("center_on_position", pos)

func initialize_camera() -> void:
	init_camera_snap()
	center_on_selected()

func init_camera_snap() -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.init_camera_snap()

func get_camera_rotation() -> float:
	if is_instance_valid(_camera_handler):
		return _camera_handler.get_camera_rotation()
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

func pan_camera(relative_delta: Vector2) -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.pan_camera(relative_delta)

func _on_unit_path_moved(index: int, _path: Array[Vector2i]) -> void:
	if is_instance_valid(_unit_manager) and index == _unit_manager.get_selected_index():
		center_on_selected()

func handle_camera_input(event: InputEvent) -> void:
	if is_instance_valid(_camera_handler):
		_camera_handler.call("handle_camera_input", event)
