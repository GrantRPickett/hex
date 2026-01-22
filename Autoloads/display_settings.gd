class_name DisplaySettingsManager
extends Node

const DisplayOrientation := preload("res://Resources/display_orientation.gd")
const Orientation = DisplayOrientation.Orientation

const LANDSCAPE_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(3840, 2160),
	Vector2i(2560, 1440),
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
]

const PORTRAIT_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(2160, 3840),
	Vector2i(1440, 2560),
	Vector2i(1080, 1920),
	Vector2i(900, 1600),
	Vector2i(720, 1280),
]

var _current_orientation: DisplayOrientation.Orientation = Orientation.LANDSCAPE
var _current_resolution_index := 2

func _ready() -> void:
	var config := get_tree().root.get_node_or_null("GameConfig")
	var orientation_name := "landscape"
	var stored_resolution: Variant = null
	if config != null:
		orientation_name = String(config.get_value("display/orientation", orientation_name))
		stored_resolution = config.get_value("display/resolution", null)
	_current_orientation = DisplayOrientation.from_string(orientation_name)
	var options := get_standard_resolutions(_current_orientation)
	if options.is_empty():
		return
	_current_resolution_index = clamp(_current_resolution_index, 0, options.size() - 1)
	var resolved := options[_current_resolution_index]
	if stored_resolution != null:
		match typeof(stored_resolution):
			TYPE_VECTOR2I:
				resolved = stored_resolution
			TYPE_VECTOR2:
				var vec2 := stored_resolution as Vector2
				resolved = Vector2i(roundi(vec2.x), roundi(vec2.y))
			TYPE_ARRAY:
				if stored_resolution.size() >= 2:
					resolved = Vector2i(int(stored_resolution[0]), int(stored_resolution[1]))
			TYPE_DICTIONARY:
				if stored_resolution.has("x") and stored_resolution.has("y"):
					resolved = Vector2i(int(stored_resolution["x"]), int(stored_resolution["y"]))
	var matched_index := _current_resolution_index
	for i in range(options.size()):
		if options[i] == resolved:
			matched_index = i
			break
	_current_resolution_index = matched_index
	if OS.has_feature("headless"):
		return
	var window_list := DisplayServer.get_window_list()
	if window_list.is_empty():
		return
	var window_id := window_list[0]
	if window_id == DisplayServer.INVALID_WINDOW_ID or DisplayServer.window_get_mode(window_id) == DisplayServer.WINDOW_MODE_MINIMIZED:
		window_id = DisplayServer.get_window_at_screen_position(DisplayServer.mouse_get_position())
	if window_id == DisplayServer.INVALID_WINDOW_ID:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
	DisplayServer.window_set_size(options[_current_resolution_index], window_id)

func get_standard_resolutions(orientation: DisplayOrientation.Orientation) -> Array[Vector2i]:
	return LANDSCAPE_RESOLUTIONS.duplicate() if orientation == Orientation.LANDSCAPE else PORTRAIT_RESOLUTIONS.duplicate()

func get_current_orientation() -> DisplayOrientation.Orientation:
	return _current_orientation

func get_current_resolution_index() -> int:
	return _current_resolution_index

func get_current_resolution() -> Vector2i:
	var options := get_standard_resolutions(_current_orientation)
	return options[_current_resolution_index] if not options.is_empty() else Vector2i.ZERO

func set_orientation(orientation: DisplayOrientation.Orientation) -> void:
	if orientation == _current_orientation:
		return
	_current_orientation = orientation
	var options := get_standard_resolutions(_current_orientation)
	if options.is_empty():
		return
	_current_resolution_index = clamp(_current_resolution_index, 0, options.size() - 1)
	if OS.has_feature("headless"):
		return
	var window_list := DisplayServer.get_window_list()
	if window_list.is_empty():
		return
	var window_id := window_list[0]
	if window_id == DisplayServer.INVALID_WINDOW_ID or DisplayServer.window_get_mode(window_id) == DisplayServer.WINDOW_MODE_MINIMIZED:
		window_id = DisplayServer.get_window_at_screen_position(DisplayServer.mouse_get_position())
	if window_id == DisplayServer.INVALID_WINDOW_ID:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
	DisplayServer.window_set_size(options[_current_resolution_index], window_id)

func set_resolution_index(index: int) -> void:
	var options := get_standard_resolutions(_current_orientation)
	if options.is_empty():
		return
	var clamped: int = clamp(index, 0, options.size() - 1)
	if clamped == _current_resolution_index:
		return
	_current_resolution_index = clamped
	if OS.has_feature("headless"):
		return
	var window_list := DisplayServer.get_window_list()
	if window_list.is_empty():
		return
	var window_id := window_list[0]
	if window_id == DisplayServer.INVALID_WINDOW_ID or DisplayServer.window_get_mode(window_id) == DisplayServer.WINDOW_MODE_MINIMIZED:
		window_id = DisplayServer.get_window_at_screen_position(DisplayServer.mouse_get_position())
	if window_id == DisplayServer.INVALID_WINDOW_ID:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
	DisplayServer.window_set_size(options[_current_resolution_index], window_id)
