extends "res://tests/test_utils.gd"
var _control_settings: Node

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
}

func after_test() -> void:
	await teardown_autoloads()

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_control_settings = instances["ControlSettings"]

func test_reset_inputs_to_defaults_restores_settings() -> void:
	var original_move: Array = _control_settings.move_actions.duplicate(true)
	var original_cam: Array = _control_settings.camera_actions.duplicate(true)
	var original_sel: Array = _control_settings.selection_actions.duplicate(true)
	var original_pause: Array = _control_settings.pause_actions.duplicate(true)

	_control_settings.move_actions = [{"action": "move_d", "keys": [KEY_F8], "joy_buttons": []}]
	_control_settings.camera_actions = []
	_control_settings.selection_actions = []
	_control_settings.pause_actions = []

	_control_settings.reset_inputs_to_defaults()

	assert_that(_control_settings.move_actions).is_not_equal([{"action": "move_d", "keys": [KEY_F8], "joy_buttons": []}])
	assert_that(_control_settings.camera_actions).is_not_equal([])
	assert_that(_control_settings.selection_actions).is_not_equal([])
	assert_that(_control_settings.pause_actions).is_not_equal([])

	# Restore original to avoid side effects
	_control_settings.move_actions = original_move
	_control_settings.camera_actions = original_cam
	_control_settings.selection_actions = original_sel
	_control_settings.pause_actions = original_pause
