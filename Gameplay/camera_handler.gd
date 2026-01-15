# Manages camera movement, rotation, and zoom.
# This class no longer handles raw input directly. Instead, it provides public methods
# that are called from Gameplay.gd in response to signals from the InputHandler.
class_name CameraHandler
extends Node

@export var camera_node: NodePath
@onready var _camera: Camera2D = get_node(camera_node) as Camera2D

# --- Constants ---

const CAMERA_ROTATE_STEP := TAU / 6.0 # 60 degrees, aligns to hex grid
const CAMERA_ZOOM_STEP := 0.1
const CAMERA_ZOOM_MIN := 0.5
const CAMERA_ZOOM_MAX := 2.5


# --- Private State ---

var _free_cam := false
var _camera_base_rotation: float = 0.0
var _camera_step_index: int = 0


# --- Signals ---

# Emitted when the free-cam state changes.
signal free_cam_toggled(is_free: bool)


# --- Engine Callbacks ---

func _ready() -> void:
	if is_instance_valid(_camera):
		_camera.make_current()
		init_camera_snap()


# --- Public Methods ---

# Snaps the camera's rotation to the nearest 60-degree increment.
func init_camera_snap() -> void:
	var current_rot := fposmod(_camera.rotation, TAU)
	var n: int = int(round(current_rot / CAMERA_ROTATE_STEP)) % 6
	_camera_step_index = 0
	_camera_base_rotation = float(n) * CAMERA_ROTATE_STEP
	_apply_camera_rotation_from_step()


# Rotates the camera by a given number of steps.
func rotate_camera(rotation_delta: int) -> void:
	_camera_step_index += rotation_delta
	_apply_camera_rotation_from_step()


# Zooms the camera in or out based on a direction.
func zoom(direction: int) -> void:
	var zoom_amount := float(direction) * CAMERA_ZOOM_STEP
	var new_zoom: float = clampf(_camera.zoom.x + zoom_amount, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
	_camera.zoom = Vector2(new_zoom, new_zoom)


# Sets the initial rotation of the camera and snaps it.
func set_initial_rotation(rotation: float) -> void:
	_camera.rotation = rotation
	init_camera_snap()


# Centers the camera on a given world position, unless in free-cam mode.
func center_on_position(pos: Vector2) -> void:
	if _free_cam:
		return
	_camera.position = Vector2(round(pos.x), round(pos.y))
	_camera.make_current()


# Enables or disables free-cam mode.
func set_free_cam(is_free: bool) -> void:
	if _free_cam == is_free:
		return
	_free_cam = is_free
	free_cam_toggled.emit(_free_cam)


# Returns true if free-cam mode is active.
func is_free_cam() -> bool:
	return _free_cam


# Returns the camera's current rotation in radians.
func get_camera_rotation() -> float:
	return _camera.rotation


# This handler exists so InputHandler can forward raw events (e.g. mouse motion) to the camera system without depending on engine-level input dispatch.
# Entry point for camera-specific raw input forwarded by Gameplay/InputHandler.
func handle_camera_input(event: InputEvent) -> void:
	if event == null:
		return

	var is_left := false
	var is_right := false
	if event is InputEventAction:
		is_left = event.pressed and event.action == "camera_rotate_left"
		is_right = event.pressed and event.action == "camera_rotate_right"
	else:
		is_left = event.is_action_pressed("camera_rotate_left")
		is_right = event.is_action_pressed("camera_rotate_right")

	if is_left:
		rotate_camera(-1)
		if get_viewport():
			get_viewport().set_input_as_handled()
		return
	if is_right:
		rotate_camera(1)
		if get_viewport():
			get_viewport().set_input_as_handled()
		return

func _unhandled_input(event: InputEvent) -> void:
	handle_camera_input(event)

# --- Private Methods ---

# Applies the final rotation to the camera based on the current step index.
func _apply_camera_rotation_from_step() -> void:
	# The modulo operator ensures the step wraps around correctly for a 6-step rotation.
	var step := int((_camera_step_index % 6 + 6) % 6)
	var new_rotation := _camera_base_rotation + float(step) * CAMERA_ROTATE_STEP
	_camera.rotation = new_rotation
