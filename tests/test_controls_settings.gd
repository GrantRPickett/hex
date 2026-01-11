extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _original_move_actions: Array

func before_test() -> void:
	_original_move_actions = ControlSettings.move_actions.duplicate(true)

func after_test() -> void:
	ControlSettings.move_actions = _original_move_actions
	InputMapper.clear_action("move_d")

func test_custom_move_action_registers_key_binding() -> void:
	randomize()
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_simulate_frames(runner, 1)

	ControlSettings.move_actions = [
		{"action": "move_d", "keys": [KEY_F1], "joy_buttons": []},
	]
	InputMapper.clear_action("move_d")
	runner.scene()._register_input_actions()
	_simulate_frames(runner, 1)

	var events := InputMap.action_get_events("move_d")
	var keycodes := []
	for event in events:
		if event is InputEventKey:
			keycodes.append(event.keycode)
	assert_that(keycodes).contains(KEY_F1)
