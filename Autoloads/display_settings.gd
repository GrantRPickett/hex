class_name DisplaySettingsManager
extends Node

const Orientation = DisplayOrientation.Orientation

signal display_settings_changed(orientation: DisplayOrientation.Orientation, resolution: Vector2i)

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
var _current_resolution_index := 1

func _ready() -> void:
	_load_stored_settings()

	if OS.has_feature("headless"):
		return

	_apply_window_settings()

func _load_stored_settings() -> void:
	var orientation_name: String = _get_stored_orientation_name()
	_current_orientation = DisplayOrientation.from_string(orientation_name)

	var options: Array[Vector2i] = get_standard_resolutions(_current_orientation)
	if options.is_empty():
		return

	var stored_res: Vector2i= GameConfig.get_value(GameConfig.Paths.DISPLAY_RESOLUTION, null) if GameConfig else null
	var resolved: Vector2i = _resolve_resolution(stored_res, options)

	_current_resolution_index = _find_resolution_index(resolved, options)

func _get_stored_orientation_name() -> String:
	var default = GameConstants.Settings.ORIENTATION_LANDSCAPE
	if GameConfig:
		var val = GameConfig.get_value(GameConfig.Paths.DISPLAY_ORIENTATION, default)
		if val is String or val is StringName:
			return String(val)
	return default

func _resolve_resolution(stored: Vector2i, options: Array[Vector2i]) -> Vector2i:
	if stored == null:
		return options[clamp(_current_resolution_index, 0, options.size() - 1)]

	return options[clamp(_current_resolution_index, 0, options.size() - 1)]

func _find_resolution_index(target: Vector2i, options: Array[Vector2i]) -> int:
	for i in range(options.size()):
		if options[i] == target:
			return i
	return clamp(_current_resolution_index, 0, options.size() - 1)

func _apply_window_settings() -> void:
	var window_id: int = _get_active_window_id()
	if window_id == DisplayServer.INVALID_WINDOW_ID:
		return

	var options: Array[Vector2i] = get_standard_resolutions(_current_orientation)
	if options.is_empty():
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
	DisplayServer.window_set_size(options[_current_resolution_index], window_id)

func _get_active_window_id() -> int:
	var window_list: PackedInt32Array = DisplayServer.get_window_list()
	if window_list.is_empty():
		return DisplayServer.INVALID_WINDOW_ID

	var window_id: int = window_list[0]
	if window_id == DisplayServer.INVALID_WINDOW_ID or DisplayServer.window_get_mode(window_id) == DisplayServer.WINDOW_MODE_MINIMIZED:
		window_id = DisplayServer.get_window_at_screen_position(DisplayServer.mouse_get_position())

	return window_id


func get_standard_resolutions(orientation: DisplayOrientation.Orientation) -> Array[Vector2i]:
	return LANDSCAPE_RESOLUTIONS.duplicate() if orientation == Orientation.LANDSCAPE else PORTRAIT_RESOLUTIONS.duplicate()

func get_current_orientation() -> DisplayOrientation.Orientation:
	return _current_orientation

func get_current_resolution_index() -> int:
	return _current_resolution_index

func get_current_resolution() -> Vector2i:
	var options: Array[Vector2i] = get_standard_resolutions(_current_orientation)
	return options[_current_resolution_index] if not options.is_empty() else Vector2i.ZERO

func set_orientation(orientation: DisplayOrientation.Orientation) -> void:
	if orientation == _current_orientation:
		return
	_current_orientation = orientation
	var options: Array[Vector2i] = get_standard_resolutions(_current_orientation)
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
	display_settings_changed.emit(_current_orientation, options[_current_resolution_index])

func set_resolution_index(index: int) -> void:
	var options: Array[Vector2i] = get_standard_resolutions(_current_orientation)
	if options.is_empty():
		return
	var clamped: int = clamp(index, 0, options.size() - 1)
	if clamped == _current_resolution_index:
		return
	_current_resolution_index = clamped
	if OS.has_feature("headless"):
		return
	var window_list: PackedInt32Array = DisplayServer.get_window_list()
	if window_list.is_empty():
		return
	var window_id: int = window_list[0]
	if window_id == DisplayServer.INVALID_WINDOW_ID or DisplayServer.window_get_mode(window_id) == DisplayServer.WINDOW_MODE_MINIMIZED:
		window_id = DisplayServer.get_window_at_screen_position(DisplayServer.mouse_get_position())
	if window_id == DisplayServer.INVALID_WINDOW_ID:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
	DisplayServer.window_set_size(options[_current_resolution_index], window_id)
	display_settings_changed.emit(_current_orientation, options[_current_resolution_index])
