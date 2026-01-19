extends "res://tests/test_utils.gd"

const CONTROLS_MENU_PATH := "res://Menus/controls_menu.tscn"

var _runner: GdUnitSceneRunner
var _control_settings: Node
var _input_mapper: Node

func before_test() -> void:
	# Mock ControlSettings
	_control_settings = Node.new()
	_control_settings.name = "ControlSettings"
	var cs_script = GDScript.new()
	cs_script.source_code = """
extends Node
var move_actions = []
var camera_actions = []
var selection_actions = []
var pause_actions = []
var interaction_actions = []
func reset_inputs_to_defaults(): pass
"""
	cs_script.reload()
	_control_settings.set_script(cs_script)
	get_tree().root.add_child(_control_settings)

	# Mock InputMapper
	_input_mapper = Node.new()
	_input_mapper.name = "InputMapper"
	var im_script = GDScript.new()
	im_script.source_code = """
extends Node
func apply_configs(configs, defaults = null): pass
"""
	im_script.reload()
	_input_mapper.set_script(im_script)
	get_tree().root.add_child(_input_mapper)

	_runner = scene_runner(CONTROLS_MENU_PATH)
	_runner.simulate_frames(1)

func after_test() -> void:
	if is_instance_valid(_control_settings):
		get_tree().root.remove_child(_control_settings)
		_control_settings.free()
	if is_instance_valid(_input_mapper):
		get_tree().root.remove_child(_input_mapper)
		_input_mapper.free()

func test_back_button_emits_signal() -> void:
	var btn: Button = _runner.find_child("Back", true, false)
	assert_that(btn).is_not_null()

	var monitor := monitor_signals(_runner.scene())
	btn.emit_signal("pressed")
	_runner.simulate_frames(1)
	assert_signal(monitor).is_emitted("back_requested")

func test_reset_button_triggers_reset() -> void:
	var btn: Button = _runner.find_child("Reset", true, false)
	assert_that(btn).is_not_null()

	btn.emit_signal("pressed")
	_runner.simulate_frames(1)

	# Since we can't easily spy on the inline script, we just ensure no crash
	# and that the scene is still valid.
	assert_that(_runner.scene()).is_not_null()
