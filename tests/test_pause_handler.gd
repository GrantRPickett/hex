extends "res://tests/test_utils.gd"

const PAUSE_HANDLER_SCRIPT = preload("res://Gameplay/pause_handler.gd")
const PAUSE_MENU_SCENE = preload("res://Menus/pause_menu.tscn")

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
func test_handle_pause_input_toggles_state() -> void:
	var handler = PAUSE_HANDLER_SCRIPT.new()
	get_tree().root.add_child(handler)
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	_simulate_frames(runner, 1)

	var pause_event := InputEventAction.new()
	pause_event.action = "pause_game"
	pause_event.pressed = true

	handler._unhandled_input(pause_event)
	var scene := runner.scene()
	_simulate_frames(runner, 1)
	assert_that(handler.is_paused()).is_true()

	handler._unhandled_input(pause_event)
	_simulate_frames(runner, 1)
	assert_that(handler.is_paused()).is_false()

	handler.queue_free()
