extends GdUnitTestSuite

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const TITLE_SCENE_PATH := "res://Menus/title_screen.tscn"

func _action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev

func test_pause_blocks_input_and_resume_restores() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	scene._show_pause_menu()
	await runner.simulate_frames(1)

	var before: Vector2i = scene.player_coord
	var move_event_action := "move_s"
	scene._unhandled_input(_action_event(move_event_action))
	await runner.simulate_frames(1)
	assert_that(scene.player_coord).is_equal(before)

	scene._on_pause_resume()
	await runner.simulate_frames(1)
	scene._unhandled_input(_action_event(move_event_action))
	await runner.simulate_frames(1)
	assert_that(scene.player_coord).is_not_equal(before)

func test_pause_menus_process_during_tree_pause() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	scene._show_pause_menu()
	await runner.simulate_frames(1)

	var pause_menu: Control = scene.get_node_or_null("PauseMenu")
	assert_that(pause_menu).is_not_null()
	assert_that(pause_menu.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

	scene._on_pause_controls()
	await runner.simulate_frames(1)

	var controls_menu: Control = scene.get_node_or_null("ControlsMenu")
	assert_that(controls_menu).is_not_null()
	assert_that(controls_menu.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

	scene._on_controls_back()
	scene._on_pause_resume()
func test_pause_controls_reset_defaults() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	# Change controls to a temporary custom value
	var original := ControlSettings.move_actions.duplicate(true)
	ControlSettings.move_actions = [{"action": "move_d", "keys": [KEY_F7], "joy_buttons": []}]

	scene._show_pause_menu()
	scene._on_pause_controls()
	await runner.simulate_frames(1)

	# Access controls menu and trigger reset
	var ctrl_menu := scene.get_node_or_null("ControlsMenu")
	if ctrl_menu == null:
		# controls menu is added as a direct child; find by type
		for child in scene.get_children():
			if child is Control and child.has_method("reset_and_apply_defaults"):
				ctrl_menu = child
				break
	assert_that(ctrl_menu).is_not_null()
	ctrl_menu.reset_and_apply_defaults()
	await runner.simulate_frames(1)

	# Ensure settings differ from our custom value (i.e., reset)
	assert_that(ControlSettings.move_actions).is_not_equal([{"action": "move_d", "keys": [KEY_F7], "joy_buttons": []}])

	# Back and resume
	scene._on_controls_back()
	scene._on_pause_resume()
	ControlSettings.move_actions = original


func test_pause_volume_and_mute_controls() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	scene._show_pause_menu()
	await runner.simulate_frames(1)

	# Find pause menu instance
	var menu := scene.get_node_or_null("PauseMenu")
	if menu == null:
		for child in scene.get_children():
			if child is Control and child.has_method("_on_volume_changed"):
				menu = child
				break
	assert_that(menu).is_not_null()

	# Change volume and toggle mute via exposed handlers
	var orig_db := AudioBusController.get_bus_volume_db("Music")
	menu._on_volume_changed(-20.0)
	await runner.simulate_frames(1)
	assert_that(AudioBusController.get_bus_volume_db("Music")).is_equal_approx(-20.0, 0.5)

	var was_muted := AudioBusController.is_bus_muted("Music")
	menu._on_mute_toggled(true)
	await runner.simulate_frames(1)
	assert_that(AudioBusController.is_bus_muted("Music")).is_true()

	# Restore
	menu._on_mute_toggled(was_muted)
	menu._on_volume_changed(orig_db)
