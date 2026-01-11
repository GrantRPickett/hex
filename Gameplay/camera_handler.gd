extends Node

@export var camera_node: NodePath
@onready var _camera: Camera2D = get_node(camera_node) as Camera2D

const CAMERA_ROTATE_STEP := TAU / 6.0 # 60 degrees, aligns to hex grid
const CAMERA_ZOOM_STEP := 0.1
const CAMERA_ZOOM_MIN := 0.5
const CAMERA_ZOOM_MAX := 3.0

var _lmb_down := false
var _rmb_down := false
var _free_cam := false
var _camera_base_rotation: float = 0.0
var _camera_step_index: int = 0

signal selection_cycled(direction: int)
signal free_cam_toggled(is_free: bool)

func _ready() -> void:
	if is_instance_valid(_camera):
		_camera.make_current()
		init_camera_snap()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if _handle_mouse_button(event as InputEventMouseButton):
			get_viewport().set_input_as_handled()
			return

	if _handle_camera_actions(event):
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("toggle_free_cam"):
		_free_cam = not _free_cam
		free_cam_toggled.emit(_free_cam)
		get_viewport().set_input_as_handled()
		return

func _handle_mouse_button(event: InputEventMouseButton) -> bool:
	_update_mouse_button_state(event)
	if event.pressed and _handle_mouse_wheel_event(event):
		return true
	if _handle_middle_click_toggle(event):
		return true
	return false

func _update_mouse_button_state(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_lmb_down = event.pressed
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_rmb_down = event.pressed

func _handle_mouse_wheel_event(event: InputEventMouseButton) -> bool:
	if event.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return false
	var dir := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
	if _rmb_down:
		_camera_step_index += dir
		_apply_camera_rotation_from_step()
	elif _lmb_down:
		selection_cycled.emit(dir)
	else:
		var nz: float = clampf(_camera.zoom.x + float(dir) * CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
		_camera.zoom = Vector2(nz, nz)
	return true

func _handle_middle_click_toggle(event: InputEventMouseButton) -> bool:
	if event.button_index != MOUSE_BUTTON_MIDDLE or not event.pressed:
		return false
	_free_cam = not _free_cam
	free_cam_toggled.emit(_free_cam)
	return true

func _handle_camera_actions(event: InputEvent) -> bool:
	if event.is_action_pressed("camera_rotate_left"):
		_camera_step_index -= 1
		_apply_camera_rotation_from_step()
		return true
	if event.is_action_pressed("camera_rotate_right"):
		_camera_step_index += 1
		_apply_camera_rotation_from_step()
		return true
	if event.is_action_pressed("camera_zoom_in"):
		var nz: float = clampf(_camera.zoom.x + CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
		_camera.zoom = Vector2(nz, nz)
		return true
	if event.is_action_pressed("camera_zoom_out"):
		var nz2: float = clampf(_camera.zoom.x - CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
		_camera.zoom = Vector2(nz2, nz2)
		return true
	return false

func _apply_camera_rotation_from_step() -> void:
	var step := int((_camera_step_index % 6 + 6) % 6)
	_camera.rotation = _camera_base_rotation + float(step) * CAMERA_ROTATE_STEP

func init_camera_snap() -> void:
	var n: int = int(round(_camera.rotation / CAMERA_ROTATE_STEP))
	_camera_step_index = 0
	_camera_base_rotation = float(n) * CAMERA_ROTATE_STEP
	_apply_camera_rotation_from_step()

func set_initial_rotation(rotation: float) -> void:
	_camera.rotation = rotation
	init_camera_snap()

func center_on_position(pos: Vector2) -> void:
	if _free_cam:
		return
	_camera.position = Vector2(round(pos.x), round(pos.y))
	_camera.make_current()

func is_free_cam() -> bool:
	return _free_cam

func get_camera_rotation() -> float:
	return _camera.rotation
