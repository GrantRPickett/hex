extends GdUnitTestSuite

const SCENE_PATH := "res://Menus/title_screen.tscn"
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const CREDITS_SCENE_PATH := "res://Menus/credits.tscn"

var _quit_called := false

func _mark_quit_called() -> void:
	_quit_called = true

var _control_settings_backup := {}

func before_test() -> void:
	_control_settings_backup = {
		"start_keycodes": ControlSettings.start_keycodes.duplicate(),
		"quit_keycodes": ControlSettings.quit_keycodes.duplicate(),
		"start_joypad_buttons": ControlSettings.start_joypad_buttons.duplicate(),
		"quit_joypad_buttons": ControlSettings.quit_joypad_buttons.duplicate(),
		"allow_any_non_quit_key_to_start": ControlSettings.allow_any_non_quit_key_to_start,
		"allow_any_joy_button_to_start": ControlSettings.allow_any_joy_button_to_start,
	}

func after_test() -> void:
	ControlSettings.start_keycodes = _control_settings_backup["start_keycodes"].duplicate()
	ControlSettings.quit_keycodes = _control_settings_backup["quit_keycodes"].duplicate()
	ControlSettings.start_joypad_buttons = _control_settings_backup["start_joypad_buttons"].duplicate()
	ControlSettings.quit_joypad_buttons = _control_settings_backup["quit_joypad_buttons"].duplicate()
	ControlSettings.allow_any_non_quit_key_to_start = _control_settings_backup["allow_any_non_quit_key_to_start"]
	ControlSettings.allow_any_joy_button_to_start = _control_settings_backup["allow_any_joy_button_to_start"]

func _press_key(scene: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	event.echo = false
	scene._unhandled_input(event)

func _press_joy_button(scene: Node, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	scene._unhandled_input(event)


func test_title_screen_scene_structure() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	assert_that(packed).is_not_null()
	assert_that(packed).is_instanceof(PackedScene)

	var instance: Node = packed.instantiate()
	assert_that(instance).is_instanceof(Control)

	var label := instance.get_node("Center/VBox/TitleLabel") as Label
	assert_that(label).is_not_null()
	assert_that(label.text).is_equal("HEX")

	var start_button := instance.get_node("Center/VBox/StartButton") as Button
	var quit_button := instance.get_node("Center/VBox/QuitButton") as Button
	assert_that(start_button).is_not_null()
	assert_that(quit_button).is_not_null()

	instance.free()
	# Ensure instance is freed
	assert_that(is_instance_valid(instance)).is_false()


func test_start_button_loads_gameplay_scene() -> void:
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)
	var tree := scene.get_tree()

	var start_button := scene.get_node("Center/VBox/StartButton") as Button
	assert_that(start_button).is_not_null()

	start_button.pressed.emit()
	@warning_ignore("redundant_await")
	await runner.simulate_until_object_signal(tree, "scene_changed")

	var current := tree.current_scene
	assert_that(current).is_not_null()
	assert_that(current.scene_file_path).is_equal(GAMEPLAY_SCENE_PATH)


func test_quit_button_requests_quit() -> void:
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	_quit_called = false
	scene.set_quit_callback(Callable(self, "_mark_quit_called"))

	var quit_button := scene.get_node("Center/VBox/QuitButton") as Button
	assert_that(quit_button).is_not_null()

	quit_button.pressed.emit()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	assert_that(_quit_called).is_true()




func test_escape_key_requests_quit() -> void:
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	_quit_called = false
	scene.set_quit_callback(Callable(self, "_mark_quit_called"))

	_press_key(scene, KEY_ESCAPE)
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	assert_that(_quit_called).is_true()


func test_any_key_starts_gameplay_scene() -> void:
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)
	var tree := scene.get_tree()

	_press_key(scene, KEY_ENTER)
	@warning_ignore("redundant_await")
	await runner.simulate_until_object_signal(tree, "scene_changed")

	var current := tree.current_scene
	assert_that(current).is_not_null()
	assert_that(current.scene_file_path).is_equal(GAMEPLAY_SCENE_PATH)


func test_custom_start_key_triggers_gameplay_when_any_key_disabled() -> void:
	ControlSettings.start_keycodes = PackedInt32Array([KEY_F5])
	ControlSettings.allow_any_non_quit_key_to_start = false
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)
	var tree := scene.get_tree()

	_press_key(scene, KEY_F5)
	@warning_ignore("redundant_await")
	await runner.simulate_until_object_signal(tree, "scene_changed")

	var current := tree.current_scene
	assert_that(current).is_not_null()
	assert_that(current.scene_file_path).is_equal(GAMEPLAY_SCENE_PATH)


func test_non_start_key_ignored_when_any_key_disabled() -> void:
	ControlSettings.start_keycodes = PackedInt32Array([KEY_F5])
	ControlSettings.allow_any_non_quit_key_to_start = false
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)
	var tree := scene.get_tree()
	var initial_scene := tree.current_scene

	_press_key(scene, KEY_ENTER)
	@warning_ignore("redundant_await")
	await runner.simulate_frames(2)

	assert_that(tree.current_scene).is_equal(initial_scene)


func test_custom_quit_key_requests_quit() -> void:
	ControlSettings.quit_keycodes = PackedInt32Array([KEY_F6])
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	_quit_called = false
	scene.set_quit_callback(Callable(self, "_mark_quit_called"))

	_press_key(scene, KEY_F6)
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	assert_that(_quit_called).is_true()


func test_custom_start_joy_button_loads_gameplay_scene() -> void:
	ControlSettings.start_joypad_buttons = PackedInt32Array([JOY_BUTTON_Y])
	ControlSettings.allow_any_joy_button_to_start = false
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)
	var tree := scene.get_tree()

	_press_joy_button(scene, JOY_BUTTON_Y)
	@warning_ignore("redundant_await")
	await runner.simulate_until_object_signal(tree, "scene_changed")

	var current := tree.current_scene
	assert_that(current).is_not_null()
	assert_that(current.scene_file_path).is_equal(GAMEPLAY_SCENE_PATH)


func test_custom_quit_joy_button_requests_quit() -> void:
	ControlSettings.quit_joypad_buttons = PackedInt32Array([JOY_BUTTON_X])
	var runner := scene_runner(SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	_quit_called = false
	scene.set_quit_callback(Callable(self, "_mark_quit_called"))

	_press_joy_button(scene, JOY_BUTTON_X)
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	assert_that(_quit_called).is_true()

func test_credits_scene_returns_to_title() -> void:
	var runner := scene_runner(CREDITS_SCENE_PATH)
	var scene := runner.scene()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(1)

	scene.set_return_delay(0.01)
	@warning_ignore("redundant_await")
	await runner.simulate_until_object_signal(scene.get_tree(), "scene_changed")

	var current := scene.get_tree().current_scene
	assert_that(current).is_not_null()
	assert_that(current.scene_file_path).is_equal(SCENE_PATH)


## Gameplay-specific behaviors are covered in dedicated gameplay tests.
