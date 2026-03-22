extends GdUnitTestSuite

const PAUSE_MENU_PATH := "res://Menus/pause_menu.tscn"
const Stubs := preload("res://tests/fixtures/test_stubs.gd")

var _runner: GdUnitSceneRunner
var _original_display_settings: Node
var _display_settings: Stubs.FakeDisplaySettings

func before_test() -> void:
	var root: Node = get_tree().root

	# Mock DisplaySettings
	_original_display_settings = root.get_node_or_null("DisplaySettings")
	if _original_display_settings != null:
		root.remove_child(_original_display_settings)
	_display_settings = Stubs.FakeDisplaySettings.new()
	_display_settings.name = "DisplaySettings"
	root.add_child(_display_settings)

	_runner = scene_runner(PAUSE_MENU_PATH)
	await _runner.simulate_frames(1)

func after_test() -> void:
	var root: Node = get_tree().root
	if is_instance_valid(_display_settings):
		root.remove_child(_display_settings)
		_display_settings.free()
	if is_instance_valid(_original_display_settings):
		root.add_child(_original_display_settings)
		_original_display_settings = null

func test_resume_button_emits_signal() -> void:
	var btn: Button = _runner.find_child("Resume", true, false)
	assert_that(btn).is_not_null()

	var monitor = monitor_signals(_runner.scene())
	btn.emit_signal("pressed")
	await _runner.simulate_frames(1)
	assert_signal(monitor).is_emitted("resume_requested")

func test_quit_button_emits_signal() -> void:
	var btn: Button = _runner.find_child("Quit", true, false)
	assert_that(btn).is_not_null()

	var monitor = monitor_signals(_runner.scene())
	btn.emit_signal("pressed")
	await _runner.simulate_frames(1)
	assert_signal(monitor).is_emitted("quit_requested")

func test_settings_button_emits_signal() -> void:
	var btn: Button = _runner.find_child("Settings", true, false)
	assert_that(btn).is_not_null()

	var monitor = monitor_signals(_runner.scene())
	btn.emit_signal("pressed")
	await _runner.simulate_frames(1)
	assert_signal(monitor).is_emitted("settings_requested")
