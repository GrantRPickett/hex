extends "res://tests/test_utils.gd"

var _control_settings: Node = null
var _input_mapper: Node = null
var _audio_bus_controller: Node = null
const AUTOLOADS_TO_MANAGE = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
	"AudioBusController": "res://Autoloads/audio_bus_controller.gd",
}

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS_TO_MANAGE)
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]
	_audio_bus_controller = instances["AudioBusController"]

func after_test() -> void:
	await super.after_test()


const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
func _action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev

func test_pause_menus_process_during_tree_pause() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	var pause_handler = scene.get_node("PauseHandler")
	pause_handler._unhandled_input(_action_event("pause_game"))
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

	var original: Array = _control_settings.move_actions.duplicate(true)
	_control_settings.move_actions = [{"action": "move_d", "keys": [KEY_F7], "joy_buttons": []}]

	var pause_handler = scene.get_node("PauseHandler")
	pause_handler._unhandled_input(_action_event("pause_game"))
	_simulate_frames(runner, 1)

	var handler = scene.get_node("PauseHandler")
	var pause_menu = handler.get_node("PauseMenu")
	pause_menu.controls_requested.emit()
	_simulate_frames(runner, 1)

	var ctrl_menu = handler.get_node("ControlsMenu")
	assert_that(ctrl_menu).is_not_null()
	ctrl_menu.reset_and_apply_defaults()
	_simulate_frames(runner, 1)

	assert_that(_control_settings.move_actions).is_not_equal([{"action": "move_d", "keys": [KEY_F7], "joy_buttons": []}])

	ctrl_menu.back_requested.emit()
	pause_menu.resume_requested.emit()
	_control_settings.move_actions = original

func test_pause_volume_and_mute_controls() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	assert_that(audio_bus_controller).is_not_null()

	var pause_handler = scene.get_node("PauseHandler")
	pause_handler._unhandled_input(_action_event("pause_game"))
	_simulate_frames(runner, 1)

	var handler = scene.get_node("PauseHandler")
	var menu = handler.get_node("PauseMenu")
	assert_that(menu).is_not_null()

	var orig_db: float = audio_bus_controller.get_bus_volume_db("Music")
	menu._on_volume_changed(-20.0)
	_simulate_frames(runner, 1)
	assert_that(audio_bus_controller.get_bus_volume_db("Music")).is_equal_approx(-20.0, 0.5)

	var was_muted: bool = audio_bus_controller.is_bus_muted("Music")
	menu._on_mute_toggled(true)
	_simulate_frames(runner, 1)
	assert_that(audio_bus_controller.is_bus_muted("Music")).is_true()

	menu._on_mute_toggled(was_muted)
	menu._on_volume_changed(orig_db)
