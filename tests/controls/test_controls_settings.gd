extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _original_move_actions: Array
var _control_settings: Node = null
var _input_mapper: Node = null

func before_test() -> void:
	_control_settings = await ensure_manager("ControlSettings", "res://Autoloads/control_settings.gd")
	_input_mapper = await ensure_manager("InputMapper", "res://Autoloads/input_mapper.gd")
	_original_move_actions = _control_settings.move_actions.duplicate(true)

func after_test() -> void:
	_control_settings.move_actions = _original_move_actions
	if _input_mapper:
		_input_mapper.clear_action("move_d")
		_input_mapper.clear_action("ui_select")
		_input_mapper.clear_action("secondary_action")
	if is_instance_valid(_control_settings):
		_control_settings.queue_free()
	if is_instance_valid(_input_mapper):
		_input_mapper.queue_free()
	await get_tree().process_frame

func test_custom_move_action_registers_key_binding() -> void:
	randomize()
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_simulate_frames(runner, 1)

	_control_settings.move_actions = [
		{"action": "move_d", "keys": [KEY_F1], "joy_buttons": []},
	]
	_input_mapper.clear_action("move_d")
	runner.scene()._register_input_actions()
	_simulate_frames(runner, 1)

	var events := InputMap.action_get_events("move_d")
	var keycodes := []
	for event in events:
		if event is InputEventKey:
			keycodes.append(event.keycode)
	assert_that(keycodes).contains(KEY_F1)

func test_interaction_actions_register_mouse_buttons() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_simulate_frames(runner, 1)
	runner.scene()._register_input_actions()
	_simulate_frames(runner, 1)

	var primary_has_mouse := false
	for event in InputMap.action_get_events("ui_select"):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			primary_has_mouse = true
			break
	assert_that(primary_has_mouse).is_true()

	var secondary_has_mouse := false
	for event in InputMap.action_get_events("secondary_action"):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			secondary_has_mouse = true
			break
	assert_that(secondary_has_mouse).is_true()
