extends Control

const DisplayOrientation := preload("res://Resources/display_orientation.gd")

signal back_requested

@onready var _volume_slider: HSlider = $CanvasLayer/Panel/VBox/VolumeRow/Volume
@onready var _mute_check: CheckButton = $CanvasLayer/Panel/VBox/VolumeRow/Mute
@onready var _orientation_option: OptionButton = $CanvasLayer/Panel/VBox/OrientationRow/Orientation
@onready var _resolution_option: OptionButton = $CanvasLayer/Panel/VBox/ResolutionRow/Resolution
@onready var _animation_speed_option: OptionButton = $CanvasLayer/Panel/VBox/AnimationSpeedRow/AnimationSpeed
@onready var _auto_advance_toggle: CheckButton = $CanvasLayer/Panel/VBox/AutoAdvanceRow/AutoAdvance
@onready var _auto_advance_speed_slider: HSlider = $CanvasLayer/Panel/VBox/AutoAdvanceSpeedRow/AutoAdvanceSpeed
@onready var _auto_advance_speed_value: Label = $CanvasLayer/Panel/VBox/AutoAdvanceSpeedRow/AutoAdvanceSpeedValue
@onready var _text_speed_slider: HSlider = $CanvasLayer/Panel/VBox/TextSpeedRow/TextSpeed
@onready var _text_speed_value: Label = $CanvasLayer/Panel/VBox/TextSpeedRow/TextSpeedValue

var _display_settings: DisplaySettingsManager
var _game_config: Node

var _is_refreshing_resolution := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_input(true)
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller == null:
		push_error("AudioBusController autoload not found!")
		return
	_game_config = get_tree().root.get_node_or_null("GameConfig")
	var game_config = _game_config
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
	var ds = get_tree().root.get_node_or_null("DisplaySettings")
	if ds == null:
		push_error("DisplaySettings autoload not found!")
		print_debug("SettingsMenu: DisplaySettings FAILED to load from root.")
	else:
		_display_settings = ds
		print_debug("SettingsMenu: DisplaySettings found, populating options.")
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
			if not _orientation_option.item_selected.is_connected(_on_orientation_selected):
				_orientation_option.item_selected.connect(_on_orientation_selected)
			_orientation_option.get_parent().show() # Ensure row is visible
		else:
			print_debug("SettingsMenu: orientation_option node NOT FOUND at path.")

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
			if not _resolution_option.item_selected.is_connected(_on_resolution_selected):
				_resolution_option.item_selected.connect(_on_resolution_selected)
			_resolution_option.get_parent().show() # Ensure row is visible
		else:
			print_debug("SettingsMenu: resolution_option node NOT FOUND at path.")

	if is_instance_valid(_animation_speed_option):
		_animation_speed_option.clear()
		_animation_speed_option.add_item("Normal", 0)
		_animation_speed_option.add_item("Fast", 1)
		_animation_speed_option.add_item("Skip", 2)

		var current_speed = game_config.get_value("gameplay/animation_speed", "normal")
		var selected_idx = 0
		match current_speed:
			"fast": selected_idx = 1
			"skip": selected_idx = 2
		_animation_speed_option.select(selected_idx)
		if not _animation_speed_option.item_selected.is_connected(_on_animation_speed_selected):
			_animation_speed_option.item_selected.connect(_on_animation_speed_selected)

	_initialize_dialogue_settings(game_config)

func _unhandled_input(event: InputEvent) -> void:
	if $CanvasLayer.visible and event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	back_requested.emit()

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

func _on_animation_speed_selected(index: int) -> void:
	var speed = "normal"
	match index:
		1: speed = "fast"
		2: speed = "skip"

	if _game_config:
		_game_config.set_value("gameplay/animation_speed", speed)
		_game_config.save_config()

func _initialize_dialogue_settings(game_config: Node) -> void:
	if not is_instance_valid(_auto_advance_toggle):
		return
	var auto_setting := false
	if game_config != null:
		auto_setting = bool(game_config.get_value("dialogue/auto_advance_enabled", false))
	_auto_advance_toggle.button_pressed = auto_setting
	# _apply_auto_advance(auto_setting) # Removed, as it was Dialogic specific
	if not _auto_advance_toggle.toggled.is_connected(_on_auto_advance_toggled):
		_auto_advance_toggle.toggled.connect(_on_auto_advance_toggled)

	if is_instance_valid(_auto_advance_speed_slider):
		_auto_advance_speed_slider.min_value = 0.5
		_auto_advance_speed_slider.max_value = 2.0
		_auto_advance_speed_slider.step = 0.05
		var stored_speed := 1.0
		if game_config != null:
			stored_speed = float(game_config.get_value("dialogue/auto_advance_speed", 1.0))
		_auto_advance_speed_slider.value = clamp(stored_speed, _auto_advance_speed_slider.min_value, _auto_advance_speed_slider.max_value)
		_update_auto_advance_speed_label(_auto_advance_speed_slider.value)
		# _apply_auto_advance_speed(_auto_advance_speed_slider.value) # Removed, as it was Dialogic specific
		if not _auto_advance_speed_slider.value_changed.is_connected(_on_auto_advance_speed_changed):
			_auto_advance_speed_slider.value_changed.connect(_on_auto_advance_speed_changed)

	if is_instance_valid(_text_speed_slider):
		_text_speed_slider.min_value = 0.5
		_text_speed_slider.max_value = 2.0
		_text_speed_slider.step = 0.05
		var stored_text_speed := 1.0
		if game_config != null:
			stored_text_speed = float(game_config.get_value("dialogue/text_speed", 1.0))
		_text_speed_slider.value = clamp(stored_text_speed, _text_speed_slider.min_value, _text_speed_slider.max_value)
		_update_text_speed_label(_text_speed_slider.value)
		# _apply_text_speed(_text_speed_slider.value) # Removed, as it was Dialogic specific
		if not _text_speed_slider.value_changed.is_connected(_on_text_speed_changed):
			_text_speed_slider.value_changed.connect(_on_text_speed_changed)

func _on_auto_advance_toggled(pressed: bool) -> void:
	_save_dialogue_value("dialogue/auto_advance_enabled", pressed)

func _on_auto_advance_speed_changed(value: float) -> void:
	if not is_instance_valid(_auto_advance_speed_slider):
		return
	var clamped: float = clamp(value, _auto_advance_speed_slider.min_value, _auto_advance_speed_slider.max_value)
	_update_auto_advance_speed_label(clamped)
	_save_dialogue_value("dialogue/auto_advance_speed", clamped)

func _on_text_speed_changed(value: float) -> void:
	if not is_instance_valid(_text_speed_slider):
		return
	var clamped: float = clamp(value, _text_speed_slider.min_value, _text_speed_slider.max_value)
	_update_text_speed_label(clamped)
	_save_dialogue_value("dialogue/text_speed", clamped)

func _update_auto_advance_speed_label(value: float) -> void:
	if is_instance_valid(_auto_advance_speed_value):
		_auto_advance_speed_value.text = "%.1fx" % value

func _update_text_speed_label(value: float) -> void:
	if is_instance_valid(_text_speed_value):
		_text_speed_value.text = "%.1fx" % value

func _save_dialogue_value(path: String, value) -> void:
	if _game_config == null:
		return
	_game_config.set_value(path, value)
	_game_config.save_config()
