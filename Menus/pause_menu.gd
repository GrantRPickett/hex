extends Control

const DisplayOrientation := preload("res://Resources/display_orientation.gd")

signal resume_requested
signal controls_requested
signal quit_requested

@onready var _volume_slider: HSlider = $CanvasLayer/Panel/VBox/VolumeRow/Volume
@onready var _mute_check: CheckButton = $CanvasLayer/Panel/VBox/VolumeRow/Mute
@onready var _orientation_option: OptionButton = $CanvasLayer/Panel/VBox/OrientationRow/Orientation
@onready var _resolution_option: OptionButton = $CanvasLayer/Panel/VBox/ResolutionRow/Resolution

var _display_settings: DisplaySettingsManager
var _is_refreshing_resolution := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_input(true)
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller == null:
		push_error("AudioBusController autoload not found!")
		return
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config == null:
		push_error("GameConfig autoload not found!")
		return
	if is_instance_valid(_volume_slider):
		_volume_slider.min_value = -40.0
		_volume_slider.max_value = 0.0
		_volume_slider.step = 0.5
		var saved_db = game_config.get_value("audio/music_db", audio_bus_controller.get_bus_volume_db("Music"))
		_volume_slider.value = float(saved_db)
		audio_bus_controller.set_bus_volume_db("Music", float(saved_db))
		_volume_slider.value_changed.connect(_on_volume_changed)
	if is_instance_valid(_mute_check):
		var saved_muted = game_config.get_value("audio/music_muted", audio_bus_controller.is_bus_muted("Music"))
		_mute_check.button_pressed = bool(saved_muted)
		audio_bus_controller.mute_bus("Music", bool(saved_muted))
		_mute_check.toggled.connect(_on_mute_toggled)
	var display_settings_node = get_tree().root.get_node_or_null("DisplaySettings")
	if display_settings_node == null:
		push_error("DisplaySettings autoload not found!")
	else:
		_display_settings = display_settings_node
		if is_instance_valid(_orientation_option):
			_orientation_option.clear()
			_orientation_option.add_item("Landscape", DisplayOrientation.Orientation.LANDSCAPE)
			_orientation_option.add_item("Portrait", DisplayOrientation.Orientation.PORTRAIT)
			var orientation_index := 0
			var current_orientation := _display_settings.get_current_orientation()
			for i in range(_orientation_option.get_item_count()):
				if _orientation_option.get_item_id(i) == current_orientation:
					orientation_index = i
					break
			_orientation_option.select(orientation_index)
			_orientation_option.item_selected.connect(_on_orientation_selected)
		if is_instance_valid(_resolution_option):
			_is_refreshing_resolution = true
			_resolution_option.clear()
			var orientation := _display_settings.get_current_orientation()
			var options := _display_settings.get_standard_resolutions(orientation)
			for i in range(options.size()):
				var res: Vector2i = options[i]
				_resolution_option.add_item("%d x %d" % [res.x, res.y], i)
			_resolution_option.select(_display_settings.get_current_resolution_index())
			_is_refreshing_resolution = false
			_resolution_option.item_selected.connect(_on_resolution_selected)

func _on_resume_pressed() -> void:
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
	resume_requested.emit()

func _on_controls_pressed() -> void:
	controls_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()

func _on_volume_changed(value: float) -> void:
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller != null:
		audio_bus_controller.set_bus_volume_db("Music", value)
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		game_config.set_value("audio/music_db", value)
		game_config.save_config()

func _on_mute_toggled(pressed: bool) -> void:
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller != null:
		audio_bus_controller.mute_bus("Music", pressed)
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		game_config.set_value("audio/music_muted", pressed)
		game_config.save_config()

func _on_orientation_selected(index: int) -> void:
	if _display_settings == null or not is_instance_valid(_orientation_option):
		return
	var orientation_id := _orientation_option.get_item_id(index)
	_display_settings.set_orientation(orientation_id)
	if is_instance_valid(_resolution_option):
		_is_refreshing_resolution = true
		_resolution_option.clear()
		var options := _display_settings.get_standard_resolutions(orientation_id)
		for i in range(options.size()):
			var res: Vector2i = options[i]
			_resolution_option.add_item("%d x %d" % [res.x, res.y], i)
		_resolution_option.select(_display_settings.get_current_resolution_index())
		_is_refreshing_resolution = false
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		var orientation_name := DisplayOrientation.to_name(orientation_id)
		game_config.set_value("display/orientation", orientation_name)
		game_config.set_value("display/resolution", _display_settings.get_current_resolution())
		game_config.save_config()

func _on_resolution_selected(index: int) -> void:
	if _display_settings == null or _is_refreshing_resolution:
		return
	_display_settings.set_resolution_index(index)
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		var orientation_name := DisplayOrientation.to_name(_display_settings.get_current_orientation())
		game_config.set_value("display/orientation", orientation_name)
		game_config.set_value("display/resolution", _display_settings.get_current_resolution())
		game_config.save_config()
