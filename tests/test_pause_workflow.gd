extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

func _action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev

func test_pause_blocks_input_and_resume_restores() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	# Pause by simulating the action
	scene._unhandled_input(_action_event("pause_game"))
	_simulate_frames(runner, 1)

	var before: Vector2i = scene.player_coord
	var move_event_action := "move_s"
	scene._unhandled_input(_action_event(move_event_action))
	_simulate_frames(runner, 1)
	assert_that(scene.player_coord).is_equal(before)

	# Find the pause menu and resume
	var handler = scene.get_node("PauseHandler")
	var pause_menu = handler.get_node("PauseMenu")
	assert_that(pause_menu).is_not_null()
	pause_menu.resume_requested.emit()

	_simulate_frames(runner, 1)
	scene._unhandled_input(_action_event(move_event_action))
	_simulate_frames(runner, 1)
	assert_that(scene.player_coord).is_not_equal(before)

func test_pause_menus_process_during_tree_pause() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	scene._unhandled_input(_action_event("pause_game"))
	_simulate_frames(runner, 1)

	var handler = scene.get_node("PauseHandler")
	var pause_menu = handler.get_node("PauseMenu")
	assert_that(pause_menu).is_not_null()
	assert_that(pause_menu.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

	pause_menu.controls_requested.emit()
	_simulate_frames(runner, 1)

	var controls_menu = handler.get_node("ControlsMenu")
	assert_that(controls_menu).is_not_null()
	assert_that(controls_menu.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

	controls_menu.back_requested.emit()
	pause_menu.resume_requested.emit()

func test_pause_controls_reset_defaults() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	var original := ControlSettings.move_actions.duplicate(true)
	ControlSettings.move_actions = [{"action": "move_d", "keys": [KEY_F7], "joy_buttons": []}]

	scene._unhandled_input(_action_event("pause_game"))
	_simulate_frames(runner, 1)

	var handler = scene.get_node("PauseHandler")
	var pause_menu = handler.get_node("PauseMenu")
	pause_menu.controls_requested.emit()
	_simulate_frames(runner, 1)

	var ctrl_menu = handler.get_node("ControlsMenu")
	assert_that(ctrl_menu).is_not_null()
	ctrl_menu.reset_and_apply_defaults()
	_simulate_frames(runner, 1)

	assert_that(ControlSettings.move_actions).is_not_equal([{"action": "move_d", "keys": [KEY_F7], "joy_buttons": []}])

	ctrl_menu.back_requested.emit()
	pause_menu.resume_requested.emit()
	ControlSettings.move_actions = original

func test_pause_volume_and_mute_controls() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	scene._unhandled_input(_action_event("pause_game"))
	_simulate_frames(runner, 1)

	var handler = scene.get_node("PauseHandler")
	var menu = handler.get_node("PauseMenu")
	assert_that(menu).is_not_null()

	var orig_db := AudioBusController.get_bus_volume_db("Music")
	menu._on_volume_changed(-20.0)
	_simulate_frames(runner, 1)
	assert_that(AudioBusController.get_bus_volume_db("Music")).is_equal_approx(-20.0, 0.5)

	var was_muted := AudioBusController.is_bus_muted("Music")
	menu._on_mute_toggled(true)
	_simulate_frames(runner, 1)
	assert_that(AudioBusController.is_bus_muted("Music")).is_true()

	menu._on_mute_toggled(was_muted)
	menu._on_volume_changed(orig_db)
