extends "res://tests/test_utils.gd"


class MockAudioBusController extends Node:
	var volume_db: Dictionary = {}
	var muted: Dictionary = {}
	func get_bus_volume_db(bus: String) -> float:
		return volume_db.get(bus, 0.0)
	func set_bus_volume_db(bus: String, db: float) -> void:
		volume_db[bus] = db
	func is_bus_muted(bus: String) -> bool:
		return muted.get(bus, false)
	func mute_bus(bus: String, enable: bool) -> void:
		muted[bus] = enable

class MockGameConfig extends Node:
	var values: Dictionary = {}
	func get_value(key: String, default = null):
		return values.get(key, default)
	func set_value(key: String, value) -> void:
		values[key] = value
	func save_config() -> void:
		pass
class MockDisplaySettings extends Node:
	var landscape: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720)]
	var portrait: Array[Vector2i] = [Vector2i(1080, 1920), Vector2i(720, 1280)]
	var orientation: int = DisplayOrientation.Orientation.LANDSCAPE
	var index: int = 0
	func get_standard_resolutions(requested_orientation: int) -> Array[Vector2i]:
		return landscape.duplicate() if requested_orientation == DisplayOrientation.Orientation.LANDSCAPE else portrait.duplicate()
	func get_current_orientation() -> int:
		return orientation
	func get_current_resolution_index() -> int:
		return index
	func get_current_resolution() -> Vector2i:
		var pool = get_standard_resolutions(orientation)
		if pool.is_empty():
			return Vector2i.ZERO
		var clamped = clamp(index, 0, pool.size() - 1)
		return pool[clamped]
	func set_orientation(new_orientation: int) -> void:
		orientation = new_orientation
		var pool = get_standard_resolutions(orientation)
		if pool.is_empty():
			index = 0
		else:
			index = clamp(index, 0, pool.size() - 1)
	func set_resolution_index(new_index: int) -> void:
		var pool = get_standard_resolutions(orientation)
		if pool.is_empty():
			index = 0
		else:
			index = clamp(new_index, 0, pool.size() - 1)

class MockAutoAdvance extends RefCounted:
	var enabled_forced := false
	var enabled_until_user_input := false

class MockDialogicInputs extends Node:
	var auto_advance := MockAutoAdvance.new()

class MockDialogicSettings extends Node:
	var autoadvance_delay_modifier := 1.0
	var text_speed := 1.0

class MockDialogic extends Node:
	var Inputs := MockDialogicInputs.new()
	var Settings := MockDialogicSettings.new()

const PAUSE_MENU_PATH := "res://Menus/pause_menu.tscn"

var _runner: GdUnitSceneRunner
var _audio_bus_controller: Node
var _game_config: Node
var _original_audio_bus_controller: Node
var _original_game_config: Node
var _display_settings: Node
var _original_display_settings: Node
var _dialogic: Node
var _original_dialogic: Node

func before_test() -> void:
	var root: Node = get_tree().root

	# Mock AudioBusController
	_original_audio_bus_controller = root.get_node_or_null("AudioBusController")
	if _original_audio_bus_controller != null:
		root.remove_child(_original_audio_bus_controller)
	_audio_bus_controller = MockAudioBusController.new()
	_audio_bus_controller.name = "AudioBusController"
	root.add_child(_audio_bus_controller)

	# Mock GameConfig
	_original_game_config = root.get_node_or_null("GameConfig")
	if _original_game_config != null:
		root.remove_child(_original_game_config)
	_game_config = MockGameConfig.new()
	_game_config.name = "GameConfig"
	root.add_child(_game_config)

	# Mock DisplaySettings
	_original_display_settings = root.get_node_or_null("DisplaySettings")
	if _original_display_settings != null:
		root.remove_child(_original_display_settings)
	_display_settings = MockDisplaySettings.new()
	_display_settings.name = "DisplaySettings"
	root.add_child(_display_settings)

	# Mock Dialogic
	_original_dialogic = root.get_node_or_null("Dialogic")
	if _original_dialogic != null:
		root.remove_child(_original_dialogic)
	_dialogic = MockDialogic.new()
	_dialogic.name = "Dialogic"
	root.add_child(_dialogic)

	_runner = scene_runner(PAUSE_MENU_PATH)
	await _runner.simulate_frames(1)

func after_test() -> void:
	var root: Node = get_tree().root
	if is_instance_valid(_audio_bus_controller):
		root.remove_child(_audio_bus_controller)
		_audio_bus_controller.free()
	if is_instance_valid(_game_config):
		root.remove_child(_game_config)
		_game_config.free()
	if is_instance_valid(_original_audio_bus_controller):
		root.add_child(_original_audio_bus_controller)
		_original_audio_bus_controller = null
	if is_instance_valid(_original_game_config):
		root.add_child(_original_game_config)
		_original_game_config = null
	if is_instance_valid(_display_settings):
		root.remove_child(_display_settings)
		_display_settings.free()
	if is_instance_valid(_original_display_settings):
		root.add_child(_original_display_settings)
		_original_display_settings = null
	if is_instance_valid(_dialogic):
		root.remove_child(_dialogic)
		_dialogic.free()
	if is_instance_valid(_original_dialogic):
		root.add_child(_original_dialogic)
		_original_dialogic = null

func test_resume_button_emits_signal() -> void:
	var btn: Button = _runner.find_child("Resume", true, false)
	assert_that(btn).is_not_null()

	var monitor = monitor_signals(_runner.scene())
	btn.emit_signal("pressed")
	await _runner.simulate_frames(1)
	assert_signal(monitor).is_emitted("resume_requested")

func test_controls_button_emits_signal() -> void:
	var btn: Button = _runner.find_child("Controls", true, false)
	assert_that(btn).is_not_null()

	var monitor = monitor_signals(_runner.scene())
	btn.emit_signal("pressed")
	await _runner.simulate_frames(1)
	assert_signal(monitor).is_emitted("controls_requested")

func test_quit_button_emits_signal() -> void:
	var btn: Button = _runner.find_child("Quit", true, false)
	assert_that(btn).is_not_null()

	var monitor = monitor_signals(_runner.scene())
	btn.emit_signal("pressed")
	await _runner.simulate_frames(1)
	assert_signal(monitor).is_emitted("quit_requested")

func test_volume_slider_updates_audio_and_config() -> void:
	var slider: HSlider = _runner.find_child("Volume", true, false)
	assert_that(slider).is_not_null()

	slider.value = -10.0
	slider.value_changed.emit(-10.0)

	assert_that(_audio_bus_controller.get_bus_volume_db("Music")).is_equal(-10.0)
	assert_that(_game_config.get_value("audio/music_db")).is_equal(-10.0)

func test_mute_check_updates_audio_and_config() -> void:
	var check: CheckButton = _runner.find_child("Mute", true, false)
	assert_that(check).is_not_null()

	check.button_pressed = true
	check.toggled.emit(true)

	assert_bool(_audio_bus_controller.is_bus_muted("Music")).is_true()
	assert_bool(_game_config.get_value("audio/music_muted")).is_true()

func test_orientation_selection_updates_display_settings_and_config() -> void:
	var orientation_option: OptionButton = _runner.find_child("Orientation", true, false)
	assert_that(orientation_option).is_not_null()
	var scene: Control = _runner.scene() as Control
	scene._on_orientation_selected(1)
	var mock: MockDisplaySettings = _display_settings as MockDisplaySettings
	assert_that(mock.orientation).is_equal(DisplayOrientation.Orientation.PORTRAIT)
	assert_that(_game_config.get_value("display/orientation")).is_equal("portrait")
	var resolution_option: OptionButton = _runner.find_child("Resolution", true, false)
	assert_that(resolution_option.get_item_count()).is_equal(mock.portrait.size())

func test_resolution_selection_updates_display_settings_and_config() -> void:
	var scene: Control = _runner.scene() as Control
	scene._on_resolution_selected(1)
	var mock: MockDisplaySettings = _display_settings as MockDisplaySettings
	assert_that(mock.get_current_resolution_index()).is_equal(1)
	assert_that(_game_config.get_value("display/resolution")).is_equal(mock.get_current_resolution())

func test_auto_advance_toggle_updates_dialogic_and_config() -> void:
	var toggle: CheckButton = _runner.find_child("AutoAdvance", true, false)
	assert_that(toggle).is_not_null()

	toggle.button_pressed = true
	toggle.toggled.emit(true)

	var mock: MockDialogic = _dialogic as MockDialogic
	assert_bool(mock.Inputs.auto_advance.enabled_until_user_input).is_true()
	assert_bool(mock.Inputs.auto_advance.enabled_forced).is_true()
	assert_bool(_game_config.get_value("dialogue/auto_advance_enabled")).is_true()

func test_auto_advance_speed_slider_updates_settings_and_config() -> void:
	var slider: HSlider = _runner.find_child("AutoAdvanceSpeed", true, false)
	var label: Label = _runner.find_child("AutoAdvanceSpeedValue", true, false)
	assert_that(slider).is_not_null()
	assert_that(label).is_not_null()

	slider.value = 1.2
	slider.value_changed.emit(1.2)

	var mock: MockDialogic = _dialogic as MockDialogic
	assert_that(mock.Settings.autoadvance_delay_modifier).is_equal(1.2)
	assert_that(_game_config.get_value("dialogue/auto_advance_speed")).is_equal(1.2)
	assert_that(label.text).is_equal("1.2x")

func test_text_speed_slider_updates_settings_and_config() -> void:
	var slider: HSlider = _runner.find_child("TextSpeed", true, false)
	var label: Label = _runner.find_child("TextSpeedValue", true, false)
	assert_that(slider).is_not_null()
	assert_that(label).is_not_null()

	slider.value = 0.6
	slider.value_changed.emit(0.6)

	var mock: MockDialogic = _dialogic as MockDialogic
	assert_that(mock.Settings.text_speed).is_equal(0.6)
	assert_that(_game_config.get_value("dialogue/text_speed")).is_equal(0.6)
	assert_that(label.text).is_equal("0.6x")
